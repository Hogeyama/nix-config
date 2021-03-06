import { Args, Mode, Preview, Runner, State } from "./types.ts";
import * as Path_ from "https://deno.land/std@0.133.0/path/mod.ts";

////////////////////////////////////////////////////////////////////////////////
// Dispatch
////////////////////////////////////////////////////////////////////////////////

export const spawnFzf = async (fzfOpts: (_: string) => string[]) => {
  // 子ども達に一意の id を渡して他の myfzf の起動と区別する
  const id = Math.random().toString(32).substring(2);

  const prog = Deno.env.get("MY_FZF_PROG") || (() => {
    throw "MY_FZF_PROG not set";
  })();

  await writeState({
    id,
    mode: "fd",
    cwd: Deno.cwd(),
    currentLoaderArgs: { _: [] },
  });

  await Deno.run({
    cmd: ["fzf"].concat(fzfOpts(`${prog} --id ${id}`)),
    stdin: "inherit",
    stdout: "piped",
    env: Object.assign(
      {},
      Deno.env.toObject(),
      {
        FZF_DEFAULT_COMMAND: `${prog} --id ${id} load fd`,
      },
    ),
  }).status();
};

export const execLoader = async (mode: Mode, s: State, args: Args) => {
  setMode(s, mode.mode);
  setCurrentLoaderArgs(s, args);
  await mode.load(s, args);
};

export const execPreviewer = async (mode: Mode, s: State, args: Args) => {
  await mode.preview(s, args);
};

export const execRunner = async (
  mode: Mode,
  runner: Runner,
  s: State,
  args: Args,
) => {
  const modifyRunnerArgs = mode.modifyRunnerArgs[runner.name];
  if (modifyRunnerArgs) {
    const modifiedArgs = "async_" in modifyRunnerArgs
      ? (await modifyRunnerArgs.async_(s, args))
      : modifyRunnerArgs(s, args);
    runner.run(s, modifiedArgs);
  } else {
    throw `run: Runner '${runner}' unavailable for mode '${s.mode}'`;
  }
};

////////////////////////////////////////////////////////////////////////////////
// State
////////////////////////////////////////////////////////////////////////////////

export const readState = async (id: string): Promise<State> => {
  return JSON.parse(
    await nvrExpr(`json_encode(g:myfzf_state['${id}'])`),
  ) as State;
};

const writeState = async (s: State) => {
  await nvrCommand(`
    if !exists('g:myfzf_state') | let g:myfzf_state = {} | endif
  `);
  // エスケープのために2回 JSON.stringify する
  await nvrCommand(
    `let g:myfzf_state['${s.id}'] = json_decode(${
      JSON.stringify(JSON.stringify(s))
    })`,
  );
};

const setMode = (s: State, mode: string) => {
  writeState(Object.assign(s, { mode }));
};

const setCurrentLoaderArgs = (s: State, currentLoaderArgs: Args) => {
  writeState(Object.assign(s, { currentLoaderArgs }));
};

////////////////////////////////////////////////////////////////////////////////
// Preview
////////////////////////////////////////////////////////////////////////////////

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

export const previewFileOrDir: Preview = async (s: State, args: Args) => {
  const rawPath = args._.shift()?.toString();
  const line = Number(args.line || 0);
  const highlightLine = args.highlightLine ? Number(args.highlightLine) : null;
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
          highlightLine ? ["--highlight-line", `${highlightLine}`] : [],
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

////////////////////////////////////////////////////////////////////////////////
// Util
////////////////////////////////////////////////////////////////////////////////

// print
////////

export const print = (s: string) => console.log(s);

export const printHeader = (s: State) => {
  print(`[${s.cwd}]`);
};

// Log
///////

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

// File
///////

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
  if (typeOfPath(s, absPath) != "dir") {
    throw `changeDirectory: ${path} is not a directory`;
  }
  const nextCwd = absPath.val;
  writeState(Object.assign(s, { cwd: nextCwd }));
};

// NeoVim
/////////

export const nvrCommand = async (command: string) => {
  const p = Deno.run({
    cmd: ["nvr", "-c", command],
    stdout: "piped",
    stderr: "piped",
  });
  const status = await p.status();
  const out = new TextDecoder().decode(await p.output());
  const err = new TextDecoder().decode(await p.stderrOutput());
  log({ context: "nvrCommand", command, status, out, err });
};

export const nvrExpr = async (expr: string): Promise<string> => {
  const p = Deno.run({
    cmd: ["nvr", "--remote-expr", expr],
    stdout: "piped",
    stderr: "piped",
  });
  const status = await p.status();
  const out = new TextDecoder().decode(await p.output()).trimEnd();
  const err = new TextDecoder().decode(await p.stderrOutput()).trimEnd();
  log({ context: "nvrExpr", expr, status, out, err });
  return out;
};
