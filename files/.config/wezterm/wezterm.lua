local wezterm = require 'wezterm'
local act = wezterm.action


local myfont = wezterm.font_with_fallback {
  "Illusion N",
  "Rounded Mgen+ 1mn",
  "Noto Color Emoji",
  "FiraMono Nerd Font",
  "Noto Sans Mono CJK JP",
}

return {
  -- FONT
  font = myfont,
  font_size = 14,

  -- COLOR
  color_scheme = 'Seti',
  colors = {
    cursor_fg = 'black',
    cursor_bg = 'white',
    cursor_border = 'white',
  },

  -- WINDOW
  window_frame = {
    font = myfont,
    font_size = 18,
    active_titlebar_fg = '#ffffff',
    active_titlebar_bg = '#1a1d1b',
    inactive_titlebar_fg = '#ffffff',
    inactive_titlebar_bg = '#1a1d1b',
  },
  window_padding = {
    left = 10,
    right = 10,
    top = 0,
    bottom = 0,
  },

  -- TAB
  tab_max_width = 30,

  -- KEY BINDINGS
  leader = { key = 'q', mods = 'CTRL', timeout_milliseconds = 1000 },
  keys = {
    { mods = 'CTRL',        key = '+', action = act.IncreaseFontSize },
    { mods = 'CTRL',        key = '-', action = act.DecreaseFontSize },
    { mods = 'ALT',         key = '1', action = act.ActivateTab(0) },
    { mods = 'ALT',         key = '2', action = act.ActivateTab(1) },
    { mods = 'ALT',         key = '3', action = act.ActivateTab(2) },
    { mods = 'ALT',         key = '4', action = act.ActivateTab(3) },
    { mods = 'ALT',         key = '5', action = act.ActivateTab(4) },
    { mods = 'ALT',         key = '6', action = act.ActivateTab(5) },
    { mods = 'ALT',         key = '7', action = act.ActivateTab(6) },
    { mods = 'ALT',         key = '8', action = act.ActivateTab(7) },
    { mods = 'ALT',         key = '9', action = act.ActivateTab(8) },
    { mods = 'LEADER',      key = 'c', action = act.SpawnTab 'CurrentPaneDomain' },
    { mods = 'LEADER',      key = 'q', action = act.ActivateCopyMode },
    { mods = 'LEADER|CTRL', key = 'q', action = act.ActivateCopyMode },
    { mods = 'LEADER',      key = 'n', action = act.ActivateTabRelative(1) },
    { mods = 'LEADER',      key = 'p', action = act.ActivateTabRelative(-1) },
    { mods = 'LEADER',      key = '-', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    { mods = 'LEADER|CTRL', key = '-', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { mods = 'LEADER',      key = 'h', action = act.ActivatePaneDirection 'Left' },
    { mods = 'LEADER',      key = 'l', action = act.ActivatePaneDirection 'Right' },
    { mods = 'LEADER',      key = 'k', action = act.ActivatePaneDirection 'Up' },
    { mods = 'LEADER',      key = 'j', action = act.ActivatePaneDirection 'Down' },
    { mods = 'LEADER',      key = ' ', action = act.QuickSelect },
    { mods = 'LEADER',      key = 'x', action = act.ShowLauncher },
  },

  -- MULTIPLEXING
  -- default_gui_startup_args = { 'connect', 'unix' },
  unix_domains = { { name = 'unix' } },
}
