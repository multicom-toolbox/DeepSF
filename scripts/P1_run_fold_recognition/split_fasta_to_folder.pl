if (@ARGV != 3)
{
	die "need two inputs: hhsearch result file, output file.\n";
}

$fastafile = shift @ARGV;
$outputdir = shift @ARGV;
$fastalist = shift @ARGV;


open(TMP,">tmp.fa") || die "Failed to open file tmp.fa\n";
open(INPUT,"$fastafile") || die "Failed to open file $fastafile\n";
open(OUT,">$fastalist") || die "Failed to open file $fastalist\n";

$num=0;
while(<INPUT>)
{
	$line=$_;
	chomp $line;
	if(substr($line,0,1) eq '>')
	{
		$num++;
		if($num == 1)
		{
			print TMP "$line\t";
		}else{
			print TMP "\n$line\t";
		}
	}else{
		print TMP "$line";
	}
}
close INPUT;
close TMP;

open(TMP,"tmp.fa") || die "Failed to open file tmp.fa\n";

while(<TMP>)
{
	$line=$_;
	chomp $line;
	@content = split(/\t/,$line);
	$name_info = $content[0];
	$seq = $content[1];
	@content2 = split(/\s/,$name_info);
	$name = $content2[0];
	if(substr($name,0,1) eq '>')
	{
		$name = substr($name,1);
	}
	print OUT "$name\n";
	open(OUTFILE,">$outputdir/$name") || die "Failed to write to $outputdir/$name\n";
	print OUTFILE "$name_info\n$seq\n";
	close OUTFILE;
	
	
}
close TMP;
close OUT;
