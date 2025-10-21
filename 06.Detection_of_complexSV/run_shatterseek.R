rm(list=ls())

library(gridExtra)
library(cowplot)
library(tidyverse)
library(ggplot2)
library(gplots)
library(scales)
library(data.table)
library(ShatterSeek)

setwd("~/ecDNA/09.CGR/04.ShatterSeek")

results = NULL

###  Run shatterseek 
sv_df = read.table("input/ShatterSeek_SV_input.bed", header = T, sep = '\t')
cnv_df = read.table("input/ShatterSeek_CNV_input.bed", header = T, sep = '\t')


chromoth_list <- list()
all_samples <- as.character(cnv_df$sample) %>% unique()

for (sample_name in all_samples) {
  # subset sample
  # sample_name = all_samples[2]
  sample_SV <- sv_df %>% filter(sample == sample_name)
  sample_CN <- cnv_df %>% filter(sample == sample_name)
  
  # load SV data into SV object
  SV_data <- SVs(chrom1=as.character(sample_SV$chrom1),
                 pos1=as.numeric(sample_SV$start1),
                 chrom2=as.character(sample_SV$chrom2),
                 pos2=as.numeric(sample_SV$end2),
                 strand1=as.character(sample_SV$strand1),
                 strand2=as.character(sample_SV$strand2),
                 SVtype=as.character(sample_SV$svtype))
  
  # load CNV data into CSVsegs object
  CN_data <- CNVsegs(chrom=as.character(sample_CN$chrom),
                     start=sample_CN$start,
                     end=sample_CN$end,
                     total_cn=sample_CN$cn)
  
  # find chromothripsis
  chromothripsis <- shatterseek(SV.sample=SV_data, seg.sample=CN_data)
  results <- rbind(results, data.frame(sampleID = sample_name, chromothripsis@chromSummary))
}

### output of all chromothripsis regions for all samples
results$inter_other_chroms[results$inter_other_chroms == ""] <- NA
results$inter_other_chroms_coords_all[results$inter_other_chroms_coords_all == " "] <- NA
results$inter_other_chroms_coords_all <- gsub("\n",";",results$inter_other_chroms_coords_all)
write.table(results, "df_chromothripsis_chromSummary.txt", row.names = FALSE,col.names = TRUE, quote = FALSE, sep = "\t") ### output of chromothripsis for all samples


### filtering to obtain high-confident chromothripsis regions
source("chromthripsis_high_conf.R")
df_chromothripsis_chromSummary <- read.table("df_chromothripsis_chromSummary.txt", header = TRUE)
results <- c()
for(sample_name in all_samples){ ### provide a set of sample ID; need MODIFY
  index <- chromthripsis_high_conf(df_chromothripsis_chromSummary, pvalue_threshold=0.05)
  results <- c()
  if(length(unique(c(index[[1]], index[[2]])))!=0){
    results <- rbind(results, data.frame(confidence = "high",
                                         df_chromothripsis_chromSummary[unique(c(index[[1]], index[[2]])),]))
  }
  if(length(unique(c(index[[3]])))!=0){
    results <- rbind(results, data.frame(confidence = "low",
                                         df_chromothripsis_chromSummary[unique(index[[3]]),]))
  }
}

### output of high-confident chromothripsis regions for all samples
write.table(results, "df_confident_chromothripsis_chromSummary.txt", row.names = FALSE,col.names = TRUE, quote = FALSE, sep = "\t") 




results <- read.table("~/ecDNA/09.CGR/04.ShatterSeek/df_confident_chromothripsis_chromSummary.txt", header = TRUE)
results <- results %>% filter(confidence == "high")
all_samples <- unique(results$sampleID)

for (sample_name in all_samples) {
  df <- results %>% filter(sampleID == sample_name) %>% select(-confidence,-sampleID)
  write.table(df, paste("~/ecDNA/09.CGR/04.ShatterSeek/outputs/",sample_name,"_shatterseek_chromothripsis.txt",sep=""), row.names = FALSE,col.names = TRUE, quote = FALSE, sep = "\t") 
  
}


