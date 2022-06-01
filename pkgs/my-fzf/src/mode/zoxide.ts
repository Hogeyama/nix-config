import { previewFileOrDir, printHeader } from "../lib.ts";
import { LoadImpl, ModeImpl } from "../types.ts";

const loadZoxide: LoadImpl = async (s, opt) => {
  printHeader(s);
  const p = Deno.run({
    cmd: ["zoxide"].concat(
      ["query", "-l"],
      opt._.map((x) => x.toString()),
    ),
    cwd: s.cwd,
  });
  await p.status();
};

export const zoxide: ModeImpl<"zoxide"> = {
  mode: "zoxide",
  load: loadZoxide,
  preview: previewFileOrDir,
  defaultRunner: "vifm",
  modifyRunnerOpt: {
    nvim: (_, opt) => opt,
    vifm: (s, _opt) => {
      return { _: [s.cwd] };
    },
  },
};

