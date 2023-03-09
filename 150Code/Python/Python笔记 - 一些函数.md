# 字典

> [!info] 合并字典 20221116
```python
dict_1 = {'a': 1, 'b': 2} 
dict_2 = {'c': 3, 'd': 4} 
# 合并字典 
merged_dict = {**dict_1, **dict_2}
```

> [!info] 字典排序    20221018
```python
product_prices = {'Z': 9.99, 'Y': 9.99, 'X': 9.99}
print({key:product_prices[key] for key in sorted(product_prices.keys())})
{'X': 9.99, 'Y': 9.99, 'Z': 9.99}
# 按照 key 
# 这个严格来说是对列表的排序

all_seq_id_dict = copy.deepcopy(dict(sorted(all_seq_id_dict.items(), key=lambda x: x[0], reverse=False)))
# 键排序 key=lambda x: x[0]
# 值排序 key=lambda x: x[1]
# 对字典的items()排序,x指代item(),x[0]代表键,x[1]代表值,然后转换成字典,利用深拷贝彻底改变原字典
```

# 列表

> [!info] 列表元素筛选 20221116
```python
my_list = [10, 11, 12, 13, 14, 15] 
# 选出所有偶数 
print(list(filter(lambda x: x%2 == 0, my_list )))
```

# 其他

> [!info] 动态生成变量    20221011
```python
createVar = locals()
listTemp = range(1,10)
for i,s in enumerate(listTemp):
	createVar['a'+i] = s
print a1,a2,a3
```

> [!info] 程序退出    20220831
```python
# 正常退出
sys.exit(0)
```

>[!info] zip()函数    20220826
```python
# 以鞋子品牌和价格为例，创建两个列表
shoes = ["huili", "lining", "anta", "tebu"]
price = [20, 10, 50, 40]
# 将品牌跟价格合在一起
shoes_price = zip(shoes, price)
# 使用list()转为列表形式
print(list(shoes_price))
print(shoes_price)
print(type(shoes_price))

# 按x[1]也就是按价格排序，若是x[0]则是按品牌排序
# 若是(x[1],x[0])，则表示先按价格再按品牌排序
sorted_shoes_price = sorted(shoes_price,key=lambda x:x[1])
# 将排序好的列表分出来并打印
result = zip(*sorted_shoes_price)

sorted_shoes, sorted_price = [list(x) for x in result]
print(sorted_shoes)
print(sorted_price)
```

>[!info] python中的pop()函数
```python
语法：

列表 list.pop(obj=list[-1])
pop()用于删除并返回列表中的一个元素（默认为最后一个元素）
obj：要删除并返回的列表元素

字典dict.pop(key[,default])
pop()用于删除字典中给定的key及对应的value，返回被删除key对应的value，key值必须给出。
给定的key值不在字典中时，返回default值。

key:需要删除的key值（不给出会报错）
default:若没有字典中key值，返回default值（给定的key值不在字典中时必须设置，否则会报错）
```

>[!info]  用户输入一个字符串，请将字符串中的所有字母全部向后移动一位，最后一个字母放到字符串开头，最后将新的字符串输出
```python
#网上的教程
arr=[],r=""
m=input("请输入")
for string in m:
    arr.append(string)
last=arr[-1]#最后一个元素
arr.insert(0,last)#最后一个元素 插入到开头0
arr.pop()#弹出最后一个元素
for str in arr:
    r+=str
print(r)

#我的
m=input("请输入")
last=m[-1]
print(last+m.rstrip(last))
如果m末尾有连续相同的last字符,那么m.rstrip(last)会把所有last去掉
换言之,这样就会出现bug
```

>[!info]  print 输出对齐        字符串.ljust(width)
```python
当需要打印如上左对齐的形式是，我们可以通过s.ljust() 之类的函数来处理。  
（1）S.ljust(width,[fillchar])
其中，width 表示对齐的字符数，fillchar 表示空格部分可以用过给定的单个字符来填充，默认是空格。ljust中第一个字母‘l’代表左对齐，不足部分用fillchar填充，默认的为空格。
类似地，S.rjust(width,[fillchar]) # 右对齐，
S.center(width, [fillchar]) # 中间对齐
```
![在这里插入图片描述](https://img-blog.csdnimg.cn/e7d909dceb184aa3848cc37b85a65878.png?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBAZmVpeXU2OA==,size_20,color_FFFFFF,t_70,g_se,x_16)


