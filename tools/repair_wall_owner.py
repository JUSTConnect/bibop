#!/usr/bin/env python3
from pathlib import Path
import re
import sys

main_text = Path(sys.argv[1]).read_text(encoding="utf-8")
wall_path = Path("scripts/visual/renderer/wall_renderer.gd")
wall_text = wall_path.read_text(encoding="utf-8")

CONST_NAMES = [
    "ISO_WALL_ASSET_PACK_DIR",
    "ISO_WALL_BREACH_OVERLAY_PACK_DIR",
    "ISO_WALL_BREACH_OVERLAY_CATALOG",
    "ISO_WALL_ASSET_EXPECTED_SIZE",
    "ISO_WALL_HEIGHT_LEVELS",
    "ISO_OUTER_WALL_HEIGHT_ORDER",
    "ISO_GRATE_WALL_HEIGHT_LEVELS",
    "ISO_TEST_WALL_HEIGHT_ORDER",
    "ISO_TEST_WALL_HEIGHT_ASSET_KEYS",
    "ISO_WALL_ASSET_CATALOG",
    "ISO_WALL_BASELINE_VISIBLE_BOUNDS",
    "ISO_WALL_HEIGHT_VISIBLE_BOUNDS",
    "ISO_TEST_WALL_VISIBLE_BOUNDS",
    "ISO_WALL_ASSET_PLACEMENT",
    "WALL_SIDE_ORDER",
    "WALL_MASS_RATIO",
    "WALL_MOUNT_BAND_RATIO",
]


def extract_const(source: str, name: str) -> str:
    match = re.search(rf"(?m)^const {re.escape(name)}\s*:[^=]+=", source)
    if match is None:
        raise RuntimeError(f"Missing canonical constant: {name}")
    start = match.start()
    end = source.find("\n", match.end())
    if end < 0:
        return source[start:]
    balance = 0
    cursor = start
    while True:
        line_end = source.find("\n", cursor)
        if line_end < 0:
            line_end = len(source)
        line = source[cursor:line_end]
        balance += line.count("{") + line.count("[")
        balance -= line.count("}") + line.count("]")
        end = line_end
        if balance <= 0:
            return source[start:end]
        cursor = line_end + 1


def extract_function(source: str, name: str) -> str:
    match = re.search(rf"(?m)^func {re.escape(name)}\s*\(", source)
    if match is None:
        raise RuntimeError(f"Missing canonical function: {name}")
    next_match = re.search(r"(?m)^func [A-Za-z0-9_]+\s*\(", source[match.end():])
    end = match.end() + next_match.start() if next_match else len(source)
    return source[match.start():end].rstrip()


for name in CONST_NAMES:
    canonical = extract_const(main_text, name)
    pattern = rf"(?m)^const {re.escape(name)}[^\n]*(?:\n)?"
    wall_text, count = re.subn(pattern, canonical + "\n", wall_text, count=1)
    if count != 1:
        raise RuntimeError(f"Missing WallRenderer constant: {name}")

profiles = extract_function(main_text, "get_wall_visual_profiles")
profiles = profiles.replace("func get_wall_visual_profiles", "static func get_visual_profiles", 1)
pattern = r"(?ms)^static func get_visual_profiles\s*\(.*?(?=^static func )"
wall_text, count = re.subn(pattern, profiles + "\n\n", wall_text, count=1)
if count != 1:
    raise RuntimeError("Missing WallRenderer get_visual_profiles")
if "WallRendererRef" in wall_text:
    raise RuntimeError("WallRenderer remains self-referential")

wall_path.write_text(wall_text, encoding="utf-8")
print("WallRenderer canonical ownership repaired")
