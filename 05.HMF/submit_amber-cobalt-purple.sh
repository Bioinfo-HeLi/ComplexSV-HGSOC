#!/bin/bash

#SBATCH -J purple
#SBATCH -N 1
#SBATCH -n 4
#SBATCH -p cpu_192
#SBATCH -o /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/purple.log
#SBATCH -e /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/purple.err

cd /share/home/sunLab/lihe/ecDNA/ovarian_cancer

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

if [ ! -d "$currentdir/06.CNV/04.amber/status" ]
then
mkdir -p "$currentdir/06.CNV/04.amber/status"
fi

if [ ! -d "$currentdir/06.CNV/05.cobalt/status" ]
then
mkdir -p "$currentdir/06.CNV/05.cobalt/status"
fi

if [ ! -d "$currentdir/06.CNV/06.purple/status" ]
then
mkdir -p "$currentdir/06.CNV/06.purple/status"
fi


cat $config_file |while read id 
do
  arr=($id)
  normal=${arr[1]}
  tumor=${arr[0]}

  if((i%$number1==$number2))
  then

    # 01. run AMBER (BAF)
    if [ ! -f  06.CNV/04.amber/status/ok.amber.${tumor}.status ]; then

      mkdir -p 06.CNV/04.amber/${tumor}

      java -Xmx32G -Djava.io.tmpdir=${JVM_TMP_DIR} -cp $AMBER_JAR com.hartwig.hmftools.amber.AmberApplication \
        -reference ${normal} -reference_bam 04.align/${normal}.bam \
        -tumor ${tumor} -tumor_bam 04.align/${tumor}.bam \
        -output_dir 06.CNV/04.amber/${tumor} \
        -threads 4 \
        -loci ${GERMLINE_HET_PON} \
        -ref_genome_version 37
      
    fi
    
    if [ $? -eq 0 ]; then
      touch  06.CNV/04.amber/status/ok.amber.${tumor}.status 
    else
      echo "amber failed" ${tumor}
    fi


    # 02. run COBALT (Read Counts)
    if [ ! -f  06.CNV/05.cobalt/status/ok.cobalt.${tumor}.status ]; then

      mkdir -p 06.CNV/05.cobalt/${tumor}

      java -Xmx32G -Djava.io.tmpdir=${JVM_TMP_DIR} -cp $COBALT_JAR com.hartwig.hmftools.cobalt.CobaltApplication \
        -reference ${normal} -reference_bam 04.align/${normal}.bam \
        -tumor ${tumor} -tumor_bam 04.align/${tumor}.bam \
        -output_dir 06.CNV/05.cobalt/${tumor} \
        -threads 4 \
        -gc_profile ${GC_PROFILE}
      
    fi
    
    if [ $? -eq 0 ]; then
      touch  06.CNV/05.cobalt/status/ok.cobalt.${tumor}.status 
    else
      echo "cobalt failed" ${tumor}
    fi


    # 03. run PURPLE (CNV/Purity/Ploidy)
    if [ ! -f  06.CNV/06.purple/status/ok.purple.${tumor}.status ]; then

      mkdir -p 06.CNV/06.purple/${tumor}

      java -Xmx32G -Djava.io.tmpdir=${JVM_TMP_DIR} -jar $PURPLE_JAR \
        -reference ${normal} \
        -tumor ${tumor} \
        -amber 06.CNV/04.amber/${tumor} \
        -cobalt 06.CNV/05.cobalt/${tumor} \
        -gc_profile ${GC_PROFILE} \
        -ref_genome_version 37 \
        -ref_genome ${ref} \
        -ensembl_data_dir ${HMF_ENSEMBLE} \
        -output_dir 06.CNV/06.purple/${tumor} \
        -threads 4
      
    fi
    
    if [ $? -eq 0 ]; then
      touch  06.CNV/06.purple/status/ok.purple.${tumor}.status 
    else
      echo "purple failed" ${tumor}
    fi


  fi 

  i=$((i+1))

done