#!/bin/bash

#SBATCH -J jabba
#SBATCH -N 1
#SBATCH -n 4
#SBATCH -o /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/jabba.log
#SBATCH -e /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/jabba.err
#SBATCH -D /share/home/sunLab/lihe/ecDNA/ovarian_cancer

export R_LIBS=/share/home/sunLab/lihe/.conda/envs/wgs/lib/R/library
JABBA_PATH=$(Rscript -e 'cat(paste0(installed.packages()["JaBbA", "LibPath"], "/JaBbA/extdata/"))')
export PATH=${PATH}:${JABBA_PATH}
export CPLEX_DIR=/share/home/sunLab/lihe/biosoft/CPLEX

config_file=$1
number1=$2
number2=$3
currentdir=`pwd`

cat $config_file |while read id 
do
  arr=($id)
  normal=${arr[1]}
  tumor=${arr[0]}
  purity=${arr[2]}
  ploidy=${arr[3]}

  if((i%$number1==$number2))
  then
    if [ ! -f  09.CGR/03.jabba/status/ok.jabba.${tumor}.status ]; then
      jba \
      08.SV/merge/${tumor}.bedpe  \
      09.CGR/02.dryclean/${tumor}/drycleaned.cov.rds \
      --field foreground \
      --purity ${purity} \
      --ploidy ${ploidy} 
    fi
    if [ $? -eq 0 ]; then
      touch  09.CGR/03.jabba/status/ok.jabba.${tumor}.status 
    else
      echo "03.jabba failed" ${tumor}
    fi
  fi 

  i=$((i+1))

done
