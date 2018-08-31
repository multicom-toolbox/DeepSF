import os
import numpy as np

from keras.engine.topology import Layer
import theano.tensor as T
from keras import backend as K

from keras.constraints import maxnorm
from keras.models import model_from_json
from keras.models import Model
from keras.layers import Activation, Dense, Dropout, Flatten, Input, Merge, Convolution1D, Convolution2D
from keras.layers.normalization import BatchNormalization


feature_dir_global ='/var/www/html/DeepSF/download/SCOP175_training_data_09202017/Feature_aa_ss_sa/'
pssm_dir_global = '/var/www/html/DeepSF/download/SCOP175_training_data_09202017/PSSM_Fea/'


if not os.path.exists(feature_dir_global):
  print "Cuoldn't find folder ",feature_dir_global, " please setting it in the script ./lib/library.py"
  exit(-1)


if not os.path.exists(pssm_dir_global):
  print "Cuoldn't find folder ",pssm_dir_global, " please setting it in the script ./lib/library.py"
  exit(-1)

def chkdirs(fn):
  dn = os.path.dirname(fn)
  if not os.path.exists(dn): os.makedirs(dn)


def import_DLS2FSVM(filename, delimiter='\t', delimiter2=' ',comment='>',skiprows=0, start=0, end = 0,target_col = 1, dtype=np.float32):
    # Open a file
    file = open(filename, "r")
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



class K_max_pooling1d(Layer):
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

def _conv_bn_relu1D(nb_filter, nb_row, subsample,use_bias=True):
    def f(input):
        conv = Convolution1D(nb_filter=nb_filter, filter_length=nb_row, subsample_length=subsample,bias=use_bias,
                             init="he_normal", activation='relu', border_mode="same")(input)
        norm = BatchNormalization(mode=0, axis=2)(conv)
        return Activation("relu")(norm)
    
    return f


def load_train_test_data_padding_with_interval(CV_dir, Interval,prefix,ktop_node,seq_end,train=True):
    try:
        # read python dict back from the file
        import pickle
        if train:
            pickle_file ="%s/Traindata_padding_interval_%i_%s.pkl" % (CV_dir,Interval,prefix) 
            print "#loading training data %s ..." % (pickle_file) 
        else:
            pickle_file ="%s/validation_padding_interval_%i_%s.pkl" % (CV_dir,Interval,prefix)  
            print "#loading validation data %s ..." % (pickle_file)
        
        pkl_file = open(pickle_file, 'rb')
        data_all_dict = pickle.load(pkl_file)
        # list(data_all_dict.keys()).
        for key in data_all_dict.keys():
            print "keys: ", key, " shape: ", data_all_dict[key].shape
        pkl_file.close()    
    except:
        import pickle
        ### loading training data
        if train:
            data_file ="%s/Traindata.list" % (CV_dir)  
            print "##loading training file set instead from %s ..." % (data_file)
        else:
            data_file ="%s/validation.list" % (CV_dir)  
            print "##loading testing file set instead %s ..." % (data_file)
        
        feature_dir = feature_dir_global
        pssm_dir = pssm_dir_global 
        
        if train:
            print "#loading training data..."
            pickle_file ="%s/Traindata_padding_interval_%i_%s.pkl" % (CV_dir,Interval,prefix)  
        else:
            print "#loading validation data..."
            pickle_file ="%s/validation_padding_interval_%i_%s.pkl" % (CV_dir,Interval,prefix)  
        
        
        sequence_file=open(data_file,'r').readlines() 
        data_all_dict = dict()
        for i in xrange(len(sequence_file)):
            if sequence_file[i].find('Length') >0 :
                print "Skip line ",sequence_file[i]
                continue
            pdb_name = sequence_file[i].split('\t')[0]
            #print "Processing ",pdb_name
            
            if pdb_name.find('.')!=-1: # found
                pdb_name = pdb_name.replace(".", "_")
            featurefile = feature_dir + '/' + pdb_name + '.fea_aa_ss_sa'
            pssmfile = pssm_dir + '/' + pdb_name + '.pssm_fea'
            if not os.path.isfile(featurefile):
                        print "feature file not exists: ",featurefile, " pass!"
                        continue         
                            
            if not os.path.isfile(pssmfile):
                        print "pssm feature file not exists: ",pssmfile, " pass!"
                        continue         
                            
            featuredata = import_DLS2FSVM(featurefile)
            pssmdata = import_DLS2FSVM(pssmfile) #
            pssm_fea = pssmdata[:,1:]
            
            fea_len = (featuredata.shape[1]-1)/(20+3+2)
            train_labels = featuredata[:,0]
            train_feature = featuredata[:,1:]
            train_feature_seq = train_feature.reshape(fea_len,25)
            train_feature_aa = train_feature_seq[:,0:20]
            train_feature_ss = train_feature_seq[:,20:23]
            train_feature_sa = train_feature_seq[:,23:25]
            train_feature_pssm = pssm_fea.reshape(fea_len,20)
            ### reconstruct feature, each residue represent aa,ss,sa,pssm
            featuredata_all = np.concatenate((train_feature_aa,train_feature_ss,train_feature_sa,train_feature_pssm), axis=1)
            featuredata_all = featuredata_all.reshape(1,featuredata_all.shape[0]*featuredata_all.shape[1])
            featuredata_all_tmp = np.concatenate((train_labels.reshape((1,1)),featuredata_all), axis=1)
            
            if fea_len <ktop_node: # suppose k-max = 30
                fea_len = ktop_node
                featuredata_all_new = np.zeros((featuredata_all_tmp.shape[0],ktop_node*(20+20+3+2)+1))
                featuredata_all_new[:featuredata_all_tmp.shape[0],:featuredata_all_tmp.shape[1]] = featuredata_all_tmp
            else:
                featuredata_all_new = featuredata_all_tmp
            
            for ran in range(0,seq_end,Interval):
                start_ran = ran
                end_ran = ran + Interval
                if end_ran > seq_end:
                    end_ran = seq_end 
                if fea_len >start_ran and   fea_len <= end_ran:
                    featuredata_all_pad = np.zeros((featuredata_all_new.shape[0],end_ran*(20+20+3+2)+1))
                    featuredata_all_pad[:featuredata_all_new.shape[0],:featuredata_all_new.shape[1]] = featuredata_all_new
                    
                    #print "fea_len: ",fea_len
                    fea_len_new=end_ran
                    if fea_len_new in data_all_dict:
                        data_all_dict[fea_len_new].append(featuredata_all_pad)
                    else:
                        data_all_dict[fea_len_new]=[]
                        data_all_dict[fea_len_new].append(featuredata_all_pad)               
                else:
                    continue
        # list(data_all_dict.keys()).
        for key in data_all_dict.keys():
            myarray = np.asarray(data_all_dict[key])
            data_all_dict[key] = myarray.reshape(len(myarray),myarray.shape[2])
            print "keys: ", key, " shape: ", data_all_dict[key].shape
        
        
        print "Saving data  ",pickle_file
        # write python dict to a file
        #output = open(pickle_file, 'wb') # dont save, release space
        #pickle.dump(data_all_dict, output)
        #output.close()
    
    return data_all_dict


def DLS2F_construct_withaa_complex_win_filter_layer_opt(win_array,ktop_node,output_dim,use_bias,hidden_type,nb_filters,nb_layers,opt,hidden_num):
    ss_feature_num = 3
    sa_feature_num = 2
    aa_feature_num = 20
    pssm_feature_num = 20
    ktop_node= ktop_node
    print "Setting hidden models as ",hidden_type
    print "Setting nb_filters as ",nb_filters
    print "Setting nb_layers as ",nb_layers
    print "Setting opt as ",opt
    print "Setting win_array as ",win_array
    print "Setting use_bias as ",use_bias
    ########################################## set up model
    DLS2F_input_shape =(None,aa_feature_num+ss_feature_num+sa_feature_num+pssm_feature_num)
    filter_sizes=win_array
    DLS2F_input = Input(shape=DLS2F_input_shape)
    DLS2F_convs = []
    for fsz in filter_sizes:
        DLS2F_conv = DLS2F_input
        for i in range(0,nb_layers):
            DLS2F_conv = _conv_bn_relu1D(nb_filter=nb_filters, nb_row=fsz, subsample=1,use_bias=use_bias)(DLS2F_conv)
        
        DLS2F_pool = K_max_pooling1d(ktop=ktop_node)(DLS2F_conv)
        DLS2F_flatten = Flatten()(DLS2F_pool)
        DLS2F_convs.append(DLS2F_flatten)
    
    if len(filter_sizes)>1:
        DLS2F_out = Merge(mode='concat')(DLS2F_convs)
    else:
        DLS2F_out = DLS2F_convs[0]  
    
    DLS2F_dense1 = Dense(output_dim=hidden_num, init='he_normal', activation=hidden_type, W_constraint=maxnorm(3))(DLS2F_out) # changed on 20170314 to check if can visualzie better
    DLS2F_dropout1 = Dropout(0.2)(DLS2F_dense1)
    DLS2F_output = Dense(output_dim=output_dim, init="he_normal", activation="softmax")(DLS2F_dropout1)
    DLS2F_ResCNN = Model(input=[DLS2F_input], output=DLS2F_output) 
    DLS2F_ResCNN.compile(loss="categorical_crossentropy", metrics=['accuracy'], optimizer=opt)
    
    return DLS2F_ResCNN


def DLS2F_train_complex_win_filter_layer_opt(data_all_dict_padding,testdata_all_dict_padding,train_list,val_list,CV_dir,model_prefix,epoch_outside,epoch_inside,seq_end,win_array,use_bias,hidden_type,nb_filters,nb_layers,opt,hidden_num,ktop_node):
    start=0
    end=seq_end
    feature_dir = feature_dir_global
    pssm_dir = pssm_dir_global
    import numpy as np
    Train_data_keys = dict()
    Train_targets_keys = dict()
    Test_data_keys = dict()
    Test_targets_keys = dict()
    #### loading training and testing dataset for model training
    for key in data_all_dict_padding.keys():
        if key <start:
            continue
        if key > end:
            continue
        print '### Loading sequence length :', key
        seq_len=key
        trainfeaturedata = data_all_dict_padding[key]
        train_labels = trainfeaturedata[:,0]
        train_feature = trainfeaturedata[:,1:]
        
        if (train_labels>1194).any():
            raise Exception("Wrong label?")
        
        if len(trainfeaturedata) < 1:
            print "len(trainfeaturedata): ",len(trainfeaturedata)
            continue
        
        if seq_len in testdata_all_dict_padding:
            testfeaturedata = testdata_all_dict_padding[seq_len]
            #print "Loading test dataset "
        else:
            testfeaturedata = trainfeaturedata
            print "\n\n##Warning: Setting training dataset as testing dataset \n\n"
        
        if len(testfeaturedata) < 1:
            testfeaturedata = trainfeaturedata
        
        test_labels = testfeaturedata[:,0]
        test_feature = testfeaturedata[:,1:]    
        sequence_length = seq_len
        #processing train data
        train_feature_seq = train_feature.reshape(train_feature.shape[0],sequence_length,45)
        train_feature_aa = train_feature_seq[:,:,0:20]
        train_feature_ss = train_feature_seq[:,:,20:23]
        train_feature_sa = train_feature_seq[:,:,23:25]
        train_feature_pssm = train_feature_seq[:,:,25:45]
        min_pssm=-8
        max_pssm=16
        
        train_feature_pssm_normalize = np.empty_like(train_feature_pssm)
        train_feature_pssm_normalize[:] = train_feature_pssm
        train_feature_pssm_normalize=(train_feature_pssm_normalize-min_pssm)/(max_pssm-min_pssm)
        train_featuredata_all = np.concatenate((train_feature_aa,train_feature_ss,train_feature_sa,train_feature_pssm_normalize), axis=2)
        train_targets = np.zeros((train_labels.shape[0], 1195 ), dtype=int)
        for i in range(0, train_labels.shape[0]):
            train_targets[i][int(train_labels[i])] = 1
        
        if seq_len in Train_data_keys:
            raise Exception("Duplicate seq length %i in Train list, since it has been combined when loading data " % seq_len)
        else:
            Train_data_keys[seq_len]=(train_featuredata_all)
            
        if seq_len in Train_targets_keys:
            raise Exception("Duplicate seq length %i in Train list, since it has been combined when loading data " % seq_len)
        else:
            Train_targets_keys[seq_len]=train_targets        
        #processing test data 
        test_feature_seq = test_feature.reshape(test_feature.shape[0],sequence_length,45)
        test_feature_aa = test_feature_seq[:,:,0:20]
        test_feature_ss = test_feature_seq[:,:,20:23]
        test_feature_sa = test_feature_seq[:,:,23:25]
        test_feature_pssm = test_feature_seq[:,:,25:45]
        min_pssm=-8
        max_pssm=16
        
        test_feature_pssm_normalize = np.empty_like(test_feature_pssm)
        test_feature_pssm_normalize[:] = test_feature_pssm
        test_feature_pssm_normalize=(test_feature_pssm_normalize-min_pssm)/(max_pssm-min_pssm)
        test_featuredata_all = np.concatenate((test_feature_aa,test_feature_ss,test_feature_sa,test_feature_pssm_normalize), axis=2)
        test_targets = np.zeros((test_labels.shape[0], 1195 ), dtype=int)
        for i in range(0, test_labels.shape[0]):
            test_targets[i][int(test_labels[i])] = 1
        
        
        print "Length: ",seq_len," ---> ",test_featuredata_all.shape[0]," testing seqs"
        if test_featuredata_all.shape[0] > 20: # to speed up the training
              test_featuredata_all = test_featuredata_all[0:20,:]
              test_targets = test_targets[0:20,:]
        if seq_len in Test_data_keys:
            raise Exception("Duplicate seq length %i in Test list, since it has been combined when loading data " % seq_len)
        else:
            Test_data_keys[seq_len]=test_featuredata_all 
        
        if seq_len in Test_targets_keys:
            raise Exception("Duplicate seq length %i in Test list, since it has been combined when loading data " % seq_len)
        else:
            Test_targets_keys[seq_len]=test_targets
    
    ### Re-loading training dataset for global evaluation
    Trainlist_data_keys = dict()
    Trainlist_targets_keys = dict()
    sequence_file=open(train_list,'r').readlines() 
    for i in xrange(len(sequence_file)):
        if sequence_file[i].find('Length') >0 :
            print "Skip line ",sequence_file[i]
            continue
        pdb_name = sequence_file[i].split('\t')[0]
        #print "Processing ",pdb_name
        featurefile = feature_dir + '/' + pdb_name + '.fea_aa_ss_sa'
        pssmfile = pssm_dir + '/' + pdb_name + '.pssm_fea'
        if not os.path.isfile(featurefile):
                    print "feature file not exists: ",featurefile, " pass!"
                    continue         
        
        if not os.path.isfile(pssmfile):
                    print "pssm feature file not exists: ",pssmfile, " pass!"
                    continue         
        
        featuredata = import_DLS2FSVM(featurefile)
        pssmdata = import_DLS2FSVM(pssmfile) 
        pssm_fea = pssmdata[:,1:]
        
        fea_len = (featuredata.shape[1]-1)/(20+3+2)
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
        
        if fea_len <ktop_node: # suppose k-max = ktop_node
            fea_len = ktop_node
            train_featuredata_all = np.zeros((ktop_node,featuredata_all_tmp.shape[1]))
            train_featuredata_all[:featuredata_all_tmp.shape[0],:featuredata_all_tmp.shape[1]] = featuredata_all_tmp
        else:
            train_featuredata_all = featuredata_all_tmp
        
        #print "train_featuredata_all: ",train_featuredata_all.shape
        train_targets = np.zeros((train_labels.shape[0], 1195 ), dtype=int)
        for i in range(0, train_labels.shape[0]):
            train_targets[i][int(train_labels[i])] = 1
        
        train_featuredata_all=train_featuredata_all.reshape(1,train_featuredata_all.shape[0],train_featuredata_all.shape[1])
        
        
        if pdb_name in Trainlist_data_keys:
            print "Duplicate pdb name %s in Train list " % pdb_name
        else:
            Trainlist_data_keys[pdb_name]=train_featuredata_all
        
        if pdb_name in Trainlist_targets_keys:
            print "Duplicate pdb name %s in Train list " % pdb_name
        else:
            Trainlist_targets_keys[pdb_name]=train_targets
        
    Vallist_data_keys = dict()
    Vallist_targets_keys = dict()
    sequence_file=open(val_list,'r').readlines() 
    for i in xrange(len(sequence_file)):
        if sequence_file[i].find('Length') >0 :
            print "Skip line ",sequence_file[i]
            continue
        pdb_name = sequence_file[i].split('\t')[0]
        #print "Processing ",pdb_name
        featurefile = feature_dir + '/' + pdb_name + '.fea_aa_ss_sa'
        pssmfile = pssm_dir + '/' + pdb_name + '.pssm_fea'
        if not os.path.isfile(featurefile):
                    print "feature file not exists: ",featurefile, " pass!"
                    continue         
        
        if not os.path.isfile(pssmfile):
                    print "pssm feature file not exists: ",pssmfile, " pass!"
                    continue         
        
        featuredata = import_DLS2FSVM(featurefile)
        pssmdata = import_DLS2FSVM(pssmfile) 
        pssm_fea = pssmdata[:,1:]
        
        fea_len = (featuredata.shape[1]-1)/(20+3+2)
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
                    
        if fea_len <ktop_node: # suppose k-max = ktop_node
            fea_len = ktop_node
            train_featuredata_all = np.zeros((ktop_node,featuredata_all_tmp.shape[1]))
            train_featuredata_all[:featuredata_all_tmp.shape[0],:featuredata_all_tmp.shape[1]] = featuredata_all_tmp
        else:
            train_featuredata_all = featuredata_all_tmp
        
        train_targets = np.zeros((train_labels.shape[0], 1195 ), dtype=int)
        for i in range(0, train_labels.shape[0]):
            train_targets[i][int(train_labels[i])] = 1
        
        train_featuredata_all=train_featuredata_all.reshape(1,train_featuredata_all.shape[0],train_featuredata_all.shape[1])
        if pdb_name in Vallist_data_keys:
            print "Duplicate pdb name %s in Val list " % pdb_name
        else:
            Vallist_data_keys[pdb_name]=train_featuredata_all
        
        if pdb_name in Vallist_targets_keys:
            print "Duplicate pdb name %s in Val list " % pdb_name
        else:
            Vallist_targets_keys[pdb_name]=train_targets
    
    ### Define the model 
    model_out= "%s/model-train-%s.json" % (CV_dir,model_prefix)
    model_weight_out = "%s/model-train-weight-%s.h5" % (CV_dir,model_prefix)
    model_weight_out_best = "%s/model-train-weight-%s-best-val.h5" % (CV_dir,model_prefix)
    

    
    if os.path.exists(model_out):
        print "######## Loading existing model ",model_out;
        # load json and create model
        json_file_model = open(model_out, 'r')
        loaded_model_json = json_file_model.read()
        json_file_model.close()
        
        print("######## Loaded model from disk")
        DLS2F_CNN = model_from_json(loaded_model_json, custom_objects={'K_max_pooling1d': K_max_pooling1d})        
    else:
        print "######## Setting initial model";
        DLS2F_CNN = DLS2F_construct_withaa_complex_win_filter_layer_opt(win_array,ktop_node,1195,use_bias,hidden_type,nb_filters,nb_layers,opt,hidden_num) # class 284 for class a 
    
    if os.path.exists(model_weight_out):
        print "######## Loading existing weights ",model_weight_out;
        DLS2F_CNN.load_weights(model_weight_out)
        DLS2F_CNN.compile(loss="categorical_crossentropy", metrics=['accuracy'], optimizer=opt)
    else:
        print "######## Setting initial weights";
        DLS2F_CNN.compile(loss="categorical_crossentropy", metrics=['accuracy'], optimizer=opt)
     
 
    train_acc_best = 0 
    val_acc_best = 0
    print 'Loading existing val accuracy is %.5f' % (val_acc_best)   
    for epoch in range(0,epoch_outside):
        print "\n############ Running epoch ", epoch 
    
        for key in data_all_dict_padding.keys():
            if key <start:
                continue
            if key > end:
                continue
            print '### Loading sequence length :', key
            seq_len=key
            
            train_featuredata_all=Train_data_keys[seq_len]
            train_targets=Train_targets_keys[seq_len]
            test_featuredata_all=Test_data_keys[seq_len]
            test_targets=Test_targets_keys[seq_len]
            print "Train shape: ",train_featuredata_all.shape, " in outside epoch ", epoch 
            print "Test shape: ",test_featuredata_all.shape, " in outside epoch ", epoch
            DLS2F_CNN.fit([train_featuredata_all], train_targets, batch_size=50,nb_epoch=epoch_inside,  validation_data=([test_featuredata_all], test_targets), verbose=1)
            # serialize model to JSON
            model_json = DLS2F_CNN.to_json()
            print("Saved model to disk")
            with open(model_out, "w") as json_file:
                json_file.write(model_json)
            del train_featuredata_all
            del train_targets
            del test_featuredata_all
            del test_targets
            
            # serialize weights to HDF5
            print("Saved weight to disk") 
            DLS2F_CNN.save_weights(model_weight_out)
        
        if epoch < epoch_outside*1/3:
            continue
        """
        corrected_top1=0
        corrected_top5=0
        corrected_top10=0
        corrected_top15=0
        corrected_top20=0
        sequence_file=open(test_list,'r').readlines() 
        #pdb_name='d1np7a1'
        all_cases=0
        corrected=0
        for i in xrange(len(sequence_file)):
            if sequence_file[i].find('Length') >0 :
                print "Skip line ",sequence_file[i]
                continue
            pdb_name = sequence_file[i].split('\t')[0]
            
            test_featuredata_all=Testlist_data_keys[pdb_name]
            test_targets=Testlist_targets_keys[pdb_name]
            score, accuracy = DLS2F_CNN.evaluate([test_featuredata_all], test_targets, batch_size=10, verbose=0)
            all_cases +=1
            if accuracy == 1:
                corrected +=1    
            
            predict_val= DLS2F_CNN.predict([test_featuredata_all])
            top1_prediction=predict_val[0].argsort()[-1:][::-1]
            top5_prediction=predict_val[0].argsort()[-5:][::-1]
            top10_prediction=predict_val[0].argsort()[-10:][::-1]
            top15_prediction=predict_val[0].argsort()[-15:][::-1]
            top20_prediction=predict_val[0].argsort()[-20:][::-1]
            true_index = test_targets[0].argsort()[-1:][::-1][0]
            if true_index in top1_prediction:
                corrected_top1 +=1
            if true_index in top5_prediction:
                corrected_top5 +=1
            if true_index in top10_prediction:
                corrected_top10 +=1
            if true_index in top15_prediction:
                corrected_top15 +=1
            if true_index in top20_prediction:
                corrected_top20 +=1
            del test_featuredata_all
            del test_targets   
        test_acc = float(corrected)/all_cases
        print 'The test accuracy is %.5f' % (test_acc) 
        top1_acc = float(corrected_top1)/all_cases
        top5_acc = float(corrected_top5)/all_cases
        top10_acc = float(corrected_top10)/all_cases
        top15_acc = float(corrected_top15)/all_cases
        top20_acc = float(corrected_top20)/all_cases
        print 'The top1_acc accuracy2 is %.5f' % (top1_acc)
        print 'The top5_acc accuracy is %.5f' % (top5_acc)
        print 'The top10_acc accuracy is %.5f' % (top10_acc)
        print 'The top15_acc accuracy is %.5f' % (top15_acc)
        print 'The top20_acc accuracy is %.5f' % (top20_acc)
        """
        sequence_file=open(val_list,'r').readlines() 
        #pdb_name='d1np7a1'
        all_cases=0
        corrected=0
        for i in xrange(len(sequence_file)):
            if sequence_file[i].find('Length') >0 :
                #print "Skip line ",sequence_file[i]
                continue
            pdb_name = sequence_file[i].split('\t')[0]
            
            val_featuredata_all=Vallist_data_keys[pdb_name]
            val_targets=Vallist_targets_keys[pdb_name]
            score, accuracy = DLS2F_CNN.evaluate([val_featuredata_all], val_targets, batch_size=10, verbose=0)
            del val_featuredata_all
            del val_targets
            all_cases +=1
            if accuracy == 1:
                corrected +=1 
        
        val_acc = float(corrected)/all_cases
        if val_acc >= val_acc_best:
            val_acc_best = val_acc 
            print("Saved best weight to disk") 
            DLS2F_CNN.save_weights(model_weight_out_best)
        print 'The val accuracy is %.5f' % (val_acc)     #   ---> 0.25499
        
        if epoch < epoch_outside-5:
            continue
                 
        sequence_file=open(train_list,'r').readlines() 
        #pdb_name='d1np7a1'
        all_cases=0
        corrected=0
        for i in xrange(len(sequence_file)):
            if sequence_file[i].find('Length') >0 :
                print "Skip line ",sequence_file[i]
                continue
            pdb_name = sequence_file[i].split('\t')[0]
            
            train_featuredata_all=Trainlist_data_keys[pdb_name]
            train_targets=Trainlist_targets_keys[pdb_name]
            score, accuracy = DLS2F_CNN.evaluate([train_featuredata_all], train_targets, batch_size=10, verbose=0)
            del train_featuredata_all
            del train_targets
            all_cases +=1
            if accuracy == 1:
                corrected +=1   
        
        train_acc = float(corrected)/all_cases
        print 'The training accuracy is %.5f' % (train_acc)
        if val_acc >= val_acc_best:
            train_acc_best = train_acc   
    print "Training finished, best training acc = ",train_acc_best
    print "Training finished, best validation acc = ",val_acc_best
    print "Setting and saving best weights"
    DLS2F_CNN.load_weights(model_weight_out_best)
    DLS2F_CNN.save_weights(model_weight_out)
  