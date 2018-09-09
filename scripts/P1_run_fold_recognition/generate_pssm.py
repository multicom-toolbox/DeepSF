import sys
import os
import os.path
import math
import shutil
import numpy 
import time
import subprocess
import errno  


def generate_PSSM(seq_name,seq_file,output_dir,pssm_tool_dir,nr_db,big_db):

	exact_script=pssm_tool_dir+'/script/generate_flatblast.pl'
	script_dir=pssm_tool_dir+'/script/'
	blast_dir=pssm_tool_dir+'/blast-2.2.17/bin'
	big_db=big_db
	nr_db=nr_db
	#seq_file=
	output_prefix_alg=output_dir+seq_name

	subprocess.call(["perl", exact_script, blast_dir, script_dir, big_db, nr_db, seq_file, output_prefix_alg ])
	

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
	if len(sys.argv) != 8:
		print 'please input the right parameters sequence_name,sequence_file,install_dir, output_dir' 
		sys.exit(1)

	sequence=sys.argv[1]
	sequence_file=sys.argv[2]
	install_dir=sys.argv[3]
	outdir=sys.argv[4]
	pssm_tool_dir=sys.argv[5]
	nr_db=sys.argv[6]
	big_db=sys.argv[7]

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
	generate_PSSM(seq_name=sequence,seq_file=input_file,output_dir=output_dir,pssm_tool_dir=pssm_tool_dir,nr_db=nr_db,big_db=big_db)
