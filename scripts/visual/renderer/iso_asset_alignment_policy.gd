extends RefCounted
class_name IsoAssetAlignmentPolicy

const IsoProjectionServiceRef = preload("res://scripts/visual/renderer/iso_projection_service.gd")

const OUTER_UTILITY_WIDTH_SCALE: float = 5.0
const OUTER_UTILITY_HEIGHT_SCALE: float = 2.0
const OUTER_UTILITY_VERTICAL_OFFSET_SCALE: float = 2.0
const COOLING_WALL_CANVAS_FACE_REGIONS: Dictionary = {
	"sw": Rect2(0.0, 0.0, 0.5, 1.0),
	"se": Rect2(0.5, 0.0, 0.5, 1.0)
}

const ALIGNMENT_RULES: Dictionary = {
	"floor_default": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": IsoProjectionServiceRef.STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Default 128x71 floor diamond centered in the grid cell."},
	"floor_concrete": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": IsoProjectionServiceRef.STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Concrete floor PNG is squeezed to the active isometric floor footprint."},
	"floor_steel": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": IsoProjectionServiceRef.STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Steel floor PNG is squeezed to the active isometric floor footprint."},
	"floor_titan": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": IsoProjectionServiceRef.STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Titanium floor PNG is squeezed to the active isometric floor footprint."},
	"floor_stepped": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": IsoProjectionServiceRef.STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Stepped 128x71 floor diamond centered in the grid cell."},
	"floor_clean_lab": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": IsoProjectionServiceRef.STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Clean lab 128x71 floor diamond centered in the grid cell."},
	"floor_dark_service": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": IsoProjectionServiceRef.STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Dark service 128x71 floor diamond centered in the grid cell."},
	"floor_hazard": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": IsoProjectionServiceRef.STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Hazard 128x71 floor diamond centered in the grid cell."},
	"floor_power": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": IsoProjectionServiceRef.STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Powered 128x71 floor diamond centered in the grid cell."},
	"floor_damaged": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": IsoProjectionServiceRef.STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Damaged 128x71 floor diamond centered in the grid cell."},
	"floor_reinforced": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": IsoProjectionServiceRef.STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Reinforced 128x71 floor diamond centered in the grid cell."},
	"floor_diagnostic": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": IsoProjectionServiceRef.STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Diagnostic 128x71 floor diamond centered in the grid cell."},
	"floor_door_underlay": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": IsoProjectionServiceRef.STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Door underlay remains centered under the wall opening."},
	"ground_low": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": IsoProjectionServiceRef.STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Visual-only raised ground step 1 floor asset."},
	"ground_halflow": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": IsoProjectionServiceRef.STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Visual-only raised ground step 2 floor asset."},
	"wall_default": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Wall canvas bottom-center aligns to the blocked wall cell base on the active 128x71 footprint."},
	"wall_outer": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Outer wall canvas bottom-center aligns to the blocked wall cell base on the active 128x71 footprint."},
	"wall_brick": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Brick wall canvas bottom-center aligns to the blocked wall cell base on the active 128x71 footprint."},
	"wall_concrete": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Concrete wall canvas bottom-center aligns to the blocked wall cell base on the active 128x71 footprint."},
	"wall_grate": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Grate wall canvas bottom-center aligns to the blocked wall cell base on the active 128x71 footprint."},
	"wall_concrete_damaged": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Concrete damaged wall visible base anchors to the blocked wall cell base on the active 128x71 footprint."},
	"wall_brick_damaged": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Brick damaged wall visible base anchors to the blocked wall cell base on the active 128x71 footprint."},
	"wall_steel": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Steel wall canvas bottom-center aligns to the blocked wall cell base on the active 128x71 footprint."},
	"wall_energy": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Energy wall canvas bottom-center aligns to the blocked wall cell base on the active 128x71 footprint."},
	"object_door": {"anchor": "door_insert_center", "scale": 0.9, "offset": Vector2(0, -20), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Door art centers inside the visual wall opening."},
	"object_terminal": {"anchor": "wall_mount_center", "scale": 0.8, "offset": Vector2(0, -18), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Terminal art centers on the wall mount band."},
	"object_key": {"anchor": "bottom_center", "scale": 0.55, "offset": Vector2(0, -6), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Key pickup uses a small bottom-centered floor footprint."},
	"object_component": {"anchor": "bottom_center", "scale": 0.75, "offset": Vector2(0, -8), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Component prop uses a readable bottom-centered floor footprint."},
	"object_socket": {"anchor": "wall_mount_center", "scale": 0.8, "offset": Vector2(0, -18), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Socket art centers on the wall mount band."},
	"object_cable": {"anchor": "bottom_center", "scale": 0.75, "offset": Vector2(0, -8), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Cable-like prop uses a readable bottom-centered floor footprint."},
	"object_generic": {"anchor": "bottom_center", "scale": 0.75, "offset": Vector2(0, -8), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Generic prop uses a readable bottom-centered floor footprint."},
	"object_fuse": {"anchor": "bottom_center", "scale": 0.55, "offset": Vector2(0, -6), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Fuse pickup uses a small bottom-centered floor footprint."},
	"object_repair_kit": {"anchor": "bottom_center", "scale": 0.55, "offset": Vector2(0, -6), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Repair kit pickup uses a small bottom-centered floor footprint."},
	"object_keycard": {"anchor": "bottom_center", "scale": 0.55, "offset": Vector2(0, -6), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Keycard pickup uses a small bottom-centered floor footprint."},
	"object_access_code": {"anchor": "bottom_center", "scale": 0.55, "offset": Vector2(0, -6), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Access-code pickup uses a small bottom-centered floor footprint."},
	"object_cable_reel": {"anchor": "bottom_center", "scale": 0.75, "offset": Vector2(0, -8), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Cable reel prop uses a readable bottom-centered floor footprint."},
	"object_button": {"anchor": "wall_mount_center", "scale": 0.8, "offset": Vector2(0, -18), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Button art centers on the wall mount band."},
	"object_switch": {"anchor": "wall_mount_center", "scale": 0.8, "offset": Vector2(0, -18), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Switch art centers on the wall mount band."}
}

static func has_alignment_rule(asset_key: String) -> bool:
	return ALIGNMENT_RULES.has(asset_key)

static func get_alignment_rule(asset_key: String) -> Dictionary:
	var raw_rule: Variant = ALIGNMENT_RULES.get(asset_key, {})
	if raw_rule is Dictionary:
		return Dictionary(raw_rule).duplicate(true)
	return {}

static func get_alignment_rule_ids() -> Array[String]:
	var result: Array[String] = []
	for asset_key_variant in ALIGNMENT_RULES.keys():
		result.append(str(asset_key_variant))
	return result

static func get_expected_size(asset_key: String, fallback: Vector2) -> Vector2:
	return get_rule_expected_size(get_alignment_rule(asset_key), fallback)

static func get_anchor(asset_key: String, fallback: String = "center") -> String:
	return get_rule_anchor(get_alignment_rule(asset_key), fallback)

static func get_scale(asset_key: String, fallback: float = 1.0) -> float:
	return get_rule_scale(get_alignment_rule(asset_key), fallback)

static func get_offset(asset_key: String, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	return get_rule_offset(get_alignment_rule(asset_key), fallback)

static func get_layer_hint(asset_key: String, fallback: String = "object") -> String:
	var rule: Dictionary = get_alignment_rule(asset_key)
	return str(rule.get("layer_hint", fallback))

static func get_rule_expected_size(rule: Dictionary, fallback: Vector2) -> Vector2:
	var value: Variant = rule.get("expected_size", fallback)
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value)
	return fallback

static func get_rule_anchor(rule: Dictionary, fallback: String = "center") -> String:
	var anchor: String = str(rule.get("anchor", fallback)).strip_edges()
	return fallback if anchor.is_empty() else anchor

static func get_rule_scale(rule: Dictionary, fallback: float = 1.0) -> float:
	var scale_value: float = fallback
	var value: Variant = rule.get("scale", fallback)
	if value is float or value is int:
		scale_value = float(value)
	return maxf(scale_value, 0.01)

static func get_rule_offset(rule: Dictionary, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	var value: Variant = rule.get("offset", fallback)
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value)
	return fallback

static func normalize_runtime_rule(asset_key: String, source_rule: Dictionary, tile_size: Vector2, tile_half_size: Vector2, classic_tile_size: Vector2) -> Dictionary:
	var rule: Dictionary = source_rule.duplicate(true)
	if asset_key.begins_with("floor_"):
		rule["expected_size"] = tile_size
	if get_rule_anchor(rule, "") == "wall_cell_base":
		var offset: Vector2 = get_rule_offset(rule, Vector2.ZERO)
		if is_equal_approx(offset.y, -classic_tile_size.y * 0.5):
			rule["offset"] = Vector2(offset.x, -tile_half_size.y)
	return rule

static func get_anchor_offset(anchor: String, size: Vector2) -> Vector2:
	match anchor:
		"center", "wall_mount_center", "door_insert_center":
			return Vector2(size.x * 0.5, size.y * 0.5)
		"bottom_center", "wall_cell_base":
			return Vector2(size.x * 0.5, size.y)
	return Vector2(size.x * 0.5, size.y * 0.5)

static func has_cooling_wall_face_region(side: String) -> bool:
	return COOLING_WALL_CANVAS_FACE_REGIONS.has(side.strip_edges().to_lower())

static func get_cooling_wall_face_region(side: String) -> Rect2:
	var normalized_side: String = side.strip_edges().to_lower()
	var value: Variant = COOLING_WALL_CANVAS_FACE_REGIONS.get(normalized_side, Rect2(0.0, 0.0, 1.0, 1.0))
	if value is Rect2:
		return value
	if value is Rect2i:
		return Rect2(value)
	return Rect2(0.0, 0.0, 1.0, 1.0)

static func get_cooling_wall_canvas_region(side: String, full_size: Vector2) -> Rect2:
	var normalized_region: Rect2 = get_cooling_wall_face_region(side)
	return Rect2(
		Vector2(full_size.x * normalized_region.position.x, full_size.y * normalized_region.position.y),
		Vector2(full_size.x * normalized_region.size.x, full_size.y * normalized_region.size.y)
	)

static func build_outer_utility_layout(context: Dictionary) -> Dictionary:
	var segment: Dictionary = {}
	var segment_value: Variant = context.get("segment", {})
	if segment_value is Dictionary:
		segment = Dictionary(segment_value)
	var fallback_center: Vector2 = _as_vector2(context.get("fallback_center", Vector2.ZERO), Vector2.ZERO)
	var center: Vector2 = _as_vector2(segment.get("mid", fallback_center), fallback_center)
	var normal: Vector2 = _as_vector2(segment.get("normal", Vector2.UP), Vector2.UP).normalized()
	center += normal * OUTER_UTILITY_VERTICAL_OFFSET_SCALE
	var start_point: Vector2 = _as_vector2(segment.get("start_edge", center), center)
	var end_point: Vector2 = _as_vector2(segment.get("end_edge", center), center)
	var base_width: float = _as_non_negative_float(context.get("base_width", 4.0), 4.0) * OUTER_UTILITY_WIDTH_SCALE
	var kind: String = str(context.get("kind", "")).strip_edges().to_lower()
	var primary_width: float = base_width
	var secondary_width: float = base_width * 0.62
	if kind != "water_pipe":
		primary_width = base_width * OUTER_UTILITY_HEIGHT_SCALE
		secondary_width = base_width * 1.55
	return {
		"kind": kind,
		"center": center,
		"start": start_point,
		"end": end_point,
		"base_width": base_width,
		"primary_width": primary_width,
		"secondary_width": secondary_width
	}

static func _as_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value)
	return fallback

static func _as_non_negative_float(value: Variant, fallback: float) -> float:
	var number: float = fallback
	if value is float or value is int:
		number = float(value)
	return maxf(number, 0.0)
