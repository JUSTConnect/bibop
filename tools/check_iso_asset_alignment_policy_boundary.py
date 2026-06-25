#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POLICY = ROOT / "scripts/visual/renderer/iso_asset_alignment_policy.gd"
RENDERER = ROOT / "scripts/field/room_visual_renderer.gd"
CATALOG = ROOT / "scripts/visual/visual_asset_catalog.gd"
CONTRACT = ROOT / "tools/ci/check_iso_asset_alignment_policy_contract.gd"
WORKFLOW = ROOT / ".github/workflows/renderer-component-gate.yml"
errors: list[str] = []


def read(path: Path) -> str:
    if not path.exists():
        errors.append(f"missing required file: {path.relative_to(ROOT)}")
        return ""
    return path.read_text(encoding="utf-8")


policy = read(POLICY)
renderer = read(RENDERER)
catalog = read(CATALOG)
contract = read(CONTRACT)
workflow = read(WORKFLOW)

for token in (
    "extends RefCounted", "class_name IsoAssetAlignmentPolicy", "const ALIGNMENT_RULES: Dictionary",
    "const OUTER_UTILITY_WIDTH_SCALE: float = 5.0", "const OUTER_UTILITY_HEIGHT_SCALE: float = 2.0",
    "const OUTER_UTILITY_VERTICAL_OFFSET_SCALE: float = 2.0", "const COOLING_WALL_CANVAS_FACE_REGIONS: Dictionary",
    "static func has_alignment_rule", "static func get_alignment_rule", "static func get_alignment_rule_ids",
    "static func normalize_runtime_rule", "static func get_cooling_wall_canvas_region",
    "static func build_outer_utility_layout", "static func get_anchor_offset",
):
    if token not in policy:
        errors.append(f"IsoAssetAlignmentPolicy missing focused token: {token}")
for forbidden in (
    "extends Node", "extends Node2D", "GridManager", "MissionManager", "ResourceLoader", "Texture2D",
    "Time", "ThemeDB", "queue_redraw(", "get_node(", "get_tree(", "draw_line(", "draw_circle(",
    "draw_rect(", "draw_arc(", "draw_polyline(", "draw_texture", "CanvasItem",
):
    if forbidden in policy:
        errors.append(f"IsoAssetAlignmentPolicy contains forbidden scene/resource/Canvas dependency: {forbidden}")
if re.search(r"(?<!pre)load\(", policy):
    errors.append("IsoAssetAlignmentPolicy contains forbidden direct load() call")

for forbidden in (
    "const ISO_ASSET_ALIGNMENT_RULES", "const ISO_OBJECT_CANONICAL_VISUAL_IDS",
    "const OUTER_UTILITY_WIDTH_SCALE", "const OUTER_UTILITY_HEIGHT_SCALE",
    "const OUTER_UTILITY_VERTICAL_OFFSET_SCALE", "const ISO_COOLING_WALL_CANVAS_FACE_REGIONS",
):
    if forbidden in renderer:
        errors.append(f"RoomVisualRenderer retained migrated alignment policy body: {forbidden}")
for token in (
    'preload("res://scripts/visual/renderer/iso_asset_alignment_policy.gd")',
    "IsoAssetAlignmentPolicyRef.get_alignment_rule", "IsoAssetAlignmentPolicyRef.normalize_runtime_rule",
    "IsoAssetAlignmentPolicyRef.get_cooling_wall_canvas_region", "IsoAssetAlignmentPolicyRef.build_outer_utility_layout",
):
    if token not in renderer:
        errors.append(f"RoomVisualRenderer missing alignment/catalog integration: {token}")
for retained in ("@export var iso_object_door_texture: Texture2D", "draw_texture_rect", "draw_iso_asset_alignment_overlay", "show_asset_alignment_overlay"):
    if retained not in renderer:
        errors.append(f"RoomVisualRenderer lost retained scene/resource/Canvas ownership: {retained}")
    if retained in policy:
        errors.append(f"IsoAssetAlignmentPolicy incorrectly owns retained runtime token: {retained}")

for token in ("const ISO_TEST_ASSET_PACK_DIR: String", "const CANONICAL_OBJECT_VISUAL_IDS: Array[String]", "static func get_canonical_object_visual_ids"):
    if token not in catalog:
        errors.append(f"VisualAssetCatalog missing canonical visual-ID ownership: {token}")
for token in (
    "IsoAssetAlignmentPolicy contract OK", "floor_default", "wall_default", "object_terminal",
    "get_cooling_wall_face_region", "build_outer_utility_layout", "get_canonical_object_visual_ids",
):
    if token not in contract:
        errors.append(f"alignment policy contract missing coverage token: {token}")
if "check_iso_asset_alignment_policy_boundary.py" not in workflow or "check_iso_asset_alignment_policy_contract.gd" not in workflow:
    errors.append("Renderer Component Gate missing alignment policy validation")

renderer_lines = len(renderer.splitlines())
CAP = 4288
if renderer_lines > CAP:
    errors.append(f"RoomVisualRenderer grew beyond final coordinator cap: {renderer_lines} > {CAP}")

if errors:
    print("IsoAssetAlignmentPolicy boundary FAILED:")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)
print(f"IsoAssetAlignmentPolicy boundary OK ({renderer_lines} coordinator lines)")
