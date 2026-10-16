---
name: forgejo-review
description: Open a throwaway Forgejo PR so the user can review a commit range in the browser. Use when the user asks to review changes with Forgejo.
user-invocable: true
argument-hint: '[range]'
---

# Forgejo Review

使い捨ての Forgejo インスタンスを起動し、指定されたコミット範囲を1本の PR として提示する。ユーザーはブラウザから、PR 全体でも、コミット単位でもレビューできる。

## 前提

`forgejo` が必要である。`which forgejo` で確認し、無ければユーザーに伝えて停止する。勝手にインストールを進めない。

## スクリプト

このスキルディレクトリの `scripts/forgejow` を使う。以下では `forgejow` と表記する。

| コマンド | 用途 |
| --- | --- |
| `forgejow request-review <range>` | インスタンスを起動し、range を push して PR を用意する。PR とコミットごとの URL を出力し、Forgejo が停止するまで待機する |
| `forgejow report` | 直近の `request-review` が出したレビュー情報の全文を表示する |
| `forgejow fetch-comments [--json]` | スレッドを一括取得する。thread id の昇順、つまりユーザーが指摘を付けた順に並ぶ。既定は平文、`--json` で生の JSON |
| `forgejow push` | 修正コミットを push し、PR に加わったコミットの URL を出力する |
| `forgejow reply <thread-id>` | stdin の本文でスレッドに返信する |
| `forgejow resolve <thread-id>` | stdin の summary で返信してから resolve する |
| `forgejow down` | インスタンスを破棄する。セッションストアと認証情報は残す |

`request-review` は Forgejo が停止するまで戻らないので、バックグラウンドで起動する。

### 出力は `report` で読む

Claude Code ではバックグラウンドで走らせたコマンドの標準出力は、最後の1ブロックがプロセスの終了まで書き出されない。`request-review` は Forgejo が停止するまで戻らないため、その標準出力は必ず末尾が欠ける。

したがって、`request-review` の標準出力をそのまま読んではならない。PR の URL とログイン情報を得るには `forgejow report` を実行する。この内容は永続ディレクトリに残るので、インスタンスを落とした後でも読める。

## レビューの回し方

1. レビュー対象の range を確定する。呼び出し元から渡されていればそれを使う。単独で起動されて range の指定がなければ、ユーザーに確認する。推測しない
2. `forgejow request-review <range>` をバックグラウンドで起動する。PR が用意できるまで待ってから `forgejow report` で全文を取得し、PR URL とコミットごとの URL、ログイン情報をユーザーに提示する。`request-review` の標準出力は末尾が欠けるので読まない。URL を curl で叩いて疎通を確認しないこと。
3. ユーザーがコメントを付けて知らせてきたら、`forgejow fetch-comments` でスレッドを一括取得する
4. 各コメントに対応する（下記「修正はコミットして URL を返す」に従う）
5. どこを直せばよいか読み取れないコメントは、推測で修正せず `reply` で対象を確認する。推測で修正すると、ユーザーが求めていない変更がレビュー対象に混入する
6. resolve はユーザーが UI で実行する。エージェントは `fetch-comments` の `resolved` を見て判定する。ユーザーが明示的に resolve を指示した場合だけ `echo "<summary>" | forgejow resolve <thread-id>` を使う
7. `awaiting_reply` のスレッドが無くなったらユーザーに承認を求める。回答待ちのまま承認を求めると、意図が未確定の指摘を残したまま先に進んでしまう。ユーザーが追加コメントを付けた場合は 3 から 6 を繰り返す
8. ユーザーが承認を伝えたら `forgejow down` でインスタンスを破棄し、制御を返す

### 修正はコミットして URL を返す

指摘に応じて修正したら1コメント1コミットでコミットし、`push` してから `reply` の本文にその修正コミットの URL を含める。「修正しました」だけではユーザーは直ったかを確認できないが、リンクがあればその場で検証できる。修正しないと判断した場合も理由を返す。

```bash
<このスキルディレクトリ>/scripts/forgejow push
echo "<返信本文>" | <このスキルディレクトリ>/scripts/forgejow reply <thread-id>
```

コミットしても既存のスレッドは消えない。ユーザーが開いているタブもそのまま使えるので、URL を貼り直す必要はない。

## ログイン

`request-review` はログイン情報を毎回出力する。人間がログイン済みかをエージェント側から判定できないためである。セッションストアにはエージェント自身のセッションも入るので、ファイルの有無や個数では人間のログインを表せない。

一度ログインすれば、インスタンスを破棄しても以降のインスタンスでログインが維持される。セッションストアだけを永続ディレクトリに残しているためである。

## Red Flags

- 出力された URL を curl で叩いて疎通を確認する
- `request-review` の標準出力をそのまま読んで、末尾が欠けたレビュー情報をユーザーに渡す
- 返答待ち（`awaiting_reply`）のスレッドを残したままユーザーに承認を求める
- ユーザーの指示なしにエージェントがスレッドを resolve する
- 承認後に `forgejow down` を実行せず、インスタンスを残したままにする
- どこへの指摘か読み取れないコメントを、確認せず推測で修正する
- 複数の指摘への修正を1コミットにまとめる
