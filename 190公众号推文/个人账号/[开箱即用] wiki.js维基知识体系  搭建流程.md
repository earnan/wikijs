```shell
wget https://github.com/Requarks/wiki/releases/latest/download/wiki-js.tar.gz
mkdir wiki
tar xzf wiki-js.tar.gz -C ./wiki
cd ./wiki
mv config.sample.yml config.yml

sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm  
sudo yum install -y postgresql14-server  
sudo /usr/pgsql-14/bin/postgresql-14-setup initdb  
sudo systemctl enable postgresql-14  
sudo systemctl start postgresql-14

systemctl status postgresql-14

安装node.js

vim config.yml # 填用户 密码

vim /var/lib/pgsql/14/data/pg_hba.conf # 改认证  trust

systemctl restart postgresql-14
psql -U postgres
	create database wiki;
	alter user postgres with password 'postgres';
	\q退出

node server

不小心关闭了，就进入 wiki目录后启动node server







```