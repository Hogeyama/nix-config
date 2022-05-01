"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"" General
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Plug{{{
" Install vim-plug if not found
if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif
call plug#begin('~/.config/nvim/plugged')
" otameshi
Plug 'vim-denops/denops.vim'
Plug 'vim-denops/denops-helloworld.vim'
" LOVE
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'Shougo/deol.nvim'
Plug 'Shougo/neosnippet'
Plug 'Shougo/neosnippet-snippets'
Plug 'kana/vim-submode'
Plug 'editorconfig/editorconfig-vim'
Plug 'voldikss/vim-floaterm'
"""便利
Plug 'easymotion/vim-easymotion'
Plug 'godlygeek/tabular'
Plug 'junegunn/vim-easy-align'
Plug 'tomtom/tcomment_vim'
Plug 'machakann/vim-sandwich'
Plug 'itchyny/lightline.vim'
Plug 'AndrewRadev/linediff.vim'
Plug 'machakann/vim-highlightedyank'
Plug 'Yggdroot/indentLine'
Plug 'wellle/visual-split.vim'
Plug 'glidenote/memolist.vim'
Plug 'kana/vim-metarw'
Plug 'mattn/vim-metarw-redmine'
Plug 'mattn/webapi-vim'
""Git TODO 整理
Plug 'tpope/vim-fugitive'
Plug 'jreybert/vimagit'
Plug 'lambdalisue/gina.vim'
""Motion
Plug 'rhysd/clever-f.vim'
"""filetype
"Haskell
Plug 'neovimhaskell/haskell-vim'
Plug 'vim-scripts/alex.vim'
Plug 'vim-scripts/happy.vim'
Plug 'LnL7/vim-nix'
Plug 'ndmitchell/ghcid', { 'rtp': 'plugins/nvim', 'tag': 'v0.6.10' }
""Dhall
Plug 'vmchale/dhall-vim'
"""Python
Plug 'vim-python/python-syntax'
""MarkDown
Plug 'preservim/vim-markdown'
Plug 'vim-voom/VOoM'
""Textile
Plug 's3rvac/vim-syntax-redminewiki'
""Rust
Plug 'rust-lang/rust.vim'
""JavaScript/TypeScript
Plug 'jelera/vim-javascript-syntax'
Plug 'leafgarland/typescript-vim'
"""Color Scheme
Plug 'zsoltf/vim-maui'
Plug 'rakr/vim-one'
Plug 'w0ng/vim-hybrid'
Plug 'tyrannicaltoucan/vim-deep-space'
Plug 'chriskempson/base16-vim'
"""otameshi
Plug 'github/copilot.vim'
Plug 'preservim/nerdtree'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
call plug#end()
"}}}

"Color"{{{
syntax on
set background=dark
colorscheme deep-space
" colorscheme maui

set termguicolors
command! GoodMatchParen hi MatchParen ctermfg=253 guifg=#dadada ctermbg=0 guibg=#000000
GoodMatchParen
" hi Normal guibg=None
hi Folded ctermbg=None guibg=None
hi LineNr ctermbg=None guibg=None
autocmd InsertLeave * GoodMatchParen

"}}}

"Set{{{
filetype plugin indent on
set fileencodings=utf-8,cp932
set termencoding=utf-8
let mapleader=","
let maplocalleader=","

filetype plugin on
filetype indent on
set mouse=n
" set ambiwidth=double
set ambiwidth=single
set foldmethod=marker
set fillchars=fold:-
set visualbell t_vb=
set hidden
set modeline
set number
set expandtab
set tabstop=2 shiftwidth=2 softtabstop=2
set autoindent
set linebreak
set breakindent
set breakindentopt=shift:0
set showbreak=..
" set showbreak=\ \ 
" set showbreak=\ \ >\
" set showbreak=
set noswapfile
set nobackup
set noundofile
set conceallevel=0
set concealcursor=
set laststatus=2
set completeopt=menuone,noselect,noinsert
"set autoread
set scrolloff=5
set history=100
set wildmenu
set wildmode=longest:full,full
set ignorecase
set smartcase
set list
" set listchars=tab:>.,trail:_
set listchars=tab:>─,trail:_
set whichwrap =b,s,h,l,<,>,[,]
set backspace=indent,eol,start
set wildoptions=pum
set showtabline=2
set switchbuf="split"
set conceallevel=0
autocmd QuickFixCmdPost *grep* cwindow
autocmd FileType qf wincmd J
autocmd FileType qf 5 wincmd _
autocmd FileType nerdtree 30 wincmd |
"}}}

" Clipboard {{{
function! MyClipboard(lines,regtype) abort
  call extend(g:, {'my_clipboard': [a:lines, a:regtype]})
  call system("myclip", a:lines)
endfunction
" let g:clipboard = {
"       \   'name': 'myClipboard',
"       \   'copy': {
"       \      '+': function("MyClipboard"),
"       \      '*': function("MyClipboard")
"       \    },
"       \   'paste': {
"       \      '+': {-> get(g:, 'my_clipboard', [])},
"       \      '*': {-> get(g:, 'my_clipboard', [])},
"       \   },
"       \ }
"}}}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"" Plugin
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"Copilot{{{
imap <silent><script><expr><Right> copilot#Accept("\<Right>")
let g:copilot_no_tab_map = v:true
"}}}

"NERDTree{{{
let g:NERDTreeCaseSensitiveSort = 1
let g:NERDTreeMapActivateNode = 'l'
let g:NERDTreeMapCloseDir = 'h'
"}}}

"memolist{{{
let g:memolist_path = "~/.memo"
let g:memolist_template_dir_path = "~/.memo/template"
command! MemoToday MemoNewWithMeta 'note', 'daily', 'daily'
nnoremap <C-t> :MemoToday<CR>
"}}}

"floaterm{{{
let g:floaterm_width = 0.9
let g:floaterm_height = 0.9
nnoremap <F6> :FloatermToggle shell6<CR>
tnoremap <F6> <C-\><C-n>:FloatermToggle shell6<CR>
nnoremap <F7> :FloatermToggle shell7<CR>
tnoremap <F7> <C-\><C-n>:FloatermToggle shell7<CR>
nnoremap <F8> :ToggleFloatermFzf<CR>
tnoremap <F8> <C-\><C-n>:ToggleFloatermFzf<CR>
nnoremap <F9> :FloatermToggle shell9<CR>
tnoremap <F9> <C-\><C-n>:FloatermToggle shell9<CR>
command! ToggleFloatermFzf call ToggleFloatermFzfFun()
function! ToggleFloatermFzfFun() abort
  if get(g:,'floaterm_fzf_exists',0)
    FloatermToggle fzf
  else
    FloatermNew  --name=fzf
    FloatermSend --name=fzf myfzf
    let g:floaterm_fzf_exists=1
  endif
endfunction
hi FloatermBorder guibg=None guifg=cyan
"}}}

"sandwich{{{
vmap s <Plug>(operator-sandwich-add)
"}}}

"editorconfig{{{
let g:EditorConfig_max_line_indicator = 'exceeding'
"}}}

"LSP {{{
nnoremap [lsp] <nop>
xnoremap [lsp] <nop>
nmap     <C-l> [lsp]
xmap     <C-l> [lsp]
nmap     <C-j>  <Plug>(coc-definition)
nmap     [lsp]j <Plug>(coc-definition)
nmap     [lsp]r <Plug>(coc-references)
nmap     [lsp]f <Plug>(coc-format)
xmap     [lsp]f <Plug>(coc-format-selected)
nmap     [lsp]a <Plug>(coc-codeaction)
nmap     <F2>   <Plug>(coc-rename)
nmap     [lsp]l <Plug>(coc-codelens-action)
nmap     [lsp]n <Plug>(coc-diagnostics-next)
nmap     [lsp]p <Plug>(coc-diagnostics-prev)
nnoremap [lsp]c :CocCommand<CR>
nnoremap [lsp]d :CocDiagnostics<CR>
nnoremap [lsp]D :call CocActionAsync("diagnosticList", {err,res -> SetQf(err,res)})<CR>
nnoremap [lsp]h :call CocActionAsync('doHover')<CR>
nnoremap <C-h>  :call CocActionAsync('doHover')<CR>
"}}}

"coc.nvim {{{
set updatetime=300
let g:coc_start_at_startup=1
let g:coc_global_extensions = [
  \ 'coc-json',
  \ 'coc-yaml',
  \ 'coc-prettier',
  \ 'coc-lists',
  \ 'coc-snippets',
  \ 'coc-neosnippet',
  \ 'coc-go',
  \ 'coc-tsserver',
  \ 'coc-deno',
  \ 'coc-diagnostic',
  \ ]
  " \ 'coc-git'
  " \ 'coc-pairs',
  " \ 'coc-highlight'
  " \ 'coc-java',
  " \ 'coc-pyright',
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction
inoremap <expr> <CR>
  \ pumvisible() ? coc#refresh()."\<C-y>" : "\<CR>"
inoremap <silent><expr> <Tab>
  \ pumvisible() ? "\<C-n>" :
  \ <SID>check_back_space() ? "\<Tab>" :
  \ coc#refresh()
inoremap <silent><expr> <S-Tab>
  \ pumvisible() ? "\<C-p>" :
  \ <SID>check_back_space() ? "\<S-Tab>" :
  \ coc#refresh()
nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
nnoremap <Space>e :CocCommand explorer<CR>

function! SetQf(cocList) abort
  let qfList = map(a:cocList, { ->
      \ { 'filename': v:val.file
      \ , 'lnum'    : v:val.lnum
      \ , 'col'     : v:val.col
      \ , 'text'    : v:val.message
      \ , 'type'    : v:val.severity is 'Error'       ? 'E'
      \             : v:val.severity is 'Hint'        ? 'H'
      \             : v:val.severity is 'Warning'     ? 'W'
      \             : v:val.severity is 'Information' ? 'I'
      \             : "I"
      \ , 'vcol'    : 0
      \ }
      \ })
  call setqflist(qfList, "r")
endfunction
autocmd User CocDiagnosticChange :call CocActionAsync("diagnosticList", {err,res -> SetQf(res)})<CR>
"}}}

"neosnippet{{{
imap <C-f> <Plug>(neosnippet_expand_or_jump)
smap <C-f> <Plug>(neosnippet_expand_or_jump)
xmap <C-f> <Plug>(neosnippet_expand_target)
let g:neosnippet#enable_conceal_markers = 0
let g:neosnippet#snippets_directory = '~/.config/nvim/snippets'
"}}}

"lightline{{{
let g:lightline = {}
let g:lightline.component_function = {
      \ 'cocstatus': 'coc#status'
      \ }
let g:lightline.active = {
      \ 'left':  [['mode', 'paste'], ['readonly', 'relativepath', 'filetype', 'modified']],
      \ 'right': [['lineinfo'], ['percent'], ['fileformat', 'fileencoding', 'cocstatus']]
      \}
let g:lightline.inactive = {
      \ 'left':  [['relativepath', 'modified']],
      \ 'right': [['lineinfo'], ['percent']]
      \}
let g:lightline.tabline = {
      \ 'left':  [['tabs']],
      \ 'right': [['cwd']]
      \}
let g:lightline.component = {
      \ 'cwd': '%{fnamemodify(getcwd(), ":~")}',
      \}
function! SetLightlineConfig() abort
  augroup lightline
    autocmd!
    autocmd WinEnter,SessionLoadPost * call lightline#update()
    autocmd SessionLoadPost * call lightline#highlight()
    autocmd ColorScheme * if !has('vim_starting')
          \ | call lightline#update() | call lightline#highlight() | endif
  augroup END
endfunction
autocmd VimEnter * call SetLightlineConfig()
"}}}

"{{{Neomake
let g:neomake_open_list=0
" let g:neomake_open_list=2
let g:neomake_place_signs=0
let g:neomake_echo_current_error=0
let g:neomake_virtualtext_current_error=0
nnoremap ! :NeomakeSh 
"}}}

"tcomment{{{
nmap ,, <Plug>TComment_gcc
vmap ,, <Plug>TComment_gc
vmap ,l <Plug>TComment_,_r
"vmap ,b <Plug>TComment_,_b
"vmap ,i <Plug>TComment_,_i
vmap ,b :TCommentRight!<CR>
vmap ,i :TCommentInline!<CR>
"}}}

"git-gutter {{{
let g:gitgutter_map_keys = 0
let g:gitgutter_signs = 0
nnoremap [gitgutter] <nop>
nmap     <C-g> [gitgutter]
nnoremap [gitgutter]n :GitGutterNextHunk<CR>
nnoremap [gitgutter]p :GitGutterPrevHunk<CR>
nnoremap [gitgutter]P :GitGutterPreviewHunk<CR>
nnoremap [gitgutter]e :GitGutterSignsEnable<CR>
nnoremap [gitgutter]d :GitGutterSignsDisable<CR>
nnoremap [gitgutter]s :GitGutterStageHunk<CR>
"}}}

"submode{{{
let g:submode_always_show_submode = 1
let g:submode_timeout = 0
"}}}

" indentLine {{{
let g:indentLine_enabled = 0
let g:indentLine_char = '⁞' "U+205E VERTICAL FOUR DOTS
let g:indentLine_char = '⏐' "U+23D0 VERTICAL LINE EXTENSION
"}}}

"EasyMotion{{{
let g:EasyMotion_keys='jfkdlamvneioc'
let g:EasyMotion_do_mapping = 0
let g:EasyMotion_smartcase = 1
let g:EasyMotion_enter_jump_first = 1
"}}}

"clever-f.vim{{{
let g:clever_f_smart_case = 1
"}}}

"vim-easy-align {{{
vmap <Enter> <Plug>(EasyAlign)
"}}}

"Rainbow {{{
autocmd FileType lisp nmap <buffer> <F7> :RainbowToggle<CR>
let g:rainbow_conf = {
\   'guifgs': ['royalblue3', 'darkorange3', 'seagreen3', 'firebrick'],
\   'ctermfgs': ["darkblue", "darkgreen", "red", "yellow"],
\   'operators': '_,_',
\   'parentheses': ['start=/(/ end=/)/ fold', 'start=/\[/ end=/\]/ fold', 'start=/{/ end=/}/ fold'],
\   'separately': {
\     '*': {},
\     'tex': {
\       'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/'],
\     },
\   }
\ }
"\  'guifgs': ['royalblue3', 'darkorange3', 'seagreen3', 'firebrick'],
"\  'ctermfgs': ['lightblue', 'lightyellow', 'lightcyan', 'lightmagenta'],
"\       'guifgs': ['royalblue3', 'darkorange3', 'seagreen3', 'firebrick', 'darkorchid3'],
"}}}

"ghcid {{{
let g:ghcid_keep_open=1
let g:ghcid_command='ghcid-docker.sh'
"}}}

"Redmine{{{
if filereadable(expand("~/.redmine_api_key"))
  let g:metarw_redmine_server = readfile(expand("~/.redmine_api_key"))[0]
  let g:metarw_redmine_apikey = readfile(expand("~/.redmine_api_key"))[1]
endif
au BufNewFile,BufRead             *.redmine  set filetype=redminewiki
au BufNewFile,BufRead,InsertLeave redmine:/* set filetype=redminewiki ro
"}}}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"" FileType
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"C"{{{
autocmd FileType c setlocal expandtab ts=4 sts=4 sw=4
"}}}

"Java"{{{
autocmd FileType java setlocal tabstop=4 shiftwidth=4 softtabstop=4
"}}}

"sh"{{{
autocmd FileType sh   setlocal expandtab shiftwidth=2
autocmd FileType bash setlocal expandtab shiftwidth=2
"}}}

"Haskell"{{{
autocmd FileType haskell setlocal tabstop=2 shiftwidth=2 softtabstop=0 ambiwidth=single
autocmd FileType haskell inoremap <buffer> <C-d> $
autocmd FileType haskell let @a = "->"
autocmd FileType haskell let @b = "<-"

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
autocmd! BufNewFile,BufFilePRe,BufRead *.x set filetype=alex
autocmd! BufNewFile,BufFilePRe,BufRead *.y set filetype=happy
"}}}

"OCaml"{{{
""general
autocmd FileType ocaml setlocal tabstop=2 shiftwidth=2 softtabstop=0 commentstring=(*%s*)
""merlin
autocmd FileType ocaml let g:neomake_enabled_makers = ['dune'] "b:だと効かない
let g:neomake_ocaml_dune_maker = {
      \ 'exe': 'dune',
      \ 'args': ['build'],
      \ 'errorformat':
      \   join([ "%DEntering directory '%f',"
      \        , 'File "%f"\, line %l\, characters %c%m,%m']),
      \}
"config for merlin and ocp-indent
let g:opamshare = substitute(system('opam config var share'),'\n$','','''')
try
  execute "set rtp+=" . g:opamshare . "/merlin/vim"
  execute "helptags " . g:opamshare . "/merlin/vim/doc"
  execute "set rtp^=" . g:opamshare . "/ocp-indent/vim"
  execute "set rtp^=" . g:opamshare . "/ocp-index/vim"
catch /.*/
endtry
"}}}

"Elm{{{
let g:elm_jump_to_error = 1
let g:elm_make_output_file = "elm.js"
let g:elm_browser_command = 'google-chrome'
let g:elm_format_autosave = 1
let g:elm_format_fail_silently = 1
"}}}

"PureScript{{{
let g:psc_ide_syntastic_mode=1
autocmd FileType purescript nnoremap <buffer> <C-h> :Ptype<CR>
autocmd FileType purescript nnoremap <buffer> ,w :Prebuild<CR>
"}}}

"Agda"{{{
autocmd FileType agda setlocal expandtab ts=2 sts=2 sw=2
"autocmd FileType agda set commentstring=\ --%s
autocmd FileType agda set commentstring=--%s
"}}}

"Elm{{{
autocmd FileType elm nnoremap <buffer> ,w :ElmMake<CR>
"}}}

"Go"{{{
autocmd FileType go setlocal tabstop=8 shiftwidth=8 softtabstop=8 noexpandtab
"}}}

"MarkDown/Pandoc{{{
let g:vim_markdown_folding_disabled = 1
"}}}

"Scheme{{{
autocmd FileType scheme setlocal iskeyword=@,33,35-38,42-43,45-58,60-64,94,_,126
autocmd FileType scheme setlocal et ts=2 sts=2 sw=2
"}}}

"Prolog{{{
autocmd! BufNewFile,BufFilePRe,BufRead *.pl set filetype=prolog
"}}}

"Scala {{{
autocmd FileType scala nnoremap <buffer><C-h> :update!<CR>:EnTypeCheck<CR>
autocmd FileType scala nnoremap <buffer>,t    :update!<CR>:EnInspectType<CR>
autocmd FileType scala nnoremap <buffer><C-j> :update!<CR>:EnDeclaration<CR>
"}}}

"Makefile {{{
autocmd FileType make setlocal tabstop=4 shiftwidth=4 softtabstop=4 noexpandtab
"}}}

"vim{{{
autocmd FileType vim setlocal et ts=2 sw=2 sts=2
"}}}

" Python{{{
let g:python_highlight_all = 1
autocmd FileType python Python3Syntax
"}}}

"Smt2{{{
autocmd FileType smt2 call PareditInitBuffer()
autocmd FileType smt2 setlocal lisp
autocmd FileType smt2 setlocal lispwords+=assert,forall,exists
"}}}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"" Other Configuration
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"My Command{{{
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
au WinLeave * let g:last_win = winnr() | let g:last_file = expand("%:p")
au TabLeave * let g:last_tab = tabpagenr()
command! -nargs=0 MoveToLastWin execute "normal! ".g:last_win."<C-w><C-w>"
command! -nargs=0 MoveToLastTab execute "tabnext ".g:last_tab
command! -complete=file -nargs=1 EditBehind    edit <args>    | MoveToLastWin
command! -complete=file -nargs=1 TabEditBehind tabedit <args> | MoveToLastTab
"}}}

"Key mapping{{{
"""esc
inoremap jk <Esc>
inoremap <C-j><C-k> <Esc>:w<CR>
nnoremap <C-\> :update<CR>
inoremap <C-\> <Esc>:update<CR>
"""tab
nnoremap <silent> tt  :<C-u>tabe<CR>
nnoremap tg gT
for n in range(1, 9)
  execute 'nnoremap <silent> t'.n  ':<C-u>tabnext'.n.'<CR>'
endfor
"""delete
nnoremap dk ddk
nnoremap dj dd
inoremap <C-w> <esc>ldba
"""yank
nnoremap Y  y$
"""folding
nnoremap zj zo
nnoremap zk zc
"""window
nnoremap zh <C-w>h
nnoremap zj <C-w>j
nnoremap zk <C-w>k
nnoremap zl <C-w>l
nnoremap cj <C-w>j:q<CR><C-w>k
nnoremap ck <C-w>k:q<CR><C-w>j
nnoremap ch <C-w>h:q<CR><C-w>l
nnoremap cl <C-w>l:q<CR><C-w>h
call submode#enter_with('winsize', 'n', '', 'z>', '<C-w>>')
call submode#enter_with('winsize', 'n', '', 'z<', '<C-w><')
call submode#enter_with('winsize', 'n', '', 'z+', '<C-w>-')
call submode#enter_with('winsize', 'n', '', 'z-', '<C-w>+')
call submode#map('winsize', 'n', '', '>', '<C-w>>')
call submode#map('winsize', 'n', '', '<', '<C-w><')
call submode#map('winsize', 'n', '', '+', '<C-w>-')
call submode#map('winsize', 'n', '', '-', '<C-w>+')
"""folding
nnoremap zn za
"""paste mode
nnoremap <F10> :set paste<CR>
autocmd InsertLeave * set nopaste
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
nmap <Leader>w <Plug>(easymotion-bd-w)
nmap <Leader>W <Plug>(easymotion-bd-W)
nmap <Leader>e <Plug>(easymotion-bd-e)
nmap <Leader>E <Plug>(easymotion-bd-E)
vmap <Leader>w <Plug>(easymotion-bd-w)
vmap <Leader>W <Plug>(easymotion-bd-W)
vmap <Leader>e <Plug>(easymotion-bd-e)
vmap <Leader>E <Plug>(easymotion-bd-E)
nmap <Leader>r <Plug>(easymotion-repeat)
nmap <Leader>; <Plug>(easymotion-next)
"""moving: insert mode
inoremap <C-j> <down>
inoremap <C-k> <up>
inoremap <C-h> <left>
inoremap <C-l> <right>
inoremap <C-b> <esc>lBi
inoremap <C-n> <esc>lWi
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
nnoremap <Space>cd :lcd %:h<CR>
nnoremap ^ :noh<CR>
vnoremap * "zy:let @/ = @z<CR>n
nnoremap <C-n> :CNextRecursive<CR>
nnoremap <C-p> :CPreviousRecursive<CR>
nnoremap <M-n> :LNextRecursive<CR>
nnoremap <M-p> :LPreviousRecursive<CR>
"}}}

if filereadable(expand("~/.config/nvim/local-init.vim"))
  source ~/.config/nvim/local-init.vim
endif

"vim: set et ts=1 sts=2 tw=2:
