#!/usr/bin/env python3
"""Build a code tour page from tour.toml and the repository's files.

Usage: build.py TOUR_TOML --root REPO --out PAGE_HTML

TOUR_TOML (see assets/example-tour.toml):
  title = "..."
  lang = "ja"  # or "en"
  label = "repo name"  # optional
  base = "main"  # optional: tour the diff from this revision
  head = "HEAD"  # optional, with base: the other side (default: the working tree)
  [files]
  key = "path/from/root"
  renamed = { path = "new/path", old = "old/path" }  # a file renamed since base
  [[steps]]
  title = "..."
  file = "key"
  range = [start, end]
  body = '''
  <p>HTML</p>
  '''

The page embeds each file's full text as it is on disk, with the commit of
HEAD (plus "+dirty" when a toured file differs from it). Every range is
checked: a step's range, its chips (data-focus="a-b", within the step's
range) and its links (data-goto="key:a-b", within that file). Exit 1 with
every problem listed, so a tour never ships a highlight on the wrong lines.
A "<" inside <code> or a diagram is also reported: the body is inserted as
HTML, so an unescaped one silently turns into a tag instead of showing.

Diff tours: with "base", each file is shown whole with the lines removed since
base interleaved and the added ones marked, as git diff would align them.
Line numbers are still the file's own, on the head side; a removed line has
none, and is highlighted when it sits between highlighted lines. A file that
no longer exists at head is shown with its numbers at base. After the check,
the build lists every change no step highlights and every changed file the
tour leaves out, so the narrative can account for each of them.

Diagrams: <pre class="d2">...</pre> is rendered here with the d2 command into
an inline SVG (light and dark themes, following prefers-color-scheme), so d2
must be on PATH when a tour uses one. <pre class="mermaid">...</pre> is left
for the page, which renders it in the browser.
"""
import argparse
import html
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import tomllib

TEMPLATE = Path(__file__).resolve().parents[1] / 'assets/template.html'
# highlight.js common-bundle names by suffix or file name; others show unhighlighted.
LANGUAGES = {
    '.py': 'python', '.sh': 'bash', '.bash': 'bash', '.js': 'javascript', '.mjs': 'javascript',
    '.cjs': 'javascript', '.jsx': 'javascript', '.ts': 'typescript', '.tsx': 'typescript',
    '.json': 'json', '.yaml': 'yaml', '.yml': 'yaml', '.toml': 'ini', '.ini': 'ini', '.md': 'markdown',
    '.java': 'java', '.kt': 'kotlin', '.go': 'go', '.rs': 'rust', '.rb': 'ruby', '.php': 'php',
    '.c': 'c', '.h': 'c', '.cc': 'cpp', '.cpp': 'cpp', '.hpp': 'cpp', '.cs': 'csharp', '.swift': 'swift',
    '.css': 'css', '.scss': 'scss', '.html': 'xml', '.xml': 'xml', '.sql': 'sql', '.lua': 'lua',
    '.diff': 'diff', '.patch': 'diff', 'Makefile': 'makefile',
}
FOCUS = re.compile(r'''data-focus=(?:"([^"]*)"|'([^']*)')''')
GOTO = re.compile(r'''data-goto=(?:"([^"]*)"|'([^']*)')''')
RANGE = re.compile(r'(\d+)(?:-(\d+))?')
CODE = re.compile(r'<code>(.*?)</code>', re.S)
DIAGRAM = re.compile(r'''<pre class=(?:"|')(d2|mermaid)(?:"|')>(.*?)</pre>''', re.S)
D2 = re.compile(r'''<pre class=(?:"|')d2(?:"|')>(.*?)</pre>''', re.S)


def git(root, *args):
    result = subprocess.run(['git', '-C', str(root), *args], capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else None


def short_commit(root, rev):
    """rev's abbreviated commit, or raise ValueError when rev names no commit."""
    value = git(root, 'rev-parse', '--short', '--verify', '--end-of-options', rev + '^{commit}')
    if not value:
        raise ValueError(f'{rev!r} is not a commit in {root}')
    return value


def count_lines(text):
    """Lines as the page splits them, and as git diff counts them."""
    if text == '':
        return 0
    return len(text.removesuffix('\n').split('\n'))


def read_side(root, rev, relative):
    """The file's text at rev (None: the working tree), or None where it does not exist."""
    if rev is None:
        path = root / relative
        return path.read_text() if path.is_file() else None
    result = subprocess.run(['git', '-C', str(root), 'show', f'{rev}:./{relative}'], capture_output=True, text=True)
    return result.stdout if result.returncode == 0 else None


def diff_ops(old, new):
    """One character per row of the whole-file diff: ' ' kept, '-' removed, '+' added."""
    with tempfile.TemporaryDirectory() as tmp:
        a, b = Path(tmp, 'a'), Path(tmp, 'b')
        a.write_text(old)
        b.write_text(new)
        result = subprocess.run(['git', 'diff', '--no-index', '--no-color', '--no-ext-diff', '--text',
                                 '-U1000000000', str(a), str(b)], capture_output=True, text=True)
    if result.returncode == 0:
        return ' ' * count_lines(new)
    if result.returncode != 1:
        raise ValueError('git diff failed: ' + (result.stderr.strip() or 'no message'))
    ops, in_hunk = [], False
    for line in result.stdout.split('\n'):
        if not in_hunk:
            in_hunk = line.startswith('@@')
        elif line[:1] in (' ', '+', '-'):
            ops.append(line[0])
    ops = ''.join(ops)
    if len(ops) - ops.count('+') != count_lines(old) or len(ops) - ops.count('-') != count_lines(new):
        raise ValueError('could not align the diff with the files')
    return ops


def row_numbers(ops, deleted):
    """Per row, the line number ranges refer to (0 for a row without one)."""
    numbers, old, new = [], 0, 0
    for kind in ops:
        old += kind != '+'
        new += kind != '-'
        if deleted:
            numbers.append(old if kind != '+' else 0)
        else:
            numbers.append(new if kind != '-' else 0)
    return numbers


def load_files(tour, root):
    """({key: page data}, {key: row numbers}) for every file in the tour."""
    base, head = tour.get('base'), tour.get('head')
    if head and not base:
        raise ValueError('"head" needs "base"')
    for rev in (base, head):
        if rev:
            short_commit(root, rev)
    files, numbers = {}, {}
    for key, entry in tour.get('files', {}).items():
        if isinstance(entry, str):
            relative = old_relative = entry
        else:
            relative = entry.get('path')
            old_relative = entry.get('old', relative)
            if not relative:
                raise ValueError(f'file {key!r}: missing "path"')
        name = Path(relative).name
        info = {'path': relative, 'lang': LANGUAGES.get(name) or LANGUAGES.get(Path(relative).suffix, '')}
        if base is None:
            text = (root / relative).read_text()
            info['text'] = text
            numbers[key] = list(range(1, count_lines(text) + 1))
        else:
            new = read_side(root, head, relative)
            old = read_side(root, base, old_relative)
            if new is None and old is None:
                raise ValueError(f'file {key!r}: {relative} exists neither at {base} nor at {head or "the working tree"}')
            ops = diff_ops(old or '', new or '')
            info.update(text=new or '', old=old or '', ops=ops, deleted=new is None)
            if old_relative != relative:
                info['old_path'] = old_relative
            numbers[key] = row_numbers(ops, new is None)
        files[key] = info
    return files, numbers


def parse_range(text):
    match = RANGE.fullmatch(text)
    if not match:
        return None
    start = int(match.group(1))
    return start, int(match.group(2) or start)


def check(tour, lines):
    """Every problem in tour, given {key: line count}."""
    problems = []
    for field in ('title', 'files', 'steps'):
        if not tour.get(field):
            problems.append(f'missing "{field}"')
    for index, step in enumerate(tour.get('steps', [])):
        at = f'step {index + 1} ({step.get("title", "untitled")!r})'
        for field in ('title', 'file', 'range', 'body'):
            if not step.get(field):
                problems.append(f'{at}: missing "{field}"')
        key = step.get('file')
        if key not in lines:
            problems.append(f'{at}: file {key!r} is not in "files"')
            continue
        bounds = step.get('range')
        if not (isinstance(bounds, list) and len(bounds) == 2 and all(isinstance(n, int) for n in bounds)):
            problems.append(f'{at}: range must be [start, end]')
            continue
        start, end = bounds
        if not 1 <= start <= end <= lines[key]:
            problems.append(f'{at}: range {start}-{end} is outside {key} (1-{lines[key]})')
        body = step.get('body', '')
        for text in CODE.findall(body):
            if '<' in text:
                problems.append(f'{at}: <code>{text}</code> needs "<" written as "&lt;"')
        for kind, text in DIAGRAM.findall(body):
            if '<' in text:
                problems.append(f'{at}: a {kind} diagram needs "<" written as "&lt;"')
        for value in (a or b for a, b in FOCUS.findall(body)):
            focus = parse_range(value)
            if not focus or not (start <= focus[0] <= focus[1] <= end):
                problems.append(f'{at}: data-focus="{value}" must lie within the step range {start}-{end}')
        for value in (a or b for a, b in GOTO.findall(body)):
            target, _, span = value.rpartition(':')
            goto = parse_range(span)
            if target not in lines:
                problems.append(f'{at}: data-goto="{value}" names a file not in "files"')
            elif not goto or not (1 <= goto[0] <= goto[1] <= lines[target]):
                problems.append(f'{at}: data-goto="{value}" is outside {target} (1-{lines[target]})')
    return problems


def row_span(numbers, start, end):
    """The rows a highlight of lines start-end covers, removed lines between them included."""
    return numbers.index(start), len(numbers) - 1 - numbers[::-1].index(end)


def uncovered(tour, files, numbers):
    """Every run of changed rows that no step's range reaches, described by its line numbers."""
    notes = []
    for key, info in files.items():
        ops, rows = info.get('ops', ''), numbers[key]
        spans = [row_span(rows, *step['range']) for step in tour['steps'] if step['file'] == key]
        for match in re.finditer(r'[+-]+', ops):
            first, last = match.start(), match.end() - 1
            if any(a <= last and b >= first for a, b in spans):
                continue
            shown = [n for n in rows[first:last + 1] if n]
            if shown:
                where = f'L{shown[0]}' + (f'-{shown[-1]}' if shown[-1] != shown[0] else '')
            else:
                before = [n for n in rows[:first] if n]
                where = f'removed after L{before[-1]}' if before else 'removed at the top'
            notes.append(f'{key} {where} (+{match.group().count("+")} -{match.group().count("-")})')
    return notes


def unlisted(root, tour, files):
    """Files changed between the two sides that the tour does not list, under the directory its files share."""
    base, head = tour['base'], tour.get('head')
    scope = os.path.commonpath([os.path.dirname(info['path']) for info in files.values()]) or '.'
    changed = set((git(root, 'diff', '--name-only', '--relative', base, *([head] if head else []), '--', scope)
                   or '').split('\n'))
    if head is None:
        changed |= set((git(root, 'ls-files', '--others', '--exclude-standard', '--', scope) or '').split('\n'))
    listed = {info['path'] for info in files.values()} | {info.get('old_path') for info in files.values()}
    return scope, sorted(changed - listed - {''})


def render_d2(source):
    """An inline <svg> for one d2 diagram, or raise ValueError with d2's message."""
    try:
        result = subprocess.run(['d2', '--dark-theme', '200', '--pad', '8', '-', '-'],
                                input=source, capture_output=True, text=True)
    except FileNotFoundError:
        raise ValueError('a step has a d2 diagram, but the d2 command is not on PATH') from None
    if result.returncode != 0:
        raise ValueError('d2 failed:\n' + (result.stderr.strip() or 'no message'))
    svg = result.stdout[result.stdout.index('<svg'):]
    # Center the drawing when the zoom dialog is wider than the diagram's aspect.
    return svg.replace('preserveAspectRatio="xMinYMin meet"', 'preserveAspectRatio="xMidYMid meet"', 1)


def render_diagrams(tour):
    """Replace every d2 <pre> in the step bodies with its rendered SVG."""
    problems = []
    for index, step in enumerate(tour['steps']):
        def replace(match):
            try:
                return "<figure class='diagram'>" + render_d2(html.unescape(match.group(1))) + '</figure>'
            except ValueError as error:
                problems.append(f'step {index + 1} ({step["title"]!r}): {error}')
                return match.group(0)
        step['body'] = D2.sub(replace, step['body'])
    return problems


def revision(root, tour, files):
    """What the header names: HEAD's commit, or the two sides of a diff tour."""
    head = tour.get('head')
    end = short_commit(root, head) if head else (git(root, 'rev-parse', '--short', 'HEAD') or 'unknown')
    paths = ({info['path'] for info in files.values()} | {info.get('old_path') for info in files.values()}) - {None}
    if not head and git(root, 'status', '--porcelain', '--', *paths):
        end += '+dirty'
    return f'{short_commit(root, tour["base"])}..{end}' if tour.get('base') else end


def build(tour_path, root, out):
    with open(tour_path, 'rb') as stream:
        tour = tomllib.load(stream)
    root = Path(root).resolve()
    files, numbers = load_files(tour, root)
    lines = {key: sum(1 for n in rows if n) for key, rows in numbers.items()}
    problems = check(tour, lines)
    if not problems:
        problems = render_diagrams(tour)
    if problems:
        sys.exit('error: the tour has problems:\n  ' + '\n  '.join(problems))
    commit = revision(root, tour, files)
    data = {'title': tour['title'], 'lang': tour.get('lang', 'en'), 'label': tour.get('label', root.name),
            'commit': commit, 'files': files, 'steps': tour['steps']}
    if tour.get('base'):
        data['diff'] = {'added': sum(f['ops'].count('+') for f in files.values()),
                        'removed': sum(f['ops'].count('-') for f in files.values())}
    # Inside <script>: keep the JSON from closing the element or opening a comment.
    payload = json.dumps(data, ensure_ascii=False).replace('</', '<\\/').replace('<!--', '<\\!--')
    page = TEMPLATE.read_text()
    for marker in ('/*__TOUR__*/', '__TITLE__'):
        if page.count(marker) != 1:
            sys.exit(f'error: the template must contain {marker} once')
    page = page.replace('__TITLE__', html.escape(tour['title'])).replace('/*__TOUR__*/', payload)
    Path(out).parent.mkdir(parents=True, exist_ok=True)
    Path(out).write_text(page)
    size = len(page.encode())
    print(f'wrote {out}: {len(tour["steps"])} steps, {len(files)} files, {"diff" if tour.get("base") else "commit"} {commit}, {size // 1024} KiB')
    if size > 15 * 1024 * 1024:
        print('warning: the page is near the 16MB artifact limit; tour fewer or smaller files.', file=sys.stderr)
    if tour.get('base'):
        notes = uncovered(tour, files, numbers)
        if notes:
            print('note: changes no step highlights:\n  ' + '\n  '.join(notes))
        scope, missing = unlisted(root, tour, files)
        if missing:
            print(f'note: changed files under {scope}/ the tour does not list:\n  ' + '\n  '.join(missing))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('tour')
    parser.add_argument('--root', default='.')
    parser.add_argument('--out', required=True)
    args = parser.parse_args()
    try:
        build(args.tour, args.root, args.out)
    except (OSError, ValueError) as error:
        sys.exit(f'error: {error}')


if __name__ == '__main__':
    main()
