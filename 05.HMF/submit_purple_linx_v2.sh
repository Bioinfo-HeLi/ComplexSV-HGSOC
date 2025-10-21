#!/bin/bash

#SBATCH -J purple_linx_v2
#SBATCH -N 1
#SBATCH -n 4
#SBATCH -o /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/purple_linx_v2.log
#SBATCH -e /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/purple_linx_v2.err

cd /share/home/sunLab/lihe/ecDNA/ovarian_cancer

config_file=$1
number1=$2
number2=$3
currentdir=`pwd`


# export JAVA_HOME=/share/apps/softwares/jdk-21.0.2
# export JRE_HOME=${JAVA_HOME}/jre
# export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib:$CLASSPATH
# export JAVA_PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin

export JAVA_HOME=/share/apps/softwares/jdk-21.0.2
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib:$CLASSPATH
export JAVA_PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin
export PATH=${JAVA_PATH}:$PATH
export PATH=/share/home/sunLab/lihe/biosoft/java-12.0.2/bin:$PATH

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

    ### 01. run PURPLE

    if [ ! -f  33.purple_linx_v2/01.purple/status/ok.purple.${tumor}.status ]; then

      conda activate wgs

      SNPEFF_VCF_FILE=/share/home/sunLab/lihe/ecDNA/ovarian_cancer/10.somatic_mutations/03.sage/${tumor}.sage.vcf.gz
      GRIDSS_FILTERED_FILE=/share/home/sunLab/lihe/ecDNA/ovarian_cancer/08.SV/05.gridss/gripss/${tumor}.gripss.filtered.pass.vcf

      mkdir -p 33.purple_linx_v2/01.purple/${tumor}

      java -Xmx32G -Djava.io.tmpdir=${JVM_TMP_DIR} -jar $PURPLE_JAR \
        -reference ${normal} \
        -tumor ${tumor} \
        -amber 06.CNV/04.amber/${tumor} \
        -cobalt 06.CNV/05.cobalt/${tumor} \
        -gc_profile ${GC_PROFILE} \
        -ref_genome_version 37 \
        -ref_genome ${ref} \
        -ensembl_data_dir ${HMF_ENSEMBLE} \
        -output_dir 33.purple_linx_v2/01.purple/${tumor} \
        -threads 4 \
        -somatic_vcf $SNPEFF_VCF_FILE \
        -somatic_sv_vcf $GRIDSS_FILTERED_FILE \
        -somatic_hotspots $SOMATIC_HOTSPOTS \
        -driver_gene_panel $DRIVER_GENE_PANEL \
        -circos $CIRCOS 
      
    fi

    if [ $? -eq 0 ]; then
      touch  33.purple_linx_v2/01.purple/status/ok.purple.${tumor}.status 
    else
      echo "purple failed" ${tumor}
    fi


    ### 02. run LINX
    if [ ! -f  33.purple_linx_v2/02.linx/status/ok.linx.${tumor}.status ]; then

      mkdir -p 33.purple_linx_v2/02.linx/${tumor}

      java -Xmx32G -Djava.io.tmpdir=${JVM_TMP_DIR} -jar $LINX_JAR \
        -sample ${tumor} \
        -sv_vcf 33.purple_linx_v2/01.purple/${tumor}/${tumor}.purple.sv.vcf.gz \
        -purple_dir 33.purple_linx_v2/01.purple/${tumor} \
        -output_dir 33.purple_linx_v2/02.linx/${tumor} \
        -threads 4 \
        -ref_genome_version 37 \
        -driver_gene_panel $DRIVER_GENE_PANEL \
        -fragile_site_file $FRAGILE_SITES \
        -line_element_file $LINE_ELEMENTS \
        -ensembl_data_dir $HMF_ENSEMBLE \
        -known_fusion_file $HMF_FUSION \
        -log_debug \
        -write_vis_data \
        -write_all_vis_fusions

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
      touch  33.purple_linx_v2/02.linx/status/ok.linx.${tumor}.status 
    else
      echo "purple failed" ${tumor}
    fi



  fi 

  i=$((i+1))

done