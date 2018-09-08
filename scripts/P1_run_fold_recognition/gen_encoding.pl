#!/usr/bin/perl -w

if (@ARGV !=2) {
  print "Usage: <input> <output>\n";
  exit;
}

$fasta_file = $ARGV[0];
$output_dir = $ARGV[1];



if (! -f $fasta_file)
{
	die "can't find file: $fasta_file.\n"; 
}

if (! -d $output_dir)
{
	die "the output directory doesn't exists.\n"; 
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

#output prefix is used as the prefix name of output files
$output_prefix = $output_dir . $seq_filename; 

############################  Set the encoding for each residue
### Set the protein residues
%AA3TO1 = qw(ALA A ASN N CYS C GLN Q HIS H LEU L MET M PRO P THR T TYR Y ARG R ASP D GLU E GLY G ILE I LYS K PHE F SER S TRP W VAL V);
#%AA1TO3 = reverse %AA3TO1;
@AA3=();
@AA1=();
foreach my $residue ( sort keys %AA3TO1) {
    push(@AA3,$residue);
}
foreach my $residue (@AA3) {
    push(@AA1,$AA3TO1{$residue});
}
#print "AA3: ".join(" ",@AA3)."\n";
#print "AA1: ".join(" ",@AA1)."\n";
### index the residue, assign it the index
%AA_id=();
$ind = 0;
foreach $res (@AA1)
{
	$AA_id{$res} = $ind;
	$ind ++;	
}
# print out 
#print "AA id\n";
foreach $res (@AA1)
{
	#print $res."\t".$AA_id{$res}."\n";
}

### Generate the encoding for each residue, a vector with 20 1/0 for each residue
%AA_encode=();
foreach $res (@AA1)
{
	@tmp=();
	for($i=0;$i<20;$i++)
	{
		if($i eq $AA_id{$res})
		{
			push(@tmp,'1');
		}else{
			push(@tmp,'0');
		}
	}
	$AA_encode{$res} = join(" ",@tmp);
}
# print out 
print "Encoding \n";
foreach $res (@AA1)
{
	#print $res."\t".$AA_encode{$res}."\n";
}
######################################  Setting finished, start encoding sequence
print "Starting encoding AA\n";
open(FILE,"$fasta_file") || die "Failed to open file $fasta_file \n";
@text=<FILE>;
#read query/target name
$name = shift @text;
chop $name;
$name =~ s/\s/-/g;
#read sequence
$sequence = shift @text;
chop $sequence;
$l=length($sequence);

open(TMP, ">$output_prefix.aaencoding") || die "can't create temporary file for $output_prefix.aaencoding.\n"; 

$encoding_fea = "";
for($i=0;$i<$l;$i++)
{
	$id = $i+1;
	$res = substr($sequence,$i,1);
	#print "Residue: $res\n";
	$res_encode = $AA_encode{$res};
	$encoding_fea .=$res_encode." ";
	print TMP $id.':'.$res."\t".$AA_encode{$res}."\n";
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
#print "The sequence is: \n $sequence \n The encoding feature for length $l is:\n".$encoding_fea_new."\n";
print "AA encoding finished\n";