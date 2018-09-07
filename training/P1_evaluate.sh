#!/bin/bash -l
#SBATCH -J  eva
#SBATCH -o eva-%j.out
#SBATCH -p gpu3
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --mem 20G
#SBATCH --gres gpu:1
#SBATCH -t 2-00:00:00

## Load Needed Modules
#module load cuda/cuda-8.0

GLOBAL_PATH='/home/jh7x3/DLS2F/DLS2F_Project/Paper_data/DeepSF_Source_code/';

datadir=$GLOBAL_PATH/datasets/D1_SimilarityReduction_dataset
outputdir=$GLOBAL_PATH/test
echo "#################  Training on inter 15"

## Test Theano
THEANO_FLAGS=floatX=float32,device=gpu python $GLOBAL_PATH/training/predict_main.py  15 10 10 nadam '6_10' 500 30 50 3  $datadir $outputdir
