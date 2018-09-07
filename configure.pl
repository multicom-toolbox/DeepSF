#!/usr/bin/perl -w
 use FileHandle; # use FileHandles instead of open(),close()
 use Cwd;
 use Cwd 'abs_path';

######################## !!! customize settings here !!! ############################
#																					#
# Set installation directory of DeepSF to your unzipped DeepSF directory            #
     
 $install_dir = "/your_path/DeepSF";
######################## !!! End of customize settings !!! ##########################

if($install_dir eq "/your_path/DeepSF")
{# user forgets to set the default path of DeepSF, try to solve this problem
    $install_dir = getcwd;
    $install_dir=abs_path($install_dir);
}


if(!-s $install_dir)
{
	die "The DeepSF directory ($install_dir) is not existing, please revise the customize settings part inside the configure.pl, set the path as  your unzipped DeepSF directory\n";
}
if ( substr($install_dir, length($install_dir) - 1, 1) ne "/" )
{
        $install_dir .= "/";
}

print "checking whether the configuration file run in the installation folder ...";
$cur_dir = `pwd`;
chomp $cur_dir;
$configure_file = "$cur_dir/configure.pl";
if (! -f $configure_file || $install_dir ne "$cur_dir/")
{
        die "\nPlease check the installation directory setting and run the configure program in the installation directory of DeepSF.\n";
}
print " OK!\n";


################Don't Change the code below##############

if (! -d $install_dir)
{
	die "can't find installation directory.\n";
}
if ( substr($install_dir, length($install_dir) - 1, 1) ne "/" )
{
	$install_dir .= "/"; 
}


if (prompt_yn("DeepSF will be installed into <$install_dir> ")){

}else{
	die "The installation is cancelled!\n";
}
print "Start install DeepSF into <$install_dir>\n"; 


$files		="training/P1_evaluate.sh,training/P1_train.sh,training/predict_single.py,training/predict_main.py,training/training_main.py";

@updatelist		=split(/,/,$files);

foreach my $file (@updatelist) {
	$file2update=$install_dir.$file;
	
	$check_log ='GLOBAL_PATH=';
	open(IN,$file2update) || die "Failed to open file $file2update\n";
	open(OUT,">$file2update.tmp") || die "Failed to open file $file2update.tmp\n";
	while(<IN>)
	{
		$line = $_;
		chomp $line;

		if(index($line,$check_log)>=0)
		{
			print $file2update."\n";
			print "Current ".$line."\n";
			print "Change to ".substr($line,0,index($line, '=')+1)." \'".$install_dir."\';\n\n\n";
			print OUT substr($line,0,index($line, '=')+1)."\'".$install_dir."\';\n";
		}else{
			print OUT $line."\n";
		}
	}
	close IN;
	close OUT;
	system("mv $file2update.tmp $file2update");
	system("chmod 755  $file2update");


}


sub prompt_yn {
  my ($query) = @_;
  my $answer = prompt("$query (Y/N): ");
  return lc($answer) eq 'y';
}
sub prompt {
  my ($query) = @_; # take a prompt string as argument
  local $| = 1; # activate autoflush to immediately show the prompt
  print $query;
  chomp(my $answer = <STDIN>);
  return $answer;
}
