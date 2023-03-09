# 一.叶绿体


# 二.线粒体
## 2.1 Win_Mitochondrion.R
```R 
# Chloroplot需要以下几种包才能正常运行
# 可通过以下命令安装
# install.packages("BiocManager")
# BiocManager::install("genbankr")
# BiocManager::install("coRdon")
# install.packages("circlize")

rm(list = ls())
args <- commandArgs(T) # args = commandArgs(trailingOnly = TRUE)
# 命令行参数依次为 输出文件夹路径/输入gbk文件路径/样本名
wddir <- format(args[1])
gbkfile <- format(args[2])
filename <- paste(format(args[3]), "circular", sep = ".") # 类似python字符串的join()函数
print(paste("outdir:", wddir))
print(paste("gbk:", gbkfile))
print(paste("outfile:", filename))

setwd(wddir)
library(dplyr)
source("D:/OneDrive - cancer/Bioinfo_analysis/Chloroplot/R/color_complement.R")
source("D:/OneDrive - cancer/Bioinfo_analysis/Chloroplot/R/converse_ssc.R")
source("D:/OneDrive - cancer/Bioinfo_analysis/Chloroplot/R/detect_ir.R")
source("D:/OneDrive - cancer/Bioinfo_analysis/Chloroplot/R/GC_count.R")
source("D:/OneDrive - cancer/Bioinfo_analysis/Chloroplot/R/gene_color.R")
source("D:/OneDrive - cancer/Bioinfo_analysis/Chloroplot/R/gene_info.R")
source("D:/OneDrive - cancer/Bioinfo_analysis/Chloroplot/R/parse_gb_file.R")
source("D:/OneDrive - cancer/Bioinfo_analysis/Chloroplot/R/plot_genome.R")
source("D:/OneDrive - cancer/Bioinfo_analysis/Chloroplot/R/read_gb_file.R")
source("D:/OneDrive - cancer/Bioinfo_analysis/Chloroplot/R/test_parameters.R")
tmp <- PlotTab(gbfile = gbkfile, local.file = T)
PlotMitGenome(plot.tables = tmp, file.name = filename, cu.bias = FALSE)
# 去掉密码子偏好性
# Rscript E:\OneDrive\jshy信息部\Script\chloroplast\R\Win_Mitochondrion.R F:\ F:\Ustilago_esculenta_MT10.gbk Ustilago_esculenta_MT10
```

## 2.2 Mitochondrion.R
```r
```

## 2.3 plot_genome.R 修改
### 2.3.1 sp_name 
**只有搭配上面线粒体脚本才能这么改**
![[Pasted image 20230111165644.png]]
```R
  sp_name <- strsplit(file.name, ".circular")[[1]] # 20230111
  sp_name <- gsub('[_]', ' ', sp_name) # 20230111
  #sp_name <- plot.tables$sp_name 20230111 yuj
```
## 2.3.2 graphics::text
![[Pasted image 20230111170300.png]]
```R
  if (organelle_type){
    graphics::text(0,0.10, sp_name, font=4, cex = 0.8 * text.size, col = info.color)
    graphics::text(0,0.05, "Mitochondrial Genome", font=4, cex = 0.8 * text.size, col = info.color)
```

