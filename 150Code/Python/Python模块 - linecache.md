linechche是用来读取文件的，他与传统的f = open('./test.txt','r')相比，当所需读取的文件比较大时，linecache将所需读取的文件加载到缓存中，从而提高了读取的效率。

1.最常用的方法1：getline(filename, lineno[, module_globals])

```lua
content = linecache.getline(path,line_index)
```

获得path文件的第line_index行的内容。

2.最常用的方法2：getlines(filename)

```lua
contents = linecache.getlines(path)
```

获得path文件的所有行的集合。

3.linecache.clearcache() ，清除现有的文件缓存。

4.linecache.checkcache([filename]) ，参数是文件名，作用是检查缓存内容的有效性，可能硬盘内容发生了变化，更新了，如果不提供参数，将检查缓存中所有的项。