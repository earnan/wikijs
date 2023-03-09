> [!info] `# IDs of nodes:((li<0>,((taozi<2>,Pmu<4>)<3>,pipa<6>)<5>)<1>,pingguo<8>)<7>`    20221011
```python
1.re.search 查找符合模式的字符，只返回第一个，返回Match对象
letter = (re.search(r'[A-Z]', name1.split('-')[0])).group(0)
result: P

2.re.findall 返回所有匹配的字符串列表
letter = re.findall(r'[a-zA-Z]', name1.split('-')[0])
result: ['l', 'i', 't', 'a', 'o', 'z', 'i', 'P', 'm', 'u', 'p', 'i', 'p', 'a', 'p', 'i', 'n', 'g', 'g', 'u', 'o']

letter = re.findall(r'[a-zA-Z]+', name1.split('-')[0])
result: ['li', 'taozi', 'Pmu', 'pipa', 'pingguo']

```



