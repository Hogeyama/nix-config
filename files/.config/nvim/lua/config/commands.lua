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

vim.api.nvim_create_user_command('RmTrailingWhiteSpaces',
  [[%s/\s\+$//g | :noh]],
  {}
)