#!/bin/bash

#SBATCH -J PoN_db
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -o /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/mutect2.log
#SBATCH -e /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/mutect2.err


cd /share/home/sunLab/lihe/ecDNA/ovarian_cancer

ref=/share/home/sunLab/lihe/ecDNA/data_repo/GRCh37/human_g1k_v37.fasta
gatk=/share/apps/softwares/gatk-4.2.5.0/gatk
Germline_Resource=/share/home/sunLab/lihe/broad_reference/hg19/af-only-gnomad.raw.sites.vcf

# a) Merge all germline vcfs into a database 
${gatk} --java-options "-Xmx30G -Djava.io.tmpdir=./10.somatic_mutations/" GenomicsDBImport  \
    -R ${ref} \
    -L 1 -L 2 -L 3 -L 4 -L 5 -L 6 -L 7 -L 8 -L 9 -L 10 -L 11  \
    -L 12 -L 13 -L 14 -L 15 -L 16 -L 17 -L 18 -L 19 -L 20 -L 21 -L 21 -L 22 -L X  \
    --genomicsdb-workspace-path 10.somatic_mutations/02.mutect2/PON/PoN_db  \
    --sample-name-map 10.somatic_mutations/02.mutect2/PON/cohort_ctl_map.txt  \
    --reader-threads 20

# b) Create PON
${gatk} --java-options "-Xmx30G -Djava.io.tmpdir=./10.somatic_mutations/" CreateSomaticPanelOfNormals  \
    -R ${ref}  \
    --germline-resource ${Germline_Resource}  \
    -V gendb://10.somatic_mutations/02.mutect2/PON/PoN_db  \
    -O 10.somatic_mutations/02.mutect2/PON/PoN.vcf.gz
