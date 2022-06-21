import { log, nvrExpr, previewFileOrDir, print } from "../lib.ts";
import { Load, Mode, Preview } from "../types.ts";
import { isLike } from "https://deno.land/x/unknownutil@v2.0.0/is.ts";

type Diagnostic = {
  lnum: number;
  col: number;
  message: string;
  severity: 1 | 2 | 3 | 4;
};

export const diagnosticExample: Diagnostic = {
  lnum: 28,
  col: 2,
  severity: 1,
  message: "Cannot find name 'x'.",
  // [unused]
  // end_lnum: 28,
  // end_col: 3,
  // bufnr: 44,
  // source: "deno-ts",
  // namespace: 8,
  // code: 2304,
};

function isDiagnostics(v: unknown): v is Diagnostic {
  // unsafe: severity out of range
  return isLike(diagnosticExample, v);
}

export const severityMap = {
  1: "E",
  2: "W",
  3: "I",
  4: "H",
};

const loadDiagnostics: Load = async (s, _args) => {
  const file = (await nvrExpr(s, "g:last_file")).trimEnd();
  print(`[${file}]`);
  const rawDiagnostics = await nvrExpr(
    s,
    "luaeval('vim.fn.json_encode(vim.diagnostic.get(vim.g.last_buf))')",
  );
  const diagnostics = (JSON.parse(rawDiagnostics) as unknown[])
    .filter(isDiagnostics);
  log({ diagnostics });
  const lnumMaxLen = Math.max(
    // +1 because diagnostic is 0-based
    ...diagnostics.map((d) => `${d.lnum + 1}`.length),
  );
  const colMaxLen = Math.max(
    ...diagnostics.map((d) => `${d.col + 1}`.length),
  );
  diagnostics.forEach((d) => {
    const severity = severityMap[d.severity];
    const lnum = `${d.lnum + 1}`.padStart(lnumMaxLen);
    const col = `${d.col + 1}`.padStart(colMaxLen);
    const message = d.message.replace(/\n/g, " ");
    print(`${severity}:${lnum}:${col}| ${message}`);
  });
};

const parseDiagnosticItem = (arg: string): { lnum: number; col: number } => {
  const [lnum, col] = arg
    .substring(2) // severity + :
    .split("|")[0] // drop message
    .split(":")
    .map((s) => Number(s.trimStart()));
  return { lnum, col };
};

const previewDiagnosticItem: Preview = async (s, args) => {
  const rawItem = args._.at(0)?.toString();
  const file = (await nvrExpr(s, "g:last_file")).trimEnd();
  if (rawItem) {
    const { lnum: highlightLine } = parseDiagnosticItem(rawItem);
    const line = Math.max(Number(highlightLine) - 15, 0);
    await previewFileOrDir(s, { _: [file], line, highlightLine });
  }
};

export const mode: Mode = {
  mode: "diagnostics",
  load: loadDiagnostics,
  preview: previewDiagnosticItem,
  defaultRunner: "nvim",
  modifyRunnerArgs: {
    nvim: {
      async_: async (s, args) => {
        const rawItem = args._.at(0)?.toString();
        if (rawItem) {
          const file = await nvrExpr(s, "g:last_file");
          const { lnum } = parseDiagnosticItem(rawItem);
          return Object.assign(args, { _: [file.trimEnd()], line: lnum });
        } else {
          throw `diagnostic: preview: No item given`;
        }
      },
    },
  },
};

export const cmd = {
  default: (prog: string) => `${prog} load diagnostics`,
};
