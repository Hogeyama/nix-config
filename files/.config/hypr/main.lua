----------------
--- MONITORS ---
----------------
hl.monitor({ output = ",", mode = "preferred", position = "auto", scale = "auto" })

-------------------
--- MY PROGRAMS ---
-------------------
local terminal = "ghostty"
local fileManager = "dolphin"
local menu = "wofi --show drun"

-----------------------------
--- ENVIRONMENT VARIABLES ---
-----------------------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

---------------------
--- LOOK AND FEEL ---
---------------------
hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 5,
    border_size = 2,
    ["col.active_border"] = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
    ["col.inactive_border"] = "rgba(595959aa)",
    resize_on_border = false,
    allow_tearing = false,
    layout = "master",
  },
  decoration = {
    rounding = 10,
    rounding_power = 2,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    shadow = {
      enabled = true,
      range = 4,
      render_power = 3,
      color = "rgba(1a1a1aee)",
    },
    blur = {
      enabled = true,
      size = 3,
      passes = 1,
      vibrancy = 0.1696,
    },
  },
  dwindle = {
    -- pseudotile は Hyprland 0.50+ で削除され、pseudo dispatcher でトグルする
    preserve_split = true,
  },
  master = {
    new_status = "master",
    orientation = "left", -- master を左ペイン、slave を右ペインに
  },
  -- 右ペインの slave を group 化するとタブ/スタックのように 1 枚ずつ切替できる
  group = {
    focus_removed_window = true,
    drag_into_group = true, -- ウィンドウをグループ(のバー)へドラッグして放り込めるように
    groupbar = {
      enabled = true,
      stacked = true, -- タブを縦積み表示
      -- gradients=false だと col.* はインジケータ線のみで背景は透明＝文字が読めない。
      -- true にするとタブ背景が col.* で塗りつぶされる。
      gradients = true,
      col = {
        active = "rgba(12283aff)", -- アクティブタブ背景
        inactive = "rgba(222222ff)", -- 非アクティブタブ背景
      },
      text_color = "rgba(ffffffff)",
      text_color_inactive = "rgba(bbbbbbff)",
      font_size = 12,
    },
  },
  misc = {
    force_default_wallpaper = -1,
    disable_hyprland_logo = false,
  },
  input = {
    kb_layout = "jp",
    follow_mouse = 1,
    sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.
    touchpad = {
      natural_scroll = false,
    },
  },
  animations = {
    enabled = true,
  },
})

--- Animations: bezier は hl.curve、animation は hl.animation。curve を先に定義する。
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

--- Workspace rules ("Smart gaps" / per-monitor orientation)
hl.workspace_rule({ workspace = "m[DP-1]", layout_opts = { orientation = "top" } })
hl.workspace_rule({ workspace = "m[HDMI-A-2]", layout_opts = { orientation = "left" } })

-------------
--- INPUT ---
-------------
hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })

-------------------
--- KEYBINDINGS ---
-------------------
local mainMod = "SUPER"

hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + CTRL + Q", hl.dsp.exit())
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("swaylock -f -c 000000"))

hl.bind(mainMod .. " + SPACE", hl.dsp.layout("nextlayout"))
hl.bind(mainMod .. " + RETURN", hl.dsp.focus({ monitor = "+1" }))
hl.bind(mainMod .. " + S", hl.dsp.workspace.swap_monitors({ monitor1 = "current", monitor2 = "+1" }))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("makoctl dismiss"))
-- SHIFT+R: 元設定で kanshictl reload と hyprctl reload が二重定義され後者が有効だった
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.layout("mfact -0.02"))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.layout("mfact +0.02"))
hl.bind(mainMod .. " + M", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.window.move({ workspace = "special:magic" }))
-- SUPER+A: 元設定で swapwindow と swapwithmaster が二重定義され後者が有効だった
hl.bind(mainMod .. " + A", hl.dsp.layout("swapwithmaster"))
hl.bind(mainMod .. " + V", hl.dsp.window.float())
-- SUPER+F: 元設定で makoctl invoke と fullscreen が二重定義され後者が有効だった
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen(1))

-- Group (右ペインをタブ化スタックとして使う)
-- 既存窓をグループへ入れるキーボード関数は新lua API(0.55.2)に無い。
-- 取り込みはマウスでタブバーへD&D(group.drag_into_group=true)、
-- もしくはグループにフォーカス中に新規窓を開くと自動参加する。
hl.bind(mainMod .. " + U", hl.dsp.group.toggle()) -- 単独グループ作成 / グループ全体を解除
hl.bind(mainMod .. " + Tab", hl.dsp.group.next()) -- グループ内タブ切替（次）
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.group.prev()) -- グループ内タブ切替（前）
-- move_window はグループ内でのタブ位置の入れ替え専用（要: 自身がグループ内）
hl.bind(mainMod .. " + CTRL + H", hl.dsp.group.move_window({ direction = "left" })) -- タブを前へ
hl.bind(mainMod .. " + CTRL + L", hl.dsp.group.move_window({ direction = "right" })) -- タブを後へ

-- Switch workspaces with mainMod + [0-9]
for i = 1, 9 do
  hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = tostring(i) }))
end
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = "10" }))

-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 9 do
  hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = tostring(i) }))
end
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = "10" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
-- マウスドラッグbindは { mouse = true }。{ drag = true } はリリースbindになり機能しない。
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness (locked + repeat)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
  { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
  { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
  { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl (locked)
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

------------------------------
--- WINDOWS AND WORKSPACES ---
------------------------------
-- Ignore maximize requests from apps.
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })
-- Fix some dragging issues with XWayland
hl.window_rule({
  match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
  no_focus = true,
})
