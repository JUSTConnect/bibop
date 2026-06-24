extends RefCounted

const ROUTE_OBJECT := "object"
const ROUTE_WALL_AUTHORED := "wall_authored"
const ROUTE_FLOOR_AUTHORED := "floor_authored"

static func build_attempt_plan(context: Dictionary) -> Array[Dictionary]:
	var attempts: Array[Dictionary] = []
	var order := 0
	var profile_key := _read_string(context, "profile_key")
	var primary_asset_id := _read_string(context, "primary_asset_id")
	var is_case_visual := _read_bool(context, "is_case_visual")
	var primary_is_png := _read_bool(context, "primary_is_png")
	if is_case_visual:
		attempts.append(_make_attempt(order, "png", _read_string(context, "case_asset_id", primary_asset_id), "case"))
		order += 1
	elif profile_key != "cable":
		if primary_is_png:
			attempts.append(_make_attempt(order, "png", primary_asset_id, "primary"))
			order += 1
		else:
			attempts.append(_make_attempt(order, "optional", primary_asset_id, "primary"))
			order += 1
			attempts.append(_make_attempt(order, "legacy", primary_asset_id, "primary"))
			order += 1
	if _read_bool(context, "has_door_visual"):
		attempts.append(_make_attempt(order, "optional", _read_string(context, "door_texture_asset_id"), "door_state"))
		order += 1
	if _read_bool(context, "has_terminal_visual"):
		attempts.append(_make_attempt(order, "optional", _read_string(context, "terminal_texture_asset_id"), "terminal_state"))
	return attempts

static func get_descriptor_route(render_contract: String, wall_contract: String, floor_contract: String) -> String:
	if render_contract == wall_contract:
		return ROUTE_WALL_AUTHORED
	if render_contract == floor_contract:
		return ROUTE_FLOOR_AUTHORED
	return ROUTE_OBJECT

static func should_emit_success_accent(context: Dictionary) -> bool:
	return _read_bool(context, "texture_succeeded") and not _read_bool(context, "is_case_visual")

static func _read_string(context: Dictionary, key: String, fallback: String = "") -> String:
	var value = context.get(key, fallback)
	if value is String or value is StringName:
		return str(value)
	return fallback

static func _read_bool(context: Dictionary, key: String, fallback: bool = false) -> bool:
	var value = context.get(key, fallback)
	if value is bool:
		return value
	return fallback

static func _make_attempt(order: int, kind: String, asset_id: String, source: String) -> Dictionary:
	return {
		"order": order,
		"kind": kind,
		"asset_id": asset_id,
		"source": source,
		"stop_on_success": true,
	}
