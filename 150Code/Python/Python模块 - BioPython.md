`D:\ProgramData\Anaconda3\Lib\site-packages\Bio`
`D:\ProgramData\Anaconda3\lib\site-packages\Bio\GenBank\__init__.py` 352 358 1236 
seq_type = 'dna circular'   # 20220519 自己添加的 1229 
改了biopython库,以后要确保这些gbk都是环形的才行,不然就要改回去

# Blast
```shell
>>> from Bio.Blast import NCBIWWW
>>> fasta_string = open("/share/nas1/yuj/project/GP-20220919-4923_20221212/analysis/assembly/Carya_sp/pseudo/Carya_sp/Final_Assembly/Carya_sp_FULLCP.fsa").read()
>>> result_handle = NCBIWWW.qblast("blastn", "nt", fasta_string,megablast="TRUE",short_query="TRUE",expect_low=0,expect_high=0.05,word_size=28,gapcosts="11 1", filter="mL")
>>> save_file = open("/share/nas1/yuj/project/GP-20220919-4923_20221212/analysis/assembly/Carya_sp/pseudo/Carya_sp/Final_Assembly/log.xml", "w")
>>> save_file.write(result_handle.read())
>>> save_file.close()
>>> result_handle.close()
```
