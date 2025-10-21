#!/bin/bash

#SBATCH -J lumpy
#SBATCH -N 1
#SBATCH -n 4
#SBATCH -o /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/lumpy.log
#SBATCH -e /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/lumpy.err

cd /share/home/sunLab/lihe/ecDNA/ovarian_cancer
conda activate py2

config_file=$1
number1=$2
number2=$3
currentdir=`pwd`

ref=/share/home/sunLab/lihe/ecDNA/data_repo/GRCh37/human_g1k_v37.fasta
excl_mainchr=/share/home/sunLab/lihe/biosoft/delly/excludeTemplates/human.hg19.excl.mainchr.bed 
extractSplitReads_BwaMem=/share/home/sunLab/lihe/biosoft/lumpy-sv/scripts/extractSplitReads_BwaMem

if [ ! -d "$currentdir/08.SV/02.lumpy/status" ]
then
mkdir -p "$currentdir/08.SV/02.lumpy/status"
fi

cat $config_file |while read id 
do
  arr=($id)
  normal=${arr[1]}
  tumor=${arr[0]}

  if((i%$number1==$number2))
  then


    if [ ! -f  08.SV/02.lumpy/status/ok.lumpy.${tumor}.status ]; then

      samtools view -bh -F 1294 04.align/${tumor}.bam > 04.align/disc_bam/${tumor}.disc.bam
      samtools view -h 04.align/${tumor}.bam | ${extractSplitReads_BwaMem} -i stdin | samtools view -Sbh - > 04.align/split_bam/${tumor}.split.bam
      
      samtools view -bh -F 1294 04.align/${normal}.bam > 04.align/disc_bam/${normal}.disc.bam
      samtools view -h 04.align/${normal}.bam | ${extractSplitReads_BwaMem} -i stdin | samtools view -Sbh - >04.align/split_bam/${normal}.split.bam

      lumpyexpress  \
      -x ${excl_mainchr} \
      -B 04.align/${normal}.bam,04.align/${tumor}.bam  \
      -D 04.align/disc_bam/${normal}.disc.bam,04.align/disc_bam/${tumor}.disc.bam  \
      -S 04.align/split_bam/${normal}.split.bam,04.align/split_bam/${tumor}.split.bam  \
      -o 08.SV/02.lumpy/${tumor}/${tumor}_sv.vcf 

      svtyper  \
      -B 04.align/${normal}.bam,04.align/${tumor}.bam  \
      -i 08.SV/02.lumpy/${tumor}/${tumor}_sv.vcf  \
      -l 08.SV/02.lumpy/${tumor}/${tumor}.json > 08.SV/02.lumpy/${tumor}/${tumor}_sv_gt.vcf

    fi
    
    if [ $? -eq 0 ]; then
      touch  08.SV/02.lumpy/status/ok.lumpy.${tumor}.status 
    else
      echo "lumpy failed" ${tumor}
    fi
  fi 

  i=$((i+1))

done
