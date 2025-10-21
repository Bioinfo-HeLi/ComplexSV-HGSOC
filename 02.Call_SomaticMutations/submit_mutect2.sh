#!/bin/bash

#SBATCH -J mutect2
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -p cpu_384
#SBATCH -o /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/mutect2.log
#SBATCH -e /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/mutect2.err

cd /share/home/sunLab/lihe/ecDNA/ovarian_cancer

config_file=$1
number1=$2
number2=$3
currentdir=`pwd`

ref=/share/home/sunLab/lihe/ecDNA/data_repo/GRCh37/human_g1k_v37.fasta
gatk=/share/apps/softwares/gatk-4.2.5.0/gatk
Germline_Resource=/share/home/sunLab/lihe/broad_reference/hg19/af-only-gnomad.raw.sites.vcf

if [ ! -d "10.somatic_mutations/02.mutect2/status" ]
then
mkdir -p "10.somatic_mutations/02.mutect2/status"
fi

cat $config_file |while read id 
do
  arr=($id)
  normal=${arr[1]}
  tumor=${arr[0]}

  if((i%$number1==$number2))
  then

    if [ ! -f  10.somatic_mutations/02.mutect2/status/ok.mutect2.${tumor}.status ]; then

        ${gatk} --java-options "-Xmx40G -Djava.io.tmpdir=./10.somatic_mutations/" GetSampleName  \
            -I 05.gatk/01.bqsr/${normal}.bqsr.bam  \
            -O 10.somatic_mutations/02.mutect2/normal/${normal}.SM.txt
        readarray -t SM<10.somatic_mutations/02.mutect2/normal/${normal}.SM.txt
        ctl_SM=${SM[0]}

        ${gatk} --java-options "-Xmx40G -Djava.io.tmpdir=./10.somatic_mutations/" Mutect2  \
            -R ${ref}  \
            -L 1 -L 2 -L 3 -L 4 -L 5 -L 6 -L 7 -L 8 -L 9 -L 10 -L 11  \
            -L 12 -L 13 -L 14 -L 15 -L 16 -L 17 -L 18 -L 19 -L 20 -L 21 -L 21 -L 22 -L X  \
            -I 05.gatk/01.bqsr/${normal}.bqsr.bam  \
            -I 05.gatk/01.bqsr/${tumor}.bqsr.bam  \
            -normal $ctl_SM  \
            --germline-resource ${Germline_Resource} \
            --af-of-alleles-not-in-resource 0.001  \
            --disable-read-filter MateOnSameContigOrNoMappedMateReadFilter  \
            --panel-of-normals 10.somatic_mutations/02.mutect2/PON/PoN.vcf.gz  \
            --f1r2-tar-gz 10.somatic_mutations/02.mutect2/${tumor}/${tumor}.f1r2.tar.gz  \
            -O 10.somatic_mutations/02.mutect2/${tumor}/${tumor}.somatic_m2.vcf.gz  \
            -bamout 10.somatic_mutations/02.mutect2/${tumor}/${tumor}.m2.bam

        ${gatk} --java-options "-Xmx40G -Djava.io.tmpdir=./10.somatic_mutations/" LearnReadOrientationModel  \
            -I 10.somatic_mutations/02.mutect2/${tumor}/${tumor}.f1r2.tar.gz  \
            -O 10.somatic_mutations/02.mutect2/${tumor}/${tumor}.read-orientation-model.tar.gz

        ${gatk}  --java-options "-Xmx40G -Djava.io.tmpdir=./10.somatic_mutations/" FilterMutectCalls  \
            -V 10.somatic_mutations/02.mutect2/${tumor}/${tumor}.somatic_m2.vcf.gz  \
            -R ${ref}  \
            --ob-priors 10.somatic_mutations/02.mutect2/${tumor}/${tumor}.read-orientation-model.tar.gz  \
            -O 10.somatic_mutations/02.mutect2/${tumor}/${tumor}.somatic_m2_filtered.vcf.gz

        # c) Split multi-allelic sites
        ${gatk} --java-options "-Xmx40G -Djava.io.tmpdir=./10.somatic_mutations/" LeftAlignAndTrimVariants  \
            -O 10.somatic_mutations/02.mutect2/${tumor}/${tumor}.somatic_m2_filtered_SplitMulti.vcf  \
            -R ${ref}  \
            -V 10.somatic_mutations/02.mutect2/${tumor}/${tumor}.somatic_m2_filtered.vcf.gz  \
            -no-trim true --split-multi-allelics true

    fi

    if [ $? -eq 0 ]; then
      touch  10.somatic_mutations/02.mutect2/status/ok.mutect2.${tumor}.status 
    else
      echo "mutect2 failed" ${tumor}
    fi
  
  fi 

  i=$((i+1))

done