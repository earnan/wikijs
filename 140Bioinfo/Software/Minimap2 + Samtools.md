#工具  #软件 

# 一.Minimap2

`https://github.com/lh3/minimap2`

## 1.minimap2安装
```bash
curl -L https://github.com/lh3/minimap2/releases/download/v2.17/minimap2-2.17_x64-linux.tar.bz2 
tar -jxvf minimap2-2.17_x64-linux.tar.bz2 
cd minimap2-2.17_x64-linux/
make
```

```bash
git clone https://github.com/lh3/minimap2
cd minimap2 && make
```

## 2.minimap2使用
```bash

# 常用
minimap2 -ax map-ont ref.fa 测序数据.fq.gz > aln.sam # nanopore


minimap2 -ax map-pb  ref.fa pacbio-reads.fq > aln.sam   # for PacBio subreads
minimap2 -ax map-ont ref.fa ont-reads.fq > aln.sam      # for Oxford Nanopore reads

-x ：非常重要的一个选项，软件预测的一些值，针对不同的数据选择不同的值
map-pb/map-ont: pb或者ont数据与参考序列比对；
ava-pb/ava-ont: 寻找pd数据或者ont数据之间的overlap关系；
asm5/asm10/asm20: 拼接结果与参考序列进行比对，适合~0.1/1/5% 序列分歧度；
splice: 长reads的切割比对
sr: 短reads比对
-d :创建索引文件名
-a ：指定输出格式为sa格式，默认为PAF
-Q ：sam文件中不输出碱基质量
-R ：reads Group信息，与bwa比对中的-R一致
-t：线程数，默认为3
```

## 3.原理
minimap2的主要思想是：首先将基因组序列的minimizer存储在哈希表中(minimizer指一段序列内最小哈希值的种子)；然后对于每一条待比对序列， 找到待比对序列所有的minimizer，通过哈希表找出其在基因组中的位置， 并利用chaining算法寻找待比对区域；最后将非种子区域用动态规划算法进行比对，得到比对结果。minimap2方法只对最小哈希值的种子进行存储，可有效降低时间复杂度。

## 4.优劣势

# 二.Samtools
Samtools是一款处理高通量测序数据的常用软件，主要包括samtools和bcftools两个工具。Samtools用于对SAM/BAM/CRAM格式文件进行读/写/编辑/建索引/查看等；bcftools可用于对BCF2/VCF/gVCF格式文件进行读/写，对SNP和短indel变异进行检测/过滤/统计总结等。
## 0.项目应用
### 筛选
```shell

$ samtools view -F 4 extend.sam  | perl -lane 'print unless($F[9] eq "*")' |  perl -ane 'print if(/^@/);if(/NM:i:(\d+)/){$n=$1;$l=0;$l+=$1 while $F[5]=~ /(\d+)[M]/g;if($l > 1000){print}}'|sort -k 4 -n> tmp.sam && cat tmp.sam  |cut -f 10 |perl -lane 'print ">",++$i;print $F[0]'    > map_gene.fa

# if($l > 1000) 筛选大于1000bp
```
### 校正
```shell

$ nohup /share/nas6/zhangxq/biosoft/canu-master/Linux-amd64/bin/canu -correct -p correct -d correct genomeSize=10k useGrid=false -nanopore-raw  map_gene.fa &

# genomeSize=10k 平均长度10K
```
## 1. 查看（viewing）
### 1.1view
```bash
# 提取
samtools view -F 4 extend.sam  | perl -lane 'print unless($F[9] eq "*")' |  perl -ane 'print if(/^@/);if(/NM:i:(\d+)/){$n=$1;$l=0;$l+=$1 while $F[5]=~ /(\d+)[M]/g;if($l > 1000){print}}'|sort -k 4 -n> tmp.sam && cat tmp.sam  |cut -f 10 |perl -lane 'print ">",++$i;print $F[0]'    > map_gene.fa
# $l > 1000 长度大于1K

-F 数字4代表该序列比对到参考序列上　数字8代表该序列的mate序列比对到参考序列上 ???

# 提取比对到参考序列上的比对结果
$ samtools view -bF 4 abc.bam > abc.F.bam

# 提取paired reads中两条reads都比对到参考序列上的比对结果，只需要把两个4+8的值12作为过滤参数即可
$ samtools view -bF 12 abc.bam > abc.F12.bam

# 提取没有比对到参考序列上的比对结果
$ samtools view -bf 4 abc.bam > unmapped.bam

# 比对到反向互补链的reads
$ samtools view -f 16 test.bam|head -1

# 比对到正向链的reads
$ samtools view -F 16 test.bam|head -1

# 统计共有多少条reads（pair-end-reads这里算一条）参与了比对参考基因组
$ samtools view -c test.bam

# 筛选出比对失败的reads，看序列特征
$ samtools view -f 4 test.bam|cut -f10 |head -3

# 筛选出比对质量值大于30的情况
$ samtools view -q 30 test.bam |awk '{print $1,$5}'|head -3

# 筛选出比对成功,但是并不是完全匹配的序列
$ samtools view -F 4 test.bam |awk '{print $6}'|grep '[IDNSHPX]'|head -5
```

```shell
# sam转bam
$ samtools view -Sb aln.sam > aln.bam

# 将sam文件转换成bam文件
$ samtools view -bS abc.sam > abc.bam
或
$ samtools view -b -S abc.sam -o abc.bam

# 提取bam文件中比对到caffold1上的比对结果，并保存到sam文件格式
$ samtools view abc.bam scaffold1 > scaffold1.sam

# 提取scaffold1上能比对到30k到100k区域的比对结果
$ samtools view abc.bam scaffold1:30000-100000 $gt; scaffold1_30k-100k.sam

# 根据fasta文件，将 header 加入到 sam 或 bam 文件中
$ samtools view -T genome.fasta -h scaffold1.sam > scaffold1.h.sam
```
### 1.2tview
交互式的查看reads比对到参考基因组上的信息，类似IGV
```bash
samtools tview SRR2584866.aligned.sorted.bam ecoli_ref.fa

#result:
1 11 21 31 41 51 61 71 81 91 101 111 121
AGCTTTTCATTCTGACTGCAACGGGCAATATGTCTCTGTGTGGATTAAAAAAAGAGTGTCTGATAGCAGCTTCTGAACTGGTTACCTGCCGTGAGTAAATTAAAATTTTATTGACTTAGGTCACTAAATAC
..................................................................................................................................
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,, ..................N................. ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,........................
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,, ..................N................. ,,,,,,,,,,,,,,,,,,,,,,,,,,,.............................
...................................,g,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,, .................................... ................
```
结果：第一行是ref的位置号，第二行是ref序列（如果不在命令中添加ref的fa文件，这一行将显示N），之后是比对情况，‘.’表示正链匹配到参考基因组上，逗号‘,’表示反链匹配到参考基因组上，‘.’中间出现大写的ATCGN代表该碱基没有匹配上，‘,’中间出现小写的atcgn代表该碱基没有匹配上。按ctrl+c或q退出。

## 2.索引（indexing）
在NGS数据分析过程中，包括比对在内的很多地方都需要建索引，主要作用就是为了快，提高效率。对一些大文件我们要养成建索引的习惯，况且一些功能的正常运行必需要提供索引文件，有的软件在生成结果文件的同时也生成其对应的索引文件，可以说，索引随处可见。
### 2.1faidx
```bash
对fasta参考基因组建索引(faidx)
samtools faidx ref.fa #生成ref.fa.fai
```
### 2.2index
```bash
对BAM文件建索引
samtools index test.sorted.dup.bam #生成test.sorted.dup.bam.bai
```
## 3. 文件操作（file operations）
### 3.1sort
当利用FASTQ文件与参考基因组进行比对时，reads比对结果的顺序相对于它们在参考基因组中的位置而言是随机的，也就是说BAM文件按照序列在输入的FASTQ文件中出现的顺序排列。如果要进一步操作（如变异检测、IGV查看比对结果等），都需要对BAM文件进行排序，以使比对结果陈列是按“基因组顺序”进行，即根据它们在每个染色体上的位置进行排序。
```bash
samtools sort mapped.bam -o aln.mapped.sort.bam
samtools sort aln.bam -o aln.sort.bam
```

```bash
samtools sort [-l level] [-m maxMem] [-o out.bam] [-O format] [-n] [-T tmpprefix] [-@ threads] [in.sam|in.bam|in.cram]

参数：
-l INT 
设置输出文件压缩等级。0-9，0是不压缩，9是压缩等级最高。不设置此参数时，使用默认压缩等级；
-m INT 
设置每个线程运行时的内存大小，可以使用K，M和G表示内存大小。
()参数默认下是 500,000,000 即500M（不支持K，M，G等缩写）。对于处理大数据时，如果内存够用，则设置大点的值，以节约时间。
-n
设定排序方式按short reads的ID排序。否则,默认下是按序列在fasta文件中的顺序（即header）和序列从左往右的位点排序。
(1)默认方式，按照染色体的位置进行排序
(2)参数-n则是根据read名进行排序
-o FILE 
设置最终排序后的输出文件名；
-O FORMAT 
设置最终输出的文件格式，可以是bam，sam或者cram，默认为bam；
-T PREFIX 
设置临时文件的前缀；
-@ INT 
设置排序和压缩是的线程数量，默认是单线程。

例子：
$ samtools sort  abc.bam  abc.sort 
# 注意 abc.sort 是输出文件的前缀，实际输出是 abc.sort.bam
$ samtools view abc.sort.bam | less -S
```

### 3.2mpileup
输入BAM文件，产生bcf或pileup格式的文件，bcf格式文件可以通过bcftools处理检测snp和indel。Pileup文件可通过varscan检测变异（如snp、indel等）
```bash
samtools mpileup test.sort.dup.bam -o test.sort.dup.bcf

# bcftools
bcftools call -Ovm -o out.vcf test.sort.dup.bcf

# samtools+ VarScan
samtools mpileup -f ref.fa test.sort.dup.bam | java -jar VarScan.jar mpileup2snp --output-vcf --strand-filter 0
samtools mpileup -f ref.fa test.sort.dup.bam | java -jar VarScan.jar mpileup2indel --output-vcf --strand-filter 0
samtools mpileup -q20 -d8000 -f ref.fa test.sorted.dup.bam | java -jar VarScan.v2.3.9.jar mpileup2cns --variants --output-vcf > out.vcf
```

## 4. 统计（statistics）
### 4.1flagstat
BAM文件的简单统计。
```bash
samtools flagstat t1.sort.bam > t1.flagstat.txt
samtools flagstat t1.sort.bam
#result
6874858 + 0 in total (QC-passed reads + QC-failed reads)
90281 + 0 duplicates
6683299 + 0 mapped (97.21%)
6816083 + 0 paired in sequencing
3408650 + 0 read1
3407433 + 0 read2
6348470 + 0 properly paired (93.14No value assigned)
6432965 + 0 with itself and mate mapped
191559 + 0 singletons (2.81No value assigned)
57057 + 0 with mate mapped to a different chr
45762 + 0 with mate mapped to a different chr (mapQ>=5)
```
各列的意义可参考：`https://www.jianshu.com/p/ccc59b459d4a`
### 4.2depth
统计每个位置碱基是测序深度。
```bash
samtools depth SRR2584866.aligned.sorted.bam > depth.txt
#result
head depth.txt
CP000819.1 1 4
CP000819.1 2 4
CP000819.1 3 5
CP000819.1 4 5
CP000819.1 5 5
CP000819.1 6 5
CP000819.1 7 5
CP000819.1 8 5
CP000819.1 9 5
CP000819.1 10 5
```
3列依次为染色体名称，位置，覆盖深度。

## 5.参数

samtools view

```text
Usage: samtools view [options] <in.bam>|<in.sam>|<in.cram> [region ...]
Options:
  -b       output BAM
  -C       output CRAM (requires -T)
  -1       use fast BAM compression (implies -b)
  -u       uncompressed BAM output (implies -b)
  -h       include header in SAM output
  -H       print SAM header only (no alignments)
  -c       print only the count of matching records
  -o FILE  output file name [stdout]
  -U FILE  output reads not selected by filters to FILE [null]
  -t FILE  FILE listing reference names and lengths (see long help) [null]
  -L FILE  only include reads overlapping this BED FILE [null]
  -r STR   only include reads in read group STR [null]
  -R FILE  only include reads with read group listed in FILE [null]
  -q INT   only include reads with mapping quality >= INT [0]
  -l STR   only include reads in library STR [null]
  -m INT   only include reads with number of CIGAR operations consuming
           query sequence >= INT [0]
  -f INT   only include reads with all  of the FLAGs in INT present [0]
  -F INT   only include reads with none of the FLAGS in INT present [0]
  -G INT   only EXCLUDE reads with all  of the FLAGs in INT present [0]
  -s FLOAT subsample reads (given INT.FRAC option value, 0.FRAC is the
           fraction of templates/read pairs to keep; INT part sets seed)
  -M       use the multi-region iterator (increases the speed, removes
           duplicates and outputs the reads as they are ordered in the file)
  -x STR   read tag to strip (repeatable) [null]
  -B       collapse the backward CIGAR operation
  -?       print long help, including note about region specification
  -S       ignored (input format is auto-detected)
      --input-fmt-option OPT[=VAL]
               Specify a single input file format option in the form
               of OPTION or OPTION=VALUE
  -O, --output-fmt FORMAT[,OPT[=VAL]]...
               Specify output format (SAM, BAM, CRAM)
      --output-fmt-option OPT[=VAL]
               Specify a single output file format option in the form
               of OPTION or OPTION=VALUE
  -T, --reference FILE
               Reference sequence FASTA FILE [null]
  -@, --threads INT
               Number of additional threads to use [0]
```

samtools tview

```text
Usage: samtools tview [options] <aln.bam> [ref.fasta]
Options:
   -d display      output as (H)tml or (C)urses or (T)ext
   -p chr:pos      go directly to this position
   -s STR          display only reads from this sample or group
      --input-fmt-option OPT[=VAL]
               Specify a single input file format option in the form
               of OPTION or OPTION=VALUE
      --reference FILE
               Reference sequence FASTA FILE [null]
```

samtools sort

```text
Usage: samtools sort [options...] [in.bam]
Options:
  -l INT     Set compression level, from 0 (uncompressed) to 9 (best)
  -m INT     Set maximum memory per thread; suffix K/M/G recognized [768M]
  -n         Sort by read name
  -t TAG     Sort by value of TAG. Uses position as secondary index (or read name if -n is set)
  -o FILE    Write final output to FILE rather than standard output
  -T PREFIX  Write temporary files to PREFIX.nnnn.bam
      --input-fmt-option OPT[=VAL]
               Specify a single input file format option in the form
               of OPTION or OPTION=VALUE
  -O, --output-fmt FORMAT[,OPT[=VAL]]...
               Specify output format (SAM, BAM, CRAM)
      --output-fmt-option OPT[=VAL]
               Specify a single output file format option in the form
               of OPTION or OPTION=VALUE
      --reference FILE
               Reference sequence FASTA FILE [null]
  -@, --threads INT
               Number of additional threads to use [0]
```

samtools index

```text
Usage: samtools index [-bc] [-m INT] <in.bam> [out.index]
Options:
  -b       Generate BAI-format index for BAM files [default]
  -c       Generate CSI-format index for BAM files
  -m INT   Set minimum interval size for CSI indices to 2^INT [14]
  -@ INT   Sets the number of threads [none]
```

samtools flagstat

```text
Usage: samtools flagstat [options] <in.bam>
      --input-fmt-option OPT[=VAL]
               Specify a single input file format option in the form
               of OPTION or OPTION=VALUE
  -@, --threads INT
               Number of additional threads to use [0]
```

Samtools手册: `http://www.htslib.org/doc/#manual-pages`


