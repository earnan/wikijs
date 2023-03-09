> 参数：
> -# 显示进度
> --compressed   要求服务器提供压缩版本
> --limit-rate 7000K  限速
> -C  -  断点续传，通常附带参数 -
> -O  以url中的文件名命名

```shell
$ curl -C - -O https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/022/788/535/GCA_022788535.1_Oat_OT3098_v2/GCA_022788535.1_Oat_OT3098_v2_genomic.gbff.gz --compressed -# --limit-rate 7000K
```


