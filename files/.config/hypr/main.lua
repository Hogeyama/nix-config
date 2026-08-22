----------------
--- MONITORS ---
----------------
hl.monitor({ output = ",", mode = "preferred", position = "auto", scale = "auto" })

-- nwg-displays (0.4.3+) が書き出す monitors.lua を取り込む。
-- 中身は hl.monitor({...}) の羅列なので dofile するだけでよい。
-- 未生成のうちは上の catch-all のままになる。
local monitors_lua = os.getenv("HOME") .. "/.config/hypr/monitors.lua"
local fh = io.open(monitors_lua, "r")
if fh then
  fh:close()
  dofile(monitors_lua)
end

-------------------
--- MY PROGRAMS ---
-------------------
local terminal = "ghostty"
local menu = "wofi --show drun"

-----------------------------
--- ENVIRONMENT VARIABLES ---
-----------------------------

------------------------
--- LAYOUT CONSTANTS ---
------------------------
-- hl.config と workspace rule の両方から参照するので定数に切り出す。
-- (ウィンドウ1枚のときの gaps を計算するのに orientation と gaps_out が要る)
local GAPS_OUT = 5
local DEFAULT_ORIENTATION = "left" -- master を左ペイン、slave を右ペインに
-- モニタ個別の orientation 上書き。ここが solo rule の向きにも効く。
local MONITOR_ORIENTATION = {
  ["DP-1"] = "top",
  ["HDMI-A-2"] = "left",
}

---------------------
--- LOOK AND FEEL ---
---------------------
hl.config({
  general = {
    gaps_in = 5,
    gaps_out = GAPS_OUT,
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
    orientation = DEFAULT_ORIENTATION,
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
        active = "rgba(12283aff)",   -- アクティブタブ背景
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

--- Workspace rules (per-monitor orientation)
for name, orientation in pairs(MONITOR_ORIENTATION) do
  hl.workspace_rule({ workspace = "m[" .. name .. "]", layout_opts = { orientation = orientation } })
end

--- ウィンドウが1枚だけのときも master ペインの大きさに収める。
--- 全画面はでかすぎるので、2枚目が既にあるかのように片側を空ける。
--- 空ける幅は master の割合に揃えてあるので、2枚目を開いても1枚目は動かない。
--- 全画面が欲しいときは今まで通り SUPER+F (fullscreen)。gaps は無視される。
---
--- 実装: w[tv1] = 「タイル表示のウィンドウがちょうど1枚」のワークスペースに
--- 非対称な gaps_out を当てる。gaps_out は px 指定なのでモニタ毎に計算が要る。
local MFACT_MIN, MFACT_MAX = 0.05, 0.95
local OPPOSITE_ORIENTATION = { left = "right", right = "left", top = "bottom", bottom = "top" }

-- 1枚のときにウィンドウを置く側。SUPER+A でモニタ毎に反転させる。
local solo_flipped = {}

-- master の割合。Hyprland はこれをワークスペース毎に保持していて読み出す API が
-- ないので、SUPER+SHIFT+H/L の増減をこちら側でも同じように追跡する。
local mfact_by_workspace = {}

local function default_mfact()
  return tonumber(hl.get_config("master.mfact")) or 0.55
end

local function workspace_mfact(ws)
  return ws and mfact_by_workspace[ws.id] or default_mfact()
end

local function set_workspace_mfact(ws, value)
  if ws then
    mfact_by_workspace[ws.id] = math.max(MFACT_MIN, math.min(MFACT_MAX, value))
  end
end

local function tiled_window_count(ws)
  if not ws then return 0 end
  local n = 0
  for _, w in ipairs(hl.get_workspace_windows(ws)) do
    if not w.floating then n = n + 1 end
  end
  return n
end

-- 直近にモニタへ撒いた gaps。値が同じでも hl.workspace_rule を呼ぶとレイアウトが
-- 走り直して monitor.layout_changed が飛び、そこからここへ戻ってくる。差分が
-- なければ撒かない、で閉ループを切る。
local last_solo_gaps = {}

local function gaps_equal(a, b)
  return a ~= nil
    and a.top == b.top
    and a.right == b.right
    and a.bottom == b.bottom
    and a.left == b.left
end

local function emit_solo_master_rules()
  for _, m in ipairs(hl.get_monitors()) do
    -- gaps はモニタ毎に固定値なので、そのモニタで今見えているワークスペースの
    -- 割合を使う。切り替わったら workspace.active で撒き直す。
    local ws = m.active_workspace or hl.get_active_workspace(m.name)
    local slave = 1 - workspace_mfact(ws) -- slave ペインが占めるはずだった割合

    -- m.width/m.height は回転前のモード解像度(物理px)。gaps は回転後の論理px なので
    -- 90/270 度回転(transform が奇数)では縦横を入れ替えてから scale で割る。
    local scale = m.scale or 1
    local width, height = m.width, m.height
    if (m.transform or 0) % 2 == 1 then
      width, height = height, width
    end
    width = width / scale
    height = height / scale

    local orientation = MONITOR_ORIENTATION[m.name] or DEFAULT_ORIENTATION
    if solo_flipped[m.name] then
      orientation = OPPOSITE_ORIENTATION[orientation] or orientation
    end

    local gaps = { top = GAPS_OUT, right = GAPS_OUT, bottom = GAPS_OUT, left = GAPS_OUT }
    if orientation == "left" then
      gaps.right = math.floor(width * slave)
    elseif orientation == "right" then
      gaps.left = math.floor(width * slave)
    elseif orientation == "top" then
      gaps.bottom = math.floor(height * slave)
    elseif orientation == "bottom" then
      gaps.top = math.floor(height * slave)
    end

    if not gaps_equal(last_solo_gaps[m.name], gaps) then
      last_solo_gaps[m.name] = gaps
      hl.workspace_rule({ workspace = "m[" .. m.name .. "] w[tv1]", gaps_out = gaps })
    end
  end
end

-- hl.workspace_rule がイベントを同期で配送してくると last_solo_gaps を更新しても
-- その場で呼び戻されるので、再入もフラグで止める。落ちてもフラグが立ちっぱなしに
-- ならないよう pcall で囲って必ず下ろす。
local applying_solo_rules = false

local function apply_solo_master_rules()
  if applying_solo_rules then return end
  applying_solo_rules = true
  local ok, err = pcall(emit_solo_master_rules)
  applying_solo_rules = false
  if not ok then error(err, 0) end
end

-- 起動直後のconfigパース時点ではモニタが未確定なことがあるので、
-- 初回呼び出しに加えてモニタ構成・表示ワークスペースの変化でも撒き直す。
apply_solo_master_rules()
hl.on("monitor.added", apply_solo_master_rules)
hl.on("monitor.layout_changed", apply_solo_master_rules)
hl.on("workspace.active", apply_solo_master_rules)

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
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
-- Hyprland 側 (ワークスペース毎の内部値) と手元の追跡値を同じだけ動かして、
-- 1枚だけのときの空き幅にも反映させる。
local function nudge_mfact(delta)
  return function()
    hl.dispatch(hl.dsp.layout(string.format("mfact %+.2f", delta)))
    local ws = hl.get_active_workspace()
    set_workspace_mfact(ws, workspace_mfact(ws) + delta)
    apply_solo_master_rules()
  end
end

hl.bind(mainMod .. " + SHIFT + H", nudge_mfact(-0.02))
hl.bind(mainMod .. " + SHIFT + L", nudge_mfact(0.02))
hl.bind(mainMod .. " + M", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.window.move({ workspace = "special:magic" }))
-- SUPER+A: 元設定で swapwindow と swapwithmaster が二重定義され後者が有効だった。
-- 1枚だけのときは入れ替える相手がいないので、代わりに置く側を反転させる
-- (orientation=left なら左半分 <-> 右半分、top なら上半分 <-> 下半分)。
hl.bind(mainMod .. " + A", function()
  local ws = hl.get_active_workspace()
  if tiled_window_count(ws) == 1 then
    local m = (ws and ws.monitor) or hl.get_active_monitor()
    if m then
      solo_flipped[m.name] = not solo_flipped[m.name]
      apply_solo_master_rules()
    end
  else
    hl.dispatch(hl.dsp.layout("swapwithmaster"))
  end
end)
hl.bind(mainMod .. " + V", hl.dsp.window.float())
-- SUPER+F: 元設定で makoctl invoke と fullscreen が二重定義され後者が有効だった
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen(1))

-- Group (右ペインをタブ化スタックとして使う)
-- 既存窓をグループへ入れるキーボード関数は新lua API(0.55.2)に無い。
-- 取り込みはマウスでタブバーへD&D(group.drag_into_group=true)、
-- もしくはグループにフォーカス中に新規窓を開くと自動参加する。
hl.bind(mainMod .. " + U", hl.dsp.group.toggle())                                    -- 単独グループ作成 / グループ全体を解除
hl.bind(mainMod .. " + Tab", hl.dsp.group.next())                                    -- グループ内タブ切替（次）
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.group.prev())                            -- グループ内タブ切替（前）
-- move_window はグループ内でのタブ位置の入れ替え専用（要: 自身がグループ内）
hl.bind(mainMod .. " + CTRL + H", hl.dsp.group.move_window({ direction = "left" }))  -- タブを前へ
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
