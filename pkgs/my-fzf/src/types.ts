
import * as flags from "https://deno.land/std@0.133.0/flags/mod.ts";

////////////////////////////////////////////////////////////////////////////////
// Types
////////////////////////////////////////////////////////////////////////////////

// Common
///////////

export type Args = flags.Args;

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

export type State = {
  mode: Mode;
  cwd: string; // absolute path to the (virtual) current directory
  currentLoaderArgs: Args;
};

export type ModeImpl<M extends Mode> = {
  mode: M;
  load: LoadImpl;
  preview: PreviewImpl;
  defaultRunner: Runner;
  modifyRunnerArgs: {
    [key in Runner]?: (s: State, _: Args) => Args;
  };
};


export type RunnerImpl = (
  s: State,
  args: Args,
) => Promise<void>;

export type AllRunners = {
  [key in Runner]: RunnerImpl;
};


export type LoadImpl = (s: State, opts: Args) => Promise<void>;

export type PreviewImpl = (s: State, o: Args) => Promise<void>;
