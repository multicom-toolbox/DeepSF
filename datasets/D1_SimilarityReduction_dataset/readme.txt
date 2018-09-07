######## Sequence similarity reduction dataset

The SCOP 1.75 dataset with less than or equal to 95% sequence identity was split into training and
validation datasets with ratio 8/2 for each fold. Specifically, 80% of the proteins in each fold are used for
training, and the remaining 20% of proteins are used for validation. The training proteins from all folds are
combined to generate the final training dataset and likewise for the final validation dataset. The validation
dataset was further filtered to at most 70%, 40%, 25% pairwise similarity with the training dataset for
rigorous model selection and validation

The training dataset has 14,699 proteins, covering 1,195 folds, . 
The Test set with 95% similarity has 2,013 proteins.
The Test set with 70% similarity has 1,428 proteins.
The Test set with 40% similarity has 893 proteins.
The Test set with 25% similarity has 711 proteins.

Detailed results can refer to Table S1 in the supplementary file.

 
