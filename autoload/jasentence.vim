" from vim-textobj-user
function! jasentence#select_function_wrapper(function_name, count1)
  let ORIG_POS = getpos('.')
  let _ = function(a:function_name)(a:count1, 0)
  if _ is 0
    call setpos('.', ORIG_POS)
    return
  endif
  let [motion_type, start_position, end_position] = _
  execute 'normal!' motion_type
  call setpos('.', start_position)
  normal! o
  call setpos('.', end_position)
endfunction

function! jasentence#select_function_wrapperv(function_name, inner)
  let cnt = v:prevcount
  if cnt == 0
    let cnt = 1
  endif
  " 何も選択されていない場合、textobj選択
  let pos = getpos('.')
  execute 'normal! gvo' . "\<Esc>"
  let otherpos = getpos('.')
  execute 'normal! gvo' . "\<Esc>"
  if pos == otherpos
    call jasentence#select_function_wrapper(a:function_name, cnt)
    return
  endif

  " 選択済の場合、選択領域をextendする
  if jasentence#pos_lt(pos, otherpos)
    " backward
    if a:inner
      call jasentence#select_b(cnt, 1)
    else
      call jasentence#select_b(cnt, 0)
    endif
  else
    if a:inner
      call jasentence#select_i(cnt, 1)
    else
      call jasentence#select_a(cnt, 1)
    endif
  endif
  let newpos = getpos('.')
  normal! gv
  call setpos('.', newpos)
endfunction

function! jasentence#select_a(cnt, visual)
  return jasentence#select(a:cnt, 0, a:visual)
endfunction

function! jasentence#select_i(cnt, visual)
  return jasentence#select(a:cnt, 1, a:visual)
endfunction

function! jasentence#select(cnt, inner, visual)
  let origpos = getpos('.')
  let startonsp = 0
  if a:visual
    call search('.', 'W') " 繰り返しas/isした場合にextendするため
    if jasentence#postype() == 1
      let startonsp = 1
    endif
  else
    let postype = jasentence#postype()
    if postype == 1
      " 次のsentence直前の連続空白上の場合は、空白開始位置以降を対象にする
      call search('[^\n[:space:]　]\zs[\n[:space:]　]', 'bcW')
      let startonsp = 1
    elseif postype == 2
      " sentence途中の空白上の場合、sentence開始位置以降を対象にする
      call jasentence#BackwardS()
    elseif postype == 4
      " sentence開始位置以降を対象にする
      call jasentence#ForwardS() " 既にsentence先頭にいる場合用
      call jasentence#BackwardS()
      " FIXME: バッファ末尾に1文字だけある場合、直前のsentenceが対象になる
    endif
  endif
  let st = getpos('.')
  let cnt = a:cnt
  let trimendsp = 0
  if a:inner
    " innerの場合はsentence間の空白もcountを消費する。
    " 日本語の場合はsentence間に空白が無い場合があるが、+kaoriya版と同様に消費
    if startonsp " sentence開始直前の連続空白上で開始した場合
      if a:cnt == 1 " sentence開始直前の連続空白のみを対象にする
	call jasentence#ForwardS()
	return ['v', st, jasentence#PrevSentEndPos()]
      endif
      let cnt = a:cnt / 2
      let cnt += 1 " sentence開始位置への移動用に1 count追加
      if a:cnt % 2 == 0
	let trimendsp = 1 " 指定されたcountが偶数ならtrimする
      else
	let trimendsp = 0
      endif
    else
      let cnt = (a:cnt + 1) / 2
      if a:cnt % 2 == 0
	let trimendsp = 0
      else
	let trimendsp = 1
      endif
    endif
  elseif startonsp
    " sentence開始直前の連続空白上だった場合、
    " sentence開始位置への移動で1 count消費するので、1 count追加
    let cnt += 1
    let trimendsp = 1
  endif
  call jasentence#MoveCount('jasentence#ForwardS', cnt)

  if trimendsp
    " 現在位置(対象文字列直後のsentence開始位置)直前の空白は含めない。
    " 現在位置がバッファ末尾かつ空白でない場合は、最後の文字が残らないように。
    if !(jasentence#bufend() && match(getline('.'), '\%' . col('.') . 'c[[:space:]　]') == -1)
      call search('[^[:space:]　]\|^', 'bW')
    endif
    return ['v', st, getpos('.')]
  endif

  let ed = jasentence#PrevSentEndPos()
  " "as"で対象文字列末尾が空白でない場合、開始位置直前に空白があれば含める
  if !a:visual && !a:inner && !startonsp && match(getline('.'), '\%' . col('.') . 'c[[:space:]　]') == -1
    call setpos('.', st)
    " 日本語の場合は空白無しの場合があるので開始位置前の空白以外の文字をsearch
    if search('[^\n[:space:]　]', 'bW') > 0
      call search('.', 'W')
    endif
    let st = getpos('.')
  endif
  return ['v', st, ed]
endfunction

function! jasentence#select_b(cnt, inner)
  let origpos = getpos('.')
  let startonsp = 0
  call search('.', 'bW') " 繰り返しas/isした場合にextendするため
  if jasentence#postype() == 1
    let startonsp = 1
  endif
  let st = getpos('.')
  let cnt = a:cnt
  let extendbegsp = 1
  if a:inner
    let cnt = (a:cnt + 1) / 2
    if startonsp
      let cnt -= 1 " 開始位置の空白に対するcountを減らす
      if cnt <= 0 " 空白のみを選択する
	call search('[^\n[:space:]　]\zs[\n[:space:]　]', 'bcW')
	return ['v', st, getpos('.')]
      endif
      if a:cnt % 2 == 0
	let extendbegsp = 0
      else
	let extendbegsp = 1 " 指定されたcountが奇数なら直前の空白も含める
      endif
    else
      if a:cnt % 2 == 0
	let extendbegsp = 1
      else
	let extendbegsp = 0
      endif
    endif
  elseif startonsp
    let extendbegsp = 0
  endif
  call jasentence#MoveCount('jasentence#BackwardS', cnt)

  " 現在位置直前の空白を含める
  if extendbegsp && search('[^\n[:space:]　]', 'bW') > 0
    call search('.', 'W')
  endif
  return ['v', st, getpos('.')]
endfunction

" 現在のカーソル位置の種別を返す
function! jasentence#postype()
  let origpos = getpos('.')
  let line = getline('.')
  if line == ''
    let ret = 0 " 空行上
  elseif match(line, '\%' . col('.') . 'c[[:space:]　]') != -1
    " カーソルが空白上の場合
    call jasentence#ForwardS()
    let nextsent = getpos('.')
    call setpos('.', origpos)
    if search('[\n[:space:]　]\+[^\n[:space:]　]', 'ceW') > 0
      if jasentence#pos_eq(getpos('.'), nextsent)
	let ret = 1 " 次のsentence直前の連続空白上
      else
	let ret = 2 " sentence途中の空白上
      endif
    else
      let ret = 3 " バッファ末尾の空白上
    endif
  else
    let ret = 4 " sentence内
  endif
  call setpos('.', origpos)
  return ret
endfunction

" バッファ末尾かどうか
function! jasentence#bufend()
  if line('.') != line('$')
    return 0
  endif
  let edtmp = getpos('.')
  call jasentence#ForwardS()
  let pos = getpos('.')
  if jasentence#pos_eq(pos, edtmp)
    return 1
  endif
  call setpos('.', edtmp)
  return 0
endfunction

" 前のsentenceの末尾位置を返す。
" 前提条件: sentence開始位置にカーソルがある
function! jasentence#PrevSentEndPos()
  " バッファ末尾の場合に末尾の文字だけが残ったりしないように
  if jasentence#bufend()
    return getpos('.')
  endif
  " 次sentence直前まで
  if col('.') > 1
    call cursor(0, col('.') - 1)
  else
    call cursor(line('.') - 1, 0)
    call cursor(0, col('$'))
  endif
  return getpos('.')
endfunction

function! jasentence#MoveCount(func, cnt)
  for i in range(a:cnt)
    call call(a:func, [])
  endfor
endfunction

" Forward{S,B}をVisual modeに対応させるためのラッパ
function! jasentence#MoveV(func)
  let cnt = v:prevcount
  if cnt == 0
    let cnt = 1
  endif
  for i in range(cnt)
    call function(a:func)()
  endfor
  let pos = getpos('.')
  normal! gv
  call cursor(pos[1], pos[2])
endfunction

function! jasentence#ForwardS()
  let origpos = getpos('.')
  normal! )
  let enpos = getpos('.')
  call setpos('.', origpos)
  " 全角空白上の場合、blankとみなして、次のnon-blank char上に移動
  if match(getline('.'), '\%' . col('.') . 'c　') != -1
    if search('[^\n[:space:]　]', 'W', enpos[1]) != 0
      return
    endif
  endif
  if search(g:jasentence_endpat . '[\n[:space:]　]*[^[:space:]　]', 'eW', enpos[1]) == 0
    call setpos('.', enpos)
    return
  endif
  let japos = getpos('.')
  if jasentence#pos_lt(japos, enpos)
    return
  endif
  call setpos('.', enpos)
  " 全角空白はblankとみなす
  if match(getline('.'), '\%' . col('.') . 'c　') != -1
    call search('[^\n[:space:]　]', 'W')
  endif
endfunction

function! jasentence#pos_lt(pos1, pos2)  " less than
  return a:pos1[1] < a:pos2[1] || a:pos1[1] == a:pos2[1] && a:pos1[2] < a:pos2[2]
endfunction

function! jasentence#pos_eq(pos1, pos2)  " equal
  return a:pos1[1] == a:pos2[1] && a:pos1[2] == a:pos2[2]
endfunction

function! jasentence#BackwardS()
  let origpos = getpos('.')
  normal! (
  let enpos = getpos('.')
  call setpos('.', origpos)
  if search('\%(' . g:jasentence_endpat . '\|^\)[\n[:space:]　]*\zs[^[:space:]　]', 'bW', enpos[1]) == 0
    call setpos('.', enpos)
    " 全角空白はblankとみなす
    if match(getline('.'), '\%' . col('.') . 'c　') != -1
      call search('[^\n[:space:]　]', 'bW')
    endif
    return
  endif
  let japos = getpos('.')
  if jasentence#pos_lt(enpos, japos)
    return
  endif
  call setpos('.', enpos)
endfunction
