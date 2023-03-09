
```shell

for i in `ls *.fasta`;do echo $i; perl misa.pl $i ${i%.fasta};done

```