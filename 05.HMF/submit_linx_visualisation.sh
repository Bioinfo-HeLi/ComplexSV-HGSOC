#!/bin/bash

#SBATCH -J linx_visualisation
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -p cpu_384
#SBATCH -o /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/linx_visualisation.log
#SBATCH -e /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/linx_visualisation.err

cd /share/home/sunLab/lihe/ecDNA/ovarian_cancer

conda activate wgs

config_file=$1
number1=$2
number2=$3
currentdir=`pwd`

ref=/share/home/sunLab/lihe/ecDNA/data_repo/GRCh37/human_g1k_v37.fasta
AMBER_JAR=/share/home/sunLab/lihe/HMFTools-Resources/hmf_dna_pipeline_tools_v5.33/jars/amber.jar
COBALT_JAR=/share/home/sunLab/lihe/HMFTools-Resources/hmf_dna_pipeline_tools_v5.33/jars/cobalt.jar
PURPLE_JAR=/share/home/sunLab/lihe/HMFTools-Resources/hmf_dna_pipeline_tools_v5.33/jars/purple.jar
GERMLINE_HET_PON=/share/home/sunLab/lihe/HMFTools-Resources/hmf_dna_pipeline_resources.37_v5.33/copy_number/GermlineHetPon.37.vcf.gz
GC_PROFILE=/share/home/sunLab/lihe/HMFTools-Resources/hmf_dna_pipeline_resources.37_v5.33/copy_number/GC_profile.1000bp.37.cnp
HMF_ENSEMBLE=/share/home/sunLab/lihe/HMFTools-Resources/hmf_dna_pipeline_resources.37_v5.33/common/ensembl_data
JVM_TMP_DIR=/share/home/sunLab/lihe/ecDNA/ovarian_cancer/JVM_TMP_DIR
LINX_JAR=/share/home/sunLab/lihe/HMFTools-Resources/hmf_dna_pipeline_tools_v5.33/jars/linx.jar
CIRCOS=/share/home/sunLab/lihe/.conda/envs/wgs/bin/circos

SOMATIC_HOTSPOTS=/share/home/sunLab/lihe/HMFTools-Resources/hmf_dna_pipeline_resources.37_v5.33/variants/KnownHotspots.somatic.37.vcf.gz
DRIVER_GENE_PANEL=/share/home/sunLab/lihe/HMFTools-Resources/hmf_dna_pipeline_resources.37_v5.33/common/DriverGenePanel.37.tsv 
FRAGILE_SITES=/share/home/sunLab/lihe/HMFTools-Resources/hmf_dna_pipeline_resources.37_v5.33/sv/fragile_sites.37.csv 
LINE_ELEMENTS=/share/home/sunLab/lihe/HMFTools-Resources/hmf_dna_pipeline_resources.37_v5.33/sv/line_elements.37.csv
HMF_FUSION=/share/home/sunLab/lihe/HMFTools-Resources/hmf_dna_pipeline_resources.37_v5.33/sv/known_fusion_data.37.csv


if [ ! -d "$currentdir/33.purple_linx_v2/01.purple/status" ]
then
mkdir -p "$currentdir/33.purple_linx_v2/01.purple/status"
fi

if [ ! -d "$currentdir/33.purple_linx_v2/02.linx/status" ]
then
mkdir -p "$currentdir/33.purple_linx_v2/02.linx/status"
fi

cat $config_file |while read id 
do
  arr=($id)
  normal=${arr[1]}
  tumor=${arr[0]}

  if((i%$number1==$number2))
  then

    if [ ! -f  33.purple_linx_v2/02.linx/status/ok.purple.${tumor}.status ]; then

      mkdir -p 33.purple_linx_v2/02.linx/${tumor}
      mkdir -p 33.purple_linx_v2/02.linx/${tumor}/plot
      mkdir -p 33.purple_linx_v2/02.linx/${tumor}/data

      java -Xmx32G -Djava.io.tmpdir=${JVM_TMP_DIR} -cp $LINX_JAR com.hartwig.hmftools.linx.visualiser.SvVisualiser \
        -sample ${tumor} \
        -ensembl_data_dir $HMF_ENSEMBLE \
        -threads 1 \
        -vis_file_dir 33.purple_linx_v2/02.linx/${tumor} \
        -plot_out 33.purple_linx_v2/02.linx/${tumor}/plot \
        -data_out 33.purple_linx_v2/02.linx/${tumor}/data \
        -ref_genome_version 37 \
        -circos $CIRCOS 
      
    fi
    
    if [ $? -eq 0 ]; then
      touch  33.purple_linx_v2/02.linx/status/ok.purple.${tumor}.status 
    else
      echo "purple failed" ${tumor}
    fi



  fi 

  i=$((i+1))

done