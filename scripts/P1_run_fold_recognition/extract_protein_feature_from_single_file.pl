#!/usr/bin/perl -w

if (@ARGV != 2) {
  print "Usage: <input> <output>\n";
  exit;
}

$inputfile = "$ARGV[0]";#
$outdir =  "$ARGV[1]"; #



open(IN,"$inputfile") || die "Failed to open file $inputfile\n";
open(TMP,">$outdir/tmpfile") || die "Failed to open file $outdir/tmpfile\n";
while(<IN>)
{
	$line = $_;
	chomp $line;
	if(substr($line,0,1) eq '>')
	{
		print TMP "$line|";
	}else{
		print TMP "$line\n";
	}
}
close IN;
close TMP;
open(IN,"$outdir/tmpfile") || die "Failed to open file $outdir/tmpfile\n";
while(<IN>)
{
	$line = $_;
	chomp $line;
	@tmp = split(/\|/,$line);
	$proteinid = $tmp[0];
	$feature = $tmp[1];
	$proteinidnew = $proteinid;
	if(substr($proteinid,0,1) eq '>')
	{
		$proteinidnew =substr($proteinid,1);
	}
	open(TMP,">$outdir/$proteinidnew.fea_aa_ss_sa") || die "Failed to open file $outdir/$proteinidnew.fea_aa_ss_sa\n";
	print TMP "$proteinid\n$feature\n";
	close TMP;
}
close IN;	

			






