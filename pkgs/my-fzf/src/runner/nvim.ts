import { nvrCommand, RelPath, resolve } from "../lib.ts";
import { Args, Runner, State } from "../types.ts";

const defaultNvimOpts = { leave: true };

export const runNvim: Runner = async (s: State, args: Args) => {
  const opt = Object.assign({}, defaultNvimOpts, args);
  const lOpt = opt.line ? `+${opt.line}` : "";
  // TODO init.vim にコマンドを定義したほうがよいかも
  if (opt.buf) {
    const buf = opt.buf;
    if (opt.tab) {
      await nvrCommand(s, `tabnew`);
      await nvrCommand(s, `buffer ${lOpt} ${buf}`);
      await nvrCommand(s, `MoveToLastTab`);
    } else if (opt.leave) {
      await nvrCommand(s, `stopinsert`);
      await nvrCommand(s, `MoveToLastWin`);
      await nvrCommand(s, `buffer ${lOpt} ${buf}`);
      await nvrCommand(s, `FloatermHide! fzf`);
    } else {
      await nvrCommand(s, `stopinsert`);
      await nvrCommand(s, `MoveToLastWin`);
      await nvrCommand(s, `buffer ${lOpt} ${buf}`);
      await nvrCommand(s, `MoveToLastWin`);
      await nvrCommand(s, `startinsert`);
    }
  } else {
    const relPath = opt._.shift()?.toString();
    if (!relPath) {
      throw `runNvim: No file specified`;
    }
    const path = resolve(s, RelPath(relPath)).val;
    if (opt.tab) {
      await nvrCommand(s, `execute 'tabedit ${lOpt} '.fnameescape('${path}')`);
      await nvrCommand(s, `MoveToLastTab`);
    } else if (opt.leave) {
      await nvrCommand(s, `stopinsert`);
      await nvrCommand(s, `MoveToLastWin`);
      await nvrCommand(s, `execute 'edit ${lOpt} '.fnameescape('${path}')`);
      await nvrCommand(s, `FloatermHide! fzf`);
    } else {
      await nvrCommand(s, `stopinsert`);
      await nvrCommand(s, `MoveToLastWin`);
      await nvrCommand(s, `execute 'edit ${lOpt} '.fnameescape('${path}')`);
      await nvrCommand(s, `MoveToLastWin`);
      await nvrCommand(s, `startinsert`);
    }
  }
};
