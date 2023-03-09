> "shell脚本文本替换_一只懒惰的程序猿的博客-CSDN博客_shell替换文本内容." https://blog.csdn.net/bluewait321/article/details/110643279, 访问时间 1 Jan. 1970.

# 项目应用
## 目标文件文本替换
```SHELL
for i in `cat ori.list`;do echo "${i//.1_/_1_}"; done > newfullbi.list

# 以下会直接改变原文件
perl -pi -e 's/.1_/_1_/g' ori.list 
sed -i 's/.1_/_1_/g' ori.bak
```
## sed用法
```bash
sed -i 's/目标字符串/替换字符串/g' 目标文件
```
## perl用法
```bash
# 字符串不包含/ 
perl -pi -e "s/目标字符串/替换字符串/g" 目标文件 
# 字符串包含/ 则改成# 
perl -pi -e "s#目标字符串/替换字符串/g" 目标文件
```

# 复杂字符串替换
```shell
1.
grep -n "目标字符串" 目标文件 | awk -F ":" '{print $1}'
或 sed -n "aaaa" test.txt

2.
sed "67d" test.txt
或 perl -ni -e "print unless $. == 67" test.txt

3.
sed "67c replaceString" test.txt
或 perl -pi -e "print 'replaceString' if $. == 67" test.txt
```

# 纯shell实现文本替换
注意：bash 5.1.16版本下测试生效，5.0版本下貌似不生效
```bash
echo hello | while read -r str; do echo "${str//l/n}"; done
```

```bash
echo hello | (read -r str; echo "${str//l/n}")
```






