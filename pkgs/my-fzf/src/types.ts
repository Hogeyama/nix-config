import * as flags from "https://deno.land/std@0.133.0/flags/mod.ts";

// Common
////////////////////////////////////////////////////////////////////////////////

export type Args = flags.Args;

export type Command = "load" | "reload" | "preview" | "run";

export const isCommand = (s: string): s is Command => {
  return (
    s === "load" || //
    s === "reload" ||
    s === "preview" ||
    s === "run"
  );
};

export type State = {
  id: string;
  mode: string;
  cwd: string; // absolute path to the (virtual) current directory
  currentLoaderArgs: Args;
};

// Interfaces
////////////////////////////////////////////////////////////////////////////////

// XXX ad-hoc!
type ModifyRunnerArgs =
  | ((s: State, _: Args) => Args)
  | { async_: ((s: State, _: Args) => Promise<Args>) };

export type Mode = {
  mode: string;
  load: Load;
  preview: Preview;
  defaultRunner: string;
  modifyRunnerArgs: Record<string, ModifyRunnerArgs>;
};

export type Runner = {
  name: string;
  run(s: State, args: Args): Promise<void>;
};

export type Load = (s: State, args: Args) => Promise<void>;

export type Preview = (s: State, args: Args) => Promise<void>;
