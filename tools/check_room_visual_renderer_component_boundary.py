#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RENDERER = ROOT / "scripts/field/room_visual_renderer.gd"
PROJECTION = ROOT / "scripts/visual/renderer/iso_projection_service.gd"
DRAW_ENTRY = ROOT / "scripts/visual/renderer/iso_draw_entry_contract.gd"
errors: list[str] = []


def read(path: Path) -> str:
    if not path.exists():
        errors.append(f"missing required renderer component: {path.relative_to(ROOT)}")
        return ""
    return path.read_text(encoding="utf-8")


def function_body(source: str, name: str) -> str:
    match = re.search(rf"(?ms)^func {re.escape(name)}\s*\(.*?(?=^func |\Z)", source)
    return match.group(0) if match else ""


renderer = read(RENDERER)
projection = read(PROJECTION)
draw_entry = read(DRAW_ENTRY)

renderer_lines = len(renderer.splitlines())
if renderer_lines > 7740:
    errors.append(f"RoomVisualRenderer grew beyond stage-1 cap: {renderer_lines} > 7740")

for token in (
    'preload("res://scripts/visual/renderer/iso_projection_service.gd")',
    'preload("res://scripts/visual/renderer/iso_draw_entry_contract.gd")',
):
    if token not in renderer:
        errors.append(f"RoomVisualRenderer missing component preload: {token}")

projection_delegates = {
    "get_iso_projection_mode": "IsoProjectionServiceRef.normalize_mode",
    "get_iso_tile_size": "IsoProjectionServiceRef.get_tile_size",
    "get_iso_exported_tile_size_matches_active_mode": "IsoProjectionServiceRef.exported_tile_size_matches_active_mode",
    "get_iso_tile_half_size": "IsoProjectionServiceRef.get_tile_half_size",
    "grid_to_iso": "IsoProjectionServiceRef.grid_to_iso",
    "iso_to_grid": "IsoProjectionServiceRef.iso_to_grid",
    "get_iso_diamond_points": "IsoProjectionServiceRef.get_diamond_points",
    "get_iso_inset_diamond_points": "IsoProjectionServiceRef.get_inset_diamond_points",
    "get_iso_depth_key": "IsoProjectionServiceRef.get_depth_key",
    "get_iso_floor_depth_key": "IsoProjectionServiceRef.get_depth_key",
    "sort_cells_by_iso_depth": "IsoProjectionServiceRef.sort_cells_by_depth",
}
for name, delegate in projection_delegates.items():
    body = function_body(renderer, name)
    if delegate not in body:
        errors.append(f"RoomVisualRenderer {name} must delegate to projection component")

sort_body = function_body(renderer, "sort_iso_draw_entries")
if "IsoDrawEntryContractRef.less" not in sort_body:
    errors.append("RoomVisualRenderer draw-entry sorting must delegate to contract")

if renderer.count("IsoDrawEntryContractRef.make_entry") < 5:
    errors.append("renderer entry builders must use the shared draw-entry contract")

for constant_name in (
    "ISO_PROJECTION_STANDARD",
    "ISO_PROJECTION_CLASSIC",
    "ISO_STANDARD_TILE_SIZE",
    "ISO_LAYER_BIAS_WALL",
    "ISO_DRAW_SUB_ORDER_FLOOR",
):
    line = next((row for row in renderer.splitlines() if row.startswith(f"const {constant_name}:")), "")
    if "Ref." not in line:
        errors.append(f"renderer constant {constant_name} must be a component alias")

for forbidden in ("GridManager", "MissionManager", "draw_line(", "draw_polygon(", "queue_redraw("):
    if forbidden in projection:
        errors.append(f"projection component contains forbidden runtime dependency: {forbidden}")

for token in (
    "class_name IsoProjectionService",
    "static func normalize_mode",
    "static func grid_to_iso",
    "static func iso_to_grid",
    "static func get_diamond_points",
    "static func get_depth_key",
    "static func sort_cells_by_depth",
):
    if token not in projection:
        errors.append(f"projection component missing contract: {token}")

for token in (
    "class_name IsoDrawEntryContract",
    "const KEY_DEPTH",
    "const LAYER_BIAS_WALL",
    "const SUB_ORDER_FLOOR",
    "static func make_entry",
    "static func less",
    "static func validate_entry",
):
    if token not in draw_entry:
        errors.append(f"draw-entry component missing contract: {token}")

if errors:
    print("RoomVisualRenderer component boundary audit FAILED:")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)

print(f"RoomVisualRenderer component boundary audit OK ({renderer_lines} lines)")
