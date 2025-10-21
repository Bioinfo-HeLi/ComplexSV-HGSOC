#!/bin/bash

#SBATCH -J gridss_pon
#SBATCH -N 1
#SBATCH -n 24
#SBATCH -o /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/gridss_pon.log
#SBATCH -e /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/gridss_pon.err

cd /share/home/sunLab/lihe/ecDNA/ovarian_cancer

GRIDSS_JAR=/share/apps/softwares/gridss-2.13.2/gridss-2.13.2-gridss-jar-with-dependencies.jar 
GRIDSS_PON=/share/home/sunLab/lihe/ecDNA/ovarian_cancer/08.SV/05.gridss/GRIDSS_PON
GRIDSS_OUTPUT=/share/home/sunLab/lihe/ecDNA/ovarian_cancer/08.SV/05.gridss/results
REFERENCE=/share/home/sunLab/lihe/ecDNA/data_repo/GRCh37/human_g1k_v37.fasta
java -Xmx8g -cp $GRIDSS_JAR gridss.GeneratePonBedpe \
  $(ls -1 $GRIDSS_OUTPUT/*.gridss.raw.vcf | awk ' { print "INPUT=" $0 }') \
  O=$GRIDSS_PON/gridss_pon_breakpoint.raw.bedpe \
  SBO=$GRIDSS_PON/gridss_pon_single_breakend.raw.bed \
  THREADS=24 \
  NORMAL_ORDINAL=0 \
  REFERENCE_SEQUENCE=$REFERENCE
 
cat $GRIDSS_PON/gridss_pon_single_breakend.raw.bed | awk '$5>=3' > $GRIDSS_PON/gridss_pon_single_breakend.bed
cat $GRIDSS_PON/gridss_pon_breakpoint.raw.bedpe | awk '$8>=3' > $GRIDSS_PON/gridss_pon_breakpoint.bedpe
rm $GRIDSS_PON/*raw*
