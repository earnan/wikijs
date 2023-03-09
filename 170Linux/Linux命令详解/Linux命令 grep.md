
> https://blog.csdn.net/lovedingd/article/details/116532053

# 1.grep命令搜索多个字符串

```shell

# 拓展正则表达式   -E(--extended-regexp)
$ grep -E 'fatal|error|critical' /var/log/nginx/error.log

# 忽略大小写 -i (--ignore-case)
$ grep -i 'fatal|error|critical' /var/log/nginx/error.log 

# 全词匹配
$ grep -w 'fatal|error|critical' /var/log/nginx/error.log

```

# 2.grep同时匹配多个关键字或任意关键字

## 2.1 与操作
> grep pattern1 files | grep pattern2 ：显示既匹配 pattern1 又匹配 pattern2 的行。
```perl
grep word1 file.txt | grep word2 |grep word3
```
必须同时满足三个条件（word1、word2和word3）才匹配。

## 2.2 或操作
grep匹配任意关键字
```delphi
grep -E 'str1|str2|str3' filename //找出文件（filename）中包含str1或者包含str2或者包含str3的行
```
egrep实现
```delphi
egrep 'str1|str2|str3' filename //用egrep同样可以实现
```
awk实现
```delphi
awk '/str1|str2/str3/' filename  //awk 的实现方式
```

### 2.3其他操作
```perl
grep -i pattern filename # 不区分大小写地搜索。默认情况区分大小写
grep -l pattern filename # 只列出匹配的文件名
grep -L pattern filename # 列出不匹配的文件名
grep -w pattern filename # 只匹配整个单词，而不是字符串的一部分（如匹配‘magic’，而不是‘magical’）。
```
