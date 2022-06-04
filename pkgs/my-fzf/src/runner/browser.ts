import { Args, Runner, State } from "../types.ts";

export const runner: Runner = {
  name: "browser",
  run: async (_: State, args: Args) => {
    const url = args._.shift()?.toString();
    if (!url) {
      throw `runBrowser: No url specified`;
    }
    const browser = Deno.env.get("BROWSER") || "firefox";
    await Deno.run({
      cmd: [browser].concat([url]),
    }).status();
  },
};
