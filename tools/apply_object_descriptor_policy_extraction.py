#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
OBJECT = ROOT / "scripts/visual/renderer/object_renderer.gd"
COORD = ROOT / "scripts/field/room_visual_renderer.gd"
TEST = ROOT / "tools/ci/check_object_renderer_contract.gd"
BOUNDARY = ROOT / "tools/check_room_visual_renderer_component_boundary.py"


def replace_func(source: str, name: str, body: str) -> str:
    pattern = re.compile(rf'(?ms)^func {re.escape(name)}\s*\(.*?(?=^func |\Z)')
    match = pattern.search(source)
    if not match:
        raise RuntimeError(f"missing coordinator function {name}")
    return source[:match.start()] + body.rstrip() + "\n\n" + source[match.end():]


object_src = OBJECT.read_text(encoding="utf-8")
block = r'''

static func get_safe_visual_scale(object_data: Dictionary, rule: Dictionary, min_scale: float, max_scale: float, is_png_asset: bool) -> float:
	var rule_scale: float = clampf(float(rule.get("scale", 1.0)), min_scale, max_scale)
	if not is_png_asset:
		return rule_scale
	if not bool(object_data.get("allow_custom_visual_scale", false)):
		return rule_scale
	return clampf(float(object_data.get("visual_scale", rule_scale)), min_scale, max_scale)

static func get_surface_context_policy(object_data: Dictionary, rule: Dictionary = {}) -> Dictionary:
	var placement_mode: String = str(object_data.get("placement_mode", object_data.get("install_mode", object_data.get("mount", "")))).to_lower().strip_edges()
	var anchor_value: String = str(object_data.get("anchor", object_data.get("visual_anchor", object_data.get("alignment_anchor", "")))).to_lower().strip_edges()
	var rule_anchor: String = str(rule.get("anchor", "")).to_lower().strip_edges()
	var rule_mount: String = str(rule.get("mount", rule.get("placement_mode", ""))).to_lower().strip_edges()
	var wall_mounted: bool = placement_mode == "wall_mounted" or get_mount_mode(object_data) == "wall" or anchor_value.contains("wall_mount") or rule_anchor.contains("wall_mount") or rule_mount in ["wall", "wall_mounted"]
	return {
		"wall_mounted": wall_mounted,
		"has_explicit_surface_y_offset": object_data.has("explicit_surface_y_offset"),
		"explicit_surface_y_offset": float(object_data.get("explicit_surface_y_offset", 0.0)),
		"uses_platform_offset": object_data.has("platform_level") or object_data.has("current_level") or object_data.has("visual_level") or object_data.has("platform_height_level"),
		"ground_surface_y_offset": float(object_data.get("ground_surface_y_offset", 0.0))
	}

static func build_object_descriptor(context: Dictionary) -> Dictionary:
	var expected_size: Vector2 = Vector2(context.get("expected_size", Vector2.ZERO))
	var visual_scale: float = float(context.get("visual_scale", 1.0))
	var destination_size: Vector2 = expected_size * visual_scale
	var visual_pivot: Vector2 = Vector2(context.get("visual_pivot", Vector2.ZERO))
	var surface_level: int = int(context.get("surface_level", 0))
	var surface_context: Dictionary = Dictionary(context.get("surface_context", {}))
	var surface_y_offset: float = float(context.get("surface_y_offset", 0.0))
	var explicit_visual_offset: Vector2 = Vector2(context.get("explicit_visual_offset", Vector2.ZERO))
	var configured_offset: Vector2 = Vector2(context.get("rule_offset", Vector2.ZERO)) + explicit_visual_offset
	var wall_mounted: bool = bool(context.get("wall_mounted", false))
	if wall_mounted:
		configured_offset = explicit_visual_offset
	var visual_center: Vector2 = Vector2(context.get("visual_center", Vector2.ZERO))
	var final_draw_position: Vector2 = visual_center + Vector2(0.0, surface_y_offset) - visual_pivot + configured_offset
	var destination_rect: Rect2 = Rect2(final_draw_position, destination_size)
	var source_size: Vector2 = Vector2(context.get("source_size", expected_size))
	return {
		"visual_asset_key": str(context.get("visual_asset_key", "")),
		"texture": context.get("texture", null),
		"render_contract": str(context.get("render_contract", "")),
		"visual_scale": visual_scale,
		"visual_pivot": visual_pivot,
		"surface_level": surface_level,
		"surface_context": surface_context,
		"surface_y_offset": surface_y_offset,
		"final_draw_position": final_draw_position,
		"destination_rect": destination_rect,
		"source_rect": Rect2(Vector2.ZERO, source_size),
		"mirror_h": bool(context.get("mirror_h", false))
	}

static func build_authored_canvas_descriptor(context: Dictionary) -> Dictionary:
	var texture_size: Vector2 = Vector2(context.get("texture_size", Vector2.ZERO))
	var tile_size: Vector2 = Vector2(context.get("tile_size", Vector2.ZERO))
	var safe_source_width: float = maxf(1.0, float(context.get("source_width", 1.0)))
	var visual_scale: float = tile_size.x / safe_source_width
	var destination_size: Vector2 = texture_size * visual_scale
	var visual_pivot: Vector2 = destination_size * Vector2(context.get("anchor_ratio", Vector2(0.5, 1.0)))
	var visual_center: Vector2 = Vector2(context.get("visual_center", Vector2.ZERO))
	var explicit_visual_offset: Vector2 = Vector2(context.get("explicit_visual_offset", Vector2.ZERO))
	var final_draw_position: Vector2 = visual_center - visual_pivot + explicit_visual_offset
	return {
		"visual_asset_key": str(context.get("visual_asset_key", "")),
		"texture": context.get("texture", null),
		"texture_path": str(context.get("texture_path", "")),
		"render_contract": str(context.get("render_contract", "")),
		"visual_scale": visual_scale,
		"visual_pivot": visual_pivot,
		"surface_level": int(context.get("surface_level", 0)),
		"surface_context": {},
		"surface_y_offset": 0.0,
		"final_draw_position": final_draw_position,
		"destination_rect": Rect2(final_draw_position, destination_size),
		"source_rect": Rect2(Vector2.ZERO, texture_size),
		"mirror_h": bool(context.get("mirror_h", false))
	}

static func build_descriptor_for_contract(context: Dictionary) -> Dictionary:
	if str(context.get("descriptor_mode", "object")) == "authored_canvas":
		return build_authored_canvas_descriptor(context)
	return build_object_descriptor(context)

static func get_descriptor_mode(render_contract: String, wall_contract: String, floor_contract: String) -> String:
	if render_contract == wall_contract:
		return "wall_authored"
	if render_contract == floor_contract:
		return "floor_authored"
	return "object"
'''
if "static func get_safe_visual_scale(" not in object_src:
    object_src = object_src.rstrip() + block + "\n"
OBJECT.write_text(object_src, encoding="utf-8")

coord = COORD.read_text(encoding="utf-8")
coord = replace_func(coord, "get_safe_iso_object_png_visual_scale", r'''func get_safe_iso_object_png_visual_scale(object_data: Dictionary, asset_key: String, rule: Dictionary = {}) -> float:
	var active_rule: Dictionary = rule
	if active_rule.is_empty():
		active_rule = get_iso_asset_alignment_rule(asset_key)
	return ObjectRendererRef.get_safe_visual_scale(
		object_data,
		active_rule,
		ISO_OBJECT_PNG_MIN_VISUAL_SCALE,
		ISO_OBJECT_PNG_MAX_VISUAL_SCALE,
		is_iso_object_png_asset_key(asset_key)
	)''')
coord = replace_func(coord, "build_iso_object_surface_context", r'''func build_iso_object_surface_context(object_data: Dictionary, _cell_visual_center: Vector2 = Vector2.INF) -> Dictionary:
	var surface_level: int = get_iso_object_surface_level(object_data)
	var rule: Dictionary = {}
	if object_data.get("rule", {}) is Dictionary:
		rule = Dictionary(object_data.get("rule", {}))
	elif object_data.get("alignment_rule", {}) is Dictionary:
		rule = Dictionary(object_data.get("alignment_rule", {}))
	elif object_data.get("visual_rule", {}) is Dictionary:
		rule = Dictionary(object_data.get("visual_rule", {}))
	var policy: Dictionary = ObjectRendererRef.get_surface_context_policy(object_data, rule)
	if bool(policy.get("wall_mounted", false)):
		return IsoVisualAlignmentServiceRef.build_surface_context(surface_level, 0.0, 0.0, true)
	if bool(policy.get("has_explicit_surface_y_offset", false)):
		return {"explicit_surface_y_offset": float(policy.get("explicit_surface_y_offset", 0.0)), "surface_level": surface_level, "wall_mounted": false}
	var platform_offset: float = 0.0
	if bool(policy.get("uses_platform_offset", false)):
		platform_offset = IsoVisualAlignmentServiceRef.get_platform_surface_y_offset(object_data)
	return IsoVisualAlignmentServiceRef.build_surface_context(surface_level, float(policy.get("ground_surface_y_offset", 0.0)), platform_offset, false)''')
coord = replace_func(coord, "build_iso_object_visual_descriptor", r'''func build_iso_object_visual_descriptor(object_data: Dictionary, asset_key: String, visual_center: Vector2, texture: Texture2D = null) -> Dictionary:
	var rule: Dictionary = get_iso_asset_alignment_rule(asset_key)
	var expected_size: Vector2 = get_iso_asset_alignment_expected_size(asset_key)
	var visual_scale: float = get_safe_iso_object_png_visual_scale(object_data, asset_key, rule)
	var destination_size: Vector2 = expected_size * visual_scale
	var default_pivot: Vector2 = get_iso_asset_alignment_anchor_offset(str(rule.get("anchor", "bottom_center")), destination_size)
	var visual_pivot: Vector2 = _parse_visual_pivot(object_data.get("visual_pivot", default_pivot), default_pivot)
	var surface_level: int = get_iso_object_surface_level(object_data)
	var surface_context: Dictionary = build_iso_object_surface_context(object_data, visual_center)
	var surface_y_offset: float = IsoVisualAlignmentServiceRef.get_object_surface_y_offset(surface_context)
	var explicit_visual_offset: Vector2 = _parse_visual_pivot(object_data.get("visual_offset", Vector2.ZERO), Vector2.ZERO)
	var wall_mounted: bool = bool(ObjectRendererRef.get_surface_context_policy(object_data, rule).get("wall_mounted", false))
	var wall_visual_side: String = normalize_wall_visual_side(object_data) if wall_mounted else ""
	var mirror_h: bool = (wall_visual_side == "se" and bool(object_data.get("mirror_visual_for_facing_side", true))) if wall_mounted else (ObjectFacingServiceRef.get_facing_side(object_data) == ObjectFacingServiceRef.FACING_SIDE_SE and bool(object_data.get("mirror_visual_for_facing_side", true)))
	var descriptor: Dictionary = ObjectRendererRef.build_descriptor_for_contract({
		"descriptor_mode": "object",
		"visual_asset_key": asset_key,
		"texture": texture,
		"render_contract": VisualAssetRenderContractServiceRef.CONTRACT_OBJECT_SPRITE,
		"expected_size": expected_size,
		"source_size": texture.get_size() if texture != null else expected_size,
		"visual_scale": visual_scale,
		"visual_pivot": visual_pivot,
		"surface_level": surface_level,
		"surface_context": surface_context,
		"surface_y_offset": surface_y_offset,
		"visual_center": visual_center,
		"rule_offset": Vector2(rule.get("offset", Vector2.ZERO)),
		"explicit_visual_offset": explicit_visual_offset,
		"wall_mounted": wall_mounted,
		"mirror_h": mirror_h
	})
	if wall_mounted:
		var raw_wall_side: String = str(object_data.get("wall_side", object_data.get("interaction_side", ""))).strip_edges().to_lower()
		log_wall_mounted_positioning(object_data, "iso_object_png_descriptor", raw_wall_side, wall_visual_side, visual_center, Rect2(descriptor.get("destination_rect", Rect2())), true)
	return descriptor''')
coord = replace_func(coord, "build_authored_wall_canvas_descriptor", r'''func build_authored_wall_canvas_descriptor(object_data: Dictionary, asset_key: String, texture_path: String, visual_center: Vector2, texture: Texture2D) -> Dictionary:
	var descriptor: Dictionary = ObjectRendererRef.build_descriptor_for_contract({
		"descriptor_mode": "authored_canvas",
		"visual_asset_key": asset_key,
		"texture": texture,
		"texture_path": texture_path,
		"render_contract": VisualAssetRenderContractServiceRef.CONTRACT_WALL_AUTHORED_CANVAS,
		"texture_size": texture.get_size(),
		"tile_size": get_iso_tile_size(),
		"source_width": authored_wall_canvas_source_width,
		"anchor_ratio": authored_wall_canvas_anchor_ratio,
		"visual_center": visual_center,
		"explicit_visual_offset": _parse_visual_pivot(object_data.get("visual_offset", Vector2.ZERO), Vector2.ZERO),
		"surface_level": get_iso_object_surface_level(object_data),
		"mirror_h": ObjectFacingServiceRef.get_facing_side(object_data) == ObjectFacingServiceRef.FACING_SIDE_SE and bool(object_data.get("mirror_visual_for_facing_side", true))
	})
	log_authored_canvas_descriptor(object_data, asset_key, texture_path, descriptor)
	return descriptor''')
coord = replace_func(coord, "build_authored_floor_canvas_descriptor", r'''func build_authored_floor_canvas_descriptor(object_data: Dictionary, asset_key: String, texture_path: String, visual_center: Vector2, texture: Texture2D) -> Dictionary:
	var descriptor: Dictionary = ObjectRendererRef.build_descriptor_for_contract({
		"descriptor_mode": "authored_canvas",
		"visual_asset_key": asset_key,
		"texture": texture,
		"texture_path": texture_path,
		"render_contract": VisualAssetRenderContractServiceRef.CONTRACT_FLOOR_AUTHORED_CANVAS,
		"texture_size": texture.get_size(),
		"tile_size": get_iso_tile_size(),
		"source_width": authored_floor_canvas_source_width,
		"anchor_ratio": authored_floor_canvas_anchor_ratio,
		"visual_center": visual_center,
		"explicit_visual_offset": _parse_visual_pivot(object_data.get("visual_offset", Vector2.ZERO), Vector2.ZERO),
		"surface_level": get_iso_object_surface_level(object_data),
		"mirror_h": ObjectFacingServiceRef.get_facing_side(object_data) == ObjectFacingServiceRef.FACING_SIDE_SE and bool(object_data.get("mirror_visual_for_facing_side", true))
	})
	log_authored_canvas_descriptor(object_data, asset_key, texture_path, descriptor)
	return descriptor''')
coord = replace_func(coord, "build_iso_object_visual_descriptor_for_contract", r'''func build_iso_object_visual_descriptor_for_contract(object_data: Dictionary, asset_key: String, texture_path: String, render_contract: String, visual_center: Vector2, texture: Texture2D) -> Dictionary:
	match ObjectRendererRef.get_descriptor_mode(render_contract, VisualAssetRenderContractServiceRef.CONTRACT_WALL_AUTHORED_CANVAS, VisualAssetRenderContractServiceRef.CONTRACT_FLOOR_AUTHORED_CANVAS):
		"wall_authored":
			return build_authored_wall_canvas_descriptor(object_data, asset_key, texture_path, visual_center, texture)
		"floor_authored":
			return build_authored_floor_canvas_descriptor(object_data, asset_key, texture_path, visual_center, texture)
	return build_iso_object_visual_descriptor(object_data, asset_key, visual_center, texture)''')
COORD.write_text(coord, encoding="utf-8")

test = TEST.read_text(encoding="utf-8")
if "\t_check_descriptor_policy()\n" not in test:
    test = test.replace("\t_check_entry_policy()\n", "\t_check_entry_policy()\n\t_check_descriptor_policy()\n")
    insertion = r'''
func _check_descriptor_policy() -> void:
	_expect(is_equal_approx(ObjectRendererRef.get_safe_visual_scale({}, {"scale": 0.75}, 0.25, 2.0, true), 0.75), "default visual scale changed")
	_expect(is_equal_approx(ObjectRendererRef.get_safe_visual_scale({"visual_scale": 1.7}, {"scale": 0.75}, 0.25, 2.0, true), 0.75), "custom scale must remain opt-in")
	_expect(is_equal_approx(ObjectRendererRef.get_safe_visual_scale({"allow_custom_visual_scale": true, "visual_scale": 5.0}, {"scale": 0.75}, 0.25, 2.0, true), 2.0), "custom scale clamp changed")
	var wall_policy: Dictionary = ObjectRendererRef.get_surface_context_policy({"placement_mode": "wall_mounted"}, {"anchor": "bottom_center"})
	_expect(bool(wall_policy.get("wall_mounted", false)), "wall-mounted surface policy changed")
	var explicit_policy: Dictionary = ObjectRendererRef.get_surface_context_policy({"explicit_surface_y_offset": -14.0})
	_expect(bool(explicit_policy.get("has_explicit_surface_y_offset", false)) and is_equal_approx(float(explicit_policy.get("explicit_surface_y_offset", 0.0)), -14.0), "explicit surface offset policy changed")
	var platform_policy: Dictionary = ObjectRendererRef.get_surface_context_policy({"platform_level": 2})
	_expect(bool(platform_policy.get("uses_platform_offset", false)), "platform surface policy changed")

	var object_descriptor: Dictionary = ObjectRendererRef.build_descriptor_for_contract({
		"descriptor_mode": "object",
		"visual_asset_key": "object_generic",
		"render_contract": "object_sprite",
		"expected_size": Vector2(96, 96),
		"source_size": Vector2(128, 96),
		"visual_scale": 0.75,
		"visual_pivot": Vector2(36, 72),
		"surface_level": 2,
		"surface_context": {"surface_level": 2},
		"surface_y_offset": -12.0,
		"visual_center": Vector2(200, 100),
		"rule_offset": Vector2(0, -8),
		"explicit_visual_offset": Vector2(3, 4),
		"wall_mounted": false,
		"mirror_h": true
	})
	_expect(Vector2(object_descriptor.get("final_draw_position", Vector2.ZERO)) == Vector2(167, 12), "object descriptor position changed")
	_expect(Rect2(object_descriptor.get("destination_rect", Rect2())) == Rect2(Vector2(167, 12), Vector2(72, 72)), "object descriptor rect changed")
	_expect(Rect2(object_descriptor.get("source_rect", Rect2())) == Rect2(Vector2.ZERO, Vector2(128, 96)), "object descriptor source changed")
	_expect(bool(object_descriptor.get("mirror_h", false)), "object descriptor mirror changed")

	var wall_descriptor: Dictionary = ObjectRendererRef.build_descriptor_for_contract({
		"descriptor_mode": "object",
		"visual_asset_key": "terminal_01",
		"render_contract": "object_sprite",
		"expected_size": Vector2(96, 96),
		"source_size": Vector2(96, 96),
		"visual_scale": 1.0,
		"visual_pivot": Vector2(48, 96),
		"surface_level": 0,
		"surface_context": {"wall_mounted": true},
		"surface_y_offset": 0.0,
		"visual_center": Vector2(100, 80),
		"rule_offset": Vector2(20, 20),
		"explicit_visual_offset": Vector2(2, -3),
		"wall_mounted": true,
		"mirror_h": false
	})
	_expect(Vector2(wall_descriptor.get("final_draw_position", Vector2.ZERO)) == Vector2(54, -19), "wall descriptor must ignore alignment-rule offset")

	var authored_descriptor: Dictionary = ObjectRendererRef.build_descriptor_for_contract({
		"descriptor_mode": "authored_canvas",
		"visual_asset_key": "terminal_01",
		"texture_path": "res://test.png",
		"render_contract": "wall_authored_canvas",
		"texture_size": Vector2(512, 400),
		"tile_size": Vector2(128, 71),
		"source_width": 512.0,
		"anchor_ratio": Vector2(0.5, 0.70),
		"visual_center": Vector2(300, 200),
		"explicit_visual_offset": Vector2(4, -2),
		"surface_level": 1,
		"mirror_h": true
	})
	_expect(is_equal_approx(float(authored_descriptor.get("visual_scale", 0.0)), 0.25), "authored canvas scale changed")
	_expect(Rect2(authored_descriptor.get("destination_rect", Rect2())) == Rect2(Vector2(240, 128), Vector2(128, 100)), "authored canvas rect changed")
	_expect(str(authored_descriptor.get("texture_path", "")) == "res://test.png", "authored canvas path changed")
	_expect(ObjectRendererRef.get_descriptor_mode("wall", "wall", "floor") == "wall_authored", "wall contract dispatch changed")
	_expect(ObjectRendererRef.get_descriptor_mode("floor", "wall", "floor") == "floor_authored", "floor contract dispatch changed")
	_expect(ObjectRendererRef.get_descriptor_mode("object", "wall", "floor") == "object", "object contract dispatch changed")
'''
    test = test.replace("\nfunc _expect(condition: bool, message: String) -> void:", "\n" + insertion + "\nfunc _expect(condition: bool, message: String) -> void:")
TEST.write_text(test, encoding="utf-8")

boundary = BOUNDARY.read_text(encoding="utf-8")
boundary = boundary.replace("if renderer_lines > 6650:", "if renderer_lines > 6620:").replace("{renderer_lines} > 6650", "{renderer_lines} > 6620")
if '"get_safe_iso_object_png_visual_scale": "ObjectRendererRef.get_safe_visual_scale"' not in boundary:
    marker = "object_delegates = {\n"
    additions = '''object_descriptor_delegates = {
    "get_safe_iso_object_png_visual_scale": "ObjectRendererRef.get_safe_visual_scale",
    "build_iso_object_surface_context": "ObjectRendererRef.get_surface_context_policy",
    "build_iso_object_visual_descriptor": "ObjectRendererRef.build_descriptor_for_contract",
    "build_authored_wall_canvas_descriptor": "ObjectRendererRef.build_descriptor_for_contract",
    "build_authored_floor_canvas_descriptor": "ObjectRendererRef.build_descriptor_for_contract",
    "build_iso_object_visual_descriptor_for_contract": "ObjectRendererRef.get_descriptor_mode",
}
for name, delegate in object_descriptor_delegates.items():
    if delegate not in function_body(renderer, name):
        errors.append(f"RoomVisualRenderer {name} must delegate object descriptor policy to ObjectRenderer")

'''
    boundary = boundary.replace(marker, additions + marker)
for token in [
    '    "static func get_safe_visual_scale",\n',
    '    "static func get_surface_context_policy",\n',
    '    "static func build_object_descriptor",\n',
    '    "static func build_authored_canvas_descriptor",\n',
    '    "static func build_descriptor_for_contract",\n',
    '    "static func get_descriptor_mode",\n',
]:
    if token not in boundary:
        boundary = boundary.replace('    "static func make_draw_entry",\n', '    "static func make_draw_entry",\n' + token)
if '[AUTHORED WALL TEST]' not in boundary:
    boundary = boundary.replace('if "IsoDrawEntryContractRef.make_entry" not in function_body(object_renderer, "make_draw_entry"):\n', 'if "[AUTHORED WALL TEST]" in renderer:\n    errors.append("RoomVisualRenderer must not contain unconditional authored-wall descriptor logging")\n\nif "IsoDrawEntryContractRef.make_entry" not in function_body(object_renderer, "make_draw_entry"):\n')
BOUNDARY.write_text(boundary, encoding="utf-8")

print("Object descriptor policy extraction applied")
