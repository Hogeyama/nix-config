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
use {'nvim-telescope/telescope.nvim' --{{{
} --}}}
use {'ibhagwan/fzf-lua', --{{{
} --}}}
-- [Love]
use {'github/copilot.vim', --{{{
  config = function()
    vim.g.copilot_no_tab_map = true
    vim.cmd[[
      imap <silent><expr><C-Right> copilot#Accept("\<Right>")
      "imap <silent><expr><Tab> copilot#Accept("\<Tab>")
      let g:copilot_no_tab_map = v:true
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
          FloatermSend --name=fzf fzfw
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
use {'mfussenegger/nvim-treehopper', --{{{
  config = function()
    vim.keymap.set(
      'n',
      'zf',
      function()
        require'tsht'.nodes()
        vim.cmd("normal! zf")
      end,
      {silent = true}
    )
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
use {'numToStr/Comment.nvim', --{{{
  config = function()
    require('Comment').setup({
      ---Add a space b/w comment and the line
      padding = true,
      ---Whether the cursor should stay at its position
      sticky = true,
      ---Lines to be ignored while (un)comment
      ignore = nil,
      ---LHS of toggle mappings in NORMAL mode
      toggler = { line = ',,', block = ',<' },
      ---LHS of operator-pending mappings in NORMAL and VISUAL mode
      opleader = { line = ',,', block = ',<' },
      ---LHS of extra mappings
      extra = {
          ---Add comment on the line above
          above = 'gcO',
          ---Add comment on the line below
          below = 'gco',
          ---Add comment at the end of line
          eol = ',>',
      },
    })
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
use {'dbridges/vim-markdown-runner', --{{{
  config = function()
    vim.cmd[[
      autocmd FileType markdown nnoremap <buffer> <C-q> <Cmd>MarkdownRunnerInsert<CR>
      autocmd FileType markdown nnoremap <buffer> <Leader>q :MarkdownRunnerInsert<CR>
    ]]
  end
}--}}}
use {'Hogeyama/metarw-redmine', --{{{
}--}}}
use {'folke/noice.nvim', -- {{{
  after = {"nui.nvim", "nvim-notify", "nvim-cmp"},
  config = function()
    require("noice").setup {
      presets = {
        bottom_search = false, -- use a classic bottom cmdline for search
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = true, -- add a border to hover docs and signature help
      },
      lsp = {
        override = {
          -- override the default lsp markdown formatter with Noice
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          -- override the lsp markdown formatter with Noice
          ["vim.lsp.util.stylize_markdown"] = true,
          -- override cmp documentation with Noice (needs the other options to work)
          ["cmp.entry.get_documentation"] = true,
        },
        progress = {
          enabled = true,
          -- Lsp Progress is formatted using the builtins for lsp_progress. See config.format.builtin
          -- See the section on formatting for more details on how to customize.
          --- @type NoiceFormat|string
          format = "lsp_progress",
          --- @type NoiceFormat|string
          format_done = "lsp_progress_done",
          throttle = 1000 / 30, -- frequency to update lsp progress message
          view = "mini",
        },
        hover = {
          enabled = true,
          view = nil, -- when nil, use defaults from documentation
          ---@type NoiceViewOptions
          opts = {
            border = {
              style = "none",
              padding = { 1, 1 },
            }
          }, -- merged with defaults from documentation
        },
        signature = {
          enabled = true,
          auto_open = {
            enabled = true,
            trigger = true, -- Automatically show signature help when typing a trigger character from the LSP
            luasnip = true, -- Will open signature help when jumping to Luasnip insert nodes
            throttle = 50, -- Debounce lsp signature help request by 50ms
          },
          view = nil, -- when nil, use defaults from documentation
          ---@type NoiceViewOptions
          opts = {}, -- merged with defaults from documentation
        },
        message = {
          -- Messages shown by lsp servers
          enabled = true,
          view = "mini",
          opts = {},
        },
        -- defaults for hover and signature help
        documentation = {
          view = "hover",
          ---@type NoiceViewOptions
          opts = {
            lang = "markdown",
            replace = true,
            render = "plain",
            format = { "{message}" },
            win_options = { concealcursor = "n", conceallevel = 3 },
          },
        },
      },
      cmdline = {
        enabled = true, -- disable if you use native command line UI
        view = "cmdline_popup", -- view for rendering the cmdline. Change to `cmdline` to get a classic cmdline at the bottom
        format = {
          cmdline = { pattern = "^:", icon = "", lang = "vim" },
          search_down = { kind = "search", pattern = "^/", icon = "  ", lang = "regex" },
          search_up = { kind = "search", pattern = "^%?", icon = "  ", lang = "regex" },
          filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
          lua = { pattern = "^:%s*lua%s+", icon = " ", lang = "lua" },
          help = { pattern = "^:%s*he?l?p?%s+", icon = " " },
          input = {}, -- Used by input()
        },
      },
      messages = {
        enabled = true,
        view = "mini",
        view_error = "mini",
        view_warn = "mini",
        view_history = "mini",
        view_search = "mini",
      },
      popupmenu = {
        enabled = true, -- disable if you use something like cmp-cmdline
        ---@type 'nui'|'cmp'
        backend = "cmp", -- backend to use to show regular cmdline completions
      },
      -- default options for require('noice').redirect
      -- see the section on Command Redirection
      ---@type NoiceRouteConfig
      redirect = {
        view = "split",
        filter = { event = "msg_show" },
      },
      history = {
        -- options for the message history that you get with `:Noice`
        view = "split",
        opts = { enter = true },
        filter = { event = "msg_show", ["not"] = { kind = { "search_count", "echo" } } },
      },
      notify = {
        -- Noice can be used as `vim.notify` so you can route any notification like other messages
        -- Notification messages have their level and other properties set.
        -- event is always "notify" and kind can be any log level as a string
        -- The default routes will forward notifications to nvim-notify
        -- Benefit of using Noice for this is the routing and consistent history view
        enabled = true,
      },
      hacks = {
        -- due to https://github.com/neovim/neovim/issues/20416
        -- messages are resent during a redraw. Noice detects this in most cases, but
        -- some plugins (mostly vim plugns), can still cause loops.
        -- When a loop is detected, Noice exits.
        -- Enable this option to simply skip duplicate messages instead.
        skip_duplicate_messages = false,
      },
      throttle = 1000 / 30, -- how frequently does Noice need to check for ui updates? This has no effect when in blocking mode.
      ---@type table<string, NoiceViewOptions>
      views = {
        cmdline_popup = { position = { row = 20, col = "50%" } },
      },
      -- NOTE ここから下はデフォルト
      ---@type NoiceRouteConfig[]
      routes = {}, -- @see the section on routes below
      ---@type table<string, NoiceFilter>
      status = {}, --@see the section on statusline components below
      ---@type NoiceFormatOptions
      format = {}, -- @see section on formatting
    }
  end,
}--}}}
-- [Git]
use {'tpope/vim-fugitive', --{{{
}--}}}
use {'jreybert/vimagit', --{{{
}--}}}
use {'lambdalisue/gina.vim', --{{{
  config = function()
    vim.cmd[[
      call gina#custom#action#alias(
        \ '/.*', 'p', 'diff:preview'
        \)
      autocmd FileType gina-log nmap F <Plug>(gina-show-commit-vsplit)zv
      "autocmd FileType gina-log nmap F <Plug>(gina-show-commit-preview)zv
    ]]
  end
}--}}}
use {'sindrets/diffview.nvim', --{{{
}--}}}
use {'TimUntersberger/neogit', --{{{
  config = function()
    require("neogit").setup {
      auto_refresh = true,
      disable_builtin_notifications = false,
      disable_commit_confirmation = true,
      use_magit_keybindings = false,
      kind = "tab",
      commit_popup = {
        kind = "vsplit",
      },
      popup = {
        kind = "vsplit",
      },
      status = {
        recent_commit_count = 25
      },
      -- customize displayed signs
      signs = {
        section = { "", "" },
        item = { "", "" },
        hunk = { ">", "v" },
      },
      integrations = {
        diffview = true
      },
      sections = {
        untracked = {
          folded = true
        },
        unstaged = {
          folded = false
        },
        staged = {
          folded = false
        },
        stashes = {
          folded = true
        },
        unpulled = {
          folded = true
        },
        unmerged = {
          folded = false
        },
        recent = {
          folded = true
        },
      },
      mappings = {
        status = {
          ["L"] = "",
          ["B"] = "BranchPopup",
          ["e"] = "LogPopup",
          ["<enter>"] = "TabOpen",
        }
      }
    }
    vim.cmd[[
      nnoremap <Leader>g :Neogit<CR>
      autocmd FileType NeogitStatus       setlocal foldmethod=diff
      autocmd FileType NeogitCommitReview setlocal foldmethod=diff
    ]]
  end
}--}}}
use {'lewis6991/gitsigns.nvim', --{{{
  config = function()
    require('gitsigns').setup()
  end
}--}}}
-- [LSP]
use {'neovim/nvim-lspconfig', --{{{
  after = {
    "nvim-lsp-installer",
    "lsp-format.nvim",
    "diagnosticls-configs-nvim",
  },
  config = function()
    -- [Common]
    -- [[configure LSP installer]] {{{
    require'nvim-lsp-installer'.setup({
      ensure_installed = {
        -- 'hls', -- managed by nix
        'bashls',
        'denols',
        'diagnosticls',
        'gopls',
        'jdtls',
        'jsonls',
        'pyright',
        'tsserver',
        'yamlls',
        'terraformls',
        'rust_analyzer',
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
      bmap('n', '<C-h>' , '<cmd>lua vim.lsp.buf.hover()<CR>')
      bmap('n', '<C-l>f', '<cmd>lua vim.lsp.buf.format({ async = true })<CR>')
      bmap('v', '<C-l>f', '<cmd>lua vim.lsp.buf.range_formatting()<CR>')
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
        client.server_capabilities.documentFormattingProvider = true
      end
      -- preffer prettier
      if client.name == "tsserver" then
        client.server_capabilities.documentFormattingProvider = false
      end
      -- 自動Format
      require "lsp-format".on_attach(client, bufnr)
    end
    -- }}}
    -- [[capabilities]] --{{{
    -- enable completion
    vim.g.lsp_default_capabilities = require('cmp_nvim_lsp').default_capabilities()
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
    -- [[diagnosticls]] --{{{
    local dlsconfig = require 'diagnosticls-configs'
    dlsconfig.init {
      on_attach = vim.g.lsp_default_on_attach,
    }
    -- }}}
    -- {{{
    require'lspconfig'['hls'].setup{
      cmd = {
        -- a wrapper of haskell-language-server-wrapper that
        -- fall backs to haskell-language-server
        'haskell-language-server-wrapper-wrapper',
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
      filetypes = {
        'sh',
        'bash',
        'python',
        'typescript',
        'typescriptreact',
        'typescript.tsx',
      },
      init_options = {
        filetypes = {
          sh = 'shellcheck',
          bash = 'shellcheck',
          python = 'flake8',
          typescript = 'eslint',
          typescriptreact = 'eslint',
          ['typescript.tsx'] = 'eslint',
        },
        linters = {
          shellcheck = require 'diagnosticls-configs.linters.shellcheck',
          flake8 = require 'diagnosticls-configs.linters.flake8',
          eslint = require 'diagnosticls-configs.linters.eslint',
        },
        formatFiletypes = {
          python = 'black',
          typescript = 'prettier',
          typescriptreact = 'prettier',
          ['typescript.tsx'] = 'prettier',
        },
        formatters = {
          black =  { command = "black", args = {"--quiet", "-"} },
          prettier = require 'diagnosticls-configs.formatters.prettier',
        }
      },
    }
    require'lspconfig'['bashls'].setup{}
    require'lspconfig'['gopls'].setup{}
    require'lspconfig'['jsonls'].setup{}
    require'lspconfig'['rust_analyzer'].setup{}
    require'lspconfig'['graphql'].setup{}
    require'lspconfig'['rnix'].setup{}
    require'lspconfig'['pyright'].setup{}
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
    require "lsp-format".setup{
      java = {
        exclude = {"jdtls"}
      }
    }
    -- 自動フォーマット
    vim.cmd [[cabbrev wq execute "Format sync" <bar> wq]]
  end
}--}}}
use {'creativenull/diagnosticls-configs-nvim', --{{{
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
use {'hrsh7th/nvim-cmp',
  after = {
    'cmp-cmdline',
    'cmp-path',
    'cmp-buffer',
    'cmp-nvim-lsp'
  },
  config = function()
    local cmp = require("cmp")
    cmp.setup {
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
        ['<CR>']    = cmp.mapping.confirm({ select = false }),
        ['<C-e>']   = cmp.mapping.abort(),
        ['<C-f>']   = cmp.mapping.complete_common_string(),
        ['<C-j>']   = cmp.mapping.scroll_docs(-4),
        ['<C-k>']   = cmp.mapping.scroll_docs(4),
        -- NOTE: 挿入したくない場合は insert の代わりに select にする
        ['<Tab>']   = cmp.mapping.select_next_item({ behavior = "insert" }),
        ['<Down>']  = cmp.mapping.select_next_item({ behavior = "insert" }),
        ['<S-Tab>'] = cmp.mapping.select_prev_item({ behavior = "insert" }),
        ['<Up>']    = cmp.mapping.select_prev_item({ behavior = "insert" }),
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
    }
    cmp.setup.cmdline({ '/', '?' }, {
      mapping = cmp.mapping.preset.cmdline({
        ['<C-f>'] = {
          c = cmp.mapping.complete_common_string(),
        }
      }),
      sources = {
        { name = 'buffer' }
      }
    })
    cmp.setup.cmdline(':', {
      mapping = cmp.mapping.preset.cmdline({
        ['<C-f>'] = {
          c = cmp.mapping.complete_common_string(),
        }
      }),
      sources = cmp.config.sources({
        { name = 'path' }
      }, {
        { name = 'cmdline' }
      })
    })
  end
}
use {'hrsh7th/vim-vsnip', --{{{
  config = function()
    vim.cmd[[
      let g:vsnip_snippet_dir = expand('~/.config/nvim/vsnip')
      imap <expr> <C-f> vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-f>'
      smap <expr> <C-f> vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-f>'
      xmap        <C-f> <Plug>(vsnip-cut-text)
    ]]
  end
} --}}}
use {'hrsh7th/vim-vsnip-integ', --{{{
  config = function()
    vim.cmd[[
      autocmd User PumCompleteDone call vsnip_integ#on_complete_done(g:pum#completed_item)
    ]]
  end
} --}}}
use {'hrsh7th/cmp-nvim-lsp', -- {{{
} -- }}}
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
-- [[GraphQL]]
use {'jparise/vim-graphql', --{{{
  config = function()
  end
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
use {'hashivim/vim-terraform', --{{{
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
use {'cocopon/iceberg.vim', --{{{
  after = {"vim-floaterm", "nvim-cmp", "noice.nvim", "nui.nvim", "popup.nvim", "nvim-notify", "hop.nvim"},
  config = function()
    vim.cmd[[
      set background=dark
      set termguicolors
      colorscheme iceberg
      hi Pmenu                         guibg=None guifg=cyan
      hi Folded                        guibg=None
      hi LineNr                        guibg=None
      hi MatchParen                    guibg=black guifg=#dadada
      hi FloatermBorder                guibg=None  guifg=cyan     " floaterm
      hi DiagnosticSignInfo            guibg=None
      hi DiagnosticSignWarn            guibg=None
      hi LspCodeLens                   guibg=None  guifg=#555555  " lsp
      hi LspReferenceRead              guibg=black
      hi LspReferenceText              guibg=black
      hi LspReferenceWrite             guibg=black
      hi NoiceCmdlineIcom              guibg=None
    ]]
  end
}--}}}
end)
