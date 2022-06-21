import { log } from "./lib.ts";
import * as browser from "./mode/browserHistory.ts";
import * as buffer from "./mode/buffer.ts";
import * as fd from "./mode/fd.ts";
import * as mru from "./mode/mru.ts";
import * as rg from "./mode/rg.ts";
import * as zoxide from "./mode/zoxide.ts";
import * as browserR from "./runner/browser.ts";
import * as nvimR from "./runner/nvim.ts";
import * as vifmR from "./runner/vifm.ts";
import { Mode, Runner } from "./types.ts";

const prompt = (s: string) => `change-prompt[${s}>]`;
const clQuery = "clear-query";

export const fzfOpts = (prog: string) => {
  const mkBind = (ty: "execute" | "reload") =>
    (
      key: string,
      command: string | ((prog: string) => string),
      extraActions: string[],
    ): string[] => {
      const cmd = typeof command == "string" ? command : command(prog);
      const extra = extraActions.map((s) => `+${s}`).join("");
      return [`--bind`, `${key}:${ty}[${cmd}]${extra}`];
    };
  const simple = (xs: string[]) => xs;
  const exec = mkBind("execute");
  const reload = mkBind("reload");

  const binds = [
    simple([`--bind`, `ctrl-s:toggle-sort`]),
    exec("enter", `${prog} run default {}`, []),
    exec("ctrl-o", nvimR.cmd.default, []),
    exec("ctrl-t", nvimR.cmd.tabEdit, []),
    exec("ctrl-v", vifmR.cmd.default, []),
    reload("ctrl-r", `${prog} reload`, []),
    reload("ctrl-f", fd.cmd.default, [prompt("files")]),
    reload("ctrl-u", fd.cmd.cdUp, [prompt("files")]),
    reload("ctrl-l", fd.cmd.cdArg, [prompt("files"), clQuery]),
    reload("ctrl-n", fd.cmd.cdLastFile, [prompt("files"), clQuery]),
    reload("ctrl-b", buffer.cmd.default, [prompt("buffer")]),
    reload("ctrl-h", mru.cmd.default, [prompt("file-history")]),
    reload("ctrl-d", zoxide.cmd.default, [prompt("dir-history")]),
    reload("ctrl-g", rg.cmd.default, [prompt("grep"), clQuery]),
    reload("ctrl-i", browser.cmd.default, [prompt("browser-history"), clQuery]),
  ];
  log(binds);

  return ([] as string[])
    .concat(["--preview", `${prog} preview {}`])
    .concat(["--preview-window", "right:50%:noborder"])
    .concat(["--header-lines=1"])
    .concat(["--prompt", "files>"])
    .concat(binds.flat());
};

export const allRunners: Record<string, Runner> = {
  [nvimR.runner.name]: nvimR.runner,
  [vifmR.runner.name]: vifmR.runner,
  [browserR.runner.name]: browserR.runner,
};

export const allModes: Record<string, Mode> = {
  fd: fd.mode,
  rg: rg.mode,
  mru: mru.mode,
  buffer: buffer.mode,
  zoxide: zoxide.mode,
  "browser-history": browser.mode,
};
