vim.g.mapleader = ","
vim.opt.fileencodings = "utf-8,cp932"
vim.opt.shell = "zsh"
vim.opt.termguicolors = true
vim.opt.mouse = "n"
vim.opt.ambiwidth = "single"
vim.opt.visualbell = true
vim.opt.hidden = true
vim.opt.modeline = true
vim.opt.number = false
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.autoindent = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = false
vim.opt.conceallevel = 0
vim.opt.concealcursor = nil
vim.opt.laststatus = 3
vim.opt.completeopt = "menuone,noselect,noinsert"
vim.opt.scrolloff = 5
vim.opt.history = 100
vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.list = true
vim.opt.listchars = "tab:>─,trail:_"
vim.opt.whichwrap = "b,s,h,l,<,>,[,]"
vim.opt.backspace = "indent,eol,start"
vim.opt.wildoptions = "pum"
vim.opt.showtabline = 0
vim.opt.switchbuf = "split"
vim.opt.updatetime = 300
vim.opt.cursorline = false
vim.opt.signcolumn = "yes"
vim.opt.fillchars = 'fold:-,eob: '
-- 開いた状態で始める。foldmethod は treesitter の起動時に決める (plugins/init.lua)
vim.opt.foldcolumn = '0'
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true
vim.opt.foldtext = '' -- 折り畳んだ行をシンタックスハイライト付きで表示

-- https://github.com/vscode-neovim/vscode-neovim/issues/2507#issuecomment-3059712058
if vim.g.vscode then
  vim.opt.cmdheight = 100
else
  -- メッセージ/cmdline の新UI (0.12+, experimental)。"Press ENTER" が出なくなる
  -- 溢れたメッセージは g< で pager に出る
  pcall(function() require('vim._core.ui2').enable({}) end)
end

-- 1. 外部でファイルが変更されたら自動的に読み込み直す（未保存の変更がない場合）
vim.opt.autoread = true

-- 2. 様々なアクションのタイミングで、ファイルの変更状態をチェック（checktime）する
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  pattern = "*",
  callback = function()
    -- コマンドラインモードでは実行しない
    if vim.fn.mode() ~= 'c' then
      vim.cmd("checktime")
    end
  end,
})

-- 3. 自動リロードされた時に通知を出す
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  pattern = "*",
  callback = function()
    vim.api.nvim_echo({ { "File changed on disk. Buffer reloaded.", "WarningMsg" } }, false, {})
  end,
})
