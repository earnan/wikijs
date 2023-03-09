> [!info] 效果
> 创建出一个虚拟的shell，在任何时候都可以在随便一个shell窗口里连接这个虚拟shell
> 跑在虚拟shell中的任务，只要虚拟shell没被杀死，就会一直跑

![[Pasted image 20220906103036.png]]

```shell
0.简介

1.创建test窗口
screen -S test

2.将test窗口变为detached状态
screen -d test/pid 
# 等同于在test窗口内 ctrl+a,输入d   test会变为detached状态

3.查看会话状态
screen -ls 
# Attached detached 两种状态

4.恢复会话
screen -r pid 
# 会话须先处于detached状态

5.重命名
   5.1 方法1
   screen -r xxx
   Press [Ctrl]+[A]
   Type `:sessionname xxxx`
   Type [Enter]
   5.2 方法2
   screen -S {pid.xxx}  -X sessionname {xxx}
   
6.完全退出窗口
   6.1 没有重命名的直接可以
   screen -S test/pid -X quit   
   screen -X -S test/28508 quit
   # 等同于 在test界面输入exit 
   # 等同于 在test界面Ctrl+d
   6.2 重命名的，需要带上id删

7.清除dead状态窗口
screen -wipe
```

# Screen命令中用到的快捷键
-   Ctrl+a c ：创建窗口
-   Ctrl+a w ：窗口列表
-   Ctrl+a n ：下一个窗口
-   Ctrl+a p ：上一个窗口
-   Ctrl+a 0-9 ：在第0个窗口和第9个窗口之间切换
-   Ctrl+a K(大写) ：关闭当前窗口，并且切换到下一个窗口（当退出最后一个窗口时，该终端自动终止，并且退回到原始shell状态）
-   exit ：关闭当前窗口，并且切换到下一个窗口（当退出最后一个窗口时，该终端自动终止，并且退回到原始shell状态）
-   Ctrl+a d ：退出当前终端，返回加载screen前的shell命令状态































