vim.cmd [[packadd packer.nvim]]
return require('packer').startup(function()
-- [Packer]
use {'wbthomason/packer.nvim', --{{{
} --}}}
-- [Lib]
use {'nvim-lua/plenary.nvim', --{{{
} --}}}
use {'vim-denops/denops.vim' --{{{
} --}}}
-- [UI]
use {'nvim-lua/popup.nvim', --{{{
} --}}}
use {'MunifTanjim/nui.nvim', --{{{
} --}}}
use {'kyazdani42/nvim-web-devicons', --{{{
} --}}}
use {'rcarriga/nvim-notify', --{{{
} --}}}
use {'stevearc/dressing.nvim', --{{{
  config = function()
    require('dressing').setup({
      input = {
        enabled = true,
        -- Default prompt string
        default_prompt = 'Input:',
        -- Can be 'left', 'right', or 'center'
        prompt_align = 'left',
        -- When true, <Esc> will close the modal
        insert_only = true,
        -- These are passed to nvim_open_win
        anchor = 'NW',
        border = 'rounded',
        -- 'editor' and 'win' will default to being centered
        relative = 'cursor',
        -- These can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
        prefer_width = 0.4,
        width = nil,
        -- min_width and max_width can be a list of mixed types.
        -- min_width = {20, 0.2} means 'the greater of 20 columns or 20% of total'
        max_width = { 140, 0.9 },
        min_width = { 20, 0.2 },
        -- Window transparency (0-100)
        winblend = 0,
        -- Change default highlight groups (see :help winhl)
        winhighlight = '',
        override = function(conf)
          -- This is the config that will be passed to nvim_open_win.
          -- Change values here to customize the layout
          return conf
        end,
        -- see :help dressing_get_config
        get_config = nil,
      },
      select = {
        enabled = true,
        backend = { 'fzf_lua', 'telescope', 'fzf', 'nui', 'builtin' },
        fzf_lua = {
          winopts = {
            width = 0.5,
            height = 0.4,
          },
        },
      },
    })
  end
} --}}}
use {'nvim-telescope/telescope.nvim' --{{{
} --}}}
use {'ibhagwan/fzf-lua', --{{{
} --}}}
-- [Love]
use {'github/copilot.vim', --{{{
  config = function()
    vim.g.copilot_no_tab_map = true
    vim.cmd[[
      imap <silent><expr><Right> copilot#Accept("\<Right>")
    ]]
  end
} --}}}
use {'nvim-treesitter/nvim-treesitter', --{{{
  run = ':TSUpdate'
} --}}}
use {'kana/vim-submode', --{{{
  config = function()
    vim.cmd[[
      let g:submode_always_show_submode = 1
      let g:submode_timeout = 0
    ]]
  end
}--}}}
use {'editorconfig/editorconfig-vim', --{{{
  config = function()
    vim.cmd[[
      let g:EditorConfig_max_line_indicator = 'exceeding'
    ]]
  end
}--}}}
use {'voldikss/vim-floaterm', --{{{
  config = function()
    vim.cmd[[
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
    ]]
  end
}--}}}
use {'lukas-reineke/indent-blankline.nvim', --{{{
  config = function()
    require("indent_blankline").setup{}
  end
}--}}}
use {'phaazon/hop.nvim', --{{{
  config = function()
    require'hop'.setup()
    -- TODO configure mappping
    vim.cmd[[
      map w <Cmd>HopWord<CR>
      map s <Cmd>HopChar2<CR>
    ]]
  end
}--}}}
use {'easymotion/vim-easymotion', --{{{
  config = function()
    vim.cmd[[
      let g:EasyMotion_keys='jfkdlamvneioc'
      let g:EasyMotion_do_mapping = 0
      let g:EasyMotion_smartcase = 1
      let g:EasyMotion_enter_jump_first = 1
      "map w <Plug>(easymotion-bd-w)
      "map W <Plug>(easymotion-bd-W)
      "map e <Plug>(easymotion-bd-e)
      "map E <Plug>(easymotion-bd-E)
      "map s <Plug>(easymotion-s2)
      nnoremap cw cw
    ]]
  end
}--}}}
use {'godlygeek/tabular', --{{{
}--}}}
use {'junegunn/vim-easy-align', --{{{
  config = function()
    vim.cmd[[
      vmap <Enter> <Plug>(EasyAlign)
    ]]
  end
}--}}}
use {'tomtom/tcomment_vim', --{{{
  config = function()
    vim.cmd[[
      nmap ,, <Plug>TComment_gcc
      vmap ,, <Plug>TComment_gc
      vmap ,l <Plug>TComment_,_r
      "vmap ,b <Plug>TComment_,_b
      "vmap ,i <Plug>TComment_,_i
      vmap ,b :TCommentRight!<CR>
      vmap ,i :TCommentInline!<CR>
    ]]
  end
}--}}}
use {'machakann/vim-sandwich', --{{{
  config = function()
    vim.cmd[[
      vmap s <Plug>(operator-sandwich-add)
    ]]
  end
}--}}}
use {'itchyny/lightline.vim', --{{{
  config = function()
    vim.cmd[[
      let g:lightline = {}
      let g:lightline.active = {
            \ 'left':  [ ['mode', 'paste'], ['readonly', 'relativepath', 'filetype', 'modified'] ],
            \ 'right': [ ['lineinfo'], ['percent'], ['fileformat', 'fileencoding'] ]
            \}
      let g:lightline.inactive = {
            \ 'left':  [ ['relativepath', 'modified'] ],
            \ 'right': [ ['lineinfo'], ['percent'] ]
            \}
      let g:lightline.tabline = {
            \ 'left':  [ ['tabs'] ],
            \ 'right': [ ['cwd'] ]
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
    ]]
  end
}--}}}
use {'AndrewRadev/linediff.vim', --{{{
}--}}}
use {'machakann/vim-highlightedyank', --{{{
}--}}}
use {'wellle/visual-split.vim', --{{{
}--}}}
use {'glidenote/memolist.vim', --{{{
  config = function()
    vim.g.memolist_path = '~/.memo'
    vim.g.memolist_template_dir_path = '~/.memo/template'
    vim.cmd[[
      command! MemoToday MemoNewWithMeta 'note', 'daily', 'daily'
      nnoremap <C-t> :MemoToday<CR>
    ]]
  end
}--}}}
use {'kana/vim-metarw', --{{{
}--}}}
use {'mattn/webapi-vim', --{{{
}--}}}
use {'rhysd/clever-f.vim', --{{{
  config = function()
    vim.cmd[[
      let g:clever_f_smart_case = 1
    ]]
  end
}--}}}
use {'haya14busa/vim-asterisk', --{{{
}--}}}
use {'Shougo/deol.nvim', --{{{
}--}}}
use {'Hogeyama/metarw-redmine', --{{{
}--}}}
-- [Git]
use {'tpope/vim-fugitive', --{{{
}--}}}
use {'jreybert/vimagit', --{{{
}--}}}
use {'lambdalisue/gina.vim', --{{{
}--}}}
-- [LSP]
use {'neovim/nvim-lspconfig', --{{{
  after = {"nvim-lsp-installer", "lsp-format.nvim"},
  config = function()
    -- [Common config]
    -- [[configure LSP installer]] {{{
    require'nvim-lsp-installer'.setup({
      ensure_installed = {
        -- 'hls', -- managed by nix
        -- 'rls', -- managed by nix
        'denols',
        'diagnosticls',
        'gopls',
        'jdtls',
        'jsonls',
        'tsserver',
        'yamlls',
        'terraformls',
        'tflint',
      },
      automatic_installation = false,
      ui = {
        icons = {
            server_installed = '✓',
            server_pending = '➜',
            server_uninstalled = '✗'
        }
      }
    })
    vim.g.jdtls_home = vim.env.HOME .. '/.local/share/nvim/lsp_servers/jdtls'
    --}}}
    -- [[diagnostic]] {{{
    vim.diagnostic.config({
      virtual_text = {
        prefix = "",
      },
    })
    vim.cmd [[
      highlight! DiagnosticLineNrError guibg=#51202A guifg=#FF0000 gui=bold
      highlight! DiagnosticLineNrWarn guibg=#51412A guifg=#FFA500 gui=bold
      highlight! DiagnosticLineNrInfo guibg=#1E535D guifg=#00FFFF gui=bold
      highlight! DiagnosticLineNrHint guibg=#1E205D guifg=#0000FF gui=bold

      sign define DiagnosticSignError text= texthl=DiagnosticSignError linehl= numhl=DiagnosticLineNrError
      sign define DiagnosticSignWarn text= texthl=DiagnosticSignWarn linehl= numhl=DiagnosticLineNrWarn
      sign define DiagnosticSignInfo text= texthl=DiagnosticSignInfo linehl= numhl=DiagnosticLineNrInfo
      sign define DiagnosticSignHint text= texthl=DiagnosticSignHint linehl= numhl=DiagnosticLineNrHint
    ]]
    vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', { noremap=true, silent=true })
    vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', { noremap=true, silent=true })
    --}}}
    -- [[code lens]] {{{

    --}}}
    -- [[on_attach]] {{{
    vim.g.lsp_default_on_attach = function(client, bufnr)
      local bmap = function (mode, key, cmd)
        vim.keymap.set(mode, key, cmd, { noremap=true, silent=true })
      end
      bmap('n', '<C-j>' , '<cmd>lua vim.lsp.buf.definition()<CR>')
      bmap('n', '<C-h>' , '<cmd>Lspsaga hover_doc<cr>')
      bmap('n', '<C-l>f', '<cmd>lua vim.lsp.buf.formatting()<CR>')
      bmap('v', '<C-l>f', '<cmd>lua vim.lsp.buf.Jange_formatting()<CR>')
      bmap('n', '<C-l>l', '<cmd>lua vim.lsp.codelens.run()<CR>')
      bmap('n', '<C-l>a', '<cmd>Lspsaga code_action<cr>')
      bmap('n', '<C-l>h', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
      bmap('n', '<C-l>d', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
      bmap('n', '<C-l>r', '<cmd>lua vim.lsp.buf.references()<CR>')
      bmap('n', '<C-l>R', '<cmd>lua vim.lsp.buf.rename()<CR>')
      vim.api.nvim_create_autocmd("CursorHold", {
        buffer = bufnr,
        callback = function()
          local opts = {
            focusable = false,
            close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
            border = 'rounded',
            source = 'always',
            prefix = ' ',
            scope = 'cursor',
          }
          vim.diagnostic.open_float(nil, opts)
        end
      })
      -- Format
      require "lsp-format".on_attach(client, bufnr)
      -- Highlight symbol under cursor
      -- https://github.com/neovim/nvim-lspconfig/wiki/UI-customization#highlight-symbol-under-cursor
      if client.server_capabilities.documentHighlightProvider then
        vim.api.nvim_create_augroup('lsp_document_highlight', {
          clear = false
        })
        vim.api.nvim_clear_autocmds({
          buffer = bufnr,
          group = 'lsp_document_highlight',
        })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          group = 'lsp_document_highlight',
          buffer = bufnr,
          callback = vim.lsp.buf.document_highlight,
        })
        vim.api.nvim_create_autocmd('CursorMoved', {
          group = 'lsp_document_highlight',
          buffer = bufnr,
          callback = vim.lsp.buf.clear_references,
        })
      end
      if client.server_capabilities.codeLensProvider then
        vim.cmd [[
          autocmd CursorHold,InsertLeave <buffer> lua vim.lsp.codelens.refresh()
        ]]
      end
      -- hack for yamlls.
      -- https://github.com/redhat-developer/yaml-language-server/issues/486#issuecomment-1046792026
      if client.name == "yamlls" then
        client.resolved_capabilities.document_formatting = true
      end
    end
    -- }}}
    -- [[capabilities]] --{{{
    -- enable completion
    vim.g.lsp_default_capabilities = vim.lsp.protocol.make_client_capabilities()
    -- enable snippet support
    vim.g.lsp_default_capabilities.textDocument.completion.completionItem.snippetSupport = true
    -- [[set default]]
    require'lspconfig'.util.default_config = vim.tbl_extend("force",
      require'lspconfig'.util.default_config,
      {
        on_attach = vim.g.lsp_default_on_attach,
        capabilities = vim.g.lsp_default_capabilities,
      }
    )
    -- }}}
    -- [Per server]
    -- {{{
    require'lspconfig'['hls'].setup{
      cmd = {
        'haskell-language-server-wrapper',
        '--lsp',
        '-d',
        '-l',
        '/tmp/LanguageServer.log',
      },
      settings = {
        haskell = {
          formattingProvider = 'fourmolu',
        },
      },
    }
    require'lspconfig'['denols'].setup{
      root_dir = require'lspconfig'.util.root_pattern("deno.json"),
      init_options = {
        lint = true,
      },
    }
    require'lspconfig'['diagnosticls'].setup{
      filetypes = {'sh', 'bash'},
      init_options = {
        filetypes = {
          sh = 'shellcheck',
          bash = 'shellcheck',
        },
        linters = {
          shellcheck = {
            command = 'shellcheck',
            debounce = 100,
            args = { '--format=gcc', '-' },
            offsetLine = 0,
            offsetColumn = 0,
            sourceName = 'shellcheck',
            formatLines = 1,
            formatPattern = {
              "^[^:]+:(\\d+):(\\d+):\\s+([^:]+):\\s+(.*)$",
              {
                line = 1,
                column = 2,
                message = 4,
                security = 3,
              },
            },
            securities = {
              error = 'error',
              warning = 'warning',
              note = 'info'
            }
          },
        },
      },
    }
    require'lspconfig'['gopls'].setup{}
    require'lspconfig'['jsonls'].setup{}
    require'lspconfig'['rls'].setup{}
    require'lspconfig'['rnix'].setup{}
    require'lspconfig'['tsserver'].setup{
      root_dir = require'lspconfig'.util.root_pattern("package.json"),
      init_options = {
        lint = true,
      },
    }
    require'lspconfig'['yamlls'].setup{}
    require'lspconfig'['terraformls'].setup{}
    require'lspconfig'['tflint'].setup{}
    -- }}}
  end
} --}}}
use {'tamago324/nlsp-settings.nvim', --{{{
  after = 'nvim-lspconfig',
  config = function()
    require'nlspsettings'.setup({
      append_default_schemas = true,
      loader = 'yaml',
      nvim_notify = {
        enable = true,
      },
    })
  end
} --}}}
use {'williamboman/nvim-lsp-installer', --{{{
} --}}}
use {'folke/trouble.nvim', --{{{
  config = function()
    require('trouble').setup{
      -- icons = false,
      -- fold_open = 'v',
      -- fold_closed = '>',
      -- signs = {
      --   error = 'E',
      --   warning = 'W',
      --   hint = 'H',
      --   information = 'I',
      --   other = 'O'
      -- },
    }
    vim.keymap.set('n', '<space>q', '<cmd>TroubleToggle<CR>', { noremap=true, silent=true })
  end
} --}}}
use {'tami5/lspsaga.nvim', --{{{
} --}}}
use {'j-hui/fidget.nvim', --{{{
  config = function()
    require'fidget'.setup{}
  end
} --}}}
use {'mfussenegger/nvim-jdtls', --{{{
} --}}}
use {'lukas-reineke/lsp-format.nvim', --{{{
  config = function()
    -- TODO configure
    require "lsp-format".setup{
      java = {
        exclude = {"jdtls"}
      }
    }
  end
}--}}}
-- [DAP]
use {'mfussenegger/nvim-dap', --{{{
  config = function()
    vim.cmd[[
      autocmd FileType dap-repl lua require('dap.ext.autocompl').attach()
    ]]
  end
} --}}}
use {'theHamsta/nvim-dap-virtual-text', --{{{
  after = 'nvim-dap',
  config = function()
    require("nvim-dap-virtual-text").setup()
  end
} --}}}
use { "rcarriga/nvim-dap-ui", --{{{
  after = 'nvim-dap',
  config = function()
    require("dapui").setup()
  end
} --}}}
-- [Completion]
use { 'Shougo/ddc.vim', --{{{
  after = {
    'ddc-fuzzy',
    'ddc-matcher_head',
    'ddc-sorter_rank',
    'ddc-around',
    'ddc-buffer',
    'ddc-cmdline',
    'ddc-cmdline-history',
    'ddc-file',
    'ddc-input',
    'ddc-nvim-lsp',
    'ddc-zsh',
    'denops-popup-preview.vim',
    'vim-vsnip',
    'vim-vsnip-integ',
    'pum.vim',
  },
  config = function()
    vim.cmd[[
      call ddc#custom#patch_global('completionMenu', 'pum.vim')
      call ddc#custom#patch_global('autoCompleteEvents', [
            \ 'InsertEnter',
            \ 'TextChangedI',
            \ 'TextChangedP',
            \ 'CmdlineChanged',
            \ ])
      call ddc#custom#patch_global('sources', [
            \ 'vsnip',
            \ 'nvim-lsp',
            \ 'around',
            \ 'buffer',
            \ 'input',
            \ 'file',
            \ 'zsh',
            \ ])
      call ddc#custom#patch_global('sourceOptions', {
            \ '_': {
            \   'matchers': ['matcher_fuzzy'],
            \   'sorters': ['sorter_fuzzy'],
            \   'converter': ['converter_fuzzy'],
            \ },
            \ 'around': {
            \   'mark': 'A'
            \ },
            \ 'buffer': {
            \   'mark': 'B'
            \ },
            \ 'cmdline': {
            \   'mark': 'C',
            \ },
            \ 'path': {
            \   'mark': 'P',
            \ },
            \ 'file': {
            \   'mark': 'F',
            \   'isVolatile': v:true,
            \   'forceCompletionPattern': '\S/\S*',
            \ },
            \ 'nvim-lsp': {
            \   'mark': 'lsp',
            \   'forceCompletionPattern': '\.\w*|:\w*|->\w*'
            \ },
            \ 'vsnip': {
            \   'mark': 'snip'
            \ },
            \ 'zsh': {
            \   'mark': 'Z'
            \ },
            \ })
      call ddc#custom#patch_global('sourceParams', {
            \ 'around': {
            \   'maxSize': 500
            \ },
            \ 'buffer': {
            \   'requireSameFiletype': v:false,
            \   'limitBytes': 5000000,
            \   'fromAltBuf': v:true,
            \   'forceCollect': v:true,
            \ },
            \ 'path': {
            \   'cmd': ['fd', '--max-depth', '5'],
            \ },
            \ })

      " Mappings
      " <TAB>: completion.
      inoremap <silent><expr><TAB> pum#visible() ?
            \ '<Cmd>call pum#map#select_relative(+1)<CR>' :
            \ '<TAB>'
      inoremap <S-Tab> <Cmd>call pum#map#select_relative(-1)<CR>
      inoremap <silent><expr><Down> pum#visible() ?
            \ '<Cmd>call pum#map#select_relative(+1)<CR>' :
            \ '<Down>'
      inoremap <silent><expr><Up> pum#visible() ?
            \ '<Cmd>call pum#map#select_relative(-1)<CR>' :
            \ '<Up>'
      inoremap <silent><expr><Right> pum#visible() ?
            \ '<Cmd>call pum#map#confirm()<CR>' :
            \ '<Right>'

      " Enable command line completion
      nnoremap /       <Cmd>call CommandlinePre()<CR>/
      function! CommandlinePre() abort
        cnoremap <silent><expr><TAB> pum#visible() ?
              \ '<Cmd>call pum#map#select_relative(+1)<CR>' :
              \ ddc#manual_complete()
        cnoremap <silent><expr><Right> pum#visible() ?
              \ '<Cmd>call pum#map#confirm()<CR>' :
              \ '<Right>'
        cnoremap <S-Tab> <Cmd>call pum#map#select_relative(-1)<CR>
        cnoremap <Down>  <Cmd>call pum#map#select_relative(+1)<CR>
        cnoremap <Up>    <Cmd>call pum#map#select_relative(-1)<CR>

        " Overwrite sources
        if !exists('b:prev_buffer_config')
          let b:prev_buffer_config = ddc#custom#get_buffer()
        endif
        if getcmdtype() == '/'
          call ddc#custom#patch_buffer('cmdlineSources', [
              \ 'buffer',
              \ ])
        elseif getcmdtype() == '@'
          call ddc#custom#patch_buffer('cmdlineSources', [
              \ 'buffer',
              \ ])
        else
          call ddc#custom#patch_buffer('cmdlineSources', [
              \ 'cmdline',
              \ 'file',
              \ ])
        endif

        autocmd User DDCCmdlineLeave ++once call CommandlinePost()
        autocmd InsertEnter <buffer> ++once call CommandlinePost()

        " Enable command line completion
        call ddc#enable_cmdline_completion()
      endfunction
      function! CommandlinePost() abort
        silent! cunmap <Right>
        silent! cunmap <Tab>
        silent! cunmap <S-Tab>
        silent! cunmap <Down>
        silent! cunmap <Up>

        " Restore sources
        if exists('b:prev_buffer_config')
          call ddc#custom#set_buffer(b:prev_buffer_config)
          unlet b:prev_buffer_config
        else
          call ddc#custom#set_buffer({})
        endif
      endfunction

      call ddc#enable()
    ]]
  end
} --}}}
use { 'Shougo/ddc-around', --{{{
} -- }}}
use { 'Shougo/ddc-matcher_head', --{{{
} -- }}}
use { 'Shougo/ddc-sorter_rank', --{{{
} -- }}}
use { 'Shougo/ddc-cmdline', --{{{
} -- }}}
use { 'Shougo/ddc-cmdline-history', --{{{
} -- }}}
use { 'Shougo/ddc-input', --{{{
} -- }}}
use { 'Shougo/ddc-nvim-lsp', --{{{
} -- }}}
use { 'Shougo/ddc-zsh', --{{{
} -- }}}
use { 'Shougo/pum.vim', --{{{
  config = function()
    vim.cmd[[
      call pum#set_option({
          \ 'border': 'none',
          \ })
    ]]
  end
} --}}}
use { 'LumaKernel/ddc-file', --{{{
} --}}}
use { 'tani/ddc-fuzzy', --{{{
} --}}}
use { 'matsui54/ddc-buffer', --{{{
} --}}}
use { 'matsui54/denops-popup-preview.vim', --{{{
  config = function()
    vim.cmd[[
      call popup_preview#enable()
    ]]
  end
} --}}}
use { 'matsui54/denops-signature_help', --{{{
  config = function()
    vim.cmd[[
      call signature_help#enable()
      let g:signature_help_config = { 'style': 'virtual' }
    ]]
  end
} --}}}
-- [Snippet]
use { 'hrsh7th/vim-vsnip', --{{{
  config = function()
    vim.cmd[[
      let g:vsnip_snippet_dir = expand('~/.config/nvim/vsnip')
      imap <expr> <C-f> vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-f>'
      smap <expr> <C-f> vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-f>'
      xmap        <C-f> <Plug>(vsnip-cut-text)
    ]]
  end
} --}}}
use { 'hrsh7th/vim-vsnip-integ', --{{{
  config = function()
    vim.cmd[[
      autocmd User PumCompleteDone call vsnip_integ#on_complete_done(g:pum#completed_item)
    ]]
  end
} --}}}
-- [Filetype]
-- [[Haskell]]
use {'neovimhaskell/haskell-vim', --{{{
}--}}}
-- [[dhall]]
use {'vmchale/dhall-vim', --{{{
}--}}}
-- [[Rust]]
use {'rust-lang/rust.vim', --{{{
}--}}}
-- [[nix]]
use {'LnL7/vim-nix', --{{{
}--}}}
-- [[Markdown]]
use {'preservim/vim-markdown', --{{{
  config = function()
    vim.g.vim_markdown_folding_disabled = 1
    vim.g.vim_markdown_new_list_item_indent = 2
  end
}--}}}
use {'vim-voom/VOoM', --{{{
}--}}}
-- [[Textile]]
use {'s3rvac/vim-syntax-redminewiki', --{{{
  config = function()
    vim.cmd[[
      autocmd BufEnter *.redmine set ft=redminewiki
    ]]
  end
}--}}}
-- [[JavaScript/TypeScript]]
use {'jelera/vim-javascript-syntax', --{{{
}--}}}
use {'leafgarland/typescript-vim', --{{{
}--}}}
-- [[Color scheme]]
use {'tyrannicaltoucan/vim-deep-space', --{{{
}--}}}
use {'cocopon/iceberg.vim', --{{{
  config = function()
    vim.cmd[[
      set background=dark
      set termguicolors
      colorscheme iceberg
      hi Folded            guibg=None
      hi LineNr            guibg=None
      hi MatchParen        guibg=black guifg=#dadada
      hi FloatermBorder    guibg=None  guifg=cyan     " floaterm
      hi Pmenu             guibg=None                 " pum.vim
      hi LspCodeLens       guibg=None  guifg=#555555  " lsp
      hi LspReferenceRead  guibg=black
      hi LspReferenceText  guibg=black
      hi LspReferenceWrite guibg=black
    ]]
  end
}--}}}
end)
