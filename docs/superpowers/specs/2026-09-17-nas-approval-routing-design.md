# nas Approval Routing into Neovim Design

## Goal

Avante.nvim starts Claude through the `nas` sandbox. Two kinds of nas approval
requests — outbound network access and host command execution — never reach the
ACP protocol, so they never appear in Avante's own approval UI. The agent simply
stalls until the request times out (300 seconds by default).

Route those requests into the running Neovim instance: show that requests are
waiting, and let the user answer them without leaving the editor.

The approval request payload itself stays out of Neovim. Neovim learns only how
many requests are pending per domain; answering them is delegated to
`nas <domain> review`, which already renders the request, offers the approval
scopes, and sends the decision.

## Components

```text
nvim (host)
 └ avante.nvim   command = "nas-acp-nvim", args = { "claude-acp" }
                 env adds NAS_APPROVAL_NVIM_SERVER = v:servername
    └ nas-acp-nvim                                    (bash)
        ├ nas-approval-watch hostexec <sid-file> &    (python3)
        ├ nas-approval-watch network  <sid-file> &    (python3)
        └ exec nas --write-session-id <sid-file> claude-acp
```

### `files/.local/bin/nas-acp-nvim`

A wrapper that Avante launches in place of `nas`. It takes the same arguments
`nas` takes and passes them through.

The session id file lives at `${XDG_RUNTIME_DIR:-/tmp}/nas-acp-nvim/$$.session-id`.
Because the wrapper `exec`s into `nas`, `$$` is also the pid of the `nas`
process, which makes the name unique for as long as the session lives. Nothing
deletes the file afterwards — `exec` leaves no process behind to do it — so the
wrapper sweeps files older than a day out of that directory on startup.

The Neovim server address is `${NAS_APPROVAL_NVIM_SERVER:-${NVIM:-}}`. When both
are empty the wrapper starts no watchers and only `exec`s `nas`, so running it
from a terminal behaves exactly like running `nas`. The fallback to `$NVIM`,
which Neovim sets for its own child jobs, means sidekick's `nas claude` entries
could be pointed at this wrapper later without further changes. They are not
pointed at it now.

`--write-session-id` is inserted ahead of the caller's arguments, because nas
requires its own flags to precede the profile name.

### `files/.local/bin/nas-approval-watch`

`nas-approval-watch <domain> <session-id-file>`, written in Python 3 with the
standard library only.

1. Poll for the session id file until it holds a line. Give up after a timeout
   (120 seconds by default, overridable through an environment variable so the
   tests do not have to wait).
2. Run `nas <domain> watch --session <sid>` and read its stdout line by line.
3. Each line is one JSON object. `added` inserts `entry.requestId` into a set,
   `removed` discards `requestId`. Push the new size to Neovim only when the set
   actually changed, so a duplicate `added` for a request already held produces
   no traffic. The session id rides along with the count, so that Neovim can
   hold `nas review` to the same session.
4. On EOF — which is how a `--session` watch reports that the session ended —
   push a count of 0 and exit.

The process also exits when `os.getppid()` no longer matches the value captured
at startup. After the wrapper `exec`s, that parent is the `nas` process, so the
watcher follows the session's life even in the failure case where nas dies
before registering a session and the watch would otherwise wait forever.

A push runs:

```sh
nvim --server <srv> --remote-expr \
  "luaeval(\"require('config.nas_approval').set_pending(_A[1], _A[2], _A[3])\", \
   ['hostexec', 'sess_a1b2c3', 2])"
```

The argv is built directly, so no shell quoting is involved. The session id is
interpolated into a Vim expression, so a value outside `[A-Za-z0-9_-]` ends the
watcher instead. Failures are logged and ignored: a Neovim that has already
exited must not take the watcher down with it.

Standard error goes to `${XDG_STATE_HOME:-$HOME/.local/state}/nas-approval/<domain>.log`.
Leaving it on the inherited descriptor would mix watcher diagnostics into the
ACP child's stderr, which Avante reads.

### `files/.config/nvim/lua/config/nas_approval.lua`

Loaded unconditionally from `initLua`, so the RPC target exists whether or not
Avante has been loaded yet.

`set_pending(domain, session_id, count)` stores both and updates the
notification. A
count of 1 or more calls `Snacks.notifier.notify` with
`id = "nas-approval-" .. domain` and `timeout = false`; reusing the id updates
the existing notification in place rather than stacking new ones. A count of 0
calls `Snacks.notifier.hide(id)`, which is how a request answered in the web UI,
answered from a terminal, or timed out disappears from the editor.

`review()` opens `nas <domain> review --session <sid>` in a `Snacks.terminal`
float. When only one domain has pending requests it opens that one directly;
when both do it asks with `vim.ui.select` first; when neither does it says so
and opens nothing.

The module registers the `:NasApprovalReview` command and the `<leader>an`
mapping. Sidekick already occupies `<leader>a` plus `s`, `d`, `t`, `f`, `v`,
and `p`; `an` is free.

Everything Neovim shows covers this session alone: each watcher subscribes with
`--session`, and the review it opens carries the same filter. Requests from
another nas session the same user is running never appear.

### `files/.config/nvim/lua/plugins/init.lua`

The `claude-nas-acp` ACP provider's `command` becomes `nas-acp-nvim`, and its
`env` gains `NAS_APPROVAL_NVIM_SERVER = vim.v.servername`. Passing the address
explicitly does not depend on how Avante spawns the process.

## Testing

`tests/nas-approval.bash`, in the same shape as `tests/git-stack.bash`, with
fake `nas` and `nvim` executables ahead of the real ones on `PATH`.

- `added`, `added`, `removed` push the counts 1, 2, 1 in that order.
- A push carries the domain, the session id, and the count.
- A session id outside the accepted shape ends the watcher before it subscribes.
- A repeated `added` for a request already pending pushes nothing.
- EOF pushes 0 and the watcher exits.
- A session id file that never appears ends the watcher at its timeout.
- The wrapper places `--write-session-id` ahead of the profile name, starts two
  watchers, and starts none when the server address is empty.

The Lua module has no automated test; it is verified by running the editor.

## Why — なぜこのアプローチを選んだか

承認の提示と応答を nas 側に残し、Neovim には件数しか渡さない。要求の表示、
スコープの選択肢、決定の送信はすべて `nas review` がすでに持っており、
複製すれば nas の変更に追随する義務を負う。件数だけなら nas の出力形式に
依存する範囲が `watch` の 2 フィールドに限られる。

購読を nas のラッパーに置いたのは、セッション id の受け渡しと購読の寿命が
そこで自然に閉じるからである。ラッパーが id ファイルのパスを決め、watcher に
渡し、nas に `--write-session-id` で書かせる。`--session` 付きの watch は
セッション終了で自走停止するので、後始末の仕組みを別に用意しなくてよい。

即座にプロンプトを開かず通知に留めたのは、承認が編集中の割り込みになるため。
エージェントは停止しているので、応答を遅らせても失うのは待ち時間だけである。

## Why Not — なぜ他の案を選ばなかったか

- **案 B: nvim の lua から watcher を job として起動する** — RPC が不要になる
  代わりに、セッション id ファイルの生成、購読の起動と停止、プロセスの後始末が
  すべて lua に載る。ACP セッションの開始を avante の内部から検知する必要も
  生じ、avante の実装に結合する。
- **案 C: 常駐 daemon（systemd user unit）で全セッションを購読する** — ターミナル
  起動の nas も拾える利点はあるが、要求をどの nvim に流すかを daemon が判断
  しなければならず、セッションと nvim の対応を別途持つことになる。今回の対象は
  avante から起動した 1 セッションなので、その複雑さに見合わない。
- **案 D: snacks picker で一覧と応答を自作する** — 見た目を nvim に揃えられるが、
  要求カードの描画とスコープの選択肢を nas と二重に持つことになる。とくに
  network の承認スコープは要求ごとに `approvalScopes` が変わるため、追随の
  コストが高い。セッションの絞り込みは `review --session` が持つので、
  自作する理由にもならない。
- **案 E: 要求が届いた時点で承認フロートを開く** — 応答までの時間は縮むが、
  編集中に割り込む。エージェントが待っている間の遅延は実害が小さい。
