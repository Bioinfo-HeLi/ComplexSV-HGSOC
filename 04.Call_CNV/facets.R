library(facets)

mysample = commandArgs(T)
mycsv = paste(mysample,"_facets.csv.gz",sep="")
out_cncf = paste(mysample,"_cncf.txt",sep="")
out_pupl = paste(mysample,"_PurityPloidy.txt",sep="")
out_pdf = paste(mysample,"_cns.pdf",sep="")
out_rdata = paste(mysample,"_cns.RData",sep="")

set.seed(12345)
rcmat = readSnpMatrix(mycsv)
# rcmat = rcmat[rcmat$Chromosome!="MT" & rcmat$Chromosome!="Y", ]
rcmat$Chromosome = factor(rcmat$Chromosome,levels=c(1:22,"X"))
head(rcmat)
xx = preProcSample(rcmat,ndepth=20,cval=500,snp.nbhd=500)
oo = procSample(xx,cval=500)
fit=emcncf(oo)

pupl = data.frame(purity=fit$purity,ploidy=fit$ploidy)
cncf = fit$cncf[,c(1,10,11,2,3,4,5,6,7,8,9,12,13,14)]
write.table(cncf,file=out_cncf,quote=F,sep="\t",row.names = F,col.names = T)
write.table(pupl,file=out_pupl,quote=F,sep="\t",row.names = F,col.names = T)

pdf(file=out_pdf,width=20/2.54,height=12/2.54)
plotSample(x=oo,emfit=fit)
dev.off()

# save.image(out_rdata)
