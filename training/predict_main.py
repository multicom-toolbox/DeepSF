
import sys
import os
import shutil

GLOBAL_PATH='/home/casp13/deepsf_3d/Github/test/DeepSF/';
sys.path.insert(0, GLOBAL_PATH+'/lib')


if len(sys.argv) != 12:
          print 'please input the right parameters: interval'
          sys.exit(1)

inter=int(sys.argv[1]) #15
nb_filters=int(sys.argv[2]) #10
nb_layers=int(sys.argv[3]) #10
opt=sys.argv[4] #nadam
filtsize=sys.argv[5] #6_10
hidden_num=int(sys.argv[6]) #500
ktop_node=int(sys.argv[7]) #30
out_epoch=int(sys.argv[8]) #100
in_epoch=int(sys.argv[9]) #3
datadir = sys.argv[10]
outputdir = sys.argv[11]



feature_dir_global =GLOBAL_PATH+'/datasets/features/Feature_aa_ss_sa/'
pssm_dir_global = GLOBAL_PATH+'/datasets/features/PSSM_Fea/'


if not os.path.exists(feature_dir_global):
  print "Cuoldn't find folder ",feature_dir_global, " please setting it in the script ./predict_main.py"
  exit(-1)


if not os.path.exists(pssm_dir_global):
  print "Cuoldn't find folder ",pssm_dir_global, " please setting it in the script ./predict_main.py"
  exit(-1)
    

test_datafile=datadir+'/SCOP206.list'
train_datafile=datadir+'/Traindata.list'
val_datafile=datadir+'/Testdata.list'

CV_dir=outputdir+'/interative_filter'+str(nb_filters)+'_layers'+str(nb_layers)+'_opt'+str(opt)+'_ftsize'+str(filtsize)+'_hn'+str(hidden_num)+'_ktop_node'+str(ktop_node);


modelfile = CV_dir+'/model-train-DLS2F.json'
weightfile = CV_dir+'/model-train-weight-DLS2F.h5'

resultdir = CV_dir+'/DCNN_results'

results_train = CV_dir+'/DCNN_results_inter'+str(inter)+'_train.txt'
results_test = CV_dir+'/DCNN_results_inter'+str(inter)+'_test.txt'
results_val = CV_dir+'/DCNN_results_inter'+str(inter)+'_val.txt'

if not os.path.exists(resultdir):
    os.makedirs(resultdir)

if not os.path.exists(modelfile):
  print "Cuoldn't find file ",modelfile
  exit(-1)


if not os.path.exists(weightfile):
  print "Cuoldn't find file ",modelfile
  exit(-1)




print "###### Evaluating Training data";
cmd1='python '+ GLOBAL_PATH + '/lib/DLS2F_predict_fea.py  '+ train_datafile + '  ' + modelfile+ '  ' + weightfile+ '  ' + feature_dir_global + '  ' +  pssm_dir_global + ' '   + resultdir + '  '+str(ktop_node)
print "Running ", cmd1,"\n\n"
os.system(cmd1)

cmd2='python '+ GLOBAL_PATH + '/lib/DLS2F_evaluate_SCOP.py  '+ train_datafile  + '  '+GLOBAL_PATH +'/datasets/D1_SimilarityReduction_dataset/fold_label_relation2.txt  '  + resultdir + '  ' + results_train
print "Running ", cmd2,"\n\n"
os.system(cmd2)


##clean files
shutil.rmtree(resultdir)
if not os.path.exists(resultdir):
    os.makedirs(resultdir)

print "###### Evaluating Testing data";
cmd1='python '+ GLOBAL_PATH + '/lib/DLS2F_predict_fea.py  '+ test_datafile + '  ' + modelfile+ '  ' + weightfile + '  ' +  feature_dir_global + '  ' +  pssm_dir_global + ' '   + resultdir + '   '+str(ktop_node)
print "Running ", cmd1,"\n\n"
os.system(cmd1)

cmd2='python '+ GLOBAL_PATH + '/lib/DLS2F_evaluate_SCOP.py  '+ test_datafile  + '  '+GLOBAL_PATH +'/datasets/D1_SimilarityReduction_dataset/fold_label_relation2.txt  '  + resultdir + '  ' + results_test
print "Running ", cmd2,"\n\n"
os.system(cmd2)

##clean files
shutil.rmtree(resultdir)
if not os.path.exists(resultdir):
    os.makedirs(resultdir)

print "###### Evaluating Validation data";
cmd1='python '+ GLOBAL_PATH + '/lib/DLS2F_predict_fea.py  '+ val_datafile + '  ' + modelfile+ '  ' + weightfile+ '  ' + feature_dir_global + '  ' +  pssm_dir_global + ' '   + resultdir + '   '+str(ktop_node)
print "Running ", cmd1,"\n\n"
os.system(cmd1)

cmd2='python '+ GLOBAL_PATH + '/lib/DLS2F_evaluate_SCOP.py  '+ val_datafile  + '  '+GLOBAL_PATH +'/datasets/D1_SimilarityReduction_dataset/fold_label_relation2.txt '  + resultdir + '  ' + results_val
print "Running ", cmd2,"\n\n"
os.system(cmd2)

shutil.rmtree(resultdir)
