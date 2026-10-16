---
description: Rewrite git history by modifying existing commits via interactive rebase. Use this skill whenever the user wants to edit, fix, or clean up past commits — for example removing lines from old commits, splitting a past commit into multiple meaningful commits, rewriting commit messages across multiple commits, or making surgical changes to specific commits in history. Triggers on phrases like "rebase", "edit commit", "fix that commit", "clean up history", "remove from old commit", "amend past commit", "split that commit", or any request that implies changing commits that aren't HEAD.
metadata:
    github-path: skills/git-rewrite
    github-ref: refs/heads/main
    github-repo: https://github.com/Hogeyama/agent-skills
    github-tree-sha: baf04f2c530b6705d22ebd4ec7b67982fc473128
name: git-rewrite
---
# Git History Rewrite via `git rebase -i`

## `GIT_SEQUENCE_EDITOR` + todo ファイルコピーパターン

todo リストをファイルにコピーし、Edit ツールで自由に編集してから rebase を実行する。
`sed` の正規表現や `pick`/`p` の揺れを気にする必要がない。

git は `GIT_SEQUENCE_EDITOR` を `sh -c` 経由で呼び出し、todo ファイルのパスを `$1` として渡す。

```bash
# 1. todo リストをコピーして rebase を中断（false で失敗させるので何も変更されない）
TODO=/path/to/todo  # スクラッチパッドのパスを使う
GIT_SEQUENCE_EDITOR='cp "$1" '"$TODO"'; false' git rebase -i <base>

# 2. $TODO を Edit ツールで編集（pick → edit, reword, drop, fixup 等に変更、行の並び替えも自由）

# 3. 編集済みの todo を使って rebase 実行
GIT_SEQUENCE_EDITOR='cp '"$TODO" git rebase -i <base>
```

### よくある操作の todo 編集例

```
# edit (内容変更): pick → edit に変更。停止後 → 修正 → git commit --amend --no-edit → git rebase --continue
edit abc1234 some commit message

# reword (メッセージ変更のみ): pick → reword に変更
reword abc1234 some commit message

# drop (コミット削除): pick → drop に変更、または行を削除
drop abc1234 some commit message

# fixup (直前のコミットに統合、メッセージ破棄): pick → fixup に変更
fixup abc1234 some commit message
```

## コミットの分割

1つの過去コミットを複数の意味あるコミットに分割したいときは、todo で対象を
`edit` にして停止させ、そこで `references/git-split.md` の手順に従う。

大まかな流れ: `edit` で対象コミットに停止 → `git reset HEAD^` でコミットを解く
→ `git split`（同梱ツール）で変更行を意味単位に配ってコミット → `git rebase --continue`。

`git add -p` の patch や行番号を手で書くより安全で速い。詳細な使い方・注意点・
同一行に複数意図が乗る場合の扱いは `references/git-split.md` を参照すること。

## 完了後: `git range-diff` の表示

リベースが成功したら、**必ず** `git range-diff` で旧コミットと新コミットの差分をユーザーに提示する。

リベース開始前に旧 HEAD のコミットハッシュを変数等で控えておき、完了後に以下のように比較する。

```bash
# リベース開始前
OLD_HEAD=$(git rev-parse HEAD)

# ... リベース実行 ...

# リベース完了後
git --no-pager range-diff <base>..$OLD_HEAD <base>..HEAD
```

* `<base>` はリベースの起点コミット（`git rebase -i <base>` で指定したもの）。
* `$OLD_HEAD` はリベース開始前に控えた旧 HEAD。
* これにより各コミットごとに何が変わったかが一目でわかる。

## Stale rebase の掃除

"rebase-merge directory" エラーが出たら:

```bash
git rebase --abort 2>/dev/null; rm -fr .git/rebase-merge 2>/dev/null
```
