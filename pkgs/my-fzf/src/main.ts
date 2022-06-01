#!/usr/bin/env -S deno run --no-check --allow-run --allow-read --allow-write --allow-env
import * as flags from "https://deno.land/std@0.133.0/flags/mod.ts";

import { Args, Command, isCommand, State } from "./types.ts";
import {
  getOrCreateStateFile,
  log,
  readState,
  setCurrentLoader,
  setMode,
  writeState,
} from "./lib.ts";
import { allModes, allRunners, fzfOpts } from "./config.ts";

const init = async () => {
  const stateFile = getOrCreateStateFile();
  try {
    const prog = Deno.env.get("MY_FZF_PROG");
    if (!prog) throw "MY_FZF_PROG not defined";

    writeState({
      mode: "fd",
      cwd: Deno.cwd(),
      currentLoaderArgs: { _: [] },
    });

    await Deno.run({
      cmd: ["fzf"].concat(fzfOpts(prog)),
      stdin: "inherit",
      stdout: "piped",
      env: Object.assign(
        {},
        Deno.env.toObject(),
        {
          FZF_DEFAULT_COMMAND: `${prog} load fd`,
        },
      ),
    }).status();
  } finally {
    Deno.remove(stateFile);
  }
};

const load = async (s: State, args: Args) => {
  setCurrentLoader(args);
  const mode = args._.shift()?.toString() || "fd";
  if (mode in allModes) {
    setMode(mode);
    await allModes[mode].load(s, args);
  }
};

const preview = async (s: State, args: Args) => {
  setMode(s.mode);
  await allModes[s.mode].preview(s, args);
};

const run = (s: State, args: Args) => {
  const currentMode = allModes[s.mode];
  const runner: string = (() => {
    const c = args._.shift()?.toString() || "default";
    if (c == "default") {
      return currentMode.defaultRunner;
    } else {
      return c;
    }
  })();
  const modifyRunnerargs = currentMode.modifyRunnerArgs[runner];
  if (modifyRunnerargs) {
    allRunners[runner](s, modifyRunnerargs(s, args));
  } else {
    throw `run: Runner '${runner}' unavailable for mode '${s.mode}'`;
  }
};

const dispatch = async (command: Command, args: Args) => {
  const state = readState();
  switch (command) {
    case "load": {
      await load(state, args);
      break;
    }
    case "reload": {
      await load(state, state.currentLoaderArgs);
      break;
    }
    case "preview": {
      await preview(state, args);
      break;
    }
    case "run": {
      run(state, args); // non-blocking
      break;
    }
  }
};

////////////////////////////////////////////////////////////////////////////////
// Main
////////////////////////////////////////////////////////////////////////////////

const main = async () => {
  try {
    if (!Deno.env.get("MY_FZF_STATE_FILE")) {
      init();
      return;
    }
    const args = flags.parse(Deno.args);
    const command = args._.shift()?.toString() || "";
    if (isCommand(command)) {
      await dispatch(command, args);
    } else {
      throw `Unknown command: ${command}`;
    }
  } catch (exception) {
    log({ exception });
    throw exception;
  }
};

main();
