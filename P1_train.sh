#!/bin/bash -l
#SBATCH -J  train
#SBATCH -o train-%j.out
#SBATCH -p gpu3
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --mem 20G
#SBATCH --gres gpu:1
#SBATCH -t 2-00:00:00

## Load Needed Modules
#module load cuda/cuda-8.0

datadir=/home/jh7x3/DLS2F/DLS2F_Project/Paper_data/DeepSF_Source_code/datasets/
outputdir=/home/jh7x3/DLS2F/DLS2F_Project/Paper_data/DeepSF_Source_code/test
echo "#################  Training on inter 15"
## Test Theano
THEANO_FLAGS=floatX=float32,device=gpu python /home/jh7x3/DLS2F/DLS2F_Project/Paper_data/DeepSF_Source_code/training_main_iterative.py 15 10 15 nadam '8_10' 500 30 100 5  $datadir $outputdir
## Test Theano
THEANO_FLAGS=floatX=float32,device=gpu python /home/jh7x3/DLS2F/DLS2F_Project/Paper_data/DeepSF_Source_code/predict_main.py  15 10 15 nadam '8_10' 500 30 100 5  $datadir $outputdir
