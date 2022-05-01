#!/usr/bin/env -S deno run --allow-run --allow-read --allow-write --allow-env
import * as Path from "https://deno.land/std@0.133.0/path/mod.ts";
import * as flags from "https://deno.land/std@0.133.0/flags/mod.ts";

// `env -S` requires coreutils >= 8.30. If your coreutils is older,
// wrap this script and path as MY_FZF_PROG environment variable.
const prog = Deno.env.get("MY_FZF_PROG") || Path.fromFileUrl(import.meta.url);

const fdExcludePaths = (() => {
  // {{{
  const def = [
    ".git",
    ".hg",
    ".hie",
    ".direnv",
    ".stack-work",
    ".aws-sam",
    ".next",
    "dist-newstyle",
    "node_modules",
    "api-cache",
    "cache",
  ];
  const env = Deno.env.get("MYFZF_FD_EXCLUDE_PATHS");
  if (env) {
    return env.split(",").concat(def);
  } else {
    return def;
  }
})();
// }}}

// TODO このへんいい感じにする
const exaOpts = ([] as string[]) // {{{
  .concat(["--all"])
  .concat(["--sort", "name"])
  .concat(["--tree"])
  .concat(["--level", "1"])
  .concat(["--classify"])
  .concat(["--git"])
  .concat(["--color=always"]);
// }}}
const batOpts = ([] as string[]) // {{{
  .concat(["--color", "always"])
  .concat(["--wrap", "never"])
  .concat(["--pager", "never"])
  .concat(["--style=numbers,changes"]);
// }}}
const fdOpts = ([] as string[]) // {{{
  .concat(["--hidden"])
  .concat(["--no-ignore"])
  .concat(["--type", "f"])
  .concat(fdExcludePaths.flatMap((p) => ["--exclude", p]));
// }}}
const rgOpts = ([] as string[]) // {{{
  .concat(["--column"])
  .concat(["--line-number"])
  .concat(["--no-heading"])
  .concat(["--color=never"])
  .concat(["--smart-case"]);
// }}}
const fzfOpts = ([] as string[]) // {{{
  .concat(["--preview", `${prog} preview {}`])
  .concat(["--preview-window", "right:50%:noborder"])
  .concat(["--header-lines=1"])
  .concat(["--prompt", "files>"])
  .concat([
    `--bind`, //
    `enter:execute[${prog} run default {}]`,
  ])
  .concat([
    `--bind`, //
    `ctrl-o:execute[${prog} run nvim {}]`,
  ])
  .concat([
    `--bind`, //
    `ctrl-t:execute[${prog} run nvim {} --tab ]`,
  ])
  .concat([
    `--bind`, //
    `ctrl-v:execute[${prog} run vifm {}]`,
  ])
  .concat([
    `--bind`, //
    `ctrl-f:reload[${prog} load fd]+change-prompt[files>]`,
  ])
  .concat([
    `--bind`, //
    `ctrl-u:reload[${prog} load fd --cd-up]+change-prompt[files>]`,
  ])
  .concat([
    `--bind`, //
    `ctrl-l:reload[${prog} load fd --cd {}]+change-prompt[files>]+clear-query`,
  ])
  .concat([
    `--bind`, //
    `ctrl-n:reload[${prog} load fd --cd-last-file]+change-prompt[files>]+clear-query`,
  ])
  .concat([
    `--bind`, //
    `ctrl-b:reload[${prog} load buffer]+change-prompt[buffer>]`,
  ])
  .concat([
    `--bind`, //
    `ctrl-h:reload[${prog} load mru]+change-prompt[mru>]`,
  ])
  .concat([
    `--bind`, //
    `ctrl-d:reload[${prog} load zoxide]+change-prompt[zoxide>]`,
  ])
  .concat([
    `--bind`, //
    `ctrl-d:reload[${prog} load zoxide]+change-prompt[zoxide>]`,
  ])
  .concat([
    `--bind`, //
    `ctrl-g:reload[${prog} load rg {q}]+clear-query+change-prompt[grep>]`,
  ])
  .concat([
    `--bind`, //
    `ctrl-b:reload[${prog} load browser-history {q}]+clear-query+change-prompt[browser-history>]`,
  ])
  .concat([
    `--bind`, //
    `ctrl-r:reload[${prog} reload]`,
  ])
  .concat([
    `--bind`, //
    `ctrl-s:toggle-sort`,
  ]);
// }}}

////////////////////////////////////////////////////////////////////////////////
// Types
////////////////////////////////////////////////////////////////////////////////

// Common
///////////

type Opt = flags.Args;

// Command
////////////

type Command = "load" | "reload" | "preview" | "run";
const isCommand = (s: string): s is Command => {
  return (
    s === "load" || //
    s === "reload" ||
    s === "preview" ||
    s === "run"
  );
};

// Mode
/////////

type Mode = "fd" | "rg" | "mru" | "zoxide" | "buffer" | "browser-history";
const isMode = (s: string): s is Mode => {
  return (
    s === "fd" ||
    s === "rg" ||
    s === "mru" ||
    s === "zoxide" ||
    s === "buffer" ||
    s === "browser-history"
  );
};

// Runner
///////////

type Runner = "nvim" | "vifm" | "browser";
const isRunner = (s: string): s is Runner => {
  return (
    s === "nvim" || //
    s === "vifm" ||
    s === "browser"
  );
};

type RunnerOpts = {
  nvim: NvimOpt;
  vifm: VifmOpt;
  browser: Opt; // TODO
};
type RunnerOpt<R extends Runner> = RunnerOpts[R];

type RunnerImpl<R extends Runner> = (
  s: State,
  opts: RunnerOpt<R>
) => Promise<void>;

type AllRunners = {
  [key in Runner]: RunnerImpl<key>;
};

// State
//////////

type State = {
  mode: Mode;
  cwd: string; // absolute path to the (virtual) current directory
  currentLoader: Opt;
};

const initialState: State = {
  mode: "fd",
  cwd: Deno.cwd(),
  currentLoader: { _: [] },
};

const stateFile =
  Deno.env.get("MYFZF_STATE_FILE") ||
  Deno.makeTempFileSync({ prefix: "myfzf", suffix: ".json" });

const readState = () => {
  return JSON.parse(Deno.readTextFileSync(stateFile)) as State;
};

const writeState = (s: State) => {
  Deno.writeFileSync(stateFile, new TextEncoder().encode(JSON.stringify(s)));
};

const modifyState = (f: (_: State) => State) => {
  writeState(f(readState()));
};

const changeDirectory = (s: State, path: Path) => {
  const absPath = resolve(s, path);
  log({ context: "changeDirectory", absPath });
  switch (typeOfPath(s, absPath)) {
    case "file": {
      const nextCwd = Path.resolve(absPath.val, "..");
      modifyState((s) => Object.assign(s, { cwd: nextCwd }));
      log({ context: "changeDirectory", file: absPath, nextCwd });
      break;
    }
    case "dir": {
      const nextCwd = absPath.val;
      modifyState((s) => Object.assign(s, { cwd: nextCwd }));
      log({ context: "changeDirectory", dir: absPath, nextCwd });
      break;
    }
  }
};

const setMode = (mode: Mode) => {
  modifyState((s) => Object.assign(s, { mode }));
};

const setCurrentLoader = (currentLoader: Opt) => {
  modifyState((s) => Object.assign(s, { currentLoader }));
};

// Load
/////////

type LoadImpl = (s: State, opts: Opt) => Promise<void>;

// Preview
////////////

type PreviewImpl = (s: State, o: Opt) => Promise<void>;

// Mode
/////////

type ModeImpl<M extends Mode> = {
  mode: M;
  load: LoadImpl;
  preview: PreviewImpl;
  defaultRunner: Runner;
  modifyRunnerOpt: {
    [key in Runner]?: (s: State, _: Opt) => RunnerOpt<key>;
  };
};

type AllModeImpls = {
  [key in Mode]: ModeImpl<key>;
};

////////////////////////////////////////////////////////////////////////////////
// Utils
////////////////////////////////////////////////////////////////////////////////

// Common
///////////

const print = (s: string) => console.log(s);

// deno-lint-ignore no-explicit-any
const log = (s: any) => {
  const logFile = "/tmp/myfzf.log";
  const fp = Deno.openSync(logFile, {
    write: true,
    append: true,
    create: true,
  });
  try {
    fp.writeSync(new TextEncoder().encode(JSON.stringify(s) + "\n"));
  } finally {
    fp.close();
  }
};

const unquote = (s: string): string => {
  if (s.startsWith('"') && s.endsWith('"')) {
    return JSON.parse(s);
  } else {
    return s;
  }
};

// deno-lint-ignore no-explicit-any
const xlog = (...x: any[]) => x;
xlog();

const printHeader = (s: State) => {
  print(`[${s.cwd}]`);
};

// Path
/////////

type AbsPath = { kind: "absolute"; val: string };
type RelPath = { kind: "relative"; val: string }; // Posiblly relative path. Can be absolute.
type Path = AbsPath | RelPath;

const RelPath = (val: string): RelPath => ({ kind: "relative", val });

const resolve = (s: State, path: Path): AbsPath => {
  return {
    kind: "absolute",
    val: Path.resolve(s.cwd, path.val),
  };
};

const typeOfPath = (s: State, path: Path) => {
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

const pathExists = (s: State, path: Path): boolean => {
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

// nvim
/////////

const nvrCommand = async (s: State, command: string) => {
  const p = Deno.run({
    cmd: ["nvr", "-c", command],
    cwd: s.cwd,
    stdout: "piped",
    stderr: "piped",
    env: {
      MYFZF_STATE_FILE: stateFile,
    },
  });
  const status = await p.status();
  const out = new TextDecoder().decode(await p.output());
  const err = new TextDecoder().decode(await p.stderrOutput());
  log({ context: "nvrCommand", command, status, out, err });
};

// File and dir
/////////////////

const previewFileOrDir: PreviewImpl = async (s: State, opt: Opt) => {
  const rawPath = opt._.shift()?.toString();
  const line = Number(opt.line || 0);
  if (!rawPath) {
    throw `previewFile_or_dir: No path given`;
  }
  log({ context: "previewFileOrDir", cwd: s.cwd, rawPath });
  print(`  [${rawPath}]`);
  switch (typeOfPath(s, { kind: "relative", val: rawPath })) {
    case "file": {
      await Deno.run({
        cmd: ["bat"].concat(
          batOpts, //
          ["--line-range", `${line}:`],
          [rawPath]
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

// browser
////////////

const getFirefoxDb = (s: State): string => {
  const home = Deno.env.get("HOME");
  const searchPath = `${home}/.mozilla/firefox`;
  if (!pathExists(s, RelPath(searchPath))) {
    throw `${searchPath} does not exist`;
  }
  const defaultProfDir = Array.from(Deno.readDirSync(searchPath)).find((f) => {
    return f.isDirectory && f.name.match(/default/);
  });
  if (!defaultProfDir) {
    throw "firefox: No default profile found";
  }
  const db = `${searchPath}/${defaultProfDir.name}/places.sqlite`;
  if (!pathExists(s, RelPath(db))) {
    throw `${db} does not exist`;
  }
  return db;
};

const getChromeDb = (s: State): string => {
  const home = Deno.env.get("HOME");
  const db = `${home}/.config/google-chrome/Default/History`;
  if (!pathExists(s, RelPath(db))) {
    throw `${db} does not exist`;
  }
  return db;
};

const sqliteRecordSep = String.fromCodePoint(0x2009); // U+2009: Thin space

////////////////////////////////////////////////////////////////////////////////
// Runner
////////////////////////////////////////////////////////////////////////////////

// nvim
/////////

type NvimOpt = {
  leave?: boolean;
  tab?: boolean;
  line?: number;
  buf?: number;
  _: (string | number)[];
};
const defaultNvimOpts = { leave: true };
const runNvim: RunnerImpl<"nvim"> = async (s: State, _opt: NvimOpt) => {
  const opt = Object.assign({}, defaultNvimOpts, _opt);
  const lOpt = opt.line ? `+${opt.line}` : "";
  // TODO init.vim にコマンドを定義したほうがよいかも
  if (opt.buf) {
    const buf = opt.buf;
    if (opt.tab) {
      await nvrCommand(s, `tabnew`);
      await nvrCommand(s, `buffer ${lOpt} ${buf}`);
      await nvrCommand(s, `MoveToLastTab`);
    } else if (opt.leave) {
      await nvrCommand(s, `stopinsert`);
      await nvrCommand(s, `MoveToLastWin`);
      await nvrCommand(s, `buffer ${lOpt} ${buf}`);
      await nvrCommand(s, `FloatermHide! fzf`);
    } else {
      await nvrCommand(s, `stopinsert`);
      await nvrCommand(s, `MoveToLastWin`);
      await nvrCommand(s, `buffer ${lOpt} ${buf}`);
      await nvrCommand(s, `MoveToLastWin`);
      await nvrCommand(s, `startinsert`);
    }
  } else {
    const relPath = opt._.shift()?.toString();
    if (!relPath) {
      throw `runNvim: No file specified`;
    }
    const path = resolve(s, RelPath(relPath)).val;
    if (opt.tab) {
      await nvrCommand(s, `execute 'tabedit ${lOpt} '.fnameescape('${path}')`);
      await nvrCommand(s, `MoveToLastTab`);
    } else if (opt.leave) {
      await nvrCommand(s, `stopinsert`);
      await nvrCommand(s, `MoveToLastWin`);
      await nvrCommand(s, `execute 'edit ${lOpt} '.fnameescape('${path}')`);
      await nvrCommand(s, `FloatermHide! fzf`);
    } else {
      await nvrCommand(s, `stopinsert`);
      await nvrCommand(s, `MoveToLastWin`);
      await nvrCommand(s, `execute 'edit ${lOpt} '.fnameescape('${path}')`);
      await nvrCommand(s, `MoveToLastWin`);
      await nvrCommand(s, `startinsert`);
    }
  }
};

// vifm
/////////

type VifmOpt = { _: [string] };
const runVifm: RunnerImpl<"vifm"> = async (s: State, opt: VifmOpt) => {
  const dir = opt._.shift();
  if (!dir) {
    throw `runVifm: No dir specified`;
  }
  await Deno.run({
    cmd: ["vifm"].concat([dir]),
    cwd: s.cwd,
    env: {
      MYFZF_STATE_FILE: stateFile,
    },
  }).status();
};

// browser
////////////

const runBrowser: RunnerImpl<"browser"> = async (_: State, opt: Opt) => {
  const url = opt._.shift()?.toString();
  if (!url) {
    throw `runBrowser: No url specified`;
  }
  const browser = Deno.env.get("BROWSER") || "firefox";
  await Deno.run({
    cmd: [browser].concat([url]),
    env: {
      MYFZF_STATE_FILE: stateFile,
    },
  }).status();
};

// allRunners
///////////////

const allRunners: AllRunners = {
  nvim: runNvim,
  vifm: runVifm,
  browser: runBrowser,
};

////////////////////////////////////////////////////////////////////////////////
// Mode
////////////////////////////////////////////////////////////////////////////////

// fd
////////////////////////////////////////

// Loader

const loadFd: LoadImpl = async (s, opts) => {
  const nextDir: string = opts["cd"]
    ? opts["cd"]
    : opts["cd-up"]
    ? s.cwd + "/.."
    : s.cwd;
  changeDirectory(s, { kind: "relative", val: nextDir });
  const sNew = readState();
  printHeader(sNew);
  await Deno.run({
    cmd: ["fd"].concat(fdOpts),
    cwd: sNew.cwd,
    env: {
      MYFZF_STATE_FILE: stateFile,
    },
  }).status();
};

const previewFd: PreviewImpl = previewFileOrDir;

const fd: ModeImpl<"fd"> = {
  mode: "fd",
  load: loadFd,
  preview: previewFd,
  defaultRunner: "nvim",
  modifyRunnerOpt: {
    nvim: (_, opt) => opt,
    vifm: (s, _) => {
      return { _: [s.cwd] };
    },
  },
};

// rg
////////////////////////////////////////

// Util

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
  return { file, line: Number(line) };
};

// Loader

const loadRg: LoadImpl = async (s, opts) => {
  printHeader(s);
  const rgArgs = opts._.map((x) => x.toString());
  const p = Deno.run({
    cmd: ["rg"].concat(rgOpts, rgArgs),
    cwd: s.cwd,
    env: {
      MYFZF_STATE_FILE: stateFile,
    },
  });
  await p.status();
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
  await Deno.run({
    cmd: ["bat"].concat(batOpts, batExtraOpts, [file]),
    cwd: s.cwd,
  }).status();
  return;
};

const rg: ModeImpl<"rg"> = {
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

// mru
////////////////////////////////////////

const loadMru: LoadImpl = async (s, _opts) => {
  printHeader(s);
  let tmp: string | undefined = undefined;
  try {
    tmp = Deno.makeTempFileSync();
    await nvrCommand(s, `call writefile(v:oldfiles,'${tmp}')`);
    const rawMru = new TextDecoder().decode(Deno.readFileSync(tmp));
    const files = rawMru
      .split("\n")
      .filter((x: string) => pathExists(s, RelPath(x)));
    log({ context: "loadMru", files });
    print(files.join("\n"));
  } finally {
    tmp && Deno.removeSync(tmp);
  }
};

const mru: ModeImpl<"mru"> = {
  mode: "mru",
  load: loadMru,
  preview: previewFileOrDir,
  defaultRunner: "nvim",
  modifyRunnerOpt: {
    nvim: (_, opt) => opt,
  },
};

// buffer
////////////////////////////////////////

const loadBuffer: LoadImpl = async (s, _opts) => {
  printHeader(s);
  let tmp: string | undefined = undefined;
  try {
    tmp = Deno.makeTempFileSync();
    await nvrCommand(s, `redir! >${tmp} | silent buffers | redir END`);
    const rawBuffers = new TextDecoder().decode(Deno.readFileSync(tmp));
    print(
      rawBuffers
        .split("\n")
        .filter((x) => x)
        .join("\n")
    );
  } finally {
    tmp && Deno.removeSync(tmp);
  }
};

type BufferItem = { bufnum: number; state: string; path: string; line: number };

const parseBufferItem = (item: string): BufferItem => {
  const [bufnum, state, path, _, line] = item.trim().split(/\s+/);
  log({ context: "parseBufferItem", item });
  return {
    bufnum: Number(bufnum),
    state: state,
    path: unquote(path),
    line: Number(line),
  };
};

const previewBuffer: PreviewImpl = async (s, opt) => {
  const rawItem = opt._.at(0)?.toString();
  if (rawItem) {
    const { path, line } = parseBufferItem(rawItem);
    const absPath = resolve(s, RelPath(path));
    // TODO nvim の pwd と myfzf の cwd が異なる場合にはずれる。
    // parseBufferItem で nvim の pwd 基準でパスを解決する。
    if (pathExists(s, absPath)) {
      await previewFileOrDir(s, { _: [absPath.val], line });
    }
  }
};

const buffer: ModeImpl<"buffer"> = {
  mode: "buffer",
  load: loadBuffer,
  preview: previewBuffer,
  defaultRunner: "nvim",
  modifyRunnerOpt: {
    nvim: (_, opt) => {
      const rawItem = opt._.at(0)?.toString();
      if (rawItem) {
        const item = parseBufferItem(rawItem);
        return Object.assign(opt, { buf: item.bufnum });
      } else {
        throw `buffer: No item given`;
      }
    },
  },
};

// zoxide
////////////////////////////////////////

const loadZoxide: LoadImpl = async (s, opt) => {
  printHeader(s);
  const p = Deno.run({
    cmd: ["zoxide"].concat(
      ["query", "-l"],
      opt._.map((x) => x.toString())
    ),
    cwd: s.cwd,
    env: {
      MYFZF_STATE_FILE: stateFile,
    },
  });
  await p.status();
};

const zoxide: ModeImpl<"zoxide"> = {
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

// browser-history
////////////////////////////////////////

const loadBrowserHistory: LoadImpl = async (s, opt) => {
  printHeader(s);
  const pat = opt.pattern || "%";
  const cond = `url LIKE '%${pat}%' OR title LIKE '%${pat}%'`;
  const browser = Deno.env.get("BROWSER") || "firefox";
  let copyDb: string | undefined = undefined;
  try {
    copyDb = Deno.makeTempFileSync({ suffix: ".sqlite" });
    let sql: string;
    if (browser.match("firefox")) {
      const origDb = getFirefoxDb(s);
      Deno.copyFileSync(origDb, copyDb);
      sql = `
      SELECT
        url,
        title,
        DATETIME(last_visit_date / 1000000, 'unixepoch', '+9 hours') AS date
      FROM
        moz_places
      WHERE
        ${cond}
      ORDER BY
        date DESC
      LIMIT
        10000
      ;
    `;
    } else if (browser.match("chrome")) {
      const origDb = getChromeDb(s);
      Deno.copyFileSync(origDb, copyDb);
      sql = `
      SELECT
        url,
        title,
        DATETIME(last_visit_time / 1000000 + (strftime('%s', '1601-01-01') ), 'unixepoch', '+9 hours') AS date
      FROM
        urls
      WHERE
        ${cond}
      GROUP BY
        title
      ORDER BY
        date DESC
      LIMIT
        10000
      ;
    `;
    } else {
      throw `browser: ${browser} is not supported`;
    }
    const p = Deno.run({
      cmd: ["sqlite3"].concat([
        "-batch",
        "-batch",
        "-readonly",
        "-separator",
        sqliteRecordSep,
        copyDb,
      ]),
      stdin: "piped",
      env: {
        MYFZF_STATE_FILE: stateFile,
        FZF_DEFAULT_COMMAND: `${prog} load`,
      },
    });
    p.stdin.write(new TextEncoder().encode(sql));
    await p.status();
  } finally {
    copyDb && Deno.removeSync(copyDb);
  }
};

type BrowserItem = {
  url: string;
  title: string;
  date: string;
};
const parseBrowserItem = (item: string): BrowserItem => {
  const [url, title, date] = item.trim().split(sqliteRecordSep);
  return { url, title, date };
};

// deno-lint-ignore require-await
const previewUrl: PreviewImpl = async (_s, opt) => {
  const rawItem = opt._.at(0)?.toString();
  if (!rawItem) {
    throw `browser: No item given`;
  }
  const { url, title, date } = parseBrowserItem(rawItem);
  print(`URL:    ${url}`);
  print(`Title:  ${title}`);
  print(`Access: ${date}`);
};

const browserHistory: ModeImpl<"browser-history"> = {
  mode: "browser-history",
  load: loadBrowserHistory,
  preview: previewUrl,
  defaultRunner: "browser",
  modifyRunnerOpt: {
    browser: (_, opt) => {
      const rawItem = opt._.at(0)?.toString();
      if (!rawItem) {
        throw `browser: No item given`;
      }
      const { url } = parseBrowserItem(rawItem);
      return Object.assign(opt, { _: [url] });
    },
  },
};

////////////////////////////////////////////////////////////////////////////////
// Dispatch
////////////////////////////////////////////////////////////////////////////////

const allModes: AllModeImpls = {
  fd,
  rg,
  mru,
  buffer,
  zoxide,
  "browser-history": browserHistory,
};

const init = async () => {
  try {
    writeState(initialState);
    await Deno.run({
      cmd: ["fzf"].concat(fzfOpts),
      stdin: "inherit",
      stdout: "piped",
      env: {
        MYFZF_STATE_FILE: stateFile,
        FZF_DEFAULT_COMMAND: `${prog} load`,
      },
    }).status();
  } finally {
    Deno.remove(stateFile);
  }
};

const load = async (s: State, opt: Opt) => {
  setCurrentLoader(opt);
  const mode = opt._.shift()?.toString() || "fd";
  if (isMode(mode)) {
    setMode(mode);
    await allModes[mode].load(s, opt);
  } else {
    throw `load: Invalid mode: ${mode}`;
  }
};

const preview = async (s: State, opt: Opt) => {
  if (isMode(s.mode)) {
    setMode(s.mode);
    await allModes[s.mode].preview(s, opt);
  } else {
    throw "impossible";
  }
};

const run = (s: State, opt: Opt) => {
  const currentMode = allModes[s.mode];
  const runner: Runner = (() => {
    const c = opt._.shift()?.toString() || "default";
    if (isRunner(c)) {
      return c;
    } else if (c === "default") {
      return currentMode.defaultRunner;
    } else {
      throw `run: Invalid runner: ${c}`;
    }
  })();
  const modifyRunnerOpt = currentMode.modifyRunnerOpt[runner];
  if (modifyRunnerOpt) {
    // union distribution のせいで推論できない。敗北
    // deno-lint-ignore no-explicit-any
    allRunners[runner](s, modifyRunnerOpt(s, opt) as any);
  } else {
    throw `run: Runner '${runner}' unavailable for mode '${s.mode}'`;
  }
};

const dispatch = async (command: Command, opt: Opt) => {
  const state = readState();
  switch (command) {
    case "load": {
      await load(state, opt);
      break;
    }
    case "reload": {
      await load(state, state.currentLoader);
      break;
    }
    case "preview": {
      await preview(state, opt);
      break;
    }
    case "run": {
      run(state, opt); // non-blocking
      break;
    }
  }
};

////////////////////////////////////////////////////////////////////////////////
// Main
////////////////////////////////////////////////////////////////////////////////

const main = async () => {
  try {
    if (!Deno.env.get("MYFZF_STATE_FILE")) {
      init();
      return;
    }
    const opt = flags.parse(Deno.args);
    const command = opt._.shift()?.toString() || "";
    if (isCommand(command)) {
      await dispatch(command, opt);
    } else {
      throw `Unknown command: ${command}`;
    }
  } catch (exception) {
    log({ exception });
    throw exception;
  }
};

main();
