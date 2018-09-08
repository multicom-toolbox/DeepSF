import sys
import os
import os.path
import math
import shutil
import numpy 
import time
import subprocess
import errno  


def generate_PSSM(seq_name,seq_file,output_dir,pssm_tool_dir,nr_db):

	exact_script=pssm_tool_dir+'/script/generate_flatblast.pl'
	script_dir=pssm_tool_dir+'/script/'
	blast_dir=pssm_tool_dir+'/blast-2.2.17/bin'
	big_db=pssm_tool_dir+'/db/big/big_98_X'
	#nr_db='/home/jh7x3/CASP13_development/DeepSF-3D/version-V2-2017-12-05/deepsf3d_tools/nr_db/nr90'
	nr_db=nr_db
	#seq_file=
	output_prefix_alg=output_dir+seq_name


	#print 'perl script_dir'+' blast_dir script_dir big_db nr_db seq_file output_prefix_alg >/home/lihaio/JieShare/ProteinTorsionAngle_Prediction/Outputs/features/tmp/tmp '
	subprocess.call(["perl", exact_script, blast_dir, script_dir, big_db, nr_db, seq_file, output_prefix_alg ])
	#+'>/home/lihaio/JieShare/ProteinTorsionAngle_Prediction/Outputs/features/tmp/tmp'

def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise

if __name__ == '__main__':

	#print len(sys.argv)
	if len(sys.argv) != 7:
		print 'please input the right parameters sequence_name,sequence_file,install_dir, output_dir'
		sys.exit(1)

	sequence=sys.argv[1]
	sequence_file=sys.argv[2]
	install_dir=sys.argv[3] #/home/jh7x3/machine_learning_bioinformatics/Tools/pspro2.0/
	outdir=sys.argv[4]
	pssm_tool_dir=sys.argv[5]
	nr_db=sys.argv[6]

	input_file=sequence_file
	output_dir=outdir+'/pssm_features/'
	if os.path.isdir(output_dir):
		print "Empty feature folder: ",output_dir
		filelist = [ f for f in os.listdir(output_dir)]
		for f in filelist:
			if "pssm" in f or "PSSM" in f : 
				continue
			print "remove file: ",f
			file_to_remove = output_dir +'/'+f
			os.remove(file_to_remove)
	else:
		print "Creating feature folder: ",output_dir
		mkdir_p(output_dir)
	

	#produce PSSM
	#pssm_tool_dir='/home/jh7x3/CASP13_development/DeepSF-3D/version-V2-2017-12-05/deepsf3d_tools/pspro2.0/' 
	generate_PSSM(seq_name=sequence,seq_file=input_file,output_dir=output_dir,pssm_tool_dir=pssm_tool_dir,nr_db=nr_db)
