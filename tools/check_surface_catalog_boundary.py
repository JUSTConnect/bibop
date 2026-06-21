#!/usr/bin/env python3
from __future__ import annotations
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MISSION = ROOT / "scripts/game/mission_manager.gd"
SURFACE = ROOT / "scripts/world/surface_material_catalog.gd"
HEIGHT = ROOT / "scripts/world/wall_height_catalog.gd"
VISUAL = ROOT / "scripts/visual/visual_asset_catalog.gd"
RENDERER = ROOT / "scripts/field/room_visual_renderer.gd"
FLOOR_RENDERER = ROOT / "scripts/visual/renderer/floor_renderer.gd"
errors: list[str] = []

def read(path: Path) -> str:
    if not path.exists():
        errors.append(f"missing required file: {path.relative_to(ROOT)}")
        return ""
    return path.read_text(encoding="utf-8")

def function_body(source: str, name: str) -> str:
    match = re.search(rf"(?ms)^func {re.escape(name)}\s*\(.*?(?=^func |\Z)", source)
    return match.group(0) if match else ""

mission = read(MISSION)
surface = read(SURFACE)
height = read(HEIGHT)
visual = read(VISUAL)
renderer = read(RENDERER)
floor_renderer = read(FLOOR_RENDERER)

for token in (
    'preload("res://scripts/world/surface_material_catalog.gd")',
    'preload("res://scripts/world/wall_height_catalog.gd")',
    'preload("res://scripts/visual/visual_asset_catalog.gd")',
):
    if token not in mission:
        errors.append(f"MissionManager missing focused owner: {token}")

for forbidden in (
    "const ISO_PLACEHOLDER_ASSET_PATHS",
    "const FLOOR_TEXTURE_ASSET_ALIASES",
    "const WALL_TEXTURE_ASSET_ALIASES",
    "const OBJECT_TEXTURE_ASSET_ALIASES",
    "const VISUAL_TEXTURE_ASSET_ALIASES",
    "var legacy_aliases: Dictionary",
):
    if forbidden in mission:
        errors.append(f"catalog inventory returned to MissionManager: {forbidden}")

for name, delegate in {
    "normalize_map_constructor_wall_material_id": "SurfaceMaterialCatalogRef.normalize_wall_material_id",
    "get_map_constructor_floor_material_catalog": "SurfaceMaterialCatalogRef.get_floor_catalog",
    "get_map_constructor_wall_material_catalog": "SurfaceMaterialCatalogRef.get_wall_catalog",
    "normalize_map_constructor_wall_height": "WallHeightCatalogRef.normalize_wall_height",
    "normalize_floor_height_level": "WallHeightCatalogRef.normalize_floor_height",
    "normalize_visual_texture_asset_id": "VisualAssetCatalogRef.resolve_legacy_mission_asset_id",
}.items():
    if delegate not in function_body(mission, name):
        errors.append(f"MissionManager {name} must delegate to focused owner")

for token in (
    "class_name SurfaceMaterialCatalog",
    "const FLOOR_MATERIALS",
    "const WALL_MATERIALS",
    "const FLOOR_MATERIAL_ALIASES",
    "const WALL_MATERIAL_ALIASES",
    "static func validate_catalog",
):
    if token not in surface:
        errors.append(f"surface catalog missing contract: {token}")

for visual_key in ("texture_asset_id", "fallback_color", "edge_color", "res://"):
    if visual_key in surface:
        errors.append(f"domain surface catalog contains renderer-only metadata: {visual_key}")

for token in (
    "class_name WallHeightCatalog",
    "const WALL_HEIGHT_LEVELS",
    "const FLOOR_HEIGHT_LEVELS",
    "static func normalize_wall_height",
    "static func normalize_floor_height",
):
    if token not in height:
        errors.append(f"height catalog missing contract: {token}")

for token in (
    "const FLOOR_MATERIAL_PRESENTATION",
    "const WALL_MATERIAL_PRESENTATION",
    "static func decorate_surface_material_catalog",
    "static func resolve_legacy_mission_asset_id",
    "static func resolve_wall_asset_key_for_material_and_height",
):
    if token not in visual:
        errors.append(f"visual catalog missing renderer contract: {token}")

# Floor normalization is now owned by FloorRenderer. The coordinator must point
# to it, and FloorRenderer must preserve the original focused-catalog boundary.
for name, delegate in {
    "normalize_floor_material_key": "FloorRendererRef.normalize_material_key",
    "normalize_floor_height_level": "FloorRendererRef.normalize_height_level",
}.items():
    if delegate not in function_body(renderer, name):
        errors.append(f"RoomVisualRenderer {name} must delegate to FloorRenderer")

for name, delegate in {
    "normalize_material_key": "SurfaceMaterialCatalogRef.normalize_floor_material_id",
    "normalize_height_level": "WallHeightCatalogRef.normalize_floor_height",
}.items():
    if delegate not in function_body(floor_renderer, name):
        errors.append(f"FloorRenderer {name} must delegate to focused owner")

# Wall presentation remains in RoomVisualRenderer until the wall component stage.
for name, delegate in {
    "normalize_wall_material_asset_base_key": "VisualAssetCatalogScript.resolve_wall_material_base_asset_key",
    "normalize_wall_height_level": "WallHeightCatalogRef.normalize_wall_height",
    "get_wall_asset_key_for_material_and_height": "VisualAssetCatalogScript.resolve_wall_asset_key_for_material_and_height",
}.items():
    if delegate not in function_body(renderer, name):
        errors.append(f"RoomVisualRenderer {name} must delegate to focused owner")

if "_map_constructor_wall_material_overrides: Dictionary" not in mission or "_map_constructor_floor_material_overrides: Dictionary" not in mission:
    errors.append("runtime surface overrides must remain in MissionManager")

if errors:
    print("Surface catalog boundary audit FAILED:")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)
print("Surface catalog boundary audit OK")
