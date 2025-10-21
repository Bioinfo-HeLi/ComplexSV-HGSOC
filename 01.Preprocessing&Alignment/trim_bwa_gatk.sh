#!/bin/bash

#SBATCH -J trim_bwa_gatk
#SBATCH -N 1
#SBATCH -n 16
#SBATCH --mem=32G
#SBATCH -o /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/trim_bwa_gatk.log
#SBATCH -e /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/trim_bwa_gatk.err
#SBATCH -D /share/home/sunLab/lihe/ecDNA/ovarian_cancer

index=/share/home/sunLab/lihe/ecDNA/data_repo/GRCh37/human_g1k_v37.fasta
samblaster=/share/apps/softwares/samblaster/samblaster
dbsnp=/share/home/sunLab/lihe/broad_reference/hg19/dbsnp_138.b37.vcf.gz
dbsnp1000G=/share/home/sunLab/lihe/broad_reference/hg19/1000G_phase1.snps.high_confidence.b37.vcf.gz
dbindel1000G=/share/home/sunLab/lihe/broad_reference/hg19/Mills_and_1000G_gold_standard.indels.b37.vcf.gz
ref=/share/home/sunLab/lihe/ecDNA/data_repo/GRCh37/human_g1k_v37.fasta
gatk=/share/apps/softwares/gatk-4.2.5.0/gatk


config_file=$1
number1=$2
number2=$3
currentdir=`pwd`


cat $config_file |while read id
do
  arr=($id)
  sample=${arr[0]}

  if((i%$number1==$number2))
  then

    ## trim-galore
    if [ ! -f  02.clean_fq/status/ok.trim_galore.${sample}.status ]; then
    trim_galore -q 28 --phred33 --length 36 -e 0.1 --stringency 3 --paired --cores 16 -o 02.clean_fq  01.raw_fq/${sample}_1.fq.gz 01.raw_fq/${sample}_2.fq.gz
    fi

    if [ $? -eq 0 ]; then
      touch 02.clean_fq/status/ok.trim_galore.${sample}.status
    else
      echo "trim_galore failed" ${sample}
    fi

    ## bwa 
    if [ ! -f  04.align/status/ok.bwa.${sample}.status ]; then
       
      bwa mem -M -t 16 -R "@RG\tID:${sample}\tSM:${sample}\tLB:WGS\tPL:Illumina"  ${index}  \
      02.clean_fq/${sample}_1_val_1.fq.gz  02.clean_fq/${sample}_2_val_2.fq.gz |  \
      $samblaster -M -e -r -d 04.align/${sample}.disc.sam -s 04.align/${sample}.split.sam -u  04.align/${sample}.umc.fasta |  \
      samtools view -Sb - > 04.align/${sample}.rmdup.bam 

      samtools sort -@ 16 -o 04.align/${sample}.rmdup.sorted.bam 04.align/${sample}.rmdup.bam 

      samtools index -@ 16 04.align/${sample}.bam

    fi 
     
    if [ $? -eq 0 ]; then
      touch 04.align/status/ok.bwa.${sample}.status
    else
      echo "bwa failed" ${sample}
    fi

    ## gatk
    if [ ! -f  05.gatk/01.bqsr/status/ok.gatk.bqsr.${sample}.status ]; then

      ${gatk} --java-options "-Xmx30G -Djava.io.tmpdir=05.gatk" BaseRecalibrator \
      -R ${ref} \
      -I 04.align/${sample}.bam  \
      -O 05.gatk/01.bqsr/${sample}.recal_data.table  \
      --known-sites ${dbsnp}  \
      --known-sites ${dbsnp1000G}  \
      --known-sites ${dbindel1000G}

      ${gatk} --java-options "-Xmx30G -Djava.io.tmpdir=05.gatk" ApplyBQSR \
      -R ${ref} \
      -I 04.align/${sample}.bam \
      --bqsr-recal-file 05.gatk/01.bqsr/${sample}.recal_data.table \
      -O 05.gatk/01.bqsr/${sample}.bqsr.bam
    fi

    if [ $? -eq 0 ]; then
      touch  05.gatk/01.bqsr/status/ok.gatk.bqsr.${sample}.status
    else
      echo "gatk bqsr failed" ${sample}
    fi


  fi 

i=$((i+1))

done 