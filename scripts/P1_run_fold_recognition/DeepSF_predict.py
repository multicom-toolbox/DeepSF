# -*- coding: utf-8 -*-

import sys
import numpy as np
import os
from keras.models import model_from_json
from keras.engine.topology import Layer
import theano.tensor as T
from keras import backend as K
from keras.constraints import maxnorm

from keras.models import Model
from keras.layers import Activation, Dense, Dropout, Flatten, Input, Merge, Convolution1D
from keras.layers.normalization import BatchNormalization


def import_DLS2FSVM(filename, delimiter='\t', delimiter2=' ',comment='>',skiprows=0, start=0, end = 0,target_col = 1, dtype=np.float32):
    # Open a file
    file = open(filename, "r")
    #print "Name of the file: ", file.name
    if skiprows !=0:
       dataset = file.read().splitlines()[skiprows:]
    if skiprows ==0 and start ==0 and end !=0:
       dataset = file.read().splitlines()[0:end]
    if skiprows ==0 and start !=0:
       dataset = file.read().splitlines()[start:]
    if skiprows ==0 and start !=0 and end !=0:
       dataset = file.read().splitlines()[start:end]
    else:
       dataset = file.read().splitlines()
    #print dataset
    newdata = []
    for i in range(0,len(dataset)):
        line = dataset[i]
        if line[0] != comment:
           temp = line.split(delimiter,target_col)
           feature = temp[target_col]
           label = temp[0]
           if label == 'N':
               label = 0
           fea = feature.split(delimiter2)
           newline = []
           newline.append(int(label))
           for j in range(0,len(fea)):
               if fea[j].find(':') >0 :
                   (num,val) = fea[j].split(':')
                   newline.append(float(val))
            
           newdata.append(newline)
    data = np.array(newdata, dtype=dtype)
    file.close()
    return data


class Dynamick_max_pooling1d(Layer):
    def __init__(self, numLayers, currlayer, ktop, **kwargs):
        self.numLayers = numLayers
        self.currlayer = currlayer
        self.ktop = ktop
        self.inputdim = 1
        super(Dynamick_max_pooling1d, self).__init__(**kwargs)
    
    def get_output_shape_for(self, input_shape):
        get_k=K.cast(K.max([self.ktop,T.ceil((self.numLayers-self.currlayer)/float(self.numLayers)*self.inputdim)]),'int32')
        return (input_shape[0],get_k,input_shape[2])
    
    def call(self,x,mask=None):
        get_k=K.cast(K.max([self.ktop,T.ceil((self.numLayers-self.currlayer)/float(self.numLayers)*self.inputdim)]),'int32')
        output = x[T.arange(x.shape[0]).dimshuffle(0, "x", "x"),
              T.sort(T.argsort(x, axis=1)[:, -get_k:, :], axis=1),
              T.arange(x.shape[2]).dimshuffle("x", "x", 0)]
        return output
    
    def get_config(self):
        config = {'numLayers': self.numLayers,
                  'currlayer': self.currlayer,
                  'ktop': self.ktop}
        base_config = super(Dynamick_max_pooling1d, self).get_config()
        return dict(list(base_config.items()) + list(config.items()))

class K_max_pooling1d(Layer):
    # def __init__(self,  ktop=40, **kwargs):
    def __init__(self,  ktop, **kwargs):
        self.ktop = ktop
        super(K_max_pooling1d, self).__init__(**kwargs)
    
    def get_output_shape_for(self, input_shape):
        return (input_shape[0],self.ktop,input_shape[2])
    
    def call(self,x,mask=None):
        output = x[T.arange(x.shape[0]).dimshuffle(0, "x", "x"),
              T.sort(T.argsort(x, axis=1)[:, -self.ktop:, :], axis=1),
              T.arange(x.shape[2]).dimshuffle("x", "x", 0)]
        return output
    
    def get_config(self):
        config = {'ktop': self.ktop}
        base_config = super(K_max_pooling1d, self).get_config()
        return dict(list(base_config.items()) + list(config.items()))

if __name__ == '__main__':
    if len(sys.argv) != 9:
            print 'please input the right parameters: list, model, weight, kmax'
            sys.exit(1)
    
    
    test_list=sys.argv[1] 
    model_file=sys.argv[2] 
    model_weight=sys.argv[3]  #
    feature_dir=sys.argv[4]  #
    pssm_dir=sys.argv[5]  #
    Resultsdir=sys.argv[6] 
    kmaxnode=int(sys.argv[7]) 
    relationfile=sys.argv[8] 
    #kmaxnode=30
    if not os.path.exists(model_file):
         raise Exception("model file %s not exists!" % model_file)
    if not os.path.exists(model_weight):
         raise Exception("model file %s not exists!" % model_weight)
    print "Loading Model file ",model_file
    print "Loading Model weight ",model_weight
    sequence_file=open(relationfile,'r').readlines() 
    fold2label = dict()
    for i in xrange(len(sequence_file)):
        if sequence_file[i].find('Label') >0 :
            print "Skip line ",sequence_file[i]
            continue
        fold = sequence_file[i].rstrip().split('\t')[0]
        label = int(sequence_file[i].rstrip().split('\t')[1])
        if label not in fold2label:
            fold2label[label]=fold
    
    json_file_model = open(model_file, 'r')
    loaded_model_json = json_file_model.read()
    json_file_model.close()    
    DLS2F_ResCNN = model_from_json(loaded_model_json, custom_objects={'Dynamick_max_pooling1d': Dynamick_max_pooling1d,'K_max_pooling1d': K_max_pooling1d})        
    
    print "######## Loading existing weights ",model_weight;
    DLS2F_ResCNN.load_weights(model_weight)
    DLS2F_ResCNN.compile(loss="categorical_crossentropy", metrics=['accuracy'], optimizer="nadam")
    get_flatten_layer_output = K.function([DLS2F_ResCNN.layers[0].input, K.learning_phase()],[DLS2F_ResCNN.layers[-3].output]) # input to flatten layer

    Testlist_data_keys = dict()
    Testlist_targets_keys = dict()
    sequence_file=open(test_list,'r').readlines() 
    for i in xrange(len(sequence_file)):
        if sequence_file[i].find('Length') >0 :
            print "Skip line ",sequence_file[i]
            continue
        pdb_name = sequence_file[i].rstrip().split('\t')[0]
        #print "Processing ",pdb_name
        featurefile = feature_dir + '/' + pdb_name + '.fea_aa_ss_sa'
        pssmfile = pssm_dir + '/' + pdb_name + '.pssm_fea'
        if not os.path.isfile(featurefile):
                    print "feature file not exists: ",featurefile, " pass!"
                    #continue         
        
        if not os.path.isfile(pssmfile):
                    print "pssm feature file not exists: ",pssmfile, " pass!"
                    #continue         
        
        featuredata = import_DLS2FSVM(featurefile)
        pssmdata = import_DLS2FSVM(pssmfile) # d1ft8e_ has wrong length, in pdb, it has 57, but in pdb, it has 44, why?
        pssm_fea = pssmdata[:,1:]
        
        fea_len = (featuredata.shape[1]-1)/(20+3+2)
        #if fea_len < 40: # since kmax right now is 30
        #    continue
        train_labels = featuredata[:,0]
        train_feature = featuredata[:,1:]
        train_feature_seq = train_feature.reshape(fea_len,25)
        train_feature_aa = train_feature_seq[:,0:20]
        train_feature_ss = train_feature_seq[:,20:23]
        train_feature_sa = train_feature_seq[:,23:25]
        train_feature_pssm = pssm_fea.reshape(fea_len,20)
        min_pssm=-8
        max_pssm=16
        
        train_feature_pssm_normalize = np.empty_like(train_feature_pssm)
        train_feature_pssm_normalize[:] = train_feature_pssm
        train_feature_pssm_normalize=(train_feature_pssm_normalize-min_pssm)/(max_pssm-min_pssm)
        featuredata_all_tmp = np.concatenate((train_feature_aa,train_feature_ss,train_feature_sa,train_feature_pssm_normalize), axis=1)
                    
        if fea_len <kmaxnode: # suppose k-max = 30
            fea_len = kmaxnode
            train_featuredata_all = np.zeros((kmaxnode,featuredata_all_tmp.shape[1]))
            train_featuredata_all[:featuredata_all_tmp.shape[0],:featuredata_all_tmp.shape[1]] = featuredata_all_tmp
        else:
            train_featuredata_all = featuredata_all_tmp
        
        train_featuredata_all=train_featuredata_all.reshape(1,train_featuredata_all.shape[0],train_featuredata_all.shape[1])
        if pdb_name in Testlist_data_keys:
            raise Exception("Duplicate pdb name %s in Test list " % pdb_name)
        else:
            Testlist_data_keys[pdb_name]=train_featuredata_all
        
    sequence_file=open(test_list,'r').readlines() 
    for i in xrange(len(sequence_file)):
        if sequence_file[i].find('Length') >0 :
            #print "Skip line ",sequence_file[i]
            continue
        pdb_name = sequence_file[i].rstrip().split('\t')[0]
        
        val_featuredata_all=Testlist_data_keys[pdb_name]
        
        predict_val= DLS2F_ResCNN.predict([val_featuredata_all])
        hidden_feature= get_flatten_layer_output([val_featuredata_all,1])[0] ## output in train mode = 1 https://keras.io/getting-started/faq/
        predict_out = Resultsdir+'/'+pdb_name+'.prediction'
        hidden_feature_out = Resultsdir+'/'+pdb_name+'.hidden_feature'
        list_out = Resultsdir+'/'+pdb_name+'.rank_list'
        np.savetxt(predict_out,predict_val,delimiter='\t')
        np.savetxt(hidden_feature_out,hidden_feature,delimiter='\t')
        top10_prediction=predict_val[0].argsort()[-10:][::-1]
        with open(list_out, "w") as myfile:
            myfile.write("Rank\tFold\tFold_index\tProbability\n")
        for indx in range(0,len(top10_prediction)):
            scop_index = top10_prediction[indx]
            scopid = fold2label[scop_index]
            prob = predict_val[0][scop_index]
            with open(list_out, "a") as myfile:
                myfile.write("%i\t%s\t%i\t%.5f\n" % (indx+1,scopid,scop_index,prob))            
                
