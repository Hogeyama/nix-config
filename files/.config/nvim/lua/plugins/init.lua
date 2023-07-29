return {
  { 'nvim-lua/plenary.nvim' },
  { 'nvim-lua/popup.nvim' },
  { 'MunifTanjim/nui.nvim' },
  { 'nvim-tree/nvim-web-devicons' },
  { 'rcarriga/nvim-notify',
    config = true,
  },
  { 'nvim-telescope/telescope.nvim',
    init = function()
      require('telescope').setup {
        defaults = {
          mappings = {
            i = {
              ["<Esc>"] = require('telescope.actions').close,
            },
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
          ["ui-select"] = {
            require("telescope.themes").get_dropdown {}
          }
        }
      }
      require('telescope').load_extension('fzf')
      require("telescope").load_extension("ui-select")
      require("telescope").load_extension("yank_history")
      vim.keymap.set("n", "P", "<Cmd>Telescope yank_history<CR>")
    end,
    dependencies = {
      { 'gbprod/yanky.nvim',
        init = function()
          require("yanky").setup {
            ring = {
              history_length = 100,
              storage = "shada",
              sync_with_numbered_registers = true,
              cancel_event = "update",
            },
            picker = {
              select = {
                action = nil, -- nil to use default put action
              },
              telescope = {
                mappings = nil, -- nil to use default mappings
              },
            },
            system_clipboard = {
              sync_with_ring = true,
            },
            highlight = {
              on_put = false,
              on_yank = true,
              timer = 100,
            },
            preserve_cursor_position = {
              enabled = true,
            },
          }
          vim.cmd [[set clipboard+=unnamedplus]]
        end,
      },
      { 'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make'
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
    },
  },
  { 'glacambre/firenvim',
    init = function()
      if vim.g.started_by_firenvim == true then
        vim.o.number = false
        vim.o.laststatus = 0
        vim.o.showtabline = 0
        vim.api.nvim_create_autocmd({ 'BufEnter' }, {
          command = "set filetype=markdown"
        })
        vim.g.firenvim_config = {
          globalSettings = { alt = "all" },
          localSettings = {
            [".*"] = {
              selector = "textarea",
              takeover = "empty"
            }
          }
        }
        vim.g.firenvim_config.localSettings['.*'] = { takeover = 'empty' }
        vim.g.firenvim_config.localSettings['.*'] = { cmdline = 'firenvim' }
        vim.api.nvim_set_keymap("n", "<Esc><Esc>", "<Cmd>call firenvim#focus_page()<CR>", {})
      end
    end,
    build = function()
      vim.fn['firenvim#install'](0)
    end,
    dependencies = {
      { 'ibhagwan/fzf-lua' },
    },
  },
  { 'miversen33/netman.nvim',
    config = true,
  },
  { 'echasnovski/mini.nvim',
    init = function()
      require('mini.ai').setup()
      require('mini.align').setup({
        mappings = {
          start = '',
          start_with_preview = 'ga',
        },
      })
      require('mini.pairs').setup()
    end,
  },
  { 'github/copilot.vim',
    init = function()
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_filetypes = {
        ['*'] = true
      }
      vim.cmd [[
        imap <silent><expr><C-Right> copilot#Accept("\<Right>")
        "imap <silent><expr><Tab> copilot#Accept("\<Tab>")
        let g:copilot_no_tab_map = v:true
      ]]
    end,
  },
  { 'mhinz/vim-startify', -- TODO
    init = function()
      vim.g.startify_lists = {
        { type = 'sessions', header = { '   Sessions' } },
        { type = 'files', header = { '   MRU' } },
        { type = 'bookmarks', header = { '   Bookmarks' } },
        { type = 'commands', header = { '   Commands' } },
      }
      vim.g.startify_commands = {
        { g = 'Neogit' },
        { n = 'Neotree remote' },
      }
      vim.g.startify_skiplist = {
        "/run/user/.*",
        "/nix/store/.*",
        "~/.local/share/nvim/site/pack/packer/.*",
      }
      -- autoload & autosave
      vim.g.startify_session_autoload = 1
      vim.g.startify_session_persistence = 1
    end
  },
  { 'nvim-treesitter/nvim-treesitter',
    init = function()
      require 'nvim-treesitter.configs'.setup {
        ensure_installed = {},
        sync_install = false,
        auto_install = false,
        highlight = {
          enable = false,
          disable = function(_, buf)
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
              return true
            end
          end,
          additional_vim_regex_highlighting = false,
        },
        textsubjects = {
          enable = true,
          keymaps = {
            ['.'] = 'textsubjects-smart',
          },
        },
      }
      -- nvim-treehopper
      vim.cmd [[
        omap     <silent> m :<C-U>lua require('tsht').nodes()<CR>
        xnoremap <silent> m :lua require('tsht').nodes()<CR>
      ]]
    end,
    dependencies = {
      { 'nvim-treesitter/playground' },
      { 'nvim-treesitter/nvim-treesitter-textobjects' },
      { 'RRethy/nvim-treesitter-textsubjects' },
      { 'mfussenegger/nvim-treehopper' },
      { 'IndianBoy42/tree-sitter-just' },
    },
  },
  { 'anuvyklack/hydra.nvim',
    init = function()
      local hydra = require('hydra')
      hydra({
        name = 'resize',
        mode = 'n',
        body = ',z',
        heads = {
          { 'l', function() vim.cmd [[wincmd >]] end },
          { 'h', function() vim.cmd [[wincmd <]] end, { desc = '←/→' } },
          { 'k', function() vim.cmd [[wincmd +]] end },
          { 'j', function() vim.cmd [[wincmd -]] end, { desc = '↑/↓' } },
        }
      })

      hydra({
        name = 'fold',
        mode = 'n',
        body = '<C-f>',
        heads = {
          { 'L', 'zr' },
          { 'H', 'zm' },
          { 'l', 'zo' },
          { 'h', 'zc' },
          { 'k', 'zk' },
          { 'j', 'zj' },
        }
      })

      local gitsigns = require('gitsigns')
      hydra({
        name = 'Git',
        hint = [[
_J_: next hunk   _s_: stage hunk        _d_: show deleted   _b_: blame line
_K_: prev hunk   _u_: undo stage hunk   _p_: preview hunk   _B_: blame show full
^ ^              _S_: stage buffer      ^ ^
^
^ ^              _<Enter>_: Neogit            _<Esc>_: exit
        ]],
        config = {
          color = 'pink',
          invoke_on_body = true,
          hint = {
            position = 'bottom',
            border = 'rounded'
          },
          on_enter = function()
            vim.bo.modifiable = false
            gitsigns.toggle_linehl(true)
          end,
          on_exit = function()
            gitsigns.toggle_linehl(false)
            gitsigns.toggle_deleted(false)
            vim.cmd 'echo' -- clear the echo area
          end
        },
        mode = { 'n', 'x' },
        body = '<C-g>',
        heads = {
          { 'J', function()
            if vim.wo.diff then return ']c' end
            vim.schedule(function() gitsigns.next_hunk() end)
            return '<Ignore>'
          end, { expr = true } },
          { 'K', function()
            if vim.wo.diff then return '[c' end
            vim.schedule(function() gitsigns.prev_hunk() end)
            return '<Ignore>'
          end, { expr = true } },
          { 's', ':Gitsigns stage_hunk<CR>', { silent = true } },
          { 'u', gitsigns.undo_stage_hunk },
          { 'S', gitsigns.stage_buffer },
          { 'p', gitsigns.preview_hunk },
          { 'd', gitsigns.toggle_deleted, { nowait = true } },
          { 'b', gitsigns.blame_line },
          { 'B', function() gitsigns.blame_line { full = true } end },
          { '<Enter>', '<cmd>Neogit<CR>', { exit = true } },
          { '<Esc>', nil, { exit = true, nowait = true } },
        }
      })
    end,
    dependencies = {
      { 'gitsigns.nvim' },
      { 'neogit' },
    },
  },
  { 'cocopon/iceberg.vim',
    init = function()
      vim.cmd [[
        set background=dark
        set termguicolors
        colorscheme iceberg
        hi! Pmenu                         guibg=None guifg=cyan
        hi! Folded                        guibg=None
        hi! LineNr                        guibg=None
        hi! MatchParen                    guibg=black guifg=#dadada
        hi! FloatBorder                   guibg=None  guifg=#555555 "LSPのCursorHold
        hi! FloatermBorder                guibg=None  guifg=cyan
        hi! DiagnosticSignInfo            guibg=None
        hi! DiagnosticSignWarn            guibg=None
        hi! LspCodeLens                   guibg=None  guifg=#555555
        hi! LspReferenceRead              guibg=black
        hi! LspReferenceText              guibg=black
        hi! LspReferenceWrite             guibg=black
        hi! NoiceCmdlineIcon                          guifg=cyan
        hi! NoiceSplitBorder              guibg=None  guifg=#555555
        hi! LspSagaCodeActionBorder       guibg=None  guifg=#555555

        hi! DiagnosticLineNrError guibg=#51202A guifg=#FF0000 gui=bold
        hi! DiagnosticLineNrWarn  guibg=#51412A guifg=#FFA500 gui=bold
        hi! DiagnosticLineNrInfo  guibg=#1E535D guifg=#00FFFF gui=bold
        hi! DiagnosticLineNrHint  guibg=#1E205D guifg=#0000FF gui=bold

        hi! ContextVt             guibg=None    guifg=#444444

        sign define DiagnosticSignError text= texthl=DiagnosticSignError linehl= numhl=DiagnosticLineNrError
        sign define DiagnosticSignWarn  text= texthl=DiagnosticSignWarn  linehl= numhl=DiagnosticLineNrWarn
        sign define DiagnosticSignInfo  text= texthl=DiagnosticSignInfo  linehl= numhl=DiagnosticLineNrInfo
        sign define DiagnosticSignHint  text= texthl=DiagnosticSignHint  linehl= numhl=DiagnosticLineNrHint
      ]]
    end
  },
  { 'editorconfig/editorconfig-vim',
    init = function()
      vim.cmd [[
        let g:EditorConfig_max_line_indicator = 'exceeding'
      ]]
    end,
  },
  { 'voldikss/vim-floaterm',
    init = function()
      vim.cmd [[
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
        "nvim_treesitter#foldexpr()が有効になっているとめちゃくちゃ重くなる
        "なぜかnofoldenableでも重いので、foldmethod=manualにする
        autocmd FileType floaterm setlocal foldmethod=manual
      ]]
    end
  },
  { 'lukas-reineke/indent-blankline.nvim',
    config = true
  },
  { 'phaazon/hop.nvim',
    init = function()
      require 'hop'.setup()
      vim.keymap.set('', 'r', function()
        require 'hop'.hint_words({
          current_line_only = false,
          hint_position = require 'hop.hint'.HintPosition.BEGIN,
          multi_windows = false,
        })
      end, { remap = true })
      vim.keymap.set('', 'R', function()
        require 'hop'.hint_words({
          current_line_only = false,
          hint_position = require 'hop.hint'.HintPosition.END,
          multi_windows = false,
        })
      end, { remap = true })
      vim.cmd [[
        nnoremap cw cw
      ]]
    end
  },
  { 'chrisgrieser/nvim-spider',
    init = function()
      require("spider").setup({
        skipInsignificantPunctuation = true
      })
      vim.keymap.set({ "n", "o", "x" }, "w", "<cmd>lua require('spider').motion('w')<CR>", { desc = "Spider-w" })
      vim.keymap.set({ "n", "o", "x" }, "e", "<cmd>lua require('spider').motion('e')<CR>", { desc = "Spider-e" })
      vim.keymap.set({ "n", "o", "x" }, "W", "<cmd>lua require('spider').motion('b')<CR>", { desc = "Spider-b" })
      vim.keymap.set({ "n", "o", "x" }, "E", "<cmd>lua require('spider').motion('ge')<CR>", { desc = "Spider-ge" })
    end
  },
  { 'godlygeek/tabular' },
  { 'numToStr/Comment.nvim',
    init = function()
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
  },
  { 'machakann/vim-sandwich',
    init = function()
      vim.cmd [[
        vmap s <Plug>(operator-sandwich-add)
      ]]
    end
  },
  { 'Bekaboo/dropbar.nvim' },
  { 'nvim-lualine/lualine.nvim',
    init = function()
      if not vim.g.started_by_firenvim then
        vim.o.laststatus = 3
        require('lualine').setup {
          globalstatus = true,
          winbar = {},
          inactive_winbar = {},
          sections = {
            lualine_a = { 'mode' },
            lualine_b = { { 'filename', path = 1 } },
            lualine_c = { 'location' },
            lualine_x = { 'encoding', 'fileformat', 'filetype' },
            lualine_y = { 'progress' },
            lualine_z = { 'branch', 'diff', 'diagnostics' },
          },
          tabline = {
            lualine_a = {
              {
                'tabs',
                mode = 2,
                max_length = vim.o.columns,
              }
            },
            lualine_b = {},
            lualine_c = {},
            lualine_x = {},
            lualine_y = {},
            lualine_z = {},
          },
        }
      end
    end,
    dependencies = { 'nvim-web-devicons', 'firenvim' },
  },
  { 'AndrewRadev/linediff.vim' },
  { 'machakann/vim-highlightedyank' },
  { 'glidenote/memolist.vim',
    init = function()
      vim.g.memolist_path = '~/.memo'
      vim.g.memolist_template_dir_path = '~/.memo/template'
      vim.cmd [[
        command! MemoToday MemoNewWithMeta 'note', 'daily', 'daily'
        nnoremap <C-t> :MemoToday<CR>
      ]]
    end
  },
  { 'kana/vim-metarw' },
  { 'mattn/webapi-vim' },
  { 'rhysd/clever-f.vim',
    init = function()
      vim.cmd [[
      let g:clever_f_smart_case = 1
    ]]
    end
  },
  { 'haya14busa/vim-asterisk' },
  { 'Shougo/deol.nvim' },
  { 'dbridges/vim-markdown-runner',
    init = function()
      vim.cmd [[
        autocmd FileType markdown nnoremap <buffer> <Leader>q :MarkdownRunnerInsert<CR>
        autocmd FileType markdown nnoremap <buffer> <Leader>w :MarkdownRunner<CR>
      ]]
      vim.g.markdown_runners = {
        mermaid = function(src)
          local n = os.tmpname()
          local f = assert(io.open(n, 'w'))
          f:write(table.concat(src, "\n"))
          f:close()
          local job = require('plenary.job'):new {
            command = "mmdc",
            args = {
              "-i", n,
              "-o", "output.png",
              "-b", "white"
            },
            writer = src,
          }
          job:sync()
          return table.concat(job:stderr_result(), "\n")
        end,
      }
    end
  },
  { 'folke/noice.nvim',
    dependencies = { "nui.nvim", "nvim-notify", "nvim-cmp" },
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
            --- type NoiceFormat|strin
            format = "lsp_progress",
            --- type NoiceFormat|string
            format_done = "lsp_progress_done",
            throttle = 1000 / 30, -- frequency to update lsp progress message
            view = "mini",
          },
          hover = {
            enabled = true,
            view = nil, -- when nil, use defaults from documentation
            ---type NoiceViewOptions
            opts = {
              border = {
                style = "rounded",
                padding = { 0, 0 },
              },
              win_options = {
                winhighlight = {
                  Normal = "NoiceSplit",
                  FloatBorder = "NoiceSplitBorder"
                },
                wrap = true,
              },
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
            ---type NoiceViewOptions
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
            ---type NoiceViewOptions
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
          view_history = "messages",
          view_search = "mini",
        },
        popupmenu = {
          enabled = true, -- disable if you use something like cmp-cmdline
          ---@type 'nui'|'cmp'
          backend = "cmp", -- backend to use to show regular cmdline completions
        },
        -- default options for require('noice').redirect
        -- see the section on Command Redirection
        -- type NoiceRouteConfig
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
        -- type table<string, NoiceViewOptions>
        views = {
          cmdline_popup = { position = { row = 20, col = "50%" } },
        },
        health = {
          checker = false,
        },
        -- NOTE ここから下はデフォルト
        -- type NoiceRouteConfig[]
        routes = {}, -- @see the section on routes below
        -- type table<string, NoiceFilter>
        status = {}, --@see the section on statusline components below
        -- type NoiceFormatOptions
        format = {}, -- @see section on formatting
      }
    end,
  },
  { 'nvim-neo-tree/neo-tree.nvim',
    dependencies = {
      "plenary.nvim",
      "nvim-web-devicons",
      "nui.nvim",
      "netman.nvim",
    },
    init = function()
      require("neo-tree").setup({
        sources = {
          "filesystem",
          "netman.ui.neo-tree",
        },
        source_selector = {
          winbar = true,
          statusline = false
        },
        window = {
          mappings = {
            ["z"] = {},
            ["zl"] = "unfocus",
          },
        },
        commands = {
          unfocus = function(_)
            vim.cmd [[wincmd l]]
          end,
        },
        filesystem = {
          bind_to_cwd = false,
          filtered_items = {
            hide_dotfiles = false,
            hide_hidden = false,
            never_show = {
              ".git",
            },
          },
          window = {
            mappings = {
              ["z"] = {},
              ["zl"] = "unfocus",
            },
          },
          commands = {
            unfocus = function(_)
              vim.cmd [[wincmd l]]
            end,
          },
        },
        ["netman.ui.neo-tree"] = {
          filtered_items = {
            hide_dotfiles = false,
            hide_hidden = false,
            never_show = {
              ".git",
            },
          },
          window = {
            mappings = {
              ["z"] = {},
              ["zl"] = "unfocus",
            },
          },
          commands = {
            unfocus = function(_)
              vim.cmd [[wincmd l]]
            end,
          },
        },
      })
      vim.cmd [[
        nnoremap <Leader>f :Neotree<CR>
      ]]
    end
  },
  { 'jrudess/vim-foldtext' },
  { 'gennaro-tedesco/nvim-possession',
    dependencies = { 'fzf-lua' },
    init = function()
      local possession = require("nvim-possession")
      possession.setup {
        autoload = true,
        autosave = true,
        autoswitch = {
          enable = true,
          exclude_ft = {}, -- list of filetypes to exclude from autoswitch
        },
      }
      vim.keymap.set("n", "<leader>sl", function()
        possession.list()
      end)
      vim.keymap.set("n", "<leader>sn", function()
        possession.new()
      end)
      vim.keymap.set("n", "<leader>su", function()
        possession.update()
      end)
    end,
  },
  { 'hrsh7th/nvim-cmp',
    config = function()
      local cmp = require("cmp")
      ---@diagnostic disable-next-line: redundant-parameter
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
          ['<CR>']    = cmp.mapping.confirm({ select = false }),
          ['<C-c>']   = cmp.mapping.abort(),
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
          { name = 'buffer' },
        }, {
          {
            name = 'rg',
            keyword_length = 3,
          },
          {
            name = 'path',
            options = { trailing_slash = false, },
            trigger_characters = { '/', '.', '~' },
          },
        })
      })
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
          {
            name = 'path',
            options = { trailing_slash = false, },
          },
        }, {
          { name = 'cmdline' }
        })
      })
    end,
    dependencies = {
      { 'hrsh7th/cmp-nvim-lsp' },
      { 'hrsh7th/cmp-nvim-lsp-signature-help' },
      { 'hrsh7th/cmp-nvim-lsp-document-symbol' },
      { 'hrsh7th/cmp-buffer' },
      { 'hrsh7th/cmp-path' },
      { 'hrsh7th/cmp-emoji' },
      { 'hrsh7th/cmp-cmdline' },
      { 'hrsh7th/cmp-vsnip' },
      { 'lukas-reineke/cmp-rg' },
      { 'hrsh7th/vim-vsnip',
        init = function()
          vim.cmd [[
            let g:vsnip_snippet_dir = expand('~/.config/nvim/vsnip')
            imap <expr> <C-f> vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-f>'
            smap <expr> <C-f> vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-f>'
            xmap        <C-f> <Plug>(vsnip-cut-text)
          ]]
        end,
      },
      { 'hrsh7th/vim-vsnip-integ',
        init = function()
          vim.cmd [[
            autocmd User PumCompleteDone call vsnip_integ#on_complete_done(g:pum#completed_item)
          ]]
        end,
      },
    },
  },
  -- [Git]
  { 'NeogitOrg/neogit',
    init = function()
      require("neogit").setup {
        disable_signs = false,
        disable_hint = false,
        disable_context_highlighting = false,
        disable_commit_confirmation = true,
        auto_refresh = true,
        sort_branches = "-committerdate",
        disable_builtin_notifications = false,
        use_telescope = true,
        use_magit_keybindings = false,
        kind = "replace",
        console_timeout = 2000,
        auto_show_console = true,
        remember_settings = true,
        use_per_project_settings = true,
        ignored_settings = {},
        popup = {
          kind = "vsplit",
        },
        status = {
          recent_commit_count = 50,
        },
        integrations = {
          diffview = true,
        },
        mappings = {
          status = {
            ["b"] = "",
            ["B"] = "BranchPopup",
            ["<c-t>"] = "disabled-<c-t>",
            ["t"] = "TabOpen",
          },
          finder = {
          }
        },
      }
      vim.cmd [[
        nnoremap <Leader>g :Neogit<CR>
        autocmd FileType NeogitStatus       setlocal foldmethod=diff
        autocmd FileType NeogitCommitReview setlocal foldmethod=diff
      ]]
    end,
    dependencies = {
      { 'iceberg.vim' },
      { 'sindrets/diffview.nvim' },
    },
  },
  { 'tpope/vim-fugitive' },
  { 'lambdalisue/gina.vim',
    init = function()
      vim.cmd [[
        autocmd FileType gina-log nmap F <Plug>(gina-show-commit-vsplit)zv
        "autocmd FileType gina-log nmap F <Plug>(gina-show-commit-preview)zv
      ]]
    end
  },
  { 'lewis6991/gitsigns.nvim',
    init = function()
      require('gitsigns').setup({
        signcolumn = false,
        numhl      = true,
      })
    end,
  },
  -- [LSP]
  { 'neovim/nvim-lspconfig',
    config = function()
      -- [Common]
      -- [[diagnostic]]
      vim.diagnostic.config({
        virtual_text = {
          prefix = "",
        },
      })
      vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', { noremap = true, silent = true })
      vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', { noremap = true, silent = true })

      -- [[code lens]]
      -- NOP

      -- [[on_attach]]
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.g.lsp_default_on_attach = function(client, bufnr)
        local bmap = function(mode, key, cmd)
          vim.keymap.set(mode, key, cmd, { noremap = true, silent = true })
        end
        bmap('n', '<C-h>', vim.lsp.buf.hover)
        bmap('n', '<C-j>', '<cmd>Lspsaga finder def+ref<CR>')
        bmap('n', '<C-k>', '<cmd>Lspsaga peek_definition<CR>')
        bmap('n', '<C-l>a', require("actions-preview").code_actions)
        bmap('n', '<C-l>o', '<cmd>Navbuddy<CR>')
        bmap('n', '<C-l>f', vim.lsp.buf.format)
        bmap('v', '<C-l>f', vim.lsp.buf.format)
        bmap('n', '<C-l>h', vim.lsp.buf.signature_help)
        bmap('n', '<C-l>d', vim.lsp.buf.type_definition)
        bmap('n', '<C-l>r', vim.lsp.buf.references)
        bmap('n', '<C-l>R', vim.lsp.buf.rename)
        bmap('n', '<C-l>j', vim.lsp.buf.definition)
        bmap('n', '<C-l>l', vim.lsp.codelens.run)
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
        require 'lsp-format'.on_attach(client, bufnr)
      end

      -- [[capabilities]]
      -- enable completion
      vim.g.lsp_default_capabilities = require('cmp_nvim_lsp').default_capabilities()
      -- enable snippet support
      vim.g.lsp_default_capabilities.textDocument.completion.completionItem.snippetSupport = true
      -- [[set default]]
      require 'lspconfig'.util.default_config = vim.tbl_extend("force",
        require 'lspconfig'.util.default_config,
        {
          on_attach = vim.g.lsp_default_on_attach,
          capabilities = vim.g.lsp_default_capabilities,
        }
      )

      -- [Per server]
      -- [[hls]]
      require 'lspconfig'['hls'].setup {
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

      -- [[denols]]
      require 'lspconfig'['denols'].setup {
        root_dir = require 'lspconfig'.util.root_pattern("deno.json"),
        init_options = {
          lint = true,
        },
      }

      -- [[tsserver]]
      require 'lspconfig'['tsserver'].setup {
        root_dir = require 'lspconfig'.util.root_pattern("package.json"),
        init_options = {
          lint = true,
        },
      }

      -- [[lua_ls]]
      require 'lspconfig'.lua_ls.setup {
        settings = {
          Lua = {
            runtime = {
              version = 'LuaJIT',
            },
            diagnostics = {
              globals = { 'vim', 'use' },
            },
            telemetry = {
              enable = false,
            },
          },
        },
      }
      -- [[nil_ls]]
      require 'lspconfig'['nil_ls'].setup {
        settings = {
          ["nil"] = {
            formatting = {
              command = { "nixpkgs-fmt" }
            },
          },
        },
      }
      -- [[others]]
      require 'lspconfig'['bashls'].setup {}
      require 'lspconfig'['dhall_lsp_server'].setup {}
      require 'lspconfig'['eslint'].setup {}
      require 'lspconfig'['gopls'].setup {}
      require 'lspconfig'['jsonls'].setup {}
      require 'lspconfig'['rust_analyzer'].setup {}
      require 'lspconfig'['graphql'].setup {}
      require 'lspconfig'['pyright'].setup {}
      require 'lspconfig'['yamlls'].setup {}
      require 'lspconfig'['terraformls'].setup {}
      require 'lspconfig'['tflint'].setup {}
      require 'lspconfig'['dockerls'].setup {}
      require 'lspconfig'['sqlls'].setup {}
    end,
    dependencies = {
      { 'WhoIsSethDaniel/mason-tool-installer.nvim',
        config = function()
          require('mason-tool-installer').setup {
            ensure_installed = {
              -- [LSP]
              "bash-language-server",
              "dhall-lsp",
              "diagnostic-languageserver",
              "dockerfile-language-server",
              "eslint-lsp",
              "gopls",
              "graphql-language-service-cli",
              "jdtls",
              "json-lsp",
              "lua-language-server",
              "pyright",
              "terraform-ls",
              "tflint",
              "typescript-language-server",
              "yaml-language-server",
              "sqls",
              -- [DAP]
              "java-debug-adapter",
              "java-test",
              -- [null-ls]
              "actionlint",
              "black",
              "flake8",
              "hadolint",
              "prettier",
              "shfmt",
              "yamllint",
            },
            auto_update = false,
            run_on_start = true,
            start_delay = 3000, -- 3 second delay
          }
        end,
        dependencies = {
          { 'williamboman/mason-lspconfig.nvim',
            config = true,
          },
          { 'williamboman/mason.nvim',
            config = true,
          },
        },
      },
      { 'lukas-reineke/lsp-format.nvim',
        config = function()
          require "lsp-format".setup {
            java = {
              exclude = { "jdtls" }
            }
          }
          -- 自動フォーマット
          vim.cmd [[cabbrev wq execute "Format sync" <bar> wq]]
        end
      },
      { 'jose-elias-alvarez/null-ls.nvim',
        config = function()
          local null_ls = require("null-ls")
          local h = require("null-ls.helpers")
          local methods = require("null-ls.methods")

          local spotbugs = h.make_builtin({
            name = "spotbugs",
            meta = {
              url = "https://spotbugs.github.io/",
              description = "SpotBugs is a program which uses static analysis to look for bugs in Java code",
            },
            method = methods.internal.DIAGNOSTICS_ON_SAVE,
            filetypes = { "java" },
            generator_opts = {
              command = "spotbugs",
              args = { "$ROOT" },
              format = "json",
              on_output = function(params)
                local parser = h.diagnostics.from_json({})
                return parser({ output = params.output.comments })
              end,
              multiple_files = true,
              check_exit_code = function(code)
                return code >= 1
              end,
              from_stderr = true, -- なぜかstderrに出力される？
            },
            factory = h.generator_factory,
          })

          local spotless = h.make_builtin({
            name = "spotless",
            timeout = 50000,
            meta = {
              url = "https://github.com/diffplug/spotless",
              description = "Spotless is a general-purpose formatter",
            },
            method = methods.internal.FORMATTING,
            filetypes = { "java", "groovy" },
            generator_opts = {
              command = "bash",
              args = {
                '-c',
                'cd "$ROOT" && ./gradlew spotlessApply -PspotlessIdeHook="$FILENAME" --quiet',
              },
              to_stdin = false,
              to_temp_file = true,
              from_temp_file = true,
            },
            factory = h.formatter_factory,
          })

          null_ls.setup {
            log_level = "trace",
            on_attach = vim.g.lsp_default_on_attach,
            default_timeout = 50000,
            sources = {
              -- diagnostics
              null_ls.builtins.diagnostics.actionlint,
              null_ls.builtins.diagnostics.flake8,
              null_ls.builtins.diagnostics.hadolint,
              null_ls.builtins.diagnostics.yamllint,
              -- null_ls.builtins.diagnostics.checkstyle.with({
              --   extra_args = { "--", "-f", "sarif", "$FILENAME" },
              -- }),
              -- spotbugs,
              -- formatter
              null_ls.builtins.formatting.black,
              null_ls.builtins.formatting.jq,
              null_ls.builtins.formatting.just,
              null_ls.builtins.formatting.prettier.with({
                filetypes = {
                  "javascript",
                  "javascriptreact",
                  "typescript",
                  "typescriptreact",
                  "json",
                  "jsonc",
                  "yaml",
                  "css",
                  "scss",
                  "html",
                },
              }),
              null_ls.builtins.formatting.shfmt.with({
                extra_args = { "-i", "4", "-ci" },
              }),
              -- spotless,
            }
          }
          -- require("null-ls").disable({ name = "spotbugs" })
        end,
        dependencies = { "plenary.nvim" },
      },
      { 'aznhe21/actions-preview.nvim' },
      { "SmiteshP/nvim-navbuddy",
        dependencies = {
          { "SmiteshP/nvim-navic",
            opts = { lsp = { auto_attach = true } },
          },
          { "MunifTanjim/nui.nvim" }
        },
        opts = { lsp = { auto_attach = true } }
      },
    },
  },
  { 'tamago324/nlsp-settings.nvim',
    dependencies = { 'nvim-lspconfig' },
    init = function()
      require 'nlspsettings'.setup({
        append_default_schemas = true,
        loader = 'yaml',
        nvim_notify = {
          enable = true,
        },
      })
    end,
  },
  { 'folke/trouble.nvim',
    init = function()
      require('trouble').setup {}
      vim.keymap.set('n', '<space>q', '<cmd>TroubleToggle<CR>', { noremap = true, silent = true })
    end,
  },
  { 'nvimdev/lspsaga.nvim',
    init = function()
      require('lspsaga').setup({
        request_timeout = 1000,
        ui = {
          border = 'rounded'
        },
        lightbulb = {
          sign = false,
          virtual_text = false,
        },
        symbol_in_winbar = {
          enable = false,
        },
        finder = {
          keys = {
            toggle_or_open = '<CR>',
            shuttle = 'zl',
            quit = { 'q', '<ESC>' },
          },
        },
        outline = {
          keys = {
            toggle_or_jump = '<CR>',
            quit = "q",
          },
        }
      })
    end,
  },
  { 'j-hui/fidget.nvim', tag = 'legacy',
    init = function()
      require 'fidget'.setup {}
    end
  },
  { 'mfussenegger/nvim-jdtls' },
  -- [DAP]
  { 'mfussenegger/nvim-dap',
    init = function()
      vim.cmd [[
      autocmd FileType dap-repl lua require('dap.ext.autocompl').attach()
    ]]
    end
  },
  { 'theHamsta/nvim-dap-virtual-text',
    dependencies = { 'nvim-dap' },
    init = function()
      require("nvim-dap-virtual-text").setup({})
    end
  },
  { "rcarriga/nvim-dap-ui",
    dependencies = { 'nvim-dap' },
    init = function()
      require("dapui").setup()
    end
  },
  -- [Filetype]
  -- [[Haskell]]
  { 'neovimhaskell/haskell-vim' },
  -- [[dhall]]
  { 'vmchale/dhall-vim' },
  -- [[Rust]]
  { 'rust-lang/rust.vim' },
  -- [[GraphQL]]
  { 'jparise/vim-graphql' },
  -- [[nix]]
  { 'LnL7/vim-nix' },
  -- [[Markdown]]
  { 'preservim/vim-markdown',
    init = function()
      vim.g.vim_markdown_folding_disabled = 1
      vim.g.vim_markdown_new_list_item_indent = 2
    end
  },
  { "iamcco/markdown-preview.nvim",
    build = "cd app && npm install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
  },
  { 'vim-voom/VOoM' },
  -- [[terraform]]
  { 'hashivim/vim-terraform' },
  -- [[Textile]]
  { 's3rvac/vim-syntax-redminewiki',
    init = function()
      vim.cmd [[
        autocmd BufEnter *.redmine set ft=redminewiki
      ]]
    end
  },
  -- [[JavaScript/TypeScript]]
  { 'jelera/vim-javascript-syntax' },
  { 'leafgarland/typescript-vim' },
}
