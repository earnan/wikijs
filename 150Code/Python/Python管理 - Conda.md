# 1.conda安装

## 1.1 Linux安装Miniconda
**官网地址: https://docs.conda.io/en/latest/miniconda.html**
```shell
wget -c https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

sh Miniconda3-latest-Linux-x86_64.sh 
# 安装过程中点enter，选择yes

# 如果有需要请将conda环境加入自己的环境变量，否则直接运行conda不会有任何反应
# export PATH=$PATH:/home/miniconda3/bin
```
1)  出现选项时敲击“Enter”查看license agreement；  
2）查看完license agreement后，需要输入“yes”表示接受才能继续；  
3）需要确认安装路径，可以使用”Enter键”确认或更改安装目录；  
4）经过1-2分钟安装完成后，需要同意安装器是否初始化miniconda，需要输入“yes”同意后，miniconda的“PATH”才能加入到~/.bashrc ；  
5）source ~/.bashrc 配置到环境中方便调用。  
在source之后可以使用命令 conda -V 查看Minconda3 的版本以用来检验是否安装并配置成功，也可以输入vim ~/.bashrc查看是否配置到环境中，配置成功则如下图  
![](https://img-blog.csdnimg.cn/3b313d3bf1394431a2d89d6d745a8f5f.png)

## 1.2 Windows安装Miniconda
**北外镜像地址: https://mirrors.bfsu.edu.cn/anaconda/miniconda/?C=M&O=A**
其中首选项界面说明如下：
-   第一个选项是将anaconda加到环境变量（Add Anaconda to my PATH environment variable）中，建议勾选，如不勾选的话，安装成功后记得将anaconda加到环境变量中（安装目录;安装目录\Scripts;安装目录\Library\bin，例如：C:\mysoft\Miniconda3;C:\mysoft\Miniconda3\Scripts;C:\mysoft\Miniconda3\Library\bin）；
-   第二个选项是将anaconda注册为默认的python环境（Register Anaconda as my default Python xx），如果电脑中已安装python环境，不建议勾选此项，如果没安装过，可以勾选此项。

# 2.conda创建环境
> [!tip]
> 常用conda命令:
> https://zhuanlan.zhihu.com/p/363904808

```shell
# 安装
$ conda create -n xxx -y # y表示一路确认
$ conda create --name xxx python=3.x # 指定python版本

# 激活
$ conda activate xxx

# 安装package
$ conda install -n xxx numpy # -n指定环境
$ conda install -c bioconda trnascan-se # -c指定通过某个channel安装
$ conda install numpy # 当前活跃环境

# 当前环境查看已经安装的packages
$ conda list

# 退出
$ conda deactivate

# 查看安装的环境
$ conda info -e
# 本地复制环境
$ conda create -n BBB --clone AAA
# 移植远程环境（pip需要重新安装）
$ conda create -n BBB --clone ~/path
# 删除一个已有的环境
$ conda remove --name xxx --all
# 查看某个指定环境的已安装包
$ conda list -n xxx
# 删除package
$ conda remove -n xxx numpy # 指定环境

# 更新package
$ conda update -n xxx numpy # 指定环境
# 更新conda，保持conda最新
$ conda update conda
# 更新anaconda
$ conda update anaconda
# 更新python
$ conda update python
# 更新所有包
$ conda upgrade --all

# 添加清华镜像源
$ conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/ 
$ conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
# 设置搜索时显示通道地址
$ conda config --set show_channel_urls yes
```
> [!info]
> 安装4.6.14版本，4.6.14版本可以在Step2输入yes，然后在Step4就会发现.bashrc文件已经写好初始化变量，source ~/.bashrc之后运行conda config --set auto_activate_base false来默认不激活base环境
> ```bash
> # 将anaconda的bin目录加入PATH
> echo 'export PATH="~/miniconda3/bin:$PATH" '>> ~/.bashrc
># 更新bashrc以立即生效
> source ~/.bashrc
> ```

# 3.shell脚本里调用conda
> [!quote] "在脚本里面调用conda创建的环境 - 简书." https://www.jianshu.com/p/0d9a738ca2dd, 访问时间 1 Jan. 1970.

## 3.1方法1
> [!quote] "Can't execute `conda activate` from bash script · Issue #7980 · conda/conda · GitHub." https://github.com/conda/conda/issues/7980, 访问时间 1 Jan. 1970.

在脚本中多加一句
```bash
source $HOME/miniconda/etc/profile.d/conda.sh
```
注意，我的conda是安装在家目录下的miniconda目录中，对于非家目录的安装方式，要修改 `$HOME/miniconda`。

## 3.2方法2
我们可以通过 `conda run` 来运行给定环境下的命令，假如，我们安装了一个环境rna-seq, 里面有一个程序叫做STAR, 我们可以随便写一个tmp.sh脚本，内容为
```bash
conda run -n rna-seq STAR --help
```
那么，此时运行 bash tmp.sh 就不会报错。也就是说，你并不是一定要用conda activate 启动环境，才能调用命令，你其实可以调用某个环境的给定指令。
> [!tip] 方法2相对于方法1有个非常大的优势，那就是，如果你有多个不同python版本的环境，你不用担心写脚本的时候写了启动，但是忘了写退出。你只需要在原来的代码前加上一句， `conda run -n 环境名`。

# 4.取消Conda bash默认启动
```shell
1.修改config
$ conda config --set auto_activate_base false

2.次级方案
$ vim ～/.bashrc
	加入conda deactivate
	:wq
$ source ～/.bashrc
```


