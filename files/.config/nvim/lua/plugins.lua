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
use {'Shougo/neosnippet', --{{{
  config = function()
    vim.cmd[[
      imap <C-f> <Plug>(neosnippet_expand_or_jump)
      smap <C-f> <Plug>(neosnippet_expand_or_jump)
      xmap <C-f> <Plug>(neosnippet_expand_target)
      let g:neosnippet#enable_conceal_markers = 0
      let g:neosnippet#snippets_directory = '~/.config/nvim/snippets'
    ]]
  end
}--}}}
use {'Shougo/neosnippet-snippets', --{{{
}--}}}
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
      hi FloatermBorder guibg=None guifg=cyan
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
use {'mattn/vim-metarw-redmine', --{{{
  config = function()
    vim.cmd[[
      if filereadable(expand("~/.redmine_api_key"))
        let g:metarw_redmine_server = readfile(expand("~/.redmine_api_key"))[0]
        let g:metarw_redmine_apikey = readfile(expand("~/.redmine_api_key"))[1]
      endif
      au BufNewFile,BufRead             *.redmine  set filetype=redminewiki
      au BufNewFile,BufRead,InsertLeave redmine:/* set filetype=redminewiki ro
    ]]
  end
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
-- [Git]
use {'tpope/vim-fugitive', --{{{
}--}}}
use {'jreybert/vimagit', --{{{
}--}}}
use {'lambdalisue/gina.vim', --{{{
}--}}}
-- [LSP]
use {'neovim/nvim-lspconfig', --{{{
  after = "nvim-lsp-installer",
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
    vim.cmd [[
      autocmd CursorHold,InsertLeave <buffer> lua vim.lsp.codelens.refresh()
      hi LspCodeLens guibg=None guifg=#555555
    ]]
    --}}}
    -- [[on_attach]] {{{
    vim.g.lsp_default_on_attach = function(client, bufnr)
      local bmap = function (mode, key, cmd)
        vim.keymap.set(mode, key, cmd, { noremap=true, silent=true })
      end
      bmap('n', '<C-j>' , '<cmd>lua vim.lsp.buf.definition()<CR>')
      bmap('n', '<C-h>' , '<cmd>Lspsaga hover_doc<cr>')
      bmap('n', '<C-l>f', '<cmd>lua vim.lsp.buf.formatting()<CR>')
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
      vim.cmd [[
        autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_seq_sync()
      ]]
      -- Highlight symbol under cursor
      -- https://github.com/neovim/nvim-lspconfig/wiki/UI-customization#highlight-symbol-under-cursor
      if client.resolved_capabilities.document_highlight then
        vim.cmd [[
          hi! LspReferenceRead  ctermbg=red guibg=black
          hi! LspReferenceText  ctermbg=red guibg=black
          hi! LspReferenceWrite ctermbg=red guibg=black
        ]]
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
      -- hack for yamlls.
      -- https://github.com/redhat-developer/yaml-language-server/issues/486#issuecomment-1046792026
      if client.name == "yamlls" then
        client.resolved_capabilities.document_formatting = true
      end
    end
    -- }}}
    -- [[capabilities]] --{{{
    -- enable completion
    vim.g.lsp_default_capabilities =
      require("cmp_nvim_lsp").update_capabilities(vim.lsp.protocol.make_client_capabilities())
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
    }
    require'lspconfig'['denols'].setup{}
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
    require'lspconfig'['tsserver'].setup{}
    require'lspconfig'['yamlls'].setup{}
    -- }}}
  end
} --}}}
use {'tamago324/nlsp-settings.nvim', --{{{
  after = 'nvim-lspconfig',
  config = function()
    require'nlspsettings'.setup({
      append_default_schemas = true,
      loader = 'yaml'
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
use {'hrsh7th/nvim-cmp', -- {{{
  config = function()
    local cmp = require'cmp'
    cmp.setup({
      snippet = {
        expand = function(args)
          vim.fn['vsnip#anonymous'](args.body)
        end,
      },
      window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      },
      mapping = {
        ['<C-d>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.close(),
        ['<CR>'] = cmp.mapping.confirm({ select = false }),
        ['<Tab>'] = function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            else
              fallback()
            end
          end,
        ['<Down>'] = function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            else
              fallback()
            end
          end,
        ['<S-Tab>'] = function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end,
        ['<Up>'] = function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end,
      },
      sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'vsnip' },
      }, {
        { name = 'buffer' },
        { name = 'path',
          options = {
            trailing_slash = false,
          },
        },
      })
    })

    cmp.setup.cmdline('/', {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        { name = 'buffer' }
      }
    })

    cmp.setup.cmdline(':', {
      mapping = cmp.mapping.preset.cmdline(),
      enabled = function() return true end,
      sources = {
        { name = 'cmdline' }
      }
    })
  end
} --}}}
use {'hrsh7th/cmp-nvim-lsp', --{{{
  config = function()
  end,
} --}}}
use {'hrsh7th/cmp-nvim-lsp-signature-help', -- {{{
} -- }}}
use {'hrsh7th/cmp-nvim-lsp-document-symbol', -- {{{
} -- }}}
use {'hrsh7th/cmp-buffer', -- {{{
} -- }}}
use {'hrsh7th/cmp-path', -- {{{
} -- }}}
use {'hrsh7th/cmp-emoji', -- {{{
} -- }}}
use {'hrsh7th/cmp-cmdline', -- {{{
} -- }}}
use {'hrsh7th/cmp-vsnip', -- {{{
} -- }}}
use {'hrsh7th/vim-vsnip', -- {{{
} -- }}}
use {'petertriho/cmp-git', -- {{{
  config = function()
    require('cmp_git').setup{}
  end
} -- }}}
-- [Filetype]
-- [[Haskell]]
use {'neovimhaskell/haskell-vim', --{{{
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
}--}}}
-- [[JavaScript/TypeScript]]
use {'jelera/vim-javascript-syntax', --{{{
}--}}}
use {'leafgarland/typescript-vim', --{{{
}--}}}
-- [[Color scheme]]
use {'tyrannicaltoucan/vim-deep-space', --{{{
}--}}}
end)
