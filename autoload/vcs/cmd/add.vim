" vcs:cmd:add: Add specified files or directories to versioning.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim


let s:openbuf = openbuf#new('vcs/cmd/add', {
\ })


let s:cmd = {
\   'name': 'add',
\ }

function! s:cmd.depends()
  return ['add']
endfunction

function! s:cmd.execute(type, ...)
  let files = a:0 ? map(copy(a:000), 'fnamemodify(v:val, ":p")')
  \              : vcs#expand('%:p')
  call s:openbuf.open('[vcs:add]')
  setlocal buftype=nofile nobuflisted noswapfile
  execute 'lcd' a:type.workdir
  let out = a:type.add(files)
  call s:openbuf.do('silent bdelete!')
  return out
endfunction

function! s:cmd.complete(args)
  return map(map(split(glob((empty(a:args) ? '' : a:args[-1]) . '*'), "\n"),
  \          'v:val . (isdirectory(v:val) ? "/" : "")'),
  \          'v:val =~ "\\s" ? "''" . v:val : v:val')
endfunction



function! vcs#cmd#add#load()
  return copy(s:cmd)
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
