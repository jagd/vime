function! VimeComplete(findstart, base)
	  if a:findstart
	    " locate the start of the word
	    let line = getline('.')
	    let start = col('.') - 1
	    while start > 0 && line[start - 1] =~ '[#a-z]'
	      let start -= 1
          if line[start] == '#'
              let  start -=1
              break
          end
	    endwhile
	    return start
	  else
	    " find matches with "a:base"
	    let res = [
            \ {'word': '于', 'menu': 'ad'},
            \ {'word': '盂', 'menu': 'adl'},
            \ {'word': '迂', 'menu': 'adw'},
            \ {'word': '邘', 'menu': 'ady'},
            \ ]
	    return {'words': res, 'refresh': 'always'}
	  endif
endfunction

set completefunc=VimeComplete
