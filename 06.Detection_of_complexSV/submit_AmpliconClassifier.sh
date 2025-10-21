#!/bin/bash

cd /share/home/sunLab/lihe/ecDNA/ovarian_cancer
currentdir=`pwd`

cat /share/home/sunLab/lihe/ecDNA/ovarian_cancer/scripts/config |cut -f 1 |while read id
do

cd ${currentdir}/07.AA

mkdir -p ${id}/${id}_amplicon_classification

ls ${currentdir}/07.AA/${id}/*_cycles.txt | grep -v "annotated_cycles" | sort > scf.txt
ls ${currentdir}/07.AA/${id}/*_graph.txt | sort > sgf.txt
if [ "$(wc -l < scf.txt)" -ne "$(wc -l < sgf.txt)" ]; then
  echo "ERROR: Unequal numbers of cycles and graph files found!"
  exit 
fi
cat scf.txt | cut -d'/' -f 9-10 | sed 's/\///g' | cut -d"_" -f 1-2 > san.txt
paste san.txt scf.txt sgf.txt > ${id}/${id}_amplicon_classification/${id}.input
rm san.txt  scf.txt  sgf.txt

cd ${id}/${id}_amplicon_classification/

python  $AC_SRC/amplicon_classifier.py  \
--ref GRCh37  \
--report_complexity \
--plotstyle individual  \
--input ${id}.input


python $AC_SRC/make_results_table.py \
-i ${id}.input \
--classification_file ${id}_amplicon_classification_profiles.tsv


cd ${currentdir}/07.AA

done
