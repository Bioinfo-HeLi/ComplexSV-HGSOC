#!/bin/bash

#SBATCH -J svaba
#SBATCH -N 1
#SBATCH -n 8
#SBATCH -o /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/svaba.log
#SBATCH -e /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/svaba.err
#SBATCH -D /share/home/sunLab/lihe/ecDNA/ovarian_cancer

config_file=$1
number1=$2
number2=$3
currentdir=`pwd`

ref=/share/home/sunLab/lihe/ecDNA/data_repo/GRCh37/human_g1k_v37.fasta
dbsnp=/share/home/sunLab/lihe/broad_reference/hg19/dbsnp_indel.vcf

if [ ! -d "08.SV/04.svaba/status" ]
then
mkdir -p "08.SV/04.svaba/status"
fi


cat $config_file |while read id 
do
  arr=($id)
  normal=${arr[1]}
  tumor=${arr[0]}

  if((i%$number1==$number2))
  then

    if [ ! -f  08.SV/04.svaba/status/ok.svaba.${tumor}.status ]; then

      mkdir -p 08.SV/04.svaba/${tumor}

      svaba run -G ${ref} -a ${tumor} -p 8 -D ${dbsnp} \
      -t 04.align/${tumor}.bam \
      -n 04.align/${normal}.bam 

      mv ${tumor}.*  08.SV/04.svaba/${tumor}
      
    fi

    if [ $? -eq 0 ]; then
      touch  08.SV/04.svaba/status/ok.svaba.${tumor}.status 
    else
      echo "svaba failed" ${tumor}
    fi
  
  fi 

  i=$((i+1))

done