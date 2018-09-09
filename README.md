# DeepSF

**Deep convolutional neural network for mapping protein sequences to folds**

Web-server and datasets at http://iris.rnet.missouri.edu/DeepSF/  

Test Environment
--------------------------------------------------------------------------------------
Red Hat Enterprise Linux Server release 6.4 (Santiago)

Installation Steps
--------------------------------------------------------------------------------------

**(A) Download and Unzip DeepSF source package**  

Create a working directory called 'DeepSF' where all scripts, programs and databases will reside:
```
cd ~
mkdir DeepSF_package
```
Download the DeepSF code:
```
cd ~/DeepSF_package/
git clone https://github.com/multicom-toolbox/DeepSF.git
cd DeepSF

# Alternately
cd ~/DeepSF_package/
wget http://sysbio.rnet.missouri.edu/bdm_download/DeepSF/DeepSF_source_code.tar.gz
tar -zxf DeepSF_source_code.tar.gz
mv DeepSF_source_code DeepSF
cd DeepSF
```

**(B) Download feature dataset for training only**  
```
cd ~/DeepSF_package/DeepSF 
cd datasets 
mkdir features
cd features
wget http://sysbio.rnet.missouri.edu/bdm_download/DeepSF/datasets/features/Feature_aa_ss_sa.tar.gz
tar -zxf Feature_aa_ss_sa.tar.gz
rm Feature_aa_ss_sa.tar.gz

wget http://sysbio.rnet.missouri.edu/bdm_download/DeepSF/datasets/features/PSSM_Fea.tar.gz
tar -zxf PSSM_Fea.tar.gz
rm PSSM_Fea.tar.gz
```

**(C) Download software package for structure prediction (~14G)**  
```
cd ~/DeepSF_package/DeepSF  
wget http://sysbio.rnet.missouri.edu/bdm_download/DeepSF/software.tar.gz
tar -zxf software.tar.gz
rm software.tar.gz
```

**(D) Install theano, Keras, and h5py and Update keras.json**  

(a) Create python virtual environment (if not installed)
```
virtualenv ~/python_virtualenv_deepsf
source ~/python_virtualenv_deepsf/bin/activate
```

(b) Install theano: 
```
pip install theano==0.9.0
```

(c) Install Keras:
```
pip install keras==1.2.2
```

(d) Install the h5py library:  
```
pip install python-h5py
```

(e) Install the matplotlib library:  
```
pip install matplotlib
```

(f) Add the entry [“image_dim_ordering": "tf”,] to your keras..json file at ~/.keras/keras.json. After the update, your keras.json should look like the one below:  
```
{
"epsilon": 1e-07,
"floatx": "float32",
"image_dim_ordering":"tf",
"image_data_format": "channels_last",
"backend": "theano"
}
```

**(E) Configuration**

```
perl configure.pl
```

**(F) Testing** 

***use Sequence similarity reduction dataset as training***
```
THEANO_FLAGS=floatX=float32,device=cpu python ./training/predict_single.py ./datasets/Traindata.list ./models/model_SimilarityReduction.json  ./models/model_SimilarityReduction.h5 /var/www/html/DeepSF/download/SCOP175_training_data_09202017/ ./test/out1 30
The top1_acc accuracy is 0.85734 (12602/14699)
The top5_acc accuracy is 0.97524 (14335/14699)
The top10_acc accuracy is 0.98925 (14541/14699)
The top15_acc accuracy is 0.99374 (14607/14699)
The top20_acc accuracy is 0.99599 (14640/14699)

THEANO_FLAGS=floatX=float32,device=cpu python ./training/predict_single.py ./datasets/D1_SimilarityReduction_dataset/Testdata_id95againstTrain.list  ./models/model_SimilarityReduction.json  ./models/model_SimilarityReduction.h5 /var/www/html/DeepSF/download/SCOP175_training_data_09202017/ ./test/out2 30
The top1_acc accuracy is 0.80378 (1618/2013)
The top5_acc accuracy is 0.93691 (1886/2013)
The top10_acc accuracy is 0.96225 (1937/2013)
The top15_acc accuracy is 0.97317 (1959/2013)
The top20_acc accuracy is 0.97963 (1972/2013)

THEANO_FLAGS=floatX=float32,device=cpu python ./training/predict_single.py ./datasets/D1_SimilarityReduction_dataset/Testdata_id70againstTrain.list  ./models/model_SimilarityReduction.json  ./models/model_SimilarityReduction.h5 /var/www/html/DeepSF/download/SCOP175_training_data_09202017/ ./test/out2 30
The top1_acc accuracy is 0.78221 (1117/1428)
The top5_acc accuracy is 0.92437 (1320/1428)
The top10_acc accuracy is 0.95378 (1362/1428)
The top15_acc accuracy is 0.96639 (1380/1428)
The top20_acc accuracy is 0.97409 (1391/1428)

THEANO_FLAGS=floatX=float32,device=cpu python ./training/predict_single.py ./datasets/D1_SimilarityReduction_dataset/Testdata_id40againstTrain.list  ./models/model_SimilarityReduction.json  ./models/model_SimilarityReduction.h5 /var/www/html/DeepSF/download/SCOP175_training_data_09202017/ ./test/out2 30
The top1_acc accuracy is 0.75812 (677/893)
The top5_acc accuracy is 0.90034 (804/893)
The top10_acc accuracy is 0.93617 (836/893)
The top15_acc accuracy is 0.95185 (850/893)
The top20_acc accuracy is 0.96193 (859/893)

THEANO_FLAGS=floatX=float32,device=cpu python ./training/predict_single.py ./datasets/D1_SimilarityReduction_dataset/Testdata_id25againstTrain.list  ./models/model_SimilarityReduction.json  ./models/model_SimilarityReduction.h5 /var/www/html/DeepSF/download/SCOP175_training_data_09202017/ ./test/out2 30
The top1_acc accuracy is 0.66948 (476/711)
The top5_acc accuracy is 0.87623 (623/711)
The top10_acc accuracy is 0.92124 (655/711)
The top15_acc accuracy is 0.94093 (669/711)
The top20_acc accuracy is 0.95218 (677/711)


THEANO_FLAGS=floatX=float32,device=cpu python ./training/predict_single.py ./datasets/SCOP206.list ./models/model_SimilarityReduction.json  ./models/model_SimilarityReduction.h5 /var/www/html/DeepSF/download/SCOP175_training_data_09202017/ ./test/out1 30
The top1_acc accuracy is 0.72996 (1849/2533)
The top5_acc accuracy is 0.90249 (2286/2533)
The top10_acc accuracy is 0.94512 (2394/2533)
The top15_acc accuracy is 0.95973 (2431/2533)
The top20_acc accuracy is 0.96723 (2450/2533)

```

*** use Three-level homology reduction dataset as training***
```
THEANO_FLAGS=floatX=float32,device=cpu python ./training/predict_single.py ./datasets/D2_Three_levels_dataset/test_dataset.list_fold ./models/model_ThreeLevel.json  ./models/model_ThreeLevel.h5 /var/www/html/DeepSF/download/SCOP175_training_data_09202017/ ./test/out2  36
The top1_acc accuracy is 0.40947 (294/718)
The top5_acc accuracy is 0.70474 (506/718)
The top10_acc accuracy is 0.82451 (592/718)
The top15_acc accuracy is 0.86908 (624/718)
The top20_acc accuracy is 0.89694 (644/718)

THEANO_FLAGS=floatX=float32,device=cpu python ./training/predict_single.py ./datasets/D2_Three_levels_dataset/test_dataset.list_family ./models/model_ThreeLevel.json  ./models/model_ThreeLevel.h5 /var/www/html/DeepSF/download/SCOP175_training_data_09202017/ ./test/out2  36
The top1_acc accuracy is 0.76179 (969/1272)
The top5_acc accuracy is 0.94497 (1202/1272)
The top10_acc accuracy is 0.97563 (1241/1272)
The top15_acc accuracy is 0.98428 (1252/1272)
The top20_acc accuracy is 0.98978 (1259/1272)

THEANO_FLAGS=floatX=float32,device=cpu python ./training/predict_single.py ./datasets/D2_Three_levels_dataset/test_dataset.list_superfamily ./models/model_ThreeLevel.json  ./models/model_ThreeLevel.h5 /var/www/html/DeepSF/download/SCOP175_training_data_09202017/ ./test/out2  36
The top1_acc accuracy is 0.50718 (636/1254)
The top5_acc accuracy is 0.77671 (974/1254)
The top10_acc accuracy is 0.86443 (1084/1254)
The top15_acc accuracy is 0.90431 (1134/1254)
The top20_acc accuracy is 0.92105 (1155/1254)
```

**Training**
```
cd training
sh P1_train.sh

The top1_acc accuracy is 0.84142 (12368/14699)
The top5_acc accuracy is 0.97007 (14259/14699)
The top10_acc accuracy is 0.98782 (14520/14699)
The top15_acc accuracy is 0.99299 (14596/14699)
The top20_acc accuracy is 0.99599 (14640/14699)
```

**Evaluation**
```
sh P1_evaluate.sh

The top1_acc accuracy is 0.84142 (12368/14699)
The top5_acc accuracy is 0.97007 (14259/14699)
The top10_acc accuracy is 0.98782 (14520/14699)
The top15_acc accuracy is 0.99299 (14596/14699)
The top20_acc accuracy is 0.99599 (14640/14699)

The top1_acc accuracy is 0.70549 (1787/2533)
The top5_acc accuracy is 0.89380 (2264/2533)
The top10_acc accuracy is 0.94039 (2382/2533)
The top15_acc accuracy is 0.95420 (2417/2533)
The top20_acc accuracy is 0.96210 (2437/2533)

The top1_acc accuracy is 0.78341 (1577/2013)
The top5_acc accuracy is 0.92697 (1866/2013)
The top10_acc accuracy is 0.95926 (1931/2013)
The top15_acc accuracy is 0.96870 (1950/2013)
The top20_acc accuracy is 0.97466 (1962/2013)
```


**(G) Protein fold recognition and structure prediction**

(a) Download the template database (~34G)
```
cd ~/DeepSF_package/DeepSF 
wget http://sysbio.rnet.missouri.edu/bdm_download/DeepSF/database.tar.gz
tar -zxf database.tar.gz
rm database.tar.gz
```

(b) Test required softwares

```
```

(c) Run fold recognition only

```
source ~/python_virtualenv_deepsf/bin/activate
perl scripts/deepsf_fr.pl scripts/fr_option_adv_for_deepsf test/test.fasta  test/out1  fold_only

The ranking of top SCOP folds are saved in test/out1/fold_rank_list.SCOP
The ranking of top ECOD_X folds are saved in test/out1/fold_rank_list.ECOD_X
The ranking of top ECOD_H folds are saved in test/out1/fold_rank_list.ECOD_H

```

(d) Run fold recognition and structure prediction

```
source ~/python_virtualenv_deepsf/bin/activate
perl scripts/deepsf_fr.pl scripts/fr_option_adv_for_deepsf test/test.fasta  test/out2

```
