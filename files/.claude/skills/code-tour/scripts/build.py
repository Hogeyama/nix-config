#!/usr/bin/env python3
"""Build a code tour page from tour.json and the repository's files.

Usage: build.py TOUR_JSON --root REPO --out PAGE_HTML

TOUR_JSON:
  {"title": "...", "lang": "ja" | "en", "label": "repo name (optional)",
   "files": {"key": "path/from/root", ...},
   "steps": [{"title": "...", "file": "key", "range": [start, end], "body": "<p>HTML</p>"}, ...]}

The page embeds each file's full text as it is on disk, with the commit of
HEAD (plus "+dirty" when a toured file differs from it). Every range is
checked: a step's range, its chips (data-focus="a-b", within the step's
range) and its links (data-goto="key:a-b", within that file). Exit 1 with
every problem listed, so a tour never ships a highlight on the wrong lines.
"""
import argparse
import html
import json
from pathlib import Path
import re
import subprocess
import sys

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
# Either quote: tour.json bodies use single quotes to avoid escaping.
FOCUS = re.compile(r'''data-focus=(?:"([^"]*)"|'([^']*)')''')
GOTO = re.compile(r'''data-goto=(?:"([^"]*)"|'([^']*)')''')
RANGE = re.compile(r'(\d+)(?:-(\d+))?')


def git(root, *args):
    result = subprocess.run(['git', '-C', str(root), *args], capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else None


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
        at = f'step {index} ({step.get("title", "untitled")!r})'
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


def build(tour_path, root, out):
    tour = json.loads(Path(tour_path).read_text())
    root = Path(root).resolve()
    files, lines = {}, {}
    for key, relative in tour.get('files', {}).items():
        path = root / relative
        text = path.read_text()
        name = Path(relative).name
        files[key] = {'path': relative, 'text': text,
                      'lang': LANGUAGES.get(name) or LANGUAGES.get(Path(relative).suffix, '')}
        lines[key] = len(text.rstrip('\n').split('\n'))
    problems = check(tour, lines)
    if problems:
        sys.exit('error: the tour has problems:\n  ' + '\n  '.join(problems))
    commit = git(root, 'rev-parse', '--short', 'HEAD') or 'unknown'
    if git(root, 'status', '--porcelain', '--', *tour['files'].values()):
        commit += '+dirty'
    data = {'title': tour['title'], 'lang': tour.get('lang', 'en'), 'label': tour.get('label', root.name),
            'commit': commit, 'files': files, 'steps': tour['steps']}
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
    print(f'wrote {out}: {len(tour["steps"])} steps, {len(files)} files, commit {commit}, {size // 1024} KiB')
    if size > 15 * 1024 * 1024:
        print('warning: the page is near the 16MB artifact limit; tour fewer or smaller files.', file=sys.stderr)


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
