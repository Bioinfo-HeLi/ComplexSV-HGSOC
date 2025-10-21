#!/bin/bash

#SBATCH -J delly
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -p cpu_384
#SBATCH -o /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/delly.log
#SBATCH -e /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/delly.err

cd /share/home/sunLab/lihe/ecDNA/ovarian_cancer

config_file=$1
number1=$2
number2=$3
currentdir=`pwd`

ref=/share/home/sunLab/lihe/ecDNA/data_repo/GRCh37/human_g1k_v37.fasta
delly=/share/apps/softwares/delly-1.1.6/delly
delly_somatic_config=/share/home/sunLab/lihe/ecDNA/ovarian_cancer/scripts/delly_somatic_config

if [ ! -d "$currentdir/08.SV/01.delly/status" ]
then
mkdir -p "$currentdir/08.SV/01.delly/status"
fi

cat $config_file |while read id 
do
  arr=($id)
  normal=${arr[1]}
  tumor=${arr[0]}

  if((i%$number1==$number2))
  then

    if [ ! -f  08.SV/01.delly/status/ok.delly.$tumor.status ]; then

      mkdir -p 08.SV/01.delly/${tumor}

      ${delly} call -q 20 -g ${ref} -o 08.SV/01.delly/${tumor}/${tumor}_pre.bcf 04.align/${tumor}.bam 04.align/${normal}.bam
      ${delly} filter -f somatic -o 08.SV/01.delly/${tumor}/${tumor}_sv.bcf -s ${delly_somatic_config} 08.SV/01.delly/${tumor}/${tumor}_pre.bcf
      bcftools view -f PASS 08.SV/01.delly/${tumor}/${tumor}_sv.bcf > 08.SV/01.delly/${tumor}/${tumor}_sv.vcf
    
    fi

    if [ $? -eq 0 ]; then
      touch  08.SV/01.delly/status/ok.delly.$tumor.status 
    else
      echo "delly failed" ${tumor}
    fi
  
  fi 

  i=$((i+1))

done
