" VIME: input method for vim
" Usage:
"    put in vimrc:
"    inoremap <silent><F12> <C-R>=VimeSwitch()<CR>
"
" TODO: “”‘’
" TODO: Pinyin reverse search

if exists('g:autoload_vime')
  finish
endif
let g:autoload_vime = 1


let b:vimeIsEnabled = 0
let b:vimeShouldCommit = 0

function s:VimeLoadTable()
    runtime vime-table.txt
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
    call assert_true(len(g:vimeTable) % 2 == 0)
    call assert_true(len(s:vimeTablePunct) % 2 == 0)
endfunction

function! VimeSwitch()
    let b:vimeDefaultOutput = ''
    if b:vimeIsEnabled " to Disable
        for i in range(0, 25)
            let c = nr2char(97+i)
            execute ':iunmap <buffer> '.c
        endfor
        for i in keys(s:vimeTablePunct)
            execute ':iunmap <buffer> '.i
        endfor
        execute ':iunmap <buffer> <SPACE>'
        let b:vimeIsEnabled = 0
        let &l:completefunc = b:VimeOldCF
    else " to Enable
        if ! exists("g:vimeTable")
            call s:VimeLoadTable()
        endif
        let b:vimeIsEnabled = 1
        for i in range(0, 25)
            let c = nr2char(97+i)
            execute ':inoremap <buffer> '.c.' '.c.'<C-X><C-U>'
        endfor
        for i in keys(s:vimeTablePunct)
            execute ':inoremap <buffer> '.i.' '.s:vimeTablePunct[i]
        endfor
        inoremap <buffer> <SPACE> <C-R>=VimeSpace()<CR><C-X><C-U>
        " Do not bind <CR> since it could be alread used for smart-enter in
        " order to complete \begin{env} \end{env} or braces in TeX / C.
        let b:VimeOldCF = &l:completefunc
        let &l:completefunc = "VimeComplete"
    endif
    return ''
endfunction

function! VimeSpace()
    if len(b:vimeDefaultOutput)
        let b:vimeShouldCommit = 1
        return ''
    endif
    return '　'
endfunction

function! VimeComplete(findstart, base)
    if a:findstart
        " locate the start of the word
        let line = getline('.')
        let start = col('.') - 1
        while start >= 0 && line[start-1] =~ '[#a-z]'
            let start -= 1
            if line[start-1] == '#'
                break
            endif
        endwhile
        return start
    else
        if len(a:base) == 0
            return []
        endif
        if b:vimeShouldCommit
            let sym = b:vimeDefaultOutput
            let b:vimeDefaultOutput = ''
            let b:vimeShouldCommit = 0
            return [sym]
        else
            return s:VimeFindCode(g:vimeTable, a:base)
        endif
    endif
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

function! s:VimeFindCode(table, code)
        let start = s:VimeFindMatch(a:table, a:code)
        let end = start
        let tablelen = len(a:table)/2
        let codelen = len(a:code)
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
        if end >= tablelen
            let end = tablelen - 1
        endif
        let words = [{'word': a:code}]
        for i in range(start, end)
            call add(words, {'word': a:table[2*i+1], 'menu': a:table[2*i]})
        endfor
        return {'words': words}
    endif
endfunction
