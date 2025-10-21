#!/bin/bash

#SBATCH -J facets
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -p cpu_384
#SBATCH -o /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/facets.log
#SBATCH -e /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/facets.err
#SBATCH -D /share/home/sunLab/lihe/ecDNA/ovarian_cancer

ref=/share/home/sunLab/lihe/ecDNA/data_repo/only_chr1-22-X_GRCh37/human_g1k_v37.fasta
dbsnp=/share/home/sunLab/lihe/broad_reference/hg19/00-common_all.vcf.gz

snp-pileup \
-g -q15 -Q20 -P100 -r15,0 ${dbsnp} \
06.CNV/02.facets/${tumor}/${tumor}_facets.csv.gz \
04.align/${normal}.bam 04.align/${tumor}.bam 

Rscript /share/home/sunLab/lihe/ecDNA/Functions/facets.R ${tumor}
