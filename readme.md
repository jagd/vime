# Notes

Transforming from a format like https://raw.githubusercontent.com/jagd/Zhengma-Single-Character/master/table.txt
```bash
awk '{printf("%s %05d %s\n",$1,n++,$2)}' | sort  | awk "{printf(\"\\\\'%s','%s',\\n\",\$1,\$3)}
```

Transforming from RIME style table:
```bash
awk '{printf("%s %08d %08d %s\n",$2,99999999-$3,n++,$1)}' | sort  | awk "{printf(\"\\\\'%s','%s',\\n\",\$1,\$4)}"
```
