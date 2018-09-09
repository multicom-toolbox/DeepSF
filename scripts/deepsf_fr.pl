#!/usr/bin/perl
##############################################################################
#The main control script of Fold Recognition using both simple and advanced 
#combination of alignments. 
##############################################################################
use Cwd 'abs_path';
use Carp;
use POSIX;
use File::Basename;
use LWP::UserAgent;
use Time::Piece;

$fold_recognition_only = "no";
if (@ARGV < 3)
{
	die "need 3 parameters: fr option file, query file(fasta), output dir.\n"; 
}

$option_file = shift @ARGV;
$query_file = shift @ARGV;
$out_dir = shift @ARGV;
$fold_recognition_only = shift @ARGV;

if($fold_recognition_only ne 'no')
{
	$fold_recognition_only = 'yes';
	print "Setting to fold recognition only mode\n\n";
}
if(!(-d $out_dir))
{
	`mkdir $out_dir`;
}
-f $option_file || die "option file doesn't exist.\n";
-f $query_file || die "query file doesn't exist.\n";
-d $out_dir || die "output dir doesn't exist.\n";

chdir($out_dir);
#read fasta file
open(QUERY, $query_file) || die "can't read query file.\n";
$qname = <QUERY>;
close QUERY;
if ($qname =~ />(\S+)/)
{
	$qname = $1;
}
else
{
	die "query is not in fasta format.\n";
}

#read option file

#total number of templates to select.
#correspond to fr_temp_select_num option.
$top_num  = 10;  

#number of structure to generate
$fr_stx_num = 5; 

#minimum cover size for a template to be used in alignment combination
$fr_min_cover_size = 20;

#maximum gap size to stop using more templates in alignment combination
$fr_gap_stop_size = 20; 

#maximum linker size added to the ends of segments of filling gaps.
$fr_max_linker_size=10;

#alignment combination method
$fr_align_comb_method="advanced";

$adv_comb_join_max_size = -1; 

#options for sorting local alignments
$sort_svm_rank = "no";
$sort_svm_delta_rvalue = 0.01;
$sort_svm_delta_resolution = 2;
$fr_add_stx_info_rm_identical = "no";
$fr_rm_identical_resolution = 2;

$thread_num = 1;

open(OPTION, $option_file) || die "can't read option file.\n";
@options = <OPTION>;
close OPTION;
foreach $line (@options)
{
	if ($line =~ /^GLOBAL_PATH\s*=\s*(\S+)/)
	{
		$GLOBAL_PATH = $1; 
	}
	if ($line =~ /^deepsf_dir\s*=\s*(\S+)/)
	{
		$deepsf_dir = $1; 
	}
	if ($line =~ /^prosys_dir\s*=\s*(\S+)/)
	{
		$prosys_dir = $1; 
	}
	if ($line =~ /^fr_template_lib_file\s*=\s*(\S+)/)
	{
		$fr_template_lib_file = $1; 
	}
	if ($line =~ /^modeller_dir\s*=\s*(\S+)/)
	{
		$modeller_dir = $1; 
	}
	if ($line =~ /^atom_dir\s*=\s*(\S+)/)
	{
		$atom_dir = $1; 
	}
	if ($line =~ /^new_hhsearch_dir\s*=\s*(\S+)/)
	{
		$new_hhsearch_dir = $1; 
	}
	if ($line =~ /^psipred_dir\s*=\s*(\S+)/)
	{
		$psipred_dir = $1; 
	}
	if ($line =~ /^num_model_simulate\s*=\s*(\S+)/)
	{
		$num_model_simulate = $1; 
	}
	if ($line =~ /^fr_temp_select_num\s*=\s*(\S+)/)
	{
		$top_num = $1; 
	}
	if ($line =~ /^fr_stx_num\s*=\s*(\S+)/)
	{
		$fr_stx_num = $1; 
	}
	if ($line =~ /^fr_min_cover_size\s*=\s*(\S+)/)
	{
		$fr_min_cover_size = $1; 
	}
	if ($line =~ /^fr_gap_stop_size\s*=\s*(\S+)/)
	{
		$fr_min_cover_size = $1; 
	}
	if ($line =~ /^fr_max_linker_size\s*=\s*(\S+)/)
	{
		$fr_max_linker_size = $1; 
	}
	if ($line =~ /^fr_align_comb_method\s*=\s*(\S+)/)
	{
		$fr_align_comb_method = $1; 
	}
	if ($line =~ /^adv_comb_join_max_size\s*=\s*(\S+)/)
	{
		$adv_comb_join_max_size = $1; 
	}
	
	if ($line =~ /^thread_num\s*=\s*(\S+)/)
	{
		$thread_num = $1;
	}
}
-d $prosys_dir || die "prosys dir doesn't exist.\n";
-d $modeller_dir || die "modeller dir doesn't exist.\n";
-f $fr_template_lib_file || die "fold recognition template library file doesn't exist.\n";
$num_model_simulate > 0 || die "modeller number of models to simulate should be bigger than 0.\n";

-d $new_hhsearch_dir || die "can't find new hhsearch dir.\n";
-d $psipred_dir || die "can't find $psipred_dir.\n";

$top_num > 0 || die "number of templates to select must be > 0\n";
$fr_stx_num > 0 && $fr_stx_num <= $top_num || die "number of stx to generate must be <= template number.\n";
$fr_min_cover_size > 0 || die "fr: minimum gap cover size must be > 0\n";
$fr_gap_stop_size > 0 || die "fr: gap stop size must be  > 0\n";
$fr_max_linker_size >= 0 || die "fr: gap stop size must be  >= 0\n";


#generate required query files.
print "generate query related files...\n";
#query dir must use absolute path
$cur_dir = `pwd`;
chomp $cur_dir;
if (substr($out_dir, 0, 1) eq "/")
{
	$query_dir = $out_dir;
}
else
{
	if (substr($out_dir, 0, 2) eq "./")
	{
		$query_dir = "$cur_dir/" . substr($out_dir,2);
	}
	else
	{
		$query_dir = "$cur_dir/" . $out_dir; 
	}
}
print "query (output) dir = $query_dir\n";


$start_time = time();


`mkdir -p $out_dir` if not -d $out_dir;
`cp $query_file $out_dir/$id.fasta`;

my $fasta_file = "$out_dir/$id.fasta";
print "\n";
print "Input: $fasta_file\n";
print "L    : ".length(seq_fasta($fasta_file))."\n";
print "Seq  : ".seq_fasta($fasta_file)."\n\n";


my $id = $qname;#C00165

$out_dir = abs_path($out_dir);
chdir $out_dir or confess $!;
my $fastacontent = seq_fasta($fasta_file);


$outdir_stage1 = "$out_dir/deepsf_stage1";
if(!(-d $outdir_stage1))
{
	`mkdir -p $outdir_stage1`;
}


########################################
#goto TEST;
########################################
#goto FOLD_RECOG;
#goto SUMMARY;
#system("/home/casp13/deepsf_3d/scripts/P0_prepare_features/gen_query_files.pl $option_file $query_file $query_dir");
print("$deepsf_dir/P0_prepare_features/gen_query_files.pl $option_file $query_file $query_dir\n\n");
system("$deepsf_dir/P0_prepare_features/gen_query_files.pl $option_file $query_file $query_dir");
print "done.\n";

########################################################################### 
#Generate secondary structure using PSI-PRED
$cur_dir = `pwd`;
chomp $cur_dir;
chdir $query_dir;
#print("$prosys_dir/script/hhsearch_align_prepare.pl $prosys_dir $new_hhsearch_dir $psipred_dir $qname.fas $qname.shhm\n");
#/home/casp13/MULTICOM_package/software/prosys/script/
print("$deepsf_dir/P0_prepare_features/hhsearch_align_prepare.pl $prosys_dir $new_hhsearch_dir $psipred_dir $qname.fas $qname.shhm");
system("$deepsf_dir/P0_prepare_features/hhsearch_align_prepare.pl $prosys_dir $new_hhsearch_dir $psipred_dir $qname.fas $qname.shhm");
chdir $cur_dir;
###########################################################################

FOLD_RECOG:
##################################################   start stage1 fold prediction

my $datetarget = localtime->strftime('%Y-%m-%d-%H-%M-%S');
print "DeepSF job id is $id-$datetarget\n";

$jobname ="$id";
$job_identifier = "$datetarget";
$sequence = "$fastacontent";
$email = "jh7x3\@mail.missouri.edu";

$server_name = 'DeepSF'; 
$pid = $$;
$query_file_new = "$outdir_stage1/$pid";
$now = time;
$ora=localtime;
#$currentID = $now.$$;
$currentID = 'results';
system("cp $fasta_file $outdir_stage1/$id.fasta");
$fasta_file = "$outdir_stage1/$id.fasta";

open(TMP,">$query_file_new");
print TMP "$server_name\n";
print TMP "$jobname\n";
print TMP "$email\n";
print TMP "$currentID\n";
print TMP ("res".$currentID.".res\n");
print TMP ($outdir_stage1."\n");
print TMP "$now\n";
print TMP "$fasta_file\n";
print TMP "$job_identifier\n";
close TMP;


$scop_rank = "$outdir_stage1/$jobname-predict-out/${qname}.rank_list";
$ecos_x_rank = "$outdir_stage1/$jobname-predict-out-ECOD_X/${qname}.rank_list";
$ecod_h_rank = "$outdir_stage1/$jobname-predict-out-ECOD_H/${qname}.rank_list";
if(!(-e $scop_rank) or !(-e $ecos_x_rank) or !(-e $ecod_h_rank))
{
	print("perl  $deepsf_dir/P1_run_fold_recognition/run_DeepSF_fr.pl  $query_file_new\n");
	system("perl  $deepsf_dir/P1_run_fold_recognition/run_DeepSF_fr.pl  $query_file_new");
}

`cp $outdir_stage1/$jobname-predict-out/${qname}.rank_list $query_dir/fold_rank_list.SCOP`;
`cp $outdir_stage1/$jobname-predict-out-ECOD_X/${qname}.rank_list $query_dir/fold_rank_list.ECOD_X`;
`cp $outdir_stage1/$jobname-predict-out-ECOD_H/${qname}.rank_list $query_dir/fold_rank_list.ECOD_H`;

print "\nThe ranking of top SCOP folds are saved in $query_dir/fold_rank_list.SCOP\n";
print "The ranking of top ECOD_X folds are saved in $query_dir/fold_rank_list.ECOD_X\n";
print "The ranking of top ECOD_H folds are saved in $query_dir/fold_rank_list.ECOD_H\n\n";

if($fold_recognition_only eq 'yes')
{
	print "DeepSF fold recognition is finished\n\n";
	exit;
}

$rank_file = "$outdir_stage1/template_rank_summary/$qname.rank";

#################################################################################
#generate profile-profile alignments between query and templates. 

ALIGN_GEN:

$top_num = 300;
print "generate profile-profile alignments for top $top_num templates...\n";
open(RANK, $rank_file) || die "can't read ranked templates file.\n";
@rank = <RANK>;
close RANK;

######## check if all templates have features, if not, need regenerate

#read template library
%lib = (); 
open(LIB, $fr_template_lib_file) || die "can't read library file.\n"; 
@entries = <LIB>;
close LIB; 
while (@entries)
{
	$tname = shift @entries;	
	$tseq = shift @entries;
	chomp $tseq; 
	if ($tname =~ />(\S+)/)
	{
		$tname = $1; 
	}
	else
	{
		die "library file is not in fasta format.\n";
	}
	if (!exists $lib{$tname})
	{
		$lib{$tname} = $tseq; 
	}
	else
	{
		die "library file includes redundant entries: $tname.\n"; 
	}
}




#decide how many templates to select
$select_file = "$query_dir/$qname.all.sel";
$select_file_complete = "$query_dir/$qname.complete.sel";
$select_file_incomplete = "$query_dir/${qname}_incomplete.fasta";
$select_file_hhm = "$query_dir/$qname.hhm.sel";

#### check two times

for($rep=1;$rep<=2;$rep++)
{
	open(SEL, ">$select_file") || die "can't create selected templates file.\n";
	open(SEL_COMPLETE, ">$select_file_complete") || die "can't create selected templates file.\n";
	open(SEL_HHM, ">$select_file_hhm") || die "can't create selected templates file.\n";
	open(TMPOUT, ">$select_file_incomplete") || die "can't create selected templates file.\n";

	$atom_folder = "$query_dir/atom";
	if(!(-d $atom_folder))
	{
		`mkdir $atom_folder`;
	}else{
		`rm $atom_folder/*`;
	}
	$i = 0;
	$incomplete_fea=0;
	for ($i = 0; $i < @rank; $i++)
	{
		#here, hard coded: the max number of templates is set to 50 
		$temp_info = $rank[$i];
		chomp $temp_info;
		@fields = split(/\s+/, $temp_info);
		if ($i < $top_num)
		{
			$record = $rank[$i];
			chomp $record;
			@tmp2=split(/\t/,$record);
			$idnew = $tmp2[1];
			print SEL $record."\n";
			#### check if the hhm feature files of templates are complete (ECOD only have hhm, so ignore other alignments right now)
			$file1 = "$GLOBAL_PATH/database/library/$idnew.hhm";
			$file2 = "$GLOBAL_PATH/database/library/$idnew.shhm";
			$pdb_file1 = "$GLOBAL_PATH/database/SCOP/SCOP_template_PDB/pdb/$idnew.atom";
			$pdb_file2 = "$GLOBAL_PATH/database/ECOD/ECOD_template_PDB/pdb/$idnew.atom";
			if(-e $file1 or -e $file2)
			{
				print SEL_HHM $record."\n";
			}
			if(-e $pdb_file1)
			{
				`cp $pdb_file1 $atom_folder/$idnew.atom`;
				if(!(-e "$atom_folder/$idnew.atom.gz"))
				{
					`gzip $atom_folder/$idnew.atom`;
				}
			}elsif(-e $pdb_file2)
			{
				`cp $pdb_file2 $atom_folder/$idnew.atom`;
				if(!(-e "$atom_folder/$idnew.atom.gz"))
				{
					`gzip $atom_folder/$idnew.atom`;
				}
			}else{
				print "Failed to find $pdb_file1 or $pdb_file2\n\n";
				next;
			}
			#### check if the feature files of templates are complete (ECOD only have hhm, so ignore other alignments right now)
			@suffix = ("align", "aln", "fas", "hmm", "lob"); 
			$check = 0;
			while (@suffix)
			{
				$suf = shift @suffix;
				$file = "$GLOBAL_PATH/database/library/$idnew.$suf";
				if (!-f "$file")
				{
					$check = 2;
					next;
				}
				
				open(TMP,"$file") || die "Failed to find $file\n\n";
				@content = <TMP>;
				close TMP;
				if(@content == 0)
				{
					print "$file is empty, remove it\n";
					$check=1;
					last;
				}
			}
			if($check != 0)
			{
				if(!exists($lib{$idnew}))
				{
					print "Failed to find template sequence for $idnew in $fr_template_lib_file\n\n";
				}else{
					$incomplete_fea ++;
					print TMPOUT ">$idnew\t".$lib{$idnew}."\n";
				}
				
				next;
			}
			print SEL_COMPLETE $record."\n";
		}
		else
		{
			last;
		}
	}
	close SEL;
	close SEL_COMPLETE;
	close SEL_HHM;
	close TMPOUT;

	############ generate profiles for templates
	if($incomplete_fea>0)
	{
		print "$incomplete_fea templates have missing profiles, need regeneration\n\n"; 
		`mkdir $query_dir/template_profiles`;
		print "perl $GLOBAL_PATH/scripts/P0_prepare_features/gen_query_files_proc.pl $select_file_incomplete $option_file $query_dir/template_profiles\n\n";
		`perl $GLOBAL_PATH/scripts/P0_prepare_features/gen_query_files_proc.pl $select_file_incomplete $option_file $query_dir/template_profiles`;
		
		### copy profiles to library
		
		
		open(IN,"$select_file_incomplete") || die "Failed to open file $select_file_incomplete\n";
		while(<IN>)
		{
			$line=$_;
			chomp $line;
			@tmp = split(/\t/,$line);
			$id_tmp = $tmp[0];
			if(substr($id_tmp,0,1) eq '>')
			{
				$id_tmp = substr($id_tmp,1);
			}
			@suffix = ("align", "aln", "fas", "hmm", "lob", "shhm"); 
			while (@suffix)
			{
				$suf = shift @suffix; 
				$file = "$query_dir/template_profiles/library/$id_tmp.$suf";
				if (!-f "$file")
				{
					print "Failed to find $file\n";
					next;
				}
				#print "cp $query_dir/template_profiles/library/$id_tmp.$suf $GLOBAL_PATH/database/library/\n";
				`cp $query_dir/template_profiles/library/$id_tmp.$suf $GLOBAL_PATH/database/library/`;
			}
		}
		close IN;
		`rm -rf $query_dir/template_profiles/*`;
	}
}

print "$incomplete_fea templates still have missing profiles, ignore\n\n"; 

#######################Generate alignments in parallel############################

#generate shhm file for the query protein, which is used by hhsearch for alignments


#TEST:

$query_file = abs_path($query_file);
##########################################################

##################################################################################

####################################################################################################
#generate alignment files using lobster, spem, hhsearch for each template...
#key idea is to use local alignments........
#goto EVA;

#must cd into the query dir contains shhm files
chdir $query_dir;

## spem doesn't need other files except sequence
#generate alignments using spem.............
open(OPTION, ">$option_file.add") || die "can't create a temporary option file.\n";
print OPTION join("", @options);
print OPTION "\nquery_dir=$query_dir\n";
print OPTION "\nalignment_method=spem\n";
close OPTION;
$align_file = "$query_dir/$qname.pir.spem";
print "generate alignments between query and $top_num templates using spem...\n";
print("$deepsf_dir/P2_alignment_generation/gen_query_temp_align_proc.pl $option_file.add $query_file $fr_template_lib_file $query_dir/$qname.all.sel $align_file\n\n");
system("$deepsf_dir/P2_alignment_generation/gen_query_temp_align_proc.pl $option_file.add $query_file $fr_template_lib_file $query_dir/$qname.all.sel $align_file");
print "done.\n";

#generate alignments using hhsearch.............
open(OPTION, ">$option_file.add") || die "can't create a temporary option file.\n";
print OPTION join("", @options);
print OPTION "\nquery_dir=$query_dir\n";
print OPTION "\nalignment_method=hhsearch\n";
close OPTION;
$align_file = "$query_dir/$qname.pir.hhs";
print "generate alignments between query and $top_num templates using hhsearch...\n";
print("$deepsf_dir/P2_alignment_generation/gen_query_temp_align_proc.pl $option_file.add $query_file $fr_template_lib_file $query_dir/$qname.hhm.sel $align_file\n");
system("$deepsf_dir/P2_alignment_generation/gen_query_temp_align_proc.pl $option_file.add $query_file $fr_template_lib_file $query_dir/$qname.hhm.sel $align_file");
print "done.\n";


#generate alignments using lobster.............
open(OPTION, ">$option_file.add") || die "can't create a temporary option file.\n";
print OPTION join("", @options);
print OPTION "\nquery_dir=$query_dir\n";
print OPTION "\nalignment_method=lobster\n";
close OPTION;
$align_file = "$query_dir/$qname.pir.lob";
print "generate alignments between query and $top_num templates using lobster...\n";
print("$deepsf_dir/P2_alignment_generation/gen_query_temp_align_proc.pl $option_file.add $query_file $fr_template_lib_file $query_dir/$qname.complete.sel $align_file\n");
system("$deepsf_dir/P2_alignment_generation/gen_query_temp_align_proc.pl $option_file.add $query_file $fr_template_lib_file $query_dir/$qname.complete.sel $align_file");
print "done.\n";

#generate alignments using muscle.............
open(OPTION, ">$option_file.add") || die "can't create a temporary option file.\n";
print OPTION join("", @options);
print OPTION "\nquery_dir=$query_dir\n";
print OPTION "\nalignment_method=muscle\n";
close OPTION;
$align_file = "$query_dir/$qname.pir.mus";
print "generate alignments between query and $top_num templates using muscle...\n";
print("$deepsf_dir/P2_alignment_generation/gen_query_temp_align_proc.pl $option_file.add $query_file $fr_template_lib_file $query_dir/$qname.complete.sel $align_file\n");
system("$deepsf_dir/P2_alignment_generation/gen_query_temp_align_proc.pl $option_file.add $query_file $fr_template_lib_file $query_dir/$qname.complete.sel $align_file");
print "done.\n";


#TEST:
$query_file = abs_path($query_file);

chdir $query_dir;
#generate alignments using compass.............
open(OPTION, ">$option_file.add") || die "can't create a temporary option file.\n";
print OPTION join("", @options);
print OPTION "\nquery_dir=$query_dir\n";
print OPTION "\nalignment_method=compass\n";
close OPTION;
$align_file = "$query_dir/$qname.pir.com";
print "generate alignments between query and $top_num templates using compass...\n";
print("$deepsf_dir/P2_alignment_generation/gen_query_temp_align_proc.pl $option_file.add $query_file $fr_template_lib_file $query_dir/$qname.complete.sel $align_file\n");
system("$deepsf_dir/P2_alignment_generation/gen_query_temp_align_proc.pl $option_file.add $query_file $fr_template_lib_file $query_dir/$qname.complete.sel $align_file");
print "done.\n";

####################################################################################################

#chdir $query_dir;

#combine alignments using gap-driven approach
print "combine alignments using gap driven approach from top to down.\n";

@suffix = ("spem", "lob", "hhs", "mus", "com");

foreach $type (@suffix)
{

	print "combine alignments generated by $type...\n";
	$align_file = "$query_dir/$qname.pir.$type";
	open(ALIGN, $align_file) || die "can't read profile-profile alignment file.\n"; 
	@align = <ALIGN>;
	close ALIGN;
	@candidate_temps = (); 
	%tscores = (); 
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
		$temp_pir_file = "$query_dir/$tname.pir";
		open(TEMP, ">$temp_pir_file") || die "can't create pir file for $tname.\n";
		print TEMP join("", @group);
		close TEMP; 
		push @candidate_temps, $temp_pir_file; 
		$tscores{$tname} = $score; 
	}

	#combine alignments here (stop here....)
	open(CANDI, ">$qname.can") || die "can't create candidate file: $qname.can\n";
	print CANDI join("\n", @candidate_temps);
	close CANDI; 

	$output_prefix = "$query_dir/$type"; 

	#always use advanced combination at this moment
	#otherwise, we need to use structure alignment first.
	print("$prosys_dir/pir_adv_comb_join_rotate.pl $prosys_dir $qname.can $fr_min_cover_size $fr_gap_stop_size $fr_max_linker_size $top_num $adv_comb_join_max_size $output_prefix\n");
	system("$prosys_dir/pir_adv_comb_join_rotate.pl $prosys_dir $qname.can $fr_min_cover_size $fr_gap_stop_size $fr_max_linker_size $top_num $adv_comb_join_max_size $output_prefix");

}

#`rm $qname.can`; 
`mv $qname.can $query_dir/$qname.can 2>/dev/null`; 

#TEST:
MODEL_GEN:

#############generate tertiary structures from each template.
print "generate structures for combined templates using multiple threads...\n";

chdir $query_dir;
@suffix = ("spem", "lob", "hhs", "mus", "com");


$list_file = "$query_dir/$qname.pir.list";
open(LIST, ">$list_file");
foreach $type (@suffix)
{
	#combine templates globally
	#print("$prosys_dir/script/combine_fr_global.pl $prosys_dir/script/ . $qname.rank 0.5 $type 3 $type-comb.pir\n");
	
	if($type eq 'lob' or $type eq 'mus' or $type eq 'com')
	{
		print("$deepsf_dir/P2_alignment_generation/combine_fr_global_deepsf.pl $prosys_dir/ . $query_dir/$qname.complete.sel $type 5 $type-comb.pir\n");
		system("$deepsf_dir/P2_alignment_generation/combine_fr_global_deepsf.pl $prosys_dir/ . $query_dir/$qname.complete.sel $type 5 $type-comb.pir");
	}elsif($type eq 'hhs')
	{
		print("$deepsf_dir/P2_alignment_generation/combine_fr_global_deepsf.pl $prosys_dir/ . $query_dir/$qname.hhm.sel $type 5 $type-comb.pir\n");
		system("$deepsf_dir/P2_alignment_generation/combine_fr_global_deepsf.pl $prosys_dir/ . $query_dir/$qname.hhm.sel $type 5 $type-comb.pir");
	}elsif($type eq 'spem')
	{
		print("$deepsf_dir/P2_alignment_generation/combine_fr_global_deepsf.pl $prosys_dir/ . $query_dir/$qname.all.sel $type 5 $type-comb.pir\n");
		system("$deepsf_dir/P2_alignment_generation/combine_fr_global_deepsf.pl $prosys_dir/ . $query_dir/$qname.all.sel $type 5 $type-comb.pir");
	}
	for ($i = 1; $i <= $top_num; $i++)
	{
		$file = "$type$i.pir";
		if (-f $file)
		{
			print LIST $file, "\n";
		}
	}

	if (-f "$type-comb.pir")
	{
		print LIST "$type-comb.pir", "\n";
	}
}
close LIST;

##########generate structures from the template
print("$deepsf_dir/P3_model_generation/gen_model_proc.pl  $prosys_dir $modeller_dir $atom_folder $query_dir $list_file $num_model_simulate $thread_num $qname\n");
system("$deepsf_dir/P3_model_generation/gen_model_proc.pl  $prosys_dir $modeller_dir $atom_folder $query_dir $list_file $num_model_simulate $thread_num $qname");
	
print "done.\n";

`rm $option_file.add`; 

EVA:
########### model evaluation
$deepsf_alndir = "$query_dir/alignments/";
$deepsf_modeldir = "$query_dir/models/";
$deepsf_evadir = "$query_dir/eva/";
if(!(-d $deepsf_alndir))
{
	system("mkdir -p $deepsf_alndir");
}
if(!(-d $deepsf_modeldir))
{
	system("mkdir -p $deepsf_modeldir");
}

if(!(-d $deepsf_evadir))
{
	system("mkdir -p $deepsf_evadir");
}
system("mv *pdb $deepsf_modeldir");
system("mv *pir $deepsf_alndir");

$SBROD_starttime = time();
chdir("$GLOBAL_PATH/software/SBROD");
$cmd = "./assess_protein $deepsf_modeldir/*pdb &> $deepsf_evadir/SBROD_ranking.txt";

print "generating SBROD score\n   $cmd \n\n";
$ren_return_val=system("$cmd");
if ($ren_return_val)
{
	$SBROD_finishtime = time();
	$SBROD_diff_hrs = ($SBROD_finishtime - $SBROD_starttime)/3600;
	print "SBROD modeling finished within $SBROD_diff_hrs hrs!\n\n";
	print "ERROR! SBROD execution failed!";
	exit 0;
}
$SBROD_finishtime = time();
$SBROD_diff_hrs = ($SBROD_finishtime - $SBROD_starttime)/3600;
print "SBROD modeling finished within $SBROD_diff_hrs hrs!\n\n";

#### processing the SBROD ranking 
print "Checking $deepsf_evadir/SBROD_ranking.txt\n";
open(TMPF,"$deepsf_evadir/SBROD_ranking.txt") || die "Failed to open file $deepsf_evadir/SBROD_ranking.txt\n";
open(TMPO,">$deepsf_evadir/Final_ranking.txt") || die "Failed to open file $deepsf_evadir/Final_ranking.txt\n";
%mod2score=();
while(<TMPF>)
{
	$li = $_;
	chomp $li;
	@info = split(/\s+/,$li);
	$modpath = $info[0];
	$modscore = $info[1];
	@tmpa = split(/\//,$modpath);
	$mod = pop @tmpa;
	$mod2score{$mod} = $modscore;
	
}
close TMPF;
foreach $mod (sort {$mod2score{$b} <=> $mod2score{$a}} keys %mod2score) 
{
	print TMPO "$mod\t".$mod2score{$mod}."\n";
}
close TMPO;

chdir($query_dir);


$rankf = "$deepsf_evadir/Final_ranking.txt";
print "\n\n###################### Start to format the top 5 models, rename the target id to CAMEO id\n";

$deepsf_top5dir = "$query_dir/TOP5/";
$deepsf_top5dir_aln = "$query_dir/TOP5_aln/";
$deepsf_top5dir_temp = "$query_dir/TOP5/temp/";
if(!(-d $deepsf_top5dir))
{
	system("mkdir -p $deepsf_top5dir");
}
if(!(-d $deepsf_top5dir_temp))
{
	system("mkdir -p $deepsf_top5dir_temp");
}

if(!(-d $deepsf_top5dir_aln))
{
	system("mkdir -p $deepsf_top5dir_aln");
}
#open(RANK,"$rankf") || die "Failed to open file $rankf\n";
#@rankmodel = <RANK>;
#close RANK;

open FEAT, "$rankf" or confess $!;
my @rankmodel = <FEAT>;
close FEAT; 
$modid=0;
print "Total lines: ".@rankmodel." in $rankf\n";
foreach (@rankmodel)
{
	$line=$_;
	chomp $line;
	@tmp = split(/\t/,$line);
	$mod = $tmp[0];
	
	
	if($modid>5)
	{
		last;
	}
	$modelfile = "$deepsf_modeldir/$mod";
	if(!(-e $modelfile))
	{
		die "Failed to find model $modelfile\n";
	}
	
	$mod_prefix = substr($mod,0,length($mod)-4);
	$mod_pir = "$deepsf_alndir/$mod_prefix.pir";
	if(!(-e $mod_pir))
	{
		print "Failed to find alignment $mod_pir, next\n";
		next;
	}
	
	
	$modid++;
	print("### cp $modelfile $deepsf_top5dir/casp$modid.pdb\n");
	system("cp $modelfile $deepsf_top5dir/casp$modid.pdb");
	print("### cp $mod_pir $deepsf_top5dir_aln/casp$modid.pir\n");
	system("cp $mod_pir $deepsf_top5dir_aln/casp$modid.pir");
}

print "Start to refine models to top 5 models \n";
#format models
#$Top5folder = $outfolder."/CHECK/";
$Top5folder = $query_dir."/TOP5/";

for($i=1;$i<=5;$i++)
{
	$file = "$Top5folder/casp$i.pdb";
	if(-e $file)
	{
		`cp $Top5folder/casp$i.pdb $Top5folder/DeepSF$i.pdb`;
	}
	$file_aln = "$deepsf_top5dir_aln/casp$i.pir";
	if(-e $file)
	{
		`cp $deepsf_top5dir_aln/casp$i.pir $Top5folder/DeepSF$i.pir`;
	}
}


############# start prepare the files for visualization
#(1) summarize the alignment based on methods

SUMMARY:

if(!(-d "$query_dir/alignments_summary"))
{
	`mkdir $query_dir/alignments_summary`;
}
print "#######################  Summarize the SCOP alignment \n";
#######################  Summarize the SCOP alignment 

$fold_rankfile = "$outdir_stage1/$id-predict-out/$id.rank_list";
if(!(-e $fold_rankfile))
{
	print "!!! Failed to find $fold_rankfile\n";
}else{

	#print "Checking $fold_rankfile\n";
	open(TMPIN,"$fold_rankfile");
	$fold_index=0;
	while(<TMPIN>)
	{
		$line=$_;
		chomp $line;
		if(index($line,'Probability')>0)
		{
			next;
		}
		@tmp = split(/\t/,$line);
		$fd = $tmp[1];
		$fold_index++;
		
		if($fold_index>5)
		{
			last;
		}
		$template_file = "$outdir_stage1/$id-KL-hidden-out/score_ranking_dir/${id}_top5_folds_info/fold_$fd";
		if(!(-e $template_file))
		{
			print "!!! Failed to find template rank: $template_file\n";
			next;
		}
		@suffix = ("spem", "lob", "hhs", "mus", "com");
		$method_name = "align";
		foreach $type (@suffix)
		{
			if($type eq 'spem')
			{
				$method_name = 'spem';
			}elsif($type eq 'lob')
			{
				$method_name = 'lobster';
			}elsif($type eq 'lob')
			{
				$method_name = 'lobster';
			}elsif($type eq 'hhs')
			{
				$method_name = 'hhalign';
			}elsif($type eq 'mus')
			{
				$method_name = 'muster';
			}
			elsif($type eq 'com')
			{
				$method_name = 'compass';
			}
			
			if(!(-e "$query_dir/$id.pir.$type"))
			{
				next;
			}
			#print "perl $GLOBAL_PATH/scripts/P2_alignment_generation/summary_alignment_method.pl  $template_file  $fd  $id  SCOP  $query_dir/$id.pir.$type $query_dir/alignments_summary $method_name $GLOBAL_PATH\n\n";
			$status = system("perl $GLOBAL_PATH/scripts/P2_alignment_generation/summary_alignment_method.pl  $template_file  $fd  $id  SCOP  $query_dir/$id.pir.$type $query_dir/alignments_summary $method_name $GLOBAL_PATH");

			
			$aln_summary_forweb_align = "$query_dir/alignments_summary/SCOP_fold_${fd}_top10_$method_name.pir";
			if(!(-e $aln_summary_forweb_align))
			{
				print "!!!!!! Failed to find $aln_summary_forweb_align\n";
			}else{
				if(!(-d "$outdir_stage1/DeepSF-$id-results/$id"))
				{
					`mkdir $outdir_stage1/DeepSF-$id-results/$id`;
				}
				`cp $aln_summary_forweb_align $outdir_stage1/DeepSF-$id-results/$id/`;
			}
			
			$aln_summary_forweb_msa = "$query_dir/alignments_summary/SCOP_fold_${fd}_top10_$method_name.msa";
			if(!(-e $aln_summary_forweb_msa))
			{
				print "!!!!!! Failed to find $aln_summary_forweb_msa\n";
			}else{
				if(!(-d "$outdir_stage1/DeepSF-$id-results/$id"))
				{
					`mkdir $outdir_stage1/DeepSF-$id-results/$id`;
				}
				`cp $aln_summary_forweb_msa $outdir_stage1/DeepSF-$id-results/$id/`;
				`cp $aln_summary_forweb_msa $outdir_stage1/DeepSF-$id-results/$id/SCOP_fold_Top${fold_index}_top10_$method_name.msa`;
			}
			
		}
	}
	close TMPIN;
}


print "#######################  Summarize the ECOD-X alignment \n"; 
#######################  Summarize the ECOD-X alignment 

$fold_rankfile = "$outdir_stage1/$id-predict-out-ECOD_X/$id.rank_list";
if(!(-e $fold_rankfile))
{
	print "!!! Failed to find $fold_rankfile\n";
}else{
	#print "Checking $fold_rankfile\n";
	open(TMPIN,"$fold_rankfile");
	$fold_index=0;
	while(<TMPIN>)
	{
		$line=$_;
		chomp $line;
		if(index($line,'Probability')>0)
		{
			next;
		}
		@tmp = split(/\t/,$line);
		$fd = $tmp[1];
		$fold_index++;
		
		if($fold_index>5)
		{
			last;
		}
		$template_file = "$outdir_stage1/$id-KL-hidden-out-ECOD_X/score_ranking_dir/${id}_top5_folds_info/fold_$fd";
		if(!(-e $template_file))
		{
			print "!!! Failed to find template rank: $template_file\n";
			next;
		}
		@suffix = ("spem", "lob", "hhs", "mus", "com");
		$method_name = "";
		foreach $type (@suffix)
		{
			if($type eq 'spem')
			{
				$method_name = 'spem';
			}elsif($type eq 'lob')
			{
				$method_name = 'lobster';
			}elsif($type eq 'lob')
			{
				$method_name = 'lobster';
			}elsif($type eq 'hhs')
			{
				$method_name = 'hhalign';
			}elsif($type eq 'mus')
			{
				$method_name = 'muster';
			}
			elsif($type eq 'com')
			{
				$method_name = 'compass';
			}
			
			if(!(-e "$query_dir/$id.pir.$type"))
			{
				next;
			}
			#print "perl $GLOBAL_PATH/scripts/P2_alignment_generation/summary_alignment_method.pl  $template_file  $fd  $id  ECOD_X  $query_dir/$id.pir.$type $query_dir/alignments_summary $method_name $GLOBAL_PATH\n\n";
			$status = system("perl $GLOBAL_PATH/scripts/P2_alignment_generation/summary_alignment_method.pl  $template_file  $fd  $id  ECOD_X  $query_dir/$id.pir.$type $query_dir/alignments_summary $method_name $GLOBAL_PATH");

			
			$aln_summary_forweb_align = "$query_dir/alignments_summary/ECOD_X_fold_${fd}_top10_$method_name.pir";
			if(!(-e $aln_summary_forweb_align))
			{
				print "!!!!!! Failed to find $aln_summary_forweb_align\n";
			}else{
				if(!(-d "$outdir_stage1/DeepSF-$id-results/$id"))
				{
					`mkdir $outdir_stage1/DeepSF-$id-results/$id`;
				}
				`cp $aln_summary_forweb_align $outdir_stage1/DeepSF-$id-results/$id/`;
			}
			
			$aln_summary_forweb_msa = "$query_dir/alignments_summary/ECOD_X_fold_${fd}_top10_$method_name.msa";
			if(!(-e $aln_summary_forweb_msa))
			{
				print "!!!!!! Failed to find $aln_summary_forweb_msa\n";
			}else{
				if(!(-d "$outdir_stage1/DeepSF-$id-results/$id"))
				{
					`mkdir $outdir_stage1/DeepSF-$id-results/$id`;
				}
				`cp $aln_summary_forweb_msa $outdir_stage1/DeepSF-$id-results/$id/`;
				`cp $aln_summary_forweb_msa $outdir_stage1/DeepSF-$id-results/$id/ECOD_X_fold_Top${fold_index}_top10_$method_name.msa`;
			}
			
		}
	}
	close TMPIN;
}

print "#######################  Summarize the ECOD-H alignment \n";
#######################  Summarize the ECOD-H alignment 


$fold_rankfile = "$outdir_stage1/$id-predict-out-ECOD_H/$id.rank_list";
if(!(-e $fold_rankfile))
{
	print "!!! Failed to find $fold_rankfile\n";;
}else{
	#print "Checking $fold_rankfile\n";
	open(TMPIN,"$fold_rankfile");
	$fold_index=0;
	while(<TMPIN>)
	{
		$line=$_;
		chomp $line;
		if(index($line,'Probability')>0)
		{
			next;
		}
		@tmp = split(/\t/,$line);
		$fd = $tmp[1];
		$fold_index++;
		
		if($fold_index>5)
		{
			last;
		}
		$template_file = "$outdir_stage1/$id-KL-hidden-out-ECOD_H/score_ranking_dir/${id}_top5_folds_info/fold_$fd";
		if(!(-e $template_file))
		{
			print "!!! Failed to find template rank: $template_file\n";
			next;
		}
		@suffix = ("spem", "lob", "hhs", "mus", "com");
		$method_name = "";
		foreach $type (@suffix)
		{
			if($type eq 'spem')
			{
				$method_name = 'spem';
			}elsif($type eq 'lob')
			{
				$method_name = 'lobster';
			}elsif($type eq 'lob')
			{
				$method_name = 'lobster';
			}elsif($type eq 'hhs')
			{
				$method_name = 'hhalign';
			}elsif($type eq 'mus')
			{
				$method_name = 'muster';
			}
			elsif($type eq 'com')
			{
				$method_name = 'compass';
			}
			
			
			if(!(-e "$query_dir/$id.pir.$type"))
			{
				next;
			}
			#print "perl $GLOBAL_PATH/scripts/P2_alignment_generation/summary_alignment_method.pl  $template_file  $fd  $id  ECOD_H  $query_dir/$id.pir.$type $query_dir/alignments_summary $method_name $GLOBAL_PATH\n\n";
			$status = system("perl $GLOBAL_PATH/scripts/P2_alignment_generation/summary_alignment_method.pl  $template_file  $fd  $id  ECOD_H  $query_dir/$id.pir.$type $query_dir/alignments_summary $method_name $GLOBAL_PATH");

			
			$aln_summary_forweb_align = "$query_dir/alignments_summary/ECOD_H_fold_${fd}_top10_$method_name.pir";
			if(!(-e $aln_summary_forweb_align))
			{
				print "!!!!!! Failed to find $aln_summary_forweb_align\n";
			}else{
				if(!(-d "$outdir_stage1/DeepSF-$id-results/$id"))
				{
					`mkdir $outdir_stage1/DeepSF-$id-results/$id`;
				}
				`cp $aln_summary_forweb_align $outdir_stage1/DeepSF-$id-results/$id/`;
			}
			
			$aln_summary_forweb_msa = "$query_dir/alignments_summary/ECOD_H_fold_${fd}_top10_$method_name.msa";
			if(!(-e $aln_summary_forweb_msa))
			{
				print "!!!!!! Failed to find $aln_summary_forweb_msa\n";
			}else{
				if(!(-d "$outdir_stage1/DeepSF-$id-results/$id"))
				{
					`mkdir $outdir_stage1/DeepSF-$id-results/$id`;
				}
				`cp $aln_summary_forweb_msa $outdir_stage1/DeepSF-$id-results/$id/`;
				`cp $aln_summary_forweb_msa $outdir_stage1/DeepSF-$id-results/$id/ECOD_H_fold_Top${fold_index}_top10_$method_name.msa`;
			}
		}
	}
	close TMPIN;
}

`rm -rf $query_dir/*thread*`;
`rm -rf $query_dir/alignments_summary/tmp`;
system("echo \"DeepSF-3D modeling finish!\" > $query_dir/DeepSF-3D.done "); 
$finish_time = time();
$DeepSF_diff_hrs = ($finish_time -$start_time)/3600;
print "DeepSF-3D modeling finish! Total time: <$DeepSF_diff_hrs> hrs!\n";


print "\nThe ranking of top SCOP folds are saved in $query_dir/fold_rank_list.SCOP`\n";
print "The ranking of top ECOD_X folds are saved in $query_dir/fold_rank_list.ECOD_X\n";
print "The ranking of top ECOD_H folds are saved in $query_dir/fold_rank_list.ECOD_H\n\n";

print "The predicted models are saved in $deepsf_top5dir\n\n";


print "\nFinished [$0]: ".(localtime).", models are saving in $Top5folder\n";



####################################################################################################
sub system_cmd{
	my $command = shift;
	my $log = shift;
	confess "EXECUTE [$command]?\n" if (length($command) < 5  and $command =~ m/^rm/);
	if(defined $log){
		system("$command &> $log");
	}
	else{
		print "[[Executing: $command]]\n";
		system($command);
	}
	if($? != 0){
		my $exit_code  = $? >> 8;
		confess "ERROR!! Could not execute [$command]! \nError message: [$!]";
	}
}


####################################################################################################
sub seq_fasta{
	my $file_fasta = shift;
	confess "ERROR! Fasta file $file_fasta does not exist!" if not -f $file_fasta;
	my $seq = "";
	open FASTA, $file_fasta or confess $!;
	while (<FASTA>){
		next if (substr($_,0,1) eq ">"); 
		chomp $_;
		$_ =~ tr/\r//d; # chomp does not remove \r
		$seq .= $_;
	}
	close FASTA;
	return $seq;
}
