
import sys
import os
import shutil

import sys

GLOBAL_PATH='/home/jh7x3/DLS2F/DLS2F_Project/Paper_data/DeepSF_Source_code/';
sys.path.insert(0, GLOBAL_PATH+'/lib')



if len(sys.argv) != 7:
          print 'please input the right parameters: interval'
          sys.exit(1)

test_file = sys.argv[1]
modelfile = sys.argv[2]
weightfile = sys.argv[3]
data_dir = sys.argv[4]
CV_dir = sys.argv[5]
ktop_node = sys.argv[6]


feature_dir_global =data_dir +'/Feature_aa_ss_sa/'
pssm_dir_global = data_dir + '/PSSM_Fea/'


if not os.path.exists(feature_dir_global):
  print "Cuoldn't find folder ",feature_dir_global, " please setting it in the script ./predict_single.py"
  exit(-1)


if not os.path.exists(pssm_dir_global):
  print "Cuoldn't find folder ",pssm_dir_global, " please setting it in the script ./predict_single.py"
  exit(-1)
    


results_file = CV_dir+'/DCNN_results.txt'

if not os.path.exists(CV_dir):
    os.makedirs(CV_dir)

if not os.path.exists(modelfile):
  print "Cuoldn't find file ",modelfile
  exit(-1)


if not os.path.exists(weightfile):
  print "Cuoldn't find file ",modelfile
  exit(-1)


resultdir = CV_dir+'/DCNN_results'

if not os.path.exists(resultdir):
    os.makedirs(resultdir)


print "###### Evaluating data";
cmd1='python ' + GLOBAL_PATH + '/lib/DLS2F_predict_fea.py  '+ test_file + '  ' + modelfile+ '  ' + weightfile+ '  ' + feature_dir_global + '  ' +  pssm_dir_global + ' '   + resultdir + '  '+str(ktop_node)
print "Running ", cmd1,"\n\n"
os.system(cmd1)

cmd2='python ' + GLOBAL_PATH + '/lib/DLS2F_evaluate_SCOP.py  '+ test_file + '  '+GLOBAL_PATH +'/datasets/fold_label_relation2.txt  '  + resultdir  + '  ' + results_file
print "Running ", cmd2,"\n\n"
os.system(cmd2)


##clean files
shutil.rmtree(resultdir)

