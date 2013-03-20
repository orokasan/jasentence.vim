" vi:set ts=8 sts=2 sw=2 tw=0:
scriptencoding utf-8

" plugin/jasentence.vim - ),(でのsentence移動を「、。」までにするスクリプト。
"
" Maintainer: KIHARA Hideto <deton@m1.interq.or.jp>
" Last Change: 2013-03-20
"
" Description:
" * )(での移動時に"。．？！"も文の終わりとみなすようにします。
"   +kaoriya版の)(と同様の動作を、スクリプトで実現します。
"
" オプション:
"    'g:loaded_jasentence'
"       このプラグインを読み込みたくない場合に次のように設定する。
"         let g:loaded_jasentence = 1

if exists('g:loaded_jasentence')
  finish
endif

if !get(g:, 'jasentence_no_default_key_mappings', 0)
  nnoremap <silent> ) :<C-U>call <SID>ForwardS()<CR>
  nnoremap <silent> ( :<C-U>call <SID>BackwardS()<CR>
endif

" TODO: <Plug>
" TODO: support count
" TODO: operator-pending mode
" TODO: visual mode
" TODO: text-object

function! s:ForwardS()
  let origpos = getpos('.')
  normal! )
  let enpos = getpos('.')
  call setpos('.', origpos)
  if search('[、。，．？！]\+\n\=\s*\S', 'eW') == 0
    call setpos('.', enpos)
    return
  endif
  let japos = getpos('.')
  if s:pos_lt(japos, enpos)
    return
  endif
  call setpos('.', enpos)
endfunction

function! s:pos_lt(pos1, pos2)  " less than
  return a:pos1[1] < a:pos2[1] || a:pos1[1] == a:pos2[1] && a:pos1[2] < a:pos2[2]
endfunction

function! s:BackwardS()
  let origpos = getpos('.')
  normal! (
  let enpos = getpos('.')
  call setpos('.', origpos)
  if search('[、。，．？！]\+\n\=\s*\zs\S', 'bW') == 0
    call setpos('.', enpos)
    return
  endif
  let japos = getpos('.')
  if s:pos_lt(enpos, japos)
    return
  endif
  call setpos('.', enpos)
endfunction
