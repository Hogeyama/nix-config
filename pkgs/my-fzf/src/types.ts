
import * as flags from "https://deno.land/std@0.133.0/flags/mod.ts";

////////////////////////////////////////////////////////////////////////////////
// Types
////////////////////////////////////////////////////////////////////////////////

// Common
///////////

export type Opt = flags.Args;

// Command
////////////

export type Command = "load" | "reload" | "preview" | "run";
export const isCommand = (s: string): s is Command => {
  return (
    s === "load" || //
    s === "reload" ||
    s === "preview" ||
    s === "run"
  );
};

// Mode
/////////

export type Mode = string

// Runner
///////////

export type Runner = string

export type NvimOpt = {
  leave?: boolean;
  tab?: boolean;
  line?: number;
  buf?: number;
  _: (string | number)[];
};

export type VifmOpt = { _: [string] };

export type RunnerOpt = Opt

export type State = {
  mode: Mode;
  cwd: string; // absolute path to the (virtual) current directory
  currentLoader: Opt;
};

export type ModeImpl<M extends Mode> = {
  mode: M;
  load: LoadImpl;
  preview: PreviewImpl;
  defaultRunner: Runner;
  modifyRunnerOpt: {
    [key in Runner]?: (s: State, _: Opt) => RunnerOpt;
  };
};


export type RunnerImpl = (
  s: State,
  opts: RunnerOpt,
) => Promise<void>;

export type AllRunners = {
  [key in Runner]: RunnerImpl;
};


export type LoadImpl = (s: State, opts: Opt) => Promise<void>;

export type PreviewImpl = (s: State, o: Opt) => Promise<void>;
