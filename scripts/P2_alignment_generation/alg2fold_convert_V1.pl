#!#!/usr/bin/perl -w

#
my $GLOBAL_PATH='/home/casp13/deepsf_3d/Github/test/DeepSF/';

if (@ARGV != 4) {
  print "Usage: <input> <output>\n";
  exit;
}

$fasta = $ARGV[0];
$qid = $ARGV[1];
$infile_aln = $ARGV[2];
$outfile_msa = $ARGV[3];


open(IN1,"$fasta")|| die("Failed to open file $fasta \n");
@content = <IN1>;
close IN1;
shift @content;
$sequence = shift @content;
chomp $sequence;
$pdbfile_aln = "$infile_aln";

$pdbfile_alnmsa = "$outfile_msa";
###### convert global pir to global alignment for visualization on website
open(MSA, ">$pdbfile_alnmsa") || die("Couldn't open file $pdbfile_alnmsa\n"); 
open(IN1, $pdbfile_aln) || die("Couldn't open file $pdbfile_aln\n"); 
@aalignf_tmp=<IN1>;
close IN1;
$c_tmp=0;
$aligntarget_tmp="";
$aligntarget_info="";
foreach $line_tmp (@aalignf_tmp){
	chomp($line_tmp);
	$c_tmp++;
	if ($c_tmp%5==1) {
			$aligntarget_info=$line_tmp;
	}
	if ($c_tmp%5==4) {
		$aligntarget_tmp=$line_tmp;
	}
}
$coverage = 0;
if(index($aligntarget_info,'cover_ratio:')>0)
{
	$coverage = substr($aligntarget_info,index($aligntarget_info,'cover_ratio:')+12,index($aligntarget_info,'cover:')-index($aligntarget_info,'cover_ratio:')-12);
	$coverage =~ s/^\s+|\s+$//g;
}

$seq_length = length($sequence);


#print MSA ">$qid|cov:$coverage\n$aligntarget_tmp\n";
print MSA ">$qid\n$aligntarget_tmp\n";
$id_tmp="";
$start_region="";
$end_region="";
$temp_index=0;
$c_tmp=0;
foreach $line_tmp (@aalignf_tmp){
	chomp($line_tmp);
	$c_tmp++;
	if(index($line_tmp,'C;query_length')>=0)
	{
		last;
	}
	if ($c_tmp%5==2) {
		@temp = split(';',$line_tmp);
		$id_tmp = $temp[1];
		$id_tmp =~ s/\s+//g;
	}
	if ($c_tmp%5==3) {
		@temp = split(':',$line_tmp);
		$start_region = $temp[2];
		$start_region =~ s/^\s+|\s+$//g;
		$end_region = $temp[4];
		$end_region =~ s/^\s+|\s+$//g;
	}
	if ($c_tmp%5==4) {
		if ($id_tmp ne $qid) {
			$aligntemp=$line_tmp;
			$temp_index++;
			print MSA ">$id_tmp|pos:$start_region-$end_region\n$aligntemp\n";
			
			
			($range,$fold_id,$fold_des) = get_align_region_annotation($aligntarget_tmp, $id_tmp, $aligntemp);
			print MARKER "$range\t$fold_id\t$fold_des(alignment: $range)\n";
		}
	}
}
close MSA;



sub get_align_region_annotation{
	my $target_align = shift;
	my $temp_name = shift;
	my $temp_align = shift;
	
	$label="";
	if(substr($target_align,length($target_align)-1) eq '*')
	{
		$target_align = substr($target_align,0,length($target_align)-1);
	}
	if(substr($temp_align,length($temp_align)-1) eq '*')
	{
		$temp_align = substr($temp_align,0,length($temp_align)-1);
	}
	for($i =0;$i<length($target_align);$i++)
	{
		$target_tmp = substr($target_align,$i,1);
		$temp_tmp = substr($temp_align,$i,1);
		if($target_tmp eq '-')
		{
			next;
		}
		
		if($temp_tmp eq '-')
		{
			$label .="0";
		}else{
			$label .= "1";
		}
	}
	
	$start = 0;
	for($i =0;$i<length($label);$i++)
	{
		if(substr($label,$i,1) eq '1')
		{
			$start = $i;
			last;
		}
	}
	$start += 1;
	$end = 0;
	for($i =length($label)-1;$i>=0;$i--)
	{
		if(substr($label,$i,1) eq '1')
		{
			$end = $i;
			last;
		}
	}
	$end += 1;
	

	$fold_description = "$GLOBAL_PATH/database/SCOP/dir.des.scop.1.75_class.txt";
	$trainlist = "$GLOBAL_PATH/database/SCOP/Traindata.list";
	open(IN1,"$fold_description")|| die("Failed to open file $fold_description \n");
	%scop_fold_class_description=();
	while(<IN1>)
	{
		$line=$_;
		chomp $line;
		@array = split(/\s+/,$line);
		$class=$array[2];
		$desc=$array[4];
		$scop_fold_class_description{$class} = $desc;
	}
	close IN1;

	open(IN1,"$trainlist")|| die("Failed to open file $trainlist \n");
	%scop_trainlist=();
	while(<IN1>)
	{
		$line=$_;
		chomp $line;
		@array = split(/\s+/,$line);
		$class=$array[3];
		$protein=$array[0];
		$scop_trainlist{$protein} = $class;
	}
	close IN1;



	$fold_description = "$GLOBAL_PATH/database/ECOD/ECOD_X/ecod.latest.fasta_id90_webinfo.txt";


	open(IN1,"$fold_description")|| die("Failed to open file $fold_description \n");
	%ecod_fold_class_description=();
	%ecod2scopid=();
	%ecod2scopid_v2=();


	while(<IN1>)
	{
		$line=$_;
		chomp $line;
		@array = split(/\t/,$line);
		$scopname=$array[0];
		$scopname2=$array[2];
		
		$classlabel=$array[3]; # X.1.1.1.1
		$descinfo=$array[4]; #ECOD|A: beta barrels|X: cradle loop barrel|H: RIFT-related|T: acid protease|F: A1_Propeptide,Asp
		
		@tmp=split(/\./,$classlabel);
		$class =$tmp[0].'.'. $tmp[1];
		$ecod2scopid{$scopname}=$class;
		$ecod2scopid_v2{$scopname2}=$class;
		
		
		@tmp2=split(/\|/,$descinfo);
		if(@tmp2 <3)
		{
			$desc = 'unknown';
		}else{
			$desc =$tmp2[1].'|'. $tmp2[2];
		}
		
		$ecod_fold_class_description{$class} = $desc;
	}
	close IN1;
	
	$fold_id="";
	$fold_des="";
	if(exists($scop_trainlist{$temp_name}))
	{
		$fid = $scop_trainlist{$temp_name};
		$fold_des = $scop_fold_class_description{$fid};
		$fold_id = $temp_name.'|SCOP:'.$fid ;
	}elsif(exists($ecod2scopid{$temp_name}))
	{
		$fid = $ecod2scopid{$temp_name};
		$fold_des = $ecod_fold_class_description{$fid};
		$fold_id = $temp_name.'|ECOD:'.$fid ;
	}elsif(exists($ecod2scopid_v2{$temp_name}))
	{
		$fid = $ecod2scopid_v2{$temp_name};
		$fold_des = $ecod_fold_class_description{$fid};
		$fold_id = $temp_name.'|ECOD:'.$fid ;
	}else{
		print "Failed to find fold id and des for $temp_name\n";
   $fold_des='Missing';
   $fold_id = $temp_name.'|ECOD:';
   
	}



	
	return ("$start-$end",$fold_id,$fold_des);
}

