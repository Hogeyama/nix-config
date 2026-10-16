# git split による分割コミット

同一ファイル内の変更を複数コミットへ安全に分割するツール。`git add -p` と違い、
変更行を「安定 ID の選択」で指すため、patch や行番号を一切書かずに済む。
全サブコマンドが JSON を返し、多層の完全性チェック（ID 会計 / betweenness /
最終 tree 一致）が事故を拒否側に倒す。

rebase 中に過去コミットを複数コミットへ分割したくなったら、このリファレンスの
ワークフローを使う（末尾「rebase 中の過去コミット分割」を参照）。

## 前提確認

このツールは git-rewrite スキルに同梱されている。スキルの base directory（スキル
読み込み時に "Base directory for this skill: ..." として知らされる）配下の
`splitstage` パッケージを呼ぶ薄いラッパ `bin/git-split` を実行する:

```bash
GS="<git-rewrite スキルのbaseディレクトリ>/bin/git-split"
"$GS" status   # JSON が返れば利用可能 ("no session" エラーも利用可能の証拠)
```

python3 (3系であれば可) が実行環境にあれば、これ以外の準備は不要。
PATH に `bin/` を足せば以降のコマンド例を `git split start` のような表記の
ままでも実行できる。

## ワークフロー

```bash
"$GS" start            # セッション開始。全変更行に ID が振られる
                       # rebase 中や無関係な untracked がある場合は --tracked-only
"$GS" show --lines     # 変更行一覧 (id / t: "-"or"+" / text)。--file <path> で1ファイルに絞れる
"$GS" add <id> <id> …  # ID で選択。hunk ID (h:...) も可
                       # --file <path>   : そのファイルの残り全部
                       # --remaining      : 残り全部
                       # --except <id>…   : 指定 ID 以外 (包含が無ければ remaining がベース)
                       # --except-file <p>: そのファイル以外
"$GS" commit -m "..."  # 検証つき commit。残りが減っていく
# … 繰り返し …
"$GS" verify           # 最後に "complete": true を確認して終える
```

- 何かを add しても**残りの行の ID は変わらない**。最初の show の ID を使い続けてよい。
- 多数の行を配るときは ID を全部手で渡さなくてよい。「テストファイル以外を全部」なら
  `add --except-file tests/foo_test.py`、「このファイルだけ」なら `add --file src/foo.py`。
- `status` と `show` は同じ形の ID を返す。トップレベルに `staged_ids` /
  `remaining_ids` / `committed_ids`（フラット配列）、`files.<path>` に per-file の
  `kind` / `staged_ids` / `remaining_ids` / `unaligned`。あるファイルの残り ID は
  `files.<path>.remaining_ids` で直接引ける。
- 1つの論理変更（ある行の書き換え）は削除行 `-` と追加行 `+` のペア。**両方を同じコミットに入れる**。純粋な行追加・行削除には相方が無いので、その ID 単独で扱ってよい。ペアと単独が混ざったコミットでも、1回の `add` に全 ID をまとめて渡せばよい。
- `complete` が false のまま終えない。false なら `"$GS" status` で残りを確認して配り切る。
- `--tracked-only` は untracked を**すべて**対象外にする（分割に入れたい新規ファイルも見えなくなる）。対象に入れたい untracked ファイルがあるときは、start の**前に** `git add -N <path>` してから `--tracked-only` を使う。対象外にしたい untracked は何もせず放置でよい。
- 失敗したら `"$GS" abort` で分割前の状態（HEAD・index・worktree）に全復元できる。**入れ忘れや配り間違いに気づいたときも、`git split` の外で rebase や amend で直そうとせず、abort して最初からやり直す方が安全で速い**（外部での履歴修正は autostash 等で壊れやすい）。

## 同一行に複数の意図が乗っているとき（行の分配では表現できない分割）

例: `retry_limit = 1` → `max_retries = 2` を「rename」と「値変更」に分けたい。
中間状態 `max_retries = 1` はどちらの端点にも無いので、行 ID の選択では作れない。
このときは中間のファイル内容を丸ごと宣言する:

```bash
"$GS" set <path> --from /tmp/intermediate   # または heredoc で stdin から
"$GS" commit -m "rename retry_limit to max_retries"
```

`set` した内容は機械検証（betweenness）の対象外になるため、**中間状態が
意味的に正しいか（消してはいけない行を消していないか）は自分で確かめる**。
`git show HEAD:<path>` と worktree の現物を読み比べ、意図した変更だけを
適用した内容になっていることを確認してから commit すること。
`set` を使ったファイルは以後のコミットでも `set` で通す（行 ID には戻れない）。他のファイルへの `add` は通常どおり併用できる。

## 制限（守らないと詰む・壊れるもの）

- **worktree のファイルを編集しない**。分割中の編集は verify が `worktree` 違反として commit を拒否する。中間内容は必ずリポジトリ外の一時ファイルか stdin で渡す
- `.gitignore` にマッチするファイルは対象外。commit したい場合は start 前に `git add -f <path>`
- 末尾改行の無いファイルが変更に含まれると start が拒否する（このツールの既知の制限）
- **変更行を持たない変更は start が拒否する**。モードのみの変更（`chmod` だけ）、
  バイナリファイルの変更、空ファイルの新規作成・削除がこれにあたる。行 ID を振れず
  stage する手段が無いため。分割の前後で別コミットにして分割対象から外す
- 同一内容の変更行が複数あるときは、ファイル内で前にある方から順に add する（後ろだけ先に add すると拒否される）

## rebase 中の過去コミット分割

`git rebase -i` の `edit` で対象コミットに停止 → `git reset HEAD^` で
コミットを解く → 上記ワークフローで分割（**必ず `--tracked-only`**。
rebase と無関係な untracked を巻き込まないため）→ `git rebase --continue`。

rebase 自体の運転（todo の非対話編集、`edit` への書き換え、完了後の
range-diff 確認）は SKILL.md 本体の手順に従う。
