{ pkgs }:
let
  src = pkgs.lib.sourceByRegex ./. [ "my-fzf.ts" ];
  myfzf = pkgs.writeScriptBin "myfzf" ''
    #!/usr/bin/env bash
    set -eu
    ${pkgs.deno}/bin/deno run \
      --allow-run \
      --allow-env \
      --allow-read \
      --allow-write \
      ${src}/my-fzf.ts
  '';
in
myfzf