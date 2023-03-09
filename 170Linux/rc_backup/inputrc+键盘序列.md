---
title: inputrc+键盘序列
description: 
published: true
date: 2023-03-09T03:58:04.920Z
tags: 
editor: markdown
dateCreated: 2023-03-09T03:57:37.812Z
---

# inputrc
```text

~/.inputrc
 
set completion-ignore-case on  
set show-all-if-ambiguous on  
"\e[A":history-search-backward   #定义上箭头为根据已键入内容向前搜索命令历史  
"\e[B":history-search-forward        #定义下箭头为根据已键入内容向后搜索命令历史

不知道有多少linuxer在敲命令的时候,由于不得不按shift而十分蛋疼,今天无意中google了一下,终于找到了
解决方案:inputrc"文件

一般情况是,在我们的home目录下是没有这个文件的,所以我们就自己建一个“.inputrc”文件,然后把以下文字粘贴过去,就ok了:

#关掉match-hidden-files不显示隐藏文件,特别是当你在home目录时,你会觉得眼前好干净。
set match-hidden-files off

#默认情况下,按下两次<tab>才会出现提示,show-all-if-ambiguous开启后,只需要一次了。
set show-all-if-ambiguous on

#开启completion-ignore-case 忽略大小写
set completion-ignore-case on 

通过以上设置,我们就可以看到这样的改变:
1.当我们的目录下有一个叫Public的目录,我们输入cd pub然后按下tab,系统一样可以自动补全,并适当的替换大小写打印匹配列表
2.当我们在home目录下,输入ls然后按下一次tab时,就可以显示所有目录(默认是有隐藏目录的,现在都没有了)
3.所有的隐藏文件不会再提示,即我们在home目录下输入ls,'.'开头的所有文件都不会显示,果然清爽了很多。当我们需要为当前的隐藏文件生成提示时,只需要输入ls..然后按下tab就可以了
```

# 键盘序列

|ESC|F1 |F2 |F3 |F4 |F5 |F6 |
|---|---|---|---|---|---|---|
|`^[` | `^[OP`  | `^[OQ`  |`^[OR`  |`^[OS`  |`^[[15~` |`^[[17~` |

|F7 |F8|F9 |F10 |F11|F12|
|---|---|---|---|---|---|
|`^[[18~` |`^[[19~` |`^[[20~` |`^[[21~` |`^[[23~` |`^[[24~` |

|INSERT|HOME|PAGE UP|
|---|---|---|
|`^[[2~`|`^[[1~`|`^[[5~`|

|DELETE|END|PAGE DOWN|
|---|---|---|
|`^[[3~`|`^[[4~`|`^[[6~`|

`^[[A上`
`^[[D左   ^[[B下   ^[[C右`







