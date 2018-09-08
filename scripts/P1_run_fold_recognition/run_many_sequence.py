import sys
import os
import os.path
import math
import shutil
import numpy 

import sys

import optparse 


parser = optparse.OptionParser()
parser.add_option( '--inputfile', dest = 'inputfile',
    default = '',    # default empty!
    help = 'protein sequence list')
parser.add_option( '--seqdir', dest = 'sequencedir',
    default = '',    # default empty!
    help = 'sequencedir')
parser.add_option( '--script_dir', dest = 'script_dir', #
    default = '',    # default empty!
    help = 'The script directory for generate_features.sh')
parser.add_option( '--pspro_dir', dest = 'pspro_dir', 
    default = '',    # default empty!
    help = 'The directory for pspro')
parser.add_option( '--nr_db', dest = 'nr_db', 
    default = '',    # default empty!
    help = 'The path for nr90')
parser.add_option( '--big_db', dest = 'big_db', 
    default = '',    # default empty!
    help = 'The path for big_db')
parser.add_option( '--outputdir', dest = 'outputdir',
    default = '',    # default empty!
    help = 'The output directory for prediction')
(options,args) = parser.parse_args()

data_file = options.inputfile
sequence_dir = options.sequencedir
output_dir = options.outputdir 
script_dir = options.script_dir 
pspro_dir = options.pspro_dir  #
nr_db = options.nr_db  #
big_db = options.big_db  #


sequence_file=open(data_file,'r').readlines() 
script= script_dir +'/generate_features.sh'
for i in xrange(len(sequence_file)):
    #pdb_name=sequence_file[i].split('.')[0]
    pdb_name=sequence_file[i].rstrip('\n')
    print "Processing ",pdb_name
    newdir = output_dir
    if os.path.isdir(newdir):
                print "Processing ",newdir
    else:
                print "Creating feature folder: ",newdir
                try:
                    os.makedirs(newdir)
                except OSError as exc:  # Python >2.5
                    if exc.errno == errno.EEXIST and os.path.isdir(newdir):
                        pass
                    else:
                        raise                
    try:
        print(script+' '+pdb_name +' '+sequence_dir+'/'+pdb_name +  ' '+ output_dir + ' ' + script_dir+ ' ' + pspro_dir+ ' ' + nr_db+ ' ' + big_db)
        os.system(script+' '+pdb_name +' '+sequence_dir+'/'+pdb_name +  ' '+ output_dir + ' ' + script_dir+ ' ' + pspro_dir+ ' ' + nr_db+ ' ' + big_db)
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST:
            pass
        else:
            exit(-1)    


