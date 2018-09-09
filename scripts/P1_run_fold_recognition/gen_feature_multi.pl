#!/usr/bin/perl -w

if (@ARGV !=5) {
  print "Usage: <input> <output>\n";
  exit;
}

$fasta_file = $ARGV[0];
$output_dir = $ARGV[1]; # use abs address
$outputfile = $ARGV[2]; # 
$GLOBAL_PATH = $ARGV[3]; #
$SCRATCH_tools = $ARGV[4]; #
$core_num = 4;
print "##################  Start generating features for $fasta_file #############\n";
if (! -f $fasta_file)
{
	die "can't find file: $fasta_file.\n"; 
}

if ( substr($output_dir, length($output_dir) - 1, 1) ne "/" )
{
	$output_dir .= "/"; 
}

#extract sequence file name
$slash_pos = rindex($fasta_file, "/");
if ($slash_pos != -1)
{
	$seq_filename = substr($fasta_file, $slash_pos + 1, length($fasta_file) - $slash_pos - 1); 
}
else
{
	$seq_filename = $fasta_file; 
}
if (length($seq_filename) <= 0)
{
	die "sequence file name shouldn't be less or equal 0.\n"; 
}

#non-char and . is not allowed for ouput file name 
$seq_filename =~ s/\s/_/g; 
#$seq_filename =~ s/\./_/g;  



if(!-d $output_dir)
{
	die "$output_dir doesn't exists\n";

}
%seqname2foldclass = ();
%seqname2seq = ();

print "##################  Start open file $fasta_file #############\n";
open(SEQ_FILE, "$fasta_file") || die "can't open sequence file $fasta_file.\n";
@content = <SEQ_FILE>;
close(SEQ_FILE);
foreach $line (@content)
{
	chomp $line;
	if(length($line)<1)
	{
		die "no content in line \n";
		exit;
	}
	if(substr($line,0,1) eq '>')
	{
		$fold_class="";
		if(rindex($line, "|") != -1)
		{
			@tmp = split(/\|/,$line);
			$seq_name = $tmp[0];
			if(substr($seq_name,0,1) eq '>')
			{
				$seq_name=substr($seq_name,1);
			}
			$fold_class = $tmp[1];
		}else{
			@tmpf = split(/\t/,$line);
			$seq_name = $tmpf[0];
			if(substr($seq_name,0,1) eq '>')
			{
				$seq_name=substr($seq_name,1);
			}
			$fold_class = 'N';
		}
		if(!exists($seqname2foldclass{$seq_name}))
		{
			$seqname2foldclass{$seq_name} = $fold_class;
		}else{
			die "Duplicate name of <$seq_name> in seqname2foldclass\n";
			exit;
		}
	}else{
		if(!exists($seqname2seq{$seq_name}))
		{
			$seqname2seq{$seq_name} = $line;
		}else{
			die "Duplicate name of <$seq_name> in seqname2seq\n";
			exit;
		}
	}
}

@seqarray = keys %seqname2seq;
print "Total number of sequences: ". @seqarray."\n";
foreach $item (@seqarray)
{
	chomp $item;
	$new_dir = $output_dir.'/'.$item;
	if(-d $new_dir)
	{
		system("rm -rf $new_dir");
		system("mkdir $new_dir");
	}else{
		system("mkdir $new_dir");
	}
}
### Start predicting SS and SA by calling run_SCRATCH-1D_predictors.sh
print "###########################  Start predicting SS and AA #############################\n";
$SCRATCH_output = $output_dir.$seq_filename;
print "$SCRATCH_tools/bin/run_SCRATCH-1D_predictors.sh $fasta_file $SCRATCH_output $core_num \n";
$status = system("$SCRATCH_tools/bin/run_SCRATCH-1D_predictors.sh $fasta_file $SCRATCH_output $core_num ");
if($status)
{
	die "Failed to run run_SCRATCH-1D_predictors.sh \n";
}

$ss_output = $SCRATCH_output.'.ss';
if(!-e $ss_output)
{
	die "File $ss_output didn't exist \n";
}else{
	print "File $ss_output  found \n";
}

open(FILE,$ss_output) || die "Failed to open file $ss_output\n";
while(<FILE>)
{
	$line=$_;
	chomp $line;
	if(substr($line,0,1) eq '>')
	{
		if(rindex($line, "|") != -1)
		{
			@tmp = split(/\|/,$line);
			$seq_name = $tmp[0];
			if(substr($seq_name,0,1) eq '>')
			{
				$seq_name=substr($seq_name,1);
			}
		}else{
			$seq_name = $line;
			if(substr($seq_name,0,1) eq '>')
			{
				$seq_name=substr($seq_name,1);
			}
		}
		$dir_check = $output_dir.'/'.$seq_name;
		if(-d $dir_check)
		{
			$seq_ss_output = $dir_check.'/'. $seq_name.'.ss';
			open(OUT,">$seq_ss_output") || die "Failed to write to $seq_ss_output\n";
			print OUT $seq_name."\n";
		}else{
			die "<$dir_check> doesn't exists!\n";
			exit;
		}
	}else{
		print OUT $line."\n";
		close OUT;
	}
}
close FILE;

$sa_output = $SCRATCH_output.'.acc';
if(!-e $sa_output)
{
	die "File $sa_output didn't exist \n";
}else{
	print "File $sa_output  found \n";
}

open(FILE,$sa_output) || die "Failed to open file $sa_output\n";
while(<FILE>)
{
	$line=$_;
	chomp $line;
	if(substr($line,0,1) eq '>')
	{
		if(rindex($line, "|") != -1)
		{
			@tmp = split(/\|/,$line);
			$seq_name = $tmp[0];
			if(substr($seq_name,0,1) eq '>')
			{
				$seq_name=substr($seq_name,1);
			}
		}else{
			$seq_name = $line;
			if(substr($seq_name,0,1) eq '>')
			{
				$seq_name=substr($seq_name,1);
			}
		}
		$dir_check = $output_dir.'/'.$seq_name;
		if(-d $dir_check)
		{
			$seq_sa_output = $dir_check.'/'. $seq_name.'.acc';
			open(OUT,">$seq_sa_output") || die "Failed to write to $seq_sa_output\n";
			print OUT $seq_name."\n";
		}else{
			die "<$dir_check> doesn't exists!\n";
			exit;
		}
	}else{
		print OUT $line."\n";
		close OUT;
	}
}
close FILE;


open(FILE,$fasta_file) || die "Failed to open file $fasta_file\n";
while(<FILE>)
{
	$line=$_;
	chomp $line;
	if(substr($line,0,1) eq '>')
	{
		if(rindex($line, "|") != -1)
		{
			@tmp = split(/\|/,$line);
			$seq_name = $tmp[0];
			if(substr($seq_name,0,1) eq '>')
			{
				$seq_name=substr($seq_name,1);
			}
		}else{
			$seq_name = $line;
			if(substr($seq_name,0,1) eq '>')
			{
				$seq_name=substr($seq_name,1);
			}
		}
		$dir_check = $output_dir.'/'.$seq_name;
		if(-d $dir_check)
		{
			$seq_file_output = $dir_check.'/'. $seq_name;
			open(OUT,">$seq_file_output") || die "Failed to write to $seq_file_output\n";
			print OUT $line."\n";
		}else{
			die "<$dir_check> doesn't exists!\n";
			exit;
		}
	}else{
		print OUT $line."\n";
		close OUT;
	}
}
close FILE;

foreach $item (@seqarray)
{
	chomp $item;
	$new_dir = $output_dir.'/'.$item;
	if(-d $new_dir)
	{
		print "Start processing $item\n"
	}else{
		die "<$new_dir> doesn't exists!\n";
		exit;
	}
	
	### Start encoding SS
	$ss_output1 = $new_dir.'/'.$item.'.ss';
	$fasta_file1 = $new_dir.'/'.$item;
	print "###########################  Start encoding SS #############################\n";
	print "perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/encoding_ss.pl $fasta_file1 $ss_output1 \n";
	$status = system("perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/encoding_ss.pl $fasta_file1 $ss_output1 ");
	if($status)
	{
		die "Failed to run run_SCRATCH-1D_predictors.sh \n";
	}
	### Start encoding SA
	$sa_output1 = $new_dir.'/'.$item.'.acc';
	print "###########################  Start encoding SA #############################\n";

	print "perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/encoding_acc.pl $fasta_file1 $sa_output1 \n";
	$status = system("perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/encoding_acc.pl $fasta_file1 $sa_output1 ");
	if($status)
	{
		die "Failed to run predict_acc.sh \n";
	}
	
	$fold_class1 = $seqname2foldclass{$item};
	$sequence1 = $seqname2seq{$item};
	print "The sequence class is $fold_class1\n";
	print "The sequence  is $sequence1\n";
	$sequence_length = length($sequence1);
	$feature_num = $sequence_length*25;
	print "The sequence length is $sequence_length and the feature number is: $feature_num \n";
	### Start encoding AA
	print "###########################  Start encoding AA #############################\n";
	print "perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/gen_encoding.pl $fasta_file1 $new_dir \n";
	$status = system("perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/gen_encoding.pl $fasta_file1 $new_dir");
	if($status)
	{
		die "Failed to run gen_encoding.pl \n";
	}
	print "###########################  Start parsing results #############################\n";
		
	$aaencoding = $new_dir.'/'.$item.'.aaencoding';
	$ssencoding = $ss_output1.'.ssencoding';
	$saencoding = $sa_output1.'.saencoding';

	if(!-e $aaencoding)
	{
		die "File $aaencoding didn't exist \n";
	}else{
		print "File $aaencoding  found \n";
	}
	if(!-e $ssencoding)
	{
		die "File $ssencoding didn't exist \n";
	}else{
		print "File $ssencoding  found \n";
	}
	if(!-e $saencoding)
	{
		die "File $saencoding didn't exist \n";
	}else{
		print "File $saencoding  found \n";
	}

	%seq_feature = ();
	open(FILE,$aaencoding) || die "Failed to open file $aaencoding\n";
	while(<FILE>)
	{
		$line=$_;
		chomp $line;
		@temp = split(/\t/,$line);
		$res = $temp[0];
		$encoding = $temp[1];
		if(exists($seq_feature{$res}))
		{
			die "$res duplicated in file $aaencoding\n";
		}else{
			$seq_feature{$res} = $encoding;
		}
	}
	close FILE;

	open(FILE,$ssencoding) || die "Failed to open file $ssencoding\n"; 
	while(<FILE>)
	{
		$line=$_;
		chomp $line;
		@temp = split(/\t/,$line);
		$res = $temp[0];
		$encoding = $temp[1];
		if(exists($seq_feature{$res}))
		{
			$seq_feature{$res} = $seq_feature{$res}." ".$encoding;
		}else{
			die "$res not added in file $ssencoding\n";
		}
	}
	close FILE;

	open(FILE,$saencoding) || die "Failed to open file $saencoding\n";
	while(<FILE>)
	{
		$line=$_;
		chomp $line;
		@temp = split(/\t/,$line);
		$res = $temp[0];
		$encoding = $temp[1];
		if(exists($seq_feature{$res}))
		{
			$seq_feature{$res} = $seq_feature{$res}." ".$encoding;
		}else{
			die "$res not added in file $saencoding\n";
		}
	}
	close FILE;

	%aa_order = ();
	%aa_order_encode = ();
	foreach $item (sort keys %seq_feature)
	{
		@tmp = split(':',$item);
		$id = $tmp[0];
		$res = $tmp[1];
		if(exists($aa_order{$id}))
		{
			die "$id duplicated in file seq_feature hash\n";
		}else{
			$aa_order{$id} = $res;
		}
		
		if(exists($aa_order_encode{$id}))
		{
			die "$id duplicated in file seq_feature hash\n";
		}else{
			$aa_order_encode{$id} = $seq_feature{$item};
		}
		
	}
	$seq="";
	$seq_feature="";
	foreach $num (sort {$a<=>$b} keys %aa_order )
	{
		#print "Residue $num \n";
		$seq .=$aa_order{$num};
		$seq_feature .=$aa_order_encode{$num}.' ';
	}
	#remove last space
	$seq_feature = substr($seq_feature,0,length($seq_feature)-1);
	@temp = split(/\s/,$seq_feature);
	$seq_name = $item;
	if($feature_num eq @temp)
	{
		print $seq_name." feature generated\n";
	}else{
		print $seq_name." feature not match\n";
		die;
	}
	$c = 0;
	$seq_feature_new ="";
	foreach $item (@temp)
	{
		$seq_feature_new .=($c+1).":". $item." ";
		$c++;
	}
	#remove last space
	$seq_feature_new = substr($seq_feature_new,0,length($seq_feature_new)-1);
	#print "The sequence is: \n$seq\n";
	#print "The feature of sequence is: \n$seq_name\n$fold_class\t$seq_feature_new\n";
	$outputfile_tmp = $new_dir.'/'.$item.'.feature';
	$outputfile_tmp2 = $output_dir.'/'.$item.'.feature';
	open(OUT,">$outputfile_tmp") || die "Failed to open file $outputfile_tmp\n";
	open(OUT2,">$outputfile_tmp2") || die "Failed to open file $outputfile_tmp2\n";
	print OUT ">$seq_name\n$fold_class1\t$seq_feature_new\n";
	print OUT2 ">$seq_name\n$fold_class1\t$seq_feature_new\n";
	close OUT;
	close OUT2;
}

$status = system("cat $output_dir/*.feature > $outputfile");
if($status)
{
	die "Failed to cat $output_dir/*.feature > $outputfile \n ";
}




