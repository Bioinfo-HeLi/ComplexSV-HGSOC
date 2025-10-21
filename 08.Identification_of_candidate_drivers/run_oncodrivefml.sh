#!/bin/bash

#SBATCH -J oncodrivefml
#SBATCH -N 1
#SBATCH -n 24
#SBATCH -o /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/oncodrivefml.log
#SBATCH -e /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/oncodrivefml.err
#SBATCH -D /share/home/sunLab/lihe/ecDNA/ovarian_cancer

/bin/oncodrivefml \
--input $ov.maf \
--elements $bed \
--sequencing wgs \
--configuration oncodrivefml.conf \
--output ${pp}_$ele \
--cores 24
