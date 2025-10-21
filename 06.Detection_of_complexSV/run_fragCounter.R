rm(list=ls())
library(dryclean)
library(GenomicRanges)
library(readr)


# 1.Creating Panel of Normal aka detergent

n = read.delim("/share/home/sunLab/lihe/ecDNA/ovarian_cancer/09.CGR/01.fragCounter/PON/n.txt")
a = as.data.table(n)
a
saveRDS(a,"/share/home/sunLab/lihe/ecDNA/ovarian_cancer/09.CGR/01.fragCounter/PON/normal_table.rds")


detergent = prepare_detergent(normal.table.path = "/share/home/sunLab/lihe/ecDNA/ovarian_cancer/09.CGR/01.fragCounter/PON/normal_table.rds", 
                              path.to.save = "/share/home/sunLab/lihe/ecDNA/ovarian_cancer/09.CGR/01.fragCounter/PON/", 
                              num.cores = 8, use.all = TRUE)

saveRDS(detergent,"/share/home/sunLab/lihe/ecDNA/ovarian_cancer/09.CGR/01.fragCounter/PON/detergent.rds")
