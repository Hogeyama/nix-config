---
name: code-tour
description: Build a guided code tour as a private claude.ai Artifact. The narrative runs step by step beside the real source files, with the step's lines highlighted, chips that highlight sub-ranges, and links that jump to definitions. Viewers can comment on lines. With a base revision, the tour explains a diff instead: each file shows whole, with removed lines interleaved and added lines marked. Use when the user asks for a code tour, a walkthrough of a file, feature or flow, an explanation of a diff, commit, branch or PR, "ツアー", "コードを順に追って説明して", "diff 解説", "この変更を説明して", or a replacement for CodeTour or diffity-tour.
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

## Diff tours

When the question is about a change (a commit, a branch, the working tree, a PR), set `base` in `tour.toml`. The build then reads each file at both sides and shows the whole file as a diff: removed lines interleaved where git diff puts them, added lines marked, and `+N −M` in the header.

```toml
base = "main"      # the old side: any revision
head = "HEAD"      # the new side; leave it out to tour the working tree

[files]
"build.py" = "scripts/build.py"
"tour.toml" = { path = "assets/example-tour.toml", old = "assets/example-tour.json" }  # renamed since base
```

- Line numbers are still the file's own, on the new side. A removed line has none: highlight the new lines on both sides of it, and the removed lines between them are highlighted too. For a pure deletion, that means the lines just before and after the gap. A file deleted since `base` keeps its old numbers.
- Take line numbers from the new side as it is now, exactly as for a plain tour. Read the removed lines with `git diff <base>` or `git show <base>:<path>`.
- After a successful build, the build lists the changes no step highlights and the changed files under the tour's directory that `files` leaves out. Each of them belongs in a step, or in the overview's list of what the tour leaves out. These notes are not errors; they are there so the narrative accounts for every change.

Diff tours follow the same writing rules, with these differences:

- The overview says what the change is for, what was wrong or missing before it, and lists the changed files in a table with what each change does. The `flow` shows the path the change touches.
- Order the steps by when the changed code runs, as in a plain tour, not by file or by hunk. Bring in unchanged code only where the reader needs it to follow a change, and say so.
- In each body, say what the old code did, what the new code does, and why the change takes this shape. Do not restate the added lines; the reader can see them in color.
- The まとめ gives the change's effect on behavior, what it leaves as it was, and what to check when reviewing it.

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
- `steps[0]` is the overview. Give it an orienting range, such as the module docstring.
- The page numbers steps from 1, so `steps[0]` appears as step 1 (ステップ1) and `steps[n]` as step n+1. When a body refers to another step by number, write the number the page shows, never the array index. A title or "the next step" (次のステップ) is safer still, since it survives inserting or removing a step.
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
| `<pre class='mermaid'>...</pre>` | A Mermaid diagram, rendered in the browser |
| `<pre class='d2'>...</pre>` | A D2 diagram, rendered to SVG by the build (needs `d2` on PATH) |

Diagrams sit in the narrow narrative column; a click opens one full-size in a modal. Use one when the shape of the flow (a sequence, a state machine, who calls whom) says more than a `flow` line or a table can, and keep it to about a dozen nodes. Inside a diagram, write `-->` as `--&gt;` and `->` as `-&gt;`, like any other text in the body. In D2, quote a name that contains a dot (`"tour.toml"`), or D2 nests it as a container. A D2 syntax error fails the build with D2's message.

Write each body as a `'''` literal string, breaking lines between elements. Nothing inside it is escaped for TOML, so attributes can use either quote. HTML escaping still applies: write `<` as `&lt;` and `&` as `&amp;`, as in `<code>Vec&lt;T&gt;</code>`. The build reports a `<` left inside `<code>`. Do not use headings (the step title is the heading), scripts, images or inline styles; draw a picture as a diagram instead.

## Writing the steps

- **Top-down, in execution order.** The first step after the overview is the real entry point (a command, a route, a script that calls in). Order the later steps by when the code runs, not by where it sits in the file. Introduce schemas, constants and helpers at the step that first uses them, as a `ref` link or a step of their own, never as a prelude or a detour in the middle of the flow.
- **One concept per step.** For a range over about 30 lines, add chips for its parts.
- **Each body goes transition → explanation → takeaway.** Open with one sentence that ties it to the previous step. Explain why the code is shaped this way (design decisions, trade-offs, edge cases), not what the reader can already see. Close with a `take`: a gotcha, or what to touch to change this. Aim for 150 to 300 words in English, or 300 to 600 characters in Japanese, not counting tags. If a body runs past about 400 words (800 characters), split the step.
- **Link every symbol whose location you know** with `ref`. Use plain `<code>` for anything you have not located.
- **The overview** (`steps[0]`) explains why the code exists and gives a `flow` of the path, a table of the moving parts, the configuration or mode the tour assumes, and what it leaves out.
- **The last step** is titled "まとめ" (or "Putting it together"). It reuses an earlier range and gives the mental model in two or three sentences, the two or three key design decisions, a table of where to change what, and what to read next.

## Comments

Viewers comment on lines in the page. Read the comments with `ArtifactComments` `action: "read"` when the user asks. A comment anchored at `#code > div:nth-of-type(1) > div:nth-of-type(N)` is on line N of the file that was being shown. Its `[location]` row quotes that line's text, so confirm the line from it. In a diff tour, N counts rows, removed lines included, so it is not the line number; go by the quoted text. Answer in the thread. Resolve a thread only after acting on it; leave a question open for the commenter.
