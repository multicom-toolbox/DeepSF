#!/usr/bin/perl -w

if (@ARGV != 2)
{
	die "Usage: blast_dir big_db nr_db ss_predictor script_dir seq_file(fasta) output_file\n";
}

$seq_file = shift @ARGV;
$sa_results = shift @ARGV;

################verify if all the things are there#########################
if (! -f $seq_file)
{
	die "can't find fasta file: $seq_file.\n";
}


if (! -f $sa_results)
{
	die "can't find solvent accessibility results: $sa_results.\n";
}

#############################End of Verification#######################################


$output_file = $sa_results.'.saencoding';

#extract sequence file name
$slash_pos = rindex($seq_file, "/");
if ($slash_pos != -1)
{
	$seq_filename = substr($seq_file, $slash_pos + 1, length($seq_file) - $slash_pos - 1); 
}
else
{
	$seq_filename = $seq_file; 
}
if (length($seq_filename) <= 0)
{
	die "sequence file name shouldn't be less or equal 0.\n"; 
}

#non-char and . is not allowed for ouput file name 
$seq_filename =~ s/\s/_/g; 
$seq_filename =~ s/\./_/g;  


open(SEQ_FILE, "$seq_file") || die "can't open sequence file.\n";
@content = <SEQ_FILE>;
close(SEQ_FILE);
$name = shift @content;
chomp $name; 
$sequence = shift @content; 

#remove unseen dos format (cause the program fail)
$name =~ s/\s//g;
$sequence =~ s/\s//g;

#check the sequence format
if (substr($name, 0, 1) ne ">") 
{
	die "sequence file: $seq_file is not in fasta format.\n"; 
}
$name = substr($name, 1, length($name) - 1); 
$target_name = $name; 
if (length($target_name) == 0)
{
	$target_name = "unknown"; 
}
if (length($sequence) < 1)
{
	die "seqeunce is empty. \n"; 
}

############ Start parse the ss and sa file, added by jie 09292015

#########################    Start encoding sa   #########################################
print "Starting encoding SA \n";
open(TMP, ">$output_file") || die "can't create temporary file for $output_file.\n"; 
open(ACCPRO, "$sa_results") || die "can't open the sa result file $sa_results.\n";
@accpro = <ACCPRO>;
shift @accpro;
#$seq = shift @accpro;
$acc = shift @accpro;
#chomp $seq;
chomp $acc;

if(length($sequence) ne length($acc))
{
	print "sequence.: ".length($sequence)."\n";
	print "acc.: ".length($acc)."\n";
	die "The sequence length is not equal to sa length\n";
	exit;
}

@SA_cat = ('E','B');
$ind=0;
%SA_id=();
foreach $res (@SA_cat)
{
	$SA_id{$res} = $ind;
	$ind ++;	
}
# print out 
#print "SA id\n";
foreach $res (@SA_cat)
{
	#print $res."\t".$SA_id{$res}."\n";
}

%SA_encode=();
foreach $res (@SA_cat)
{
	@tmp=();
	for($i=0;$i<2;$i++)
	{
		if($i eq $SA_id{$res})
		{
			push(@tmp,'1');
		}else{
			push(@tmp,'0');
		}
	}
	$SA_encode{$res} = join(" ",@tmp);
}
# print out 
#print "Encoding \n";
foreach $res (@SA_cat)
{
	#print $res."\t".$SA_encode{$res}."\n";
}

$encoding_fea = "";
print "length ".length($sequence)."\n";
for($i=0;$i<length($sequence);$i++)
{
	$id = $i+1;
	$res = substr($sequence,$i,1);
	$res_SA = substr($acc,$i,1);
	if($res_SA eq '-')
	{
		$res_SA = 'B';
	}
	if($res_SA eq 'e')
	{
		$res_SA = 'E';
	}
	
	$res_SA_encode = $SA_encode{$res_SA};
	$encoding_fea .=$res_SA_encode." ";
	print TMP $id.':'.$res."\t".$res_SA_encode."\n";
}
close TMP;
#remove last space
$encoding_fea = substr($encoding_fea,0,length($encoding_fea)-1);
@temp = split(/\s/,$encoding_fea);
$c = 0;
$encoding_fea_new ="";
foreach $item (@temp)
{
	$encoding_fea_new .=($c+1).":". $item." ";
	$c++;
}
#remove last space
$encoding_fea_new = substr($encoding_fea_new,0,length($encoding_fea_new)-1);
#$l= length($seq);
#print "The sequence is: \n $seq \n The encoding feature for SA is:\n".$encoding_fea_new."\n";
print "SA encoding finished \n"
