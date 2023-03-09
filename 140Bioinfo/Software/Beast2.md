---
title: Beast2
description: 
published: true
date: 2023-03-09T03:56:59.237Z
tags: 
editor: markdown
dateCreated: 2023-03-09T03:56:06.352Z
---

```bash

cd /share/nas1/yuj/software/zip_package

wget BEAST.v2.6.7.Linux.tgz #下载压缩包
wget BEAST_with_JRE.v2.6.7.Linux.tgz #下载压缩包

tar -zxvf BEAST.v2.6.7.Linux.tgz #解压缩
tar -zxvf BEAST_with_JRE.v2.6.7.Linux.tgz #解压缩

mv beast ../ && cd ..

echo 'PATH=$PATH:/share/nas1/yuj/software/beast/bin' >> ~/.bashrc #添加环境路径
source ~/.bashrc

beauti & #运行图形化界面



```
