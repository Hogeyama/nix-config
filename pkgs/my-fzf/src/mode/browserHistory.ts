import { pathExists, print, printHeader, RelPath } from "../lib.ts";
import { LoadImpl, ModeImpl, PreviewImpl, State } from "../types.ts";

const getFirefoxDb = (s: State): string => {
  const home = Deno.env.get("HOME");
  const searchPath = `${home}/.mozilla/firefox`;
  if (!pathExists(s, RelPath(searchPath))) {
    throw `${searchPath} does not exist`;
  }
  const defaultProfDir = Array.from(Deno.readDirSync(searchPath)).find((f) => {
    return f.isDirectory && f.name.match(/default/);
  });
  if (!defaultProfDir) {
    throw "firefox: No default profile found";
  }
  const db = `${searchPath}/${defaultProfDir.name}/places.sqlite`;
  if (!pathExists(s, RelPath(db))) {
    throw `${db} does not exist`;
  }
  return db;
};

const getChromeDb = (s: State): string => {
  const home = Deno.env.get("HOME");
  const db = `${home}/.config/google-chrome/Default/History`;
  if (!pathExists(s, RelPath(db))) {
    throw `${db} does not exist`;
  }
  return db;
};

const sqliteRecordSep = String.fromCodePoint(0x2009); // U+2009: Thin space


const loadBrowserHistory: LoadImpl = async (s, args) => {
  printHeader(s);
  const pat = args.pattern || "%";
  const cond = `url LIKE '%${pat}%' OR title LIKE '%${pat}%'`;
  const browser = Deno.env.get("BROWSER") || "firefox";
  let copyDb: string | undefined = undefined;
  try {
    copyDb = Deno.makeTempFileSync({ suffix: ".sqlite" });
    let sql: string;
    if (browser.match("firefox")) {
      const origDb = getFirefoxDb(s);
      Deno.copyFileSync(origDb, copyDb);
      sql = `
      SELECT
        url,
        title,
        DATETIME(last_visit_date / 1000000, 'unixepoch', '+9 hours') AS date
      FROM
        moz_places
      WHERE
        ${cond}
      ORDER BY
        date DESC
      LIMIT
        10000
      ;
    `;
    } else if (browser.match("chrome")) {
      const origDb = getChromeDb(s);
      Deno.copyFileSync(origDb, copyDb);
      sql = `
      SELECT
        url,
        title,
        DATETIME(last_visit_time / 1000000 + (strftime('%s', '1601-01-01') ), 'unixepoch', '+9 hours') AS date
      FROM
        urls
      WHERE
        ${cond}
      GROUP BY
        title
      ORDER BY
        date DESC
      LIMIT
        10000
      ;
    `;
    } else {
      throw `browser: ${browser} is not supported`;
    }
    const p = Deno.run({
      cmd: ["sqlite3"].concat([
        "-batch",
        "-batch",
        "-readonly",
        "-separator",
        sqliteRecordSep,
        copyDb,
      ]),
      stdin: "piped",
    });
    p.stdin.write(new TextEncoder().encode(sql));
    await p.status();
  } finally {
    copyDb && Deno.removeSync(copyDb);
  }
};

type BrowserItem = {
  url: string;
  title: string;
  date: string;
};
const parseBrowserItem = (item: string): BrowserItem => {
  const [url, title, date] = item.trim().split(sqliteRecordSep);
  return { url, title, date };
};

// deno-lint-ignore require-await
const previewUrl: PreviewImpl = async (_s, args) => {
  const rawItem = args._.at(0)?.toString();
  if (!rawItem) {
    throw `browser: No item given`;
  }
  const { url, title, date } = parseBrowserItem(rawItem);
  print(`URL:    ${url}`);
  print(`Title:  ${title}`);
  print(`Access: ${date}`);
};

export const browserHistory: ModeImpl = {
  mode: "browser-history",
  load: loadBrowserHistory,
  preview: previewUrl,
  defaultRunner: "browser",
  modifyRunnerArgs: {
    browser: (_, args) => {
      const rawItem = args._.at(0)?.toString();
      if (!rawItem) {
        throw `browser: No item given`;
      }
      const { url } = parseBrowserItem(rawItem);
      return Object.assign(args, { _: [url] });
    },
  },
};

