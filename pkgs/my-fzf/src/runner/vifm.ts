import { Args, Runner, State } from "../types.ts";

export const runVifm: Runner = {
  name: "vifm",
  run: async (s: State, args: Args) => {
    const dir = args._.shift()?.toString();
    if (!dir) {
      throw `runVifm: No dir specified`;
    }
    await Deno.run({
      cmd: ["vifm"].concat([dir]),
      cwd: s.cwd,
    }).status();
  },
};
