--------------------------------------------------------------------------------
-- Long line wrap display (wrap=false時に長い行をfloating window/virtual textで表示)
--------------------------------------------------------------------------------
do
  local ns = vim.api.nvim_create_namespace("long_line_wrap")
  local float_winid = nil
  local float_bufnr = nil

  local function close_float()
    if float_winid and vim.api.nvim_win_is_valid(float_winid) then
      vim.api.nvim_win_close(float_winid, true)
    end
    float_winid = nil
    if float_bufnr and vim.api.nvim_buf_is_valid(float_bufnr) then
      vim.api.nvim_buf_delete(float_bufnr, { force = true })
    end
    float_bufnr = nil
  end

  local function clear_virt(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  end

  --- タブを展開してdisplaywidthを計算するためのヘルパー
  local function display_width(text, tabstop)
    return vim.fn.strdisplaywidth(text, tabstop)
  end

  --- テキストをwrap幅で折り返す
  local function wrap_text(text, width, tabstop)
    local lines = {}
    local remaining = text
    while display_width(remaining, tabstop) > width do
      -- バイト単位で切り出す必要がある
      local byte_pos = 0
      local dw = 0
      while byte_pos < #remaining do
        local char_len = vim.fn.byteidx(remaining, vim.fn.charidx(remaining, byte_pos) + 1) - byte_pos
        if char_len <= 0 then char_len = 1 end
        local char = remaining:sub(byte_pos + 1, byte_pos + char_len)
        local char_dw
        if char == "\t" then
          char_dw = tabstop - (dw % tabstop)
        else
          char_dw = vim.fn.strdisplaywidth(char)
        end
        if dw + char_dw > width then
          break
        end
        dw = dw + char_dw
        byte_pos = byte_pos + char_len
      end
      if byte_pos == 0 then
        -- 1文字もwidthに収まらない（超幅広文字）場合は最低1文字
        local char_len = vim.fn.byteidx(remaining, 1)
        if char_len <= 0 then char_len = 1 end
        byte_pos = char_len
      end
      table.insert(lines, remaining:sub(1, byte_pos))
      remaining = remaining:sub(byte_pos + 1)
    end
    if #remaining > 0 then
      table.insert(lines, remaining)
    end
    return lines
  end

  local function find_right_window(cur_win)
    local cur_pos = vim.api.nvim_win_get_position(cur_win)
    local cur_width = vim.api.nvim_win_get_width(cur_win)
    local cur_row = cur_pos[1]
    local cur_right_col = cur_pos[2] + cur_width

    local best_win = nil
    local best_col = math.huge
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if win ~= cur_win then
        local cfg = vim.api.nvim_win_get_config(win)
        if cfg.relative == "" then -- 通常ウィンドウのみ
          local pos = vim.api.nvim_win_get_position(win)
          local win_row = pos[1]
          local win_col = pos[2]
          local win_height = vim.api.nvim_win_get_height(win)
          -- 右側にあり、垂直方向で重なりがあること
          if win_col >= cur_right_col
              and win_row < cur_row + vim.api.nvim_win_get_height(cur_win)
              and win_row + win_height > cur_row then
            if win_col < best_col then
              best_col = win_col
              best_win = win
            end
          end
        end
      end
    end
    return best_win
  end

  local function show_wrap()
    local bufnr = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    close_float()
    clear_virt(bufnr)

    if vim.wo[win].wrap then
      return
    end

    local cursor = vim.api.nvim_win_get_cursor(win)
    local row = cursor[1] -- 1-indexed
    local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ""
    local win_width = vim.api.nvim_win_get_width(win)
    -- signcolumnなどのオフセット分
    local win_info = vim.fn.getwininfo(win)[1]
    local text_width = win_width - (win_info.textoff or 0)
    local tabstop = vim.bo[bufnr].tabstop

    if display_width(line, tabstop) <= text_width then
      return
    end

    local wrapped = wrap_text(line, text_width, tabstop)
    if #wrapped <= 1 then
      return
    end

    -- 最初の行は既に表示されているので、はみ出し部分を取得
    local overflow_text = line:sub(#wrapped[1] + 1)
    if #overflow_text == 0 then
      return
    end

    local right_win = find_right_window(win)

    if right_win then
      local right_pos = vim.api.nvim_win_get_position(right_win)
      local right_width = vim.api.nvim_win_get_width(right_win)
      local right_height = vim.api.nvim_win_get_height(right_win)

      local cur_pos = vim.api.nvim_win_get_position(win)
      local screen_row = cur_pos[1] + (cursor[1] - vim.fn.line("w0", win))

      -- はみ出し部分を右側ウィンドウの幅でwrap
      local overflow_lines = wrap_text(overflow_text, right_width, tabstop)

      local float_height = math.min(#overflow_lines, right_height)
      local float_width = right_width + 1
      local float_row = screen_row + 1
      local float_col = right_pos[2] - 1

      float_bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(float_bufnr, 0, -1, false, overflow_lines)
      vim.bo[float_bufnr].modifiable = false
      vim.bo[float_bufnr].bufhidden = "wipe"

      float_winid = vim.api.nvim_open_win(float_bufnr, false, {
        relative = "editor",
        row = float_row,
        col = float_col,
        width = float_width,
        height = float_height,
        style = "minimal",
        border = "none",
        focusable = false,
        zindex = 50,
      })
      vim.wo[float_winid].winblend = 0
      vim.wo[float_winid].winhighlight = "Normal:Normal"
    else
      -- virtual textでカーソル行の下に表示
      local overflow_lines = wrap_text(overflow_text, text_width, tabstop)
      local virt_lines = {}
      for _, vl in ipairs(overflow_lines) do
        table.insert(virt_lines, { { vl, "Normal:Normal" } })
      end
      vim.api.nvim_buf_set_extmark(bufnr, ns, row - 1, 0, {
        virt_lines = virt_lines,
        virt_lines_above = false,
      })
    end
  end

  local function on_cursor_move()
    -- defer to avoid flicker during rapid movement
    vim.defer_fn(function()
      if vim.api.nvim_get_mode().mode:match("^[nc]") then
        show_wrap()
      else
        close_float()
        local bufnr = vim.api.nvim_get_current_buf()
        clear_virt(bufnr)
      end
    end, 50)
  end

  local augroup = vim.api.nvim_create_augroup("LongLineWrap", { clear = true })
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = augroup,
    callback = on_cursor_move,
  })
  vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave", "InsertEnter", "ModeChanged" }, {
    group = augroup,
    callback = function()
      close_float()
      -- 全バッファのvirtual textをクリアするのは重いので、現在バッファのみ
      pcall(function()
        clear_virt(vim.api.nvim_get_current_buf())
      end)
    end,
  })
end
