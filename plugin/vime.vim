" VIME: Input Method for Vim
"
" Usage:
"    Put in vimrc the following maps, here <F12> is taken for example
"       inoremap <silent><F12> <C-R>=VimeSwitch()<CR>
"       nnoremap <silent><F12> :call VimeInverseLookup()<CR>
"
" Feature:
"   - High performance
"   - Pinyin prefix: #
"   - Tables are loaded lazily at the first time when it is needed
"

if exists('g:vime_loaded')
  finish
endif
let g:autoload_vime = 1

function! VimeInverseLookup()
    call s:VimeLoadTable()
    call s:VimeMakeInverseTable()
    let s = strcharpart(getline('.')[col('.') - 1:], 0, 1)
    if len(s) == 0
        return
    elseif exists('s:inverseTable["'.s.'"]')
        echo s.': ' s:inverseTable[s]
    else
        echo "No result found"
    endif
endfunction

function! VimeSwitch()
    if ! exists('b:vimeIsEnabled')
        call s:VimeBufferInit()
    endif
    let b:vimeDefaultOutput = ''
    if b:vimeIsEnabled " to Disable
        for i in range(0, 25)
            let c = nr2char(97+i)
            execute ':iunmap <buffer> '.c
        endfor
        for i in keys(s:vimeTablePunct)
            execute ':iunmap <buffer> '.i
        endfor
        iunmap <buffer> <SPACE>
        iunmap <buffer> <BS>
        iunmap <buffer> '
        iunmap <buffer> "
        let b:vimeIsEnabled = 0
        let &l:completefunc = b:VimeOldCF
    else " to Enable
        call s:VimeLoadTable()
        let b:vimeIsEnabled = 1
        for i in range(0, 25)
            let c = nr2char(97+i)
            execute ':inoremap <silent><buffer> '.c.' '.c.'<C-X><C-U>'
        endfor
        for i in keys(s:vimeTablePunct)
            execute ':inoremap <silent><buffer> '.i.' '.s:vimeTablePunct[i]
        endfor
        inoremap <silent><buffer> <SPACE> <C-R>=VimeSpace()<CR><C-X><C-U>
        inoremap <silent><buffer> <BS> <BS><C-X><C-U>
        inoremap <silent><buffer> ' <C-R>=VimeQuote()<CR>
        inoremap <silent><buffer> " <C-R>=VimeDoubleQuote()<CR>
        " Do not bind <CR> since it could be alread used for smart-enter in
        " order to complete \begin{env} \end{env} or braces in TeX / C.
        let b:VimeOldCF = &l:completefunc
        let &l:completefunc = "VimeComplete"
    endif
    return ''
endfunction

function! VimeQuote()
    let b:vimeOpenedQuote = !b:vimeOpenedQuote
    if b:vimeOpenedQuote
        return '‘'
    else
        return '’'
    endif
endfunction

function! VimeDoubleQuote()
    let b:vimeOpenedDoubleQuote = !b:vimeOpenedDoubleQuote
    if b:vimeOpenedDoubleQuote
        return '“'
    else
        return '”'
    endif
endfunction

function! VimeSpace()
    call VimeComplete(1, '')
    if len(b:vimeDefaultOutput)
        let b:vimeShouldCommit = 1
        return ''
    endif
    return '　'
endfunction

function! s:VimeMatchLaTeXStart()
    let line = getline('.')
    let verystart = col('.') - 1
    let start = verystart
    while start >= 0 && line[start-1] =~ "[-=a-zA-Z0-9+'`_^()]"
        let start -= 1
    endwhile
    if (start >= 0) && (line[start-1] == '\')
        " Pinyin
        return start-1
    else
        return -3
    endif
endfunction

function! s:VimeMatchChineseStart()
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
endfunction

function! VimeComplete(findstart, base)
    if a:findstart
        " locate the start of the word
        let start = s:VimeMatchLaTeXStart()
        if start >= 0
            return start
        endif
        let start = s:VimeMatchChineseStart()
        if start >= 0
            return start
        endif
        " otherwise: mismatched
        let b:vimeDefaultOutput=''
        return -3
    else
        if len(a:base) == 0
            return []
        endif
        if b:vimeShouldCommit
            let sym = b:vimeDefaultOutput
            let b:vimeDefaultOutput = ''
            let b:vimeShouldCommit = 0
            return [sym]
        elseif a:base[0] == '#'
            call s:VimeLoadPinyinTable()
            return s:VimeFindCode(s:vimePinyinTable, a:base[1:], a:base[0])
        elseif a:base[0] == '\'
            call s:VimeLoadLaTeXTable()
            return s:VimeFindCode(s:vimeLaTeXTable, a:base[1:], a:base[0])
        else
            return s:VimeFindCode(s:vimeTable, a:base, '')
        endif
    endif
endfunction

function! s:VimeFindCode(table, code, prefix)
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
        " refresh always cannot handle <BS>, therefore use a inoremap
        return {'words': words}
    endif
endfunction

function! s:VimeMakeInverseTable()
    if exists("s:inverseTable")
        return
    endif
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
endfunction

function! s:VimeLoadPinyinTable()
    if exists("s:vimePinyinTable")
        return
    endif
    runtime vime-table-pinyin.txt
    let s:vimePinyinTable = g:vimeTable
endfunction

function! s:VimeLoadLaTeXTable()
    if exists("s:vimeLaTeXTable")
        return
    endif
    runtime vime-table-latex.txt
    let s:vimeLaTeXTable = g:vimeTable
endfunction

function! s:VimeLoadTable()
    if exists("s:vimeTable")
        return
    endif
    runtime vime-table.txt
    let s:vimeTable = g:vimeTable
    unlet g:vimeTable
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
    call assert_true(len(s:vimeTable) % 2 == 0)
    call assert_true(len(s:vimeTablePunct) % 2 == 0)
endfunction

function! s:VimeFindMatch(table, code)
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
endfunction

function s:VimeBufferInit()
    let b:vimeIsEnabled = 0
    let b:vimeShouldCommit = 0
    let b:vimeOpenedQuote = 0
    let b:vimeOpenedDoubleQuote = 0
endfunction
