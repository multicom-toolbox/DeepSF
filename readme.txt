******************************************
Source code for project 

Hou, J., Adhikari, B., & Cheng, J. (2017). DeepSF: deep convolutional neural network for mapping protein sequences to folds. Bioinformatics, 34(8), 1295-1303.

http://iris.rnet.missouri.edu/DeepSF/

2018/07/23
******************************************

datasets/:
    The training dataset has 12,312 proteins, covering 1,195 folds. 
    The validation set has 736 proteins, covering 319 folds. 
    The three redundancy-reduced test datasets at fold-level, superfamily-level and familylevel have 718, 1,254, and 1,272 proteins, respectively. 
    The combined test dataset of the three has 3,244 proteins in total, covering 457 folds.
    
    
lib/:
    Source code for training, prediction, and evaluation


training_main.py:
    script for training model
    
    
predict_main.py:
    script for predicting results
    

P1_train.sh:
    shell script do all training with pre-specified parameters
    
    
P1_evaluate.sh:
    shell script do all prediciton and evaluation with pre-specified parameters
    
    
Start the project:

1. first download the feature files (Training dataset from SCOP 1.75 (314M)) from website http://iris.rnet.missouri.edu/DeepSF/download.html
   
2. set the path of feature variables (feature_dir_global, pssm_dir_global) in script './predict_main.py'    
   
3. set the path of feature variables (feature_dir_global, pssm_dir_global) in script './library.py'  

4. install packages 


  keras: 1.2.2
  
  numpy: 1.12.1
  
  theano: 0.9.0


4. training
  cd DeepSF_Source_code/
  sh P1_train.sh

5. run evaluation
  cd DeepSF_Source_code/
  sh P1_evaluate.sh

