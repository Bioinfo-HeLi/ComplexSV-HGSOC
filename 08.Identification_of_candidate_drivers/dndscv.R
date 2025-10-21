rm(list=ls())
library(tidyverse)
library(dndscv)
library(maftools)

ov_maf = read.maf("OV_somatic_mutations.maf")
mut_df = ov_maf@data %>% select("Tumor_Sample_Barcode","Chromosome","Start_Position",
                         "Reference_Allele","Tumor_Seq_Allele2")
colnames(mut_df) = c("sampleID", "chr","pos", "ref", "mut")
dndsout = dndscv(mut_df)

sel_cv = dndsout$sel_cv
print(head(sel_cv))

signif_genes_dndscv_p.05 = sel_cv[sel_cv$qglobal_cv < 0.05, c("gene_name")]
rownames(signif_genes_dndscv_p.05) = NULL
print(signif_genes_dndscv_p.05)

write.table(signif_genes_dndscv_p.05,"ovarian_dndscv_sigGenes.txt",col.names = F,row.names = F,quote = F)
write.table(sel_cv,"ovarian_dndscv_allGenes.txt",col.names = F,row.names = F,quote = F)

