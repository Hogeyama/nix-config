local is_light_mode = vim.env.NVIM_LIGHT_MODE == "1"
local is_inside_vscode = vim.env.VSCODE_INJECTION == '1'

return {
  { 'nvim-lua/plenary.nvim' },
  { 'nvim-lua/popup.nvim' },
  { 'MunifTanjim/nui.nvim' },
  { 'nvim-tree/nvim-web-devicons' },
  {
    'rcarriga/nvim-notify',
    enabled = not is_light_mode and not vim.g.vscode,
    opts = {
      timeout = 2000,
      render = "compact",
      stages = "static",
      on_open = function(win)
        vim.api.nvim_set_option_value("winblend", 30, { win = win })
        vim.api.nvim_win_set_config(win, { zindex = 100 })
      end
    },
  },
  {
    'gbprod/yanky.nvim',
    enabled = true,
    config = function()
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
  {
    'ibhagwan/fzf-lua',
    event = "VeryLazy",
    enabled = true,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local actions = require "fzf-lua.actions"
      require("fzf-lua").setup({
        actions = {
          files = {
            ["default"] = function(selected, opts)
              opts.copen = false
              if #selected > 1 then
                local r = actions.file_sel_to_qf(selected, opts)
                require("trouble").open("quickfix")
                return r
              else
                return actions.file_edit(selected, opts)
              end
            end,
            ["ctrl-s"]  = actions.file_split,
            ["ctrl-v"]  = actions.file_vsplit,
            ["ctrl-t"]  = actions.file_tabedit,
            ["alt-q"]   = actions.file_sel_to_qf,
            ["alt-l"]   = actions.file_sel_to_ll,
          },
          buffers = {
            ["default"] = actions.buf_edit,
            ["ctrl-s"]  = actions.buf_split,
            ["ctrl-v"]  = actions.buf_vsplit,
            ["ctrl-t"]  = actions.buf_tabedit,
          }
        },
      })
    end
  },
  {
    'nvim-telescope/telescope.nvim',
    event = "VeryLazy",
    enabled = true and not vim.g.vscode,
    config = function()
      require('telescope').setup {
        defaults = {
          mappings = {
            i = {
              ["<Esc>"] = require('telescope.actions').close,
              ["<Tab>"] = require('telescope.actions').move_selection_next,
              ["<S-Tab>"] = require('telescope.actions').move_selection_previous,
              ["<C-Space>"] = require('telescope.actions').toggle_selection
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
      { 'gbprod/yanky.nvim' },
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make'
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
    },
  },
  {
    "chrisgrieser/nvim-rip-substitute",
    enabled = not is_light_mode and not vim.g.vscode,
    cmd = "RipSubstitute",
    keys = {
      {
        "<leader>fs",
        function() require("rip-substitute").sub() end,
        mode = { "n", "x" },
        desc = "rip substitute",
      },
    },
  },
  {
    'miversen33/netman.nvim',
    event = "VeryLazy",
    enabled = not is_light_mode and not vim.g.vscode,
    config = true,
  },
  {
    'stevearc/resession.nvim',
    enabled = not is_light_mode and not vim.g.vscode,
    dependencies = {
      'neovim/nvim-lspconfig'
    },
    config = function()
      local resession = require("resession")
      resession.setup()

      local session_name = function()
        local pwd = vim.fn.getcwd()
        local branch = vim.trim(vim.fn.system("git branch --show-current"))
        return vim.v.shell_error == 0 and pwd .. "@" .. branch or pwd
      end

      vim.api.nvim_create_user_command('LoadSession',
        function()
          vim.g.session_loaded = 1
          resession.load(session_name(), { silence_errors = true })
        end,
        {}
      )

      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
          local has_buf = false
          local bufs = vim.fn.getbufinfo()
          for _, buf in ipairs(bufs) do
            if buf.listed == 1 and buf.name ~= '' then
              has_buf = true
            end
          end
          if has_buf then
            resession.save(session_name(), { notify = false })
          end
        end,
      })
    end,
    keys = {
      { "<leader>sl",  "<Cmd>LoadSession<CR>",                          mode = { 'n' } },
      { "<leader>ssl", function() require("resession").load(nil) end,   mode = { 'n' } },
      { "<leader>ssd", function() require("resession").delete(nil) end, mode = { 'n' } },
      {
        "<leader>ssr",
        function()
          require("resession").save(require("resession").get_current())
          require("resession").load(require("resession").get_current())
        end,
        mode = { 'n' }
      },
    }
  },
  {
    'echasnovski/mini.nvim',
    event = "VeryLazy",
    enabled = true,
    config = function()
      require('mini.ai').setup()
      require('mini.align').setup({
        mappings = {
          start = '',
          start_with_preview = 'ga',
        },
      })
      require('mini.pairs').setup()
      require('mini.trailspace').setup()
      require('mini.bracketed').setup()
      require('mini.starter').setup({
        items = {
          function()
            local items = {}
            for _, session in ipairs(require('resession').list()) do
              table.insert(items, {
                name = session:gsub("_", "/"),
                action = [[lua require("resession").load("]] .. session .. [[")]],
                section = 'Sessions'
              })
            end
            return items
          end,
        },
        footer = '',
      })
      require('mini.visits').setup({
        list = {
          filter = function(path_data)
            return not vim.endswith(path_data.path, 'COMMIT_EDITMSG')
          end,
          sort = require('mini.visits').gen_sort.default({ recency_weight = 1 })
        },
      })

      vim.api.nvim_create_user_command('RmTrailingWhiteSpaces',
        function() require('mini.trailspace').trim() end,
        {}
      )
      vim.api.nvim_create_user_command('MkSession',
        function(opts)
          require('mini.sessions').write(opts.args, {})
        end,
        { nargs = 1 }
      )
      vim.keymap.set({ "n" }, "1", function()
        local paths = { table.unpack(require 'mini.visits'.list_paths(nil), 1, 50) }
        vim.ui.select(
          paths,
          {
            format_item = function(item)
              local replace_prefix = function(s, p, r)
                return s:sub(1, #p) == p and r .. s:sub(#p + 1) or s
              end
              local home = vim.env.HOME
              local pwd = vim.fn.getcwd()
              return replace_prefix(replace_prefix(item, pwd .. "/", ""), home, '~')
            end,
          },
          function(choice)
            if choice ~= nil then
              vim.cmd('edit ' .. choice)
            end
          end)
      end)
    end,
    dependencies = {
      'stevearc/resession.nvim',
    },
  },
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      words = { enabled = true },
      scratch = { ft = function() return "markdown" end }
    },
    keys = {
      { "<leader>go", function() Snacks.gitbrowse.open() end, mode = { 'n' } },
    }
  },
  {
    'nvim-treesitter/nvim-treesitter',
    event = "VeryLazy",
    enabled = true and not vim.g.vscode,
    config = function()
      require 'nvim-treesitter.configs'.setup {
        ensure_installed = {},
        sync_install = false,
        auto_install = false,
        highlight = {
          enable = true,
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
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "b",
            node_incremental = "b",
            node_decremental = "v",
            scope_incremental = false,
          },
        },
      }
      require 'treesitter-context'.setup {
        enable = true,
        max_lines = 0,            -- How many lines the window should span. Values <= 0 mean no limit.
        min_window_height = 0,    -- Minimum editor window height to enable context. Values <= 0 mean no limit.
        line_numbers = true,
        multiline_threshold = 20, -- Maximum number of lines to show for a single context
        trim_scope = 'outer',     -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
        mode = 'cursor',          -- Line used to calculate context. Choices: 'cursor', 'topline'
        -- Separator between context and content. Should be a single character string, like '-'.
        -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
        separator = nil,
        zindex = 20,     -- The Z-index of the context window
        on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
      }

      -- configure nushell
      local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
      parser_config.nu = {
        install_info = {
          url = "https://github.com/nushell/tree-sitter-nu",
          files = { "src/parser.c" },
          branch = "main",
        },
        filetype = "nu",
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
      { 'nvim-treesitter/nvim-treesitter-context' },
      { 'mfussenegger/nvim-treehopper' },
      {
        'JoosepAlviste/nvim-ts-context-commentstring',
        config = function()
          require('ts_context_commentstring').setup {
            enable_autocmd = false,
          }
        end
      },
    },
  },
  {
    'nvimtools/hydra.nvim',
    event = "VeryLazy",
    enabled = not is_light_mode and not vim.g.vscode,
    config = function()
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
          { 'L', 'zO' },
          { 'H', 'zC' },
          { 'l', 'zo' },
          { 'h', 'zc' },
          { 'k', 'zk' },
          { 'j', 'zj' },
        }
      })
    end,
    dependencies = {
      { 'gitsigns.nvim' },
      { 'neogit' },
    },
  },
  {
    'catppuccin/nvim',
    enabled = true,
    name = "catppuccin",
    config = function()
      require("catppuccin").setup {
        flavour = "macchiato",
        background = {
          light = "latte",
          dark = "macchiato",
        },
        term_colors = true,
        dim_inactive = {
          enabled = true,
          shade = "dark",
          percentage = 0.1,
        },
        styles = {
          comments = {},
          conditionals = {},
          loops = {},
          functions = {},
          keywords = {},
          strings = {},
          variables = {},
          numbers = {},
          booleans = {},
          properties = {},
          types = {},
          operators = {},
        },
        color_overrides = {},
        custom_highlights = {},
        integrations = {
          cmp = false,
          gitsigns = true,
          nvimtree = true,
          treesitter = true,
          notify = true,
          mini = {
            enabled = true,
            indentscope_color = "",
          },
          dropbar = {
            enabled = false,
          },
          fidget = true,
          hop = true,
          indent_blankline = {
            enabled = true,
            colored_indent_levels = true,
          },
          markdown = true,
          neotree = true,
          noice = true,
          dap = true,
          dap_ui = true,
        },
      }
      vim.cmd [[
        set background=dark
        set termguicolors
        colorscheme catppuccin
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
  {
    'editorconfig/editorconfig-vim',
    enabled = true and not vim.g.vscode,
    config = function()
      vim.cmd [[
        let g:EditorConfig_max_line_indicator = 'exceeding'
      ]]
    end,
  },
  {
    'numToStr/FTerm.nvim',
    enabled = true and not vim.g.vscode,
    event = "VeryLazy",
    config = function()
      local fterm = require 'FTerm'
      local shells = {}
      local opts = {
        border = 'rounded',
        dimensions = { height = 0.9, width = 0.9 }
      }
      local toggle_shell = function(shell)
        for _, s in pairs(shells) do
          if s ~= shell then
            s:close()
          end
        end
        shell:toggle()
      end
      local zsh = function()
        return {
          cmd = "zsh",
          border = opts.border,
          dimensions = opts.dimensions
        }
      end
      local fzfw = function()
        return {
          cmd = "fzfw",
          border = opts.border,
          dimensions = opts.dimensions,
        }
      end
      local shellDefs = {
        zsh6 = { num = 6, def = zsh },
        zsh7 = { num = 7, def = zsh },
        fzfw = { num = 8, def = fzfw },
        zsh9 = { num = 9, def = zsh },
        zsh0 = { num = 0, def = zsh },
      }
      for name, shell in pairs(shellDefs) do
        shells[name] = fterm:new(shell.def())
        vim.keymap.set({ "n", "t" },
          "<F" .. shell.num .. ">",
          function() toggle_shell(shells[name]) end
        )
      end
      vim.keymap.set({ "n" }, "B", function()
        -- switch to buffer mode
        shells.fzfw:run(vim.api.nvim_replace_termcodes('<C-b>', true, true, true))
      end)
      vim.keymap.set({ "n" }, "M", function()
        -- switch to mark mode
        shells.fzfw:run(vim.api.nvim_replace_termcodes('<C-d>', true, true, true))
      end)
      vim.api.nvim_create_user_command('FloatermHide', function() -- TODO rename
        for _, s in pairs(shells) do
          s:close()
        end
      end, { bang = true, nargs = "*" })
    end,
  },
  {
    'lukas-reineke/indent-blankline.nvim',
    enabled = not is_light_mode and not vim.g.vscode,
    main = "ibl",
    opts = {
      scope = {
        enabled = false,
      },
    },
  },
  {
    'smoka7/hop.nvim',
    enabled = true,
    config = function()
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
  {
    'chrisgrieser/nvim-spider',
    enabled = true,
    config = function()
      require("spider").setup({
        skipInsignificantPunctuation = true
      })
      vim.keymap.set({ "n", "o", "x" }, "w", "<cmd>lua require('spider').motion('w')<CR>", { desc = "Spider-w" })
      vim.keymap.set({ "n", "o", "x" }, "e", "<cmd>lua require('spider').motion('e')<CR>", { desc = "Spider-e" })
      vim.keymap.set({ "n", "o", "x" }, "W", "<cmd>lua require('spider').motion('b')<CR>", { desc = "Spider-b" })
      vim.keymap.set({ "n", "o", "x" }, "E", "<cmd>lua require('spider').motion('ge')<CR>", { desc = "Spider-ge" })
    end
  },
  {
    'godlygeek/tabular',
    enabled = true,
  },
  {
    'numToStr/Comment.nvim',
    event = "VeryLazy",
    enabled = true,
    dependencies = { 'JoosepAlviste/nvim-ts-context-commentstring' },
    config = function()
      local pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook()
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
        pre_hook = function(ctx)
          -- なんかうまく動かない
          if vim.opt.filetype:get() == "haskell" then
            return
          end
          pre_hook(ctx)
        end,
      })
    end
  },
  {
    'machakann/vim-sandwich',
    enabled = true,
    config = function()
      vim.cmd [[
        vmap s <Plug>(operator-sandwich-add)
      ]]
    end
  },
  {
    'nvim-lualine/lualine.nvim',
    enabled = not is_light_mode and not vim.g.vscode,
    opts = {
      sections = {
        -- default + copilot
        lualine_x = { 'copilot', 'encoding', 'fileformat', 'filetype' },
      },
    },
    dependencies = {
      'nvim-tree/nvim-web-devicons',
      'AndreM222/copilot-lualine',
    }
  },
  {
    'nanozuki/tabby.nvim',
    enabled = false,
    -- enabled = not is_light_mode and not vim.g.vscode and not is_inside_vscode,
    config = function()
      vim.opt.sessionoptions = 'curdir,folds,globals,help,tabpages,terminal,winsize'
      local api = require('tabby.module.api')
      local buf_name = require('tabby.feature.buf_name')
      local theme = {
        fill = 'TabLineFill',
        sep = 'TabLine',
        head = 'TabLine',
        current_tab = 'TabLineSel',
        tab = 'TabLine',
        win = 'TabLine',
      }
      require('tabby.tabline').set(function(line)
        return {
          {
            { '  ', hl = theme.head },
          },
          line.tabs().foreach(function(tab)
            local hl = tab.is_current() and theme.current_tab or theme.tab
            return {
              line.sep(' ', hl, theme.sep),
              tab.name(),
              tab.close_btn(''),
              hl = hl,
              margin = ' ',
            }
          end),
          line.spacer(),
          line.wins_in_tab(line.api.get_current_tab()).foreach(function(win)
            return {
              line.sep(' ', theme.win, theme.sep),
              win.is_current() and '' or '',
              win.buf_name(),
              hl = theme.win,
              margin = ' ',
            }
          end),
        }
      end, {
        tab_name = {
          name_fallback = function(tabid)
            local wins = api.get_tab_wins(tabid)
            local cur_win = api.get_tab_current_win(tabid)
            local name = ''
            if api.is_float_win(cur_win) then
              name = '[Floating]'
            else
              name = buf_name.get(cur_win)
            end
            if #wins > 1 then
              name = string.format('%s…', name)
            end
            return name
          end,
        },
        buf_name = {
          mode = 'unique'
        }
      })
    end,
  },
  {
    'AndrewRadev/linediff.vim',
    enabled = true and not vim.g.vscode,
  },
  {
    'machakann/vim-highlightedyank',
    enabled = true and not vim.g.vscode,
  },
  {
    'glidenote/memolist.vim',
    enabled = not is_light_mode,
    config = function()
      vim.g.memolist_path = '~/.memo'
      vim.g.memolist_template_dir_path = '~/.memo/template'
      vim.cmd [[
        command! MemoToday MemoNewWithMeta 'note', 'daily', 'daily'
      ]]
    end
  },
  {
    'kana/vim-metarw',
    enabled = not is_light_mode and not vim.g.vscode,
  },
  {
    'rhysd/clever-f.vim',
    enabled = true,
    config = function()
      vim.cmd [[
      let g:clever_f_smart_case = 1
    ]]
    end
  },
  {
    'haya14busa/vim-asterisk',
    enabled = true,
  },
  {
    'dbridges/vim-markdown-runner',
    enabled = not is_light_mode,
    config = function()
      -- vim.cmd [[
      --   autocmd FileType markdown nnoremap <buffer> <Leader>q :MarkdownRunnerInsert<CR>
      --   autocmd FileType markdown nnoremap <buffer> <Leader>w :MarkdownRunner<CR>
      -- ]]
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
  {
    'folke/noice.nvim',
    event = "VeryLazy",
    enabled = not is_light_mode and not vim.g.vscode,
    dependencies = { "nui.nvim", "nvim-notify" },
    config = function()
      require("noice").setup {
        presets = {
          command_palette = true,
          lsp_doc_border = true,
        },
        views = {
          cmdline_popup = {
            position = {
              row = 20,
              col = "50%",
            },
          },
        },
        cmdline = {
          enabled = true,
          view = "cmdline_popup",
          format = {
            cmdline = { pattern = "^:", icon = "", lang = "vim" },
            search_down = { kind = "search", pattern = "^/", icon = "  ", lang = "regex" },
            search_up = { kind = "search", pattern = "^%?", icon = "  ", lang = "regex" },
            filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
            lua = { pattern = "^:%s*lua%s+", icon = " ", lang = "lua" },
            help = { pattern = "^:%s*he?l?p?%s+", icon = "❓" },
            input = {}, -- Used by input()
          },
        },
        popupmenu = {
          enabled = true,
          backend = "nui",
        },
        messages = {
          enabled = true,
          view = "mini",
          view_error = "mini",
          view_warn = "mini",
          view_history = "messages",
          view_search = "mini",
        },
        notify = {
          enabled = true,
          view = "notify",
        },
        throttle = 1000 / 30, -- how frequently does Noice need to check for ui updates? This has no effect when in blocking mode.
        lsp = {
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = false,
          },
          message = {
            view = "mini",
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
              win_options = { conceallevel = 0 },
            },
          },
        },
      }
    end,
  },
  {
    'nvim-neo-tree/neo-tree.nvim',
    event = "VeryLazy",
    enabled = not is_light_mode and not vim.g.vscode,
    dependencies = {
      "plenary.nvim",
      "nvim-web-devicons",
      "nui.nvim",
      "netman.nvim",
    },
    config = function()
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
  {
    'stevearc/oil.nvim',
    enabled = not is_light_mode,
    opts = {},
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
  {
    'klen/nvim-config-local',
    enabled = not is_light_mode,
    config = function()
      require('config-local').setup {
        config_files = { ".nvim.lua" },
        hashfile = vim.fn.stdpath("data") .. "/config-local",
        autocommands_create = true, -- default
        commands_create = true,     -- default
        silent = false,             -- default
        lookup_parents = false,     -- default
      }
    end
  },
  {
    'jrudess/vim-foldtext',
    enabled = not is_light_mode and not vim.g.vscode,
  },
  {
    'kevinhwang91/nvim-ufo',
    enabled = not is_light_mode and not vim.g.vscode,
    dependencies = { 'kevinhwang91/promise-async' },
    event = "VeryLazy",
    config = function()
      vim.o.foldcolumn = '0'
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
      vim.keymap.set('n', 'zR', function()
        vim.cmd [[Lazy reload nvim-ufo]]
        return require('ufo').openAllFolds
      end)
      vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)
      vim.keymap.set('n', 'zv', '<Cmd>lua require("ufo").closeAllFolds()<CR>zvzO', { noremap = true })
      require('ufo').setup({
        provider_selector = function()
          return { 'treesitter', 'indent' }
        end
      })
    end
  },
  {
    'saghen/blink.cmp',
    enabled = not vim.g.vscode,
    version = 'v1.7.0',
    build = 'nix run .#build-plugin',
    opts = {
      keymap = {
        preset = 'super-tab',
        ['<Up>'] = { 'select_prev', 'fallback' },
        ['<Down>'] = { 'select_next', 'fallback' },
      },
      appearance = {
        nerd_font_variant = 'mono'
      },
      completion = {
        documentation = { auto_show = true },
        menu = {
          -- nvim-cmp style menu
          draw = {
            columns = {
              { "label",     "label_description", gap = 1 },
              { "kind_icon", "kind" }
            },
          }
        },
        ghost_text = { enabled = true },
        trigger = {
          -- Copilot向け
          show_on_backspace = true,
          show_on_insert = true,
        },
      },
      sources = {
        default = { 'copilot', 'lsp', 'path', 'snippets', 'buffer' },
        providers = {
          copilot = {
            name = "copilot",
            module = "blink-copilot",
            score_offset = 100,
            async = true,
          },
        },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
      signature = { enabled = true },
      cmdline = {
        keymap = { preset = 'inherit' },
        completion = { menu = { auto_show = true } },
      },
    },
    opts_extend = { "sources.default" },
    dependencies = {
      {
        'fang2hou/blink-copilot',
        dependencies = {
          {
            "zbirenbaum/copilot.lua",
            cmd = "Copilot",
            event = "InsertEnter",
            opts = {
              suggestion = { enabled = true },
              panel = { enabled = true },
              filetypes = {
                markdown = true,
                help = true,
              },
            },
          },
        },
      },
    },

  },
  {
    'hrsh7th/nvim-cmp',
    event = "InsertEnter",
    enabled = false,
    -- enabled = true and not vim.g.vscode,
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        formatting = {
          format = require('lspkind').cmp_format({ with_text = false }),
        },
        snippet = {
          expand = function(args)
            vim.fn['vsnip#anonymous'](args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered({
            zindex = 10,
          }),
          documentation = cmp.config.window.bordered({
            zindex = 50,
            side_padding = 10,
          }),
        },
        mapping = cmp.mapping.preset.insert({
          ['<CR>']    = cmp.mapping.confirm({ select = false }),
          ['<C-c>']   = cmp.mapping.abort(),
          -- NOTE: 挿入したくない場合は insert の代わりに select にする
          ['<Tab>']   = cmp.mapping.select_next_item({ behavior = "insert" }),
          ['<Down>']  = cmp.mapping.select_next_item({ behavior = "insert" }),
          ['<S-Tab>'] = cmp.mapping.select_prev_item({ behavior = "insert" }),
          ['<Up>']    = cmp.mapping.select_prev_item({ behavior = "insert" }),
        }),
        sources = cmp.config.sources({
          { name = 'copilot' },
          { name = 'nvim_lsp' },
          { name = 'nvim_lsp_signature_help' },
          { name = 'vsnip' },
          { name = 'buffer' },
          { name = 'rg',                     keyword_length = 3, },
          {
            name = 'path',
            options = {
              trailing_slash = false,
              label_trailing_slash = false,
            },
            trigger_characters = { '/', '.', '~' },
          },
        }),
        performance = {
          debounce = 0,
          throttle = 0,
        },
      })
      cmp.setup.cmdline({ '/', '?' }, {
        mapping = cmp.mapping.preset.cmdline({
          ['<C-f>'] = {
            c = cmp.mapping.complete_common_string(),
          }
        }),
        sources = {
          { name = 'buffer' },
          { name = 'nvim_lsp_document_symbol' },
        }
      })
      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'path' }
        }, {
          { name = 'cmdline' },
          { name = 'cmp-nvim-lua' },
        }),
        matching = { disallow_symbol_nonprefix_matching = false }
      })
    end,
    dependencies = {
      { 'hrsh7th/cmp-nvim-lsp' },
      { 'hrsh7th/cmp-nvim-lsp-document-symbol' },
      { 'hrsh7th/cmp-buffer' },
      { 'hrsh7th/cmp-path' },
      { 'hrsh7th/cmp-emoji' },
      { 'hrsh7th/cmp-cmdline' },
      { 'hrsh7th/cmp-vsnip' },
      { 'hrsh7th/cmp-nvim-lua' },
      { 'lukas-reineke/cmp-rg' },
      {
        'hrsh7th/vim-vsnip',
        config = function()
          vim.cmd [[
            let g:vsnip_snippet_dir = expand('~/.config/nvim/vsnip')
            imap <expr> <C-f> vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-f>'
            smap <expr> <C-f> vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-f>'
            xmap        <C-f> <Plug>(vsnip-cut-text)
          ]]
        end,
      },
      {
        'hrsh7th/vim-vsnip-integ',
        config = function()
          vim.cmd [[
            autocmd User PumCompleteDone call vsnip_integ#on_complete_done(g:pum#completed_item)
          ]]
        end,
      },
      {
        "zbirenbaum/copilot-cmp",
        config = function()
          require("copilot_cmp").setup({
            fix_pairs = false,
          })
        end
      },
      { 'onsails/lspkind.nvim' },
      {
        'zbirenbaum/copilot.lua',
        event = "VeryLazy",
        enabled = true and not vim.g.vscode,
        config = function()
          require('copilot').setup({
            panel = {
              enabled = false,
            },
            suggestion = {
              enabled = false,
            },
            filetypes = {
              yaml = true,
              markdown = true,
              gitcommit = true,
              gitrebase = true,
              hgcommit = true,
            },
          })
        end,
      },
    },
  },
  {
    'direnv/direnv.vim',
    enabled = not is_light_mode and not vim.g.vscode,
  },
  {
    'cshuaimin/ssr.nvim',
    enabled = not is_light_mode and not vim.g.vscode,
  },
  {
    'folke/zen-mode.nvim',
    enabled = not is_light_mode and not vim.g.vscode,
    opts = {
      plugins = {
        tmux = {
          enabled = true,
        }
      }
    },
  },
  {
    "GCBallesteros/jupytext.nvim",
    enabled = not is_light_mode and not vim.g.vscode,
    config = true,
  },
  {
    'mateuszwieloch/automkdir.nvim',
    enabled = not is_light_mode and not vim.g.vscode,
  },
  {
    'MattesGroeger/vim-bookmarks',
    enabled = not is_light_mode and not vim.g.vscode,
    event = "VeryLazy",
    keys = {
      { 'mm', "<Plug>BookmarkToggle", mode = { 'n' } },
      { 'mx', "<Plug>BookmarkClear",  mode = { 'n' } },
    },
    cmd = {
      'BookmarkShowAll'
    },
    config = function()
      vim.g.bookmark_save_per_working_dir = 1
      vim.g.bookmark_no_default_key_mappings = 1
      vim.g.bookmark_sign = ''
    end,
  },
  {
    "johmsalas/text-case.nvim",
    enabled = not is_light_mode and not vim.g.vscode,
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      require("textcase").setup({})
      require("telescope").load_extension("textcase")
    end,
    keys = {
      "ga",
      { "ga.", "<cmd>TextCaseOpenTelescope<CR>", mode = { "n", "v" }, desc = "Telescope" },
    },
  },
  {
    'soulis-1256/eagle.nvim',
    event = "VeryLazy",
    enabled = not is_light_mode and not vim.g.vscode,
    config = function()
      require("eagle").setup {}
    end,
  },
  {
    'dlvhdr/gh-addressed.nvim',
    enabled = not is_light_mode and not vim.g.vscode,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      'folke/trouble.nvim',
    },
    cmd = "GhReviewComments",
    keys = {
      { "<leader>gc", "<cmd>GhReviewComments<cr>", desc = "GitHub Review Comments" },
    },
  },
  {
    'pwntester/octo.nvim',
    enabled = true and not vim.g.vscode,
    event = "VeryLazy",
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
      'ibhagwan/fzf-lua',
      'nvim-tree/nvim-web-devicons',
    },
    config = function()
      require "octo".setup({
        picker = "fzf-lua",
        suppress_missing_scope = {
          projects_v2 = true,
        }
      })
    end
  },
  {
    'michaelb/sniprun',
    enabled = not is_light_mode,
    build = "sh install.sh",
    config = function()
      local sa = require('sniprun.api')
      local state = {}

      local function find_code_fence()
        local node = vim.treesitter.get_node()
        while node do
          if node:type() == 'code_fence_content' then
            return node
          end
          node = node:parent()
        end
      end

      local function remove_last_result()
        local bufnr = state.last_sniprun_bufnr
        local last_node = state.last_sniprun_node
        local l0, c0, _, _ = last_node:range()
        local mfence = vim.treesitter.get_node({ bufnr = bufnr, pos = { l0, c0 } })
        while mfence do
          if mfence:type() == 'fenced_code_block' then
            break
          end
          mfence = mfence:parent()
        end
        if mfence == nil then
          vim.notify("fenced_code_block not found")
          return
        end
        local mresult = mfence:next_sibling()
        if mresult == nil or mresult:type() ~= 'fenced_code_block' then
          return
        end
        local info = mresult:child(1)
        if info == nil or info:type() ~= 'info_string' then
          vim.notify("info_string not found")
          return
        end
        local lang = info:child(0)
        if lang == nil or lang:type() ~= 'language' then
          vim.notify("language not found")
          return
        end
        local a, b, c, d = lang:range()
        local val = vim.api.nvim_buf_get_text(bufnr, a, b, c, d, {})[1]
        if val ~= '[result]' then
          return
        end
        local d0, _, d1, _ = mresult:range()
        vim.api.nvim_buf_set_lines(bufnr, d0, d1, false, {})
      end

      sa.register_listener(function(d)
        local bufnr = state.last_sniprun_bufnr
        local node = state.last_sniprun_node
        if node == nil then
          return
        end
        remove_last_result()

        local _, c0, l1, _ = node:range()
        local indent = string.rep(' ', c0)
        local lines = { indent .. "```[result]" }
        for s in d.message:gmatch("[^\r\n]+") do
          -- indent to the same level as the code fence
          table.insert(lines, indent .. s)
        end
        table.insert(lines, indent .. "```")
        vim.api.nvim_buf_set_lines(bufnr, l1 + 1, l1 + 1, false, lines)
      end)

      vim.api.nvim_create_autocmd({ 'FileType' }, {
        pattern = 'markdown',
        callback = function(_)
          local opts = { noremap = true, silent = true, buffer = true }
          vim.keymap.set('n', '<Leader>q', function()
            vim.notify("Running sniprun")
            local bufnr = vim.api.nvim_get_current_buf()
            local node = find_code_fence()
            if node == nil then
              return
            end
            state.last_sniprun_bufnr = bufnr
            state.last_sniprun_node = node
            local l0, _, l1, _ = node:range()
            sa.run_range(l0 + 1, l1, 'bash', { display = { 'Api' } })
          end, opts)
          vim.keymap.set('n', '<Leader>c', function()
            vim.notify("Stopping sniprun")
            vim.cmd [[SnipReset]]
          end, opts)
        end
      })
    end,
    ft = { "markdown" }
  },
  {
    'nvim-pack/nvim-spectre',
    enabled = not is_light_mode and not vim.g.vscode,
    config = function()
      vim.keymap.set('n', '<leader>S', '<cmd>lua require("spectre").toggle()<CR>', {
        desc = "Toggle Spectre"
      })
      vim.keymap.set('n', '<leader>sw', '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', {
        desc = "Search current word"
      })
      vim.keymap.set('v', '<leader>sw', '<esc><cmd>lua require("spectre").open_visual()<CR>', {
        desc = "Search current word"
      })
      vim.keymap.set('n', '<leader>sp', '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>', {
        desc = "Search on current file"
      })
    end,
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
  },
  -- [Git]
  {
    'NeogitOrg/neogit',
    enabled = false,
    config = function()
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
        use_per_project_settings = false,
        ignored_settings = {},
        popup = {
          kind = "vsplit",
        },
        status = {
          recent_commit_count = 50,
        },
        integrations = {
          diffview = true,
          fzf_lua = true,
        },
        mappings = {
          status = {
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
    },
  },
  {
    'sindrets/diffview.nvim',
    event = "VeryLazy",
    enabled = not is_light_mode and not vim.g.vscode,
    config = function()
      require("diffview").setup {
        view = {
          merge_tool = {
            layout = "diff4_mixed",
            disable_diagnostics = true,
            winbar_info = true,
          },
        },
        keymaps = {
          file_panel = {
            { 'n', 'q', function() vim.cmd("tabclose") end, { desc = "Close" } },
          },
          file_history_panel = {
            { 'n', 'q', function() vim.cmd("DiffviewClose") end, { desc = "Close" } },
          },
        },
      }
    end,
    keys = {
      -- --no-mergesのようなオプションを追加したい場合があるので<CR>で閉じないでおく
      { "<leader>dh", ":DiffviewFileHistory %",   mode = { "n" },      desc = "DiffviewFileHistory" },
      { "<leader>dh", ":DiffviewFileHistory<CR>", mode = { "v" },      desc = "DiffviewFileHistory" },
      { "<leader>do", ":DiffviewOpen",            mode = { "n", "v" }, desc = "DiffviewOpen" },
    },
  },
  {
    'tpope/vim-fugitive',
    enabled = true and not vim.g.vscode,
  },
  {
    'lambdalisue/gina.vim',
    enabled = true and not vim.g.vscode,
    config = function()
      vim.cmd [[
        autocmd FileType gina-log   nmap F <Plug>(gina-show-commit-vsplit)zv
        autocmd FileType gina-blame nmap F <Plug>(gina-show-commit-tab)zv
        command Gblame Gina blame
      ]]
    end
  },
  {
    'lewis6991/gitsigns.nvim',
    enabled = not is_light_mode and not vim.g.vscode,
    config = function()
      require('gitsigns').setup({
        signcolumn = true,
        numhl      = true,
      })
    end,
  },
  -- [LSP]
  {
    'neovim/nvim-lspconfig',
    event = "VeryLazy",
    enabled = not is_light_mode and not vim.g.vscode,
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
        local format = function()
          require 'conform'.format({
            timeout_ms = 10000,
            lsp_fallback = true,
          })
        end
        local trouble = function(mode, focus)
          return function()
            if focus then
              require('trouble').focus(mode)
            else
              require('trouble').toggle(mode)
            end
          end
        end
        bmap('n', '<C-h>', require("noice.lsp").hover)
        bmap('n', '<C-j>', function() require('trouble').first("definitions") end)
        bmap('n', '<C-k>', '<cmd>Lspsaga peek_definition<CR>')
        bmap('n', '<C-l>a', require("actions-preview").code_actions)
        bmap('n', '<C-.>', require("actions-preview").code_actions)
        bmap('n', '<C-l>f', format)
        bmap('v', '<C-l>f', format)
        bmap('n', '<C-l>q', trouble('diagnostics', false))
        bmap('n', '<C-l>o', trouble('symbols', false))
        bmap('n', '<C-l>i', trouble('lsp_implementations', true))
        bmap('n', '<C-l>r', trouble('lsp_references', true))
        bmap('n', '<C-l>h', vim.lsp.buf.signature_help)
        bmap('n', '<C-l>R', vim.lsp.buf.rename)
        bmap('n', '<C-l>l', vim.lsp.codelens.run)
        bmap('n', '<C-l>k', function()
          local opts = {
            severity_sort = true,
            source = true,
            scope = 'cursor',
            border = 'rounded',
            prefix = ' ',
            focusable = true,
          }
          vim.diagnostic.open_float(nil, opts)
        end)
        vim.api.nvim_create_autocmd("CursorHold", {
          buffer = bufnr,
          callback = function()
            local opts = {
              severity_sort = true,
              source = true,
              scope = 'cursor',
              border = 'rounded',
              prefix = ' ',
              focusable = false, -- important
            }
            vim.diagnostic.open_float(nil, opts)
          end
        })
        -- require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
        -- 重いので一旦無効化
        client.server_capabilities.codeLensProvider = false
        client.server_capabilities.documentHighlightProvider = false
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
        if client.name == "ts_ls" or client.name == "jsonls" then
          client.server_capabilities.documentFormattingProvider = false
        end
      end

      -- [[capabilities]]
      vim.g.lsp_default_capabilities = require('blink.cmp').get_lsp_capabilities({
        textDocumtent = {
          completion = {
            completionItem = {
              snippetSupport = true,
            },
          },
        },
      })

      -- [[set default]]
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          local bufnr = ev.buf
          vim.g.lsp_default_on_attach(client, bufnr)
        end
      })
      vim.lsp.config('*', {
        capabilities = vim.g.lsp_default_capabilities,
      })

      local enabled_servers = {}
      local function enable_lsp(name, opts)
        if opts then
          vim.lsp.config(name, opts)
        end
        if enabled_servers[name] then
          return
        end
        enabled_servers[name] = true
        vim.lsp.enable(name)
      end

      -- [Per server]
      -- [[hls]]
      enable_lsp('hls', {
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
        filetypes = { 'haskell', 'lhaskell', 'cabal' },
      })

      -- [[denols]]
      enable_lsp('denols', {
        root_dir = function(_, on_dir)
          local dir = vim.fs.root(0, 'deno.json')
          if dir then
            on_dir(dir)
          end
        end,
        init_options = {
          lint = true,
        },
        single_file_support = false,
      })

      -- [[ts_ls]]
      -- thx! https://tech-blog.cloud-config.jp/2024-05-22-write-vue-with-neovim
      -- > The contents of the package directory is not a stable interface and its structure may change without prior notice
      -- らしいが、これよりいい方法があるか不明
      local vue_typescript_plugin =
          vim.env.MASON ..
          "/packages/vue-language-server/node_modules/@vue/language-server/node_modules/@vue/typescript-plugin"
      enable_lsp('ts_ls', {
        root_dir = function(_, on_dir)
          local dir = vim.fs.root(0, 'package.json')
          if dir then
            on_dir(dir)
          end
        end,
        init_options = {
          lint = true,
          plugins = {
            {
              name = "@vue/typescript-plugin",
              location = vue_typescript_plugin,
              languages = { "vue", },
            },
          },
        },
        single_file_support = false,
        filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact", "vue" },
      })
      enable_lsp('vue_ls', {
        root_markers = { "vue.config.js", "nuxt.config.ts", "src/App.vue" },
        init_options = {
          vue = {
            hybridMode = false,
          },
        },
        filetypes = { "javascript", "typescript", "typescriptreact", "javascriptreact", "vue" },
      })

      -- [[lua_ls]]
      enable_lsp('lua_ls')
      -- [[nil_ls]]
      enable_lsp('nil_ls', {
        settings = {
          ["nil"] = {
            formatting = {
              command = { "nixpkgs-fmt" }
            },
          },
        },
      })
      -- [[others]]
      enable_lsp('bashls')
      enable_lsp('eslint')
      enable_lsp('biome')
      enable_lsp('tailwindcss', {
        filetypes = {
          "html",
          "css",
          "postcss",
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "vue",
        },
      })
      enable_lsp('dhall_lsp_server')
      -- enable_lsp('jsonls')
      enable_lsp('rust_analyzer', {
        settings = {
          ['rust-analyzer'] = {
            check = {
              command = "clippy"
            },
            files = {
              excludeDirs = { ".direnv" },
            },
          }
        }
      })
      enable_lsp('gopls')
      enable_lsp('graphql')
      enable_lsp('pyright')
      -- enable_lsp('yamlls')
      enable_lsp('terraformls')
      enable_lsp('tflint')
      enable_lsp('dockerls')
      enable_lsp('sqlls')
      enable_lsp('gradle_ls')
      enable_lsp('unison')
    end,
    dependencies = {
      {
        'WhoIsSethDaniel/mason-tool-installer.nvim',
        config = function()
          require('mason-tool-installer').setup {
            ensure_installed = {
              -- [LSP]
              "bash-language-server",
              "dhall-lsp",
              "diagnostic-languageserver",
              "dockerfile-language-server",
              "eslint-lsp",
              "gradle-language-server",
              "graphql-language-service-cli",
              "json-lsp",
              "lua-language-server",
              "pyright",
              "terraform-ls",
              "tflint",
              "typescript-language-server",
              "tailwindcss-language-server",
              "yaml-language-server",
              -- [null-ls]
              "actionlint",
              "black",
              "hadolint",
              "prettier",
              "yamllint",
            },
            auto_update = false,
            run_on_start = true,
            start_delay = 3000, -- 3 second delay
          }
        end,
        dependencies = {
          {
            'williamboman/mason-lspconfig.nvim',
            version = 'v1.11.0',
            config = true,
          },
          {
            'williamboman/mason.nvim',
            version = 'v1.11.0',
            opts = {
              -- registries = {
              --   -- 'github:Hogeyama/jdtls-mason-registry',
              --   'github:nvim-java/mason-registry',
              --   'github:mason-org/mason-registry',
              -- },
            }
          },
        },
      },
      {
        'stevearc/conform.nvim',
        event = "VeryLazy",
        config = function()
          vim.g.format_on_save_enabled = true
          require("conform").setup({
            formatters_by_ft = {
              vue = { "prettier" },
              typescript = { "prettier" },
              typescriptreact = { "prettier" },
              java = { "spotless" },
            },
            format_on_save = function()
              if vim.b.format_on_save_enabled ~= nil then
                return vim.b.format_on_save_enabled and {
                  timeout_ms = 500,
                  lsp_fallback = true,
                } or nil
              else
                return vim.g.format_on_save_enabled and {
                  timeout_ms = 500,
                  lsp_fallback = true,
                } or nil
              end
            end,
          })
          vim.api.nvim_create_user_command('FormatToggle', function()
            vim.g.format_on_save_enabled = not vim.g.format_on_save_enabled
          end, {})
          vim.api.nvim_create_user_command('FormatToggleBuf', function()
            if vim.b.format_on_save_enabled == nil then
              vim.b.format_on_save_enabled = false
            else
              vim.b.format_on_save_enabled = not vim.b.format_on_save_enabled
            end
          end, {})
          -- Disable on some filetypes
          vim.api.nvim_create_autocmd({ 'FileType' }, {
            pattern = { 'java', 'markdown' },
            callback = function()
              vim.b.format_on_save_enabled = false
            end
          })
        end,
      },
      {
        'nvimtools/none-ls.nvim',
        enabled = not is_light_mode and not vim.g.vscode,
        config = function()
          local null_ls = require("null-ls")
          local helpers = require("null-ls.helpers")
          local gradlew_spotless = helpers.make_builtin({
            name = "spotless",
            method = null_ls.methods.FORMATTING,
            filetypes = { "java" },
            generator_opts = {
              command = "./gradlew",
              args = {
                "--console=plain",
                "--quiet",
                '--no-configuration-cache',
                "spotlessApply",
                "-PspotlessIdeHook=$FILENAME",
                '-PspotlessIdeHookUseStdOut',
              },
              timeout = 3000,
            },
            factory = helpers.formatter_factory,
          })
          null_ls.setup {
            log_level = "trace",
            on_attach = vim.g.lsp_default_on_attach,
            default_timeout = 50000,
            root_dir = function()
              return nil
            end,
            sources = {
              -- [diagnostics]
              null_ls.builtins.diagnostics.actionlint,
              null_ls.builtins.diagnostics.hadolint,
              -- null_ls.builtins.diagnostics.yamllint,
              -- [formatter]
              null_ls.builtins.formatting.black,
              null_ls.builtins.formatting.just,
              null_ls.builtins.formatting.prettier.with({
                condition = function(utils)
                  return not utils.root_has_file({ "biome.json", "biome.jsonc" })
                end,
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
                  "vue",
                },
              }),
              null_ls.builtins.formatting.markdownlint,
              gradlew_spotless,
              -- [code_action]
              null_ls.builtins.code_actions.gitrebase,
            }
          }
        end,
        dependencies = { "plenary.nvim" },
      },
      { 'aznhe21/actions-preview.nvim' },
      { "artemave/workspace-diagnostics.nvim" },
      {
        "folke/neoconf.nvim",
        config = function()
          require("neoconf").setup({})
        end,
      },
    },
  },
  {
    'folke/trouble.nvim',
    enabled = not is_light_mode and not vim.g.vscode,
    config = function()
      require('trouble').setup {
        auto_refresh = false,
        modes = {
          definitions = {
            mode = 'lsp_definitions',
            filter = function(items)
              return vim.tbl_filter(function(item)
                -- volarとts_ls with vue/typescript-pluginの出すitemが重複するので
                -- volarの方を削除する
                return item.item.client ~= 'volar'
              end, items)
            end,
          },
        }
      }
    end,
  },
  {
    'nvimdev/lspsaga.nvim',
    event = "VeryLazy",
    enabled = not is_light_mode and not vim.g.vscode,
    config = function()
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
          enable = true,
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
  {
    'j-hui/fidget.nvim',
    enabled = not is_light_mode and not vim.g.vscode,
    tag = 'legacy',
    config = function()
      require 'fidget'.setup {}
    end
  },
  -- [DAP]
  {
    'mfussenegger/nvim-dap',
    enabled = not is_light_mode and not vim.g.vscode,
    config = function()
      vim.cmd [[
      autocmd FileType dap-repl lua require('dap.ext.autocompl').attach()
    ]]
    end
  },
  {
    'theHamsta/nvim-dap-virtual-text',
    enabled = not is_light_mode and not vim.g.vscode,
    dependencies = { 'nvim-dap' },
    config = function()
      require("nvim-dap-virtual-text").setup({})
    end
  },
  {
    "rcarriga/nvim-dap-ui",
    enabled = not is_light_mode and not vim.g.vscode,
    dependencies = {
      'nvim-dap',
      'nvim-neotest/nvim-nio'
    },
    config = function()
      require("dapui").setup()
    end
  },
  -- [Filetype]
  -- [[Haskell]]
  {
    'neovimhaskell/haskell-vim',
    enabled = not is_light_mode and not vim.g.vscode,
  },
  -- [[dhall]]
  {
    'vmchale/dhall-vim',
    enabled = not is_light_mode and not vim.g.vscode,
  },
  -- [[Rust]]
  {
    'rust-lang/rust.vim',
    enabled = not is_light_mode and not vim.g.vscode,
  },
  -- [[GraphQL]]
  {
    'jparise/vim-graphql',
    enabled = not is_light_mode and not vim.g.vscode,
  },
  -- [[nix]]
  {
    'LnL7/vim-nix',
    enabled = not is_light_mode and not vim.g.vscode,
  },
  -- [[Markdown]]
  {
    'preservim/vim-markdown',
    enabled = false,
    config = function()
      vim.g.vim_markdown_folding_disabled = 1
      vim.g.vim_markdown_new_list_item_indent = 2
      vim.api.nvim_create_autocmd({ 'FileType' }, {
        pattern = 'markdown',
        command = "set nowrap",
      })
    end
  },
  {
    "iamcco/markdown-preview.nvim",
    enabled = not is_light_mode and not vim.g.vscode,
    build = function() vim.fn["mkdp#util#install"]() end,
    config = function()
      vim.g.mkdp_filetypes = { "markdown" }
      vim.g.mkdp_preview_options = {
        disable_sync_scroll = true,
      }
    end,
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    enabled = not is_light_mode and not vim.g.vscode,
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons'
    },
    config = function()
      require('render-markdown').setup({
        completions = { blink = { enabled = true } },
      })
      vim.cmd [[RenderMarkdown disable]]
    end,
    keys = {
      {
        '<leader>mr',
        function() require('render-markdown').toggle() end,
        mode = { 'n' },
        desc = "Toggle Render Markdown",
      },
    },

  },
  {
    'vim-voom/VOoM',
    enabled = not is_light_mode and not vim.g.vscode,
  },
  {
    'epwalsh/obsidian.nvim',
    enabled = not is_light_mode and not vim.g.vscode,
    version = "*",
    ft = "markdown",
    dependencies = {
      "plenary.nvim",
      "nvim-treesitter",
      "fzf-lua",
    },
    opts = {
      workspaces = {
        {
          name = "notes",
          path = "~/notes",
        },
      },
      daily_notes = {
        folder = "dailies",
        date_format = "%Y-%m-%d",
      },
      completion = {
        nvim_cmp = false,
        min_chars = 2,
      },
      mappings = {
        ["gf"] = {
          action = function()
            return require("obsidian").util.gf_passthrough()
          end,
          opts = { noremap = false, expr = true, buffer = true },
        },
        ["<leader>ch"] = {
          action = function()
            return require("obsidian").util.toggle_checkbox()
          end,
          opts = { buffer = true },
        },
        ["<cr>"] = {
          action = function()
            return require("obsidian").util.smart_action()
          end,
          opts = { buffer = true, expr = true },
        }
      },
      picker = {
        name = "fzf-lua",
        mappings = {
          new = "<C-x>",
          insert_link = "<C-l>",
        },
      },
      -- %Y%m%dT%H%M%S-XXXX
      note_id_func = function(title)
        local prefix = os.date("%Y%m%dT%H%M%S")
        local random = ""
        for _ = 1, 4 do
          random = random .. string.char(math.random(65, 90))
        end
        if title == nil then
          return prefix .. "_" .. random
        else
          local suffix = string.gsub(title, " ", "_")
          return prefix .. "_" .. random .. "-" .. suffix
        end
      end,
      ---@param spec { id: string, dir: {filename: string}, title: string|? }
      ---@return string The full path to the new note.
      note_path_func = function(spec)
        local no_id_dirs = {
          "nikki",
          "shumi",
          "books",
        }
        local path = (function()
          for _, dir in ipairs(no_id_dirs) do
            if string.match(spec.dir.filename, dir) ~= nil then
              return spec.dir / spec.title
            end
          end
          return spec.dir / spec.id
        end)()
        return path:with_suffix(".md")
      end,
      follow_url_func = function(url)
        vim.fn.jobstart({ "xdg-open", url })
      end,
      ui = {
        enable = false,
        checkboxes = {
          [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
          ["x"] = { char = "", hl_group = "ObsidianDone" },
        },
      },
    },
    keys = {
      { '<C-t>',      "<Cmd>ObsidianToday<CR>",       mode = { 'n' } },
      { '<leader>ob', "<Cmd>ObsidianBacklinks<CR>",   mode = { 'n' } },
      { '<leader>oq', "<Cmd>ObsidianQuickSwitch<CR>", mode = { 'n' } },
    },
  },
  {
    "oflisback/obsidian-bridge.nvim",
    enabled = not is_light_mode and not vim.g.vscode,
    lazy = true,
    ft = "markdown",
    config = function()
      if vim.env.OBSIDIAN_REST_API_KEY ~= nil then
        require("obsidian-bridge").setup()
      end
    end,
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
  },
  -- [[terraform]]
  {
    'hashivim/vim-terraform',
    enabled = not is_light_mode and not vim.g.vscode,
  },
  -- [[Textile]]
  {
    's3rvac/vim-syntax-redminewiki',
    enabled = not is_light_mode and not vim.g.vscode,
    config = function()
      vim.cmd [[
        autocmd BufEnter *.redmine set ft=redminewiki
      ]]
    end
  },
  -- [[just]]
  {
    "NoahTheDuke/vim-just",
    enabled = not is_light_mode and not vim.g.vscode,
    ft = { "just" },
  },
  -- [[vue]]
  {
    'posva/vim-vue',
    enabled = not is_light_mode and not vim.g.vscode,
  },
  {
    "mhanberg/output-panel.nvim",
    version = "*",
    event = "VeryLazy",
    config = function()
      require("output_panel").setup({
        max_buffer_size = 5000 -- default
      })
    end,
    cmd = { "OutputPanel" },
    keys = {
      {
        "<leader>o",
        vim.cmd.OutputPanel,
        mode = "n",
        desc = "Toggle the output panel",
      },
    }
  },
  {
    'norcalli/nvim-colorizer.lua',
    config = function()
      require 'colorizer'.setup()
    end,
  }
}
