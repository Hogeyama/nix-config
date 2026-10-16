#!/usr/bin/env bash
# Forgejo の API と web エンドポイントの薄いラッパ。
#
# 既存スレッドへの返信と resolve は公開 API に無いので web エンドポイントを使う。
# 文書化されていない経路なので、request-review の初期化時にスモークテストで
# 疎通を確かめる。

fj_api() {
  local method="$1" path="$2"
  shift 2
  curl -sS -X "$method" \
    -H "Authorization: token $(fj_token)" \
    -H 'Content-Type: application/json' \
    "http://localhost:$(fj_port)/api/v1$path" "$@"
}

fj_login_agent() {
  local jar
  jar="$(fj_run_dir)/cookies-agent"
  [ -s "$jar" ] && return 0
  fj_credentials
  # Forgejo 16 のログインフォームは CSRF トークンを要求しない。
  curl -sS -c "$jar" -o /dev/null \
    -d "user_name=agent&password=$FJ_AGENT_PASS" \
    "http://localhost:$(fj_port)/user/login"
  [ -s "$jar" ] || { fj_die "agent のログインに失敗した"; return 1; }
}

# web エンドポイントを叩き、HTTP ステータスだけを出力する。
fj_web() {
  local method="$1" path="$2"
  shift 2
  fj_login_agent || return 1
  curl -sS -X "$method" -b "$(fj_run_dir)/cookies-agent" -o /dev/null -w '%{http_code}' \
    "http://localhost:$(fj_port)$path" "$@"
}

# 返信と resolve は文書化されていない web エンドポイントに依存するため、Forgejo の
# バージョン更新で壊れうる。壊れたまま進むと、指摘に返信できないままレビューが
# 成立したように見える。スクラッチリポジトリで1往復して疎通を確かめ、駄目ならその場で
# 止める。起動が1秒台なので毎回実行しても支障はない。
#
# FJ_SMOKE_REPLY_PATH はテストで経路を差し替えるためにだけ使う。
fj_smoke() {
  local repo=agent/_forgejow_smoke work rc=0 head_sha pr rid cid before after code holders resolver url
  fj_api DELETE "/repos/$repo" >/dev/null 2>&1
  fj_api POST /user/repos -d '{"name":"_forgejow_smoke","auto_init":false,"private":true}' \
    >/dev/null || { fj_die "スモーク用リポジトリを作れない"; return 1; }

  # push 先の URL は cd する前に確定させる。fj_run_dir はカレントのリポジトリの
  # パスから引くので、別リポジトリに cd した後ではポートもトークンも取れない。
  url="http://agent:$(fj_token)@localhost:$(fj_port)/$repo.git"
  work="$(mktemp -d)"
  (
    set -e
    cd "$work"
    git init -q -b main
    git config user.email smoke@review.invalid
    git config user.name smoke
    git config commit.gpgsign false
    printf 'a\n' >f.txt
    git add -A && git commit -qm base
    git push -q -f "$url" HEAD:refs/heads/smoke-base
    printf 'a\nb\n' >f.txt
    git add -A && git commit -qm change
    git push -q -f "$url" HEAD:refs/heads/smoke-head
  ) >/dev/null 2>&1 || rc=1
  head_sha="$(git -C "$work" rev-parse HEAD 2>/dev/null)"
  rm -rf "$work"
  if [ "$rc" != 0 ]; then
    fj_api DELETE "/repos/$repo" >/dev/null 2>&1
    fj_die "スモークの push に失敗した"
    return 1
  fi

  for _ in $(seq 1 40); do
    fj_api GET "/repos/$repo/branches/smoke-head" | jq -e '.name' >/dev/null 2>&1 && break
    sleep 0.25
  done

  pr="$(fj_api POST "/repos/$repo/pulls" \
    -d '{"head":"smoke-head","base":"smoke-base","title":"smoke","body":"smoke"}' |
    jq -r '.number // empty')"
  if [ -z "$pr" ]; then
    fj_api DELETE "/repos/$repo" >/dev/null 2>&1
    fj_die "スモーク用 PR を作れない"
    return 1
  fi
  # 複数行コメント (1-2行目) にする。返信が範囲を引き継げないと UI で別スレッドに
  # 分かれるので、その経路まで含めて疎通を確かめる。
  rid="$(fj_api POST "/repos/$repo/pulls/$pr/reviews" \
    -d '{"event":"COMMENT","comments":[{"path":"f.txt","new_position":1,"extra_lines_count":1,"body":"smoke"}]}' |
    jq -r '.id // empty')"
  cid="$(fj_api GET "/repos/$repo/pulls/$pr/reviews/$rid/comments" | jq -r '.[0].id // empty')"
  if [ -z "$rid" ] || [ -z "$cid" ]; then
    fj_api DELETE "/repos/$repo" >/dev/null 2>&1
    fj_die "スモーク用のレビューコメントを作れない"
    return 1
  fi
  before="$(fj_api GET "/repos/$repo/pulls/$pr/reviews/$rid/comments" | jq 'length')"

  code="$(fj_web POST "${FJ_SMOKE_REPLY_PATH:-/$repo/pulls/$pr/files/reviews/comments}" \
    --data-urlencode "origin=diff" \
    --data-urlencode "latest_commit_id=$head_sha" \
    --data-urlencode "side=proposed" \
    --data-urlencode "line=1" \
    --data-urlencode "extra_lines_count=1" \
    --data-urlencode "path=f.txt" \
    --data-urlencode "reply=$rid" \
    --data-urlencode "content=smoke reply")"
  after="$(fj_api GET "/repos/$repo/pulls/$pr/reviews/$rid/comments" | jq 'length')"
  if [ "$after" -le "$before" ]; then
    fj_api DELETE "/repos/$repo" >/dev/null 2>&1
    fj_die "返信のエンドポイントが機能しない (HTTP $code)。forgejo $(fj_version) で経路が変わった可能性がある"
    return 1
  fi
  # review への追加だけでは足りない。表示行 (行 + extra_lines_count) が揃わないと
  # ブラウザは同じ review でも別の会話として描画する。人間が見る HTML そのもので、
  # 会話が1つのままであることを確かめる。
  holders="$(curl -sS -b "$(fj_run_dir)/cookies-agent" \
    "http://localhost:$(fj_port)/$repo/pulls/$pr/files" |
    grep -o 'class="conversation-holder"' | wc -l)"
  if [ "$holders" != 1 ]; then
    fj_api DELETE "/repos/$repo" >/dev/null 2>&1
    fj_die "返信が UI 上で別スレッドに分かれる (conversation-holder が $holders 個)。forgejo $(fj_version) で会話の分け方が変わった可能性がある"
    return 1
  fi

  code="$(fj_web POST "/$repo/issues/resolve_conversation" \
    --data-urlencode "origin=diff" --data-urlencode "action=Resolve" \
    --data-urlencode "comment_id=$cid")"
  resolver="$(fj_api GET "/repos/$repo/pulls/$pr/reviews/$rid/comments" |
    jq -r '.[0].resolver.login // "null"')"
  fj_api DELETE "/repos/$repo" >/dev/null 2>&1
  if [ "$resolver" = null ]; then
    fj_die "resolve のエンドポイントが機能しない (HTTP $code)。forgejo $(fj_version) で経路が変わった可能性がある"
    return 1
  fi
}

fj_version() { forgejo --version | awk '{print $3}'; }

fj_repo_name() { basename "$(fj_repo_root)"; }

fj_ensure_repo() {
  local name owner=agent
  name="$(fj_repo_name)"
  if ! fj_api GET "/repos/$owner/$name" | jq -e '.id' >/dev/null 2>&1; then
    # public にするのは、出力した URL を認証なしで開けるようにするためである。
    # private だと匿名 GET が 404 を返す。エージェントは提示した URL の疎通を curl で
    # 確かめるので、仕様どおりの 404 を故障と誤認して原因調査を始めてしまう。
    #
    # public にすると localhost のポートに届く任意のリクエストがソースを読める。ただし
    # reviewer のパスワードを固定値にしている時点で、同じマシンの他ユーザーはログイン
    # して読めるため、追加のリスクは小さい。コメントの投稿には引き続きログインが必要で、
    # 行コメントのボタンは匿名では描画されない。
    fj_api POST /user/repos \
      -d "$(jq -nc --arg n "$name" '{name: $n, auto_init: false, private: false}')" \
      >/dev/null
    # reviewer が自分のスレッドを resolve するには write 権限が必要になる。
    # Forgejo は resolve ボタンの表示条件に write を要求する。
    fj_api PUT "/repos/$owner/$name/collaborators/reviewer" \
      -d '{"permission":"write"}' >/dev/null
  fi
  echo "$owner/$name"
}

fj_push_url() {
  echo "http://agent:$(fj_token)@localhost:$(fj_port)/$(fj_ensure_repo).git"
}

# base をレビュー用のブランチとして、head を作業ブランチ名で push する。
# 実リポジトリに remote を追加しないため URL を直接指定する。レビュー用の
# 一時的な forge がユーザーの git config に痕跡を残さないようにする。
fj_push_range() {
  local range="$1" base head branch url run
  base="$(git rev-parse "${range%%..*}")" || { fj_die "base ref を解決できない: $range"; return 1; }
  head="$(git rev-parse "${range##*..}")" || { fj_die "head ref を解決できない: $range"; return 1; }
  branch="$(git symbolic-ref -q --short HEAD || echo review-head)"
  url="$(fj_push_url)"
  git push -q -f "$url" "$base:refs/heads/review-base" ||
    { fj_die "base の push に失敗した"; return 1; }
  git push -q -f "$url" "$head:refs/heads/$branch" ||
    { fj_die "head の push に失敗した"; return 1; }
  run="$(fj_run_dir)"
  echo "$branch" >"$run/branch"
  echo "$base" >"$run/base"
  echo "$head" >"$run/head"

  # push の完了と DB への反映は同期しない。反映前のリポジトリは empty 扱いのままで
  # PR 系のエンドポイントが 404 を返すので、ブランチが見えるまで待つ。
  fj_wait_branch review-base || return 1
  fj_wait_branch "$branch" || return 1
}

# 修正コミットを push する。前回 push した head から HEAD までを新規分として報告
# する。Forgejo は PR head を即座に追随させ、修正コミット自体が同じ PR のレビュー
# 対象コミットとして加わるので、レビュー用の URL を貼り直す必要がない。
fj_push_head() {
  local run prev head branch
  run="$(fj_run_dir)"
  prev="$(cat "$run/head")"
  head="$(git rev-parse HEAD)"
  branch="$(fj_branch)"
  git push -q -f "$(fj_push_url)" "HEAD:refs/heads/$branch" ||
    { fj_die "push に失敗した"; return 1; }
  echo "$head" >"$run/head"
  [ "$prev" = "$head" ] && return 0
  fj_wait_commit_in_pr "$head" || return 1
  # 完全な SHA を返す。呼び出し側が per-commit URL を組むので、短縮では 404 になる。
  git log --reverse --format='%H' "$prev..$head"
}

# push した head が PR に反映されるまで待つ。反映前に URL を返すと、ユーザーが開いた
# ときにその修正コミットがまだ PR に無い。
#
# head.sha の一致では足りない。PR の head が更新された後もコミット一覧の反映は
# 遅れるため、一覧に現れることまで確かめる。ユーザーが見るのは一覧の側である。
fj_wait_commit_in_pr() {
  local sha="$1" repo pr
  repo="$(fj_ensure_repo)"
  pr="$(fj_pr_num)"
  for _ in $(seq 1 40); do
    fj_api GET "/repos/$repo/pulls/$pr/commits?limit=100" |
      jq -e --arg s "$sha" 'type == "array" and any(.[]; .sha == $s)' >/dev/null 2>&1 && return 0
    sleep 0.25
  done
  fj_die "push した $sha が PR のコミット一覧に現れない"
}

fj_wait_branch() {
  local branch="$1" repo
  repo="$(fj_ensure_repo)"
  for _ in $(seq 1 40); do
    fj_api GET "/repos/$repo/branches/$branch" | jq -e '.name' >/dev/null 2>&1 && return 0
    sleep 0.25
  done
  fj_die "ブランチ $branch が Forgejo 側に現れない"
}

fj_branch() { cat "$(fj_run_dir)/branch"; }

# body にレビュー対象の range を残す。PR を開いた人が、どの範囲を見ればよいかを
# コミット一覧から逆算せずに済ませるためである。
fj_ensure_pr() {
  local range="$1" repo branch existing
  repo="$(fj_ensure_repo)"
  branch="$(fj_branch)"
  existing="$(fj_api GET "/repos/$repo/pulls?state=open" |
    jq -r --arg b "$branch" 'map(select(.head.ref == $b)) | .[0].number // empty')"
  if [ -n "$existing" ]; then
    echo "$existing"
    return 0
  fi
  fj_api POST "/repos/$repo/pulls" \
    -d "$(jq -nc --arg b "$branch" --arg r "$range" '{head: $b, base: "review-base",
          title: "実装ブランチのレビュー", body: "レビュー対象: \($r)"}')" |
    jq -r '.number'
}

fj_pr_num() { cat "$(fj_run_dir)/pr"; }

# PR の作成直後は Forgejo が patch check を非同期で走らせるため、commits などの
# エンドポイントが一時的に 404 を返す。ここで待たないと、直後にレビュー対象を
# 参照する処理が対象を見つけられずに失敗する。
fj_wait_pr_ready() {
  local pr="$1" repo
  repo="$(fj_ensure_repo)"
  for _ in $(seq 1 40); do
    if fj_api GET "/repos/$repo/pulls/$pr/commits" | jq -e 'type == "array"' >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.25
  done
  fj_die "PR $pr が準備できない"
}

fj_pr_url() {
  echo "http://localhost:$(fj_port)/$(fj_ensure_repo)/pulls/$(fj_pr_num)"
}

fj_commit_url() {
  echo "$(fj_pr_url)/commits/$1"
}

# 返信は公開 API では作れない。同じ path/line に API で投稿すると会話が review 単位
# で分かれるため別スレッドとして表示されてしまう。web エンドポイントに
# reply=<review_id> を渡して同一スレッドに入れる。
#
# line と extra_lines_count はスレッドの先頭コメントの値をそのまま引き継ぐ。UI の
# 返信フォームも同じことをする (templates/repo/diff/comment_form_datahandler.tmpl)。
# Forgejo は会話を (path, side, 表示行 = line + extra_lines_count) で分けるので、
# extra_lines_count を落とすと同じ review に入っても UI では別スレッドとして描画される。
# line は符号なしで渡す。previous 側の符号はハンドラが side から復元するため、
# 負数を渡すと二重に反転して proposed 側に付く。
fj_reply() {
  local tid="$1" body="$2" t code
  t="$(fj_threads | jq -c --argjson id "$tid" '.[] | select(.thread_id == $id)')"
  [ -n "$t" ] || { fj_die "thread $tid が見つからない"; return 1; }
  code="$(fj_web POST "/$(fj_ensure_repo)/pulls/$(fj_pr_num)/files/reviews/comments" \
    --data-urlencode "origin=diff" \
    --data-urlencode "latest_commit_id=$(cat "$(fj_run_dir)/head")" \
    --data-urlencode "side=$(printf '%s' "$t" | jq -r '.side')" \
    --data-urlencode "line=$(printf '%s' "$t" | jq -r '.line')" \
    --data-urlencode "extra_lines_count=$(printf '%s' "$t" | jq -r '.extra_lines_count')" \
    --data-urlencode "path=$(printf '%s' "$t" | jq -r '.path')" \
    --data-urlencode "reply=$(printf '%s' "$t" | jq -r '.review_id')" \
    --data-urlencode "content=$body")"
  case "$code" in
    2*) return 0 ;;
    *) fj_die "返信に失敗した (HTTP $code)"; return 1 ;;
  esac
}

fj_resolve() {
  local tid="$1" code
  code="$(fj_web POST "/$(fj_ensure_repo)/issues/resolve_conversation" \
    --data-urlencode "origin=diff" \
    --data-urlencode "action=Resolve" \
    --data-urlencode "comment_id=$tid")"
  case "$code" in
    2*) return 0 ;;
    *) fj_die "resolve に失敗した (HTTP $code)"; return 1 ;;
  esac
}

# 会話は Forgejo の UI と同じく (review, path, side, 表示行) で決まる。表示行は範囲の
# 末尾、つまり行 + extra_lines_count である (models/issues/comment.go の DisplayLine)。
# 単一行コメントでも、表示行が複数行コメントの末尾と一致すれば UI は同じ会話に描画
# するので、ここでも同じキーでまとめる。先頭コメントの id を thread_id として扱う。
# 返信は review_id と (line, extra_lines_count, side) を、resolve は先頭コメント id を
# 要求するので、どれもここから引ける。
#
# API の position と original_position はどちらも符号なしのファイル行番号で、
# proposed 側は position、previous 側は original_position に入る (もう一方は 0)。
#
# PENDING のレビューは投稿者にしか見えない下書きなので除外する。
#
# 出力は thread_id の昇順に揃える。id は Forgejo が発行するコメント id なので、この順は
# reviewer が指摘を付けた順になる。整列しない場合の順序は review の取得順と
# group_by に従うため、同一 review 内で後から付けた指摘が先に並ぶ。
# 読み手はレビューを書かれた順に追うので、その順序を出力でも保つ。
fj_threads() {
  local repo pr rid stale
  repo="$(fj_ensure_repo)"
  pr="$(fj_pr_num)"
  fj_api GET "/repos/$repo/pulls/$pr/reviews" |
    jq -r '.[] | select(.state != "PENDING") | select(.comments_count > 0)
           | "\(.id)\t\(.stale)"' |
  while IFS=$'\t' read -r rid stale; do
    fj_api GET "/repos/$repo/pulls/$pr/reviews/$rid/comments" |
      jq --arg rid "$rid" --arg stale "$stale" '
        [ .[]
          | {rid: $rid, stale: ($stale == "true"), c: .}
          | .side = (if .c.original_position > 0 then "previous" else "proposed" end)
          | .line = (if .side == "previous" then .c.original_position else .c.position end)
          | .display = ((.line + .c.extra_lines_count)
                        * (if .side == "previous" then -1 else 1 end))
        ]
        | group_by([.c.path, .display])
        | map(
            (. | sort_by(.c.id)) as $g
            | ($g[0]) as $first
            | ($g[-1]) as $last
            | {
                thread_id: $first.c.id,
                review_id: ($first.rid | tonumber),
                path: $first.c.path,
                line: $first.line,
                extra_lines_count: $first.c.extra_lines_count,
                side: $first.side,
                commit_id: $first.c.commit_id,
                stale: $first.stale,
                resolved: ($first.c.resolver != null),
                resolver: ($first.c.resolver.login // null),
                awaiting_reply: (($first.c.resolver == null) and ($last.c.user.login == "reviewer")),
                html_url: $first.c.html_url,
                diff_hunk: $first.c.diff_hunk,
                comments: [ $g[] | {author: .c.user.login, created_at: .c.created_at, body: .c.body} ]
              }
          )'
  done | jq -s 'add // [] | sort_by(.thread_id)'
}
