local is_light_mode = vim.env.NVIM_LIGHT_MODE == "1"
local completion_engine = "cmp"
-- local completion_engine = "ddc"
-- if is_light_mode then completion_engine = "cmp" end

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
        vim.api.nvim_win_set_option(win, "winblend", 30)
        vim.api.nvim_win_set_config(win, { zindex = 100 })
      end
    },
  },
  {
    'gbprod/yanky.nvim',
    enabled = true,
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
  {
    'ibhagwan/fzf-lua',
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
    enabled = not is_light_mode,
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
      { 'gbprod/yanky.nvim' },
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make'
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
    },
  },
  {
    'glacambre/firenvim',
    enabled = not is_light_mode,
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
  {
    'miversen33/netman.nvim',
    config = true,
  },
  {
    'echasnovski/mini.nvim',
    init = function()
      require('mini.ai').setup()
      require('mini.align').setup({
        mappings = {
          start = '',
          start_with_preview = 'ga',
        },
      })
      require('mini.pairs').setup()
      require('mini.trailspace').setup()
      require('mini.sessions').setup()
      require('mini.starter').setup({
        items = {
          require('mini.starter').sections.sessions(5, true)
        },
        footer = '',
      })
      require('mini.bracketed').setup()
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
    end,
  },
  {
    -- See copilot-cmp
    'zbirenbaum/copilot.lua',
    init = function()
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
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim",
    },
    config = function()
      local anthropic = require("codecompanion.adapters").use("anthropic", {
        env = {
          api_key = "cmd:pass anthropic_api_key",
        },
      })
      require("codecompanion").setup({
        adapters = {
          chat = anthropic,
          inline = anthropic,
        },
        display = {
          action_palette = {
            width = 95,
            height = 10,
          },
          chat = {                   -- Options for the chat strategy
            type = "buffer",         -- float|buffer
            show_settings = true,    -- Show the model settings in the chat buffer?
            show_token_count = true, -- Show the token count for the current chat in the buffer?
            buf_options = {          -- Buffer options for the chat buffer
              buflisted = false,
            },
            float_options = { -- Float window options if the type is "float"
              border = "single",
              buflisted = false,
              max_height = 0,
              max_width = 0,
              padding = 1,
            },
            win_options = { -- Window options for the chat buffer
              cursorcolumn = false,
              cursorline = false,
              foldcolumn = "0",
              linebreak = true,
              list = false,
              signcolumn = "no",
              spell = false,
              wrap = true,
            },
          },
        },
        keymaps = {
          ["<C-s>"] = "keymaps.save",       -- Save the chat buffer and trigger the API
          ["<C-c>"] = "keymaps.close",      -- Close the chat buffer
          ["q"] = "keymaps.cancel_request", -- Cancel the currently streaming request
          ["gc"] = "keymaps.clear",         -- Clear the contents of the chat
          ["ga"] = "keymaps.codeblock",     -- Insert a codeblock into the chat
          ["gs"] = "keymaps.save_chat",     -- Save the current chat
          ["]"] = "keymaps.next",           -- Move to the next header in the chat
          ["["] = "keymaps.previous",       -- Move to the previous header in the chat
        },
        log_level = "ERROR",                -- TRACE|DEBUG|ERROR
        send_code = false,                  -- Send code context to the generative AI service? Disable to prevent leaking code outside of Neovim
        silence_notifications = false,      -- Silence notifications for actions like saving saving chats?
        use_default_actions = false,        -- Use the default actions in the action palette?
      })
    end,
  },
  {
    "folke/edgy.nvim",
    enabled = false,
    event = "VeryLazy",
    init = function()
      vim.opt.laststatus = 3
      vim.opt.splitkeep = "screen"
    end,
    opts = {
      right = {
        { ft = "codecompanion", title = "Code Companion Chat", size = { width = 1 } },
      }
    }
  },
  {
    'nvim-treesitter/nvim-treesitter',
    init = function()
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
      { 'RRethy/nvim-treesitter-textsubjects' },
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
    enabled = not is_light_mode,
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
          { 'L', 'zO' },
          { 'H', 'zC' },
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
          { 's',       ':Gitsigns stage_hunk<CR>',                        { silent = true } },
          { 'u',       gitsigns.undo_stage_hunk },
          { 'S',       gitsigns.stage_buffer },
          { 'p',       gitsigns.preview_hunk },
          { 'd',       gitsigns.toggle_deleted,                           { nowait = true } },
          { 'b',       gitsigns.blame_line },
          { 'B',       function() gitsigns.blame_line { full = true } end },
          { '<Enter>', '<cmd>Neogit<CR>',                                 { exit = true } },
          { '<Esc>',   nil,                                               { exit = true, nowait = true } },
        }
      })
    end,
    dependencies = {
      { 'gitsigns.nvim' },
      { 'neogit' },
    },
  },
  {
    'cocopon/iceberg.vim',
  },
  {
    'catppuccin/nvim',
    name = "catppuccin",
    init = function()
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
          cmp = true,
          gitsigns = true,
          nvimtree = true,
          treesitter = true,
          notify = true,
          mini = {
            enabled = true,
            indentscope_color = "",
          },
          dropbar = {
            enabled = true,
            color_mode = false,
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
    init = function()
      vim.cmd [[
        let g:EditorConfig_max_line_indicator = 'exceeding'
      ]]
    end,
  },
  {
    'numToStr/FTerm.nvim',
    enabled = true,
    event = "VeryLazy",
    config = function()
      local fterm = require 'FTerm'
      local shells = {}
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
          border = "rounded",
          dimensions = {
            height = 0.9,
            width = 0.9
          },
        }
      end
      local fzfw = function()
        return {
          cmd = "fzfw",
          border = "rounded",
          dimensions = {
            height = 0.9,
            width = 0.9
          },
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
    'voldikss/vim-floaterm',
    enabled = false,
    init = function()
      vim.g.floaterm_width = 0.9
      vim.g.floaterm_height = 0.9
      vim.keymap.set("n", "<F6>", "<Cmd>FloatermToggle shell6<CR>")
      vim.keymap.set("t", "<F6>", "<C-\\><C-n><Cmd>FloatermToggle shell6<CR>")
      vim.keymap.set("n", "<F7>", "<Cmd>FloatermToggle shell7<CR>")
      vim.keymap.set("t", "<F7>", "<C-\\><C-n><Cmd>FloatermToggle shell7<CR>")
      vim.keymap.set("n", "<F8>", "<Cmd>ToggleFloatermFzf<CR>")
      vim.keymap.set("t", "<F8>", "<C-\\><C-n><Cmd>ToggleFloatermFzf<CR>")
      vim.keymap.set("n", "<F9>", "<Cmd>FloatermToggle shell9<CR>")
      vim.keymap.set("t", "<F9>", "<C-\\><C-n><Cmd>FloatermToggle shell9<CR>")
      vim.api.nvim_create_user_command('ToggleFloatermFzf', function()
        if vim.g.floaterm_fzf_exists == 1 then
          vim.cmd [[FloatermToggle fzf]]
        else
          local old_shell = vim.g.floaterm_shell
          vim.g.floaterm_shell = 'fzfw'
          vim.cmd [[FloatermNew  --name=fzf]]
          vim.g.floaterm_shell = old_shell
          vim.g.floaterm_fzf_exists = 1
        end
      end, {})
      -- nvim_treesitter#foldexpr()が有効になっているとめちゃくちゃ重くなる
      -- なぜかnofoldenableでも重いので、foldmethod=manualにする
      vim.api.nvim_create_autocmd({ 'FileType' }, {
        pattern = 'floaterm',
        command = "setlocal foldmethod=manual nonumber norelativenumber",
      })
    end
  },
  {
    'lukas-reineke/indent-blankline.nvim',
    enabled = not is_light_mode and not vim.g.vscode,
    main = "ibl",
    opts = {
      indent = {
        char = "▏",
      },
      scope = {
        enabled = false,
      },
    },
  },
  {
    'smoka7/hop.nvim',
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
  {
    'chrisgrieser/nvim-spider',
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
  {
    'numToStr/Comment.nvim',
    dependencies = { 'JoosepAlviste/nvim-ts-context-commentstring' },
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
        pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
      })
    end
  },
  {
    'machakann/vim-sandwich',
    init = function()
      vim.cmd [[
        vmap s <Plug>(operator-sandwich-add)
      ]]
    end
  },
  {
    'Bekaboo/dropbar.nvim',
    enabled = not is_light_mode,
  },
  {
    "sontungexpt/sttusline",
    branch = "table_version",
    enabled = not is_light_mode and not vim.g.vscode,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    event = { "BufEnter" },
    config = function(_, _)
      require("sttusline").setup {
        statusline_color = "StatusLine",
        disabled = {
          filetypes = {},
          buftypes = { "terminal" },
        },
        components = {
          "mode",
          "filename",
          "git-branch",
          "git-diff",
          "%=",
          "diagnostics",
          "lsps-formatters",
          "copilot",
          "indent",
          "encoding",
          {
            "pos-cursor",
            {
              update = function()
                -- Use display offset instead of byte offset
                local cursor = vim.api.nvim_win_get_cursor(0)
                local line = vim.api.nvim_get_current_line()
                local display_offset = vim.fn.strdisplaywidth(line:sub(1, cursor[2] + 1))
                return cursor[1] .. ":" .. display_offset
              end,
            }
          },
        },
      }
    end,
  },
  {
    'nanozuki/tabby.nvim',
    enabled = not is_light_mode,
    init = function()
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
  { 'AndrewRadev/linediff.vim' },
  { 'machakann/vim-highlightedyank' },
  {
    'glidenote/memolist.vim',
    enabled = not is_light_mode,
    init = function()
      vim.g.memolist_path = '~/.memo'
      vim.g.memolist_template_dir_path = '~/.memo/template'
      vim.cmd [[
        command! MemoToday MemoNewWithMeta 'note', 'daily', 'daily'
      ]]
    end
  },
  { 'kana/vim-metarw' },
  {
    'mattn/webapi-vim',
    enabled = not is_light_mode,
  },
  {
    'rhysd/clever-f.vim',
    init = function()
      vim.cmd [[
      let g:clever_f_smart_case = 1
    ]]
    end
  },
  { 'haya14busa/vim-asterisk' },
  { 'Shougo/deol.nvim' },
  {
    'dbridges/vim-markdown-runner',
    enabled = not is_light_mode,
    init = function()
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
    enabled = not is_light_mode and not vim.g.vscode,
    dependencies = { "nui.nvim", "nvim-notify", "nvim-cmp" },
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
          backend = "cmp",
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
        routes = {
          {
            -- nlspsettings
            filter = {
              find = "Success to update the settings.",
              event = "notify",
            },
            view = "mini",
          },
        },
      }
    end,
  },
  {
    'nvim-neo-tree/neo-tree.nvim',
    enabled = not is_light_mode,
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
  {
    'klen/nvim-config-local',
    init = function()
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
  { 'jrudess/vim-foldtext' },
  {
    'kevinhwang91/nvim-ufo',
    dependencies = { 'kevinhwang91/promise-async' },
    event = "VeryLazy",
    config = function()
      vim.o.foldcolumn = '0'
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
      vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
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
    'Shougo/ddc.vim',
    enabled = completion_engine == "ddc",
    dependencies = {
      { 'vim-denops/denops.vim', },
      { 'Shougo/ddc-ui-pum', },
      {
        'Shougo/pum.vim',
        config = function()
          vim.fn["pum#set_option"]({
            auto_select = false,
            border = "rounded",
            scrollbar_char = "┃",
            direction = "below",
            max_height = 20,
          })
        end,
      },
      -- sources
      { 'Shougo/ddc-source-rg', },
      { 'Shougo/ddc-source-lsp', },
      { 'Shougo/ddc-source-copilot', },
      { 'Shougo/ddc-source-cmdline', },
      { 'Shougo/ddc-source-cmdline-history', },
      { 'Shougo/ddc-source-shell-native', },
      { 'Shougo/ddc-source-nvim-lua', },
      { 'uga-rosa/ddc-source-buffer', },
      { 'uga-rosa/ddc-source-vsnip', },
      { 'LumaKernel/ddc-source-file', },
      { 'tani/ddc-path', },
      -- matchers, rankers
      { 'Shougo/ddc-matcher_head' },
      { 'tani/ddc-fuzzy', },
      -- other dependencies
      { 'hrsh7th/nvim-insx' },
      {
        'uga-rosa/ddc-source-lsp-setup',
        config = function()
          require("ddc_source_lsp_setup").setup({
            override_capabilities = false, -- 手動でやってるので
            respect_trigger = true,
          })
        end,
      },
      {
        'hrsh7th/vim-vsnip',
        init = function()
          vim.cmd [[
            let g:vsnip_snippet_dir = stdpath('config') . '/vsnip'
            imap <expr> <C-f> vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-f>'
            smap <expr> <C-f> vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-f>'
            xmap        <C-f> <Plug>(vsnip-cut-text)
          ]]
        end,
      },
      {
        'github/copilot.vim',
        config = function()
          vim.g.copilot_no_tab_map = true
        end,
      },
    },
    config = function()
      vim.fn["ddc#custom#patch_global"]({
        ui = 'pum',
        sources = {
          'copilot',
          'lsp',
          'buffer',
          'rg',
          'file',
        },
        cmdlineSources = {
          [':'] = {
            'nvim-lua',
            'cmdline',
            'cmdline-history',
            'path',
            'file',
          },
          ['/'] = {
            'buffer',
          },
          ['?'] = {
            'buffer',
          },
        },
        autoCompleteEvents = {
          "InsertEnter",
          "TextChangedI",
          "TextChangedP",
          "TextChangedT",
          "CmdlineEnter",
          "CmdlineChanged",
        },
        backspaceCompletion = true,
        sourceOptions = {
          _ = {
            minAutoCompleteLength = 1,
            keywordPattern = [[(?:-?\d+(?:\.\d+)?|[a-zA-Z_][\w\.]*(?:-\w*)*)]],
            matchers = { "matcher_fuzzy", },
            sorters = { "sorter_fuzzy", },
            converters = { "converter_fuzzy", },
            ignoreCase = false,
          },
          copilot = {
            mark = ' ',
            matchers = {},
            minAutoCompleteLength = 0,
            forceCompletionPattern = [[.+]],
          },
          buffer = {
            mark = "📃"
          },
          rg = {
            mark = "🔍",
            minAutoCompleteLength = 4,
          },
          file = {
            mark = "📁",
            isVolatile = true,
            forceCompletionPattern = [[\S?/\S*|~/\S*]],
          },
          lsp = {
            mark = "🗿",
            keywordPattern = [[\k+]],
            sorters = { 'sorter_lsp-kind' },
          },
          path = {
            mark = '🛣️',
          },
          lua = {
            mark = '',
          },
        },
        sourceParams = {
          lsp = {
            snippetEngine = vim.fn["denops#callback#register"](function(body)
              vim.fn["vsnip#anonymous"](body)
            end),
            enableResolveItem = true,
            enableAdditionalTextEdit = true,
            confirmBehavior = 'replace',
          },
          path = {
            cmd = { 'fd', '--max-depth', 6 },
            absolute = false,
          },
        },
        filterParams = {
          ['matcher_fuzzy'] = {
            splitMode = 'word',
          },
        },
      })
      vim.fn["ddc#custom#patch_filetype"]({ 'zsh', 'floaterm', 'deol' }, {
        specialBufferCompletion = true,
        sources = {
          'shell-native',
          'copilot',
        },
        sourceOptions = {
          _ = {
            keywordPattern = "[0-9a-zA-Z_./#:-]*",
          },
          copilot = {
            mark = ' ',
            matchers = {},
            minAutoCompleteLength = 0,
          },
          ['shell-native'] = {
            mark = '🐚',
          },
        },
        sourceParams = {
          ['shell-native'] = {
            shell = 'zsh',
          },
        },
      })
      vim.fn["ddc#enable"]()

      -- mapping
      local map = function(mode, key, on_pum_visible, on_pum_invisible)
        vim.keymap.set(mode, key, function()
          local info = vim.fn["pum#complete_info"]()
          if info.pum_visible then
            on_pum_visible(info)
          else
            if on_pum_invisible then
              return on_pum_invisible(info)
            else
              return key
            end
          end
        end, { expr = true, silent = true })
      end
      -- insert mode
      map('i', '<CR>', function(info)
        if info.selected >= 0 then
          vim.fn["pum#map#confirm"]()
        else
          vim.fn["pum#map#cancel"]()
          vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes('<CR>', true, false, true),
            'n',
            false)
        end
      end)
      map('i', '<Tab>', function() vim.fn["pum#map#select_relative"](1) end)
      map('i', '<Down>', function() vim.fn["pum#map#select_relative"](1) end)
      map('i', '<S-Tab>', function() vim.fn["pum#map#select_relative"](-1) end)
      map('i', '<Up>', function() vim.fn["pum#map#select_relative"](-1) end)
      map('i', '<C-c>', function() vim.fn["pum#map#cancel"]() end)

      -- cmdline mode
      vim.keymap.set('n', ":", "<Cmd>call ddc#enable_cmdline_completion()<CR>:",
        { noremap = true })
      vim.keymap.set('n', "/", "<Cmd>call ddc#enable_cmdline_completion()<CR>/",
        { noremap = true })
      vim.keymap.set('n', "?", "<Cmd>call ddc#enable_cmdline_completion()<CR>?",
        { noremap = true })
      map('c', '<CR>',
        function(info)
          if info.selected >= 0 then
            vim.fn["pum#map#confirm"]()
          else
            vim.fn["pum#map#cancel"]()
          end
          vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes('<CR>', true, false, true),
            'n',
            false)
        end)
      map('c', '<Tab>', function() vim.fn["pum#map#insert_relative"](1) end,
        function() vim.fn["ddc#map#manual_complete"]() end)
      map('c', '<Down>', function() vim.fn["pum#map#insert_relative"](1) end)
      map('c', '<S-Tab>', function() vim.fn["pum#map#insert_relative"](-1) end)
      map('c', '<Up>', function() vim.fn["pum#map#insert_relative"](-1) end)
      map('c', '<C-c>', function() vim.fn["pum#map#cancel"]() end)
    end,
  },
  {
    'hrsh7th/nvim-cmp',
    enabled = completion_engine == "cmp",
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
          {
            name = 'nvim_lsp'
          },
          {
            name = 'nvim_lsp_document_symbol'
          },
          {
            name = 'vsnip'
          },
          {
            name = 'copilot'
          },
          {
            name = 'buffer'
          },
          {
            name = 'otter'
          },
        }, {
          {
            name = 'rg',
            keyword_length = 3,
          },
          {
            name = 'path',
            options = {
              trailing_slash = false,
              label_trailing_slash = false,
            },
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
            options = {
              trailing_slash = false,
              label_trailing_slash = false,
            },
          },
        }, {
          { name = 'cmdline' },
          { name = 'cmp-nvim-lua' },
        })
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
        init = function()
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
        init = function()
          vim.cmd [[
            autocmd User PumCompleteDone call vsnip_integ#on_complete_done(g:pum#completed_item)
          ]]
        end,
      },
      {
        "zbirenbaum/copilot-cmp",
        config = function()
          require("copilot_cmp").setup()
        end
      },
      { 'jmbuhr/otter.nvim' },
    },
  },
  {
    'direnv/direnv.vim',
    enabled = not is_light_mode,
  },
  {
    'cshuaimin/ssr.nvim',
    enabled = not is_light_mode,
  },
  {
    'folke/zen-mode.nvim',
    enabled = not is_light_mode,
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
    enabled = not is_light_mode,
    config = true,
  },
  {
    'mateuszwieloch/automkdir.nvim',
    enabled = not is_light_mode,
  },
  {
    'MattesGroeger/vim-bookmarks',
    enabled = not is_light_mode,
    event = "VeryLazy",
    keys = {
      { 'mm', "<Plug>BookmarkToggle", mode = { 'n' } },
      { 'mx', "<Plug>BookmarkClear",  mode = { 'n' } },
    },
    cmd = {
      'BookmarkShowAll'
    },
    init = function()
      vim.g.bookmark_save_per_working_dir = 1
      vim.g.bookmark_no_default_key_mappings = 1
      vim.g.bookmark_sign = ''
    end,
  },
  {
    "johmsalas/text-case.nvim",
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
    enabled = not is_light_mode,
    config = function()
      require("eagle").setup {}
    end,
  },
  {
    'dlvhdr/gh-addressed.nvim',
    enabled = not is_light_mode,
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
    enabled = true,
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
        if val ~= 'result' then
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
        local lines = { indent .. "```result" }
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
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
  },
  -- [Git]
  {
    'NeogitOrg/neogit',
    enabled = false,
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
    init = function()
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
        },
      }
    end,
  },
  {
    'tpope/vim-fugitive',
  },
  {
    'lambdalisue/gina.vim',
    init = function()
      vim.cmd [[
        autocmd FileType gina-log   nmap F <Plug>(gina-show-commit-vsplit)zv
        autocmd FileType gina-blame nmap F <Plug>(gina-show-commit-tab)zv
        command Gblame Gina blame
      ]]
    end
  },
  {
    'lewis6991/gitsigns.nvim',
    enabled = not is_light_mode,
    init = function()
      require('gitsigns').setup({
        signcolumn = false,
        numhl      = true,
      })
    end,
  },
  -- [LSP]
  {
    'neovim/nvim-lspconfig',
    enabled = not is_light_mode,
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
            timeout_ms = 500,
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
        bmap('n', '<C-h>', vim.lsp.buf.hover)
        bmap('n', '<C-j>', trouble('lsp_definitions', true))
        bmap('n', '<C-k>', '<cmd>Lspsaga peek_definition<CR>')
        bmap('n', '<C-l>a', require("actions-preview").code_actions)
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
        client.server_capabilities.semanticTokensProvider = nil
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
        if client.name == "tsserver" or client.name == "jsonls" then
          client.server_capabilities.documentFormattingProvider = false
        end
        -- Force load
        vim.cmd("LspSettings update " .. client.name)
      end

      -- [[capabilities]]
      -- enable completion
      vim.g.lsp_default_capabilities = require("ddc_source_lsp").make_client_capabilities()
      -- vim.g.lsp_default_capabilities = require('cmp_nvim_lsp').default_capabilities()
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
      require 'lspconfig'.hls.setup {
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
      }

      -- [[denols]]
      require 'lspconfig'.denols.setup {
        root_dir = require 'lspconfig'.util.root_pattern("deno.json"),
        init_options = {
          lint = true,
        },
        single_file_support = false,
      }

      -- [[tsserver]]
      require 'lspconfig'.tsserver.setup {
        root_dir = require 'lspconfig'.util.root_pattern("package.json"),
        init_options = {
          lint = true,
        },
        single_file_support = false,
      }

      -- [[lua_ls]]
      require 'lspconfig'.lua_ls.setup {}
      -- [[nil_ls]]
      require 'lspconfig'.nil_ls.setup {
        settings = {
          ["nil"] = {
            formatting = {
              command = { "nixpkgs-fmt" }
            },
          },
        },
      }
      -- [[others]]
      require 'lspconfig'.bashls.setup {}
      require 'lspconfig'.eslint.setup {}
      require 'lspconfig'.biome.setup {}
      require 'lspconfig'.tailwindcss.setup {
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
      }
      require 'lspconfig'.dhall_lsp_server.setup {}
      require 'lspconfig'.gopls.setup {}
      require 'lspconfig'.jsonls.setup {}
      require 'lspconfig'.rust_analyzer.setup {
        settings = {
          ['rust-analyzer'] = {
            check = {
              command = "clippy"
            }
          }
        }
      }
      require 'lspconfig'.graphql.setup {}
      require 'lspconfig'.pyright.setup {}
      require 'lspconfig'.yamlls.setup {}
      require 'lspconfig'.terraformls.setup {}
      require 'lspconfig'.tflint.setup {}
      require 'lspconfig'.dockerls.setup {}
      require 'lspconfig'.sqlls.setup {}
      require 'lspconfig'.gradle_ls.setup {}
      require 'lspconfig'.volar.setup {
        root_dir = require 'lspconfig'.util.root_pattern("vue.config.js", "nuxt.config.ts"),
      }
      require 'lspconfig'.unison.setup {}
    end,
    dependencies = {
      {
        'WhoIsSethDaniel/mason-tool-installer.nvim',
        config = function()
          require('mason-tool-installer').setup {
            ensure_installed = {
              -- [LSP]
              "bash-language-server",
              "biome",
              "dhall-lsp",
              "diagnostic-languageserver",
              "dockerfile-language-server",
              "eslint-lsp",
              "gopls",
              "gradle-language-server",
              "graphql-language-service-cli",
              "jdtls",
              "json-lsp",
              "lua-language-server",
              "pyright",
              "terraform-ls",
              "tflint",
              "typescript-language-server",
              "tailwindcss-language-server",
              "yaml-language-server",
              "sqls",
              -- [DAP]
              "java-debug-adapter",
              "java-test",
              -- [null-ls]
              "actionlint",
              "black",
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
          {
            'williamboman/mason-lspconfig.nvim',
            config = true,
          },
          {
            'williamboman/mason.nvim',
            config = true,
          },
        },
      },
      {
        'stevearc/conform.nvim',
        event = "VeryLazy",
        config = function()
          vim.g.format_on_save_enabled = true
          require("conform").setup({
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
        config = function()
          local null_ls = require("null-ls")
          local h = require("null-ls.helpers")
          local methods = require("null-ls.methods")

          ---@diagnostic disable-next-line: unused-local
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

          ---@diagnostic disable-next-line: unused-local
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
              -- [diagnostics]
              null_ls.builtins.diagnostics.actionlint,
              null_ls.builtins.diagnostics.hadolint,
              null_ls.builtins.diagnostics.yamllint,
              -- null_ls.builtins.diagnostics.checkstyle.with({
              --   extra_args = { "--", "-f", "sarif", "$FILENAME" },
              -- }),
              -- spotbugs,
              -- [formatter]
              null_ls.builtins.formatting.black,
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
                  "vue",
                },
              }),
              null_ls.builtins.formatting.markdownlint,
              null_ls.builtins.formatting.shfmt.with({
                extra_args = { "-i", "0", "-ci" },
              }),
              -- spotless,
              -- [code_action]
              null_ls.builtins.code_actions.gitrebase,
            }
          }
          -- require("null-ls").disable({ name = "spotbugs" })
        end,
        dependencies = { "plenary.nvim" },
      },
      { 'aznhe21/actions-preview.nvim' },
      { 'Shougo/ddc-source-lsp', },
      {
        "unisonweb/unison",
        branch = "trunk",
        config = function(plugin)
          vim.opt.rtp:append(plugin.dir .. "/editor-support/vim")
          require("lazy.core.loader").packadd(plugin.dir .. "/editor-support/vim")
        end,
        init = function(plugin)
          require("lazy.core.loader").ftdetect(plugin.dir .. "/editor-support/vim")
        end,
      },
      { "artemave/workspace-diagnostics.nvim" }
    },
  },
  {
    'tamago324/nlsp-settings.nvim',
    enabled = not is_light_mode,
    dependencies = { 'nvim-lspconfig' },
    init = function()
      require 'nlspsettings'.setup({
        append_default_schemas = true,
        loader = 'json',
        nvim_notify = {
          enable = false,
        }
      })
    end,
  },
  {
    'folke/trouble.nvim',
    enabled = not is_light_mode,
    init = function()
      require('trouble').setup {}
    end,
  },
  {
    'nvimdev/lspsaga.nvim',
    enabled = not is_light_mode,
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
  {
    'j-hui/fidget.nvim',
    enabled = not is_light_mode,
    tag = 'legacy',
    init = function()
      require 'fidget'.setup {}
    end
  },
  {
    'mfussenegger/nvim-jdtls',
    enabled = not is_light_mode,
  },
  -- [DAP]
  {
    'mfussenegger/nvim-dap',
    enabled = not is_light_mode,
    init = function()
      vim.cmd [[
      autocmd FileType dap-repl lua require('dap.ext.autocompl').attach()
    ]]
    end
  },
  {
    'theHamsta/nvim-dap-virtual-text',
    enabled = not is_light_mode,
    dependencies = { 'nvim-dap' },
    init = function()
      require("nvim-dap-virtual-text").setup({})
    end
  },
  {
    "rcarriga/nvim-dap-ui",
    enabled = not is_light_mode,
    dependencies = {
      'nvim-dap',
      'nvim-neotest/nvim-nio'
    },
    init = function()
      require("dapui").setup()
    end
  },
  -- [Filetype]
  -- [[Haskell]]
  {
    'neovimhaskell/haskell-vim',
    enabled = not is_light_mode,
  },
  -- [[dhall]]
  {
    'vmchale/dhall-vim',
    enabled = not is_light_mode,
  },
  -- [[Rust]]
  {
    'rust-lang/rust.vim',
    enabled = not is_light_mode,
  },
  -- [[GraphQL]]
  {
    'jparise/vim-graphql',
    enabled = not is_light_mode,
  },
  -- [[nix]]
  {
    'LnL7/vim-nix',
    enabled = not is_light_mode,
  },
  -- [[Markdown]]
  {
    'preservim/vim-markdown',
    enabled = not is_light_mode,
    init = function()
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
    enabled = not is_light_mode,
    build = "cd app && npm install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
      vim.g.mkdp_preview_options = {
        disable_sync_scroll = true,
      }
    end,
  },
  {
    'vim-voom/VOoM',
    enabled = not is_light_mode,
  },
  {
    'epwalsh/obsidian.nvim',
    version = "*",
    ft = "markdown",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "hrsh7th/nvim-cmp",
      "ibhagwan/fzf-lua",
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
        nvim_cmp = true,
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
    },
    keys = {
      { '<C-t>',      "<Cmd>ObsidianToday<CR>",       mode = { 'n' } },
      { '<leader>ob', "<Cmd>ObsidianBacklinks<CR>",   mode = { 'n' } },
      { '<leader>oq', "<Cmd>ObsidianQuickSwitch<CR>", mode = { 'n' } },
    },
  },
  {
    "oflisback/obsidian-bridge.nvim",
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
    enabled = not is_light_mode,
  },
  -- [[Textile]]
  {
    's3rvac/vim-syntax-redminewiki',
    enabled = not is_light_mode,
    init = function()
      vim.cmd [[
        autocmd BufEnter *.redmine set ft=redminewiki
      ]]
    end
  },
  -- [[JavaScript/TypeScript]]
  {
    'jelera/vim-javascript-syntax',
    enabled = not is_light_mode,
  },
  {
    'leafgarland/typescript-vim',
    enabled = not is_light_mode,
  },
  -- [[just]]
  {
    "NoahTheDuke/vim-just",
    ft = { "just" },
  }
}
