# 用法
## 安装
若用 vim 的插件管理器 [vim-plug](https://github.com/junegunn/vim-plug) ，在 `.vimrc`　的
```vim
call plug#begin(...)
```

中加入
```vim
    Plug 'jagd/vime'
```

## 制定快捷键
比如用 `F12`：
- 汉 / Latin 切换（插入模式）
  ```vim
  inoremap <silent><F12>  <C-R>=VimeSwitch()<CR>
  ```
- 半角 / 全角（插入模式）
  ```vim
  inoremap <silent><F12>. <C-R>=VimeToggleFullPunct()<CR>
  ```
- 反查码表（普通模式）
  ```vim
  nnoremap <silent><F12>  :call VimeInverseLookup()<CR>
   ```

## 拼音
- 输入法打开装态下， `#` 后跟着小写拼音字母

## 全角
- 默认关闭全角，若设为默认开启:
  ```vim
  let g:vimeDefaultFullPunct = 1
  ```
- 全角时 LaTeX 自动关闭，以方便数学输入。

## 数学符号
-  输入法打开并且半角时 `\` 后跟 LaTeX command。与LaTeX不同之处在于所有符号都需要 `\` 引导，如
    * 德文引号 ``\glqq\grqq`` 得 `„“`，而英文引号仍需要 `\` 符号以区分非数学输入，如 ```\``\''``` 得 `“”`
    * 上下标需要 `\`，如 `CO\_2` 得 `CO₂`， `H\^+` 得　`H⁺`
    * Italic 或其它风格的拉丁／希腊字符例如 `\mathitpsi\_p` 得 `𝜓ₚ`
    * Umlaute 如 `\"u` 得 `ü`，　`\"e` 得 `ë`
    * 其它数学或非数学的符号如 `\cmark` 得 `✓`；`\xmark` 得 `✗`

## 其它
- 空格上屏，`<C-N>` 与 `<C-P>` 选择候选字词
- Vim 中 `q/` 可用此插件输入待搜索的字符，而 `q:` 可用此插件输入包涵汉字的命令（如替换，grep，打开文件）
- 设 vim 为 readline 的 EDITOR，便可以在 Shell 中输入汉字路径名

# 自定义码表
默认附帯了我自己用的郑码单字码表。

自定义码表名字为 `vime-table.txt`，放在 `~/.vim` 或其它 runtime 目录下。
由于 runtime 依序寻找文件，故**不必**存于此插件的文件夹中。
码表是一个**从小到大**编码排列有序的平面一维数组，两个元素一组用二分查找编码。
重码时越靠前的字词候选也越排前。
例如：
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


## 码表转换

Transforming from a format like https://raw.githubusercontent.com/jagd/Zhengma-Single-Character/master/table.txt
```bash
awk '{printf("%s %05d %s\n",$1,n++,$2)}' | sort  | awk "{printf(\"\\\\'%s','%s',\\n\",\$1,\$3)}
```

Transforming from [RIME](https://raw.githubusercontent.com/rime/rime-stroke/master/stroke.dict.yaml) style table:
```bash
awk '{printf("%s %08d %08d %s\n",$2,99999999-$3,n++,$1)}' | sort  | awk "{printf(\"\\\\'%s','%s',\\n\",\$1,\$4)}"
```

# Known Issues
- 一些 Unicode 符号（比如粗体/Fraktur字母）与一些国标扩展的汉字在 GVim 中有残影，`set rop` 无法解决。NeoVim-Qt 中渲染正常。

# TODO
- Use `complete()` instead of `<C-X><C-U>`
- Migrate to `lmap` and `im*`
