#!/bin/sh
# Scripts/make_DeepProTa_prediction.sh  2mnjB  /exports/store1/jh7x3/DNTorsion/Inputs/2mnjB  DNN  /exports/store1/jh7x3/DNTorsion/output


if [ "$#" -ne 7 ]; then
    echo "The number of parameters ($#) is not correct! >"
    exit 1
fi
sequence_name=$1
sequence_file=$2
outputdir=$3
GLOBAL_PATH=$4
PSPRO_PATH=$5
NR_PATH=$6
BIGDB_PATH=$7


install_dir=${GLOBAL_PATH}
Scriptdir=${GLOBAL_PATH}

cd ${Scriptdir}

#use tools to generate features for sequence  

python  ./generate_pssm.py $sequence_name $sequence_file $install_dir $outputdir $PSPRO_PATH $NR_PATH $BIGDB_PATH
