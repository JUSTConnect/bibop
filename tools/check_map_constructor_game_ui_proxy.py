#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAME_UI = ROOT / "scripts/ui/game_ui.gd"
SESSION_STATE = ROOT / "scripts/ui/map_constructor/map_constructor_session_state.gd"
MAP_CONSTRUCTOR_DIR = ROOT / "scripts/ui/map_constructor"

DIRECT_UI_RE = re.compile(
    r"\bui\.(?!runtime_map_constructor_)(?!map_constructor_state\b)"
    r"(map_constructor_[A-Za-z0-9_]*|selected_map_constructor_[A-Za-z0-9_]*|"
    r"pending_map_constructor_[A-Za-z0-9_]*|room_visual_preset_preview|selected_room_visual_preset_id)\b"
)


def strip_comments_and_strings(source: str) -> str:
    out: list[str] = []
    i = 0
    n = len(source)
    in_string: str | None = None
    triple = False
    while i < n:
        ch = source[i]
        nxt3 = source[i:i+3]
        if in_string is not None:
            if ch == "\n":
                out.append("\n")
                i += 1
                continue
            out.append(" ")
            if triple:
                if nxt3 == in_string * 3:
                    out.extend([" ", " "])
                    i += 3
                    in_string = None
                    triple = False
                else:
                    i += 1
                continue
            if ch == "\\":
                if i + 1 < n:
                    out.append(" ")
                    i += 2
                else:
                    i += 1
                continue
            if ch == in_string:
                in_string = None
            i += 1
            continue
        if nxt3 in ('"""', "'''"):
            in_string = nxt3[0]
            triple = True
            out.extend("   ")
            i += 3
            continue
        if ch in ('"', "'"):
            in_string = ch
            triple = False
            out.append(" ")
            i += 1
            continue
        if ch == "#":
            while i < n and source[i] != "\n":
                out.append(" ")
                i += 1
            continue
        out.append(ch)
        i += 1
    return "".join(out)


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> int:
    game_ui_clean = strip_comments_and_strings(GAME_UI.read_text())
    for match in re.finditer(r"func\s+_(get|set)\s*\([^)]*\)(?::[^\n]*)?\n(?P<body>(?:\t.*(?:\n|$)|\s*\n)*)", game_ui_clean):
        body = match.group("body")
        if "map_constructor_state" in body:
            fail(f"{GAME_UI.relative_to(ROOT)} contains Map Constructor dynamic _{match.group(1)} proxy")

    session_clean = strip_comments_and_strings(SESSION_STATE.read_text())
    if re.search(r"\bSESSION_PROPERTY_NAMES\b", session_clean):
        fail(f"{SESSION_STATE.relative_to(ROOT)} still defines SESSION_PROPERTY_NAMES")
    if re.search(r"func\s+has_session_property\s*\(", session_clean):
        fail(f"{SESSION_STATE.relative_to(ROOT)} still defines has_session_property()")

    violations: list[str] = []
    for path in sorted(MAP_CONSTRUCTOR_DIR.glob("*.gd")):
        clean = strip_comments_and_strings(path.read_text())
        for line_no, line in enumerate(clean.splitlines(), 1):
            for match in DIRECT_UI_RE.finditer(line):
                violations.append(f"{path.relative_to(ROOT)}:{line_no}: direct session access `{match.group(0)}`")
    if violations:
        print("ERROR: Map Constructor session fields must be accessed via ui.map_constructor_state.<field>:", file=sys.stderr)
        print("\n".join(violations), file=sys.stderr)
        return 1
    print("OK: GameUI Map Constructor proxy is absent and callers use map_constructor_state")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
