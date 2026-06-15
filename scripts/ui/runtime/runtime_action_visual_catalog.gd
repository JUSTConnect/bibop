extends RefCounted
class_name RuntimeActionVisualCatalog

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")

const ICON_GENERIC := "action_generic"

const VISUAL_ID_TO_ICON_ID: Dictionary = {
	"move_forward": "action_move_forward",
	"move_backward": "action_move_backward",
	"turn_left": "action_turn_left",
	"turn_right": "action_turn_right",
	"action": "action_interact",
	"interact": "action_interact",
	"end_turn": "action_end_turn",
	"door_open": "action_door_open",
	"door_close": "action_door_close",
	"unlock": "action_unlock",
	"password_input": "action_password_input",
	"digital_key_apply": "action_digital_key",
	"connect": "action_connect",
	"scan": "action_scan",
	"hack": "action_hack",
	"download": "action_download",
	"energy_drain": "action_energy_drain",
	"pickup": "action_pickup",
	"pickup_digital": "action_pickup_digital",
	"use_item": "action_use_item",
	"fuse_insert": "action_fuse_insert",
	"fuse_remove": "action_fuse_remove",
	"plug_in": "action_plug_in",
	"plug_out": "action_plug_out",
	"cable_end_1": "action_cable_end_1",
	"cable_end_2": "action_cable_end_2",
	"wire_connect": "action_wire_connect",
	"wire_connect_1": "action_wire_connect",
	"wire_connect_2": "action_wire_connect",
	"power_wire_disconnect": "action_power_disconnect",
	"wire_disconnect_1": "action_wire_disconnect",
	"wire_disconnect_2": "action_wire_disconnect",
	"cut": "action_cut",
	"repair": "action_repair",
	"light_toggle": "action_light_toggle",
	"breaker_open": "action_breaker_open",
	"breaker_close": "action_breaker_close",
	"power_switch": "action_power_switch",
	"switch": "action_switch",
	"power_line_select": "action_power_line",
	"platform_activate": "action_platform",
	"platform_raise": "action_platform_raise",
	"platform_lower": "action_platform_lower",
	"platform_rotate": "action_platform_rotate",
	"platform_rotate_left": "action_platform_rotate_left",
	"platform_rotate_right": "action_platform_rotate_right",
	"heavy_claw": "action_heavy_claw",
	"heavy_claw_attach": "action_heavy_claw",
	"heavy_claw_break_wall": "action_heavy_claw_break_wall",
	"push": "action_push",
	"pull": "action_pull",
	"force_open": "action_force_open",
	"impact": "action_impact",
	"attack": "action_attack",
	"stun": "action_stun",
	"repair_ally": "action_repair_ally",
	"disable": "action_disable",
	"enable": "action_enable"
}

const CONTROL_VISUAL_IDS: Dictionary = {
	"move_forward": "move_forward",
	"move_backward": "move_backward",
	"turn_left": "turn_left",
	"turn_right": "turn_right",
	"action": "action",
	"connect": "connect",
	"heavy_claw": "heavy_claw",
	"cut": "cut",
	"end_turn": "end_turn"
}


static func normalize_action_id(action_id: String) -> String:
	return action_id.strip_edges().to_lower()


static func _is_power_switcher_data(object_data: Dictionary) -> bool:
	if object_data.is_empty():
		return false
	var object_type: String = str(object_data.get("object_type", object_data.get("type", ""))).strip_edges().to_lower()
	var archetype_id: String = str(object_data.get("archetype_id", object_data.get("map_constructor_prefab_id", object_data.get("prefab_id", "")))).strip_edges().to_lower()
	return object_type == "power_switcher" or archetype_id == "power_switcher"


static func _get_platform_operation(object_data: Dictionary) -> String:
	return str(object_data.get("mechanism_operation", object_data.get("operation", object_data.get("platform_action", "")))).strip_edges().to_lower()


static func get_visual_action_id(action_id: String, object_data: Dictionary = {}) -> String:
	var normalized_action_id: String = normalize_action_id(action_id)
	match normalized_action_id:
		"open", "open_door":
			return "door_open"
		"close", "close_door":
			return "door_close"
		"unlock", "unlock_door":
			return "unlock"
		"input_password":
			return "password_input"
		"apply_digital_key":
			return "digital_key_apply"
		"connect":
			return "connect"
		"scan":
			return "scan"
		"hack":
			return "hack"
		"download":
			return "download"
		"drain_energy":
			return "energy_drain"
		"pickup":
			return "pickup_digital" if str(object_data.get("item_form", "physical")).strip_edges().to_lower() == "digital" else "pickup"
		"use_item":
			return "use_item"
		"insert_fuse":
			return "fuse_insert"
		"remove_fuse":
			return "fuse_remove"
		"plug_in":
			return "plug_in"
		"plug_out":
			return "plug_out"
		"take_end_1":
			return "cable_end_1"
		"take_end_2":
			return "cable_end_2"
		"connect_wire_end":
			return "wire_connect"
		"connect_wire_1":
			return "wire_connect_1"
		"connect_wire_2":
			return "wire_connect_2"
		"disconnect_power_wire":
			return "power_wire_disconnect"
		"disconnect_wire_1":
			return "wire_disconnect_1"
		"disconnect_wire_2":
			return "wire_disconnect_2"
		"cut":
			return "cut"
		"repair":
			return "repair"
		"switch":
			return get_switch_visual_action_id(object_data)
		"activate_platform":
			return get_platform_visual_action_id(object_data)
		"raise_platform", "raise":
			return "platform_raise"
		"lower_platform", "lower":
			return "platform_lower"
		"rotate_platform_left", "rotate_left":
			return "platform_rotate_left"
		"rotate_platform_right", "rotate_right":
			return "platform_rotate_right"
		"push":
			return "heavy_claw_attach" if WorldObjectCatalogRef.can_world_object_be_moved_by_heavy_claw(object_data) else "push"
		"pull":
			return "pull"
		"break_breachable_wall", "breach":
			return "heavy_claw_break_wall"
		"force_open":
			return "force_open"
		"impact":
			return "impact"
		"attack":
			return "attack"
		"stun":
			return "stun"
		"repair_ally":
			return "repair_ally"
		"disable":
			return "disable"
		"enable":
			return "enable"
	if normalized_action_id.begins_with("circuit_"):
		return "power_line_select"
	if normalized_action_id.begins_with("access_code_"):
		return "password_input"
	return normalized_action_id if not normalized_action_id.is_empty() else "generic"


static func get_switch_visual_action_id(object_data: Dictionary) -> String:
	if _is_power_switcher_data(object_data):
		var switcher_type: String = WorldObjectCatalogRef.normalize_switcher_type(object_data)
		if switcher_type == WorldObjectCatalogRef.SWITCHER_TYPE_LIGHT:
			return "light_toggle"
		if switcher_type == WorldObjectCatalogRef.SWITCHER_TYPE_POWER_BREAKER:
			return "breaker_open" if bool(object_data.get("is_on", false)) else "breaker_close"
		if switcher_type == WorldObjectCatalogRef.SWITCHER_TYPE_POWER_SWITCHER:
			return "power_switch"
	return "switch"


static func get_platform_visual_action_id(object_data: Dictionary) -> String:
	var operation: String = _get_platform_operation(object_data)
	match operation:
		"raise":
			return "platform_raise"
		"lower":
			return "platform_lower"
		"rotate_left":
			return "platform_rotate_left"
		"rotate_right":
			return "platform_rotate_right"
		"rotate":
			return "platform_rotate"
	return "platform_activate"


static func get_icon_id(visual_action_id: String) -> String:
	var normalized_visual_id: String = normalize_action_id(visual_action_id)
	return str(VISUAL_ID_TO_ICON_ID.get(normalized_visual_id, ICON_GENERIC))


static func get_control_visual_metadata(control_id: String) -> Dictionary:
	var normalized_control_id: String = normalize_action_id(control_id)
	var visual_action_id: String = str(CONTROL_VISUAL_IDS.get(normalized_control_id, normalized_control_id))
	return {
		"visual_action_id": visual_action_id,
		"icon_id": get_icon_id(visual_action_id)
	}


static func apply_control_button_metadata(button: Button, control_id: String) -> void:
	if button == null:
		return
	var metadata: Dictionary = get_control_visual_metadata(control_id)
	button.set_meta("visual_action_id", str(metadata.get("visual_action_id", "")))
	button.set_meta("icon_id", str(metadata.get("icon_id", ICON_GENERIC)))


static func get_circuit_line_metadata(action_id: String, object_data: Dictionary = {}) -> Dictionary:
	var normalized_action_id: String = normalize_action_id(action_id)
	if not normalized_action_id.begins_with("circuit_"):
		return {}
	var line_number_text: String = normalized_action_id.trim_prefix("circuit_")
	if not line_number_text.is_valid_int():
		return {}
	var line_index: int = int(line_number_text) - 1
	if line_index < 0:
		return {}
	var switcher_lines: Array[Dictionary] = WorldObjectCatalogRef.normalize_switcher_lines(object_data)
	if line_index >= switcher_lines.size():
		return {}
	var line: Dictionary = switcher_lines[line_index]
	return {
		"line_index": line_index,
		"line_id": str(line.get("line_id", "")),
		"line_label": str(line.get("label", "")),
		"line_direction": str(line.get("direction", "")),
		"line_color_id": str(line.get("color_id", "")),
		"line_circuit_id": str(line.get("circuit_id", ""))
	}


static func get_action_visual_metadata(action_id: String, object_data: Dictionary = {}) -> Dictionary:
	var visual_action_id: String = get_visual_action_id(action_id, object_data)
	var metadata: Dictionary = {
		"visual_action_id": visual_action_id,
		"icon_id": get_icon_id(visual_action_id)
	}
	var line_metadata: Dictionary = get_circuit_line_metadata(action_id, object_data)
	for key in line_metadata.keys():
		metadata[key] = line_metadata[key]
	return metadata
