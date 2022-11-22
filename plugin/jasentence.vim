" vi:set ts=8 sts=2 sw=2 tw=0:
scriptencoding utf-8

" plugin/jasentence.vim - 日本語句読点もsentence終了として扱うスクリプト。
"
" Maintainer: KIHARA Hideto <deton@m1.interq.or.jp>
" Last Change: 2013-05-08
"
" Description:
" * )(での移動時に"、。，．？！"も文の終わりとみなすようにします。
"   +kaoriya版の)(と同様の動作を、スクリプトで実現します。
"
" オプション:
"    'g:loaded_jasentence'
"       このプラグインを読み込みたくない場合に次のように設定する。
"         let g:loaded_jasentence = 1

if exists('g:loaded_jasentence')
  finish
endif

" 日本語sentenceの終了位置特定用パターン
if !exists('g:jasentence_endpat')
  let g:jasentence_endpat = '[、。，．？！]\+'
endif

nnoremap <silent> <Plug>JaSentenceMoveNF :<C-U>call jasentence#MoveCount('jasentence#ForwardS', v:count1)<CR>
nnoremap <silent> <Plug>JaSentenceMoveNB :<C-U>call jasentence#MoveCount('jasentence#BackwardS', v:count1)<CR>
onoremap <silent> <Plug>JaSentenceMoveOF :<C-U>call jasentence#MoveCount('jasentence#ForwardS', v:count1)<CR>
onoremap <silent> <Plug>JaSentenceMoveOB :<C-U>call jasentence#MoveCount('jasentence#BackwardS', v:count1)<CR>
vnoremap <silent> <Plug>JaSentenceMoveVF <Esc>:call jasentence#MoveV('jasentence#ForwardS')<CR>
vnoremap <silent> <Plug>JaSentenceMoveVB <Esc>:call jasentence#MoveV('jasentence#BackwardS')<CR>

onoremap <silent> <Plug>JaSentenceTextObjA :<C-U>call jasentence#select_function_wrapper('jasentence#select_a', v:count1)<CR>
onoremap <silent> <Plug>JaSentenceTextObjI :<C-U>call jasentence#select_function_wrapper('jasentence#select_i', v:count1)<CR>
vnoremap <silent> <Plug>JaSentenceTextObjVA <Esc>:call jasentence#select_function_wrapperv('jasentence#select_a', 0)<CR>
vnoremap <silent> <Plug>JaSentenceTextObjVI <Esc>:call jasentence#select_function_wrapperv('jasentence#select_i', 1)<CR>

if !get(g:, 'jasentence_no_default_key_mappings', 0)
  nmap <silent> ) <Plug>JaSentenceMoveNF
  nmap <silent> ( <Plug>JaSentenceMoveNB
  omap <silent> ) <Plug>JaSentenceMoveOF
  omap <silent> ( <Plug>JaSentenceMoveOB
  xmap <silent> ) <Plug>JaSentenceMoveVF
  xmap <silent> ( <Plug>JaSentenceMoveVB
  omap <silent> as <Plug>JaSentenceTextObjA
  omap <silent> is <Plug>JaSentenceTextObjI
  xmap <silent> as <Plug>JaSentenceTextObjVA
  xmap <silent> is <Plug>JaSentenceTextObjVI
endif

