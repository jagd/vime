# 用法

若用 vim 的插件管理器 [vim-plug](https://github.com/junegunn/vim-plug) ，在 `.vimrc`　的
```vim
call plug#begin(...)
```

中加入
```vim
    Plug 'jagd/vime'
```
再绑定快捷键，比如用 `F12`：
- 汉 / Latin 切换（插入模式）
  ```vim
  inoremap <silent><F12>  <C-R>=VimeSwitch()<CR>
  ```
- 全角（插入模式）
  ```vim
  inoremap <silent><F12>. <C-R>=VimeToggleFullPunct()<CR>
  ```
- 反查码表（普通模式）
  ```vim
  nnoremap <silent><F12>  :call VimeInverseLookup()<CR>
   ```

## 拼音
- 前导符号 `#` 

## 全角
- 全角时 LaTeX 自动关闭。 
- 默认关闭全角，若设为默认开启:
  ```vim
  let g:vimeDefaultFullPunct = 1`
  ```
## Unicode Math
- 前导符号 `\`

# 自定义码表
默认附帯了我自己用的郑码单字码表。

若要挂上自己的码表，在 `~/.vim` 或其它 runtime 目录下（runtime 依序寻找文件，故不须放在此插件目录）的 `vime-table.txt` 为自定义的码表。这是一个**从小到大有序**的大数组（二分查找），越靠前的字词候选也越排前。例如：
```vim
let g:vimeTable = [
  \'a','啊',
  \'a','阿',
  \'ba','吧',
  \'ba','把',
  \'ba','八',
  \'zun','尊',
  \'zun','遵',
  \'zun','樽',
\]
```
拼音码表亦是如是，只需将文件命名为 `vim-table-pinyin.txt`。


# 码表转换

Transforming from a format like https://raw.githubusercontent.com/jagd/Zhengma-Single-Character/master/table.txt
```bash
awk '{printf("%s %05d %s\n",$1,n++,$2)}' | sort  | awk "{printf(\"\\\\'%s','%s',\\n\",\$1,\$3)}
```

Transforming from RIME style table:
```bash
awk '{printf("%s %08d %08d %s\n",$2,99999999-$3,n++,$1)}' | sort  | awk "{printf(\"\\\\'%s','%s',\\n\",\$1,\$4)}"
```
