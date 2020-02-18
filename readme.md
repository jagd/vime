# Note
```bash
awk '{printf("%s %05d %s\n",$1,n++,$2)}' orig.txt | sort  | awk "{printf(\"\\\\'%s','%s',\\n\",\$1,\$3)}
```
to generate the vime table from a ontent.com/jagd/Zhengma-Single-Character/master/table.txt
