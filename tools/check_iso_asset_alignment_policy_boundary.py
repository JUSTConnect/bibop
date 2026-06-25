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

if re.search(r"(?<!pre)load\(", policy):
    errors.append("IsoAssetAlignmentPolicy contains forbidden direct load() call")

for forbidden in (
    "extends Node", "extends Node2D", "GridManager", "MissionManager", "ResourceLoader",
    "FileAccess", "ResourceSaver", "Texture2D", "Time", "ThemeDB", "queue_redraw(", "get_node(",
    "get_tree(", "draw_line(", "draw_circle(", "draw_rect(", "draw_arc(", "draw_polyline(",
    "draw_texture", "CanvasItem",
):
    if forbidden in policy:
        errors.append(f"IsoAssetAlignmentPolicy contains forbidden scene/resource/Canvas dependency: {forbidden}")

for forbidden in (
    "const ISO_ASSET_ALIGNMENT_RULES", "const ISO_OBJECT_CANONICAL_VISUAL_IDS",
    "const OUTER_UTILITY_WIDTH_SCALE", "const OUTER_UTILITY_HEIGHT_SCALE",
    "const OUTER_UTILITY_VERTICAL_OFFSET_SCALE", "const ISO_COOLING_WALL_CANVAS_FACE_REGIONS",
):
    if forbidden in renderer:
        errors.append(f"RoomVisualRenderer retained migrated policy body: {forbidden}")

removed_aliases = (
    "ISO_WALL_ASSET_PACK_DIR", "ISO_WALL_BREACH_OVERLAY_PACK_DIR", "ISO_WALL_BREACH_OVERLAY_CATALOG",
    "ISO_WALL_ASSET_EXPECTED_SIZE", "ISO_WALL_HEIGHT_LEVELS", "ISO_OUTER_WALL_HEIGHT_ORDER",
    "ISO_GRATE_WALL_HEIGHT_LEVELS", "ISO_TEST_WALL_HEIGHT_ORDER", "ISO_TEST_WALL_HEIGHT_ASSET_KEYS",
    "ISO_WALL_ASSET_CATALOG", "ISO_FLOOR_ASSET_PACK_DIR", "ISO_FLOOR_TEST_ASSET_KEY",
    "ISO_FLOOR_ASSET_CATALOG", "ISO_GROUND_ASSET_PACK_DIR", "ISO_GROUND_ASSET_CATALOG",
    "ISO_FLOOR_ASSET_TARGET_FOOTPRINT", "ISO_FLOOR_ASSET_NORMALIZED_OVERLAP", "ISO_FLOOR_ASSET_PLACEMENT",
    "ISO_GROUND_ASSET_PLACEMENT", "ISO_WALL_BASELINE_VISIBLE_BOUNDS", "ISO_WALL_HEIGHT_VISIBLE_BOUNDS",
    "ISO_TEST_WALL_VISIBLE_BOUNDS", "ISO_WALL_ASSET_PLACEMENT", "ISO_FLOOR_ATLAS_COLUMNS",
    "ISO_FLOOR_ATLAS_ROWS", "ISO_FLOOR_ATLAS_BASE_VARIANTS", "ISO_FLOOR_ATLAS_HEAVY_METAL_VARIANTS",
    "ISO_FLOOR_ATLAS_SOURCE_EDGE_PADDING", "ISO_FLOOR_ATLAS_SCREEN_OVERLAP", "ISO_FLOOR_UNDERLAY_OVERLAP",
    "ISO_FLOOR_ASSET_SCREEN_OVERLAP", "ISO_FLOOR_OVERLAY_INNER_INSET", "ISO_FLOOR_SEAM_SAFE_BASE_VARIANTS",
    "ISO_FLOOR_ATLAS_LAYOUT", "WALL_SIDE_ORDER", "WALL_MASS_RATIO", "WALL_MOUNT_BAND_RATIO",
)
for alias in removed_aliases:
    if re.search(rf"(?m)^const {re.escape(alias)}(?::|\s*=)", renderer):
        errors.append(f"RoomVisualRenderer retained coordinator-only catalog alias: {alias}")

for token in (
    'preload("res://scripts/visual/renderer/iso_asset_alignment_policy.gd")',
    "IsoAssetAlignmentPolicyRef.get_alignment_rule", "IsoAssetAlignmentPolicyRef.normalize_runtime_rule",
    "IsoAssetAlignmentPolicyRef.get_cooling_wall_canvas_region", "IsoAssetAlignmentPolicyRef.build_outer_utility_layout",
    "VisualAssetCatalogScript.get_all_asset_paths",
):
    if token not in renderer:
        errors.append(f"RoomVisualRenderer missing alignment/catalog integration: {token}")

for retained in (
    "@export var iso_object_door_texture: Texture2D", "_iso_object_png_texture_cache",
    "ResourceLoader", "draw_texture_rect", "draw_iso_asset_alignment_overlay", "show_asset_alignment_overlay",
):
    if retained not in renderer:
        errors.append(f"RoomVisualRenderer lost retained scene/resource/Canvas ownership: {retained}")
    if retained in policy:
        errors.append(f"IsoAssetAlignmentPolicy incorrectly owns retained runtime token: {retained}")

for token in ("const ISO_TEST_ASSET_PACK_DIR: String", "const CANONICAL_OBJECT_VISUAL_IDS: Array[String]", "static func get_canonical_object_visual_ids"):
    if token not in catalog:
        errors.append(f"VisualAssetCatalog missing canonical visual-ID ownership: {token}")

for token in (
    "IsoAssetAlignmentPolicy contract OK", "floor_default", "wall_default", "object_key",
    "object_terminal", "object_socket", "get_cooling_wall_face_region", "build_outer_utility_layout",
    "get_canonical_object_visual_ids",
):
    if token not in contract:
        errors.append(f"alignment policy contract missing exact coverage token: {token}")

for token in (
    "python tools/check_iso_asset_alignment_policy_boundary.py",
    "res://tools/ci/check_iso_asset_alignment_policy_contract.gd",
):
    if token not in workflow:
        errors.append(f"Renderer Component Gate missing alignment policy check: {token}")

renderer_lines = len(renderer.splitlines())
if renderer_lines > 5488:
    errors.append(f"RoomVisualRenderer did not shrink by at least 80 lines: {renderer_lines} > 5488")

if errors:
    print("IsoAssetAlignmentPolicy boundary FAILED:")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)

print(f"IsoAssetAlignmentPolicy boundary OK ({renderer_lines} coordinator lines)")
