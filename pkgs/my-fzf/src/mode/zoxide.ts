import { previewFileOrDir, printHeader } from "../lib.ts";
import { Load, Mode } from "../types.ts";

const loadZoxide: Load = async (s, _) => {
  printHeader(s);
  const p = Deno.run({
    cmd: ["zoxide"].concat(["query", "-l"]),
    cwd: s.cwd,
  });
  await p.status();
};

export const mode: Mode = {
  mode: "zoxide",
  load: loadZoxide,
  preview: previewFileOrDir,
  defaultRunner: "vifm",
  modifyRunnerArgs: {
    nvim: (_, args) => args,
    vifm: (s, _args) => {
      return { _: [s.cwd] };
    },
  },
};

export const cmd = {
  default: (prog: string) => `${prog} load zoxide`,
};
