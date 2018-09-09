#!#!/usr/bin/perl -w

#$GLOBAL_PATH='/home/jh7x3/CASP13_development/DeepSF-3D/version-V3-2018-04-05/';

if (@ARGV != 7) {
  print "Usage: <input> <output>\n";
  exit;
}

$test_file = $ARGV[0];
$querypdb = $ARGV[1];
$featuredir  = $ARGV[2]; 
$queryfea_dir  = $ARGV[3]; 
$outdir = $ARGV[4]; 
$out = $ARGV[5]; 
$GLOBAL_PATH = $ARGV[6]; 


open(IN1,"$test_file")|| die("Failed to open file $test_file \n");
#opendir(DIR,"$featuredir")|| die("Failed to open file $featuredir \n");
open(OUT,">$out")|| die("Failed to open file $out \n");


$filepath = "$queryfea_dir/$querypdb.hidden_feature";
if(!(-e $filepath))
{
	die "Couldn't find $filepath\n";
}
open(IN,"$filepath") || die "Failed to open file $filepath\n";
@content = <IN>;
close IN;
$line = shift @content;
chomp $line;
@tmp2 = split(/\t/,$line);
if(@tmp2!=1500)
{
	die "The number of prediciton is not correct ".@tmp2."\n";
}
print OUT "Query_$querypdb";
foreach $it (@tmp2)
{
	$new = sprintf("%.5f",$it);
	print OUT "\t$new";
}
print OUT "\n";



$c=0;
%top5_folds_info = ();
%top5_folds_statistics = ();
while(<IN1>){
	$c++;
	$line = $_;
	chomp $line;
	@temp = split(/\t/,$line);
	#$qid = $temp[0];
	$tid = $temp[1];
	#$KL = $temp[2];
	$tscop_fold = $temp[4];
	
	if(exists($top5_folds_statistics{$tscop_fold}))
	{
		if($top5_folds_statistics{$tscop_fold}>10)
		{
			next;
		}
		$top5_folds_statistics{$tscop_fold}++;
		$top5_folds_info{$tscop_fold} .=";".$line;
	}else{
		$top5_folds_statistics{$tscop_fold}=1;
		$top5_folds_info{$tscop_fold}=$line;
	}
	
	$fold = $tscop_fold; # a.1
	$filepath = "$featuredir/$tid.hidden_feature";
	if(!(-e $filepath))
	{
		die "Couldn't find $filepath\n";
	}
	open(IN,"$filepath") || die "Failed to open file $filepath\n";
	@content = <IN>;
	close IN;
	$line2 = shift @content;
	chomp $line2;
	@tmp2 = split(/\t/,$line2);
	if(@tmp2!=1500)
	{
		die "The number of prediciton is not correct ".@tmp2."\n";
	} 
	print OUT "${fold}_$tid";
	foreach $it (@tmp2)
	{
		$new = sprintf("%.5f",$it);
		print OUT "\t$new";
	}
	print OUT "\n";
		
}
close IN1;
close OUT;

$outputdir = "$outdir/${querypdb}_top5_folds_info";
if(-d $outputdir)
{
	`rm -rf $outputdir/*`;
}else{
	`mkdir $outputdir`;
}
foreach $key (sort keys %top5_folds_info)
{
	$outputfile = "$outputdir/fold_$key";
	$pdbdir = "$outputdir/fold_${key}_atom";
	if(-d $pdbdir)
	{
		`rm -rf $pdbdir/*`;
	}else{
		`mkdir $pdbdir`;
	}	
	open(TMP,">$outputfile")|| die "Failed to write $outputfile\n";
	$tems = $top5_folds_info{$key};
	@tmps_detail = split(';',$tems);
	$c = 0;
	foreach $l (@tmps_detail)
	{
		$c++;
		print TMP "$l\n";
		if($c == 1)
		{
			@tmps = split(/\t/,$l);
			$template = $tmps[1];
			$pdbfile = $GLOBAL_PATH.'/database/ECOD/ECOD_template_PDB/pdb/'.$template.'.atom';
			if(!(-e $pdbfile))
			{
				print "couldn't find $pdbfile\n";
			}
			`cp $pdbfile $pdbdir/$template.pdb`;
			
		}
	}
	close TMP;
}

`touch $out.done`;
