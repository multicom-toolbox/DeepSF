#!/usr/bin/perl -w
#perl  /var/www/cgi-bin/DeepSF/scripts/combine_prediction_with_template.pl    /var/www/cgi-bin/DeepSF/work/DeepSF-Jie3-149090540221348/Jie3-seqs/DeepSF-Jie3-149090540221348.list_with_fea  /var/www/cgi-bin/DeepSF/work/DeepSF-Jie3-149090540221348/Jie3-predict-out/  /var/www/cgi-bin/DeepSF/database/Traindata.list /var/www/cgi-bin/DeepSF/work/DeepSF-Jie3-149090540221348/Jie3-KL-hidden-out/score_ranking_dir/ /var/www/cgi-bin/DeepSF/database/dir.des.scop.1.75_class.txt /var/www/cgi-bin/DeepSF/work/DeepSF-Jie3-149090540221348/Jie3-top5-model/

if (@ARGV != 7) {
  print "Usage: <input> <output>\n";
  exit;
}


$test_file = $ARGV[0];#Jie3-seqs/DeepSF-Jie3-149090540221348.list_with_fea
$prediction_dir = $ARGV[1]; # Jie3-predict-out 
$Traindatalist = $ARGV[2];  
$temp_dir = $ARGV[3]; #Jie3-KL-hidden-out/score_ranking_dir/d1ri9a__top5_folds_info/
$fold_description = $ARGV[4]; 
$family_description = $ARGV[5]; 
$outdir = $ARGV[6]; 




open(IN1,"$fold_description")|| die("Failed to open file $fold_description \n");
%fold_class_description=();
%fold_class_scopid=();
while(<IN1>)
{
	$line=$_;
	chomp $line;
	@array = split(/\s+/,$line);
	$scopid=$array[0];
	$class=$array[2];
	$desc=$array[4];
	$fold_class_description{$class} = $desc;
	$fold_class_scopid{$class} = $scopid;
}
close IN1;

open(IN1,"$family_description")|| die("Failed to open file $family_description \n");
%family_class_description=();
%family_class_scopid=();
while(<IN1>)
{
	$line=$_;
	chomp $line;
	@array = split(/\s+/,$line);
	$scopid=$array[0];
	$class=$array[2];
	$desc=$array[4];
	$family_class_description{$class} = $desc;
	$family_class_scopid{$class} = $scopid;
}
close IN1;
open(IN1,"$Traindatalist")|| die("Failed to open file $Traindatalist \n");
%pro2label=();
while(<IN1>)
{
	$line=$_;
	chomp $line;
	@temp = split(/\t/,$line);
	$qid = $temp[0];
	$label = $temp[2];
	$pro2label{$qid} =$label;
}

close IN1;
open(IN1,"$test_file")|| die("Failed to open file $test_file \n");

$c=0;
while(<IN1>){
	$c++;
	$line = $_;
	chomp $line;
	@temp = split(/\t/,$line);
	$qid = $temp[0];
	$predictionfile = "$prediction_dir/$qid.rank_list";
	$temp_dir_target =  "$temp_dir/${qid}_top5_folds_info";#Jie3-KL-hidden-out/score_ranking_dir/d1ri9a__top5_folds_info/
	if(!(-e $predictionfile))
	{
		die "Failed to find $predictionfile\n";
	}
	
	$outputdir="$outdir/$qid";
	if(-d $outputdir)
	{
		`rm -rf $outputdir/*`;
	}else{
		`mkdir $outputdir`;
	}

	open(IN,"$predictionfile") || die "Failed to open file $predictionfile\n";
	open(OUT,">$outputdir/DeepSF_summary.txt") || die "Failed to open file $outputdir/DeepSF_summary.txt\n";
	@content = <IN>;
	close IN;

	$title = shift @content;
	chomp $title;

	print OUT "$title\tTemplate\tKL\tTemplate_id\tModel_src\tModel_des\tfold_des\tfold_id\tfamily_des\tfamily_id\n";
	$c = 0;
	foreach $line (@content)
	{
		chomp $line;
		$c++;
		if($c >5)
		{
			last;
		}
		@tmp = split(/\t/,$line); #1       b.34    315     0.72448
		$rank = $tmp[0];
		$fold = $tmp[1];
		$KL_fold_file = "$temp_dir_target/fold_$fold";
		open(TMP,"$KL_fold_file") || die "Failed to open file $KL_fold_file\n";
		@content2 = <TMP>;
		close TMP;
		$tem = shift @content2;
		chomp $tem;	
		@tmp2 = split(/\t/,$tem); #d1ri9a_ d1nppa2 49.6640641119938        Unknown b.34
		$tempname = $tmp2[1];
		$KL = $tmp2[2];
		
		$temlabel = $pro2label{$tempname};
		#print "$tem\n";
		$pdbfile = "$temp_dir_target/fold_${fold}_atom/$tempname.pdb";
		if(!(-e $pdbfile))
		{
			die "Couldn't find $pdbfile\n";
		}
		`cp $pdbfile $outputdir/DeepSF_top${rank}_model.pdb`;
		if(exists($fold_class_description{$fold}))
		{
			$des= $fold_class_description{$fold};
			$sid= $fold_class_scopid{$fold};
		}else{
			$des='Not annotated!Report Error!';
			$sid='Not annotated!Report Error!';
		}
		if(exists($family_class_description{$temlabel}))
		{
			$fa_des= $family_class_description{$temlabel};
			$fa_sid= $family_class_scopid{$temlabel};
		}else{
			$fa_des='Not annotated!Report Error!';
			$fa_sid='Not annotated!Report Error!';
		}
		print OUT "$line\t$tempname\t$KL\t$temlabel\t$pdbfile\t$outputdir/DeepSF_top${rank}_model.pdb\t$des\t$sid\t$fa_des\t$fa_sid\n";
	}
	close OUT;
}