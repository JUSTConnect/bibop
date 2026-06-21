#!/usr/bin/env python3
from pathlib import Path

path = Path("scripts/visual/renderer/object_renderer.gd")
text = path.read_text(encoding="utf-8")
preload = 'const IsoVisualAlignmentServiceRef = preload("res://scripts/visual/iso_visual_alignment_service.gd")'
if preload not in text:
    marker = 'const WallMountedPlacementRulesServiceRef = preload("res://scripts/game/wall/wall_mounted_placement_rules_service.gd")'
    text = text.replace(marker, marker + "\n" + preload, 1)
addition = r'''

static func _parse_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return Vector2(value)
	if value is Vector2i:
		return Vector2(Vector2i(value))
	if value is Array:
		var values: Array = Array(value)
		if values.size() >= 2:
			return Vector2(float(values[0]), float(values[1]))
	if value is Dictionary:
		var row: Dictionary = Dictionary(value)
		if row.has("x") and row.has("y"):
			return Vector2(float(row.get("x", fallback.x)), float(row.get("y", fallback.y)))
	return fallback

static func get_safe_visual_scale(object_data: Dictionary, rule_scale: float, is_png_asset: bool, min_scale: float, max_scale: float) -> float:
	var safe_rule_scale: float = clampf(rule_scale, min_scale, max_scale)
	if not is_png_asset or not bool(object_data.get("allow_custom_visual_scale", false)):
		return safe_rule_scale
	return clampf(float(object_data.get("visual_scale", safe_rule_scale)), min_scale, max_scale)

static func build_surface_context(object_data: Dictionary, surface_level: int) -> Dictionary:
	var placement_mode: String = str(object_data.get("placement_mode", object_data.get("install_mode", object_data.get("mount", "")))).to_lower().strip_edges()
	var anchor_value: String = str(object_data.get("anchor", object_data.get("visual_anchor", object_data.get("alignment_anchor", "")))).to_lower().strip_edges()
	var rule: Dictionary = {}
	if object_data.get("rule", {}) is Dictionary:
		rule = Dictionary(object_data.get("rule", {}))
	elif object_data.get("alignment_rule", {}) is Dictionary:
		rule = Dictionary(object_data.get("alignment_rule", {}))
	elif object_data.get("visual_rule", {}) is Dictionary:
		rule = Dictionary(object_data.get("visual_rule", {}))
	var rule_anchor: String = str(rule.get("anchor", "")).to_lower().strip_edges()
	var rule_mount: String = str(rule.get("mount", rule.get("placement_mode", ""))).to_lower().strip_edges()
	var wall_mounted: bool = placement_mode == "wall_mounted" or get_mount_mode(object_data) == "wall" or anchor_value.contains("wall_mount") or rule_anchor.contains("wall_mount") or rule_mount in ["wall", "wall_mounted"]
	if wall_mounted:
		return IsoVisualAlignmentServiceRef.build_surface_context(surface_level, 0.0, 0.0, true)
	if object_data.has("explicit_surface_y_offset"):
		return {"explicit_surface_y_offset": float(object_data.get("explicit_surface_y_offset", 0.0)), "surface_level": surface_level, "wall_mounted": false}
	var platform_offset: float = 0.0
	if object_data.has("platform_level") or object_data.has("current_level") or object_data.has("visual_level") or object_data.has("platform_height_level"):
		platform_offset = IsoVisualAlignmentServiceRef.get_platform_surface_y_offset(object_data)
	var ground_offset: float = float(object_data.get("ground_surface_y_offset", 0.0)) if object_data.has("ground_surface_y_offset") else 0.0
	return IsoVisualAlignmentServiceRef.build_surface_context(surface_level, ground_offset, platform_offset, false)

static func build_object_sprite_descriptor(object_data: Dictionary, asset_key: String, visual_center: Vector2, texture_size: Vector2, rule: Dictionary, expected_size: Vector2, surface_level: int, surface_context: Dictionary, wall_visual_side: String, facing_side: String, render_contract: String, is_png_asset: bool, min_scale: float, max_scale: float) -> Dictionary:
	var visual_scale: float = get_safe_visual_scale(object_data, float(rule.get("scale", 1.0)), is_png_asset, min_scale, max_scale)
	var destination_size: Vector2 = expected_size * visual_scale
	var anchor: String = str(rule.get("anchor", "bottom_center"))
	var default_pivot: Vector2 = Vector2(destination_size.x * 0.5, destination_size.y) if anchor in ["bottom_center", "wall_cell_base"] else destination_size * 0.5
	var visual_pivot: Vector2 = _parse_vector2(object_data.get("visual_pivot", default_pivot), default_pivot)
	var surface_offset: Vector2 = Vector2(0.0, IsoVisualAlignmentServiceRef.get_object_surface_y_offset(surface_context))
	var explicit_visual_offset: Vector2 = _parse_vector2(object_data.get("visual_offset", Vector2.ZERO), Vector2.ZERO)
	var configured_offset: Vector2 = Vector2(rule.get("offset", Vector2.ZERO)) + explicit_visual_offset
	var placement_mode: String = str(object_data.get("placement_mode", object_data.get("placement", ""))).strip_edges().to_lower()
	var install_mode: String = str(object_data.get("install_mode", object_data.get("mount", ""))).strip_edges().to_lower()
	var wall_mounted: bool = bool(object_data.get("is_wall_mounted", false)) or placement_mode in ["wall_mounted", "wall"] or install_mode == "wall" or get_mount_mode(object_data) == "wall"
	if wall_mounted:
		configured_offset = explicit_visual_offset
	var final_draw_position: Vector2 = visual_center + surface_offset - visual_pivot + configured_offset
	var mirror_h: bool = (wall_visual_side == "se" if wall_mounted else facing_side == "se") and bool(object_data.get("mirror_visual_for_facing_side", true))
	return {"visual_asset_key": asset_key, "render_contract": render_contract, "visual_scale": visual_scale, "visual_pivot": visual_pivot, "surface_level": surface_level, "surface_context": surface_context, "surface_y_offset": float(surface_offset.y), "final_draw_position": final_draw_position, "destination_rect": Rect2(final_draw_position, destination_size), "source_rect": Rect2(Vector2.ZERO, texture_size), "mirror_h": mirror_h, "wall_mounted": wall_mounted}

static func build_authored_canvas_descriptor(object_data: Dictionary, asset_key: String, texture_path: String, visual_center: Vector2, texture_size: Vector2, surface_level: int, tile_width: float, source_width: float, anchor_ratio: Vector2, render_contract: String, facing_side: String) -> Dictionary:
	var visual_scale: float = tile_width / maxf(1.0, source_width)
	var destination_size: Vector2 = texture_size * visual_scale
	var visual_pivot: Vector2 = destination_size * anchor_ratio
	var explicit_visual_offset: Vector2 = _parse_vector2(object_data.get("visual_offset", Vector2.ZERO), Vector2.ZERO)
	var final_draw_position: Vector2 = visual_center - visual_pivot + explicit_visual_offset
	return {"visual_asset_key": asset_key, "texture_path": texture_path, "render_contract": render_contract, "visual_scale": visual_scale, "visual_pivot": visual_pivot, "surface_level": surface_level, "surface_context": {}, "surface_y_offset": 0.0, "final_draw_position": final_draw_position, "destination_rect": Rect2(final_draw_position, destination_size), "source_rect": Rect2(Vector2.ZERO, texture_size), "mirror_h": facing_side == "se" and bool(object_data.get("mirror_visual_for_facing_side", true))}
'''
if "static func build_object_sprite_descriptor" not in text:
    text = text.rstrip() + addition + "\n"
path.write_text(text, encoding="utf-8")
print("ObjectRenderer descriptor owner added")
