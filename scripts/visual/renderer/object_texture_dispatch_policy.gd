extends RefCounted
class_name ObjectTextureDispatchPolicy

const ROUTE_OBJECT := "object"
const ROUTE_WALL_AUTHORED := "wall_authored"
const ROUTE_FLOOR_AUTHORED := "floor_authored"

static func build_attempt_plan(context: Dictionary) -> Array[Dictionary]:
	var attempts: Array[Dictionary] = []
	var order := 0
	var profile_key := str(context.get("profile_key", ""))
	var primary_asset_id := str(context.get("primary_asset_id", ""))
	var is_case_visual := bool(context.get("is_case_visual", false))
	var primary_is_png := bool(context.get("primary_is_png", false))
	if is_case_visual:
		attempts.append(_make_attempt(order, "png", str(context.get("case_asset_id", primary_asset_id)), "case"))
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
	if bool(context.get("has_door_visual", false)):
		attempts.append(_make_attempt(order, "optional", str(context.get("door_texture_asset_id", "")), "door_state"))
		order += 1
	if bool(context.get("has_terminal_visual", false)):
		attempts.append(_make_attempt(order, "optional", str(context.get("terminal_texture_asset_id", "")), "terminal_state"))
	return attempts

static func get_descriptor_route(render_contract: String, wall_contract: String, floor_contract: String) -> String:
	if render_contract == wall_contract:
		return ROUTE_WALL_AUTHORED
	if render_contract == floor_contract:
		return ROUTE_FLOOR_AUTHORED
	return ROUTE_OBJECT

static func should_draw_success_accent(context: Dictionary) -> bool:
	return bool(context.get("texture_succeeded", false)) and not bool(context.get("is_case_visual", false))

static func _make_attempt(order: int, kind: String, asset_id: String, source: String) -> Dictionary:
	return {
		"order": order,
		"kind": kind,
		"asset_id": asset_id,
		"source": source,
		"stop_on_success": true,
	}
