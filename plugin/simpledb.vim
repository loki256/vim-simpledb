
function! s:GetQuery(first, last)
  let query = ''
  let lines = getline(a:first, a:last)
  for line in lines
    if line !~ '--.*'
      let query .= line . "\n"
    endif
  endfor

  return query
endfunction

function! s:ShowResults()
  let source_buf_nr = bufnr('%')

  if !exists('s:result_buf_nr')
    let s:result_buf_nr = -1
  endif

  if bufwinnr(s:result_buf_nr) > 0
    exec bufwinnr(s:result_buf_nr) . "wincmd w"
  else
    exec 'silent! botright ' . 'sview +set\ autoread /tmp/vim-simpledb-result.txt '
    let s:result_buf_nr = bufnr('%')
  endif

  exec bufwinnr(source_buf_nr) . "wincmd w"
endfunction

function! simpledb#ExecuteSql() range
  let conprops = matchstr(getline(1), '--\s*\zs.*')
  let adapter = matchlist(conprops, 'db:\(\w\+\)')
  let conprops = substitute(conprops, "db:\\w\\+", "", "")
  let query = s:GetQuery(a:firstline, a:lastline)
  redir! > /tmp/vim-simpledb-query.sql
  silent echo query
  redir END

  if len(adapter) > 1 && adapter[1] == 'mysql'
    let cmdline = s:MySQLCommand(conprops)
  else
    let cmdline = s:PostgresCommand(conprops)
  endif

  silent execute '!(' . cmdline . ' > /tmp/vim-simpledb-result.txt) 2> /tmp/vim-simpledb-error.txt'
  silent execute '!(cat /tmp/vim-simpledb-error.txt >> /tmp/vim-simpledb-result.txt)'
  call s:ShowResults()
  redraw!
endfunction

function! s:MySQLCommand(conprops)
  let cmdline = 'mysql -v -v -v -t ' . a:conprops . ' < /tmp/vim-simpledb-query.sql'
  return cmdline
endfunction

function! s:PostgresCommand(conprops)
  let cmdline = 'psql ' . a:conprops . ' < /tmp/vim-simpledb-query.sql'
  return cmdline
endfunction

command! -range=% SimpleDBExecuteSql <line1>,<line2>call simpledb#ExecuteSql()
