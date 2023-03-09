# .tar.gz格式  解压 
```shell
tar -xzvf REDItools-1.0.3.tar.gz -C /指定目录
```

# gzip -d \[file\] —— 解压缩
```shell
gunzip -c correct.correctedReads.fasta.gz > correct.correctedReads.fasta #保留源文件
gunzip correct.correctedReads.fasta.gz #不保留源文件

# 压缩命令 gzip [file]
# 解压文件 gunzip [file]/gzip -d [file]

# 压缩保留源文件 gzip –c filename > filename.gz
# 解压保留源文件 gunzip –c filename.gz > filename
```

# zcat 不真正解压缩文件
```shell
zcat *.fq.gz # 等同 gunzip –c *.fq.gz > filename
```

# 批量解压
```shell
for i in *.gz;do gunzip -c $i > ${i%.gz} ;done
```
