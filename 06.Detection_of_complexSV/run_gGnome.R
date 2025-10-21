library(gGnome)
library(parallel)

fls <- list.files('~/ecDNA/ovarian_cancer/09.CGR/03.JABBA/');fls

# get jabba alt edges ####
lapply(fls, function(xfl) {
  #xfl = fls[1]
  
  jabbaX = gG(jabba = paste0('~/ecDNA/ovarian_cancer/09.CGR/03.JABBA/',xfl,'/jabba.rds'))
  
  ## Identify all supported SV event types
  jabbaX = events(jabbaX, verbose = T)
  
  jabbaX_edgesdt <- jabbaX$edgesdt   
  jabbaX_ALTedgesdt <- jabbaX_edgesdt[type == 'ALT']
  jabbaX_ALTedgesdt[, sampleID := xfl]
  write.table(jabbaX_ALTedgesdt, paste0(
    '~/ecDNA/ovarian_cancer/09.CGR/gGnomeALTedges_',xfl,'.txt'), quote = FALSE, sep = "\t", row.names = F)
  if (nrow(jabbaX$meta$event) >=1) {
    retruntbl <- jabbaX$meta$event[, table(type)]
    retruntbl_dt <- as.data.table(retruntbl)
    retruntbl_dt[, sampleID := xfl]
    print(retruntbl_dt)
    write.table(retruntbl_dt,paste0("~/ecDNA/ovarian_cancer/09.CGR/gGnomeEvents/",xfl,'.txt'),quote = FALSE, sep = "\t", row.names = F)
  } else {
    retruntbl_dt <- as.data.table(t(c('no_events', 0)))
    colnames(retruntbl_dt) <- c('type', 'N')
    retruntbl_dt[, sampleID := xfl]
    write.table(retruntbl_dt,paste0("~/ecDNA/ovarian_cancer/09.CGR/gGnomeEvents/",xfl,'.txt'),quote = FALSE, sep = "\t", row.names = F)
  }
})
