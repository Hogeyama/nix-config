import { isString } from "https://deno.land/x/unknownutil@v2.0.0/is.ts";
import {
  nvrExpr,
  pathExists,
  previewFileOrDir,
  print,
  printHeader,
  RelPath,
} from "../lib.ts";
import { LoadImpl, ModeImpl } from "../types.ts";

const loadMru: LoadImpl = async (s, _opts) => {
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

export const mru: ModeImpl = {
  mode: "mru",
  load: loadMru,
  preview: previewFileOrDir,
  defaultRunner: "nvim",
  modifyRunnerArgs: {
    nvim: (_, args) => args,
  },
};
