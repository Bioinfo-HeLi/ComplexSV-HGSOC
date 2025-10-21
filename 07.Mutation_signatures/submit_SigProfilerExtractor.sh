#!/bin/bash

#SBATCH -J SBS96
#SBATCH -N 1
#SBATCH -n 24

python /share/home/sunLab/lihe/ecDNA/Functions/Signatures-Manuscript/SigProfiler/extractor_v18_vt22042020-noplots.py \
--input_catalogue /share/home/sunLab/lihe/ecDNA/ovarian_cancer/18.signatures/01.SigProfiler/SBS/01.SigProfilerMatrixGenerator/output/SBS/output.SBS96.all \
--output /share/home/sunLab/lihe/ecDNA/ovarian_cancer/18.signatures/01.SigProfiler/SBS/02.SigProfilerExtractor/SBS96 \
--min_sig 5 \
--max_sig 15  \
--max_iter 500 \
--cat_channel 96
