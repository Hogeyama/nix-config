import { isString } from "https://deno.land/x/unknownutil@v2.0.0/is.ts";
import {
  changeDirectory,
  nvrExpr,
  pathExists,
  previewFileOrDir,
  print,
  RelPath,
  resolve,
  typeOfPath,
} from "../lib.ts";
import { Args, Load, Mode, Preview, State } from "../types.ts";

const fdExcludePaths = (() => {
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
  const env = Deno.env.get("MY_FZF_FD_EXCLUDE_PATHS");
  if (env) {
    return env.split(",").concat(def);
  } else {
    return def;
  }
})();

const fdExtraOpt = (() => {
  const opt = Deno.env.get("MY_FZF_FD_EXTRA_OPT");
  return opt ? opt.split(/\s+/) : [];
})();

const fdOpts = ([] as string[])
  .concat(["--hidden"])
  .concat(["--no-ignore"])
  .concat(["--type", "f"])
  .concat(fdExtraOpt)
  .concat(fdExcludePaths.flatMap((p) => ["--exclude", p]));

const nvrLastFile = async (s: State): Promise<string> => {
  return await nvrExpr(s, "g:last_file");
};

const getNextCwd = async (s: State, args: Args) => {
  let nextDirBase: string;
  if (args["cd"]) {
    nextDirBase = args["cd"];
  } else if (args["cd-up"]) {
    nextDirBase = s.cwd + "/..";
  } else if (args["cd-last-file"]) {
    nextDirBase = (await nvrLastFile(s)) + "/..";
  } else {
    const arg = args["_"].at(0);
    if (isString(arg) && pathExists(s, RelPath(arg))) {
      nextDirBase = arg;
    } else {
      nextDirBase = s.cwd;
    }
  }
  switch (typeOfPath(s, RelPath(nextDirBase))) {
    case "file":
      return resolve(s, RelPath(nextDirBase + "/.."));
    case "dir":
      return resolve(s, RelPath(nextDirBase));
  }
};

const loadFd: Load = async (s, args) => {
  const nextCwd = await getNextCwd(s, args);
  changeDirectory(s, nextCwd);
  print(`[${nextCwd.val}]`); // header
  await Deno.run({
    cmd: ["fd"].concat(fdOpts),
    cwd: nextCwd.val,
  }).status();
};

const previewFd: Preview = previewFileOrDir;

export const mode: Mode = {
  mode: "fd",
  load: loadFd,
  preview: previewFd,
  defaultRunner: "nvim",
  modifyRunnerArgs: {
    nvim: (_, args) => args,
    vifm: (s, _) => {
      return { _: [s.cwd] };
    },
  },
};

export const cmd = {
  default: (prog: string) => `${prog} load fd {q}`,
  cdUp: (prog: string) => `${prog} load fd --cd-up`,
  cdArg: (prog: string) => `${prog} load fd --cd {}`,
  cdLastFile: (prog: string) => `${prog} load fd --cd-last-file`,
};
