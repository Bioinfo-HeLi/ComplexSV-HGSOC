#!/bin/bash

#SBATCH -J GRIDSS
#SBATCH -N 1
#SBATCH -n 8
#SBATCH --mem=40G
#SBATCH -o /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/gridss.log
#SBATCH -e /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/gridss.err

cd /share/home/sunLab/lihe/ecDNA/ovarian_cancer

config_file=$1
number1=$2
number2=$3
currentdir=`pwd`

ref=/share/home/sunLab/lihe/ecDNA/data_repo/GRCh37/human_g1k_v37.fasta
GRIDSS=/share/apps/softwares/gridss-2.13.2/gridss
GRIDSS_JAR=/share/apps/softwares/gridss-2.13.2/gridss-2.13.2-gridss-jar-with-dependencies.jar 
exclude_list=/share/home/sunLab/lihe/HMFTools-Resources/hmf_dna_pipeline_resources.37_v5.33/sv/gridss_blacklist.37.bed


if [ ! -d "$currentdir/08.SV/05.gridss/status" ]
then
mkdir -p "$currentdir/08.SV/05.gridss/status"
fi

if [ ! -d "$currentdir/08.SV/05.gridss/working_dir" ]
then
mkdir -p "$currentdir/08.SV/05.gridss/working_dir"
fi

if [ ! -d "$currentdir/08.SV/05.gridss/results" ]
then
mkdir -p "$currentdir/08.SV/05.gridss/results"
fi

cat $config_file |while read id 
do
  arr=($id)
  normal=${arr[1]}
  tumor=${arr[0]}

  if((i%$number1==$number2))
  then

    if [ ! -f  08.SV/05.gridss/status/ok.gridss.${tumor}.status ]; then

      GRIDSS_RAW=/share/home/sunLab/lihe/ecDNA/ovarian_cancer/08.SV/05.gridss/results/${tumor}.gridss.raw.vcf
      GRIDSS_ASSEMBLY=/share/home/sunLab/lihe/ecDNA/ovarian_cancer/08.SV/05.gridss/results/${tumor}.assembly.bam
      GRIDSS_WORKING_DIR=/share/home/sunLab/lihe/ecDNA/ovarian_cancer/08.SV/05.gridss/working_dir/${tumor}
      NORMAL_BAM=/share/home/sunLab/lihe/ecDNA/ovarian_cancer/04.align/${normal}.bam
      TUMOR_BAM=/share/home/sunLab/lihe/ecDNA/ovarian_cancer/04.align/${tumor}.bam

      $GRIDSS \
      --reference ${ref} \
      --output $GRIDSS_RAW \
      --assembly $GRIDSS_ASSEMBLY \
      --jar $GRIDSS_JAR \
      --steps All \
      --workingdir $GRIDSS_WORKING_DIR \
      --threads 8 \
      --jvmheap 40g \
      --blacklist ${exclude_list} \
      --maxcoverage 50000 \
      $NORMAL_BAM $TUMOR_BAM
      
   
    fi
    
    if [ $? -eq 0 ]; then
      touch  08.SV/05.gridss/status/ok.gridss.${tumor}.status 
    else
      echo "gridss failed" ${tumor}
    fi
  fi 

  i=$((i+1))

done
