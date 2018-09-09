$numArgs = @ARGV;
if($numArgs != 3)
{
        print "the number of parameters is not correct!\n";
        exit(1);
}

$list_file         = "$ARGV[0]";
$option_file       = "$ARGV[1]";
$outfolder      = "$ARGV[2]";

if(!(-d $outfolder))
{
	`mkdir $outfolder`;
}
chdir($outfolder);



-f $option_file || die "option file doesn't exist.\n";
-f $list_file || die "query file doesn't exist.\n";
-d $outfolder || die "output dir doesn't exist.\n";

#read option file

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


#generate features
open(LIB, $list_file) || die "can't read selected list file.\n";
@idlist = <LIB>;
close LIB;

#remove title
#shift @idlist;
#split  for threads
$total = @idlist; 
if ($total < $thread_num)
{
	$thread_num = 1; 
}

$max_num = int($total / $thread_num) + 1; 
$thread_dir = "profiles-thread";
for ($i = 0; $i < $thread_num; $i++)
{
	`mkdir $outfolder/$thread_dir$i`; 	

	open(THREAD, ">$thread_dir$i/lib$i.list") || die "can't create template file for thread $i\n";
	#print THREAD "Ranked templates for $name, thread$i\n";

	#allocate templates for thread
	for ($j = $i * $max_num; $j < ($i+1) * $max_num && $j < $total; $j++)
	{
		print THREAD $idlist[$j];
	}
	close THREAD;

}
#run treads to generate features
#input: working dir, prosys dir, query seq name, query file, query opt name, library file, output file, thread id

#use Thread; 


#input: working dir, prosys dir, query seq name, query file, query opt name, library file, output file, thread id
sub create_feature
{
	my ($work_dir, $libfile) = @_; 
	
	chdir $work_dir; 
	
	open(IN,"$libfile") || die "Failed to open file $libfile\n";
	while(<IN>)
	{
		$line=$_;
		chomp $line;
		@tmp = split(/\t/,$line);
		$id_tmp = $tmp[0];
		$seq = $tmp[1];
		if(substr($id_tmp,0,1) eq '>')
		{
			$id_tmp = substr($id_tmp,1);
		}
		open(TMPO,">$work_dir/$id_tmp.fasta");
		print TMPO ">$id_tmp\n$seq\n";
		close TMPO;
		
		print("$deepsf_dir/P0_prepare_features/gen_query_files.pl $option_file $work_dir/$id_tmp.fasta $work_dir\n\n");
		system("$deepsf_dir/P0_prepare_features/gen_query_files.pl $option_file $work_dir/$id_tmp.fasta $work_dir");

		########################################################################### 
		#Generate secondary structure using PSI-PRED
		$cur_dir = `pwd`;
		chomp $cur_dir;
		chdir $work_dir;
		#print("$prosys_dir/script/hhsearch_align_prepare.pl $prosys_dir $new_hhsearch_dir $psipred_dir $qname.fas $qname.shhm\n");
		#/home/casp13/MULTICOM_package/software/prosys/script/
		print("$deepsf_dir/P0_prepare_features/hhsearch_align_prepare.pl $prosys_dir $new_hhsearch_dir $psipred_dir $work_dir/$id_tmp.fas $work_dir/$id_tmp.shhm");
		system("$deepsf_dir/P0_prepare_features/hhsearch_align_prepare.pl $prosys_dir $new_hhsearch_dir $psipred_dir $work_dir/$id_tmp.fas $work_dir/$id_tmp.shhm");
		chdir $work_dir;
	}
	close IN;
	
}


$post_process = 0; 

for ($i = 0; $i  < $thread_num; $i++)
{
#	$threads[$i] = new Thread \&create_feature, "$full_path/$thread_dir$i", $prosys_dir, $name, $query_file, $query_opt, "lib$i.fasta", "thread$i.out", $i;
	if ( !defined( $kidpid = fork() ) )
	{
		die "can't create process $i\n";
	}
	elsif ($kidpid == 0)
	{
		#within the child process
		print "start thread $i\n";
		&create_feature("$outfolder/$thread_dir$i", "$outfolder/$thread_dir$i/lib$i.list");
		goto END;
	}
	else
	{
		$thread_ids[$i] = $kidpid;
	}
	
}

`mkdir $outfolder/library`;
#collect results
#wait threads to return
use Fcntl qw (:flock);
if ($i == $thread_num && $post_process == 0)
{
	#print "postprocess: $i\n";
	$post_process = 1; 
	chdir $outfolder;
	
	for ($i = 0; $i < $thread_num; $i++)
	{
		#$threads[$i]->join;
		if (defined $thread_ids[$i])
		{
			print "wait thread $i ";
			waitpid($thread_ids[$i], 0);
			$thread_ids[$i] = ""; 
			print "done\n";
		}
		
		`mv $outfolder/$thread_dir$i/*align $outfolder/library`;
		`mv $outfolder/$thread_dir$i/*aln $outfolder/library`;
		`mv $outfolder/$thread_dir$i/*chk $outfolder/library`;
		`mv $outfolder/$thread_dir$i/*fas $outfolder/library`;
		`mv $outfolder/$thread_dir$i/*hmm $outfolder/library`;
		`mv $outfolder/$thread_dir$i/*lob $outfolder/library`;
		`mv $outfolder/$thread_dir$i/*shhm $outfolder/library`;
		#remove thread dir
	}

}
END:
#	`rm -r -f $full_path/$thread_dir$i 2>/dev/null`;
