# 简介
tRNAscan-SE 能在基因组水平上进行 tRNA 扫描。该软件实际上是一个 perl 脚本，整合了 tRNAscan、 EufindRNA 和 Cove 这 3 个独立的 tRNA 检测软件。tRNAscan-SE 首先调用 tRNAscan 和 EufindRNA 鉴定基因组序列中的 tRNA 区域，然后调用 Cove 进行验证。这样既保证了前者的 sensitivities， 又保证了后者较低的假阳性概率，同时在搜索速度上提升了很多。  
有关 tRNAscan-SE 的详细说明，参考其本地化软件包中的 man 文档。

tRNAscan-SE 工具中综合了多个识别和分析程序，通过分析启动子元件的保守序列模式，tRNA 二级结构的分析，转录控制元件分析和除去绝大多数假阳性的筛选过程，据称能识别99%的真实tRNA基因，其搜索的速度可以达到30kb/秒。该程序适用于大规模人类基因组序列的分析，同时也可以用于其它DNA 序列。并且可以在Web上使用这个工具，也可以下载这个程序。

```bash
# 安装
conda create -n trnascan -y
conda activate trnascan
conda install -c bioconda trnascan-se

# 报错
tRNAscan-SE -h
# Perl lib version (5.28.3) doesn't match executable 

# 退出conda 再操作
/share/nas1/yuj/software/miniconda3/envs/trnascan/bin/tRNAscan-SE -h

# sample
/share/nas1/yuj/software/miniconda3/envs/trnascan/bin/tRNAscan-SE -o tRNA.out -f tRNA.ss -m tRNA.stats /share/nas1/yuj/project/GP-20220506-4313_20220519/analysis/assembly/Nanorana_medogensis/finish/Nanorana_medogensis_FULLMT.fsa -O

# 帮助命令
/share/nas1/yuj/software/miniconda3/envs/trnascan/bin/tRNAscan-SE -h
/share/nas1/yuj/software/miniconda3/envs/trnascan/bin/tRNAscan-SE -o tRNA.out -f tRNA.ss -m tRNA.stats sample.fasta
-o 输出的结果
-f 二级结构
-m 统计结果

# 默认情况下，不选择，-A -B -G 或 -O 参数，则适合于真核生物。
-A 适合于古细菌。该参数选择了古细菌特异性的协方差模型，同时稍微放宽了 EufindtRNA 的 cutoffs。
-B 适合于细菌。
-G 适合于古细菌，细菌和真核生物的混合序列。该参数使用 general tRNA 协方差模型。
-O 适合于线粒体和叶绿体。选择该参数，则仅使用 Cove 进行分析，搜索速度会很慢，同时也不能给出 pseudogenes 检测。

-i 使用 Infernal cm analysis only。该参数设置后，需要 cmsearch 命令，但是 tRNAscan-SE 软件包中貌似没有该程序，最终无法运行。
-C 仅使用 Cove 进行 tRNA 分析。虽然从一定程度上提高了准确性，但是会极慢，当然不建议了。

-a 生成ACeDB 格式的结果
-H 为输出一级和二级结构的分值
-q 为安静模式运行
-h 则为打印帮助信息
```

#  结果
1. 在真核生物中，tRNA由RNA聚合酶Ⅲ在核内转录生成pre-tRNA，再加工生成有功能的tRNA分子（一些tRNA序列中还含有内含子）。若tRNA存在内含子，则结果文件中第7、8列给出内含子区间，没有内含子则为0；
2. tRNAscan-SE的结果中，如果begin比end的值大，则表示tRNA在负义链（反义链、-）上；
3. 有些结果中第5列为pseudogene，这表示其一级或二级结构比较差；
4. 最后一列是Cove Score，最低阈值为20。该值是一个log ratio值。ratio是指符合tRNA covariance model概率与随机序列模型概率的比值；
5. 可以将表格格式的结果转换为gff格式，这样可以通过IGV可视化。

#  七、常见问题：

1、软件默认安装到HOME目录下，可以修改Makefile中的$HOME变量进行修改；
2、需要将程序目录添加到export PERL5LIB变量中，否则会提示找不到perl模块；
3、原始的输出结果只是列表形式的结果，需要自己从原始文件中提取出序列。

![[Pasted image 20221104152144.png]]