**`20220329`**
```python
CRLF/LF问题:
以二进制方式写入文件
with open(file, 'wb') as f:
写入的字符串要转换成字节
f.write(str.encode())
```


**`20220608`**
```python
seq = 'CTATTTTTAA\n'
print(seq.index('\n'))
last = seq[-2:] #预计取出AA
print(last)  #实际上从显示效果来看只有一个A
```
> 实际上取出的是'A\n'   看起来就像是bug  因此要去掉末尾的换行