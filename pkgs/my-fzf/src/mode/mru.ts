import { isString } from "https://deno.land/x/unknownutil@v2.0.0/is.ts";
import {
  nvrExpr,
  pathExists,
  previewFileOrDir,
  print,
  printHeader,
  RelPath,
} from "../lib.ts";
import { Load, Mode } from "../types.ts";

const loadMru: Load = async (s, _opts) => {
  printHeader(s);
  let tmp: string | undefined = undefined;
  try {
    tmp = Deno.makeTempFileSync();
    const rawMru = await nvrExpr(s, "json_encode(v:oldfiles)");
    (JSON.parse(rawMru) as unknown[])
      .filter(isString)
      .filter((x: string) => pathExists(s, RelPath(x)))
      .forEach(print);
  } finally {
    tmp && Deno.removeSync(tmp);
  }
};

export const mode: Mode = {
  mode: "mru",
  load: loadMru,
  preview: previewFileOrDir,
  defaultRunner: "nvim",
  modifyRunnerArgs: {
    nvim: (_, args) => args,
  },
};

export const cmd = {
  default: (prog: string) => `${prog} load mru`,
};
