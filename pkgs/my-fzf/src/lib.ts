import { Args, Preview, State } from "./types.ts";
import * as Path_ from "https://deno.land/std@0.133.0/path/mod.ts";

export const getProgName = () => {
  return Deno.env.get("MY_FZF_PROG") || (() => {
    throw "MY_FZF_PROG";
  })();
};

// deno-lint-ignore no-explicit-any
export const log = (s: any, raw = false) => {
  const logFile = "/tmp/myfzf.log";
  const fp = Deno.openSync(logFile, {
    write: true,
    append: true,
    create: true,
  });
  try {
    const str = raw ? s : new TextEncoder().encode(JSON.stringify(s) + "\n");
    fp.writeSync(str);
  } finally {
    fp.close();
  }
};

// deno-lint-ignore no-explicit-any
export const xlog = (_s: any, _raw = false) => {};

export const getOrCreateStateFile = (): {
  stateFile: string;
  created: boolean;
} => {
  const stateFile = Deno.env.get("MY_FZF_STATE_FILE");
  if (stateFile) {
    return { stateFile, created: false };
  } else {
    const stateFile = Deno.makeTempFileSync({
      prefix: "myfzf",
      suffix: ".json",
    });
    Deno.env.set("MY_FZF_STATE_FILE", stateFile);
    return { stateFile, created: true };
  }
};

export const nvrCommand = async (s: State, command: string) => {
  const p = Deno.run({
    cmd: ["nvr", "-c", command],
    cwd: s.cwd,
    stdout: "piped",
    stderr: "piped",
  });
  const status = await p.status();
  const out = new TextDecoder().decode(await p.output());
  const err = new TextDecoder().decode(await p.stderrOutput());
  xlog({ context: "nvrCommand", command, status, out, err });
};

export const nvrExpr = async (s: State, expr: string): Promise<string> => {
  const p = Deno.run({
    cmd: ["nvr", "--remote-expr", expr],
    cwd: s.cwd,
    stdout: "piped",
    stderr: "piped",
  });
  const status = await p.status();
  const out = new TextDecoder().decode(await p.output());
  const err = new TextDecoder().decode(await p.stderrOutput());
  log({ context: "nvrExpr", expr, status, out, err });
  return out;
};

export type AbsPath = { kind: "absolute"; val: string };
export type RelPath = { kind: "relative"; val: string }; // Posiblly relative path. Can be absolute.
type Path = AbsPath | RelPath;

export const unsafeAbsPath = (val: string): AbsPath => ({
  kind: "absolute",
  val,
});
export const RelPath = (val: string): RelPath => ({ kind: "relative", val });

export const resolve = (s: State, path: Path): AbsPath => {
  return {
    kind: "absolute",
    val: Path_.resolve(s.cwd, path.val),
  };
};

export const typeOfPath = (s: State, path: Path) => {
  const absPath = resolve(s, path);
  const stat = Deno.statSync(absPath.val);
  if (stat.isFile) {
    return "file";
  } else if (stat.isDirectory) {
    return "dir";
  } else {
    throw `impossible: ${absPath.val} is neither file nor directory`;
  }
};

export const changeDirectory = (s: State, path: Path) => {
  const absPath = resolve(s, path);
  log({ context: "changeDirectory", absPath });
  switch (typeOfPath(s, absPath)) {
    case "file": {
      const nextCwd = Path_.resolve(absPath.val, "..");
      modifyState((s) => Object.assign(s, { cwd: nextCwd }));
      xlog({ context: "changeDirectory", file: absPath, nextCwd });
      break;
    }
    case "dir": {
      const nextCwd = absPath.val;
      modifyState((s) => Object.assign(s, { cwd: nextCwd }));
      xlog({ context: "changeDirectory", dir: absPath, nextCwd });
      break;
    }
  }
};

export const readState = () => {
  const { stateFile } = getOrCreateStateFile();
  log({ stateFile });
  return JSON.parse(Deno.readTextFileSync(stateFile)) as State;
};

export const writeState = (s: State) => {
  const { stateFile } = getOrCreateStateFile();
  Deno.writeFileSync(stateFile, new TextEncoder().encode(JSON.stringify(s)));
};

export const modifyState = (f: (_: State) => State) => {
  writeState(f(readState()));
};

export const batOpts = ([] as string[])
  .concat(["--color", "always"])
  .concat(["--wrap", "never"])
  .concat(["--pager", "never"])
  .concat(["--style=numbers,changes"]);

export const exaOpts = ([] as string[])
  .concat(["--all"])
  .concat(["--sort", "name"])
  .concat(["--tree"])
  .concat(["--level", "1"])
  .concat(["--classify"])
  .concat(["--git"])
  .concat(["--color=always"]);

export const print = (s: string) => console.log(s);

export const printHeader = (s: State) => {
  print(`[${s.cwd}]`);
};

export const previewFileOrDir: Preview = async (s: State, args: Args) => {
  const rawPath = args._.shift()?.toString();
  const line = Number(args.line || 0);
  if (!rawPath) {
    throw `previewFile_or_dir: No path given`;
  }
  xlog({ context: "previewFileOrDir", cwd: s.cwd, rawPath });
  print(`  [${rawPath}]`);
  switch (typeOfPath(s, { kind: "relative", val: rawPath })) {
    case "file": {
      await Deno.run({
        cmd: ["bat"].concat(
          batOpts, //
          ["--line-range", `${line}:`],
          [rawPath],
        ),
        cwd: s.cwd,
      }).status();
      break;
    }
    case "dir": {
      await Deno.run({
        cmd: ["exa"].concat(exaOpts, [rawPath]),
        cwd: s.cwd,
      }).status();
      break;
    }
  }
};

export const pathExists = (s: State, path: Path): boolean => {
  const absPath = resolve(s, path);
  try {
    Deno.lstatSync(absPath.val);
    return true;
  } catch (err) {
    if (err instanceof Deno.errors.NotFound) {
      return false;
    }
    throw err;
  }
};

export const setMode = (mode: string) => {
  modifyState((s) => Object.assign(s, { mode }));
};

export function setCurrentLoaderArgs(currentLoaderArgs: Args) {
  modifyState((s) => Object.assign(s, { currentLoaderArgs }));
}
