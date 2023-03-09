> [!quote] "python使用国内源安装&pip使用代理下载&离线安装第三方库 - 简书." https://www.jianshu.com/p/69860e51189c, 访问时间 1 Jan. 1970.

# 1.更换国内镜像源
```txt
# 国内镜像	地址
# 清华大学	https://pypi.tuna.tsinghua.edu.cn/simple/
# 阿里云	http://mirrors.aliyun.com/pypi/simple/
# 豆瓣	http://pypi.douban.com/simple/
# 中国科学技术大学	http://pypi.mirrors.ustc.edu.cn/simple/
# 华中科技大学	http://pypi.hustunique.com/
```
## 1.1 临时方法
```bash
$ pip install pandas -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
```
## 1.2 永久方法
### 1.2.1 mac
```bash
mkdir ~/.pip
tee ~/.pip/pip.conf <<-'EOF'

[global]
index-url=https://pypi.tuna.tsinghua.edu.cn/simple
[install]
trusted-host=https://pypi.tuna.tsinghua.edu.cn
EOF
```
### 1.2.2 win
直接在user目录中创建一个pip目录，如：C:\Users\用户名\pip，然后新建文件pip.ini，即 %HOMEPATH%\pip\pip.ini，在pip.ini文件中输入以下内容：
> global下添加镜像源  
> timeout下设置超时时间  
> install下添加信任镜像源
```csharp
[global]
index-url = http://mirrors.aliyun.com/pypi/simple/
timeout = 100
[install]
trusted-host = mirrors.aliyun.com
```
### 1.2.3 Linux
修改 ~/.pip/pip.conf (没有就创建一个文件夹及文件。文件夹要加“.”，表示是隐藏文件夹)  
内容如下：
```csharp
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
[install]
trusted-host = https://pypi.tuna.tsinghua.edu.cn
```

...



