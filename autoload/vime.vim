source vime-table.txt
let s:numtable = len(g:vimetable)
if s:numtable % 2 != 0
    echoerr "Bad vime table"
endif
let s:numtable /= 2 " 字词个数

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
        " find matches with "a:base"
        let codelen = len(a:base)
        if codelen == 0
            return []
        endif
        let bd1 = 0
        let bd2 = s:numtable - 1
        call assert_true(bd1 <= bd2)
        while bd1 < bd2
            let i = (bd1+bd2) /2
            let midcode = g:vimetable[i*2] " ind=/2 and ind*2  cancelled
            if a:base < midcode
                let bd2 = i - 1
            elseif a:base > midcode
                let bd1 = i + 1 
            else " a:base == midcode
                let bd1 = i
                break
            endif
        endwhile
        " now, either bd1 == bd2 (may or maynot found, the latter case means
        "                         that there is no exact match, e.g. 'aa')
        "      or found one of the solutions at bd1
        let range1 = bd1
        if strpart(g:vimetable[(range1+1)*2], 0, codelen) == a:base
            " in case of range1 is not the exact index, e.g 'aa'
            let range1 += 1
        endif
        while range1 > 0
            let range1 -= 1
            " if they are exactly equal, strpart() does not harm
            " but incase of solution not found, comparing with strpart() will
            " prompt potential candidates
            if strpart(g:vimetable[range1*2], 0, codelen) != a:base
                let range1 += 1 " restore the -1
                break
            endif
        endwhile

        let range2 = max([range1, bd1])
        while range2 < (s:numtable - 1)
            let range2 += 1
            if g:vimetable[range2*2] != a:base
                let range2 -= 1
                break
            endif
        endwhile

        " Now range1 and range2 are exact matches
        " Now find the prompts, must include the check of range2 again
        let i = 1000 " max additional prompt count
        while i >= 0 && range2 < (s:numtable - 1)
                    \ && strpart(g:vimetable[(range2+1)*2], 0, codelen) == a:base
            let i -= 1
            let range2 += 1
        endwhile
        let words = []
        " TODO: if  solution not found:
        "       call add(words, {'word': a:base})
        for i in range(range1, range2)
            call add(words, {'word': g:vimetable[2*i+1], 'menu': g:vimetable[2*i]})
        endfor
        return {'words': words, 'refresh': 'always'}
    endif
endfunction

set completefunc=VimeComplete
