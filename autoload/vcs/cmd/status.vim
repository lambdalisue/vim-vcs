" vcs:cmd:status: Show the status of files.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim

let s:openbuf = openbuf#new('vcs/cmd/status', {
\ })

let s:cmd = {
\   'name': 'status',
\ }

function! s:cmd.depends()
  return ['status', 'root']
endfunction

function! s:cmd.execute(type, ...)
  let self.type = a:type
  let self.files = copy(a:000)
  call s:openbuf.open('[vcs:status]')
  let b:vcs_status = self

  setlocal buftype=nofile nobuflisted noswapfile

  nnoremap <silent><buffer> <Enter> :<C-u>call <SID>add_cursor_file()<CR>
  nnoremap <silent><buffer> -       :<C-u>call <SID>remove_cursor_file()<CR>

  call s:refresh_buffer()

  1
  setlocal filetype=vcs-status

  return ''
endfunction

" Misc.
function! s:add_cursor_file()
  let cfile = expand('<cfile>')
  if cfile ==# '#' || cfile == '' || cfile =~ ':$'
    return
  endif

  let status = matchstr(getline('.'), '^#\t\zs\h\w*\ze:')
  if status ==# 'deleted'
    call b:vcs_status.type.rm([cfile])
  else
    call b:vcs_status.type.add([cfile])
  endif

  call s:refresh_buffer()
endfunction
function! s:remove_cursor_file()
  let cfile = expand('<cfile>')
  if cfile ==# '#' || cfile == '' || cfile =~ ':$'
    return
  endif

  call b:vcs_status.type.reset([cfile])
  call s:refresh_buffer()
endfunction
function! s:refresh_buffer()
  let pos = getpos('.')
  silent % delete _

  " print current branch.
  if has_key(b:vcs_status.type, 'current_branch')
    let current_branch = b:vcs_status.type.current_branch()
    if current_branch != ''
      silent $ put ='# On branch '.current_branch
      silent $ put ='#'
    endif
  endif

  " print staged status.
  let status = b:vcs_status.type.status(b:vcs_status.files)
  let staged_lines = []
  for st in ['added', 'modified', 'deleted', 'conflicted', 'untracked', 'renamed']
    let files = filter(copy(status), 'v:val ==# st')
    if !empty(files)
      let staged_lines += map(keys(files), '"#\<TAB>" . st . ":\<TAB>" . v:val')
    endif
  endfor
  if !empty(staged_lines)
    silent $ put ='# Staged files:'
    silent $ put ='#'
    silent $ put =staged_lines
    silent $ put ='#'
  endif

  " print unstaged status.
  if has_key(b:vcs_status.type, 'unstaged_status')
    let status = b:vcs_status.type.unstaged_status(b:vcs_status.files)
    let unstaged_lines = []
    for st in ['added', 'modified', 'deleted', 'conflicted', 'untracked', 'renamed']
      let files = filter(copy(status), 'v:val ==# st')
      if !empty(files)
        let unstaged_lines += map(keys(files), '"#\<TAB>" . st . ":\<TAB>" . v:val')
      endif
    endfor
    if !empty(unstaged_lines)
      silent $ put ='# Unstaged files:'
      silent $ put ='#'
      silent $ put =unstaged_lines
      silent $ put ='#'
    endif
  endif

  if empty(staged_lines) && empty(unstaged_lines)
    call setline(1, '# nothing to commit')
  else
    silent 1delete _
  endif

  call setpos('.', pos)
endfunction



function! vcs#cmd#status#load()
  return copy(s:cmd)
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
