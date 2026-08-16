#!/bin/sh
# アプリは起動のたびに resources/plugins を ~/.codex/.tmp/bundled-marketplaces/ へ
# fs.cp(recursive) でコピーするが、fs.cp は mode を保持する。store のファイルは常に
# 444/555 に正規化されるためコピー先も読み取り専用になり、直後にその中へ
# plugin.json を書こうとして EACCES で落ちる。書けなかった staging ディレクトリは
# rm -rf もできずに残り続けるので、放置すると起動そのものが壊れる。
#
# そこで書き込み可能な mode で複製したものをキャッシュに置き、アプリにはそちらを
# 読ませる。この上書き用の環境変数は app.asar 内の main bundle が解釈する。
set -eu

cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/chatgpt"
resources="$cache_root/@name@"

if [ ! -e "$resources/.stamp" ]; then
  rm -rf "$resources"
  mkdir -p "$resources"
  cp -R --no-preserve=mode,ownership "@app@/resources/plugins" "$resources/plugins"
  chmod -R u+w "$resources"
  : > "$resources/.stamp"
  # 旧バージョンのキャッシュを掃除する
  for stale in "$cache_root"/*; do
    [ "$stale" = "$resources" ] || rm -rf "$stale"
  done
fi

export CODEX_ELECTRON_BUNDLED_PLUGINS_RESOURCES_PATH="$resources"
exec "@app@/ChatGPT" "$@"
