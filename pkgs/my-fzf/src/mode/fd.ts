import { changeDirectory, nvrExpr, previewFileOrDir, printHeader, readState } from "../lib.ts";
import { LoadImpl, ModeImpl, PreviewImpl, State } from "../types.ts";

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

const fdOpts = ([] as string[])
  .concat(["--hidden"])
  .concat(["--no-ignore"])
  .concat(["--type", "f"])
  .concat(fdExcludePaths.flatMap((p) => ["--exclude", p]));

const nvrLastFile = async (s: State): Promise<string> => {
  return await nvrExpr(s, "g:last_file");
};

const loadFd: LoadImpl = async (s, opts) => {
  const nextDir: string = opts["cd"]
    ? opts["cd"]
    : opts["cd-up"]
    ? s.cwd + "/.."
    : opts["cd-last-file"]
    ? (await nvrLastFile(s)) + "/.."
    : s.cwd;
  changeDirectory(s, { kind: "relative", val: nextDir });
  const sNew = readState();
  printHeader(sNew);
  await Deno.run({
    cmd: ["fd"].concat(fdOpts),
    cwd: sNew.cwd,
  }).status();
};

const previewFd: PreviewImpl = previewFileOrDir;

export const fd: ModeImpl<"fd"> = {
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

