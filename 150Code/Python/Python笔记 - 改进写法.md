"🐮！这15个技巧直接让你的Python性能起飞🚀 - 掘金." https://juejin.cn/post/7066429930380197895
## 1.使用`map()`进行函数映射
```python
newlist = []
for word in oldlist:
    newlist.append(word.upper())

list(map(str.upper, oldlist))
```
## 3.使用`sort()`或`sorted()`排序
```python
# 学生：（姓名，成绩，年龄） 
students = [('john', 'A', 15),('jane', 'B', 12),('dave', 'B', 10)] 
students.sort(key = lambda student: student[0]) #根据姓名排序 
sorted(students, key = lambda student: student[0])
```
## 4.使用collections.Counter()计数
```python
# 统计字符串中每个字符出现的次数。
sentence='life is short, i choose python'。
from collections import Counter
Counter(sentence)
```
## 6.使用 join() 连接字符串
```python
# 将字符串列表中的元素连接起来。
oldlist = ['life', 'is', 'short', 'i', 'choose', 'python']。
"".join(oldlist)
```
## 10.减少点运算符(.)的使用
```python
# 点运算尽量移到循环外
oldlist = ['life', 'is', 'short', 'i', 'choose', 'python']。

# 方法一
newlist = []
for word in oldlist:
    newlist.append(str.upper(word))

# 方法二
newlist = []
upper = str.upper
for word in oldlist:
    newlist.append(upper(word))
```
## 12.使用`Numba.jit`加速计算
```python
# 求从 1 加到 100 的和。

# 方法一
def my_sum(n):
    x = 0
    for i in range(1, n+1):
        x += i
    return x

# 方法二
from numba import jit
@jit(nopython=True) 
def numba_sum(n):
    x = 0
    for i in range(1, n+1):
        x += i
    return x
```
## 13.使用`Numpy`矢量化数组
```python
# 两个长度相同的序列逐元素相乘。
a = [1,2,3,4,5], b = [2,4,6,8,10]

# 方法1
[a[i]*b[i] for i in range(len(a))]

# 方法2
import numpy as np
a = np.array([1,2,3,4,5])
b = np.array([2,4,6,8,10])
a*b
```