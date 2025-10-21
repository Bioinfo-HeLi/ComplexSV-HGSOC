rm(list=ls())
library(dryclean)
library(GenomicRanges)

cov = paste0("/share/home/sunLab/lihe/ecDNA/ovarian_cancer/09.CGR/01.fragCounter/tumor/",paste0(list.files("/share/home/sunLab/lihe/ecDNA/ovarian_cancer/09.CGR/01.fragCounter/tumor"),"/cov.rds"))

for (i in cov) {
  name = gsub("/cov.rds","",gsub("/share/home/sunLab/lihe/ecDNA/ovarian_cancer/09.CGR/01.fragCounter/tumor","",i))
  name
  cov_input = readRDS(i)
  cov_out = start_wash_cycle(cov = cov_input, 
                             detergent.pon.path = "/share/home/sunLab/lihe/ecDNA/ovarian_cancer/09.CGR/01.fragCounter/PON/detergent.rds", 
                             whole_genome = TRUE, chr = NA)
  cov_tmp = sortSeqlevels(cov_out)
  saveRDS(cov_tmp,paste0(paste0("/share/home/sunLab/lihe/ecDNA/ovarian_cancer/09.CGR/02.dryclean/",name),"/drycleaned.cov.rds"))
}
