#Linux #linux命令 #组装 #细胞器 #注释
# 1.组装
```SHELL
for file in `ls *.fasta`;do mv $file `echo ${file%.fasta}`;done 
# 文件名去除名字后缀,rename也行

for file in `ls *.fasta`;do echo ${file%.fasta};done 
# 只取需要的部分

for i in *.fasta;do echo ${file%.fasta};done 
# 缺一个,不知道为啥
```
## mapping
```shell
# map时手动中止 调整双端reads条数

$ wc -l map_pair_hits.1.fq | awk '{print $1}'
8251592


$ awk 'END{print NR}' map_pair_hits.1.fq && awk 'END{print NR}' map_pair_hits.2.fq
2000
2000

$ head -n 1000  map_pair_hits.1.fq > 1.fa
$ head -n 1000  map_pair_hits.2.fq > 2.fa

head -n 1000 map_pair_hits.1.fq > cut.1.fq && head -n 1000 map_pair_hits.2.fq > cut.2.fa
```
## asmqc
```shell
# 以4313 7个脊椎动物为例(蛙 蜥蜴 等)

# 组装结果
for i in $( ls analysis/assembly) ;do ls analysis/assembly/$i/finish/*.fsa;done

# clean data
for i in $( ls analysis/assembly) ;do grep $i  analysis/samples.reads.txt | awk '{print $2"     "$3}';done

# gbk
for i in $( ls analysis/assembly) ;do ls analysis/annotation/$i/*.gbk;done

# asmqc路径
for i in $( ls analysis/assembly) ;do ls analysis/annotation/$i/asmqc;done

# ref
for i in $( ls analysis/assembly) ;do grep $i  ann.cfg | awk '{print $3}';done


# perl /share/nas6/pub/pipline/genome-assembly-seq/mitochondrial-genome-seq/v2.0/asmqc/mtDNA_asmqc.pl -i 组装结果  -1 clean*1 -2 clean*2 -p sample -q 物种.gbk  -o asmqc -g 2 -r 参考.gbk

# 全部物种
for i in $( ls analysis/assembly) ;do perl /share/nas6/pub/pipline/genome-assembly-seq/mitochondrial-genome-seq/v2.0/asmqc/mtDNA_asmqc.pl -i analysis/assembly/$i/finish/*.fsa  -1 `grep $i  analysis/samples.reads.txt | awk '{print $2}'` -2 `grep $i  analysis/samples.reads.txt | awk '{print $3}'` -p sample -q analysis/annotation/$i/*.gbk  -o analysis/annotation/$i/asmqc -g 2 -r `grep $i  ann.cfg | awk '{print $3}'`;done

# 括号内物种
for i in {Megaustenia_imperator,Meghimatium_bilineatum_1,Meghimatium_bilineatum_2,Succinea_arundinetorum};do echo /share/nas6/pub/pipline/genome-assembly-seq/mitochondrial-genome-seq/v2.0/asmqc/mtDNA_asmqc.pl -i analysis/assembly/$i/finish/*.fsa -1 `grep $i analysis/samples.reads.txt | awk '{print $2}'` -2 `grep $i analysis/samples.reads.txt | awk '{print $3}'` -p sample -q analysis/annotation/$i/*.gbk -o analysis/annotation/$i/asmqc -g 2 -r `grep $i ann.cfg | awk '{print $3}'`;done

```

# 2.注释
```shell
# 从注释info里查看每个基因
for i in `grep CDS gene.annotation.info |awk -F" " '{ print $2 }'`;do echo "########################################################################################################################################################################"$i;mt_add.py -n 5 -i *.fsa -p $i;done > ne07356.check
```

# 3.高级分析
```shell
# 配置文件
echo `ir analysis/assembly/Cyclobalanopsis_fleuryi/finish/Cyclobalanopsis_fleuryi_FULLCP.fsa | grep -E 'IRb'|awk -F ":" '{print $2}'`","`ir analysis/assembly/Cyclobalanopsis_fleuryi/finish/Cyclobalanopsis_fleuryi_FULLCP.fsa | grep -E 'IRa'|awk -F ":" '{print $2}'`

# result 90206-116047,134937-160778
```

```shell

# 给gbk改名
cd ref_adv/fasta && for i in *.fasta;do rename               `awk '{if(NR==1) print $0}' $i | awk -F ">" '{ print $2 }' | awk -F ".1_" '{ print ""$1""".1" }'`       `awk '{if(NR==1) print $0}' $i | awk -F ">" '{ print $2 }' | awk -F ".1_" '{ print $2"""_"""$1""".1" }'`   ../gbk/""`awk '{if(NR==1) print $0}' $i | awk -F ">" '{ print $2 }' | awk -F ".1_" '{ print ""$1""".1" }'`.gbk  ;done  && cd ../../

# 给fasta改名
cd ref_adv/fasta && for i in *.fasta;do rename              `awk '{if(NR==1) print $0}' $i | awk -F ">" '{ print $2 }' | awk -F ".1_" '{ print ""$1""".1" }'`       `awk '{if(NR==1) print $0}' $i | awk -F ">" '{ print $2 }' | awk -F ".1_" '{ print $2"""_"""$1""".1" }'`   ../fasta/""`awk '{if(NR==1) print $0}' $i | awk -F ">" '{ print $2 }' | awk -F ".1_" '{ print ""$1""".1" }'`.fasta  ;done  && cd ../../

```











