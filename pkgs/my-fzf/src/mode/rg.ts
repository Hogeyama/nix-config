import { batOpts, log, print, printHeader } from "../lib.ts";
import { LoadImpl, ModeImpl, Opt, State } from "../types.ts";

const parseRgItem = (opt: Opt) => {
  const item = opt._.at(0)?.toString();
  if (!item) {
    throw `parseRgItem: No item given`;
  }
  const file = item.split(":").at(0);
  if (!file) {
    throw `parseRgItem: Parse error: file not found: ${item}`;
  }
  const line = item.split(":").at(1);
  if (!line) {
    throw `parseRgItem: Parse error: line not found: ${item}`;
  }
  log({ item, line });
  return { file, line: Number(line) };
};

// Loader
const rgOpts = ([] as string[])
  .concat(["--column"])
  .concat(["--line-number"])
  .concat(["--no-heading"])
  .concat(["--color=never"])
  .concat(["--smart-case"]);

const loadRg: LoadImpl = async (s, opts) => {
  printHeader(s);
  const query = opts.query.toString();
  try {
    const p = Deno.run({
      cmd: ["rg"].concat(rgOpts, query),
      cwd: s.cwd,
    });
    await p.status();
  } catch (e) {
    log(e.toString());
    throw e;
  }
};

const previewRgItem = async (s: State, opt: Opt) => {
  const { file, line } = parseRgItem(opt);
  const start = Math.max(Number(line) - 15, 0);
  const batExtraOpts = [
    "--line-range",
    `${start}:`,
    "--highlight-line",
    `${line}`,
  ];
  print(`  [${file}]`);
  log(["bat"].concat(batOpts, batExtraOpts, [file]));
  await Deno.run({
    cmd: ["bat"].concat(batOpts, batExtraOpts, [file]),
    cwd: s.cwd,
  }).status();
  return;
};

export const rg: ModeImpl<"rg"> = {
  mode: "rg",
  load: loadRg,
  preview: previewRgItem,
  defaultRunner: "nvim",
  modifyRunnerOpt: {
    nvim: (_, opt) => {
      const { file, line } = parseRgItem(opt);
      return Object.assign(opt, { _: [file], line });
    },
    vifm: (s, _opt) => {
      return { _: [s.cwd] };
    },
  },
};
