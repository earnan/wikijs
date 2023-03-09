# 编码
## urlencode()
将存入的字典（或 元素为元组的列表）参数编码为URL查询字符串，即转换成以key1=value1&key2=value2的形式
```python
from urllib.parse import urlencode
params1={}
s=urlencode(params1, encoding='gb2312') # 默认为utf8的编码，指定编码：urlencode(data,encoding='gbk')
print(s)
```
## quote()
对url单个字符串进行编码
```python
from urllib.parse import quote
s=''
s=quote(s)
print(s)
```
# 解码
## unquote()
解码——urllib提供了unquote()这个函数
```python
# 对单字符串解码
from urllib.parse import unquote
s='%E5%B9%BF%E5%B7%9E'  
s=unquote(s)
print(s)

# 对拼接字符串解码
from urllib.parse import unquote
s='name=%E7%8E%8B%E4%BA%8C&extra=%2F&special=%26&equal=%3D'
s=unquote(s)
print(s) # 'name=王二&extra=/&special=&&equal=='
```
