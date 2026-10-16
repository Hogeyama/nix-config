#!/usr/bin/env bash
# スレッドの JSON を人間とエージェントが読める平文に整形する。
#
# 生の JSON では body の改行が \n に潰れてレビューコメントが読めないので、既定の
# 出力はこちらにする。

fj_format_threads() {
  jq -r '
    def indent($prefix):
      split("\n") | map(if . == "" then "" else $prefix + . end) | join("\n");
    def stamp: .[0:16] | sub("T"; " ");
    def clip($n):
      split("\n")
      | (if length > $n then .[0:$n] + ["… (\(length - $n) 行省略)"] else . end)
      | join("\n");
    def state:
      if .resolved then "resolved by \(.resolver)"
      elif .awaiting_reply then "返答待ち"
      else "open" end;
    def lines:
      if .extra_lines_count > 0 then "\(.line)-\(.line + .extra_lines_count)"
      else "\(.line)" end;

    if length == 0 then "reviewer がコメントしたスレッドはない"
    else
      [ .[]
        | "════════════════════════════════════════",
          "thread: \(.thread_id)  [\(state)]\(if .stale then "  (レビュー時点より head が進んでいる)" else "" end)",
          "at:     \(.path):\(lines) (\(.side))  commit=\(.commit_id[0:9])",
          "url:    \(.html_url)",
          ( if (.diff_hunk // "") == "" then empty
            else (.diff_hunk | clip(20) | indent("  │ ")) end),
          ( .comments[]
            | "",
              "── \(.author) (\(.created_at | stamp))",
              (.body | indent("  "))
          )
      ] | join("\n")
    end
  '
}

# 返答待ちのスレッドはユーザーへの報告時にそのまま提示する。どのスレッドに未対応が
# 残っているかをユーザーが覚えている前提を置かない。
fj_format_pending() {
  jq -r '
    def lines:
      if .extra_lines_count > 0 then "\(.line)-\(.line + .extra_lines_count)"
      else "\(.line)" end;
    map(select(.awaiting_reply)) as $p
    | if ($p | length) == 0 then empty
      else
        [ "",
          "──── 返答待ちのスレッド ────",
          ( $p[] | "thread \(.thread_id)  \(.path):\(lines)",
                   "      \(.html_url)" )
        ] | join("\n")
      end
  '
}
