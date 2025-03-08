--------------------------------------------------------------------------------
-- util
--------------------------------------------------------------------------------

local map = vim.keymap.set
local nmap = function(lhs, rhs, opts)
  map({ 'n' }, lhs, rhs, opts)
end
local imap = function(lhs, rhs, opts)
  map({ 'i' }, lhs, rhs, opts)
end
local vmap = function(lhs, rhs, opts)
  map({ 'v' }, lhs, rhs, opts)
end
local nvmap = function(lhs, rhs, opts)
  map({ 'n', 'v' }, lhs, rhs, opts)
end
local cmap = function(lhs, rhs, opts)
  map({ 'c' }, lhs, rhs, opts)
end
local tmap = function(lhs, rhs, opts)
  map({ 't' }, lhs, rhs, opts)
end

--------------------------------------------------------------------------------
-- mapping
--------------------------------------------------------------------------------

nmap('<C-n>', '<Cmd>:update!<CR>')
imap('<C-n>', '<Esc><Cmd>:update<CR>')

nmap('tt', '<Cmd>tabedit<CR>')
nmap('tg', 'gT')

nmap('vs', '<Cmd>rightbelow vsplit<CR>')

nmap('dk', 'ddk')
nmap('dj', 'dd')

nmap('Y', 'y$')
nmap('yw', 'ye')

nmap('zh', '<C-w>h')
nmap('zj', '<C-w>j')
nmap('zk', '<C-w>k')
nmap('zl', '<C-w>l')

nmap('cj', '<C-w>j:q<CR><C-w>k')
nmap('ck', '<C-w>k:q<CR><C-w>j')
nmap('ch', '<C-w>h:q<CR><C-w>l')
nmap('cl', '<C-w>l:q<CR><C-w>h')

nmap('zn', 'za')

nmap('<C-a>', 'I')
nmap('<C-e>', 'A')

nvmap('fJ', 'J')
nvmap('J', '5j')
nvmap('K', '5k')
nvmap('H', 'B')
nvmap('L', 'W')

nvmap('j', 'gj')
nvmap('k', 'gk')
nvmap('gj', 'j')
nvmap('gk', 'k')

imap('<C-j>', '<Down>')
imap('<C-k>', '<Up>')
imap('<C-h>', '<Left>')
imap('<C-l>', '<Right>')

imap('<C-b>', '<Esc>lBi')
imap('<C-a>', '<Esc>I')
imap('<C-e>', '<Esc>A')

cmap('<C-j>', '<Down>')
cmap('<C-k>', '<Up>')

nmap('te', '<Cmd>terminal<CR>')
tmap('JK', '<C-\\><C-n><C-w>h')
tmap('zh', '<C-\\><C-n><C-w>h')
tmap('zj', '<C-\\><C-n><C-w>j')
tmap('zk', '<C-\\><C-n><C-w>k')
tmap('zl', '<C-\\><C-n><C-w>l')
tmap('zz', '<C-\\><C-n>')

nmap('<Space>cd', '<Cmd>cd %:h<CR>')
nmap('^', '<Cmd>noh<CR>')
vmap('*', '"zy:let @/ = @z<CR>n')
nmap(':w<CR>', '<Cmd>echom "yo"<CR>')

vim.keymap.set("v", "y",
  function()
    vim.cmd('normal! y')
    -- 現在のバッファがターミナルならhard-wrapで追加された改行を削除する
    -- ちょうどwidthと一致するところに改行がある場合は誤判定されるが、諦めている
    local buftype = vim.api.nvim_get_option_value("buftype", {})
    if buftype == "terminal" then
      local width = vim.api.nvim_win_get_width(0)
      local yanked_text = vim.fn.getreg('"')

      local lines = {}
      local real_line = {}
      for line in yanked_text:gmatch("[^\r\n]+") do
        table.insert(real_line, line)
        if #line < width then
          table.insert(lines, table.concat(real_line, ""))
          real_line = {}
        end
      end
      if #real_line > 0 then
        table.insert(lines, table.concat(real_line, ""))
      end

      vim.fn.setreg('+', lines, 'l')
    end
  end, { noremap = true, silent = true })
