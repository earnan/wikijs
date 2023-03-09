---
title: 08简化测序流程1-有参ddrad
description: 
published: true
date: 2023-03-09T03:57:46.308Z
tags: 
editor: markdown
dateCreated: 2023-03-09T03:57:12.411Z
---

# 一 准备数据
```shell
1. 测序所在路径，一般有多个文件夹，每个样品一个文件夹

2. 基因组fasta文件，有时需要下载，有时客户提供，还有常见的或者我们做过的可以到 /share/nas6/pub/genome中找找

3. 基因组注释文件，gff3格式。

4. 染色体列表，txt文件，一列。存放序列名称，因为有的fasta文件中有很多序列，该文件用于定义某些图片中需要展示的序列
一般是保留染色体级别的序列，如果该基因组都是scaffold，那么就保留几个比较长的序列名称，十个左右就行。
序列名称为fasta文件中">"后面的连续非空字符。
grep ">" Gardenia_genome/Gardenia_v2.fasta > chrlist.txt
fl Gardenia_genome/Gardenia_v2.fasta | sort -k 1 -n # -n:从小到大  不加-n：从大到小
# 发现有11个染色体级别的
fl Gardenia_genome/Gardenia_v2.fasta | sort -k 1 | head -n 11 | awk '{print $2}'

5. 功能注释结果的整合文件
```

# 二 功能注释（可放后台  如果已经做过了，可以跳过该步骤，nas6中的基因组一般都做过这个分析）
```SHELL
1. 获取转录本序列文件，fasta格式的核酸序列。
gffread -x cds.fa -g genome.fa  in.gff3
遇到错误就删删删
例子:
grep -n "rna-A564_p001"  GCF_004118075.2_ASM411807v2_genomic.gff | wc -l
for i in {1..6};do echo $i;sed -i '649514d' GCF_004118075.2_ASM411807v2_genomic.gff;done
# cds要用id来命名，重测序这块分析可能不用管

2.获取最长转录本
有的基因可能存在多个转录本，所以需要过滤下，根据上述提取出来的基因名称判断哪些是同一个基因的，一般id后面有.1 .2这种，就属于一个基因的不同转录本。
具体还要看提取出来的格式。
参考程序：
perl  /share/nas6/zhouxy/functional_modules/cnvfmt_trans2longest/fasta2longest.pl  -i cds.fa  -o filter.cds.fa(旧的程序)
perl /share/nas6/zhouxy/functional_modules/cnvfmt_trans2longest/fasta2longest_with_gff3.pl -i -g -o (新程序)
# perl /share/nas6/zhouxy/functional_modules/cnvfmt_trans2longest/fasta_trans_to_geneid_format_convert_ncbi.pl 格式转换  没用过

3. 填写功能注释的配置文件，以植物为例：
cp /share/nas6/pub/pipline/gene-function-annotation/v1.3/profile/plant_QAll.cfg .
修改第一行，改成filter.cds.fa的 ！绝对路径！。下面的nr库需要根据情况改成单子叶的或者双子叶的。

4. 运行主程序
nohup perl /share/nas6/pub/pipline/gene-function-annotation/v1.3/Gene_Func_Anno_Pipline.pl --nr --swissprot --cog --kog --kegg --pfam --GO --cfg *_QAll.cfg --od Basic_function &

程序运行完后需要用到的文件就是：Basic_function/Result/All_Database_annotation.xls 这个文件，用于填写下面的配置文件
```

# 三 主流程
```shell
示例：
/share/nas6/zhouxy/project/jinhua/GP-20210329-2838_ningdanongxueyuan_malixia_180samples_chicken_ddrad/config.yaml

配置文件脚本：
perl /share/nas6/xul/program/ddrad/create_profile_for_ddrad.pl  
-i 2.clean_data
-s CM3.6.1_pseudomol.fa
-c chrlist.txt
-gff CM3.6.1_gene.gff3
-a Gene_Anno/Result/All_Database_annotation.xls

主流程：
nohup  perl /share/nas6/zhouxy/pipline/genetic_diversity_pip/v1.0/pop_pip_v3.pl -i ddrad_config.yaml -o analysis -c 1 &
（参考基因组有染色体是-c 1，无染色体时 -c 0）

整理结果：
perl /share/nas6/zhouxy/pipline/genetic_diversity_pip/current/script/resultdir/resultDir.pl -i analysis/ -o complete_dir

报告：
cp /share/nas6/xul/project/ddrad/GP-20210729-3250_ningxiadaxue_211samples_niu_ddrad/pop_html.cfg pop_html.cfg
# 改配置文件
perl /share/nas6/zhouxy/pipline/genetic_diversity_pip/current/html_report_v2/gwas_report2html.pl -id complete_dir/ -cfg pop_html.cfg
```

# 有参简化 指纹图谱
```shell
指纹图等上面做完后单独做

配置文件：
cp /share/nas6/zhouxy/project/ddrad/GP-20220524-4388-1_guizhoudaxue_chentaolin_48samples_ddrad/kasp-develop.config.yaml kasp-develop.config.yaml
修改配置文件
   
流程：
perl /share/nas6/zhouxy/pipline/kasp/kasp-develop/v1.1/kasp-develop.pl -i kasp-develop.config.yaml -o kasp_analysis

整理结果：
perl /share/nas6/zhouxy/pipline/kasp/kasp-develop/v1.1/bin/resultsdir/resultsdir_v2.pl -i kasp_analysis/ -o kasp_complete_dir

报告：
cp /share/nas6/zhouxy/pipline/kasp/kasp-develop/v1.1/html_report/kasp_report.cfg . && realpath  kasp_report.cfg
perl /share/nas6/zhouxy/pipline/kasp/kasp-develop/v1.1/html_report/kasp_Web_Report.pl -id kasp_complete_dir/ -cfg kasp_report.cfg
```

# 筛选纯合snp
```shell
# 数据路径 

less -S -x20 samples.pop.snp.anno.result.list|grep -v "INTERGENIC"|awk '$5!=$8 && $5!="N" && $8!="N"'|awk '($5=="A" || $5=="T" || $5=="C" || $5=="G") && ($8=="A" || $8=="T" || $8=="C" || $8=="G")'|awk '$6>=10 && $9>=10'|grep SYNONYMOUS_CODING|less -S -x30

less -S -x20 samples.pop.snp.anno.result.list # -x20 tab展示为20个空格
|grep -v "INTERGENIC" # 剔除
|awk '$5!=$8 && $5!="N" && $8!="N"' # 不等且不为N
|awk '($5=="A" || $5=="T" || $5=="C" || $5=="G") && ($8=="A" || $8=="T" || $8=="C" || $8=="G")'
|awk '$6>=10 && $9>=10' # 深度大于10
|grep SYNONYMOUS_CODING # 同义编码
|less -S -x30

# 抓取序列  
perl /share/nas6/wangyq/src/advance/ssr/get_ssr_region.pl -r region_file -g genome -o snp.fasta  
  
# 添加列名  
sed -n '1p' samples.pop.snp.anno.result.list > head.txt 

然后还要加三列Gene_name        rawseq        snpseq
```

# 程序流程
```bash
."--------------------- Step 00 : config information -----------------------------\n"
                       ."--------------------- Step 01 : fastQC -----------------------------------------\n"
                      ."--------------------- Step 02 : Reference Index Build --------------------------\n"
                  ."--------------------- Step 03 : BWA Alignment ----------------------------------\n"
                  ."--------------------- Step 04 : BAM statistics  --------------------------\n"
                  ."--------------------- Step 5.1 : gatk HaplotypeCaller --------------------------\n"
                  ."--------------------- Step 5.2 : gatk CombineGVCFs and GenotypeGVCFs -----------\n"
                  ."--------------------- Step 5.3 : gatk4 GatherVCFs ------------------------------\n"
                  ."--------------------- Step 5.4 : gatk SelectVariants ---------------------------\n"
                  ."--------------------- Step 5.5 : gatk VariantRecalibrator ----------------------\n"
                  ."--------------------- Step 5.6 : gatk VariantFiltration ------------------------\n"
                  ."--------------------- Step 5.7 : gatk Filter -----------------------------------\n"
                  ."--------------------- Step 6.1 : SnpEff build index ----------------------------\n"
                  ."--------------------- Step 6.2 : GATK Annotation ------------------------------\n"
                  ."--------------------- Step 6.3 : gatk MergeVcfs --------------------------------\n"
                  ."--------------------- Step 6.4 : gatk Result Stat ------------------------------\n"
                  ."--------------------- Step 06 : Vcftools Filter ----------------------------\n"
                  ."--------------------- Step 07 : PTS ---------------------------------------\n"
  
# 20220916 第一次跑流程,这出了问题
解决:
1.$outdir/vcf_filter/samples.pop.snp.recode.vcf  把没有染色体的删去  该文件是之前步骤生成的
2.再手动执行第7步,造个.ok文件
3.ok  接着跑流程
perl /share/nas6/zhouxy/pipline/genetic_diversity_pip/v1.0/pop_pip_v3.pl -i ddrad_config.yaml -o analysis -c 1

# 下面的命令用来显示map文件里染色体有哪些
a="start" && for i in `awk '{print $2}' /share/nas1/yuj/project/GP-20220715-4649-1_20220825/analysis/PTS_analysis/pca_dir/samples.plink.map | awk -F ':' '{print $1}'`;do if [ $a != $i ];then echo $i ;a=$i;fi;done
NC_040279.1
NC_040280.1
NC_040281.1
NC_040282.1
NC_040283.1
NC_040284.1
NC_040285.1
NC_040286.1
NC_040287.1
NC_040288.1
NC_040289.1
NW_021010809.1

# 下面的命令用来显示map文件里染色体有哪些
n=1;a="NC_040279.1" && for i in `awk '{print $2}' /share/nas1/yuj/project/GP-20220715-4649-1_20220825/analysis/PTS_analysis/pca_dir/samples.plink.map | awk -F ':' '{print $1}'`;do if [ $a != $i ];then a=$i;n=$(expr $n + 1 );elif [ $i = $a ];then echo $i $n;fi;done
NC_040279.1 1
NC_040279.1 1
NC_040279.1 1
...
NC_040289.1 11
NC_040289.1 11
NC_040289.1 11
NC_040289.1 11
NC_040289.1 11
  
                  ."--------------------- Step 8 : Admixture Structure ------------------------\n"
                  ."--------------------- Step 9 : Phylogenetic tree -------------------------------\n"
					  ."--------- Step 07 : PSMC (Pairwise Sequentially Markovian Coalescent) ---------------\n"
					  
					  ## 整理结果时,这个出问题了 少pdf png
					  打不开临时文件
					  然后修改了.bashrc
					  mkdir /share/nas1/yuj/tmp
					  export TEMP=/share/nas1/yuj/tmp
					  
					  ."--------------------- Step 07 : Treemix ----------------------------------------\n"
                  ."--------------------- Step 12 : LDdecay ----------------------------------------\n"
                  ."--------------------- Step 13: PopGen statistic --------------------------------\n"
                  ."--------------------- Step 14: ROH Analysis ------------------------------------\n"
				  
				  ## 20220920 第二次跑流程卡住
				  perl /share/nas6/zhouxy/pipline/genetic_diversity_pip/v1.0/pop_pip_v3.pl -i ddrad_config.yaml -o analysis -c 1

				  /share/nas6/zhouxy/biosoft/plink/v20200428/plink --vcf $outdir/vcf_filter/samples.pop.snp.recode.vcf --recode --out $outdir/ROH_dir/samples.plink --allow-extra-chr  ##这一步之后也是要改map文件的第一列   干脆用上面的map文件来替换  ped文件倒没什么问题

				  python3 /share/nas6/zhouxy/pipline/genetic_diversity_pip/v1.0/script/14ROH/ped2cnvfmt.py -i $outdir/ROH_dir/samples.plink.ped -g $outdir/config_dir/group.list -o $outdir/ROH_dir/samples.fmt.ped

				  python3 /share/nas6/zhouxy/pipline/genetic_diversity_pip/v1.0/script/14ROH/map2cnvfmt.py -i $outdir/ROH_dir/samples.plink.map -o $outdir/ROH_dir/samples.fmt.map

				  /share/nas6/zhouxy/biosoft/R/current/bin/Rscript /share/nas6/zhouxy/pipline/genetic_diversity_pip/v1.0/script/14ROH/run_dR_cr_ROHom_v2.R $outdir/ROH_dir/samples.fmt.ped $outdir/ROH_dir/samples.fmt.map 33 $outdir/ROH_dir  ## 流程里是33条染色体,4649-1项目是11条染色体,改成11

				  造个.ok  
				  ok  接着跑流程
				  perl /share/nas6/zhouxy/pipline/genetic_diversity_pip/v1.0/pop_pip_v3.pl -i ddrad_config.yaml -o analysis -c 1
				  
                  ."--------------------- Step 6.4 : SnpEff Stat -----------------------------------\n"
				  
				  ## 20220921 第三次跑流程卡住
				  看那个失败的命令  原因在于软链接的一个文件被挪动了    不要随便改项目的目录结构
				  把文件挪回去就好了
				  perl /share/nas6/zhouxy/pipline/genetic_diversity_pip/v1.0/pop_pip_v3.pl -i ddrad_config.yaml -o analysis -c 1
				  让程序自己生成.ok
				  这次全部ok了

                  ."--------------------- Step 04 : Variant Merge ----------------------------------\n"
                  ."--------------------- Step 05 : Het Hom ----------------------------------------\n"
                  ."--------------------- Step 06 : Variant TSTV -----------------------------------\n"
                  ."--------------------- Step 06 : Sweep -----------------------------------------\n"
                  ."--------------------- Step 06 : SSR Density ------------------------------------\n"
                  ."--------------------- Step 06 : Population Marker ------------------------------\n"
                  ."--------------------- Step 14: GWAS TASSEL -------------------------------------\n"
                  ."--------------------- Step xxx : MSMC ------------------------------------------\n"
```

# Software
samtools	/share/nas6/zhouxy/biosoft/samtools/current/bin/samtools
perl	/share/nas6/zhouxy/biosoft/perl/current/bin/perl
python	/share/nas6/zhouxy/biosoft/python/2.7.18/bin/python
Rscript	/share/nas6/zhouxy/biosoft/R/current/bin/Rscript
ngsqc	/share/nas6/zhouxy/biosoft/bin/ngsqc
bwa	/share/nas6/zhouxy/biosoft/bwa/current/bwa
bcftools	/share/nas6/zhouxy/biosoft/bcftools/current/bin/bcftools
depth_stat_windows	/share/nas6/zhouxy/biosoft/bin/depth_stat_windows
gatk	/share/nas6/zhouxy/biosoft/GATK/current/gatk
vcftools	/share/nas6/zhouxy/biosoft/vcftools/current/bin/vcftools
python3	/share/nas6/zhouxy/biosoft/python/3.8.2/bin/python3
java	/share/nas6/zhouxy/software/java/current/bin/java
plink	/share/nas6/zhouxy/biosoft/plink/v20200428/plink
PopLDdecay	/share/nas6/zhouxy/biosoft/PopLDdecay/current/bin/
primer3_core	/share/nas6/zhouxy/biosoft/bin/primer3_core
gcta	/share/nas6/zhouxy/biosoft/gcta/current/gcta64
FastTreeMP	/share/nas6/zhouxy/biosoft/FastTree/FastTreeMP
