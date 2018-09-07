# DeepSF
Deep convolutional neural network for mapping protein sequences to folds


```
### use Sequence similarity reduction dataset as training
python ./training/predict_single.py ./datasets/Traindata.list ./models/model_SimilarityReduction.json  ./models/model_SimilarityReduction.h5 /var/www/html/DeepSF/download/SCOP175_training_data_09202017/ ./test/out1
The top1_acc accuracy is 0.84836 (10445/12312)
The top5_acc accuracy is 0.96093 (11831/12312)
The top10_acc accuracy is 0.97685 (12027/12312)
The top15_acc accuracy is 0.98424 (12118/12312)
The top20_acc accuracy is 0.98863 (12172/12312)


python ./training/predict_single.py ./datasets/validation.list ./models/model_SimilarityReduction.json  ./models/model_SimilarityReduction.h5 /var/www/html/DeepSF/download/SCOP175_training_data_09202017/ ./test/out2
The top1_acc accuracy is 0.75136 (553/736)
The top5_acc accuracy is 0.94565 (696/736)
The top10_acc accuracy is 0.97147 (715/736)
The top15_acc accuracy is 0.98098 (722/736)
The top20_acc accuracy is 0.98505 (725/736)

python ./training/predict_single.py ./datasets/Testdata.list ./models/model_SimilarityReduction.json  ./models/model_SimilarityReduction.h5 /var/www/html/DeepSF/download/SCOP175_training_data_09202017/ ./test/out1
The top1_acc accuracy is 0.72996 (1849/2533)
The top5_acc accuracy is 0.90249 (2286/2533)
The top10_acc accuracy is 0.94512 (2394/2533)
The top15_acc accuracy is 0.95973 (2431/2533)
The top20_acc accuracy is 0.96723 (2450/2533)


### use Three-level homology reduction dataset as training

python ./training/predict_single.py ./datasets/Three_levels_dataset/test_dataset.list_fold ./models/model_ThreeLevel.json  ./models/model_ThreeLevel.h5 /var/www/html/DeepSF/download/SCOP175_training_data_09202017/ ./test/out2
The top1_acc accuracy is 0.41226 (296/718)
The top5_acc accuracy is 0.70613 (507/718)
The top10_acc accuracy is 0.82591 (593/718)
The top15_acc accuracy is 0.86908 (624/718)
The top20_acc accuracy is 0.89694 (644/718)

python ./training/predict_single.py ./datasets/Three_levels_dataset/test_dataset.list_family ./models/model_ThreeLevel.json  ./models/model_ThreeLevel.h5 /var/www/html/DeepSF/download/SCOP175_training_data_09202017/ ./test/out2
The top1_acc accuracy is 0.76494 (973/1272)
The top5_acc accuracy is 0.94733 (1205/1272)
The top10_acc accuracy is 0.97406 (1239/1272)
The top15_acc accuracy is 0.98428 (1252/1272)
The top20_acc accuracy is 0.98978 (1259/1272)

python ./training/predict_single.py ./datasets/Three_levels_dataset/test_dataset.list_superfamily ./models/model_ThreeLevel.json  ./models/model_ThreeLevel.h5 /var/www/html/DeepSF/download/SCOP175_training_data_09202017/ ./test/out1
The top1_acc accuracy is 0.50638 (635/1254)
The top5_acc accuracy is 0.77751 (975/1254)
The top10_acc accuracy is 0.86443 (1084/1254)
The top15_acc accuracy is 0.90750 (1138/1254)
The top20_acc accuracy is 0.92185 (1156/1254)
```
