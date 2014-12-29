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
let s:status_list = [
      \ 'added',
      \ 'modified',
      \ 'deleted',
      \ 'conflicted',
      \ 'untracked',
      \ 'renamed'
      \]
let s:status_pattern = join(s:status_list, '\|')
let s:status_path_pattern = printf('^#\t\%%(%s\):\t\(.\+\)$', s:status_pattern)

function! s:cmd.depends()
  return ['status', 'add', 'rm', 'reset']
endfunction

nmap <silent> <Plug>(vcs-toggle-cursor-file) :<C-u>call <SID>toggle_cursor_file()<CR>

function! s:cmd.execute(type, ...)
  let self.type = a:type
  let self.files = copy(a:000)

  call s:openbuf.open('[vcs:status]')
  setlocal buftype=nofile nobuflisted noswapfile
  execute 'lcd' a:type.workdir

  let b:vcs_status = self


  nmap <silent><buffer> <Return> <Plug>(vcs-toggle-cursor-file)
  call s:refresh_buffer()

  1
  setlocal filetype=vcs-status

  return ''
endfunction
" Misc.
function! s:find_path_on_status(line)
  if a:line =~# s:status_path_pattern
    return substitute(a:line, s:status_path_pattern, '\1', 'g')
  endif
  return ''
endfunction
function! s:add_cursor_file()
  let cfile = s:find_path_on_status(getline('.'))
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
  let cfile = s:find_path_on_status(getline('.'))
  if cfile ==# '#' || cfile == '' || cfile =~ ':$'
    return
  endif

  call b:vcs_status.type.reset([cfile])
  call s:refresh_buffer()
endfunction
function! s:toggle_cursor_file()
  let cfile = s:find_path_on_status(getline('.'))
  if cfile ==# '#' || cfile == '' || cfile =~ ':$'
    return
  endif

  if index(keys(s:get_staged_files()), cfile) != -1
    call s:remove_cursor_file()
  else
    call s:add_cursor_file()
  endif
endfunction
function! s:get_staged_files()
  if has_key(b:vcs_status.type, '__staged_files')
    return b:vcs_status.type.__staged_files
  else
    let status = b:vcs_status.type.status(b:vcs_status.files)
    let staged_files = filter(copy(status), 'index(s:status_list, v:val) != -1')
    let b:vcs_status.type.__staged_files = staged_files
    return staged_files
  endif
endfunction
function! s:get_unstaged_files()
  if has_key(b:vcs_status.type, '__unstaged_files')
    return b:vcs_status.type.__unstaged_files
  elseif has_key(b:vcs_status.type, 'unstaged_status')
    let status = b:vcs_status.type.unstaged_status(b:vcs_status.files)
    let unstaged_files = filter(copy(status), 'index(s:status_list, v:val) != -1')
    let b:vcs_status.type.__unstaged_files = unstaged_files
    return unstaged_files
  else
    return {}
  endif
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

  " remove staged_files/unstaged_files cache
  if has_key(b:vcs_status.type, '__staged_files')
    unlet! b:vcs_status.type.__staged_files
  endif
  if has_key(b:vcs_status.type, '__unstaged_files')
    unlet! b:vcs_status.type.__unstaged_files
  endif

  " print staged status.
  let staged_files = s:get_staged_files()
  let staged_lines = map(keys(staged_files),
        \ '"#\<TAB>" . staged_files[v:val] . ":\<TAB>" . v:val') 
  if !empty(staged_lines)
    silent $ put ='# Staged files:'
    silent $ put ='#'
    silent $ put =staged_lines
    silent $ put ='#'
  endif

  " print unstaged status.
  let unstaged_files = s:get_unstaged_files()
  let unstaged_lines = map(keys(unstaged_files),
        \ '"#\<TAB>" . unstaged_files[v:val] . ":\<TAB>" . v:val')
  if !empty(unstaged_lines)
    silent $ put ='# Unstaged files:'
    silent $ put ='#'
    silent $ put =unstaged_lines
    silent $ put ='#'
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
