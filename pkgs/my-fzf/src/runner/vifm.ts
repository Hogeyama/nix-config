import { Opt, RunnerImpl, State } from "../types.ts";

export const runVifm: RunnerImpl = async (s: State, opt: Opt) => {
  const dir = opt._.shift()?.toString();
  if (!dir) {
    throw `runVifm: No dir specified`;
  }
  await Deno.run({
    cmd: ["vifm"].concat([dir]),
    cwd: s.cwd,
  }).status();
};
