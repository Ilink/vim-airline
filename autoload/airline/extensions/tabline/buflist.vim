" MIT License. Copyright (c) 2013-2016 Bailey Ling.
" vim: et ts=2 sts=2 sw=2

let s:excludes = get(g:, 'airline#extensions#tabline#excludes', [])
let s:exclude_preview = get(g:, 'airline#extensions#tabline#exclude_preview', 1)

function! airline#extensions#tabline#buflist#invalidate()
  unlet! s:current_buffer_list
endfunction

function! airline#extensions#tabline#buflist#get_curr_buf_idx()
  let curBuf = winbufnr(0)
    " let s:ordered_buffs = s:ordered_buffs

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


" Buffer re-ordering
""""""""""""""""""""""""""""""""""
function! airline#extensions#tabline#buflist#move_cur_buf_dir(isForward)
		echom "move buffer"
  " let s:ordered_buffs = s:ordered_buffs
    let curBufIdx = airline#extensions#tabline#buflist#get_curr_buf_idx()
    let tgtBufIdx = airline#extensions#tabline#buflist#get_dir_buffer_idx_ordered(a:isForward) 

    let tmp = s:ordered_buffs[curBufIdx]
    let s:ordered_buffs[curBufIdx] = s:ordered_buffs[tgtBufIdx]
    let s:ordered_buffs[tgtBufIdx] = tmp

    " TODO session integration
    " call airline#extensions#tabline#buflist#updateSessionOrder()
    " re-render the tabline since stuff got moved around
    " call airline#extensions#tabline#buflist#update(0)
    call airline#extensions#tabline#buflist#invalidate()
    let detect_modified = g:airline_detect_modified 
    let g:airline_detect_modified = 0
    let g:airline_force_tabline_update = 1
    set tabline=%!airline#extensions#tabline#get()
		" doautocmd User BufMRUChange
    call airline#extensions#tabline#update_tabline2()  
    let g:airline_detect_modified = detect_modified
endfunction

function! airline#extensions#tabline#buflist#move_cur_buf_forward()
    call airline#extensions#tabline#buflist#move_cur_buf_dir(1)
endfunction

function! airline#extensions#tabline#buflist#move_cur_buf_backward()
    call airline#extensions#tabline#buflist#move_cur_buf_dir(0)
endfunction



" if we dont have anything in ordered, simply copy
" else lookup each buffer in the new list and find its spot in the ordered list


function! airline#extensions#tabline#buflist#list()
  echom "buflist list"
  if exists('s:current_buffer_list')
    if len(s:current_buffer_list) > 0
      echom "first in order: " . s:current_buffer_list[0]
    endif
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

  if !exists('s:ordered_buffs')
    echom "copy from buffers to ordered buffers"
    let s:ordered_buffs = copy(buffers)
  elseif len(s:ordered_buffs) == 0
    echom "copy from buffers to ordered buffers"
    let s:ordered_buffs = copy(buffers)
  else
    let append_list = []
    " make sure we have everything represented in the ordered buffer

    " TODO handle situation when entry is in ordered but not unordered
    "      This happens when a buffer is deleted.
    for nr in buffers
      let buf_found = 0
      for ordered_nr in s:ordered_buffs
        if nr == ordered_nr
          let buf_found = 1
          break
        endif
      endfor

      if !buf_found
        call add(append_list, nr)
      endif

    endfor

    for nr in append_list
      echom "appending missing buffer: " . nr
      call add(s:ordered_buffs, nr)
    endfor

  endif

  if len(s:ordered_buffs) > 0
    echom "first in order: " . s:ordered_buffs[0]
  endif

  " let s:current_buffer_list = buffers
  let s:current_buffer_list = copy(s:ordered_buffs)
  return copy(s:ordered_buffs) 
endfunction

