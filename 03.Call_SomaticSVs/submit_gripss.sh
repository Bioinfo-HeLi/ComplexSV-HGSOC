#!/bin/bash

#SBATCH -J gripss
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --mem=20G
#SBATCH -o /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/gripss.log
#SBATCH -e /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/gripss.err

cd /share/home/sunLab/lihe/ecDNA/ovarian_cancer

config_file=$1
number1=$2
number2=$3
currentdir=`pwd`

GRIDSS_JAR=/share/apps/softwares/gridss-2.13.2/gridss-2.13.2-gridss-jar-with-dependencies.jar
GRIPSS_JAR=/share/home/sunLab/lihe/biosoft/gridss/scripts/gripss_v2.3.5.jar
GRIDSS_PON=/share/home/sunLab/lihe/ecDNA/ovarian_cancer/08.SV/05.gridss/GRIDSS_PON
GRIDSS_OUTPUT=/share/home/sunLab/lihe/ecDNA/ovarian_cancer/08.SV/05.gridss/results
REFERENCE=/share/home/sunLab/lihe/ecDNA/data_repo/GRCh37/human_g1k_v37.fasta
GRIPSS=/share/home/sunLab/lihe/ecDNA/ovarian_cancer/08.SV/05.gridss/gripss

if [ ! -d "$currentdir/08.SV/05.gridss/gripss/status" ]
then
mkdir -p "$currentdir/08.SV/05.gridss/gripss/status"
fi


cat $config_file |while read id 
do
  arr=($id)
  normal=${arr[1]}
  tumor=${arr[0]}

  if((i%$number1==$number2))
  then

    if [ ! -f  08.SV/05.gridss/gripss/status/ok.gripss.${tumor}.status ]; then

      java -jar  $GRIPSS_JAR \
         -sample ${tumor} \
         -reference ${normal} \
         -ref_genome $REFERENCE \
         -pon_sgl_file $GRIDSS_PON/gridss_pon_single_breakend.bed \
         -pon_sv_file $GRIDSS_PON/gridss_pon_breakpoint.bedpe \
         -vcf /share/home/sunLab/lihe/ecDNA/ovarian_cancer/08.SV/05.gridss/results/${tumor}.gridss.raw.vcf \
         -output_dir $GRIPSS

      gunzip /share/home/sunLab/lihe/ecDNA/ovarian_cancer/08.SV/05.gridss/gripss/${tumor}.gripss.filtered.vcf.gz

      cat $GRIPSS/${tumor}.gripss.filtered.vcf | grep -v "PON" > $GRIPSS/${tumor}.gripss.filtered.pass.vcf
      
      Rscript /share/home/sunLab/lihe/biosoft/gridss/scripts/simple-event-annotation.R \
      $GRIPSS/${tumor}.gripss.filtered.pass.vcf \
      /share/home/sunLab/lihe/ecDNA/ovarian_cancer/08.SV/05.gridss/gripss/bedpe_with_simple_annotation/ \
      hg19
  
   
    fi
    
    if [ $? -eq 0 ]; then
      touch  08.SV/05.gridss/gripss/status/ok.gripss.${tumor}.status 
    else
      echo "gridss failed" ${tumor}
    fi
  fi 

  i=$((i+1))

done