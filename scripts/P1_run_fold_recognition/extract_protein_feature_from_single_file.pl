#!/usr/bin/perl -w

if (@ARGV != 2) {
  print "Usage: <input> <output>\n";
  exit;
}

$inputfile = "$ARGV[0]";#/home/jh7x3/DLS2F/DLS2F_Project/PDB_SCOP95_SEQ/Feature_data_SCOP/Feature_data_SCOP_generation/PDB_SCOP95_ss_sa_aa_not_generated_withLabel.fea 
$outdir =  "$ARGV[1]"; # Feature_aa_ss_sa



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

			






