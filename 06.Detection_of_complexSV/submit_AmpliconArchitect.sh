#!/bin/bash

#SBATCH -J AA
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -o /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/AA.log
#SBATCH -e /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/AA.err
#SBATCH -D /share/home/sunLab/lihe/ecDNA/ovarian_cancer

config_file=$1
number1=$2
number2=$3
currentdir=`pwd`

ref=/share/home/sunLab/lihe/ecDNA/data_repo/only_chr1-22-X_GRCh37/human_g1k_v37.fasta

cat $config_file |while read id 
do
  arr=($id)
  normal=${arr[1]}
  tumor=${arr[0]}

  if((i%$number1==$number2))
  then 

    if [ ! -f  06.CNV/status/ok.CNV.${tumor}.status ]; then
      
      cnvkit.py  batch  04.align/${tumor}.bam  \
      --normal  04.align/${normal}.bam  \
      --fasta  ${ref}  --output-reference 06.CNV/${tumor}/my_reference.cnn  \
      --drop-low-coverage  --scatter  --diagram  --method  wgs  -p  6  \
      --output-dir  06.CNV/${tumor}/
    fi

    if [ $? -eq 0 ]; then
      touch 06.CNV/status/ok.cnvkit.${tumor}.status
    else
      echo "cnvkit failed" ${tumor}
    fi

    if [ ! -f  07.AA/status/ok.AA.${tumor}.status ]; then

      python /share/home/sunLab/lihe/biosoft/PrepareAA-master/scripts/convert_cns_to_bed.py \
      --cns_file 06.CNV/01.CNVkit/${tumor}/${tumor}.cns

      mv ${tumor}_ESTIMATED_PLOIDY_CORRECTED_CN.bed  ${tumor}_uncorr_CN.bed  07.AA/prepareAA/
        
      python $AA_SRC/amplified_intervals.py   \
      --gain 4.3 --cnsize_min 50000 --ref GRCh37   \
      --bed  07.AA/prepareAA/${tumor}_ESTIMATED_PLOIDY_CORRECTED_CN.bed   \
      --out  07.AA/${tumor}/${tumor}.alts.dat   \
      --bam  04.align/${tumor}.bam 

      python $AA_SRC/AmpliconArchitect.py  \
      --ref  GRCh37  \
      --bam  04.align/${tumor}.bam   \
      --bed  07.AA/${tumor}/${tumor}.alts.dat.bed   \
      --out  07.AA/${tumor}/

    fi

    if [ $? -eq 0 ]; then
      touch 07.AA/status/ok.AA.${tumor}.status
    else
      echo "AA failed" ${tumor}
    fi

  fi 

  i=$((i+1))

done 
