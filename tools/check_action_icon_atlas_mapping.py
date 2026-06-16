#!/usr/bin/env python3
"""Validate runtime action icon atlas mappings and UI references."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SERVICE = ROOT / "scripts/ui/action_icon_atlas_service.gd"
PRESENTER = ROOT / "scripts/ui/runtime/runtime_interaction_presenter.gd"
CONTROL_PANEL = ROOT / "scripts/ui/runtime/runtime_control_panel.gd"
ATLAS = ROOT / "assets/visual/isometric/icons/action/icon_menu_action.png"


def fail(message: str) -> None:
    print(f"ERROR: {message}")
    sys.exit(1)


def main() -> None:
    if not SERVICE.exists():
        fail("ActionIconAtlasService is missing")
    if not ATLAS.exists():
        fail("icon_menu_action.png atlas is missing")


    png_bytes = ATLAS.read_bytes()
    if not png_bytes.startswith(b"\x89PNG\r\n\x1a\n"):
        fail("atlas file is not a PNG")
    width = int.from_bytes(png_bytes[16:20], "big")
    height = int.from_bytes(png_bytes[20:24], "big")
    if (width, height) != (1024, 1024):
        fail(f"atlas dimensions must be 1024x1024 for an 8x8 grid of 128px cells, got {width}x{height}")

    text = SERVICE.read_text(encoding="utf-8")
    if 'ATLAS_PATH: String = "res://assets/visual/isometric/icons/action/icon_menu_action.png"' not in text:
        fail("atlas path is not referenced by ActionIconAtlasService")
    if "SOURCE_ICON_SIZE: Vector2i = Vector2i(128, 128)" not in text:
        fail("source icon size must be 128x128")
    if "DISPLAY_ICON_SIZE: Vector2i = Vector2i(64, 64)" not in text:
        fail("display icon size must be 64x64")
    if "ACTION_BUTTON_MIN_SIZE: Vector2i = Vector2i(72, 72)" not in text:
        fail("action button minimum size must be 72x72")
    if "TextureRect" not in text or "Vector2(DISPLAY_ICON_SIZE)" not in text:
        fail("service must use a TextureRect sized to DISPLAY_ICON_SIZE for robust 64px icons")
    if ":=" in text:
        fail("ActionIconAtlasService must use explicit typed variables instead of :=")
    if "load(ATLAS_PATH)" not in text or "_icon_cache" not in text:
        fail("service must load the atlas once and cache generated icons")

    canonical_block = re.search(r"const ACTION_ICON_CELLS: Dictionary = \{(?P<body>.*?)\n\}", text, re.S)
    if not canonical_block:
        fail("ACTION_ICON_CELLS dictionary is missing")
    canonical_cells: dict[str, tuple[int, int]] = {}
    for action_id, row, col in re.findall(r'"([^"]+)":\s*Vector2i\((\d+),\s*(\d+)\)', canonical_block.group("body")):
        row_i, col_i = int(row), int(col)
        if not (1 <= row_i <= 8 and 1 <= col_i <= 8):
            fail(f"{action_id} maps outside the 8x8 atlas: row {row_i}, col {col_i}")
        if row_i == 8 and col_i >= 5:
            fail(f"{action_id} maps to an intentionally empty row 8 cell: col {col_i}")
        canonical_cells[action_id] = (row_i, col_i)

    alias_block = re.search(r"const ACTION_ICON_ALIASES: Dictionary = \{(?P<body>.*?)\n\}", text, re.S)
    if not alias_block:
        fail("ACTION_ICON_ALIASES dictionary is missing")
    for alias, target in re.findall(r'"([^"]+)":\s*"([^"]+)"', alias_block.group("body")):
        if target not in canonical_cells:
            fail(f"alias {alias} points to unknown canonical action {target}")

    presenter_text = PRESENTER.read_text(encoding="utf-8")
    control_text = CONTROL_PANEL.read_text(encoding="utf-8")
    if "ActionIconAtlasServiceRef" not in presenter_text or "apply_icon_to_button" not in presenter_text:
        fail("runtime interaction presenter does not apply ActionIconAtlasService icons")
    if "ActionIconAtlasServiceRef" not in control_text or "apply_icon_to_button" not in control_text:
        fail("runtime control panel does not apply ActionIconAtlasService icons")

    diff = (ROOT / ".git").exists()
    if diff:
        import subprocess
        changed = subprocess.check_output(["git", "diff", "--name-only"], cwd=ROOT, text=True).splitlines()
        forbidden = [path for path in changed if path == "project.godot" or path.startswith("scripts/game/") or path.startswith("scripts/bipob/") or path.startswith("scripts/field/")]
        if forbidden:
            fail("icon-only change touched forbidden gameplay/project files: " + ", ".join(forbidden))

    print(f"OK: {len(canonical_cells)} canonical action icon mappings and aliases validated")


if __name__ == "__main__":
    main()
