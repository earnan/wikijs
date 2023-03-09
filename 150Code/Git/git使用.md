---
title: git使用
description: 
published: true
date: 2023-03-09T03:57:52.772Z
tags: 
editor: markdown
dateCreated: 2023-03-09T03:57:21.619Z
---

# 仓库初始化与远程连接
```bash
1.创建远程仓库,复制链接地址 https://github.com/earnan/Obsidian.git
	不勾选readme
2.vs打开对应文件夹并初始化存储库
3.对应文件夹内打开git bash,输入以下命令
	git remote add origin https://github.com/earnan/Obsidian.git
	//git pull origin master 不用
4.暂存--提交--推送(第一次为发布分支)或同步更改
```

# FAQ
## fatal detected dubious ownership in repository at
```bash
原因:
更新或重装git导致

解决:
$ git config --global --add safe.directory /问题目录

# 如果仍有其他问题可以考虑把目录下的所有内容都添加到信任列表：
$ git config --global --add safe.directory "*"
```

# git新分支
```bash
1.从现有源创建新分支
2.推送分支的选择:
   - 签出选择本地的仓库,相当于上锁,先修改
   - 签入相当于解锁,上传修改
```

# 同步方案
**优先级 onedrive>编辑软件>git同步**
