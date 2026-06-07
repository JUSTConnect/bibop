extends RefCounted
class_name BreachableWallRulesService

# Breachable wall rule helpers.
# Foundation only: no renderer drawing, no scene mutation, no input/action-panel integration.

const FacingSideUtilsRef = preload("res://scripts/visual/facing_side_utils.gd")

const WALL_STATE_INTACT: String = "intact"
const WALL_STATE_BREACHED: String = "breached"
const WALL_STATE_DESTROYED: String = "destroyed"

const BREACH_TOOL_HEAVY_CLAW: String = "heavy_claw"
const BREACH_TOOL_NONE: String = "none"

const BREACH_OVERLAY_TALL: String = "tall"
const BREACH_OVERLAY_MID: String = "mid"
const BREACH_OVERLAY_HALFMID: String = "halfmid"

static func normalize_wall_state(value: String) -> String:
	var normalized: String = str(value).strip_edges().to_lower()
	if normalized in [WALL_STATE_INTACT, WALL_STATE_BREACHED, WALL_STATE_DESTROYED]:
		return normalized
	return WALL_STATE_INTACT

static func normalize_overlay_height(value: String) -> String:
	var normalized: String = str(value).strip_edges().to_lower()
	if normalized in [BREACH_OVERLAY_TALL, BREACH_OVERLAY_MID, BREACH_OVERLAY_HALFMID]:
		return normalized
	return BREACH_OVERLAY_TALL

static func normalize_crack_side(value: String) -> String:
	return FacingSideUtilsRef.normalize_wall_side(value)

static func is_breachable_wall(wall_data: Dictionary) -> bool:
	return bool(wall_data.get("is_breachable", wall_data.get("breachable", false)))

static func is_destroyed(wall_data: Dictionary) -> bool:
	return normalize_wall_state(str(wall_data.get("wall_state", wall_data.get("state", WALL_STATE_INTACT)))) == WALL_STATE_DESTROYED

static func is_passable_after_state(wall_data: Dictionary) -> bool:
	if is_destroyed(wall_data):
		return true
	return bool(wall_data.get("is_passable", false))

static func can_heavy_claw_breach(
	wall_data: Dictionary,
	approach_direction: Vector2i,
	has_heavy_claw: bool
) -> Dictionary:
	if not has_heavy_claw:
		return {"ok": false, "message": "Heavy Claw is not installed.", "required_tool": BREACH_TOOL_HEAVY_CLAW}
	if not is_breachable_wall(wall_data):
		return {"ok": false, "message": "Wall is not breachable.", "required_tool": BREACH_TOOL_NONE}
	if is_destroyed(wall_data):
		return {"ok": false, "message": "Wall is already destroyed.", "required_tool": BREACH_TOOL_NONE}
	var crack_side: String = get_crack_side(wall_data)
	if not FacingSideUtilsRef.can_interact_from_side(crack_side, approach_direction):
		return {
			"ok": false,
			"message": "Heavy Claw can breach only from the cracked side.",
			"required_tool": BREACH_TOOL_HEAVY_CLAW,
			"crack_side": crack_side,
			"approach_direction": approach_direction
		}
	return {
		"ok": true,
		"message": "Heavy Claw breach available.",
		"required_tool": BREACH_TOOL_HEAVY_CLAW,
		"crack_side": crack_side,
		"approach_direction": approach_direction
	}

static func should_show_heavy_claw_action(
	wall_data: Dictionary,
	approach_direction: Vector2i,
	has_heavy_claw: bool
) -> bool:
	return bool(can_heavy_claw_breach(wall_data, approach_direction, has_heavy_claw).get("ok", false))

static func should_show_regular_action_for_breach(wall_data: Dictionary) -> bool:
	# Breach destruction uses Heavy Claw, not the generic Action button.
	return false if is_breachable_wall(wall_data) and not is_destroyed(wall_data) else false

static func apply_heavy_claw_breach(
	wall_data: Dictionary,
	approach_direction: Vector2i,
	has_heavy_claw: bool
) -> Dictionary:
	var check: Dictionary = can_heavy_claw_breach(wall_data, approach_direction, has_heavy_claw)
	if not bool(check.get("ok", false)):
		return {"ok": false, "message": str(check.get("message", "Cannot breach wall.")), "wall_data": wall_data.duplicate(true), "check": check}
	var next_wall: Dictionary = wall_data.duplicate(true)
	next_wall["wall_state"] = WALL_STATE_DESTROYED
	next_wall["state"] = WALL_STATE_DESTROYED
	next_wall["is_passable"] = true
	next_wall["blocks_movement"] = false
	next_wall["blocks_line_of_sight"] = false
	next_wall["needs_visual_refresh"] = true
	next_wall["breached_by"] = BREACH_TOOL_HEAVY_CLAW
	return {
		"ok": true,
		"message": "Breachable wall destroyed.",
		"wall_data": next_wall,
		"opened_passage": true,
		"spawn_debris_overlay": false,
		"requires_visual_refresh": true
	}

static func get_crack_side(wall_data: Dictionary) -> String:
	if wall_data.has("crack_side"):
		return normalize_crack_side(str(wall_data.get("crack_side", "")))
	if wall_data.has("breach_side"):
		return normalize_crack_side(str(wall_data.get("breach_side", "")))
	if wall_data.has("wall_side"):
		return normalize_crack_side(str(wall_data.get("wall_side", "")))
	if wall_data.has("facing"):
		return normalize_crack_side(str(wall_data.get("facing", "")))
	return FacingSideUtilsRef.WALL_SIDE_SW

static func set_crack_side(wall_data: Dictionary, crack_side: String) -> Dictionary:
	var next_wall: Dictionary = wall_data.duplicate(true)
	next_wall["crack_side"] = normalize_crack_side(crack_side)
	return next_wall

static func get_overlay_adjustment(overlay_height: String) -> Dictionary:
	var height: String = normalize_overlay_height(overlay_height)
	match height:
		BREACH_OVERLAY_TALL:
			return {
				"overlay_height": height,
				"scale_y": 1.0,
				"offset_y": 0.0,
				"bottom_trim_px": 0,
				"notes": "Tall overlay is the baseline and should remain unchanged."
			}
		BREACH_OVERLAY_MID:
			return {
				"overlay_height": height,
				"scale_y": 0.96,
				"offset_y": -2.0,
				"bottom_trim_px": 3,
				"notes": "Mid overlay is slightly reduced at the bottom to avoid spilling onto neighboring floor."
			}
		BREACH_OVERLAY_HALFMID:
			return {
				"overlay_height": height,
				"scale_y": 0.88,
				"offset_y": -4.0,
				"bottom_trim_px": 5,
				"notes": "Halfmid overlay needs stronger vertical correction and face alignment."
			}
		_:
			return {}

static func build_overlay_payload(wall_data: Dictionary) -> Dictionary:
	var overlay_height: String = normalize_overlay_height(str(wall_data.get("breach_overlay_height", wall_data.get("height", BREACH_OVERLAY_TALL))))
	return {
		"is_breachable": is_breachable_wall(wall_data),
		"wall_state": normalize_wall_state(str(wall_data.get("wall_state", wall_data.get("state", WALL_STATE_INTACT)))),
		"crack_side": get_crack_side(wall_data),
		"overlay_height": overlay_height,
		"overlay_adjustment": get_overlay_adjustment(overlay_height),
		"visible": is_breachable_wall(wall_data) and not is_destroyed(wall_data)
	}

static func build_action_payload(
	wall_data: Dictionary,
	approach_direction: Vector2i,
	has_heavy_claw: bool
) -> Dictionary:
	var heavy_claw_check: Dictionary = can_heavy_claw_breach(wall_data, approach_direction, has_heavy_claw)
	return {
		"show_heavy_claw": bool(heavy_claw_check.get("ok", false)),
		"show_action": should_show_regular_action_for_breach(wall_data),
		"required_tool": BREACH_TOOL_HEAVY_CLAW if is_breachable_wall(wall_data) and not is_destroyed(wall_data) else BREACH_TOOL_NONE,
		"message": str(heavy_claw_check.get("message", "")),
		"crack_side": get_crack_side(wall_data),
		"approach_direction": approach_direction
	}
