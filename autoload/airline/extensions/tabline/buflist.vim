" MIT License. Copyright (c) 2013-2016 Bailey Ling.
" vim: et ts=2 sts=2 sw=2

let s:excludes = get(g:, 'airline#extensions#tabline#excludes', [])
let s:exclude_preview = get(g:, 'airline#extensions#tabline#exclude_preview', 1)

function! airline#extensions#tabline#buflist#invalidate()
  unlet! s:current_buffer_list
endfunction

function! airline#extensions#tabline#buflist#get_curr_buf_idx()
  let curBuf = winbufnr(0)
    " let s:ordred_buffs = s:ordered_buffs

    " TODO: might be worth refactoring this to use a dict lookup instead
    " would only really matter if there were a lot of buffers open
  let bufIdx = 0
  for cur_ordered in s:ordered_buffs  
    if cur_ordered == curBuf
      let curOrderedBuf = bufIdx
      break
    endif
    let bufIdx+=1
  endfor

  return bufIdx
endfunction

function! airline#extensions#tabline#buflist#get_dir_buffer_idx_ordered(isForward)
  " let s:ordered_buffs = s:ordered_buffs

    let dir = -1
    if a:isForward
        let dir = 1
    endif

    let curBufIdx = airline#extensions#tabline#buflist#get_curr_buf_idx()
    let tgtBufIdx = curBufIdx+dir
		 " wrap around	
		 if tgtBufIdx < 0
			 let tgtBufIdx = len(s:ordered_buffs)-1 
		 elseif tgtBufIdx == len(s:ordered_buffs)
			 let tgtBufIdx = 0
		 endif

		 return tgtBufIdx
     
endfunction

function! airline#extensions#tabline#buflist#get_dir_buffer_ordered(isForward)
  " let s:ordered_buffs = s:ordered_buffs
    let tgtBufIdx = airline#extensions#tabline#buflist#get_dir_buffer_idx_ordered(a:isForward)
  let tgtOrdered = s:ordered_buffs[tgtBufIdx]
  return tgtOrdered
endfunction

function! airline#extensions#tabline#buflist#get_last_buffer_ordered()
  let tgtOrdered = s:ordered_buffs[len(s:ordered_buffs)-1]
  return tgtOrdered
endfunction

function! airline#extensions#tabline#buflist#get_buffer_num_ordered(num)
  if(a:num >= len(s:ordered_buffs)) 
    return len(s:ordered_buffs)-1
  endif
  let tgtOrdered = s:ordered_buffs[a:num]
  return tgtOrdered
endfunction


" Ordered Buffer Navigation
""""""""""""""""""""""""""""""""""
function! airline#extensions#tabline#buflist#get_next_buffer_ordered()
    return airline#extensions#tabline#buflist#get_dir_buffer_ordered(1)
endfunction

function! airline#extensions#tabline#buflist#get_prev_buffer_ordered()
    return airline#extensions#tabline#buflist#get_dir_buffer_ordered(0)
endfunction

function! airline#extensions#tabline#buflist#next_buffer_ordered()
    execute ":b " . airline#extensions#tabline#buflist#get_next_buffer_ordered()
endfunction

function! airline#extensions#tabline#buflist#prev_buffer_ordered()
    execute ":b " . airline#extensions#tabline#buflist#get_prev_buffer_ordered()
endfunction

function! airline#extensions#tabline#buflist#last_buffer()
    execute ":b " . airline#extensions#tabline#buflist#get_last_buffer_ordered()
endfunction

function! airline#extensions#tabline#buflist#goto_buf_num(num)
    execute ":b " . airline#extensions#tabline#buflist#get_buffer_num_ordered(a:num)
endfunction

" Buffer re-ordering
""""""""""""""""""""""""""""""""""
function! airline#extensions#tabline#buflist#move_cur_buf_dir(isForward)
  " let s:ordered_buffs = s:ordered_buffs
    let curBufIdx = airline#extensions#tabline#buflist#get_curr_buf_idx()
    let tgtBufIdx = airline#extensions#tabline#buflist#get_dir_buffer_idx_ordered(a:isForward) 

    let tmp = s:ordered_buffs[curBufIdx]
    let s:ordered_buffs[curBufIdx] = s:ordered_buffs[tgtBufIdx]
    let s:ordered_buffs[tgtBufIdx] = tmp

    " TODO session integration
    " call airline#extensions#tabline#buflist#updateSessionOrder()
    " re-render the tabline since stuff got moved around
    call airline#extensions#tabline#buflist#invalidate()
    " TODO provide a better mechanism than this, it's pretty broken
    let g:airline_force_tabline_update = 1
    set tabline=%!airline#extensions#tabline#get()
endfunction

function! airline#extensions#tabline#buflist#move_cur_buf_forward()
    call airline#extensions#tabline#buflist#move_cur_buf_dir(1)
endfunction

function! airline#extensions#tabline#buflist#move_cur_buf_backward()
    call airline#extensions#tabline#buflist#move_cur_buf_dir(0)
endfunction


" Commands
""""""""""""""""""""""""""""""""""
com! -bar AirlineMoveCurBufBackward call airline#extensions#tabline#buflist#move_cur_buf_backward()   
com! -bar AirlineMoveCurBufForward call airline#extensions#tabline#buflist#move_cur_buf_forward()  

com! -bar AirlineNextBuffer call airline#extensions#tabline#buflist#next_buffer_ordered()  
com! -bar AirlinePrevBuffer call airline#extensions#tabline#buflist#prev_buffer_ordered()  

com! -bar AirlineLastBuffer call airline#extensions#tabline#buflist#last_buffer()  
com! -bar AirlineGotoOrderedBuffer1 call airline#extensions#tabline#buflist#goto_buf_num(0)  
com! -bar AirlineGotoOrderedBuffer2 call airline#extensions#tabline#buflist#goto_buf_num(1)  
com! -bar AirlineGotoOrderedBuffer3 call airline#extensions#tabline#buflist#goto_buf_num(2)  
com! -bar AirlineGotoOrderedBuffer4 call airline#extensions#tabline#buflist#goto_buf_num(3)  
com! -bar AirlineGotoOrderedBuffer5 call airline#extensions#tabline#buflist#goto_buf_num(4)  
com! -bar AirlineGotoOrderedBuffer6 call airline#extensions#tabline#buflist#goto_buf_num(5)  
com! -bar AirlineGotoOrderedBuffer7 call airline#extensions#tabline#buflist#goto_buf_num(6)  
com! -bar AirlineGotoOrderedBuffer8 call airline#extensions#tabline#buflist#goto_buf_num(7)  
com! -bar AirlineGotoOrderedBuffer9 call airline#extensions#tabline#buflist#goto_buf_num(8)  


function! s:update_session_order()
    let g:airline_session_order = []
    for bufnum in s:ordered_buffs  
        let fname = expand(bufname(bufnum))
        let g:airline_session_order += [fname]
    endfor   
endfunction

function! s:from_session_order(session_buffers)
  let buffers = []
  for sessionFname in a:session_buffers 
      let localBuf = bufnr(expand(sessionFname))
      let buffers += [localBuf] 
  endfor
  return buffers
endfunction

function! s:sync_ordered_buffers(buffers)
  if !exists('s:ordered_buffs') || (exists('s:ordered_buffs') && len(s:ordered_buffs) == 0)
    if exists("g:airline_session_order") && len(g:airline_session_order) > 0
      let s:ordered_buffs = s:from_session_order(g:airline_session_order)
    else
      " No session order available, starting fresh
      let s:ordered_buffs = copy(a:buffers)
    endif
  else
    let append_list = []
    let in_cur_buffers = {}
    " make sure we have everything represented in the ordered buffer

    " TODO this can probably be faster
    for nr in a:buffers
      let buf_found = 0
      for ordered_nr in s:ordered_buffs
        if nr == ordered_nr
          " call add(found_list, nr)
          let in_cur_buffers[nr] = 1
          let buf_found = 1
          break
        endif
      endfor

      if !buf_found
        call add(append_list, nr)
      endif

    endfor

    let ordered_copy = copy(s:ordered_buffs)
    let s:ordered_buffs = []
    let i = 0
    for ordered_nr in ordered_copy 
      let buf_found = has_key(in_cur_buffers, ordered_nr)
      " let buf_found = 0
      " for nr in a:buffers 
      "   if nr == ordered_nr
      "     let buf_found = 1
      "     break
      "   endif
      " endfor

      if buf_found
        call add(s:ordered_buffs, ordered_nr)
      endif
      let i += 1
    endfor
    
    for nr in append_list
      " echom 'appending missing buffer: ' . nr
      call add(s:ordered_buffs, nr)
    endfor

  endif

  call s:update_session_order()
  " return s:ordered_buffs
endfunction


function! airline#extensions#tabline#buflist#list()
  " let start = reltime()
   
  if exists('s:current_buffer_list')
    return s:current_buffer_list
  elseif exists('g:airline_session_buffers')
    let s:ordered_buffers = s:from_session_order(g:airline_session_buffers)
    let s:current_buffer_list = s:ordered_buffers
    return s:current_buffer_list
  endif

  let list = (exists('g:did_bufmru') && g:did_bufmru) ? BufMRUList() : range(1, bufnr("$"))

  let buffers = []
  " If this is too slow, we can switch to a different algorithm.
  " Basically branch 535 already does it, but since it relies on
  " BufAdd autocommand, I'd like to avoid this if possible.
  for nr in list
    if buflisted(nr)
      " Do not add to the bufferlist, if either
      " 1) buffername matches exclude pattern
      " 2) buffer is a quickfix buffer
      " 3) exclude preview windows (if 'bufhidden' == wipe
      "    and 'buftype' == nofile
      if (!empty(s:excludes) && match(bufname(nr), join(s:excludes, '\|')) > -1) ||
            \ (getbufvar(nr, 'current_syntax') == 'qf') ||
            \  (s:exclude_preview && getbufvar(nr, '&bufhidden') == 'wipe'
            \  && getbufvar(nr, '&buftype') == 'nofile')
        continue
      endif
      call add(buffers, nr)
    endif
  endfor


  call s:sync_ordered_buffers(buffers)
  let s:current_buffer_list = s:ordered_buffs  

  " let s:current_buffer_list = buffers
  

  " let seconds = reltimefloat(reltime(start))
  " echom printf("buflist list took %f", seconds)

  return s:current_buffer_list
  " return copy(s:ordered_buffs) 
endfunction

