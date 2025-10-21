#!/bin/bash

#SBATCH -J annovar
#SBATCH -N 1
#SBATCH -n 4
#SBATCH -o /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/annovar.log
#SBATCH -e /share/home/sunLab/lihe/ecDNA/ovarian_cancer/logs/annovar.err

cd /share/home/sunLab/lihe/ecDNA/ovarian_cancer

config_file=$1
number1=$2
number2=$3
currentdir=`pwd`


if [ ! -d "10.somatic_mutations/merge/status" ]
then
mkdir -p "10.somatic_mutations/merge/status"
fi


cat $config_file |while read id 
do
  arr=($id)
  normal=${arr[1]}
  tumor=${arr[0]}

  if((i%$number1==$number2))
  then

    if [ ! -f  10.somatic_mutations/merge/status/ok.annovar.${tumor}.status  ]; then

        /share/home/sunLab/lihe/biosoft/annovar/table_annovar.pl  \
        /share/home/sunLab/lihe/ecDNA/ovarian_cancer/10.somatic_mutations/merge/${tumor}/${tumor}.input  \
        /share/home/sunLab/lihe/biosoft/annovar/humandb  \
        --buildver hg19 --otherinfo --thread 4 --remove --operation g,f,f,f,f,f,f,f,f,f   \
        --protocol refGene,exac03,gnomad_genome,esp6500siv2_all,1000g2015aug_all,avsnp150,cosmic97_coding,cosmic97_noncoding,clinvar_20220320,ljb26_all   \
        --outfile  /share/home/sunLab/lihe/ecDNA/ovarian_cancer/10.somatic_mutations/merge/${tumor}/${tumor}.annovar

        perl /share/home/sunLab/lihe/ecDNA/Functions/Filter_Somatic.pl 10.somatic_mutations/merge/${tumor}/${tumor}

    fi

    if [ $? -eq 0 ]; then
      touch  10.somatic_mutations/merge/status/ok.annovar.${tumor}.status 
    else
      echo "annovar failed" ${tumor}
    fi
  fi 

  i=$((i+1))

done
