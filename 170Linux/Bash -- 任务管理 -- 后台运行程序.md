> [!cite] https://blog.csdn.net/qq_36955294/article/details/122114188
> 效果：关掉shell窗口，程序还会在后台继续运行
# nohup/setsid  \*.sh  &
```shell
$ echo $$ 
21734  
$ nohup ./test.sh & # ok
[1] 29016  
$ ps -ef | grep test 
515      29710 21734  0 11:47 pts/12   00:00:00 /bin/sh ./test.sh 
515      29713 21734  0 11:47 pts/12   00:00:00 grep test 

$ setsid ./test.sh & # ok
[1] 409  
$ ps -ef | grep test 
515        410     1  0 11:49 ?        00:00:00 /bin/sh ./test.sh 
515        413 21734  0 11:49 pts/12   00:00:00 grep test

$ (./test.sh &)  # 等同setsid
$ ps -ef | grep test 
515        410     1  0 11:49 ?        00:00:00 /bin/sh ./test.sh 
515      12483 21734  0 11:59 pts/12   00:00:00 grep test
```

# 当前shell中已经在后台运行的进程（之前没加nohup） 使用disown
```shell
$ ./test.sh & 
[1] 2539  
$ jobs -l 
[1]+  2539 Running                 ./test.sh &  
$ disown -h %1  # ok
$ ps -ef | grep test 
515        410     1  0 11:49 ?        00:00:00 /bin/sh ./test.sh 
515       2542 21734  0 11:52 pts/12   00:00:00 grep test
```

注：本文试验环境为Red Hat Enterprise Linux AS release 4 (Nahant Update 5),shell为/bin/bash，不同的OS和shell可能命令有些不一样。例如AIX的ksh，没有disown，但是可以使用**nohup -p PID**来获得disown同样的效果。
