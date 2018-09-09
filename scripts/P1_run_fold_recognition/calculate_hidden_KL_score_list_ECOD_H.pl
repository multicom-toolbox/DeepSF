#!#!/usr/bin/perl -w

if (@ARGV != 6) {
  print "Usage: <input> <output>\n";
  exit;
}

$train_file = $ARGV[0];
$runlist = $ARGV[1];
$train_dir = $ARGV[2];
$Testidir  = $ARGV[3]; 
$outdir = $ARGV[4]; 
$pdbname = $ARGV[5]; 


open(IN1,"$runlist")|| die("Failed to open file $runlist \n");

%run_proteinlist = ();
%run_proteinlist_label = ();
while(<IN1>){
	$c++;
	$line = $_;
	chomp $line;
		@temp = split(/\t/,$line);
		$name = $temp[0];
		
		$run_proteinlist{$name} = 1;
		$run_proteinlist_label{$name} = 'Unknown';
	
}
close IN1;



open(IN1,"$train_file")|| die("Failed to open file $train_file \n");
%protein2label=(); 
$c=0;
while(<IN1>){
	$c++;
	$line = $_;
	chomp $line;
		@temp = split(/\t/,$line);
		$name = $temp[0];
		$label = $temp[2];
		
		@tmp3  = split(/\./,$label);
		$class = $tmp3[0].'.'.$tmp3[1].'.'.$tmp3[2]; # a.1
		$protein2label{$name} = $class;
		
	
}
close IN1;


%train_hidden_fea= ();
%train_hidden_fea_label= ();
for $name (keys %protein2label)
{
	$fold = $protein2label{$name};
  $filepath = "$train_dir/$name.hidden_feature";
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
	$train_hidden_fea{"$name"}=$line;
	$train_hidden_fea_label{"$name"}=$fold;
}


$index=0;
for $name (keys %run_proteinlist)
{
  $index++;
  print "Processing $name\n";
	$fold = $run_proteinlist_label{$name};
  $filepath = "$Testidir/$name.hidden_feature";
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
	print "Predict $index:$name\n";
	open(IN,"$filepath") || die "Failed to open file $filepath\n";
	@content = <IN>;
	close IN;
	$test_fea = shift @content;
	chomp $test_fea;
	@test_feas = split(/\t/,$test_fea);
	if(@test_feas!=1500)
	{
		die "The number of prediciton is not correct ".@tmp2."\n";
	}
	#$testname = "${fold}_$name"; # let 0 equal test
	
	%check_list_KL = ();
	%check_list_score1 = ();
	%check_list_score2 = ();
	%check_list_score3 = ();
	$Hidden_vector = [];
	$c1 = 0;
	foreach $l (@test_feas)
	{
		chomp $l;
		$c1++;
		$Hidden_vector->[$c1][1]= $l;
	}
	foreach $train_pro (keys %train_hidden_fea)
	{
     if($train_pro eq $name ) # this is used for evaluatin, if testing, comment it
     {
       #next;
     }
		$train_fea = $train_hidden_fea{$train_pro};
		@train_feas = split(/\t/,$train_fea);
		$c2 = 0;
		foreach $l (@train_feas)
		{
			chomp $l;
			$c2++;
			$Hidden_vector->[$c2][2]= $l;
		}
		
		# calculation pearson correlation score  log(1-corr(F_i-F_j))
		$correlation = correlation($Hidden_vector);
		$corr_score1 = log10(1-$correlation);
		
		# calculation normalized absolute diff  (\Sigma(F_i-F_j)/\SigmaF_i)
		$Score2 = ScoreFunction2($Hidden_vector);
		
		# calculation eclidean diff  (\Sigma(F_i-F_j)^2
		$Score3 = ScoreFunction3($Hidden_vector);
		
		# calculation  KL
		$check_list_KL{$name."\t".$train_pro}= KL_calc($train_fea,$test_fea);
		$check_list_score1{$name."\t".$train_pro}= $corr_score1;
		$check_list_score2{$name."\t".$train_pro}= $Score2;
		$check_list_score3{$name."\t".$train_pro}= $Score3;
	}
	
	open(OUT1,">$outdir/$name.KL_output")|| die("Failed to open file $name \n");
	foreach $it (sort { $check_list_KL{$a} <=> $check_list_KL{$b} } keys %check_list_KL)
	{
		@contents = split(/\t/,$it);
		$testname_id = $contents[0];
		$train_pro_id = $contents[1];
		if(!exists($run_proteinlist_label{$testname_id}))
		{
			die "$testname_id} not found in $runlist\n";
		}
		if(!exists($train_hidden_fea_label{$train_pro_id}))
		{
			die "$train_pro_id} not found in $train_file\n";
		}
		print OUT1 "$it\t".$check_list_KL{$it}."\t".$run_proteinlist_label{$testname_id}."\t".$train_hidden_fea_label{$train_pro_id}."\n";
	}
	close OUT1;
	
	
}
`touch $outdir/${pdbname}_KL_calc.done`;

## for Discrete Probability Distribution
## considering that sum of probability values in both arrays equals to

sub KL_calc{
	my ($train_feature,$test_feature) = (@_);
	my $dist = 0;
	@train_fea = split(/\t/,$train_feature);
	@test_fea = split(/\t/,$test_feature);
	if((scalar(@train_fea) != scalar(@test_fea) ) ){
		print " The size should be same \n";
		exit;
	}
	else{
		for(my $i = 0; $i<= $#test_fea; $i++){
			my $temp = 0 if($test_fea[$i] == 0 || $train_fea[$i] == 0);
			$temp = ($test_fea[$i]*log($test_fea[$i]/$train_fea[$i]) + $train_fea[$i]*log($train_fea[$i]/$test_fea[$i]))/2 if($test_fea[$i] != 0 && $train_fea[$i] != 0); 
			$dist = $dist + $temp;
		}
	}
	return $dist;
	
}


sub mean {
   my ($x)=@_;
   my $num = scalar(@{$x}) - 1;
   my $sum_x = '0';
   my $sum_y = '0';
   for (my $i = 1; $i < scalar(@{$x}); $i++){
      $sum_x += $x->[$i][1];
      $sum_y += $x->[$i][2];
   }
   my $mu_x = $sum_x / $num;
   my $mu_y = $sum_y / $num;
   return($mu_x,$mu_y);
}
 
### ss = sum of squared deviations to the mean
sub ss {
   my ($x,$mean_x,$mean_y,$one,$two)=@_;
   my $sum = '0';
   #print $x->[1][$one]."\n";
   for (my $i = 1; $i < scalar(@{$x}); $i++){
     $sum += ($x->[$i][$one]-$mean_x)*($x->[$i][$two]-$mean_y);
   }
   return $sum;
}
 
 
sub correlation {
   my ($x) = @_;
   my ($mean_x,$mean_y) = mean($x);
   my $ssxx=ss($x,$mean_x,$mean_x,1,1);
   my $ssyy=ss($x,$mean_y,$mean_y,2,2);
   my $ssxy=ss($x,$mean_x,$mean_y,1,2);
   my $correl=correl($ssxx,$ssyy,$ssxy);
   my $xcorrel=sprintf("%.6f",$correl);
   return($xcorrel);
 
}
 
sub correl {
   my($ssxx,$ssyy,$ssxy)=@_;
   my $sign=$ssxy/abs($ssxy);
   #print "ssxy --> $ssxy \n";
   #print "ssxx --> $ssxx \n";
   #print "ssyy --> $ssyy \n";
   my $correl=$sign*sqrt($ssxy*$ssxy/($ssxx*$ssyy));
   return $correl;
}



sub ScoreFunction2 {
   my ($x) = @_;
   my $sum_dev = '0';
   my $sum_query = '0';
   for (my $i = 1; $i < scalar(@{$x}); $i++){
	 $term1  = ($x->[$i][1]-$x->[$i][2]); # query - template
	 $term2  = ($x->[$i][1]); # query 
     $sum_dev += abs($term1);
     $sum_query += abs($term2);
   }
   my $score = $sum_dev / $sum_query;
   my $xscore = sprintf("%.6f",$score);
   return $xscore;
}


sub ScoreFunction3 {
   my ($x) = @_;
   my $sum_query = '0';
   for (my $i = 1; $i < scalar(@{$x}); $i++){
	 $term1  = ($x->[$i][1]-$x->[$i][2]); # query - template
     $sum_query += abs($term1) * abs($term1);
   }
   my $score = $sum_query;
   my $xscore = sprintf("%.6f",$score);
   return $xscore;
}


sub log10 {
	my $n = shift;
	if($n == 0)
	{
		$n = $n + 0.0001;
	}
	return log($n)/log(10);
}
