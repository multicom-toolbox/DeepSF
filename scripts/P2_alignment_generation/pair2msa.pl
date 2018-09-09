#!/usr/bin/perl -w
#define hash

###############################################################################
#Combine multiple pairwise alignments into a multiple sequence alignment
#
#Input: hits file, pairwise alignment file path, output file, target ID 
#
#Author: Jilong Li
#Date: 03/07/2014
###############################################################################

$numArgs = @ARGV;
if($numArgs != 4)
{   
	print "the number of parameters is not correct!\n";
	exit(1);
}

$hitsfile	= "$ARGV[0]";
$pirpath	= "$ARGV[1]";
$pirfile	= "$ARGV[2]";
$targetid	= "$ARGV[3]";

%h1=();	#line1 in pir
%h2=();	#line2 in pir
%h3=();	#line3 in pir
%h4=();	#line4 in pir
@hits=();
$k=0;

open(IN1, "$hitsfile") || die("Couldn't open file $hitsfile\n"); 
@ahits=<IN1>;
close IN1;

$c=0;
foreach $tid (@ahits) {
	chomp($tid);
	$c++;
	$hits[$k]=$tid;
	$f1=$pirpath."/".$tid.".pir";
	open(IN2, "$f1") || die("Couldn't open file $f1\n"); 
	@apir=<IN2>;
	close IN2;
	
	$c1=0;
	foreach $l1 (@apir) {
		$c1++;
		chomp($l1);
		if ($c1==1) {$h1{$tid}=$l1;}
		if ($c1==2) {$h2{$tid}=$l1;}
		if ($c1==3) {$h3{$tid}=$l1;}
		if ($c1==4) {
			if (substr($l1,length($l1)-1,1) eq "*") {
				$l11=substr($l1,0,length($l1)-1);
			}
			$h4{$tid}=$l11;
		}

		if ($c==1){
			if ($c1==6) {$h1{$targetid}=$l1;}
			if ($c1==7) {$h2{$targetid}=$l1;}
			if ($c1==8) {$h3{$targetid}=$l1;}
			if ($c1==9) {
				if (substr($l1,length($l1)-1,1) eq "*") {
					$l11=substr($l1,0,length($l1)-1);
				}
				$h4{$targetid}=$l11;
			}
		}
		else{
			if ($c1==9) {
				if (substr($l1,length($l1)-1,1) eq "*") {
					$l11=substr($l1,0,length($l1)-1);
				}
				$target2=$l11;
				$targetnew="";
				$i=0;
				$j=0;
				$t=0;
				while ($i<length($h4{$targetid}) && $j<length($target2)) {
					$s1=substr($h4{$targetid},$i,1);
					$s2=substr($target2,$j,1);
					if ($s1 eq "-" && $s2 eq "-") {
						$targetnew.="-";
						$i++;
						$j++;
						$t++;
					}
					if ($s1 eq "-" && $s2 ne "-") {
						$targetnew.="-";
						$i++;
						$left="";
						if ($t>0) {$left=substr($h4{$tid},0,$t);}
						$right=substr($h4{$tid},$t);
						$h4{$tid}=$left."-".$right;
						$t++;
					}
					if ($s1 ne "-" && $s2 eq "-") {
						$targetnew.="-";
						$j++;
						for ($m=0; $m<$k; $m++) {
							$left="";
							if ($t>0) {$left=substr($h4{$hits[$m]},0,$t);}
							$right=substr($h4{$hits[$m]},$t);
							$h4{$hits[$m]}=$left."-".$right;
						}
						$t++;
					}
					if ($s1 ne "-" && $s2 ne "-") {
						$targetnew.=$s1;
						$i++;
						$j++;
						$t++;
					}
				}
				while ($i<length($h4{$targetid})) {
					$s1=substr($h4{$targetid},$i,1);
					$targetnew.=$s1;
					$i++;
					$h4{$tid}.="-";
					$t++;
				}
				while ($j<length($target2)) {
					$s2=substr($target2,$j,1);
					$targetnew.=$s2;
					$j++;
					for ($m=0; $m<$k; $m++) {
						$h4{$hits[$m]}.="-";
					}
					$t++;
				}
				$h4{$targetid}=$targetnew;
				last;
			}
		}
	}
	$k++;
}

open(OUT1, ">$pirfile") || die("Couldn't open file $pirfile\n");
foreach $tid (@ahits) {
	chomp($tid);
	print OUT1 $h1{$tid}."\n";
	print OUT1 $h2{$tid}."\n";
	print OUT1 $h3{$tid}."\n";
	print OUT1 $h4{$tid}."*\n\n";
}
print OUT1 $h1{$targetid}."\n";
print OUT1 $h2{$targetid}."\n";
print OUT1 $h3{$targetid}."\n";
print OUT1 $h4{$targetid}."*\n";
close OUT1;

