rm(list=ls())

library(fishHook)
library(gUtils)
library(roverlaps)
library(rtracklayer)
library(BSgenome.Hsapiens.1000genomes.hs37d5)
library(ggplot2)
library(plotly)
library(MASS)
library(data.table)

BINSIZE <- 10e4
frac_eligible = 0.75

genome_hg19 <- BSgenome.Hsapiens.1000genomes.hs37d5
genome_hg19_info <- seqinfo(genome_hg19)[seqlevels(genome_hg19)[1:23]]
eligible <- rtracklayer::import('covariate/hg19/um75-hs37d5.covered.bed')
gr.eligible <- eligible

## set binsize and create bins
hypotheses <- gr.tile(si2gr(gUtils::si), BINSIZE)
hypotheses = dropSeqlevels(hypotheses,"Y",pruning.mode="coarse")  


## load SV
sv_data_raw <- read.table("OV/input/final.merged.sv.txt", header=T, as.is=T, sep="\t")

sv_data$length <- sv_data$start2 - sv_data$start1
sv_data = sv_data %>% filter((svclass == "TRA") | 
                               (svclass %in% c('DUP','INV')) |
                               (svclass == "DEL"))
bp1_data <- data.frame(start=sv_data$start1,
                       end=sv_data$end1,
                       strand=rep('*', nrow(sv_data)),
                       seqnames=gsub("chr", "", sv_data$chrom1),
                       sample = sv_data$sampleID)
bp2_data <- data.frame(start=sv_data$start2,
                       end=sv_data$end2,
                       strand=rep('*', nrow(sv_data)),
                       seqnames=gsub("chr", "", sv_data$chrom2),
                       sample = sv_data$sampleID)
sv_gr <- dt2gr(rbind(bp1_data, bp2_data))
sv_gr <- sortSeqlevels(sv_gr)

sv_gr = dropSeqlevels(sv_gr, "Y", pruning.mode="coarse")
seqinfo(sv_gr) <- genome_hg19_info
sv_gr <- trim(sv_gr)


## (optional) filtering out centromeric regions
cytoband <- read.table("covariate/hg19/cytoBand_hg19.bed", sep="\t", as.is=T,
                       col.names=c("chr", "start", "end", "band", "stain"))
centromere <- subset(cytoband, stain=="acen" & chr!="chrY", select=-stain)
cen_gr <- dt2gr(data.frame(start=centromere$start, 
                           end=centromere$end,
                           strand=rep('*', nrow(centromere)),
                           seqnames=gsub("chr", "", centromere$chr)))
cen_gr <- sortSeqlevels(cen_gr)
seqinfo(cen_gr) <- genome_hg19_info
sv_gr <- sv_gr[!(sv_gr %over% cen_gr)]

## load covariates
mappability <- readRDS("covariate/hg19/wgEncodeCrgMapabilityAlign100mer.gr.rds")
rmsk_sine = with(fread("covariate/hg19/retrotransposon.sine.hg19.bed"), GRanges(V1, IRanges(V2, V3)))
rmsk_line = with(fread("covariate/hg19/retrotransposon.line.hg19.bed"), GRanges(V1, IRanges(V2, V3)))
rmsk_ltr = with(fread("covariate/hg19/retrotransposon.ltr.hg19.bed"), GRanges(V1, IRanges(V2, V3)))
rmsk_dna = with(fread("covariate/hg19/retrotransposon.dna.hg19.bed"), GRanges(V1, IRanges(V2, V3)))
rmsk_simple = with(fread("covariate/hg19/retrotransposon.simple.hg19.bed"), GRanges(V1, IRanges(V2, V3)))
nt_comp <- readRDS("covariate/hg19/nucleotide.context.rds")

oldFRAG <- fread("covariate/hg19/fragile_genes_smith.hg19fp.txt")
oldFRAG = oldFRAG[,c("chrn","start","end")]
setnames(oldFRAG, c("chrn","start","end"),c("seqnames","start","end"))
oldFRAG <- dt2gr(oldFRAG)

## make the gene density track
gr.genes = sort(gr.fix(gr.nochr(with(fread("covariate/hg19/genes.hg19.ucsc.txt", sep="\t"), GRanges(chr, IRanges(beg, end), gene=symbol))), si))

grall <- si2gr(gUtils::si)
grall <- grall[seqnames(grall) %in% c(seq(22),"X")]
gr.density <- trim(gr.fix(gr.tile(grall, w=1e6) + 1e6, si))
fo <- gr2dt(gr.findoverlaps(gr.density, gr.genes))
fo[, gene.count := nrow(.SD), by=query.id]
fo[, gene.density := gene.count / width(gr.density)[query.id], by=query.id]
gr.density$gene.density <- 0
gr.density$gene.density[fo$query.id] <- fo$gene.density
gr.density <- gr.density[width(gr.density) > 2e6]
gene_density <- gr.density - 1e6
gene_density <- gr.fix(gene_density, si)
ff <- GenomicRanges::setdiff(si2gr(si), gene_density)
ff$gene.density <- 0
gene_density$query.id <- gene_density$tile.id <- NULL
gene_density <- c(ff, gene_density)
gene_density$score <- gene_density$gene.density
gene_density$score <- gene_density$score*width(gene_density)

## create GRanges object for tissue specific covariate
cov_Mappability <- Cov(mappability, name = "Mappability", field = "score", type="numeric")
cov_rmsk_line <- Cov(rmsk_line, name="LINE", type="interval")
cov_rmsk_sine <- Cov(rmsk_sine, name="SINE", type="interval")
cov_rmsk_ltr <- Cov(rmsk_ltr, name="LTR", type="interval")
cov_rmsk_dna <- Cov(rmsk_dna, name="DNA_transposon", type="interval")
cov_rmsk_simple <- Cov(rmsk_simple, name="Simple_repeat", type="interval")
cov_nt_gc <- Cov(nt_comp, field = c('C', 'G'))
covs_intFRAG <- Cov(oldFRAG, name = "IntervalFragility", type = "interval")
covsGenedens <- Cov(gene_density, name = "gene_density", field = "score",type="numeric")

cov_list = list(cov_Mappability,cov_rmsk_line,cov_rmsk_sine,
                cov_rmsk_ltr,cov_rmsk_dna,cov_rmsk_simple,
                cov_nt_gc)

## Run basic model without covariates
fh <- Fish(hypotheses = hypotheses, events = sv_gr, eligible = gr.eligible, mc.cores=1)
fh$score()
fh$res %Q% (fdr<0.25) %Q% order(p)
fh$qqp(plotly = FALSE)

## Add covariates to FishHook model
fh$covariates <- c(cov_Mappability,cov_rmsk_line,cov_rmsk_sine,
                   cov_rmsk_ltr,cov_rmsk_dna,cov_rmsk_simple,
                   cov_nt_gc)
fh$score()
fh$res %Q% (fdr<0.25) %Q% order(p)
fh$qqp(plotly = FALSE)

reptimedata = import("covariate/hg19/wgEncodeUwRepliSeqWaveSignalMean.bigWig")
seqlevels(reptimedata) <- sub("^chr", "", seqlevels(reptimedata))
cov_rep_timing <- Cov(reptimedata, name="Replication_timing", field="score", type="numeric")
fh$merge(cov_rep_timing) 
fh$score()
fh$res %Q% (fdr<0.25) %Q% order(p)
fh$qqp(plotly = FALSE)

chromhmm = gr.sub(import('OV/input/covariate/E097_15_coreMarks_mnemonics.bed'), 'chr', '')
hetchromdata = chromhmm %Q% (name %in% c('8_ZNF/Rpts', '9_Het', '15_Quies'))
hetchrom = Cov(hetchromdata, name = 'Heterochromatin') 
fh$merge(hetchrom) 
fh$score()
fh$res %Q% (fdr<0.25) %Q% order(p)
fh$qqp(plotly = FALSE)

fh <- fh[which(fh$data$frac.eligible >= frac_eligible), ]

genes_a = gr.sub(import('covariate/hg19/gencode.v19.genes.gtf'))
sigBins.annot <- fh$res
sigBins.annot <- sigBins.annot %$% genes_a

# nearest.cgc.genes
cgc.genes <-  fread("../../../ovarian_cancer/metadata/ov_related_gene_list.txt", header = F)

nearest_indices <- nearest(sigBins.annot, gr.stripstrand(cgc.genes))
sigBins.annot$nearest.cgc.gene = cgc.genes$gene_name[nearest_indices]
distance <- distance(sigBins.annot, gr.stripstrand(cgc.genes)[nearest_indices])
sigBins.annot$distance = distance
sigBins.annot

rows_with_distance_less_than_1MB <- elementMetadata(sigBins.annot)$distance < 1000000
nearest.cgc.gene <- elementMetadata(sigBins.annot)$nearest.cgc.gene
if (length(nearest.cgc.gene) == 0) {
  elementMetadata(sigBins.annot)$nearest.cgc.gene.under.1MB.away <- elementMetadata(sigBins.annot)$nearest.cgc.gene
} else if (any(rows_with_distance_less_than_1MB)) {
  # 
  elementMetadata(sigBins.annot)$nearest.cgc.gene.under.1MB.away <- ifelse(rows_with_distance_less_than_1MB, 
                                                                           nearest.cgc.gene, "")
} else {
  elementMetadata(sigBins.annot)$nearest.cgc.gene.under.1MB.away <- ""
}

a = sigBins.annot %Q% (fdr<0.25) %Q% order(p)
mcols(a) <- mcols(a)[, -which(names(mcols(a)) %in% c('source','type','score','phase','gene_id','transcript_id','gene_type',
                                                     'gene_status','transcript_type','transcript_status','transcript_name',
                                                     'level','havana_gene','tag'))]
write.table(a, "OV/output/fdr0.25/100kbins_fdr0.25.txt", row.names = FALSE, sep = "\t")
b = sigBins.annot %Q% order(p)
mcols(b) <- mcols(b)[, -which(names(mcols(b)) %in% c("strand","query.id","tile.id","hid","p.neg","fdr.neg",'source','type','score','phase','gene_id','transcript_id','gene_type',
                                                     'gene_status','transcript_type','transcript_status','transcript_name',
                                                     'level','havana_gene','tag'))]
write.table(b, "OV/output/100kbins.txt", row.names = FALSE, sep = "\t")      


