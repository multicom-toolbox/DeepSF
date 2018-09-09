
if (@ARGV != 8)
{
	die "need four parameters: input sequence file, given sequence folder, folder of TM-score files and center template file, resulting file of multiple structural alignment of templates!\n"."For example:  /storage/homes/xd9d3/MSA_3D_project/tool/promals_structure_MSA/test/T0515/T0515.fasta /storage/homes/xd9d3/MSA_3D_project/tool/promals_structure_MSA/test/T0515_templates/ /storage/homes/xd9d3/MSA_3D_project/tool/promals_structure_MSA/test/T0515_align/ /storage/homes/xd9d3/MSA_3D_project/tool/promals_structure_MSA/test/T0515_template.msa\n";
}	 

$template_file = shift @ARGV; #
$fd = shift @ARGV; #
$qid  = shift @ARGV; #
$prefix = shift @ARGV; # SCOP, ECOD_X
$align_file = shift @ARGV; #T0859.pir.lob 
$outdir = shift @ARGV; #$task_dir/$jobname-alignment/$qid/hhalign
$method = shift @ARGV; #hhalign
$GLOBAL_PATH = shift @ARGV; #


$aln_summary = "$outdir/${prefix}_fold_${fd}_top10_$method.pir";
$aln_summary_msa = "$outdir/${prefix}_fold_${fd}_top10_$method.msa";
$aln_summary_list = "$outdir/${prefix}_fold_${fd}_top10.list";
$aln_summary_dir = "$outdir/${prefix}_fold_${fd}_top10_pir_dir";

`mkdir $aln_summary_dir`;

$tmpdir = "$outdir/tmp";
if(-d "$tmpdir")
{
	`rm $tmpdir/*`;
}else{
	`mkdir $tmpdir`;
}

open(ALIGN, $align_file) || die "can't read profile-profile alignment file.\n"; 
@align = <ALIGN>;
close ALIGN;
@candidate_temps = (); 
while (@align)
{
	#read alignments for one template	
	$title = shift @align;
	@group = ();
	while (@align)
	{
		$line = shift @align;
		if ($line =~ /=====/)
		{
			shift @align;
			#shift @group; 
			pop @group; 
			last;	
		}
		else
		{
			push @group, $line;
		}
	}
	#create  a pir alignment file for the template
	($rank, $tname, $score) = split(/\s+/, $title);
	$temp_pir_file = "$tmpdir/$tname.pir";
	open(TEMP, ">$temp_pir_file") || die "can't create pir file for $tname.\n";
	print TEMP join("", @group);
	close TEMP; 
	push @candidate_temps, $temp_pir_file; 
}


open(ALNLIST,">$aln_summary_list");
open(TMPIN2,"$template_file");
$tmp_num=0;
$aln_num=0;
$aln_for_model_num=0;


while(<TMPIN2>)
{
	$line2=$_;
	chomp $line2;
	@tmp2 = split(/\t/,$line2);
	$qid_query = $tmp2[0];
	$qid_target = $tmp2[1];
	if($qid ne $qid_query)
	{
		print "${prefix} id: $qid ne $qid_query\n\n";
	}
	$aln_file = "$tmpdir/$qid_target.pir";
	if(!(-e $aln_file))
	{
		print "Failed to find $aln_file\n";
		next;
	}
	
	$tmp_num++;
	if($tmp_num >10) # at most 10 templates for each fold
	{
		last;
	}
	
	$tpdb="";
	$tpdb1 = "$GLOBAL_PATH/database/SCOP/SCOP_template_PDB/pdb/$qid_target.atom";
	$tpdb2 = "$GLOBAL_PATH/database/ECOD/ECOD_template_PDB/pdb/$qid_target.atom";
	$tpdb3 = "$GLOBAL_PATH/database/ECOD/ECOD_template_PDB/pdb/$qid_target.atom";
	if(-e $tpdb1)
	{
		$tpdb = $tpdb1;
	}elsif(-e $tpdb2)
	{
		$tpdb = $tpdb2;
	}elsif(-e $tpdb3)
	{
		$tpdb = $tpdb3;
	}else
	{
		die "couldn't find $tpdb1 or  $tpdb2 or  $tpdb3 \n";
	}
	
	
	print ALNLIST "$qid_target\n";
	`cp $aln_file $aln_summary_dir`;
	$aln_num++;
	open(IN1, $aln_file) || die("Couldn't open file $aln_file\n"); 
	@aalignf_tmp=<IN1>;
	close IN1;
	$c_tmp=0;
	$aligntarget_info="";
	foreach $line_tmp (@aalignf_tmp){
		chomp($line_tmp);
		$c_tmp++;
		if ($c_tmp%5==1) {
			$aligntarget_info=$line_tmp;
		}
	}
	$coverage = 1;
	if(index($aligntarget_info,'cover_ratio:')>0)
	{
		$coverage = substr($aligntarget_info,index($aligntarget_info,'cover_ratio:')+12,index($aligntarget_info,'cover:')-index($aligntarget_info,'cover_ratio:')-12);
		$coverage =~ s/^\s+|\s+$//g;
		if($coverage <= 0.2)
		{
			#print "The coverage for ${qid_query}_$qid_target.pir is $coverage, pass\n";
		}
	}
	
}
close TMPIN2;
close ALNLIST;

## convert multiple pir into global pir 
if($aln_num>0)
{
	`perl $GLOBAL_PATH/scripts/P2_alignment_generation/pair2msa.pl $aln_summary_list $aln_summary_dir $aln_summary $qid`;
	`rm -rf $aln_summary_dir`;
}else{
	`rm -rf $aln_summary_dir`;
	exit;
}



###### convert global pir to global alignment for visualization on website
open(MSA, ">$aln_summary_msa") || die("Couldn't open file $aln_summary_msa\n"); 
open(IN1, $aln_summary) || die("Couldn't open file $aln_summary\n"); 
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
$coverage = 0;# this is not the global msa coverage
if(index($aligntarget_info,'cover_ratio:')>0)
{
	$coverage = substr($aligntarget_info,index($aligntarget_info,'cover_ratio:')+12,index($aligntarget_info,'cover:')-index($aligntarget_info,'cover_ratio:')-12);
	$coverage =~ s/^\s+|\s+$//g;
}
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
			
		}
	}
}
close MSA;


`rm $outdir/*list`;