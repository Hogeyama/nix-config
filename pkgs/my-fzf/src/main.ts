#!/usr/bin/env -S deno run --no-check --allow-run --allow-read --allow-write --allow-env
import * as flags from "https://deno.land/std@0.133.0/flags/mod.ts";

import { Command, isCommand, Opt, Runner, State } from "./types.ts";
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
    if (!prog) throw "MY_FZF_PROG not defined"

    writeState({
      mode: "fd",
      cwd: Deno.cwd(),
      currentLoader: { _: [] },
    });

    await Deno.run({
      cmd: ["fzf"].concat(fzfOpts(prog)),
      stdin: "inherit",
      stdout: "piped",
      env: Object.assign(
        {},
        Deno.env.toObject(),
        {
          FZF_DEFAULT_COMMAND: `${prog} load`,
        },
      ),
    }).status();
  } finally {
    Deno.remove(stateFile);
  }
};

const load = async (s: State, opt: Opt) => {
  setCurrentLoader(opt);
  const mode = opt._.shift()?.toString() || "fd";
  if (mode in allModes) {
    setMode(mode);
    await allModes[mode].load(s, opt);
  }
};

const preview = async (s: State, opt: Opt) => {
  setMode(s.mode);
  await allModes[s.mode].preview(s, opt);
};

const run = (s: State, opt: Opt) => {
  const currentMode = allModes[s.mode];
  const runner: Runner = (() => {
    const c = opt._.shift()?.toString() || "default";
    if (c == "default") {
      return currentMode.defaultRunner;
    } else {
      return c;
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
    if (!Deno.env.get("MY_FZF_STATE_FILE")) {
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
