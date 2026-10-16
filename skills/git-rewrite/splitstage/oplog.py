"""全呼び出しの JSONL ログ。操作数の客観測定に使う。"""

import json
import time
from pathlib import Path


def append(log_path, record):
    log_path = Path(log_path)
    log_path.parent.mkdir(parents=True, exist_ok=True)
    record = dict(record, ts=round(time.time(), 3))
    with log_path.open("a") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")


def count(log_path):
    try:
        with Path(log_path).open() as f:
            return sum(1 for _ in f)
    except FileNotFoundError:
        return 0
