#!/usr/bin/env python3
from pathlib import Path
import re

path = Path("scripts/field/room_visual_renderer.gd")
text = path.read_text(encoding="utf-8")

def replace_fn(name: str, body: str) -> None:
    global text
    pattern = re.compile(rf"(?ms)^func {re.escape(name)}\s*\(.*?(?=^func |\Z)")
    text, count = pattern.subn(body.rstrip() + "\n\n", text, count=1)
    if count != 1:
        raise RuntimeError(f"failed to replace {name}")

replace_fn("get_safe_iso_object_png_visual_scale", '''func get_safe_iso_object_png_visual_scale(object_data: Dictionary, asset_key: String, rule: Dictionary = {}) -> float:
\tvar active_rule: Dictionary = rule if not rule.is_empty() else get_iso_asset_alignment_rule(asset_key)
\treturn ObjectRendererRef.get_safe_visual_scale(object_data, float(active_rule.get("scale", 1.0)), is_iso_object_png_asset_key(asset_key), ISO_OBJECT_PNG_MIN_VISUAL_SCALE, ISO_OBJECT_PNG_MAX_VISUAL_SCALE)''')

replace_fn("build_iso_object_surface_context", '''func build_iso_object_surface_context(object_data: Dictionary, _cell_visual_center: Vector2 = Vector2.INF) -> Dictionary:
\treturn ObjectRendererRef.build_surface_context(object_data, get_iso_object_surface_level(object_data))''')

replace_fn("build_iso_object_visual_descriptor", '''func build_iso_object_visual_descriptor(object_data: Dictionary, asset_key: String, visual_center: Vector2, texture: Texture2D = null) -> Dictionary:
\tvar rule: Dictionary = get_iso_asset_alignment_rule(asset_key)
\tvar expected_size: Vector2 = get_iso_asset_alignment_expected_size(asset_key)
\tvar surface_level: int = get_iso_object_surface_level(object_data)
\tvar surface_context: Dictionary = build_iso_object_surface_context(object_data, visual_center)
\tvar wall_mounted: bool = is_wall_mounted_runtime_object(object_data) or ObjectRendererRef.get_mount_mode(object_data) == "wall"
\tvar wall_visual_side: String = normalize_wall_visual_side(object_data) if wall_mounted else ""
\tvar texture_size: Vector2 = texture.get_size() if texture != null else expected_size
\tvar descriptor: Dictionary = ObjectRendererRef.build_object_sprite_descriptor(object_data, asset_key, visual_center, texture_size, rule, expected_size, surface_level, surface_context, wall_visual_side, ObjectFacingServiceRef.get_facing_side(object_data), VisualAssetRenderContractServiceRef.CONTRACT_OBJECT_SPRITE, is_iso_object_png_asset_key(asset_key), ISO_OBJECT_PNG_MIN_VISUAL_SCALE, ISO_OBJECT_PNG_MAX_VISUAL_SCALE)
\tdescriptor["texture"] = texture
\tif wall_mounted:
\t\tlog_wall_mounted_positioning(object_data, "iso_object_png_descriptor", str(object_data.get("wall_side", object_data.get("interaction_side", ""))).strip_edges().to_lower(), wall_visual_side, visual_center, Rect2(descriptor.get("destination_rect", Rect2())), true)
\treturn descriptor''')

replace_fn("build_authored_wall_canvas_descriptor", '''func build_authored_wall_canvas_descriptor(object_data: Dictionary, asset_key: String, texture_path: String, visual_center: Vector2, texture: Texture2D) -> Dictionary:
\tprint("[AUTHORED WALL TEST] asset=", asset_key, " path=", texture_path)
\tvar descriptor: Dictionary = ObjectRendererRef.build_authored_canvas_descriptor(object_data, asset_key, texture_path, visual_center, texture.get_size(), get_iso_object_surface_level(object_data), get_iso_tile_size().x, authored_wall_canvas_source_width, authored_wall_canvas_anchor_ratio, VisualAssetRenderContractServiceRef.CONTRACT_WALL_AUTHORED_CANVAS, ObjectFacingServiceRef.get_facing_side(object_data))
\tdescriptor["texture"] = texture
\tlog_authored_canvas_descriptor(object_data, asset_key, texture_path, descriptor)
\treturn descriptor''')

replace_fn("build_authored_floor_canvas_descriptor", '''func build_authored_floor_canvas_descriptor(object_data: Dictionary, asset_key: String, texture_path: String, visual_center: Vector2, texture: Texture2D) -> Dictionary:
\tvar descriptor: Dictionary = ObjectRendererRef.build_authored_canvas_descriptor(object_data, asset_key, texture_path, visual_center, texture.get_size(), get_iso_object_surface_level(object_data), get_iso_tile_size().x, authored_floor_canvas_source_width, authored_floor_canvas_anchor_ratio, VisualAssetRenderContractServiceRef.CONTRACT_FLOOR_AUTHORED_CANVAS, ObjectFacingServiceRef.get_facing_side(object_data))
\tdescriptor["texture"] = texture
\tlog_authored_canvas_descriptor(object_data, asset_key, texture_path, descriptor)
\treturn descriptor''')

path.write_text(text, encoding="utf-8")
print("Object descriptor delegates applied")
