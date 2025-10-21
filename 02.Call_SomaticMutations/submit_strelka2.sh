#!/bin/bash

#SBATCH -J strelka2
#SBATCH -N 1
#SBATCH -n 4
#SBATCH -p cpu_384
#SBATCH -o /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/strelka2.log
#SBATCH -e /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/strelka2.err

cd /share/home/sunLab/lihe/ecDNA/ovarian_cancer

config_file=$1
number1=$2
number2=$3
currentdir=`pwd`

ref=/share/home/sunLab/lihe/ecDNA/data_repo/GRCh37/human_g1k_v37.fasta

if [ ! -d "10.somatic_mutations/01.strelka2/status" ]
then
mkdir -p "10.somatic_mutations/01.strelka2/status"
fi

cat $config_file |while read id 
do
  arr=($id)
  normal=${arr[1]}
  tumor=${arr[0]}

  if((i%$number1==$number2))
  then

    if [ ! -f  10.somatic_mutations/01.strelka2/status/ok.strelka2.$tumor.status ]; then

        mkdir -p 10.somatic_mutations/01.strelka2/${tumor}

        /share/apps/softwares/strelka-2.9.10.centos6_x86_64/bin/configureStrelkaSomaticWorkflow.py  \
        --config=/share/apps/softwares/strelka-2.9.10.centos6_x86_64/bin/configureStrelkaSomaticWorkflow.py.ini  \
        --normalBam=05.gatk/01.bqsr/${normal}.bqsr.bam  \
        --tumorBam=05.gatk/01.bqsr/${tumor}.bqsr.bam  \
        --referenceFasta=${ref}  \
        --runDir=10.somatic_mutations/01.strelka2/${tumor} 

        python 10.somatic_mutations/01.strelka2/${tumor}/runWorkflow.py -m local -j 4
    
    fi

    if [ $? -eq 0 ]; then
      touch  10.somatic_mutations/01.strelka2/status/ok.strelka2.${tumor}.status 
    else
      echo "strelka2 failed" ${tumor}
    fi
  
  fi 

  i=$((i+1))

done
