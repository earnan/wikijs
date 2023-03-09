---
title: Vcftools详解
description: 
published: true
date: 2023-03-09T03:57:15.949Z
tags: 
editor: markdown
dateCreated: 2023-03-09T03:56:29.312Z
---

# 一. VCF文件
![[Pasted image 20221026181450.png]]

## 1.1 简介
以“#”开头的注释部分：VCF的介绍信息，通常以##作为起始，其后一般接以FILTER，INFO，FORMAT等字样。
```text
以##FILTER开头的行，表示注释VCF文件当中第7列中缩写词的说明，比如q10为Quality below 10；##INFO开头的行注释VCF第8列中的缩写字母说明，比如AF代表Allele Frequency也就是等位基因频率；##FILTER开头的行注释VCF第9列中的缩写字母说明；另外还有其他的一些信息，文件版本"fileformat=VCFv4.0"等等。
```
没有“#”开头的主体部分：每一行代表一个variant，各列之间用tab空白隔开，前面9列为固定列，第10列开始为样品信息列，可以无限多个
```text
# 主体部分10列的范例
#CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO    FORMAT  MP16
13      7       13:6    C       T       .       PASS    NS=9;AF=0.500   GT:DP:AD:GQ:GL  0/1:122:81,41:40:-70.65,0.00,-174.69
```

## 1.2 10列分别代表的意义
```shell
1.CHROM：染色体编号

2.POS：variant所在的left-most位置（1-base position，发生变异的位置的第一个碱基所在的位置）

3.ID：variant的ID，对应着dbSNP数据库中的ID。（SNP/INDEL的dbSNP编号通常以rs开头，一般只有人类基因组才有dbSNP编号，若没有，则默认使用‘.’）

4.REF：参考序列的Allele。（等位碱基，即参考序列该位置的碱基类型及碱基数量，必须是A,C,G,T,N且都大写）

5.ALT：variant的Allele，若有多个，则使用逗号分隔。（变异的碱基类型及碱基数量）这里的碱基类型和碱基数量，对于SNP来说是单个碱基类型的编号，而对于Indel来说是指碱基个数的添加或缺失，以及碱基类型的变化

6.QUAL：variants的质量。PPhred格式(Phred_scaled)的质量值，代表着此位点是纯合的概率，此值越大，则纯合概率越低，表示突变可能性越大。（表示变异碱基的可能性）
计算方法：Phred值 = -10 * log (1-p)， p为variant存在的概率; 通过计算公式可以看出值为10的表示错误概率为0.1，该位点为variant的概率为90%。

7.FILTER：使用上一个QUAL值来进行过滤的话，是不够的。GATK能使用其它的方法来进行过滤，过滤结果中通过则该值为”PASS”;若variant不可靠，则该项不为”PASS”或为”.”。

8.INFO：variant的相关信息

9.FORMAT：variants的格式，例如GT:AD:DP:GQ:PL

10.SAMPLES：各个Sample的值，由BAM文件中的@RG下的SM标签所决定，这些值对应着第9列的各个格式，不同格式的值用冒号分开，每一个sample对应着1列；多个samples则对应着多列，这种情况下列的数多余10列。
```

## 1.3 FORMAT 及对应  SAMPLES值
FORMAT和最后一列（最后一列一般为样品名），两者和一起则为基因型信息，前者为格式，后者为对应的数据，如：
```shell
GT:AD:DP:GQ:PL    0/1:6,5:11:99:138,0,153
```
1. GT（GenoType）：表示样品的基因型，通常用”/” or “|”分隔两个数字，“|”phase过也就是杂合的两个等位基因知道哪个等位基因来自哪条染色体
> 对于二倍体生物，GT值表示的是样本在这个位点所携带的两个等位基因。0代表参考基因组的碱基类型；1代表ALT碱基类型的第一个碱基（多个碱基用","分隔），2代表ALT第二个碱基，以此类推。0表示跟REF一样，1表示跟ALT一样，2表示有第二个ALT。
> 
> - 0/0表示sample中该位点为纯合位点，和REF的碱基类型一致
> - 0/1表示sample中该位点为杂合突变，有REF和ALT两个基因型（部分碱基和REF碱基类型一致，部分碱基和ALT碱基类型一致）
> - 1/1表示sample中该位点为纯合突变，总体突变类型和ALT碱基类型一致
> - 1/2表示sample中该位点为杂合突变，有ALT1和ALT2两个基因型（部分和ALT1碱基类型一致，部分和ALT2碱基类型一致）
> - ./.表示缺失
> 
> 以二倍体生物为例，基因型由两条染色体上的allel构成。当我们知道每一个allel来自于具体哪条染色体时，这种genotype叫做Phased genotype, 用|连接，1|0和0|1代表两种不同的基因型；不清楚allel对应的染色体的时， genotype叫做unphased genotype, 用/连接，0/1和1/0这两种写法是等价的。目前高通量分析鉴定到的基因型，大多数都是unphased genotype。
2. AD(Allele Depth)：sample中每一种allele（等位碱基）的reads覆盖度，在diploid（二倍体，或可指代多倍型）中则是用逗号分隔的两个值，前者对应REF基因，后者对应ALT基因型
3. DP(Depth)：表示覆盖在这个位点的总reads数，也就是这个位点的测序深度（并不是指具体有多少个reads数量，而是大概满足一定质量值要求的reads数），是所支持的两个AD值（逗号前和逗号后）的加和
4. PL（likelihood genotypes）：指定的三种基因型的质量值（provieds the likelihoods of the given genotypes），分别对应该位点的三个基因型0/0，0/1，1/1的没经过先验的标准化Phred-scaled似然值（L）
> - L= -10 * log (p)，P为支持该基因型的概率，3个概率总和为1；因此，L这个值越小，支持概率就越大，也就是说是这个基因型的可能性越大。最有可能的genotype的值为0。
> - 归一化后各基因型的可能性，通常有三个数字用’,'隔开，顺序对应AA,AB,BB基因型，A代表REF，B代表ALT(也就是0/0, 0/1, and 1/1)，由于是归一化之后，数值越小代表基因型越可靠；那么最小的数字对应的基因型判读为该样品的最可能的基因型
5. GQ(Genotype Quality)：基因型的质量值。Phred格式（Phred_scaled）的质量值，表示在该位点该基因型存在的可能性
> - 针对PL的判读得到的基因型的质量值，此值越大基因型质量值越好。由于PL归一化之后通常最小的数字为0；那么基因型的质量值取PL中第二小的数字，如果第二小的数字大于99，我们只取99，因为在GATK中再大的值是没有意义的，第二小的数大于99的话一般说明基因型的判读是很可靠的，只有当第二小的数小于99的时候，才有必要怀疑基因型的可靠性
> - 该值越高，则Genotype的可能性越大；计算方法：Phred值=-10 * log(1-P)，P为基因型存在的概率。（一般在final.snp.vcf文件中，该值为99，为99时，其可能性最大）

## 1.4 INFO 信息列
```shell
AC=1;AF=0.500;AN=2;BaseQRankSum=0.748;ClippingRankSum=0.000;DB;DP=34;ExcessHet=3.0103;FS=3.424;MLEAC=1;MLEAF=0.500;MQ=31.07;MQRankSum=-0.087;QD=11.87;ReadPosRankSum=-1.349;SOR=2.636
AC=2;AF=1.00;AN=2;DB;DP=14;ExcessHet=3.0103;FS=0.000;MLEAC=2;MLEAF=1.00;MQ=31.60;QD=29.36;SOR=5.421
```
以 “TAG=Value”,并使用”;”分隔的形式。其中很多的注释信息在VCF文件的头部注释中给出。以下是这些TAG的解释：
1. AC(Allele Count)：表示基因型为与variant一致的Allele的数目，Allele数目为1表示双倍体的样本在该位点只有1个等位基因发生了突变
2. AF(Allele Frequency)：表示Allele的频率，AF值=AC值/AN值，Allele频率为0.5表示双倍体的样本在该位点只有50%的等位基因发生了突变
3. AN(Allele Number)：表示Allele的总数目
> - 对于1个diploid sample而言：
> - 基因型 0/1 表示sample为杂合子，Allele数为1(双倍体的sample在该位点只有1个等位基因发生了突变)，Allele的频率为0.5(双倍体的 sample在该位点只有50%的等位基因发生了突变)，总的Allele为2；
> - 基因型 1/1 则表示sample为纯合的，Allele数为2，Allele的频率为1，总的Allele为2。
4. DP：样本在这个位置的reads覆盖度，是一些reads被过滤掉后的覆盖度（跟上面提到的DP类似）
5. Dels：Fraction of Reads Containing Spanning Deletions。进行SNP和INDEL calling的结果中，有该TAG并且值为0表示该位点为SNP，没有则为INDEL。
6. FS(FisherStrand)：使用Fisher’s精确检验来检测strand bias而得到的Fhred格式的p值，值越小越好。
> - 使用F检验来检验测序是否存在链偏好性（？）。链偏好性可能会导致变异等位基因检测出现错误。输出值Phred-scaled p-value，值越大越可能出现链偏好性。
> - 如果该值较大，表示strand bias（正负链偏移）越严重，即所检测到的variants位点上，reads比对到正负义链上的比例不均衡。
> - 一般进行filter的时候，推荐保留FS<10~20的variants位点。GATK可设定FS参数。
7. HaplotypeScore：Consistency of the site with at most two segregating haplotypes.最多有2个分离的单倍型的一致性。
8. InbreedingCoeff：Inbreeding coefficient as estimated from the genotype likelihoods per-sample when compared against the Hard-Weinberg expectation.与哈代温伯格的期望相比，近亲繁殖估计每个样品基因型的可能性。
9. MLEAC：Maximum likelihood expectation (MLE) for the allele counts (not necessarily the same as the AC), for each ALT allele, in the same order as listed.对于每个ALT等位基因，等位基因计数（不一定与AC相同）的最大似然期望（MLE），顺序与列出的顺序相同。
10. MLEAF：Maximum likelihood expectation (MLE) for the allele frequency (not necessarily the same as the AF), for each ALT alle in the same order as listed.对于每个ALT等位基因，等位基因频率（不一定与AF相同）的最大似然期望（MLE），顺序与列出的顺序相同。
11. MQ：RMS Mapping Quality 表示覆盖序列质量的均方值 
12. MQ0：Total Mapping Quality Zero Reads.总的Mapping 质量 零Reads 。
13. MQRankSum：Z-score From Wilcoxon rank sum test of Alt vs. Ref read mapping qualities.对Alt vs 参考片段映射质量的Wilcoxon秩和检验的z 分数。
> - 比较支持变异的序列和支持参考基因组的序列的质量，负值表示支持变异的碱基质量值不及支持参考基因组的，只针对杂合。正值则相反，支持变异的质量值好于参考基因组的。0表示两者无明显差异。实际应用中一般过滤掉较小的负值。
> - 该值用于衡量alternative allele上reads的mapping quality与reference allele上reads的mapping quality的差异。若该值是负数值，则表明alternative allele比reference allele的reads mapping quality差。
> - 进行filter的时候，推荐保留MQRankSum>-1.65~-3.0的variant位点。
14. BaseQRankSum：Z-score from Wilcoxon rank sum test of Alt Vs. Ref base qualities.来自Wilcoxon的Z分数 Alt与Ref基本质量的秩和测试
> - 比较支持变异的碱基和支持参考基因组的碱基的质量，负值表示支持变异的碱基质量值不及支持参考基因组的。
15. ClippingRankSum：Z-score From Wilcoxon rank sum test of Alt vs. Ref number of hard clipped bases.Z 得分来自 Wilcoxon 的 Alt 与 Ref 硬剪切基数的秩和检验
16. ExcessHet：过量Het.Phred-scaled p-value for exact test of excess heterozygosity.用于精确检验过量杂合度的Phred标度p值。
> - 检测样本的相关性，与InbreedingCoeff相似，值越大越可能是错误。
17. QD：Variant Confidence/Quality by Depth.变异置信度/深度质量。
> - 通过深度来评估一个变异的可信度。
18. RPA：Number of times tandem repeat unit is repeated, for each allele (including reference).对于每个等位基因（包括参考），大量的串联重复序列单位被重复。
19. RU：Tandem repeat unit (bases).串联重复序列单元（基础）。
20. ReadPosRankSum：Z-score from Wilcoxon rank sum test of Alt vs. Ref read position bias.对Alt vs 参考片段位置偏差的Wilcoxon秩和检验的z 分数。
> - 检测变异位点是否有位置偏好性（是否存在于序列末端，此时往往容易出错）。最佳值为0，表示变异与其在序列上的位置无关。负值表示变异位点更容易在末端出现，正值表示参考基因组中的等位基因更容易在末端出现。
> - 当variants出现在reads尾部的时候，其结果可能不准确。该值用于衡量alternative allele（变异的等位基因）相比于reference allele（参考基因组等位基因），其variant位点是否匹配到reads更靠中部的位置。因此只有基因型是杂合且有一个allele和参考基因组一致的时候，才能计算该值。若该值为正值，表明和alternative allele相当于reference allele，落来reads更靠中部的位置；若该值是负值，则表示alternative allele相比于reference allele落在reads更靠尾部的位置。
> - 进行filter的之后，推荐保留ReadPosRankSum>-1.65~-3.0的variant位点
21. SOR：Symmetric Odds Ratio of 2x2 contingency table to detect strand bias.  2x2 列联表的对称比值比，用于检测链偏置。
> - The StrandOddsRatio annotation is one of several methods that aims to evaluate whether there is strand bias in the data. It is an updated form of the Fisher Strand Test that is better at taking into account large amounts of data in high coverage situations. It is used to determine if there is strand bias between forward and reverse strands for the reference or alternate allele. The reported value is ln-scaled.
> - 也是一个用来评估是否存在链偏向性的参数，相当于FS的升级版。
22. STR：Variant is a short tandem repeat.Variant是一个短的串联重复。

# 二. Vcftools用法

## 2.1 过滤变异类型  
vcf文件中可能会同时包含snp以及indel两种变异类型，vcftools可以很快的将两者进行分离。
### 2.1.1 过滤掉indel，只保留snp，用到的命令选项：–remove-indels。
```bash
vcftools --remove-indels --recode --recode-INFO-all --vcf raw.vcf --stdout >raw.snp.vcf
```
### 2.1.2 过滤掉snp，只保留indel，用到的命令选项：–keep-only-indels。
```bash
vcftools --keep-only-indels --recode --recode-INFO-all --vcf raw.vcf --stdout >raw.indel.vcf
```
这样，就可以分别得到只包含snp和indel的vcf文件。

## 2.2 筛选指定位置变异位点  
vcftools还可以挑选出基因组上某些区域的变异信息。
```bash
vcftools --vcf Variants.snp.unknown_multianno.vcf --chr A03 --from-bp 577700 --to-bp 607700 --out out_prefix --recode --recode-INFO-all
```
这里解释一下各个参数：
–vcf：后面跟的是vcf文件
–chr：后面跟筛选区域所在的染色体
–form-bp：后跟筛选区域的起始位置
–to-bp：后跟筛选区域的终止位置
–out：输出文件的前缀
–recode：没有此参数则不会输出

## 2.3 过滤指定缺失率的变异位点  
vcf 文件中很多snp在某些样品中是缺失的，也就是基因型为 “./.” 。如果缺失率较高，这种snp位点在很多分析中是不能用的，需要去掉。这里用到的选项是 --max-missing。
```bash
vcftools --vcf snp.vcf --recode --recode-INFO-all --stdout --max-missing 1 > snp.new.vcf
--max-missing 后跟的值为 0-1 ，1代表不允许缺失，0代表允许全部缺失。
```

## 2.4 计算snp缺失率  
vcftools中有两个参数可以计算vcf文件中snp的缺失率。
分别是：
–missing-indv：生成一个文件，报告每个样品的缺失情况，该文件的后缀为“.imiss”。
–missing-site：生成一个文件，报告每个snp位点的缺失情况，该文件的后缀为“.lmiss”。
### 2.4.1 –missing-site
```bash
vcftools --vcf snp.vcf. --missing-site
```
运行以上命令后会在当前目录生成一个 out.lmiss 文件，其格式如下：
```text
CHR POS N_DATA N_GENOTYPE_FILTERED N_MISS F_MISS  
chr01 194921 988 0 368 0.37247  
chr01 384714 988 0 204 0.206478  
chr01 384719 988 0 202 0.204453  
chr01 518438 988 0 488 0.493927  
chr01 518473 988 0 452 0.45749  
chr01 518579 988 0 418 0.423077  
chr01 518635 988 0 428 0.433198  
chr01 680786 988 0 346 0.350202  
chr01 680834 988 0 412 0.417004  
# 前两列为snp所在位置，第三列为等位基因总数，第5列为缺失的总数，最后一列为缺失率。
```
### 2.4.2 –missing-indv
```bash
vcftools --vcf snp.vcf. --missing-indv
```
运行以上命令后会在当前目录生成一个 out.imiss 文件，其格式如下：
```text
INDV N_DATA N_GENOTYPES_FILTERED N_MISS F_MISS  
1 8747 0 3632 0.415228  
10 8747 0 1264 0.144507  
102 8747 0 2016 0.230479  
105 8747 0 6322 0.722762  
106 8747 0 2365 0.270378  
107 8747 0 4376 0.500286  
108 8747 0 5682 0.649594  
109 8747 0 1877 0.214588  
11 8747 0 1039 0.118784  
# 第一列为样品名称，第二列为总的snp数，第4列为缺失的总数，最后一列为缺失率。
```

## 2.5 随机抽取指定个样品  
vcftools可以随机抽取指定个样品的vcf文件，用到的选项为 --max-indv ，指定要从vcf文件中随机抽取指定个样品。
```bash
# 随机抽取5个样品，执行以下代码：
vcftools --vcf snp.vcf --max-indv 5 --remove-indels --recode --out outfilename
```
