import { Opt, RunnerImpl, State } from "../types.ts";

export const runBrowser: RunnerImpl = async (_: State, opt: Opt) => {
  const url = opt._.shift()?.toString();
  if (!url) {
    throw `runBrowser: No url specified`;
  }
  const browser = Deno.env.get("BROWSER") || "firefox";
  await Deno.run({
    cmd: [browser].concat([url]),
  }).status();
};

