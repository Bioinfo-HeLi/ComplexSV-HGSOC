#!/bin/bash

#SBATCH -J manta
#SBATCH -N 1
#SBATCH -n 8
#SBATCH -p cpu_384
#SBATCH -o /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/manta.log
#SBATCH -e /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/manta.err

cd /share/home/sunLab/lihe/ecDNA/ovarian_cancer

config_file=$1
number1=$2
number2=$3
currentdir=`pwd`

ref=/share/home/sunLab/lihe/ecDNA/data_repo/GRCh37/human_g1k_v37.fasta
delly=/share/apps/softwares/delly_v0.9.1/delly
excl=/share/home/sunLab/lihe/biosoft/delly/excludeTemplates/human.hg19.excl.tsv
extractSplitReads_BwaMem=/share/home/sunLab/lihe/biosoft/lumpy-sv/scripts/extractSplitReads_BwaMem

if [ ! -d "$currentdir/08.SV/03.manta/status" ]
then
mkdir -p "$currentdir/08.SV/03.manta/status"
fi

cat $config_file | while read id 
do
  arr=($id)
  normal=${arr[1]}
  tumor=${arr[0]}

  if((i%$number1==$number2))
  then

    if [ ! -f  08.SV/03.manta/status/ok.manta.${tumor}.status ]; then

      mkdir -p 08.SV/03.manta/${tumor}

      configManta.py  \
      --tumorBam 04.align/${tumor}.bam  \
      --normalBam 04.align/${normal}.bam  \
      --referenceFasta ${ref}  \
      --runDir 08.SV/03.manta/${tumor}

      python 08.SV/03.manta/${tumor}/runWorkflow.py --quiet -m local -j 8
    
    fi
    
    if [ $? -eq 0 ]; then
      touch  08.SV/03.manta/status/ok.manta.${tumor}.status 
    else
      echo "manta failed" ${tumor}
    fi
  fi 

  i=$((i+1))

done