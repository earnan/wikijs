# 添加echo,命令不生效
```shell
$ for i in {1..11};do echo sed -i  "'s/0\tGardenia$i:/$i\tGardenia$i:/g'" samples.plink.map;done > sed.sh # 显示ok
# 显示效果:sed -i 's/0\tGardenia1:/1\tGardenia1:/g' samples.plink.map

$ for i in {1..38};do if [ $(($i%2)) -eq 0 ];then echo sed -n "'"$i"p'" rps3_all.fa;fi;done
# 显示效果:sed -n '2p' rps3_all.fa
```

# 未加echo,命令生效
```shell
$ for i in {1..38};do if [ $(($i%2)) -eq 0 ];then sed -n ""$i"p" rps3_all.fa;fi;done
# 直接运行该命令

$ for i in {1..38};do if [ $(($i%2)) -eq 0 ];then query=`sed -n ""$i"p" rps3_all.fa`;echo $query;fi;done
# ATGCTTTTTTT

$ for i in {1..38};do if [ $(($i%2)) -eq 0 ];then sed -n ""$i"p" rps3_all.fa > $i"_rps3";blastn -query $i"_rps3" -subject *.fsa -outfmt 6;fi;done
# Query_1	Ustilago_esculenta_MT10	76.153	759	130	24	71	799	138126	137389	1.23e-98	351
# Query_1	Ustilago_esculenta_MT10	100.000	765	0	0	1	765	138145	137381	0.0	1413
```

