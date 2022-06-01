{ pkgs }:
let
  src = pkgs.lib.sourceByRegex ./. [ "src.*" ];
  myfzf = pkgs.writeScriptBin "myfzf" ''
    #!/usr/bin/env bash
    set -eu
    export MY_FZF_PROG=$(realpath "$0")
    ${pkgs.deno}/bin/deno run \
      --no-check \
      --allow-run \
      --allow-env \
      --allow-read \
      --allow-write \
      ${src}/src/main.ts "$@"
  '';
in
myfzf
