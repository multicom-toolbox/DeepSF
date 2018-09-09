

if (@ARGV != 2)
{ # @ARGV used in scalar context = number of args
  exit(1) ;
}
my $starttime = localtime();
print "\nThe time started at : $starttime.\n";
my($pssmdir)=$ARGV[0];
my($outputdir)=$ARGV[1];


%AA3TO1 = qw(ALA A ASN N CYS C GLN Q HIS H LEU L MET M PRO P THR T TYR Y ARG R ASP D GLU E GLY G ILE I LYS K PHE F SER S TRP W VAL V);
%AA1TO3 = reverse %AA3TO1;



opendir(DIR,"$pssmdir") || die "Failed to open dir $pssmdir\n";
@files=readdir(DIR);
foreach $file (@files)
{
	if($file eq "." || $file eq ".." || index($file,'.pssm')<0)
	{
		 next;
	}
	
	$spe_id = substr($file,0,index($file,'.'));
	print "processing $file\n";
	open(IN,"$pssmdir/$file") || die "Failed to open file $pssmdir/$file\n";
	$sequence="";
	$pssm_feature="";
	$non_num=0;
	while(<IN>)
	{
		$line=$_;
		chomp $line;
		@temp = split(/\s+/,$line);
		shift @temp;# space
		shift @temp;# index
		$new_line = join(" ",@temp);
		if(@temp == 21)
		{
			$res = shift @temp;
			chomp $res;
			if(!exists($AA1TO3{$res}))
			{
				print "Unknown aa $res, removed\n";
				$non_num++;
				last;
			}
			$res_fea = join(" ",@temp);
			$sequence .= $res;
			$pssm_feature .=" ".$res_fea;
		}
	}
	close IN;
	if($non_num !=0)
	{
		print "$non_num residues are found, ignore it\n";
		next;
	}
	if(substr($pssm_feature,0,1) eq ' ')
	{
		$pssm_feature = substr($pssm_feature,1);
	}
        open(OUT,">$outputdir/${file}_fea") || die "Failed to open file $outputdir/${file}_fea\n";	
	print OUT ">$spe_id\n";
	#print OUT ">$sequence\n";
	@temp = split(' ',$pssm_feature);
	print OUT "0\t";
	for($k=1;$k<=@temp;$k++)
	{
		if($k==1)
		{
			print OUT "$k:".$temp[$k-1];
		}else{
			print OUT " $k:".$temp[$k-1];
		}
		
	}
	print OUT "\n";
	
	close OUT;
}
closedir(DIR);	
	
