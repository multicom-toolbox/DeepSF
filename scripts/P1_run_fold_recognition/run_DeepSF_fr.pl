#!/usr/bin/perl

use Cwd;
#use MIME::Lite;
use List::Util qw(reduce);
use List::Util qw(min);
use List::Util qw(max);

######################################
# Read the input query file
######################################


my $GLOBAL_PATH='/home/casp13/deepsf_3d/Github/DeepSF/';

$OBSOLETE=7200*15; # 2h * 24   -> 2 days
$numArgs = @ARGV;
if($numArgs != 1)
{   
	print "the number of parameters is not correct!\n";
	exit(1);
}

$input_file	= "$ARGV[0]";

###############################Software and Data Settings####################

#DeepSF tool dir
$tool_dir = $GLOBAL_PATH;

#SCRATCH tool dir
$SCRATCH_tools = $GLOBAL_PATH.'/software/SCRATCH-1D_1.1/';

#nr90_path tool dir
#$nr90_path = '/home/casp13/MULTICOM_package/nr/nr90';
$nr90_path = $GLOBAL_PATH.'/software/pspro2/data/nr/nr';

#pspro2 tool dir
$pspro2_tools = $GLOBAL_PATH.'/software/pspro2/';

#decoy_model_number
$decoy_model_number = 100;

#final_model_number
$final_model_number = 5;

#Unicon3D prefix
$output_prefix_name = 'DeepSF';



if (! -d $tool_dir)
{
        die "can't find tool_dir $tool_dir directory.\n";
}

if (! -d $pspro2_tools)
{
        die "can't find pspro2_tools $pspro2_tools directory.\n";
}
if (! -d $SCRATCH_tools)
{
        die "can't find SCRATCH_tools $SCRATCH_tools directory.\n";
}

if (! -e "$nr90_path.00.phr")
{
        die "can't find $nr90_path.00.phr.\n";
}


 
open(fi,"<$input_file");
@text=<fi>;
close fi;

#read server name
$server_name = shift @text;
chomp $server_name;

#read job name
$jobname = shift @text;
chomp $jobname;

#read email id
$reply_email = shift @text;
chomp $reply_email;

#read query ID (reservation id)
$currentID = shift @text;
chop $currentID;

#read reservation file name
$reservation = shift @text;
chomp $reservation;

#read the researvation dir (work dir)
$task_dir = shift @text;
chomp $task_dir;

#read the query submission time
$initime = shift @text;
chomp $initime;

#read the path of the uploaded initial file
$fasta_file = shift @text;
chomp $fasta_file;


#read the path of the uploaded initial file
$job_identifier = shift @text;
chomp $job_identifier;



######################################
# Job Pre Processing
######################################

#make a sub work dir for this task
`mkdir -m 777 $task_dir`;

$results_dir_targets = "$task_dir/$server_name-$jobname-$currentID";
`mkdir -m 777 $results_dir_targets`;

chdir $task_dir;

#start writing to an execution log file
$execution_log = "$server_name-$jobname-$currentID-log.txt";
open(LOG, ">$task_dir/$execution_log");
$curr_time = localtime;
print LOG "$curr_time\nJob $jobname has been queued\n\n";
print LOG "Job ID = $currentID\n";
print LOG "Email  = $reply_email\n";
print LOG "Job_identifier  = $job_identifier\n";



######################################
# Job Execution
######################################


if($job_identifier eq "")
{
	print LOG "Job identifier should be defined (None/Job_identifier)\n";
	die "Job identifier should be defined (None/Job_identifier)\n";	
}


#prepare the input for the job
$initial_model_name = "$server_name-$jobname-$currentID";


$seed = "0";

#download the model file
$model_dir = "$jobname-seqs";
`mkdir -m 777 $model_dir`;

$feature_dir = "$jobname-features";
`mkdir -m 777 $feature_dir`;

$template_hmm_dir = "$jobname-hhm";
`mkdir -m 777 $template_hmm_dir`;


$template_msa_dir = "$jobname-alignment";
`mkdir -m 777 $template_msa_dir`;


### results for SCOP 
$predict_dir = "$jobname-predict-out";
`mkdir -m 777 $predict_dir`;

$Final_prediction_dir = "$jobname-predict-out";
`mkdir -m 777 $results_dir_targets/$Final_prediction_dir`;


$KL_hidden_dir = "$jobname-KL-hidden-out";
`mkdir -m 777 $KL_hidden_dir`;

$Final_model_dir = "$jobname-top5-model";
`mkdir -m 777 $results_dir_targets/$Final_model_dir`;



### results for ECOD_X 
$predict_dir_ECOD_X = "$jobname-predict-out-ECOD_X";
`mkdir -m 777 $predict_dir_ECOD_X`;

$Final_prediction_dir_ECOD_X = "$jobname-predict-out-ECOD_X";
`mkdir -m 777 $results_dir_targets/$Final_prediction_dir_ECOD_X`;


$KL_hidden_dir_ECOD_X = "$jobname-KL-hidden-out-ECOD_X";
`mkdir -m 777 $KL_hidden_dir_ECOD_X`;

$Final_model_dir_ECOD_X = "$jobname-top5-model-ECOD_X";
`mkdir -m 777 $results_dir_targets/$Final_model_dir_ECOD_X`;



### results for ECOD_H
$predict_dir_ECOD_H = "$jobname-predict-out-ECOD_H";
`mkdir -m 777 $predict_dir_ECOD_H`;

$Final_prediction_dir_ECOD_H = "$jobname-predict-out-ECOD_H";
`mkdir -m 777 $results_dir_targets/$Final_prediction_dir_ECOD_H`;


$KL_hidden_dir_ECOD_H = "$jobname-KL-hidden-out-ECOD_H";
`mkdir -m 777 $KL_hidden_dir_ECOD_H`;

$Final_model_dir_ECOD_H = "$jobname-top5-model-ECOD_H";
`mkdir -m 777 $results_dir_targets/$Final_model_dir_ECOD_H`;


#### msa dir
$Final_msa_dir = "$results_dir_targets/$jobname-hhm";
`mkdir -m 777 $Final_msa_dir/`;

#### msa dir
$Final_msa_dir = "$results_dir_targets/$jobname-alignment";
`mkdir -m 777 $Final_msa_dir/`;


`chmod -R 777 $results_dir_targets`;


open(SEQ, $fasta_file) || die "can't read initial fasta file: $fasta_file\n";
@seq_array = <SEQ>;
close SEQ;


# transfer the fasta sequences to tab format, for further check if same sequences has been processed
open(TMP, ">$task_dir/$model_dir/$initial_model_name") || die "can't generate : $task_dir/$model_dir/$initial_model_name\n";
$c=0;
foreach(@seq_array){
	$c++;
	$line = $_;
	chomp $line;
	if(substr($line,0,1) eq '>'){
		if($c>1)
		{
			print TMP "\n";
		}
		@temp2 = split(/[;:,\s\/\|]+/,$line);
		$id = $temp2[0];
		print TMP $id."\t";
		
	}else{
		print TMP $line;
	}

}
print TMP "\n";
close TMP;


$curr_time = localtime;
print LOG "$curr_time\nUploaded file copied to working dir\n\n";


####### check if same sequence has been processed
open(TMP, "$task_dir/$model_dir/$initial_model_name") || die "can't read : $task_dir/$model_dir/$initial_model_name\n";

%query_sequences = ();
while(<TMP>){
	$line = $_;
	chomp $line;
	if(substr($line,0,1) eq '>'){
		@temp = split(/\t/,$line);
		$idinfo = $temp[0];
		@temp2 = split(/[;:,\s\/\|]+/,$line);
		$id = $temp2[0];
		$seq = $temp[1];
		if(substr($id,0,1) eq '>')
		{
			$id = substr($id,1);
		}
		$query_sequences{$id}=$seq;
	}
}
close TMP;

#goto SUMMARY;

open(TMP2, ">$task_dir/$model_dir/$initial_model_name.feature_not_processed") || die "can't generate : $task_dir/$model_dir/$initial_model_name.not_processed\n";
open(TMP3, ">$task_dir/$model_dir/$initial_model_name.feature_not_processed.fa") || die "can't generate : $task_dir/$model_dir/$initial_model_name.feature_not_processed.fa\n";


$unprocessed_num=0;
$processed_num=0;
foreach $qid (sort keys %query_sequences)
{
	chomp $qid;
	$seq = $query_sequences{$qid};
	
	print TMP2 "$qid\n";
	print TMP3 ">$qid\n$seq\n";
	$unprocessed_num++;
	
}
close TMP2;
close TMP3;



chdir "$task_dir";
$curr_time = localtime;
print LOG "\n$curr_time\n$processed_num proteins have features, $unprocessed_num need generate features\n";
print LOG "\n$curr_time\nExecuting Job\n\n";



### generate sequence feature and pssm files
if($unprocessed_num >0)
{
	# generate sequence feature
	$feature_ss_dir = "$task_dir/$jobname-features/SCRATCH";
	if(-e "$task_dir/$jobname-features/$jobname.fea_aa_ss_sa")
	{
		print "$task_dir/$jobname-features/$jobname.fea_aa_ss_sa was generated!\n\n";
		print LOG "$task_dir/$jobname-features/$jobname.fea_aa_ss_sa was generated!\n\n";
	}else{
		`mkdir -m 777 $feature_ss_dir`;
	
		print LOG "Generate features:\nperl $GLOBAL_PATH/scripts/P1_run_fold_recognition/gen_feature_multi.pl  $task_dir/$model_dir/$initial_model_name.feature_not_processed.fa   $feature_ss_dir  $feature_ss_dir/$initial_model_name.feature_not_processed.fea $GLOBAL_PATH $SCRATCH_tools\n";
		system("perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/gen_feature_multi.pl  $task_dir/$model_dir/$initial_model_name.feature_not_processed.fa   $feature_ss_dir  $feature_ss_dir/$initial_model_name.feature_not_processed.fea $GLOBAL_PATH $SCRATCH_tools");
		system("perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/extract_protein_feature_from_single_file.pl $feature_ss_dir/$initial_model_name.feature_not_processed.fea  $task_dir/$jobname-features/\n");
		print LOG "perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/extract_protein_feature_from_single_file.pl $feature_ss_dir/$initial_model_name.feature_not_processed.fea  $task_dir/$jobname-features/ \n";
	}
	$curr_time = localtime;
	print LOG "$curr_time\nSS_SA_AA files are generated!\n";
	
	
	# generate pssm feature
	print LOG "perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/split_fasta_to_folder.pl $task_dir/$model_dir/$initial_model_name.feature_not_processed.fa  $task_dir/$model_dir/  $task_dir/$model_dir/initial_model_name.unprocessed.list\n";
	system("perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/split_fasta_to_folder.pl $task_dir/$model_dir/$initial_model_name.feature_not_processed.fa  $task_dir/$model_dir/  $task_dir/$model_dir/initial_model_name.unprocessed.list");
	$feature_pssm_dir = "$task_dir/$jobname-features/PSSM";
	if(-e "$task_dir/$jobname-features/$jobname.pssm_fea")
	{
		print "$task_dir/$jobname-features/$jobname.pssm_fea was generated!\n\n";
		print LOG "$task_dir/$jobname-features/$jobname.pssm_fea was generated!\n\n";
	}else{
	
		`mkdir -m 777 $feature_pssm_dir`;
		print LOG "python $GLOBAL_PATH/scripts/P1_run_fold_recognition/run_many_sequence.py --inputfile  $task_dir/$model_dir/initial_model_name.unprocessed.list  --seqdir $task_dir/$model_dir/ --script_dir $GLOBAL_PATH/scripts/P1_run_fold_recognition/ --pspro_dir $pspro2_tools --nr_db $nr90_path  --big_db $pspro2_tools/data/big/big_98_X  --outputdir $feature_pssm_dir\n";
		system("python $GLOBAL_PATH/scripts/P1_run_fold_recognition/run_many_sequence.py --inputfile  $task_dir/$model_dir/initial_model_name.unprocessed.list  --seqdir $task_dir/$model_dir/ --script_dir $GLOBAL_PATH/scripts/P1_run_fold_recognition/ --pspro_dir $pspro2_tools --nr_db $nr90_path  --big_db $pspro2_tools/data/big/big_98_X  --outputdir $feature_pssm_dir");
		print LOG "perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/process_pssm_file.pl  $feature_pssm_dir/pssm_features/    $task_dir/$jobname-features/ \n";
		system("perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/process_pssm_file.pl  $feature_pssm_dir/pssm_features/    $task_dir/$jobname-features/");
	}		
	$curr_time = localtime;
	print LOG "$curr_time\nPSSM files are generated!\n\n";

}

# check if all query ids have features 
 
$ungenerated_num=0;  
$generated_num=0; 
open(TMP1, ">$task_dir/$model_dir/$initial_model_name.list_with_fea") || die "can't generate : $task_dir/$model_dir/$initial_model_name.list_with_fea\n";

foreach $qid (sort keys %query_sequences)
{
	chomp $qid;
	$seq = $query_sequences{$qid};
	$ss_fea = "$task_dir/$jobname-features/$qid.fea_aa_ss_sa";
	$pssm_fea = "$task_dir/$jobname-features/$qid.pssm_fea";

	if(!(-e $ss_fea) or !(-e $pssm_fea))
	{
		$curr_time = localtime;
		print LOG "$curr_time\nThe features of $qid are not generated!\n";
		next; # do we need report error?
	}
	print TMP1 "$qid\n";
	
} 
close TMP1;


if(-e "$predict_dir/$jobname.prediction" and -e "$predict_dir/$jobname.hidden_feature" and -e "$predict_dir/$jobname.rank_list")
{
	print "$predict_dir/$jobname.prediction and $predict_dir/$jobname.hidden_feature and $predict_dir/$jobname.rank_list were generated!\n\n";
}else{
	print LOG "python $GLOBAL_PATH/scripts/P1_run_fold_recognition/DeepSF_predict.py  $task_dir/$model_dir/$initial_model_name.list_with_fea $GLOBAL_PATH/models/model_SimilarityReduction.json   $GLOBAL_PATH/models/model_SimilarityReduction.h5     $task_dir/$feature_dir  $task_dir/$feature_dir    $task_dir/$predict_dir/ 30 $GLOBAL_PATH/database/SCOP/fold_label_relation2.txt\n\n";
	print "python $GLOBAL_PATH/scripts/P1_run_fold_recognition/DeepSF_predict.py  $task_dir/$model_dir/$initial_model_name.list_with_fea $GLOBAL_PATH/models/model_SimilarityReduction.json    $GLOBAL_PATH/models/model_SimilarityReduction.h5     $task_dir/$feature_dir  $task_dir/$feature_dir    $task_dir/$predict_dir/ 30 $GLOBAL_PATH/database/SCOP/fold_label_relation2.txt\n\n";
	`python $GLOBAL_PATH/scripts/P1_run_fold_recognition/DeepSF_predict.py  $task_dir/$model_dir/$initial_model_name.list_with_fea $GLOBAL_PATH/models/model_SimilarityReduction.json    $GLOBAL_PATH/models/model_SimilarityReduction.h5     $task_dir/$feature_dir  $task_dir/$feature_dir    $task_dir/$predict_dir/ 30 $GLOBAL_PATH/database/SCOP/fold_label_relation2.txt`;
}

if(-e "$predict_dir_ECOD_X/$jobname.prediction" and -e "$predict_dir_ECOD_X/$jobname.hidden_feature" and -e "$predict_dir_ECOD_X/$jobname.rank_list")
{
	print "$predict_dir_ECOD_X/$jobname.prediction and $predict_dir_ECOD_X/$jobname.hidden_feature and $predict_dir_ECOD_X/$jobname.rank_list were generated!\n\n";
}else{
	print LOG "python $GLOBAL_PATH/scripts/P1_run_fold_recognition/DeepSF_predict.py  $task_dir/$model_dir/$initial_model_name.list_with_fea $GLOBAL_PATH/models/model_ECOD_X/model.json  $GLOBAL_PATH/models/model_ECOD_X/model.h5    $task_dir/$feature_dir  $task_dir/$feature_dir    $task_dir/$predict_dir_ECOD_X/ 48 $GLOBAL_PATH/models/model_ECOD_X/ecod.latest.fasta_id90_Xgroup_to_label_relation2.txt\n\n";
	print "python $GLOBAL_PATH/scripts/P1_run_fold_recognition/DeepSF_predict.py  $task_dir/$model_dir/$initial_model_name.list_with_fea $GLOBAL_PATH/models/model_ECOD_X/model.json  $GLOBAL_PATH/models/model_ECOD_X/model.h5    $task_dir/$feature_dir  $task_dir/$feature_dir    $task_dir/$predict_dir_ECOD_X/ 48 $GLOBAL_PATH/models/model_ECOD_X/ecod.latest.fasta_id90_Xgroup_to_label_relation2.txt\n\n";
	`python $GLOBAL_PATH/scripts/P1_run_fold_recognition/DeepSF_predict.py  $task_dir/$model_dir/$initial_model_name.list_with_fea $GLOBAL_PATH/models/model_ECOD_X/model.json  $GLOBAL_PATH/models/model_ECOD_X/model.h5    $task_dir/$feature_dir  $task_dir/$feature_dir    $task_dir/$predict_dir_ECOD_X/ 48 $GLOBAL_PATH/models/model_ECOD_X/ecod.latest.fasta_id90_Xgroup_to_label_relation2.txt`;
}

if(-e "$predict_dir_ECOD_H/$jobname.prediction" and -e "$predict_dir_ECOD_H/$jobname.hidden_feature" and -e "$predict_dir_ECOD_H/$jobname.rank_list")
{
	print "$predict_dir_ECOD_H/$jobname.prediction and $predict_dir_ECOD_H/$jobname.hidden_feature and $predict_dir_ECOD_H/$jobname.rank_list were generated!\n\n";
}else{
	print "python $GLOBAL_PATH/scripts/P1_run_fold_recognition/DeepSF_predict.py  $task_dir/$model_dir/$initial_model_name.list_with_fea $GLOBAL_PATH/models/model_ECOD_H/model.json  $GLOBAL_PATH/models/model_ECOD_H/model.h5   $task_dir/$feature_dir  $task_dir/$feature_dir    $task_dir/$predict_dir_ECOD_H/ 46 $GLOBAL_PATH/models/model_ECOD_H/ecod.latest.fasta_id90_XHgroup_to_label_relation2.txt\n\n";
	print LOG "python $GLOBAL_PATH/scripts/P1_run_fold_recognition/DeepSF_predict.py  $task_dir/$model_dir/$initial_model_name.list_with_fea $GLOBAL_PATH/models/model_ECOD_H/model.json  $GLOBAL_PATH/models/model_ECOD_H/model.h5    $task_dir/$feature_dir  $task_dir/$feature_dir    $task_dir/$predict_dir_ECOD_H/ 46 $GLOBAL_PATH/models/model_ECOD_H/ecod.latest.fasta_id90_XHgroup_to_label_relation2.txt\n\n";
	`python $GLOBAL_PATH/scripts/P1_run_fold_recognition/DeepSF_predict.py  $task_dir/$model_dir/$initial_model_name.list_with_fea $GLOBAL_PATH/models/model_ECOD_H/model.json  $GLOBAL_PATH/models/model_ECOD_H/model.h5    $task_dir/$feature_dir  $task_dir/$feature_dir    $task_dir/$predict_dir_ECOD_H/ 46 $GLOBAL_PATH/models/model_ECOD_H/ecod.latest.fasta_id90_XHgroup_to_label_relation2.txt`;
}


##############################  visualize the top 10 predictions in SCOP 

print LOG "python  $GLOBAL_PATH/scripts/P1_run_fold_recognition/Analyze_top5_folds.py   $task_dir/$model_dir/$initial_model_name.list_with_fea    $GLOBAL_PATH/database/SCOP/fold_label_relation2.txt $GLOBAL_PATH/database/SCOP/Traindata.list   $GLOBAL_PATH/database/SCOP/SCOP95Ratio8_2_DCNN_results/ $task_dir/$predict_dir/   5  $task_dir/$KL_hidden_dir\n";
system("python  $GLOBAL_PATH/scripts/P1_run_fold_recognition/Analyze_top5_folds.py   $task_dir/$model_dir/$initial_model_name.list_with_fea    $GLOBAL_PATH/database/SCOP/fold_label_relation2.txt $GLOBAL_PATH/database/SCOP/Traindata.list  $GLOBAL_PATH/database/SCOP/SCOP95Ratio8_2_DCNN_results/ $task_dir/$predict_dir/   5  $task_dir/$KL_hidden_dir ");


open(TMPFILE,"$task_dir/$model_dir/$initial_model_name.list_with_fea") || die "Failed to run $task_dir/$model_dir/$initial_model_name.list_with_fea\n";
while(<TMPFILE>)
{
	$pdb_name=$_;
	chomp $pdb_name;
	
	$listdir = "$task_dir/$KL_hidden_dir/search_list_dir";	
	$selected_templist_file = "$listdir/$pdb_name.templist";
	$selected_query_file = "$listdir/$pdb_name.querylist";
	
	## this need be updated to pdb-based sequence in CASP13, currently, still use seq-based sequences
    print LOG "perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/calculate_hidden_KL_score_list.pl  $selected_templist_file $selected_query_file $GLOBAL_PATH/database/SCOP/SCOP95Ratio8_2_DCNN_results/   $task_dir/$predict_dir/   $task_dir/$KL_hidden_dir/score_ranking_dir  $pdb_name\n";
    $status = system("perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/calculate_hidden_KL_score_list.pl  $selected_templist_file $selected_query_file $GLOBAL_PATH/database/SCOP/SCOP95Ratio8_2_DCNN_results/   $task_dir/$predict_dir/   $task_dir/$KL_hidden_dir/score_ranking_dir  $pdb_name");
    if($status)
	{
		print LOG  "Failed to run <perl $GLOBAL_PATH/scripts/calculate_hidden_KL_score_list.pl  $selected_templist_file $selected_query_file $GLOBAL_PATH/database/SCOP/SCOP95Ratio8_2_DCNN_results/   $task_dir/$predict_dir/   $task_dir/$KL_hidden_dir/score_ranking_dir  $pdb_name>\n";
		die "Failed to run <perl $GLOBAL_PATH/scripts/calculate_hidden_KL_score_list.pl  $selected_templist_file $selected_query_file $GLOBAL_PATH/database/SCOP/SCOP95Ratio8_2_DCNN_results/   $task_dir/$predict_dir/   $task_dir/$KL_hidden_dir/score_ranking_dir  $pdb_name>\n";
	}
	
    $KL_file_check = "$task_dir/$KL_hidden_dir/score_ranking_dir/${pdb_name}_KL_calc.done";
    $finish = 0;
    while(1)
	{
		if($finish ==1)
		{
			last;
		}
		if(-e $KL_file_check)
		{
		   $finish = 1
		}
		sleep(1);
		print "Waiting ".$KL_file_check."\n";
	}	
	
        $hidden_feature_file = "$task_dir/$KL_hidden_dir/score_ranking_dir/${pdb_name}_template_fea.txt";
        $KL_score_file = "$task_dir/$KL_hidden_dir/score_ranking_dir/${pdb_name}.KL_output";
       

		## need use updated template pdb database in CASP13
	    print LOG "perl $GLOBAL_PATH/scripts//P1_run_fold_recognition/combine_top10_hidden_for_5folds_CAMEO.pl  $KL_score_file $pdb_name   $GLOBAL_PATH/database/SCOP/SCOP95Ratio8_2_DCNN_results/  $task_dir/$predict_dir/  $task_dir/$KL_hidden_dir/score_ranking_dir  $hidden_feature_file $GLOBAL_PATH\n";
        $status = system("perl $GLOBAL_PATH/scripts//P1_run_fold_recognition/combine_top10_hidden_for_5folds_CAMEO.pl  $KL_score_file $pdb_name   $GLOBAL_PATH/database/SCOP/SCOP95Ratio8_2_DCNN_results/  $task_dir/$predict_dir/  $task_dir/$KL_hidden_dir/score_ranking_dir  $hidden_feature_file $GLOBAL_PATH");
        if($status)
		{
			print LOG  "Failed to run <perl $GLOBAL_PATH/scripts//P1_run_fold_recognition/combine_top10_hidden_for_5folds_CAMEO.pl  $KL_score_file $pdb_name   $GLOBAL_PATH/database/SCOP/SCOP95Ratio8_2_DCNN_results/  $task_dir/$predict_dir/  $task_dir/$KL_hidden_dir/score_ranking_dir  $hidden_feature_file $GLOBAL_PATH>\n";
			die "Failed to run <perl $GLOBAL_PATH/scripts//P1_run_fold_recognition/combine_top10_hidden_for_5folds_CAMEO.pl  $KL_score_file $pdb_name   $GLOBAL_PATH/database/SCOP/SCOP95Ratio8_2_DCNN_results/  $task_dir/$predict_dir/  $task_dir/$KL_hidden_dir/score_ranking_dir  $hidden_feature_file $GLOBAL_PATH>\n";
		}
		
        
    $hidden_feature_file_check = $hidden_feature_file.'.done';
    $finish = 0;
    while(1)
	{
		if($finish ==1)
		{
			last;
		}
		if(-e $hidden_feature_file_check)
		{
		   $finish = 1
		}
		sleep(1);
		print "Waiting ".$hidden_feature_file_check."\n";
	}	
}
close TMPFILE;



$fold_description = "$GLOBAL_PATH/database/SCOP/dir.des.scop.1.75_class.txt";
$family_description = "$GLOBAL_PATH/database/SCOP/dir.des.scop.1.75_family.txt";
### combine the prediction with top1 template 

print LOG "perl  $GLOBAL_PATH/scripts/P1_run_fold_recognition/combine_prediction_with_template.pl   $task_dir/$model_dir/$initial_model_name.list_with_fea  $task_dir/$predict_dir/ $GLOBAL_PATH/database/SCOP/Traindata.list  $task_dir/$KL_hidden_dir/score_ranking_dir  $fold_description $family_description $results_dir_targets/$Final_model_dir\n";
system("perl  $GLOBAL_PATH/scripts/P1_run_fold_recognition/combine_prediction_with_template.pl   $task_dir/$model_dir/$initial_model_name.list_with_fea  $task_dir/$predict_dir/  $GLOBAL_PATH/database/SCOP/Traindata.list  $task_dir/$KL_hidden_dir/score_ranking_dir  $fold_description $family_description $results_dir_targets/$Final_model_dir");





## visualize the heatmap 
$curr_time = localtime;

$firstprotein="";
print LOG "$curr_time\nPlot the heatmaps:\n";
open(INFILE,"$task_dir/$model_dir/$initial_model_name.list_with_fea") || die "Failed to open file $task_dir/$model_dir/$initial_model_name.list_with_fea\n";
$c = 0;
while(<INFILE>)
{
	$pdb_name=$_;
	chomp $pdb_name;
	$c++;
	if($c==1)
	{
		$firstprotein=$pdb_name;
	}
	
	$rankfile = "$task_dir/$predict_dir/${pdb_name}.rank_list";
	$rankfile_image = "$task_dir/$predict_dir/${pdb_name}_prediction_prob.png";
	#sleep(2);
	print LOG "python $GLOBAL_PATH/scripts/P1_run_fold_recognition/Visualize_prediction.py  $rankfile $rankfile_image\n";
	system("python $GLOBAL_PATH/scripts/P1_run_fold_recognition/Visualize_prediction.py  $rankfile $rankfile_image");
	`cp $rankfile_image $results_dir_targets/$Final_prediction_dir/`;
	
}
close INFILE;


print LOG "\n\n";


##############################  visualize the top 10 predictions in ECOD_X 

print LOG "python  $GLOBAL_PATH/scripts/P1_run_fold_recognition/Analyze_top5_folds.py   $task_dir/$model_dir/$initial_model_name.list_with_fea   $GLOBAL_PATH/database/ECOD/ECOD_X/ecod.latest.fasta_id90_Xgroup_to_label_relation2.txt  $GLOBAL_PATH/database/ECOD/ECOD_X/XGroup2length_withName_hasFea.list     $GLOBAL_PATH/scripts/database_ECOD_X/deepsf_results/ $task_dir/$predict_dir_ECOD_X/   5  $task_dir/$KL_hidden_dir_ECOD_X\n";
system("python  $GLOBAL_PATH/scripts/P1_run_fold_recognition/Analyze_top5_folds.py   $task_dir/$model_dir/$initial_model_name.list_with_fea   $GLOBAL_PATH/database/ECOD/ECOD_X/ecod.latest.fasta_id90_Xgroup_to_label_relation2.txt  $GLOBAL_PATH/database/ECOD/ECOD_X/XGroup2length_withName_hasFea.list    $GLOBAL_PATH/scripts/database_ECOD_X/deepsf_results/ $task_dir/$predict_dir_ECOD_X/   5  $task_dir/$KL_hidden_dir_ECOD_X");


open(TMPFILE,"$task_dir/$model_dir/$initial_model_name.list_with_fea") || die "Failed to run $task_dir/$model_dir/$initial_model_name.list_with_fea\n";
while(<TMPFILE>)
{
	$pdb_name=$_;
	chomp $pdb_name;
	
	$listdir = "$task_dir/$KL_hidden_dir_ECOD_X/search_list_dir";	
	$selected_templist_file = "$listdir/$pdb_name.templist";
	$selected_query_file = "$listdir/$pdb_name.querylist";
	
    print LOG "perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/calculate_hidden_KL_score_list_ECOD_X.pl  $selected_templist_file $selected_query_file $GLOBAL_PATH/database/ECOD/ECOD_X/deepsf_results/   $task_dir/$predict_dir_ECOD_X/   $task_dir/$KL_hidden_dir_ECOD_X/score_ranking_dir  $pdb_name\n";
    $status = system("perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/calculate_hidden_KL_score_list_ECOD_X.pl  $selected_templist_file $selected_query_file $GLOBAL_PATH/database/ECOD/ECOD_X/deepsf_results/   $task_dir/$predict_dir_ECOD_X/   $task_dir/$KL_hidden_dir_ECOD_X/score_ranking_dir  $pdb_name");
    if($status)
	{
		print LOG  "Failed to run <perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/calculate_hidden_KL_score_list_ECOD_X.pl  $selected_templist_file $selected_query_file  $GLOBAL_PATH/database/ECOD/ECOD_X/deepsf_results/   $task_dir/$predict_dir_ECOD_X/   $task_dir/$KL_hidden_dir_ECOD_X/score_ranking_dir  $pdb_name>\n";
		die "Failed to run <perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/calculate_hidden_KL_score_list_ECOD_X.pl  $selected_templist_file $selected_query_file $GLOBAL_PATH/database/ECOD/ECOD_X/deepsf_results/   $task_dir/$predict_dir_ECOD_X/   $task_dir/$KL_hidden_dir_ECOD_X/score_ranking_dir  $pdb_name>\n";
	}
	
    $KL_file_check = "$task_dir/$KL_hidden_dir_ECOD_X/score_ranking_dir/${pdb_name}_KL_calc.done";
    $finish = 0;
    while(1)
	{
		if($finish ==1)
		{
			last;
		}
		if(-e $KL_file_check)
		{
		   $finish = 1
		}
		sleep(1);
		print "Waiting ".$KL_file_check."\n"; 
	}	
	
        $hidden_feature_file = "$task_dir/$KL_hidden_dir_ECOD_X/score_ranking_dir/${pdb_name}_template_fea.txt";
        $KL_score_file = "$task_dir/$KL_hidden_dir_ECOD_X/score_ranking_dir/${pdb_name}.KL_output";
        
		## need use updated template pdb database in CASP13
		print LOG "perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/combine_top10_hidden_for_5folds_ECOD_X_CAMEO.pl  $KL_score_file $pdb_name   $GLOBAL_PATH/database/ECOD/ECOD_X/deepsf_results/  $task_dir/$predict_dir_ECOD_X/  $task_dir/$KL_hidden_dir_ECOD_X/score_ranking_dir  $hidden_feature_file $GLOBAL_PATH\n";
        $status = system("perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/combine_top10_hidden_for_5folds_ECOD_X_CAMEO.pl  $KL_score_file $pdb_name   $GLOBAL_PATH/database/ECOD/ECOD_X/deepsf_results/  $task_dir/$predict_dir_ECOD_X/  $task_dir/$KL_hidden_dir_ECOD_X/score_ranking_dir  $hidden_feature_file $GLOBAL_PATH");
        if($status)
		{
			print LOG  "Failed to run <perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/combine_top10_hidden_for_5folds_ECOD_X_CAMEO.pl  $KL_score_file $pdb_name  $GLOBAL_PATH/database/ECOD/ECOD_X/deepsf_results/  $task_dir/$predict_dir_ECOD_X/  $task_dir/$KL_hidden_dir_ECOD_X/score_ranking_dir  $hidden_feature_file $GLOBAL_PATH\n";
			die "Failed to run <perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/combine_top10_hidden_for_5folds_ECOD_X_CAMEO.pl  $KL_score_file $pdb_name   $GLOBAL_PATH/database/ECOD/ECOD_X/deepsf_results/  $task_dir/$predict_dir_ECOD_X/  $task_dir/$KL_hidden_dir_ECOD_X/score_ranking_dir  $hidden_feature_file $GLOBAL_PATH\n";
		}
		
        
    $hidden_feature_file_check = $hidden_feature_file.'.done';
    $finish = 0;
    while(1)
	{
		if($finish ==1)
		{
			last;
		}
		if(-e $hidden_feature_file_check)
		{
		   $finish = 1
		}
		sleep(1);
		print "Waiting ".$hidden_feature_file_check."\n";
	}	
}
close TMPFILE;



$fold_description = "$GLOBAL_PATH/database/ECOD/ECOD_X/ecod.latest.fasta_id90_webinfo.txt";
$family_description = "$GLOBAL_PATH/database/ECOD/ECOD_X/ecod.latest.fasta_id90_webinfo.txt";
### combine the prediction with top1 template 

print LOG "perl  $GLOBAL_PATH/scripts/P1_run_fold_recognition/combine_prediction_with_template_ECOD_X.pl   $task_dir/$model_dir/$initial_model_name.list_with_fea  $task_dir/$predict_dir_ECOD_X/  $GLOBAL_PATH/database/ECOD/ECOD_X/XGroup2length_withName_hasFea.list  $task_dir/$KL_hidden_dir_ECOD_X/score_ranking_dir  $fold_description $family_description $results_dir_targets/$Final_model_dir_ECOD_X\n";
system("perl  $GLOBAL_PATH/scripts/P1_run_fold_recognition/combine_prediction_with_template_ECOD_X.pl   $task_dir/$model_dir/$initial_model_name.list_with_fea  $task_dir/$predict_dir_ECOD_X/  $GLOBAL_PATH/database/ECOD/ECOD_X/XGroup2length_withName_hasFea.list $task_dir/$KL_hidden_dir_ECOD_X/score_ranking_dir  $fold_description $family_description $results_dir_targets/$Final_model_dir_ECOD_X");



print LOG "\n\n";




## visualize the heatmap 
$curr_time = localtime;

$firstprotein="";
print LOG "$curr_time\nPlot the heatmaps:\n";
open(INFILE,"$task_dir/$model_dir/$initial_model_name.list_with_fea") || die "Failed to open file $task_dir/$model_dir/$initial_model_name.list_with_fea\n";
$c = 0;
while(<INFILE>)
{
	$pdb_name=$_;
	chomp $pdb_name;
	$c++;
	if($c==1)
	{
		$firstprotein=$pdb_name;
	}
	
	$rankfile = "$task_dir/$predict_dir_ECOD_X/${pdb_name}.rank_list";
	$rankfile_image = "$task_dir/$predict_dir_ECOD_X/${pdb_name}_prediction_prob.png";
	#sleep(2);
	print LOG "python $GLOBAL_PATH/scripts/P1_run_fold_recognition/Visualize_prediction.py  $rankfile $rankfile_image\n";
	system("python $GLOBAL_PATH/scripts/P1_run_fold_recognition/Visualize_prediction.py  $rankfile $rankfile_image");
	`cp $rankfile_image $results_dir_targets/$Final_prediction_dir_ECOD_X/`;
	
}
close INFILE;


##############################  visualize the top 10 predictions in ECOD_H 


print LOG "python  $GLOBAL_PATH/scripts/P1_run_fold_recognition/Analyze_top5_folds.py   $task_dir/$model_dir/$initial_model_name.list_with_fea   $GLOBAL_PATH/database/ECOD/ECOD_H/ecod.latest.fasta_id90_XHgroup_to_label_relation2.txt $GLOBAL_PATH/database/ECOD/ECOD_H/XHGroup2length_withName_hasFea.list    $GLOBAL_PATH/database/ECOD/ECOD_H/deepsf_results/ $task_dir/$predict_dir_ECOD_H/   5  $task_dir/$KL_hidden_dir_ECOD_H\n";
system("python  $GLOBAL_PATH/scripts/P1_run_fold_recognition/Analyze_top5_folds.py   $task_dir/$model_dir/$initial_model_name.list_with_fea    $GLOBAL_PATH/database/ECOD/ECOD_H/ecod.latest.fasta_id90_XHgroup_to_label_relation2.txt $GLOBAL_PATH/database/ECOD/ECOD_H/XHGroup2length_withName_hasFea.list   $GLOBAL_PATH/database/ECOD/ECOD_H/deepsf_results/ $task_dir/$predict_dir_ECOD_H/   5  $task_dir/$KL_hidden_dir_ECOD_H ");




open(TMPFILE,"$task_dir/$model_dir/$initial_model_name.list_with_fea") || die "Failed to run $task_dir/$model_dir/$initial_model_name.list_with_fea\n";
while(<TMPFILE>)
{
	$pdb_name=$_;
	chomp $pdb_name;
	
	$listdir = "$task_dir/$KL_hidden_dir_ECOD_H/search_list_dir";	
	$selected_templist_file = "$listdir/$pdb_name.templist";
	$selected_query_file = "$listdir/$pdb_name.querylist";
	
    print LOG "perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/calculate_hidden_KL_score_list_ECOD_H.pl  $selected_templist_file $selected_query_file $GLOBAL_PATH/database/ECOD/ECOD_H/deepsf_results/   $task_dir/$predict_dir_ECOD_H/   $task_dir/$KL_hidden_dir_ECOD_H/score_ranking_dir  $pdb_name\n";
    $status = system("perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/calculate_hidden_KL_score_list_ECOD_H.pl  $selected_templist_file $selected_query_file $GLOBAL_PATH/database/ECOD/ECOD_H/deepsf_results/   $task_dir/$predict_dir_ECOD_H/   $task_dir/$KL_hidden_dir_ECOD_H/score_ranking_dir  $pdb_name");
    if($status)
	{
		print LOG  "Failed to run <perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/calculate_hidden_KL_score_list_ECOD_H.pl  $selected_templist_file $selected_query_file  $GLOBAL_PATH/database/ECOD/ECOD_H/deepsf_results/   $task_dir/$predict_dir_ECOD_H/   $task_dir/$KL_hidden_dir_ECOD_H/score_ranking_dir  $pdb_name\n";
		die "Failed to run <perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/calculate_hidden_KL_score_list_ECOD_H.pl  $selected_templist_file $selected_query_file $GLOBAL_PATH/database/ECOD/ECOD_H/deepsf_results/   $task_dir/$predict_dir_ECOD_H/   $task_dir/$KL_hidden_dir_ECOD_H/score_ranking_dir  $pdb_name\n";
	}
	
    $KL_file_check = "$task_dir/$KL_hidden_dir_ECOD_H/score_ranking_dir/${pdb_name}_KL_calc.done";
    $finish = 0;
    while(1)
	{
		if($finish ==1)
		{
			last;
		}
		if(-e $KL_file_check)
		{
		   $finish = 1
		}
		sleep(1);
		print "Waiting ".$KL_file_check."\n";
	}	
	
        $hidden_feature_file = "$task_dir/$KL_hidden_dir_ECOD_H/score_ranking_dir/${pdb_name}_template_fea.txt";
        $KL_score_file = "$task_dir/$KL_hidden_dir_ECOD_H/score_ranking_dir/${pdb_name}.KL_output";
        
		## need use updated template pdb database in CASP13
		print LOG "perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/combine_top10_hidden_for_5folds_ECOD_H_CAMEO.pl  $KL_score_file $pdb_name   $GLOBAL_PATH/database/ECOD/ECOD_H/deepsf_results/  $task_dir/$predict_dir_ECOD_H/  $task_dir/$KL_hidden_dir_ECOD_H/score_ranking_dir  $hidden_feature_file $GLOBAL_PATH\n";
        $status = system("perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/combine_top10_hidden_for_5folds_ECOD_H_CAMEO.pl  $KL_score_file $pdb_name   $GLOBAL_PATH/database/ECOD/ECOD_H/deepsf_results/  $task_dir/$predict_dir_ECOD_H/  $task_dir/$KL_hidden_dir_ECOD_H/score_ranking_dir  $hidden_feature_file $GLOBAL_PATH");
        if($status)
		{
			print LOG  "Failed to run <perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/combine_top10_hidden_for_5folds_ECOD_H_CAMEO.pl  $KL_score_file $pdb_name   $GLOBAL_PATH/database/ECOD/ECOD_H/deepsf_results/  $task_dir/$predict_dir_ECOD_H/  $task_dir/$KL_hidden_dir_ECOD_H/score_ranking_dir  $hidden_feature_file $GLOBAL_PATH>\n";
			die "Failed to run <perl $GLOBAL_PATH/scripts/P1_run_fold_recognition/combine_top10_hidden_for_5folds_ECOD_H_CAMEO.pl  $KL_score_file $pdb_name   $GLOBAL_PATH/database/ECOD/ECOD_H/deepsf_results/  $task_dir/$predict_dir_ECOD_H/  $task_dir/$KL_hidden_dir_ECOD_H/score_ranking_dir  $hidden_feature_file $GLOBAL_PATH>\n";
		}
		
        
    $hidden_feature_file_check = $hidden_feature_file.'.done';
    $finish = 0;
    while(1)
	{
		if($finish ==1)
		{
			last;
		}
		if(-e $hidden_feature_file_check)
		{
		   $finish = 1
		}
		sleep(1);
		print "Waiting ".$hidden_feature_file_check."\n";
	}	
}
close TMPFILE;


$fold_description = "$GLOBAL_PATH/database/ECOD/ECOD_X/ecod.latest.fasta_id90_webinfo.txt";
$family_description = "$GLOBAL_PATH/database/ECOD/ECOD_X/ecod.latest.fasta_id90_webinfo.txt";
### combine the prediction with top1 template 

print LOG "perl  $GLOBAL_PATH/scripts/P1_run_fold_recognition/combine_prediction_with_template_ECOD_H.pl   $task_dir/$model_dir/$initial_model_name.list_with_fea  $task_dir/$predict_dir_ECOD_H/    $GLOBAL_PATH/database/ECOD/ECOD_H/XHGroup2length_withName_hasFea.list  $task_dir/$KL_hidden_dir_ECOD_H/score_ranking_dir  $fold_description $family_description $results_dir_targets/$Final_model_dir_ECOD_H\n";
system("perl  $GLOBAL_PATH/scripts/P1_run_fold_recognition/combine_prediction_with_template_ECOD_H.pl   $task_dir/$model_dir/$initial_model_name.list_with_fea  $task_dir/$predict_dir_ECOD_H/    $GLOBAL_PATH/database/ECOD/ECOD_H/XHGroup2length_withName_hasFea.list  $task_dir/$KL_hidden_dir_ECOD_H/score_ranking_dir  $fold_description $family_description $results_dir_targets/$Final_model_dir_ECOD_H");




## visualize the heatmap 
$curr_time = localtime;

$firstprotein="";
print LOG "$curr_time\nPlot the heatmaps:\n";
open(INFILE,"$task_dir/$model_dir/$initial_model_name.list_with_fea") || die "Failed to open file $task_dir/$model_dir/$initial_model_name.list_with_fea\n";
$c = 0;
while(<INFILE>)
{
	$pdb_name=$_;
	chomp $pdb_name;
	$c++;
	if($c==1)
	{
		$firstprotein=$pdb_name;
	}
	
	$rankfile = "$task_dir/$predict_dir_ECOD_H/${pdb_name}.rank_list";
	$rankfile_image = "$task_dir/$predict_dir_ECOD_H/${pdb_name}_prediction_prob.png";
	#sleep(2);
	print LOG "python $GLOBAL_PATH/scripts/P1_run_fold_recognition/Visualize_prediction.py  $rankfile $rankfile_image\n";
	system("python $GLOBAL_PATH/scripts/P1_run_fold_recognition/Visualize_prediction.py  $rankfile $rankfile_image");
	`cp $rankfile_image $results_dir_targets/$Final_prediction_dir_ECOD_H/`;
	
}
close INFILE;

SUMMARY:

### get SCOP template proteins and add to %query_template_sequences
%template_list_summary=();
foreach $qid (sort keys %query_sequences)
{

	$fold_rankfile = "$task_dir/$jobname-predict-out/$qid.rank_list";
	if(!(-e $fold_rankfile))
	{
		print "!!! Failed to find $fold_rankfile\n";
		next;
	}
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
		$template_file = "$task_dir/$KL_hidden_dir/score_ranking_dir/${qid}_top5_folds_info/fold_$fd";
		if(!(-e $template_file))
		{
			print "!!! Failed to find template rank: $template_file\n";
			next;
		}
		open(TMPIN2,"$template_file");
		$tmp_num=0;
		while(<TMPIN2>)
		{
			$line2=$_;
			chomp $line2;
			@tmp2 = split(/\t/,$line2);
			$tplate = $tmp2[1];
			$score = $tmp2[2];
			$template_list_summary{$line2} = $score;
			if($tmp_num >10) # at most 10 templates for each fold
			{
				last;
			}
			
		}
		close TMPIN2;
		
	}
	close TMPIN;
}


### get ECOD_X template proteins and add to %query_template_sequences
foreach $qid (sort keys %query_sequences)
{

	$fold_rankfile = "$task_dir/$jobname-predict-out-ECOD_X/$qid.rank_list";
	if(!(-e $fold_rankfile))
	{
		print "!!! Failed to find $fold_rankfile\n";
		next;
	}
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
		$template_file = "$task_dir/$KL_hidden_dir_ECOD_X/score_ranking_dir/${qid}_top5_folds_info/fold_$fd";
		if(!(-e $template_file))
		{
			print "!!! Failed to find template rank: $template_file\n";
			next;
		}
		open(TMPIN2,"$template_file");
		$tmp_num=0;
		while(<TMPIN2>)
		{
			$line2=$_;
			chomp $line2;
			@tmp2 = split(/\t/,$line2);
			$tplate = $tmp2[1];
			$score = $tmp2[2];
			$template_list_summary{$line2} = $score;
			$tmp_num++;
			if($tmp_num >10) # at most 10 templates for each fold
			{
				last;
			}
			
		}
		close TMPIN2;
		
	}
	close TMPIN;
}


### get ECOD_H template proteins and add to %query_template_sequences
foreach $qid (sort keys %query_sequences)
{

	$fold_rankfile = "$task_dir/$jobname-predict-out-ECOD_H/$qid.rank_list";
	if(!(-e $fold_rankfile))
	{
		print "!!! Failed to find $fold_rankfile\n";
		next;
	}
	open(TMPIN,"$fold_rankfile");
	$fold_index = 0;
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
		$template_file = "$task_dir/$KL_hidden_dir_ECOD_H/score_ranking_dir/${qid}_top5_folds_info/fold_$fd";
		if(!(-e $template_file))
		{
			print "!!! Failed to find template rank: $template_file\n";
			next;
		}
		open(TMPIN2,"$template_file");
		$tmp_num=0;
		while(<TMPIN2>)
		{
			$line2=$_;
			chomp $line2;
			@tmp2 = split(/\t/,$line2);
			$tplate = $tmp2[1];
			$score = $tmp2[2];
			$template_list_summary{$line2} = $score;
			$tmp_num++;
			if($tmp_num >10) # at most 10 templates for each fold
			{
				last;
			}
			
		}
		close TMPIN2;
		
	}
	close TMPIN;
}

$template_rank_out = "$task_dir/template_rank_summary";
if(!(-d $template_rank_out))
{
	`mkdir $template_rank_out`;
}else{
	`rm -rf $template_rank_out/*`;
}

foreach $info (sort {$template_list_summary{$a} <=> $template_list_summary{$b}} keys %template_list_summary)
{
	@tmp2 = split(/\t/,$info);
	$query_id = $tmp2[0];
	if(-e "$template_rank_out/$query_id.rank")
	{
		open(OUTTMP,">>$template_rank_out/$query_id.rank");
		print OUTTMP "$info\n";
		close OUTTMP;
	}else{
		open(OUTTMP,">$template_rank_out/$query_id.rank");
		print OUTTMP "$info\n";
		close OUTTMP;
	}
}


chdir "$task_dir";
CLEAN:

`cp -avr $model_dir  $results_dir_targets/`; # this is for deepsf webservice

$curr_time = localtime;
print LOG "$curr_time\nJob $jobname Finished\n";
close LOG;

#create a .done file once the job is complete
$done = "$task_dir/.done";
$done_job ="touch $done";
system($done_job);


`touch $task_dir/Deepsf_stage1.finished`;


###################################################################################################################

