---
name: crit-review
description: Open a Markdown document in a local crit session so the user can review it in the browser with line comments. Use when the user asks to review a document with crit.
user-invocable: true
argument-hint: '[file]'
---

# Crit Review

ローカルで crit を起動し、Markdown の文書をユーザーにブラウザでレビューしてもらう。crit は文書を整形して表示し、行や選択範囲にコメントを付けられる形で開く。ユーザーが Finish Review を押すとラウンドが終わり、コメントと承認可否がエージェントに戻る。

## 前提

`crit` が必要である。`which crit` で確認し、無ければユーザーに伝えて停止する。勝手にインストールを進めない。

## crit を直接起動しない

crit は crit.md へのアップロード、gh 経由の PR の問い合わせ、最新版の問い合わせで外に通信する。同梱の `scripts/critw` がこれらを起動時に潰し、起動後にデーモンの設定を検査する。crit を直接起動せず、critw を使う。

## スクリプト

このスキルディレクトリの `scripts/critw` を使う。以下では `critw` と表記する。

| コマンド | 用途 |
| --- | --- |
| `critw request-review <file>` | crit を起動して file を文書としてレビューに出す。URL を出力してから Finish Review まで待機し、終了時にコメントと承認可否を出力する。2 回目以降も同じコマンドで次のラウンドに入る |
| `critw report` | 直近の `request-review` が出した URL を表示する |
| `critw comments [--json]` | 未解決コメントを一覧する |
| `critw reply <comment-id>` | stdin の本文でコメントに返信する。resolve はしない |
| `critw down` | デーモンを止める |

`request-review` は Finish Review まで戻らないので、バックグラウンドで起動する。

## レビューの回し方

1. レビュー対象のファイルを確定する。呼び出し元から渡されていればそれを使う。単独で起動されてファイルの指定がなければ、ユーザーに確認する。推測しない
2. `critw request-review <file>` をバックグラウンドで起動する。URL が出るまで待ってから `critw report` で URL を読み、ユーザーに渡してレビューを依頼する。ブラウザはユーザーが開く
3. コマンドが終了したら、出力の `--- review result ---` 以降を読む。コメントが JSON で含まれ、`approved: true` は承認、`approved: false` はコメントありを意味する。途中で読み直したいときは `critw comments --json` を使う
4. 各コメントに対応する。修正が必要なら文書を修正し、`echo "<何をどう直したか>" | critw reply <id>` で返答する。質問なら同じ形で答える。resolve はしない。解決したかどうかはレビュアーが判断する
5. `critw request-review <file>` を再度起動する。文書の新しい版が保存され、前のラウンドの完了がブラウザに通知され、次の Finish Review まで待つ。手順 3 から繰り返す
6. `approved: true` が出たら承認とみなす。`critw down` でデーモンを止め、制御を返す

critw は作業ツリーのファイルをそのまま読むので、次のラウンドに進むために修正をコミットする必要はない。コミットするかどうか、いつするかは呼び出し元の方針に従う。

## Red Flags

- critw を使わずに crit を直接起動する
- `crit share`、`crit unpublish`、`crit auth` を実行する
- エージェントがコメントを resolve する
- `approved: true` が出る前に、承認されたものとして制御を返す
- 承認後に `critw down` を実行せず、デーモンを残したままにする
