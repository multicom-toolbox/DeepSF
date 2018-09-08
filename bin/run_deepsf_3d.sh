#!/bin/sh
# DeepSF for protein fold recognition and tertiary structure prediction#
if [ $# -lt 3 ]
then
	echo "need three parameters : target id, path of fasta sequence, directory of output"
	exit 1
fi

targetid=$1 #test
fasta=$2 #
outputfolder=$3


source /home/casp13/python_virtualenv/bin/activate

echo "perl /home/casp13/deepsf_3d/Github/DeepSF/scripts/deepsf_fr.pl /home/casp13/deepsf_3d/Github/DeepSF/scripts/fr_option_adv_for_deepsf    $fasta   $outputfolder  &>  $outputfolder/run_deepsf.log\n"

#perl /home/casp13/deepsf_3d/scripts/deepsf-main-V1-2018-04-09.pl $targetid  $fasta    /home/casp13/deepsf_3d/scripts/DeepSF_option  $outputfolder  &>  $outputfolder/run_deepsf.log

perl /home/casp13/deepsf_3d/Github/DeepSF/scripts/deepsf_fr.pl /home/casp13/deepsf_3d/Github/DeepSF/scripts/fr_option_adv_for_deepsf    $fasta   $outputfolder  &>  $outputfolder/run_deepsf.log




