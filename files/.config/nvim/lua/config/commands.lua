--------------------------------------------------------------------------------
-- User commands
--------------------------------------------------------------------------------

vim.api.nvim_create_user_command('MoveToLastWin',
  [[execute "normal! ".g:last_win."<C-w><C-w>"]],
  {}
)

vim.api.nvim_create_user_command('MoveToLastTab',
  [[execute "tabnext ".g:last_tab ]],
  {}
)

vim.api.nvim_create_user_command('EditBehind',
  [[edit <args> | MoveToLastWin]],
  { nargs = 1, complete = "file" }
)

vim.api.nvim_create_user_command('TabEditBehind',
  [[tabedit <args> | MoveToLastTab]],
  { nargs = 1, complete = "file" }
)

vim.api.nvim_create_user_command('OpenGitHub',
  function(opts)
    local relpath = vim.fn.fnamemodify(vim.fn.expand("%"), ":~:.")
    vim.cmd("!gh browse " .. relpath .. " " .. opts.args)
  end,
  { nargs = "*" }
)

--------------------------------------------------------------------------------
-- Autocommands
--------------------------------------------------------------------------------

vim.g.last_win = 1
vim.api.nvim_create_autocmd({ "WinLeave" }, {
  pattern = { "*" },
  callback = function()
    vim.g.last_win = vim.fn.winnr()
    vim.g.last_file = vim.fn.expand("%:p")
  end,
})

vim.g.last_tab = 0
vim.api.nvim_create_autocmd({ "TabLeave" }, {
  pattern = { "*" },
  callback = function()
    vim.g.last_tab = vim.fn.tabpagenr()
  end,
})

vim.g.last_buf = 1
vim.g.current_buf = 1
vim.api.nvim_create_autocmd({ "BufLeave" }, {
  pattern = { "*" },
  callback = function()
    vim.g.last_buf = vim.g.current_buf
    vim.g.current_buf = vim.fn.bufnr("%")
  end,
})

vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "markdown" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
  end,
})

vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "bash" },
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
  end,
})

vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "just" },
  callback = function()
    vim.cmd [[TSBufEnable highlight]]
  end,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = { "*.nu" },
  callback = function()
    vim.bo.filetype = "nu"
  end,
})
