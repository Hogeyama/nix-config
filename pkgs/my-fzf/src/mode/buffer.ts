// 必要そうなフィールドだけ定義する。

import { isLike } from "https://deno.land/x/unknownutil@v2.0.0/is.ts";
import {
  AbsPath,
  nvrExpr,
  pathExists,
  previewFileOrDir,
  print,
  printHeader,
  unsafeAbsPath,
} from "../lib.ts";
import { Load, Mode, Preview } from "../types.ts";

// 各フィールドについては :h getbufinfo() を参照。
type NvimBuffer = {
  bufnr: number;
  changed: number;
  lastused: number;
  lnum: number;
  name: string;
  // changedtick: number;
  // hidden: number;
  // linecount: number;
  // listed: number;
  // loaded: number;
  // signs: unknown[];
  // variables: unknown[];
  // windows: number[];
};

const bufferExample: NvimBuffer = {
  "bufnr": 2,
  "changed": 0,
  "lastused": 16528747810,
  "lnum": 1,
  "name": "/tmp/foo.md",
};

function isNvimBuffer(v: unknown): v is NvimBuffer {
  return isLike(bufferExample, v);
}

const loadBuffer: Load = async (s, _opts) => {
  printHeader(s);
  // variables に function が入っていることがあり、json_encode が失敗する。
  // →必要なフィールドだけを取り出すことにする。
  const rawBuffers = await nvrExpr(
    s,
    "json_encode(map(getbufinfo(),{_,v->filter(v,{k->index(['bufnr','name','changed','lastused','lnum'],k)>=0})}))",
  );
  (JSON.parse(rawBuffers) as unknown[])
    .filter(isNvimBuffer)
    .filter((b) =>
      !b.name.startsWith("term://") &&
      b.name != "" &&
      JSON.stringify(b.name) == `"${b.name}"`
    ).forEach((b) => {
      const bufnr = b.bufnr.toString().padStart(3);
      const name = b.name;
      const lnum = b.lnum;
      print(`${bufnr}:${name}:${lnum}`);
    });
};

type BufferItem = { path: AbsPath; bufnum: number; line: number };

const parseBufferItem = (item: string): BufferItem => {
  const delim = ":";
  const firstIx = item.indexOf(delim);
  const lastIx = item.lastIndexOf(delim);
  const bufnum = Number(item.slice(0, firstIx));
  // getbufinfo() が full path を返すことは保証されている
  const path = unsafeAbsPath(item.slice(firstIx + 1, lastIx));
  const line = Number(item.slice(lastIx + 1));
  return { bufnum, path, line };
};

const previewBuffer: Preview = async (s, args) => {
  const rawItem = args._.at(0)?.toString();
  if (rawItem) {
    const { path, line } = parseBufferItem(rawItem);
    if (pathExists(s, path)) {
      await previewFileOrDir(s, { _: [path.val], line });
    }
  }
};

export const mode: Mode = {
  mode: "buffer",
  load: loadBuffer,
  preview: previewBuffer,
  defaultRunner: "nvim",
  modifyRunnerArgs: {
    nvim: (_, args) => {
      const rawItem = args._.at(0)?.toString();
      if (rawItem) {
        const item = parseBufferItem(rawItem);
        return Object.assign(args, { buf: item.bufnum });
      } else {
        throw `buffer: No item given`;
      }
    },
  },
};

export const cmd = {
  default: (prog: string) => `${prog} load buffer`,
};
