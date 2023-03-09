#Linux 

**`以腾讯云为例`**

## 1.FTP
### 1.1安装 vsftpd
```shell
1.  执行以下命令，安装 vsftpd。 
sudo yum install -y vsftpd
   
2.  执行以下命令，设置 vsftpd 开机自启动。  
sudo systemctl enable vsftpd

3.  执行以下命令，启动 FTP 服务。  
sudo systemctl start vsftpd

4.  执行以下命令，确认服务是否启动。  
sudo netstat -antup | grep ftp

//显示结果如下，则说明 FTP 服务已成功启动。  
[root@VM-4-7-centos ~]# netstat -antup | grep ftp
tcp        0      0 0.0.0.0:21              0.0.0.0:*               LISTEN      11272/vsftpd    

//此时，vsftpd 已默认开启匿名访问模式，无需通过用户名和密码即可登录 FTP 服务器。使用此方式登录 FTP 服务器的用户没有权修改或上传文件的权限。
```
### 1.2配置 vsftpd
```shell
1.  执行以下命令，为 FTP 服务创建用户，本文以 ftpuser 为例。  
sudo useradd ftpuser

2.  执行以下命令，设置 ftpuser 用户的密码。  
sudo passwd ftpuser

//输入密码后请按 **Enter** 确认设置，密码默认不显示。

3.  (选做)执行以下命令，创建 FTP 服务使用的文件目录，本文以 `/var/ftp/test` 为例。  
sudo mkdir /var/ftp/test

4.  (选做)执行以下命令，修改目录权限。  
sudo chown -R ftpuser:ftpuser /var/ftp/test

5.  执行以下命令，打开 `vsftpd.conf` 文件。   
sudo vim /etc/vsftpd/vsftpd.conf
```

    1. 修改以下配置参数，设置匿名用户和本地用户的登录权限，设置指定例外用户列表文件的路径，并开启监听 IPv4 sockets。
    
    anonymous_enable=NO
    local_enable=YES
    chroot_local_user=YES
    chroot_list_enable=YES
    chroot_list_file=/etc/vsftpd/chroot_list
    listen=YES
    
    2. 在行首添加 `#`，注释 `listen_ipv6=YES` 配置参数，关闭监听 IPv6 sockets。
    
    #listen_ipv6=YES
    
    3. 添加以下配置参数，开启被动模式，设置本地用户登录后所在目录，以及云服务器建立数据传输可使用的端口范围值。
    
    local_root=/var/ftp/test
    allow_writeable_chroot=YES
    pasv_enable=YES
    pasv_address=xxx.xx.xxx.xx #请修改为您的轻量应用服务器公网 IP
    pasv_min_port=40000
	pasv_max_port=45000

```shell
6.执行以下命令，创建并编辑 `chroot_list` 文件。  
sudo vim /etc/vsftpd/chroot_list

//按 i 进入编辑模式，输入用户名，一个用户名占据一行，设置完成后按 Esc 并输入 :wq 保存后退出。

//您若没有设置例外用户的需求，可跳过此步骤，输入 :wq退出文件。

7.  执行以下命令，重启 FTP 服务。 
sudo systemctl restart vsftpd
```

### 1.3设置安全组
- 主动模式：放通端口21。
- 被动模式：放通端口21，及修改`配置文件`中设置的 `pasv_min_port` 到 `pasv_max_port` 之间的所有端口，本文放通端口为40000 - 45000。


