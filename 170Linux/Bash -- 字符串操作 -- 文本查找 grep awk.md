# 一.grep
```shell
$ grep -A|B|C n -i 'parttern' file 
-A 表示在字符串之后 after  context
-B 表示在字符串之前 before context
-C 表示在字符串前后
-i 忽略小写
n：要获取多少行文本 line number
parttern：为要查找的字符串
file：文件名

# 打印匹配行的前后10行
$ grep -10 'parttern' file
$ grep -C 10 'parttern' file
$ grep -A 10 -B 10 -i 'parttern' file

# 打印匹配行的后5行
$ grep -A 5 'parttern' file

# 打印匹配行的前5行
$ grep -B 5 'parttern' file

$ grep -A 1 -i 'nd5' /share/nas1/yuj/project/GP-20220920-4939_20221107/1/ref_tre/out/cds/cds_DQ157700.1.fasta
>Ustilago_maydis_DQ157700 [46103..46811;47906..49221] [gene=ND5]
ATGTATCTATCACTTCTACTACTACCAATGTTTGGATCTGCTGTTACAGGTCTACTAGGACG
```

# 二.grep awk对比
> [!cite]
> "linux指令-查找字符串所在行，输出行号 - 破茧之初 - 博客园." https://www.cnblogs.com/d0minic/p/16370345.html, 访问时间 1 Jan. 1970.

查找某个字符串所在行，可以用grep或awk来解决。
二者最大区别是，
grep的结果是输出匹配内容的同时输出其所在行号；
awk可以仅输出行号，不输出匹配内容。
按需选择。
## 【模糊匹配】输出行号
```shell
grep
# 输出内容同时输出行号
$ grep -n "要匹配的字符串" 文件名

awk
# 输出行号，并不输出内容
# 注意是单引号
$ awk '/要匹配字符串/{print NR}' 文件名
```
## 【精确匹配（全匹配）】输出行号
```shell
grep
$ grep -wn "要匹配的字符串" 文件名
其中 grep -w 是完全匹配要匹配的字符串

awk
# 匹配以逗号为分隔（如csv）的第三列/第三个字段，打印行号
$ awk -F, '$3=="要匹配的字符串" {print NR}' 文件名
# 匹配以逗号为分隔（如csv）的第三列/第三个字段,打印该行内容 写{print}或{print $0}
$ awk -F, '$3=="要匹配的字符串" {print}' 文件名
# 如果非要过滤到单词，可以根据单词的格式不同，利用正则表达式来灵活具体得精确匹配。
$ awk "/要匹配字符串/{print NR}" 文件名
```