#!/usr/bin/env -S deno run --no-check --allow-run --allow-read --allow-write --allow-env
import * as flags from "https://deno.land/std@0.133.0/flags/mod.ts";

import { Args, Command, isCommand, State } from "./types.ts";
import {
  getOrCreateStateFile,
  getProgName,
  log,
  readState,
  setCurrentLoaderArgs,
  setMode,
  writeState,
} from "./lib.ts";
import { allModes, allRunners, fzfOpts } from "./config.ts";

const spawnFzf = async () => {
  const prog = getProgName();

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
  log("spawnFzf");
};

const load = async (s: State, args: Args) => {
  log({ context: "load", args });
  setCurrentLoaderArgs(args);
  const mode = args._.shift()?.toString() || "fd";
  log({ args, mode });
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
    const { stateFile, created } = getOrCreateStateFile();
    if (created) {
      try {
        await spawnFzf();
      } finally {
        Deno.removeSync(stateFile);
      }
    } else {
      const args = flags.parse(Deno.args);
      const command = args._.shift()?.toString() || "";
      if (isCommand(command)) {
        await dispatch(command, args);
      } else {
        throw `Unknown command: ${command}`;
      }
    }
  } catch (e) {
    log({ e, stack: e.stack });
    Deno.exit(1);
  }
};

main();
