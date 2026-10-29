---
name: code-tour
description: Build a guided code tour as a private claude.ai Artifact. The narrative runs step by step beside the real source files, with the step's lines highlighted, chips that highlight sub-ranges, and links that jump to definitions. Viewers can comment on lines. Use when the user asks for a code tour, a walkthrough of a file, feature or flow, "ツアー", "コードを順に追って説明して", or a replacement for CodeTour or diffity-tour.
---

# Code tour

The page comes from `assets/template.html`, assembled by `scripts/build.py`, both in this skill's directory. You write only `tour.toml`: the narrative and the line ranges.

## Steps

1. **Scope.** Turn the question into one flow you can walk in 6 to 15 steps. The overview (`steps[0]`) states what is left out.
2. **Read the code** along that flow, and find out the order things happen at runtime. Configuration can change that order (a lazy connection, a deferred import, a hook that runs later than its place in the file suggests). Take every line number from the file as it is now (`grep -n`, or Read with an offset), never from memory.
3. **Write `tour.toml`** in the scratchpad (format below). Write it in the user's language and set `lang` to match.
4. **Build:**
   ```
   python3 -I <this skill>/scripts/build.py <scratchpad>/tour.toml --root <repo root> --out <scratchpad>/<slug>.html
   ```
   `<slug>` is a short file name for the tour, such as `addon-tour`. The build embeds the files' full text and checks every range. Fix everything it reports and run it again. Do not publish a tour that failed the check. The check covers line numbers only, so also re-read each body against its highlighted code and fix any sentence the code does not bear out.
5. **Publish.** For a new tour, call Artifact with `action: "quickstart"` and `intent: "other"`, as the Artifact tool requires for every new artifact. Then publish the built page as it is: `file_path` with `icon: "code"` and a one-sentence `description`. To revise a tour, rebuild to the same `--out` and publish that same `file_path`.
6. **Reply** with the URL. Say what the tour covers, and that it is a snapshot of the commit shown in its header that will not follow later changes.

## tour.toml

```toml
title = "settings.py ツアー"
lang = "ja"
label = "claude-devcontainer"

[files]
"settings.py" = ".devcontainer/claude/scripts/settings.py"

[[steps]]
title = "..."
file = "settings.py"
range = [1, 35]
body = '''
<p>...</p>
'''
```

`assets/example-tour.toml` is a complete tour of 15 steps.

- `title` is the artifact's name: a short noun phrase, never a sentence.
- `label` is the repository's name, shown in the header. Without it, the header shows the name of the `--root` directory, which is often unhelpful (`workspace`).
- `files` maps a short key to a path relative to `--root`. Steps and links name files by key. List a file only when a step highlights it or a `ref` links into it, since each one is embedded whole. Name any other file as plain `<code>`.
- `steps[0]` is the overview; "step 1" below means `steps[1]`. Give the overview an orienting range, such as the module docstring.
- Every line number (`range`, `data-focus`, `data-goto`) is the file's own line number: 1-based, inclusive, and never relative to the step.

### Body HTML

| Markup | Effect |
|---|---|
| `<p>`, `<ul>`/`<ol>`/`<li>`, `<strong>`, `<code>` | Running text |
| `<p class='take'>...</p>` | Closing takeaway, under a "覚えておくこと" label (ja) |
| `<div class='chips'><button class='chip' data-focus='12-20'>label</button>...</div>` | Highlights a sub-range of the step's range |
| `<a class='ref' data-goto='key:40-52'><code>name</code></a>` | Jumps to a range in any listed file, inside or outside the step's range |
| `<div class='tbl'><table>...</table></div>` | A table that scrolls on its own when narrow |
| `<div class='flow'><span>a</span><i>→</i><span>b</span></div>` | A one-line flow of boxes |

Write each body as a `'''` literal string, breaking lines between elements. Nothing inside it is escaped for TOML, so attributes can use either quote. HTML escaping still applies: write `<` as `&lt;` and `&` as `&amp;`, as in `<code>Vec&lt;T&gt;</code>`. The build reports a `<` left inside `<code>`. Do not use headings (the step title is the heading), scripts, images or inline styles.

## Writing the steps

- **Top-down, in execution order.** Step 1 is the real entry point (a command, a route, a script that calls in). Order the later steps by when the code runs, not by where it sits in the file. Introduce schemas, constants and helpers at the step that first uses them, as a `ref` link or a step of their own, never as a prelude or a detour in the middle of the flow.
- **One concept per step.** For a range over about 30 lines, add chips for its parts.
- **Each body goes transition → explanation → takeaway.** Open with one sentence that ties it to the previous step. Explain why the code is shaped this way (design decisions, trade-offs, edge cases), not what the reader can already see. Close with a `take`: a gotcha, or what to touch to change this. Aim for 150 to 300 words in English, or 300 to 600 characters in Japanese, not counting tags. If a body runs past about 400 words (800 characters), split the step.
- **Link every symbol whose location you know** with `ref`. Use plain `<code>` for anything you have not located.
- **Step 0** gives the overview: why the code exists, a `flow` of the path, a table of the moving parts, the configuration or mode the tour assumes, and what it leaves out.
- **The last step** is titled "まとめ" (or "Putting it together"). It reuses an earlier range and gives the mental model in two or three sentences, the two or three key design decisions, a table of where to change what, and what to read next.

## Comments

Viewers comment on lines in the page. Read the comments with `ArtifactComments` `action: "read"` when the user asks. A comment anchored at `#code > div:nth-of-type(1) > div:nth-of-type(N)` is on line N of the file that was being shown. Its `[location]` row quotes that line's text, so confirm the line from it. Answer in the thread. Resolve a thread only after acting on it; leave a question open for the commenter.
