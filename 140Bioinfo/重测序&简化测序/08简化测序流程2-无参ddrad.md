---
title: 08简化测序流程2-无参ddrad
description: 
published: true
date: 2023-03-09T03:57:49.597Z
tags: 
editor: markdown
dateCreated: 2023-03-09T03:57:17.088Z
---

# 主流程
```shell
没有参考基因组，直接根据序列聚类来做。
流程：
 配置文件：   perl /share/nas6/xul/program/ddrad/create_profile_for_ddrad.pl -n -i data/ 
             注意老师给的数据命名，自动生成的名字是文件名字前缀，老师可能另外要求了编号，-n 表示无参，-i 输入所有测序数据所在的所有目录。如果老师重新命名，可以自己编写了对照表，第一列是老的名字，第二列是新的名字，一一对应，然后 -l 参数修改生成配置文件中的名字。
         
  主流程： 
        nohup perl /share/nas6/zhouxy/pipline/stacks-seq/current/stacks.pip.v2.pl -i ddrad_config.yaml -o analysis & 
   
  整理结果：
        perl /share/nas6/xul/program/ddrad/get_result_noref.pl  analysis complete_dir
   
  报告：
        cp /share/nas6/xul/program/ddrad/html_for_ddrad_noref/ddrad_noref_report.cfg . && realpath ddrad_noref_report.cfg
        perl /share/nas6/xul/program/ddrad/html_for_ddrad_noref/ddrad_noref_report.pl -id  complete_dir -cfg ddrad_noref_report.cfg
```

# 无参简化指纹图
```shell
主流程：
          perl /share/nas6/zhouxy/pipline/kasp/kasp-develop/v1.1/kasp-develop_ddrad_with_noref.pl -v samples.pop.snp.recode.vcf -g ../stacks_stat/consensus/tags.consensus.fa
          1，按照深度(10x）、标记完整度（0。9）、maf（0.05）过滤
          2，按照比对NR库上的序列过滤，保留比对上NR库的
          3，按照PIC（0.35）过滤。
          4，kasp引物设计
          5，指纹图

        注：如果第一步后标记很多，第二步后标记很少，可以增加第一步参数，跳过第二步。
整理结果：
        perl /share/nas6/zhouxy/pipline/kasp/kasp-develop/v1.1/bin/resultsdir/resultsdir_ddrad_with_noref.pl -i kasp_analysis -o kasp_result

报告：
         cp  /share/nas6/zhouxy/pipline/kasp/kasp-develop/v1.1/html_report/kasp_report.cfg . && realpath  kasp_report.cfg
         perl /share/nas6/zhouxy/pipline/kasp/kasp-develop/v1.1/html_report/kasp_ddrad_with_noref_Web_Report.pl -id kasp_result/ -cfg kasp_report.cfg
```