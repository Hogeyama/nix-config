import { browserHistory } from "./mode/browserHistory.ts";
import { buffer } from "./mode/buffer.ts";
import { fd } from "./mode/fd.ts";
import { mru } from "./mode/mru.ts";
import { rg } from "./mode/rg.ts";
import { zoxide } from "./mode/zoxide.ts";
import { runBrowser } from "./runner/browser.ts";
import { runNvim } from "./runner/nvim.ts";
import { runVifm } from "./runner/vifm.ts";
import { Mode, Runner } from "./types.ts";

export const fzfOpts = (myfzf: string) =>
  ([] as string[])
    .concat(["--preview", `${myfzf} preview {}`])
    .concat(["--preview-window", "right:50%:noborder"])
    .concat(["--header-lines=1"])
    .concat(["--prompt", "files>"])
    .concat([
      `--bind`, //
      `enter:execute[${myfzf} run default {}]`,
    ])
    .concat([
      `--bind`, //
      `ctrl-o:execute[${myfzf} run nvim {}]`,
    ])
    .concat([
      `--bind`, //
      `ctrl-t:execute[${myfzf} run nvim {} --tab ]`,
    ])
    .concat([
      `--bind`, //
      `ctrl-v:execute[${myfzf} run vifm {}]`,
    ])
    .concat([
      `--bind`, //
      `ctrl-f:reload[${myfzf} load fd]+change-prompt[files>]`,
    ])
    .concat([
      `--bind`, //
      `ctrl-u:reload[${myfzf} load fd --cd-up]+change-prompt[files>]`,
    ])
    .concat([
      `--bind`, //
      `ctrl-l:reload[${myfzf} load fd --cd {}]+change-prompt[files>]+clear-query`,
    ])
    .concat([
      `--bind`, //
      `ctrl-n:reload[${myfzf} load fd --cd-last-file]+change-prompt[files>]+clear-query`,
    ])
    .concat([
      `--bind`, //
      `ctrl-b:reload[${myfzf} load buffer]+change-prompt[buffer>]`,
    ])
    .concat([
      `--bind`, //
      `ctrl-h:reload[${myfzf} load mru]+change-prompt[file-history>]`,
    ])
    .concat([
      `--bind`, //
      `ctrl-d:reload[${myfzf} load zoxide]+change-prompt[dir-history>]`,
    ])
    .concat([
      `--bind`, //
      `ctrl-g:reload[${myfzf} load rg --query {q}]+clear-query+change-prompt[grep>]`,
    ])
    .concat([
      `--bind`, //
      `ctrl-i:reload[${myfzf} load browser-history {q}]+clear-query+change-prompt[browser-history>]`,
    ])
    .concat([
      `--bind`, //
      `ctrl-r:reload[${myfzf} reload]`,
    ])
    .concat([
      `--bind`, //
      `ctrl-s:toggle-sort`,
    ]);

export const allRunners: Record<string, Runner> = {
  nvim: runNvim,
  vifm: runVifm,
  browser: runBrowser,
};

export const allModes: Record<string, Mode> = {
  fd,
  rg,
  mru,
  buffer,
  zoxide,
  "browser-history": browserHistory,
};
