#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FUNC_RE = re.compile(r"^\s*(?:static\s+)?func\s+(_[A-Za-z0-9_]+)\s*\(([^)]*)\)\s*(?:->\s*([^:]+))?:")

CALLBACKS = {
    "_notification": {
        "argc": 1,
        "return_type": "void",
        "reason": "Godot Object._notification callback must be func _notification(what: int) -> void; helper functions must use another name.",
    },
}

errors: list[str] = []


def clean_type(value: str | None) -> str:
    return "" if value is None else value.strip()


def split_args(value: str) -> list[str]:
    if value.strip() == "":
        return []
    return [part.strip() for part in value.split(",")]


for path in sorted(ROOT.rglob("*.gd")):
    if "/.godot/" in path.as_posix():
        continue
    text = path.read_text(encoding="utf-8")
    for line_number, line in enumerate(text.splitlines(), start=1):
        match = FUNC_RE.match(line)
        if match is None:
            continue
        name = match.group(1)
        if name not in CALLBACKS:
            continue
        args = split_args(match.group(2))
        return_type = clean_type(match.group(3))
        expected = CALLBACKS[name]
        if len(args) != expected["argc"] or return_type != expected["return_type"] or line.lstrip().startswith("static func"):
            errors.append(f"{path.relative_to(ROOT)}:{line_number}: invalid {name} signature: {line.strip()} -- {expected['reason']}")

if errors:
    print("GDScript builtin callback signature gate FAILED:")
    for error in errors:
        print(f" - {error}")
    raise SystemExit(1)

print("GDScript builtin callback signature gate OK")
