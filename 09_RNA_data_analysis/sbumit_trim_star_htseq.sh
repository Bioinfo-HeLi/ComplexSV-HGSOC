#!/bin/bash

#SBATCH -J trim_star_htseq
#SBATCH -N 1
#SBATCH -n 8
#SBATCH -o /share/home/sunLab/lihe/ecDNA/rna-seq/logs/trim_star_htseq.log
#SBATCH -e /share/home/sunLab/lihe/ecDNA/rna-seq/logs/trim_star_htseq.err
#SBATCH -D /share/home/sunLab/lihe/ecDNA/rna-seq

STAR_index=/share/home/sunLab/lihe/reference/human/GRCh37/star/star_index/
gene_annotation=/share/home/sunLab/lihe/reference/human/GRCh37/gencode.v19.annotation.gtf

trim_galore=/share/apps/softwares/TrimGalore-0.6.7/trim_galore

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

    ## trim_galore 
    if [ ! -f  02.clean_fq/status/ok.trim_galore.${sample}.status ]; then
    trim_galore -q 28 --phred33 --length 36 -e 0.1 --stringency 3 --paired --cores 8 -a AAGTCGGAGGCCAAGCGGTCTTAGGAAGACAA -a2 AAGTCGGATCGTAGCCATGTCGTTCTGTGAGCCAAGGAGTTG -o 02.clean_fq  01.raw_fq/${sample}_1.fq.gz  01.raw_fq/${sample}_2.fq.gz
    fi

    if [ $? -eq 0 ]; then
      touch 02.clean_fq/status/ok.trim_galore.${sample}.status
    else
      echo "trim_galore failed" ${sample}
    fi

    ## STAR 
    if [ ! -f  04.star/status/ok.star.${sample}.status ]; then
      STAR \
        --runThreadN 8 \
        --quantMode TranscriptomeSAM GeneCounts  \
        --outFilterType BySJout \
        --outFilterMultimapNmax 20 \
        --outSAMattrRGline ID:${sample} SM:${sample} PL:${Illumina} \
        --alignSJoverhangMin 8 \
        --alignSJDBoverhangMin 1 \
        --outFilterMismatchNmax 999 \
        --outFilterMismatchNoverLmax 0.04 \
        --alignIntronMin 20  \
        --alignMatesGapMax 1000000   \
        --twopassMode Basic \
        --genomeDir ${STAR_index}  \
        --readFilesCommand zcat \
        --outSAMtype BAM SortedByCoordinate \
        --sjdbGTFfile ${gene_annotation} \
        --outReadsUnmapped None \
        --chimSegmentMin 12 \
        --chimJunctionOverhangMin 12    \
        --alignIntronMax 100000 \
        --chimSegmentReadGapMax parameter 3  \
        --alignSJstitchMismatchNmax 5 -1 5 5  \
        --readFilesIn  02.clean_fq/${sample}_1_val_1.fq.gz  02.clean_fq/${sample}_2_val_2.fq.gz \
        --outFileNamePrefix  04.star/${sample}. \
        --chimOutType Junctions
      
    fi 
     
    if [ $? -eq 0 ]; then
      touch 04.star/status/ok.star.${sample}.status
    else
      echo "star failed" ${sample}
    fi

    ## HTSeq 
    if [ ! -f  05.htseq/status/ok.htseq.${sample}.status ]; then
      htseq-count  \
      -f bam \
      -m union \
      --stranded=no \
      --t exon \
      -i gene_id \
      -a 10 \
      -r pos \
      -n 4 \
      04.star/${sample}.Aligned.sortedByCoord.out.bam  ${gene_annotation} >  05.htseq/${sample}.htseq_counts.out   
    fi

    if [ $? -eq 0 ]; then
      touch 05.htseq/status/ok.htseq.${sample}.status
    else
      echo "htseq failed" ${sample}
    fi

  fi 

i=$((i+1))

done 
