" VIME: Input Method for Vim
"
" Usage:
"    Put in vimrc the following maps, here <F12> is taken for example
"       inoremap <silent><F12>  <C-R>=VimeSwitch()<CR>
"       inoremap <silent><F12>. <ESC>:call VimeToggleFullPunct()<CR>
"       nnoremap <silent><F12>  :call VimeInverseLookup()<CR>
"
"    `let g:vimeDefaultFullPunct = 1` to enable full punctuation by default.
"         b:vimeFullPunct, if exists, will override g:vimeDefaultFullPunct
"
"    Full punctuation conflicts with LaTeX. When full punct is enabled, LaTeX
"    will be automatically disabled.
"
" Feature:
"   - Pinyin prefix: #
"   - LaTeX prefix: \
"

if exists('g:autoload_vime')
    finish
endif
let g:autoload_vime = 1

if !exists("g:vimeDefaultFullPunct")
    let g:vimeDefaultFullPunct = 0
endif

augroup VIME
autocmd!
autocmd BufEnter * call s:VimeBufferInit()
augroup END

" Exported Functions {{{

function! VimeToggleFullPunct() "{{{
    if b:vimeIsEnabled
        let b:vimeFullPunct = !b:vimeFullPunct
        call s:VimeMapPuntuation(b:vimeFullPunct)
    endif
    return ''
endfunction "}}}

function! VimeInverseLookup() "{{{
    call s:VimeMakeInverseTable()
    let s = strcharpart(getline('.')[col('.') - 1:], 0, 1)
    if len(s) == 0
        return
    elseif exists('s:inverseTable["'.s.'"]')
        echo s.': ' s:inverseTable[s]
    else
        echo "No result found"
    endif
endfunction "}}}

function! VimeSwitch() "{{{
    let b:vimeDefaultOutput = ''
    if b:vimeIsEnabled " to Disable
        for i in range(0, 25)
            let c = nr2char(97+i)
            execute ':iunmap <buffer> '.c
        endfor
        iunmap <buffer> <SPACE>
        iunmap <buffer> <BS>
        let b:vimeIsEnabled = 0
        call s:VimeMapPuntuation(0)
        call s:VimeMapLaTeX(0)
    else " to Enable
        call s:VimLoadAllTablesOnce()
        for i in range(0, 25)
            let c = nr2char(97+i)
            execute ':inoremap <silent><buffer> '.c.' '.c.'<C-R>=VimeComplete()<CR>'
        endfor
        inoremap <silent><buffer> <SPACE> <C-R>=VimeSpace()<CR>
        inoremap <silent><buffer> <BS> <BS><C-R>=VimeComplete()<CR>
        let b:vimeIsEnabled = 1
        if b:vimeFullPunct
            call s:VimeMapPuntuation(1)
        else
            call s:VimeMapLaTeX(1)
        endif
        " Do not bind <CR> since it could be alread used for smart-enter in
        " order to complete \begin{env} \end{env} or braces in TeX / C.
    endif
    return ''
endfunction "}}}

" Exported Functions }}}

" Private Functions {{{

function! s:VimeBufferInit() abort "{{{
    if exists('b:vimeIsEnabled')
        return
    endif
    let b:vimeIsEnabled = 0
    let b:vimeShouldCommit = 0
    let b:vimeOpenedQuote = 0
    let b:vimeOpenedDoubleQuote = 0
    let b:vimeFullPunct = g:vimeDefaultFullPunct
    let b:vimeFullPunctIsMapped = 0
    let b:vimeLaTeXIsMapped = 0
endfunction "}}}

function! s:VimLoadAllTablesOnce() abort "{{{
    if !exists('s:vimeAllTablesLoaded')
        call s:VimeLoadPinyinTable()
        call s:VimeLoadLaTeXTable()
        call s:VimeLoadTable()
        let s:vimeAllTablesLoaded = 1
    endif
endfunction "}}}

function! s:VimeMapPuntuation(shouldMap) abort "{{{
    if a:shouldMap
        call s:VimeMapLaTeX(0)
        for i in keys(s:vimeTablePunct)
            execute ':inoremap <silent><buffer> '.i.' '.s:vimeTablePunct[i]
        endfor
        inoremap <silent><buffer> ' <C-R>=VimeQuote()<CR>
        inoremap <silent><buffer> " <C-R>=VimeDoubleQuote()<CR>
        let b:vimeFullPunctIsMapped = 1
    elseif b:vimeFullPunctIsMapped
        for i in keys(s:vimeTablePunct)
            execute ':iunmap <buffer> '.i
        endfor
        iunmap <buffer> '
        iunmap <buffer> "
        let b:vimeFullPunctIsMapped = 0
    endif
endfunction "}}}

function! VimeQuote() "{{{
    let b:vimeOpenedQuote = !b:vimeOpenedQuote
    if b:vimeOpenedQuote
        return '‘'
    else
        return '’'
    endif
endfunction "}}}

function! VimeDoubleQuote() "{{{
    let b:vimeOpenedDoubleQuote = !b:vimeOpenedDoubleQuote
    if b:vimeOpenedDoubleQuote
        return '“'
    else
        return '”'
    endif
endfunction "}}}

function! VimeSpace() "{{{
    if len(b:vimeDefaultOutput)
        let b:vimeShouldCommit = 1
        return VimeComplete()
    endif
    if b:vimeFullPunctIsMapped
        return '　'
    else
        return ' '
    endif
endfunction "}}}

let s:latexSpecialSymbols = split("+-=_^()\"`'" ,'\zs')
function! s:VimeMapLaTeX(shouldMap) abort "{{{
    if a:shouldMap
        if b:vimeFullPunctIsMapped
            return
        endif
        for i in range(0, 25)
            let c = nr2char(65+i)
            execute ':inoremap <silent><buffer> '.c.' '.c.'<C-R>=VimeComplete()<CR>'
        endfor
        for i in range(0, 9)
            let c = nr2char(48+i)
            execute ':inoremap <silent><buffer> '.c.' '.c.'<C-R>=VimeComplete()<CR>'
        endfor
        for c in s:latexSpecialSymbols
            execute ':inoremap <silent><buffer> '.c.' '.c.'<C-R>=VimeComplete()<CR>'
        endfor
        let b:vimeLaTeXIsMapped = 1
    elseif b:vimeLaTeXIsMapped
        for i in range(0, 25)
            let c = nr2char(65+i)
            execute ':iunmap <buffer> '.c
        endfor
        for i in range(0, 9)
            let c = nr2char(48+i)
            execute ':iunmap <buffer> '.c
        endfor
        for c in s:latexSpecialSymbols
            execute ':iunmap <buffer> '.c
        endfor
        let b:vimeLaTeXIsMapped = 0
    endif
endfunction "}}}

function! s:VimeMatchLaTeXStart() "{{{
    let line = getline('.')
    let verystart = col('.') - 1
    let start = verystart
    while start >= 0 && line[start-1] =~ "[-=a-zA-Z0-9+'`_^()\"]"
        let start -= 1
    endwhile
    if (start >= 0) && (line[start-1] == '\')
        " Pinyin
        let start -= 1
    else
        let start = -3
    endif
    return l:start
endfunction "}}}

function! s:VimeMatchChineseStart() "{{{
    let line = getline('.')
    let verystart = col('.') - 1
    let start = verystart
    while start >= 0 && line[start-1] =~ '[a-z]'
        let start -= 1
    endwhile
    if (start >= 0) && (line[start-1] == '#')
        " Pinyin
        let start -= 1
    endif
    if start == verystart
        return -3
    endif
    return start
endfunction "}}}

function! VimeComplete() "{{{
        " locate the start of the word
        " the start var is compatible to `completefunc`
        let start = s:VimeMatchLaTeXStart()
        if start < 0
            let start = s:VimeMatchChineseStart()
            if start < 0
                " mismatched:
                let b:vimeDefaultOutput=''
                return ''
            endif
        endif

        let endcol = col('.')-1
        if l:start > l:endcol-1
            return ''
        endif
        " vim [range] is close ended and start from 0
        let base = getline('.')[l:start : (l:endcol-1)]

        " start was compatible with `completefunc`
        " to make it be compatible with `complete()`, we need +1
        let start += 1

        let prefix=''
        if (l:base[0] == '#') || (l:base[0] == '\')
            let prefix = l:base[0]
            let base = l:base[1:]
        endif
        if len(l:base) == 0
            return []
        endif
        if b:vimeShouldCommit
            let sym = b:vimeDefaultOutput
            let b:vimeDefaultOutput = ''
            let b:vimeShouldCommit = 0
            call complete(start, [sym])
        elseif l:prefix == '#'
            call complete(start, s:VimeFindCode(s:vimePinyinTable, l:base, l:prefix))
        elseif (l:prefix == '\') && (!b:vimeFullPunctIsMapped)
            call complete(start, s:VimeFindCode(s:vimeLaTeXTable, l:base, l:prefix))
        else
            call complete(start, s:VimeFindCode(s:vimeTable, l:base, l:prefix))
        endif
        return ''
endfunction "}}}

" IME table operations {{{

function! s:VimeLoadTable() "{{{
    " load the main table
    if exists("s:vimeTable")
        return
    endif
    runtime vime-table.txt
    let s:vimeTable = g:vimeTable
    unlet g:vimeTable
    "{{{
    let s:vimeTablePunct = {
        \'0':'０',
        \'1':'１',
        \'2':'２',
        \'3':'３',
        \'4':'４',
        \'5':'５',
        \'6':'６',
        \'7':'７',
        \'8':'８',
        \'9':'９',
        \'!':'！',
        \'$':'￥',
        \'%':'％',
        \'&':'＆',
        \'(':'（',
        \')':'）',
        \'*':'× ',
        \'+':'＋',
        \',':'，',
        \'-':'－',
        \'.':'。',
        \'/':'÷ ',
        \':':'：',
        \';':'；',
        \'=':'＝',
        \'<':'《',
        \'>':'》',
        \'?':'？',
        \'[':'「',
        \']':'」',
        \'^':'…',
    \ }
    "}}}
    if v:version >= 801
        call assert_true(len(s:vimeTable) % 2 == 0)
        call assert_true(len(s:vimeTablePunct) % 2 == 0)
    endif
endfunction "}}}

function! s:VimeLoadPinyinTable() "{{{
    if exists("s:vimePinyinTable")
        return
    endif
    runtime vime-table-pinyin.txt
    let s:vimePinyinTable = g:vimeTable
endfunction "}}}

function! s:VimeLoadLaTeXTable() "{{{
    if exists("s:vimeLaTeXTable")
        return
    endif
    runtime vime-table-latex.txt
    let s:vimeLaTeXTable = g:vimeTable
endfunction "}}}

function! s:VimeMakeInverseTable() "{{{
    if exists("s:inverseTable")
        return
    endif
    call s:VimeLoadTable()
    let s:inverseTable = {}
    let tablelen = len(s:vimeTable)/2
    for i in range(tablelen)
        let c = s:vimeTable[i*2]
        let s = s:vimeTable[i*2+1]
        if exists('s:inverseTable["'.s.'"]')
            let s:inverseTable[s] = s:inverseTable[s] .' | '. c
        else
            let s:inverseTable[s] =  c
        endif
    endfor
endfunction "}}}

function! s:VimeFindCode(table, code, prefix) "{{{
        " default param like prefix='' is supported since vim8.2
        let codelen = len(a:code)
        if codelen == 0
            return {}
        endif
        let start = s:VimeFindMatch(a:table, a:code)
        let end = start  " end is an open interval boundary i.e., [start, end)
        let tablelen = len(a:table)/2
        " find the exact matches
        while (end < tablelen) && (a:table[end*2] == a:code)
            let end += 1
        endwhile
        let numAdditionalPrompt = 10
        while numAdditionalPrompt  > 0
            \ && (end < tablelen)
            \ && strpart(a:table[end*2], 0, codelen) == a:code
            let end += 1
            let numAdditionalPrompt -= 1
        endwhile
        let words = [{'word': a:prefix.a:code}]
        for i in range(start, end-1)
            call add(words, {'word': a:table[2*i+1], 'menu': a:prefix.a:table[2*i]})
        endfor
        " In case of `completefunc`:
        " 'refresh always' in complete cannot handle <BS>, therefore use a inoremap
        "   return {'words': words}
        " Otherwise, for `complete()`:
        return words
    endif
endfunction "}}}

function! s:VimeFindMatch(table, code) "{{{
    " Parameters: a:table is a list, which is passed by reference
    " Return: The first index(/2) of the match;  If not found, returns the
    " index(/2) i, where tablecode[i] < code, where i*2 <= len(a:table)
    let b:vimeDefaultOutput = ''
    let found = 0
    let codelen = len(a:code)
    let tablelen = len(a:table)/2
    let bd1 = 0
    let bd2 = tablelen - 1
    call assert_true(bd1 <= bd2)
    while bd1 <= bd2 " only '<' it may ends without triggering match
        let i = (bd1+bd2) /2
        let midcode = a:table[i*2] " ind=/2 and ind*2  cancelled
        if a:code < midcode
            let bd2 = i - 1
        elseif a:code > midcode
            let bd1 = i + 1
        else " a:code == midcode
            let bd1 = i
            let found = 1
            break
        endif
    endwhile
    if found
        while (bd1 > 0) && (a:table[(bd1-1)*2] == a:code)
            let bd1 -= 1
        endwhile
        let b:vimeDefaultOutput = a:table[bd1*2+1]
    elseif codelen && a:table[bd1*2] < a:code
        let bd1 += 1
        if (bd1 < tablelen) && (strpart(a:table[bd1*2], 0, codelen) == a:code)
            let b:vimeDefaultOutput = a:table[bd1*2+1]
        endif
    endif
    return bd1
endfunction "}}}

" IME table operations }}}

" Private Functions }}}

" vi:fdm=marker
