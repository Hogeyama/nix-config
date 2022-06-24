import { nvrCommand, RelPath, resolve } from "../lib.ts";
import { Args, Runner, State } from "../types.ts";

const defaultNvimOpts = { leave: true };

export const runner: Runner = {
  name: "nvim",
  run: async (s: State, args: Args) => {
    const opt = Object.assign({}, defaultNvimOpts, args);
    const lOpt = opt.line ? `+${opt.line}` : "";
    // TODO init.vim にコマンドを定義したほうがよいかも
    if (opt.buf) {
      const buf = opt.buf;
      if (opt.tab) {
        await nvrCommand(`tabnew`);
        await nvrCommand(`buffer ${lOpt} ${buf}`);
        await nvrCommand(`MoveToLastTab`);
      } else if (opt.leave) {
        await nvrCommand(`stopinsert`);
        await nvrCommand(`MoveToLastWin`);
        await nvrCommand(`buffer ${lOpt} ${buf}`);
        await nvrCommand(`FloatermHide! fzf`);
      } else {
        await nvrCommand(`stopinsert`);
        await nvrCommand(`MoveToLastWin`);
        await nvrCommand(`buffer ${lOpt} ${buf}`);
        await nvrCommand(`MoveToLastWin`);
        await nvrCommand(`startinsert`);
      }
    } else {
      const relPath = opt._.shift()?.toString();
      if (!relPath) {
        throw `runNvim: No file specified`;
      }
      const path = resolve(s, RelPath(relPath)).val;
      if (opt.tab) {
        await nvrCommand(`execute 'tabedit ${lOpt} '.fnameescape('${path}')`);
        await nvrCommand(`MoveToLastTab`);
      } else if (opt.leave) {
        await nvrCommand(`stopinsert`);
        await nvrCommand(`MoveToLastWin`);
        await nvrCommand(`execute 'edit ${lOpt} '.fnameescape('${path}')`);
        await nvrCommand(`FloatermHide! fzf`);
      } else {
        await nvrCommand(`stopinsert`);
        await nvrCommand(`MoveToLastWin`);
        await nvrCommand(`execute 'edit ${lOpt} '.fnameescape('${path}')`);
        await nvrCommand(`MoveToLastWin`);
        await nvrCommand(`startinsert`);
      }
    }
  },
};

export const cmd = {
  default: (prog: string) => `${prog} run nvim {}`,
  tabEdit: (prog: string) => `${prog} run nvim {} --tab`,
};
