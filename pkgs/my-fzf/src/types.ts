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
  mode: string;
  cwd: string; // absolute path to the (virtual) current directory
  currentLoaderArgs: Args;
};

// Interfaces
////////////////////////////////////////////////////////////////////////////////

export type ModeImpl = {
  mode: string;
  load: LoadImpl;
  preview: PreviewImpl;
  defaultRunner: string;
  modifyRunnerArgs: Record<string, ((s: State, _: Args) => Args)>;
};

export type RunnerImpl = (
  s: State,
  args: Args,
) => Promise<void>;

export type LoadImpl = (s: State, args: Args) => Promise<void>;

export type PreviewImpl = (s: State, args: Args) => Promise<void>;
