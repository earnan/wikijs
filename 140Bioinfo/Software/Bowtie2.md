> [!info] 项目应用
> ```txt 
> 1.索引
> bowtie2-build /share/nas1/yuj/project/20221117_wuboshi_eRNA_20221123/ref_ass/allref.fa sirna_ref
> 
> 2.创建文件夹
> for i in {MYSV1,MYSV2,MYSV3};do mkdir -p SR_data/$i"_bowtie" ;done
> 
> 3.单端比对
> for i in {CK1,CK2,CK3,MYSV1,MYSV2,MYSV3};do cd /share/nas1/yuj/project/20221117_wuboshi_eRNA_20221123/SR_data/$i"_bowtie";bowtie2 -x ../../ref_ass/sirna_ref -U ../clean_data/$i".clean.fq.gz" -S $i".sam" & done
> 
> 4.sam转换为fq
> for i in {CK1,CK2,CK3,MYSV1,MYSV2,MYSV3};do cd /share/nas1/yuj/project/20221117_wuboshi_eRNA_20221123/SR_data/$i"_bowtie";samtools fastq $i".sam" > $i".fq" & done
> 
> 5.sam转换为bam
> for i in {MYSV1,MYSV2,MYSV3};do cd /share/nas1/yuj/project/20221117_wuboshi_eRNA_20221123/SR/archive/$i"_bowtie";samtools sort $i".sam" >  $i".bam" & done
> 
> # 批量解压
> for i in *.gz;do gunzip -c $i > /share/nas1/yuj/project/20221117_wuboshi_eRNA_20221123/analysis/02.cutadapter_dir/${i%.clean.fq.gz}".cutadapt.fastq" ;done
> ```

# 一、安装
## 1.1 conda安装
`conda install gatk bowtie2`
`conda install -y bowtie`2
## 1.2 下载安装
```shell
$ sudo wget https://jaist.dl.sourceforge.net/project/bowtie-bio/bowtie2/2.3.4.1/bowtie2-2.3.4.1-linux-x86_64.zip
$ unzip bowtie2-2.3.4.1-linux-x86_64.zip```text
$ sudo vim /etc/environment
# 添加软件 bin 目录的路径，并用 `:` 隔开，如下图
# 执行source命令，使配置立即生效
$ sudo source /etc/enviroment
```

# 二、使用
## 2.1 建索引
```shell
$ bowtie2-build Tsa.v1.genome.fa(参考基因组) Tas(输出文件名前缀)
```

## 2.2 比对
```shell
双端：
$ bowtie2 -x ../ref/Tsa(索引所在目录，因为在上一级，所以使用../) -1 read1_1.fq(第一端) -2 read1_2.fq(第二端) -S read1.sam(指定输出文件名) -p 8（线程）

$ bowtie2 -x ref/Tsa(索引所在目录/前缀) -1 read1_1.fq(第一端) -2 read1_2.fq(第二端) -p 8（线程）| samtools sort -O bam(输出格式) -@ 10(线程) -o - > output.bam

单端：
$ bowtie2 -x ref/Tsa(索引所在目录/前缀) -U a_0.fq(第一端) -S a_0_Tsa.sam(指定输出文件名) -p 8（线程）

$ bowtie2 -x ref/Tsa(索引所在目录/前缀) -U a_0.fq(第一端) -p 8（线程）| samtools sort -O bam -@ 10 -o - > output.bam

# SAM 文件转为 BAM 文件
samtools sort example.sam > example.bam
```

![[Pasted image 20221221140536.png]]

![[Pasted image 20221221140606.png]]