#!/bin/bash

#SBATCH -J gistic2
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -p cpu_384
#SBATCH -o /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/gistic2.log
#SBATCH -e /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/gistic2.err

gistic2=/share/home/sunLab/lihe/biosoft/GISTIC_2_0_23/gistic2
refgene=/share/home/sunLab/lihe/biosoft/GISTIC_2_0_23/refgenefiles/hg19.mat

${gistic2} -b /share/home/sunLab/lihe/ecDNA/ovarian_cancer/06.CNV/02.gistic2/  \
-seg /share/home/sunLab/lihe/ecDNA/ovarian_cancer/06.CNV/02.gistic2/gistic.segments -refgene ${refgene}  \
-rx 0 -ta 0.1 -td 0.1 -cap 3  \
-conf 0.99 -genegistic 0 -twoside 1 \
-maxspace 1000 -broad 0 -savegene 1 -res 0.05 -v 10 -maxseg 80000
