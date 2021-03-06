#!/usr/bin/env -S deno run --no-check --allow-run --allow-read --allow-write --allow-env
import * as flags from "https://deno.land/std@0.133.0/flags/mod.ts";

import { Args, Command, isCommand, State } from "./types.ts";
import {
  execLoader,
  execPreviewer,
  execRunner,
  log,
  readState,
  spawnFzf,
} from "./lib.ts";
import { allModes, allRunners, fzfOpts } from "./config.ts";

const load = async (s: State, args: Args) => {
  const mode = args._.shift()?.toString() || "fd";
  if (mode in allModes) {
    await execLoader(allModes[mode], s, args);
  }
};

const reload = async (s: State) => {
  await execLoader(allModes[s.mode], s, s.currentLoaderArgs);
};

const preview = async (s: State, args: Args) => {
  await execPreviewer(allModes[s.mode], s, args);
};

const run = (s: State, args: Args) => {
  const mode = allModes[s.mode];
  const runner: string = (() => {
    const c = args._.shift()?.toString() || "default";
    if (c == "default") {
      return mode.defaultRunner;
    } else {
      return c;
    }
  })();
  execRunner(mode, allRunners[runner], s, args);
};

const dispatch = async (s: State, command: Command, args: Args) => {
  switch (command) {
    case "load": {
      await load(s, args);
      break;
    }
    case "reload": {
      await reload(s);
      break;
    }
    case "preview": {
      await preview(s, args);
      break;
    }
    case "run": {
      run(s, args); // non-blocking
      break;
    }
  }
};

////////////////////////////////////////////////////////////////////////////////
// Main
////////////////////////////////////////////////////////////////////////////////

const main = async () => {
  try {
    const args = flags.parse(Deno.args);
    const id = args?.id;
    if (!id) {
      await spawnFzf(fzfOpts);
    } else {
      const command = args._.shift()?.toString() || "";
      const s = await readState(id.toString());
      if (isCommand(command)) {
        await dispatch(s, command, args);
      } else {
        throw `Unknown command: ${command}`;
      }
    }
  } catch (e) {
    log({ exception: e, stack: e.stack });
    Deno.exit(1);
  }
};

main();
