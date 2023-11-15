#!/usr/bin/perl

use Data::Dumper;
use utf8;

$lsoas;

open(CSV,"Lower_Layer_Super_Output_Area_(2021)_to_LAD_(April_2023)_Lookup_in_England_and_Wales.csv");
@lines = <CSV>;
close(CSV);
foreach $line (@lines){
	$line =~ s/[\n\r]//g;
	($LSOA21CD,$LSOA21NM,$LSOA21NMW,$LAD23CD,$LAD23NM,$LAD23NMW,$ObjectId) = split(/,(?=(?:[^\"]*\"[^\"]*\")*(?![^\"]*\"))/,$line);
	$LAD23NM =~ s/(^\"|\"$)//g;
	$lsoas->{$LSOA21CD} = {'LAD23CD'=>$LAD23CD,'LAD23NM'=>$LAD23NM};
}

open(CSV,"Output_Area_to_Lower_layer_Super_Output_Area_to_Middle_layer_Super_Output_Area_to_Local_Authority_District_(December_2021)_Lookup_in_England_and_Wales_v3.csv");
@lines = <CSV>;
close(CSV);
foreach $line (@lines){
	$line =~ s/[\n\r]//g;
	($OA21CD,$LSOA21CD,$LSOA21NM,$LSOA21NMW,$MSOA21CD,$MSOA21NM,$MSOA21NMW,$LAD22CD,$LAD22NM,$LAD22NMW,$ObjectId) = split(/,(?=(?:[^\"]*\"[^\"]*\")*(?![^\"]*\"))/,$line);
	$LAD22NM =~ s/(^\"|\"$)//g;
	$MSOA21NM =~ s/(^\"|\"$)//g;
	$lsoas->{$LSOA21CD}{'LAD22CD'} = $LAD22CD;
	$lsoas->{$LSOA21CD}{'LAD22NM'} = $LAD22NM;
	$lsoas->{$LSOA21CD}{'MSOA21CD'} = $MSOA21CD;
	$lsoas->{$LSOA21CD}{'MSOA21NM'} = $MSOA21NM;
}

open(FILE,"maps/Lower_layer_Super_Output_Areas_2021_EW_BSC_v2_-3367547069962449861/clipped.geojson");
@geolines = <FILE>;
close(FILE);
foreach $line (@geolines){
	if($line =~ /"LSOA21CD": ?"([^\"]{9})"/){
		$lsoas->{$1}{'keep'} = 1;
	}
}


$lads;

open(JSON,">:utf8","lsoa2lad.json");
print JSON "{";
$n = 0;
foreach $lsoa (sort(keys(%{$lsoas}))){
	if($lsoas->{$lsoa}{'LAD23CD'} && $lsoas->{$lsoa}{'keep'}){
		push(@{$lads->{$lsoas->{$lsoa}{'LAD23CD'}}},"\"".$lsoas->{$lsoa}{'MSOA21CD'}."\"");
		print JSON ($n > 0 ? ",":"")."\n\t"."\"$lsoa\":\{\"$lsoas->{$lsoa}{'LAD23CD'}\":1\}";
		$n++;
	}
}
print JSON "}\n";
close(JSON);


open(JSON,">:utf8","msoa2lad.json");
print JSON "{";
$n = 0;
foreach $lad (sort(keys(%{$lads}))){
	print JSON ($n > 0 ? ",":"")."\n\t\"$lad\":[".join(",",@{$lads->{$lad}})."]";
}
print JSON "}\n";
close(JSON);

exit;

open(GEO,">:utf8","maps/LSOA2021-super-generalised-clipped-lookup.geojson");
foreach $line (@geolines){
	$tline = $line."";
	if($tline =~ /"LSOA21CD": ?"([^\"]{9})"/){
		$id = $1;
		if($lsoas->{$id}{'LAD23CD'} && $lsoas->{$id}{'MSOA21CD'}){
			$tline =~ s/"LSOA21CD": ?"$id"/"LSOA21CD": "$id"\, "LAD23CD": "$lsoas->{$id}{'LAD23CD'}"\, "LAD23NM": "$lsoas->{$id}{'LAD23NM'}"\, "MSOA21CD": "$lsoas->{$id}{'MSOA21CD'}"\, "MSOA21NM": "$lsoas->{$id}{'MSOA21NM'}"/g;
		}else{
			print "Bad LSOA $id ($lsoas->{$id}{'LAD23CD'}, $lsoas->{$id}{'MSOA21CD'})\n";
		}
	}
	print GEO $tline;
}
close(GEO);

