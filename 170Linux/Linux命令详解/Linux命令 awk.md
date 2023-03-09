#Linux  #linux命令

# awk概述

相当于一种编程语言,把awk看成perl或python来理解
一行代码操作
```shell
awk '{pattern + action}' {filenames}
```

![[Pasted image 20220630103505.png]]

# 项目应用
> len.txt文件示例：
> 90870 1
> 16664 2
## 显示每行第一个字段(默认会以` `为分隔符)
```shell
$ awk -F " " '{ print $1 }' len.txt 
$ awk  '{ print $1 }' len.txt 

90870
16664
```
## 查找关键字所在行(匹配任意关键字) - 或操作
```shell
$ awk '/str1|str2/str3/' filename

# 输出行号，并不输出内容 
# 注意是单引号 
$ awk '/要匹配字符串/{print NR}' 文件名
```
## 对第一个字段计数
```shell
$ awk 'BEGIN {n=0;count=0} {count=count+$1;print $1;n=n+1} END{print "count/n is ",count,n;print "adv is",count/n;}' len.txt

# 例1
$ awk 'BEGIN {n=0;count=0;print "[start] count is ",count} {count=count+$1;print $1;n=n+1} END{print "[end] count/n is ",count,n;print "adv is",count/n;}' len.txt

[start] count is  0
90870
16664
[end] count/n is  107534 2
adv is 53767

# 例2
$ awk 'BEGIN {count=0;print "[start] user count is ",count} {count=count+$1;print $1} END{print "[end] user count is ",count;print "adv is",count/2;}' len.txt 

[start] user count is  0
90870
16664
[end] user count is  107534
adv is 53767
```
## 求第一个字段的极值
```shell
# 求最大值
$ awk  'BEGIN {max = 0} {if ($1+0 > max+0) max=$1} END {print "Max=", max,"bp"}' len.txt 

# 求最小值
$ awk 'BEGIN {min = 100000} {if ($1+0 < min+0) min=$1} END {print "Min=", min,"MB"}' len.txt
```

# 其他实例
## 实例一：只查看test.txt文件（100行）内第20到第30行的内容（企业面试）

```shell
awk '{if(NR>=20 && NR<=30) print $1}' test.txt
```

## 实例二：已知test.txt文件内容为：

```shell
$ cat test.txt
I am Poe,my qq is 33794712

# 请从该文件中过滤出'Poe'字符串与33794712，最后输出的结果为：Poe 33794712

$awk -F '[ ,]+' '{print $3" "$7}' test.txt

Poe 33794712
```
