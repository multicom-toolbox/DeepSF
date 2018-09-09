# DeepSF

**Deep convolutional neural network for mapping protein sequences to folds**
Web-server and datasets at http://iris.rnet.missouri.edu/DeepSF/  

Test Environment
--------------------------------------------------------------------------------------
64-bit PC - Ubuntu 16.04 LTS

Installation Steps
--------------------------------------------------------------------------------------

**(A) Download and Unzip DeepSF package**  
Create a working directory called 'DeepSF' where all scripts, programs and databases will reside:
```
cd ~
mkdir DeepSF
```
Download the DeepSF code:
```
cd ~/DeepSF/
git clone https://github.com/multicom-toolbox/DeepSF.git
```

**(B) Download feature dataset**  
```
cd ~/DeepSF/  
cd datasets 
wget http://sysbio.rnet.missouri.edu/bdm_download/DeepSF/datasets/features.tar.gz
tar -zxf features.tar.gz
```

**(C) Install theano, Keras, and h5py and Update keras.json**  

virtualenv ~/python_virtualenv
source ~/python_virtualenv/bin/activate

(a) Install theano: 
```
sudo pip install theano==0.9.0
```
(b) Install Keras:
```
sudo pip install keras==1.2.2
```
(c) Install the h5py library:  
```
sudo pip install python-h5py
```
(d) Install the matplotlib library:  
```
sudo pip install matplotlib
```

(e) Add the entry [“image_dim_ordering": "tf”,] to your keras..json file at ~/.keras/keras.json. After the update, your keras.json should look like the one below:  
```
{
"epsilon": 1e-07,
"floatx": "float32",
"image_dim_ordering":"tf",
"image_data_format": "channels_last",
"backend": "theano"
}
```

**(D) Configuration**

```
perl configure.pl
```

**(E) Testing** 

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

The top1_acc accuracy is 0.75672 (11123/14699)
The top5_acc accuracy is 0.94013 (13819/14699)
The top10_acc accuracy is 0.97265 (14297/14699)
The top15_acc accuracy is 0.98415 (14466/14699)
The top20_acc accuracy is 0.99000 (14552/14699)
```

**Evaluation**
```
sh P1_evaluate.sh

The top1_acc accuracy is 0.75672 (11123/14699)
The top5_acc accuracy is 0.94013 (13819/14699)
The top10_acc accuracy is 0.97265 (14297/14699)
The top15_acc accuracy is 0.98415 (14466/14699)
The top20_acc accuracy is 0.99000 (14552/14699)

The top1_acc accuracy is 0.63956 (1620/2533)
The top5_acc accuracy is 0.86932 (2202/2533)
The top10_acc accuracy is 0.92538 (2344/2533)
The top15_acc accuracy is 0.94473 (2393/2533)
The top20_acc accuracy is 0.95539 (2420/2533)

The top1_acc accuracy is 0.73572 (1481/2013)
The top5_acc accuracy is 0.89916 (1810/2013)
The top10_acc accuracy is 0.94635 (1905/2013)
The top15_acc accuracy is 0.96274 (1938/2013)
The top20_acc accuracy is 0.97069 (1954/2013)
```


**(G) Protein fold recognition and structure prediction**
Working on the update
