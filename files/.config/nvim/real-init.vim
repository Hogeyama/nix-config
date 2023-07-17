
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"" Options{{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

syntax on
filetype plugin indent on
set fileencodings=utf-8,cp932
set termencoding=utf-8
set termguicolors
set mouse=n
set ambiwidth=single
set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()
set fillchars=fold:-
set visualbell t_vb=
set hidden
set modeline
set nonumber
set expandtab
set tabstop=2 shiftwidth=2 softtabstop=2
set autoindent
set linebreak
set breakindent
set breakindentopt=shift:0
set showbreak=
set noswapfile
set nobackup
set noundofile
set conceallevel=0
set concealcursor=
set laststatus=2
set completeopt=menuone,noselect,noinsert
set scrolloff=5
set history=100
set wildmenu
set wildmode=longest:full,full
set ignorecase
set smartcase
set list
set listchars=tab:>─,trail:_
set whichwrap =b,s,h,l,<,>,[,]
set backspace=indent,eol,start
set wildoptions=pum
set showtabline=2
set switchbuf="split"
set updatetime=300
"}}}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"" Key Mappings{{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let mapleader=","
let maplocalleader=","
"""esc
"inoremap jk <Esc>
nnoremap <C-\> :update<CR>
inoremap <C-\> <Esc>:update<CR>
nnoremap <C-s> :w<CR>
inoremap <C-s> <Esc>:w<CR>
nnoremap <C-n> :w<CR>
inoremap <C-n> <Esc>:w<CR>
"""tab
nnoremap <silent> tt  :<C-u>tabe<CR>
nnoremap tg gT
"""delete
nnoremap dk ddk
nnoremap dj dd
inoremap <C-w> <esc>ldba
"""yank
nnoremap Y  y$
"""window
nnoremap zh <C-w>h
nnoremap zj <C-w>j
nnoremap zk <C-w>k
nnoremap zl <C-w>l
nnoremap cj <C-w>j:q<CR><C-w>k
nnoremap ck <C-w>k:q<CR><C-w>j
nnoremap ch <C-w>h:q<CR><C-w>l
nnoremap cl <C-w>l:q<CR><C-w>h
"""folding
nnoremap zn za
"""moving: normal mode
nnoremap <C-a> I
nnoremap <C-e> A
nnoremap gJ J
noremap J 5j
noremap K 5k
noremap H B
noremap L W
noremap <A-h> gE
noremap <A-l> E
nnoremap j gj
nnoremap k gk
vnoremap j gj
vnoremap k gk
nnoremap gj j
nnoremap gk k
vnoremap gj j
vnoremap gk k
"""moving: insert mode
inoremap <C-j> <down>
inoremap <C-k> <up>
inoremap <C-h> <left>
inoremap <C-l> <right>
inoremap <C-b> <esc>lBi
inoremap <C-a> <esc>I
inoremap <C-e> <esc>A
"""moving: mode
cnoremap <C-j> <down>
cnoremap <C-k> <up>
"""terminal
nnoremap te :terminal<CR>
nnoremap vs :rightbelow vs<CR>
tnoremap <C-j><C-k> <C-\><C-n>
tnoremap JK         <C-\><C-n><C-w>h
tnoremap zh         <C-\><C-n><C-w>h
tnoremap zj         <C-\><C-n><C-w>j
tnoremap zk         <C-\><C-n><C-w>k
tnoremap zl         <C-\><C-n><C-w>l
tnoremap zz         <C-\><C-n>
tnoremap zgt        <C-\><C-n>gt
tnoremap ztg        <C-\><C-n>gT
"""other
nnoremap <Space>cd :cd %:h<CR>
nnoremap ^ :noh<CR>
vnoremap * "zy:let @/ = @z<CR>n
"nnoremap <C-n> :CNextRecursive<CR>
"nnoremap <C-p> :CPreviousRecursive<CR>
nnoremap <M-n> :LNextRecursive<CR>
nnoremap <M-p> :LPreviousRecursive<CR>

nnoremap :w<CR> :echom "yo"<CR>
"}}}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"" Custom Commands{{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

command! -nargs=+ -complete=command Redir let s:reg = @@ | redir @"> | silent execute <q-args> | redir END | e /tmp/vim_tmp_redir | pu | 1,2d_ | let @@ = s:reg
command! RmTrailingWhiteSpaces %s/\s\+$//g | :noh
command! LNextRecursive call CRecursive("lnext")
command! LPreviousRecursive call CRecursive("lprevious")
command! CNextRecursive call CRecursive("cnext")
command! CPreviousRecursive call CRecursive("cprevious")
function! CRecursive(cmd) abort "{{{
  let p0 = getpos('.')
  let p  = p0
  try
    while p is p0
      execute a:cmd
      let p = getpos('.')
    endwhile
  catch
    echomsg "no more items"
  endtry
endfunction "}}}
let g:current_buf = 0
au WinLeave * let g:last_win = winnr() | let g:last_file = expand("%:p")
au TabLeave * let g:last_tab = tabpagenr()
au BufLeave * let g:last_buf = g:current_buf | let g:current_buf = bufnr('%')
command! -nargs=0 MoveToLastWin execute "normal! ".g:last_win."<C-w><C-w>"
command! -nargs=0 MoveToLastTab execute "tabnext ".g:last_tab
command! -complete=file -nargs=1 EditBehind    edit <args>    | MoveToLastWin
command! -complete=file -nargs=1 TabEditBehind tabedit <args> | MoveToLastTab

function CursorColumnForAWhile()
  setlocal cursorcolumn
  if exists('g:cursorcolumn_timer')
    call timer_stop(g:cursorcolumn_timer)
  endif
  let g:cursorcolumn_timer = timer_start(1000, function('NoCursorColumn'))
endfunction
function NoCursorColumn(...)
  setlocal nocursorcolumn
endfunction
nnoremap <C-c> :call CursorColumnForAWhile()<CR>
"}}}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"" Per file-type configuration (TODO move to ftplugin){{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"terminal"{{{
"nvim_treesitter#foldexpr()が有効になっているとめちゃくちゃ重くなる
"なぜかnofoldenableでも重いので、foldmethod=manualにする
autocmd FileType floaterm setlocal foldmethod=manual
"}}}

"C"{{{
autocmd FileType c setlocal expandtab tabstop=4 shiftwidth=4 softtabstop=4
"}}}

"Java"{{{
autocmd FileType java setlocal tabstop=4 shiftwidth=4 softtabstop=4
"}}}

"sh"{{{
autocmd FileType sh   setlocal expandtab shiftwidth=4
autocmd FileType bash setlocal expandtab shiftwidth=4
"}}}

"markdown"{{{
autocmd FileType markdown setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
"}}}

"Haskell"{{{
autocmd FileType haskell setlocal tabstop=2 shiftwidth=2 softtabstop=0 ambiwidth=single
autocmd FileType haskell inoremap <buffer> <C-d> $

""syntax
let g:haskell_enable_quantification = 1
let g:haskell_enable_recursivedo = 1
let g:haskell_enable_arrowsyntax = 1
let g:haskell_enable_pattern_synonyms = 1
let g:haskell_enable_typeroles = 1
let g:haskell_enable_static_pointers = 1
let g:haskell_backpack = 1

""other filetype
autocmd FileType cabal   setlocal expandtab tabstop=4
"}}}

"Go"{{{
autocmd FileType go setlocal tabstop=8 shiftwidth=8 softtabstop=8 noexpandtab
"}}}

"Makefile {{{
autocmd FileType make setlocal tabstop=4 shiftwidth=4 softtabstop=4 noexpandtab
"}}}

"vim{{{
autocmd FileType vim setlocal et ts=2 sw=2 sts=2
"}}}

"quickfix{{{
autocmd FileType qf wincmd J
autocmd FileType qf 5 wincmd _
"}}}
"}}}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"" Load machine specific settings{{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if filereadable(expand("~/.config/nvim/local-init.vim"))
  source ~/.config/nvim/local-init.vim
endif
"}}}

" vim:foldmethod=marker:
