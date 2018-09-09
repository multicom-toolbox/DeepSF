import sys
import os
from shutil import copyfile

GLOBAL_PATH='/home/casp13/deepsf_3d/Github/test/DeepSF/';
sys.path.insert(0, GLOBAL_PATH+'/lib')

from library import load_train_test_data_padding_with_interval,K_max_pooling1d,DLS2F_train_complex_win_filter_layer_opt

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

train_datafile=datadir+'/Traindata.list'
val_datafile=datadir+'/validation.list'
test_datafile=datadir+'/Testdata.list'

CV_dir=outputdir+'/interative_filter'+str(nb_filters)+'_layers'+str(nb_layers)+'_opt'+str(opt)+'_ftsize'+str(filtsize)+'_hn'+str(hidden_num)+'_ktop_node'+str(ktop_node);


modelfile = CV_dir+'/model-train-DLS2F.json'
weightfile = CV_dir+'/model-train-weight-DLS2F.h5'
weightfile_best = CV_dir+'/model-train-weight-DLS2F-best-val.h5'


if os.path.exists(modelfile):
  cmd1='rm  '+ modelfile
  print "Running ", cmd1,"\n\n"
  os.system(cmd1)
  

if os.path.exists(weightfile_best):
  cmd1='cp  '+ weightfile_best + '  ' + weightfile
  print "Running ", cmd1,"\n\n"
  os.system(cmd1)


filetsize_array = map(int,filtsize.split("_"))

if not os.path.exists(CV_dir):
    os.makedirs(CV_dir)

import time


data_all_dict_padding_interval15 = load_train_test_data_padding_with_interval(datadir, inter, 'kmax30',ktop_node,1150,train=True)
testdata_all_dict_padding_interval15 = load_train_test_data_padding_with_interval(datadir,inter, 'kmax30',ktop_node,1150,train=False)

start_time = time.time()

DLS2F_train_complex_win_filter_layer_opt(data_all_dict_padding_interval15,testdata_all_dict_padding_interval15,train_datafile,val_datafile,test_datafile,CV_dir,"DLS2F",out_epoch,in_epoch,1150,filetsize_array,True,'sigmoid',nb_filters,nb_layers,opt,hidden_num,ktop_node)




print("--- %s seconds ---" % (time.time() - start_time))
