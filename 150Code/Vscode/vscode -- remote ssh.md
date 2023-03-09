> [!cite] 
> "vscode连接服务器进行远程开发调试 - 知乎." https://zhuanlan.zhihu.com/p/565986817, 访问时间 1 Jan. 1970.

> [!cite] 
> "vscode配置remote ssh_Hello_wshuo的博客-CSDN博客_remote ssh vscode." https://blog.csdn.net/chouzhou9701/article/details/125072235, 访问时间 1 Jan. 1970.

# 1. 安装ssh（git自带的）
0.安装ssh到`D:\Program Files\Git`目录下
1.卸载windows自带的OpenSSH
2.我的电脑->属性->高级系统设置->环境变量->系统变量->path
添加`D:\Program Files\Git\usr\bin\`

# 2. 安装remote development
打开vscode，搜索扩展remote development，这一步会下载多个扩展，相互依赖
![[Pasted image 20221210133727.png]]

# 3. 添加远程服务器
## 3.1 编辑配置文件
### 3.1.1 （二选一）
点击左下角图标，`connect current window to host` -> `+ add new ssh host` -> 键入ssh usr@ip（换成自己的）
![[Pasted image 20221210112925.png]]
### 3.1.2 （二选一）
选择一个文件作为存储：
![[Pasted image 20221210134040.png]]
编辑内容如下（示例）:
```shell
# C:/Users/用户名/.ssh/config
Host 192.168.1.200
  HostName 192.168.1.200
  User yuj
```
### 3.1.3 注意事项
> [!attention] 注意
>如果你选择的文件没有访问权限，是无法显示出连接的，这里可能需要修改一下文件夹或文件的权限：
>![[Pasted image 20221210134738.png]]
>点击编辑，设置完全控制权限：
>![[Pasted image 20221210134829.png]]

## 3.2 连接服务器
点击按钮开始连接，首次登录需要输入密码
![[Pasted image 20221210133023.png]]
连接成功，如图所示
![[Pasted image 20221210135947.png]]

# 4. 配置无密码登录
每次连接服务器，或者打开文件夹都需要输入一遍密码，很麻烦。
`bash ssh-keygen -t rsa -b 4096`
一路回车
将用户目录下的`.ssh/id_rsa.pub` 文件内容上传到服务器的`~/.ssh` 下并且命名为 `authorized_keys`
需要开启sshd服务的 公钥认证选项：
`/etc/ssh/sshd_config`:
`PubkeyAuthentication yes`
