extends RefCounted
class_name InteractionSystem
const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const ObjectFacingServiceRef = preload("res://scripts/game/object/object_facing_service.gd")
const BreachableWallRulesServiceRef = preload("res://scripts/game/wall/breachable_wall_rules_service.gd")
const WallMountedPlacementRulesServiceRef = preload("res://scripts/game/wall/wall_mounted_placement_rules_service.gd")

const SUPPORTED_ACTIONS := ["open","close","unlock","input_password","apply_digital_key","access_code_0","access_code_1","access_code_2","access_code_3","access_code_4","access_code_5","access_code_6","access_code_7","access_code_8","access_code_9","cut","impact","force_open","connect","scan","hack","download","drain_energy","pickup","use_item","insert_fuse","remove_fuse","repair","plug_in","plug_out","take_end_1","take_end_2","connect_wire_end","connect_wire_1","connect_wire_2","disconnect_power_wire","disconnect_wire_1","disconnect_wire_2","circuit_1","circuit_2","circuit_3","open_door","close_door","unlock_door","activate_platform","raise_platform","lower_platform","rotate_platform_left","rotate_platform_right","push","pull","breach","break_breachable_wall","switch","disable","enable","attack","stun","repair_ally"]

static func normalize_action_id(action_type: String) -> String:
	match action_type.strip_edges().to_lower():
		"breach":
			return "break_breachable_wall"
		_:
			return action_type.strip_edges().to_lower()

static func _is_cable_object(target_object: Dictionary) -> bool:
	for field_name in ["object_type", "type", "archetype_id", "map_constructor_prefab_id", "prefab_id"]:
		var id_value: String = str(target_object.get(field_name, "")).strip_edges().to_lower()
		if id_value in ["power_cable", "cable", "wall_cable", "placed_cable_segment", "cable_reel", "power_cable_reel"]:
			return true
	return false

static func _is_cable_reel_object(target_object: Dictionary) -> bool:
	for field_name in ["object_type", "type", "archetype_id", "map_constructor_prefab_id", "prefab_id"]:
		var id_value: String = str(target_object.get(field_name, "")).strip_edges().to_lower()
		if id_value in ["power_cable_reel", "cable_reel"]:
			return true
	return false

static func _object_supports_external_power_input(target_object: Dictionary) -> bool:
	if bool(target_object.get("requires_external_power", false)):
		return true
	var power_mode: String = str(target_object.get("power_mode", "")).strip_edges().to_lower()
	if power_mode in ["external", "external_power", "external power"]:
		return true
	var object_type: String = str(target_object.get("object_type", target_object.get("type", ""))).strip_edges().to_lower()
	return object_type in ["power_socket", "outlet"]

static func _is_broken_cable_object(target_object: Dictionary) -> bool:
	return bool(target_object.get("broken", false)) or bool(target_object.get("is_broken", false)) or bool(target_object.get("damaged", false)) or str(target_object.get("state", "")).strip_edges().to_lower() == "broken" or str(target_object.get("cable_health_state", "")).strip_edges().to_lower() == "broken" or str(target_object.get("health_state", "")).strip_edges().to_lower() == "broken"

static func _actor_held_item_matches(actor: Dictionary, expected_type: String) -> bool:
	var normalized_expected: String = expected_type.strip_edges().to_lower()
	if normalized_expected.is_empty():
		return false

	var held_id: String = str(actor.get("held_item_id", "")).strip_edges().to_lower()
	var held_type: String = str(actor.get("held_item_type", "")).strip_edges().to_lower()
	var held_data: Dictionary = Dictionary(actor.get("held_item_data", {}))

	if held_type == normalized_expected:
		return true

	if normalized_expected == "fuse":
		if held_id.contains("fuse"):
			return true
		if held_type.contains("fuse"):
			return true
	if normalized_expected in ["cable_reel", "power_cable_reel"]:
		if held_id.contains("cable_reel"):
			return true
		if held_type.contains("cable_reel"):
			return true

	for field_name in ["item_type", "object_type", "item_class", "id", "item_id", "display_name"]:
		var value: String = str(held_data.get(field_name, "")).strip_edges().to_lower()
		if value.is_empty():
			continue

		if value == normalized_expected:
			return true

		if normalized_expected == "fuse" and value.contains("fuse"):
			return true

		if normalized_expected in ["cable_reel", "power_cable_reel"] and value.contains("cable_reel"):
			return true

	return false

static func _actor_has_valid_cable_reel_end(actor: Dictionary) -> bool:
	var held_type: String = str(actor.get("held_item_type", "")).strip_edges().to_lower()
	var held_data: Dictionary = Dictionary(actor.get("held_item_data", {}))
	var data_type: String = ""
	for field_name in ["item_type", "object_type", "item_class", "id", "item_id"]:
		var value: String = str(held_data.get(field_name, "")).strip_edges().to_lower()
		if not value.is_empty():
			data_type = value
			break
	var is_reel_end: bool = held_type == "cable_reel_end" or data_type == "cable_reel_end"
	var is_legacy_identified_end: bool = (held_type in ["cable_end", "wire_end"] or data_type in ["cable_end", "wire_end"]) and held_data.has("reel_id") and held_data.has("end_index")
	if not is_reel_end and not is_legacy_identified_end:
		return false
	var reel_id: String = str(held_data.get("reel_id", "")).strip_edges()
	var end_index: int = int(held_data.get("end_index", 0))
	return not reel_id.is_empty() and end_index >= 1 and end_index <= 2

static func _actor_has_visible_cable_item(actor: Dictionary) -> bool:
	return _actor_has_valid_cable_reel_end(actor)


static func _actor_has_free_storage_slot(actor: Dictionary) -> bool:
	var has_free_pocket_slot: bool = bool(actor.get("has_free_pocket_slot", false))
	var has_free_manipulator_slot: bool = bool(actor.get("has_free_manipulator_slot", false))

	return has_free_pocket_slot or has_free_manipulator_slot
	
static func _is_heavy_claw_movable_action(action_type: String, target_object: Dictionary) -> bool:
	if action_type not in ["push", "pull"]:
		return false
	return WorldObjectCatalogRef.can_world_object_be_moved_by_heavy_claw(target_object)

static func _is_platform_target_object(target_object: Dictionary) -> bool:
	if target_object.is_empty():
		return false

	var object_group: String = str(target_object.get("object_group", target_object.get("group", ""))).strip_edges().to_lower()
	var object_type: String = str(target_object.get("object_type", target_object.get("type", ""))).strip_edges().to_lower()
	var platform_mode: String = str(target_object.get("platform_mode", "")).strip_edges().to_lower()
	var platform_type: String = str(target_object.get("platform_type", "")).strip_edges().to_lower()

	if object_group == "platform":
		return true
	if object_type == "platform":
		return true
	if object_type in ["lifting_platform", "rotating_platform"]:
		return true
	if not platform_mode.is_empty():
		return true
	if platform_type in ["lifting", "rotating", "elevator", "rotator"]:
		return true

	return false
	
static func _is_platform_control_action(action_type: String, target_object: Dictionary) -> bool:
	if action_type not in ["activate_platform", "raise_platform", "lower_platform", "rotate_platform_left", "rotate_platform_right"]:
		return false

	return _is_platform_target_object(target_object)
	
static func can_apply_action(actor: Dictionary, module: Dictionary, target_object: Dictionary, action_type: String) -> Dictionary:
	action_type = normalize_action_id(action_type)
	if action_type not in SUPPORTED_ACTIONS:
		return _result(false, "Action not supported.", [], "unsupported_action")
	if target_object.is_empty():
		return _result(false, "No target object.", [], "target_missing")
	var module_id: String = str(module.get("id", "")).strip_edges()
	if _is_platform_control_action(action_type, target_object):
		if module_id != "platform_control":
			return _result(false, "Platform control module required.", [], "platform_control_required")
		return _result(true, "Platform Action possible.")
	if BreachableWallRulesServiceRef.is_breachable_wall(target_object) and not BreachableWallRulesServiceRef.is_destroyed(target_object) and action_type != "break_breachable_wall":
		return _result(false, "Use Heavy Claw from the cracked side.", [], "heavy_claw_breach_only")
	if _is_heavy_claw_movable_action(action_type, target_object):
		var object_cell: Vector2i = WorldObjectCatalogRef.to_world_cell(target_object.get("position", actor.get("target_position", Vector2i(-1, -1))), Vector2i(-1, -1))
		var actor_cell: Vector2i = WorldObjectCatalogRef.to_world_cell(actor.get("actor_position", Vector2i(-1, -1)), Vector2i(-1, -1))
		var facing_direction: Vector2i = Vector2i(actor.get("facing_direction", Vector2i.ZERO))
		if object_cell != actor_cell + facing_direction:
			return _result(false, "Face the object to attach Heavy Claw.", [], "face_object_to_attach_heavy_claw")
	if _is_door_object(target_object):
		target_object = _normalize_runtime_door_data(target_object)
		if action_type in ["open", "close"]:
			var door_gate: Dictionary = _validate_door_class(actor, target_object)
			if not bool(door_gate.get("success", false)):
				return door_gate
		if action_type == "unlock":
			var unlock_power_mode: String = str(target_object.get("power_mode", "internal")).strip_edges().to_lower()
			if unlock_power_mode in ["external", "external_power", "external power"] and bool(target_object.get("is_powered", false)):
				return _result(false, "Door opens when power is cut.", [], "power_must_be_cut")
			if _door_requires_terminal(target_object):
				return _result(false, "Use linked terminal.", [], "terminal_control_required")
			if _get_door_access_type(target_object) in [WorldObjectCatalogRef.ACCESS_TYPE_DIGITAL_KEY, WorldObjectCatalogRef.ACCESS_TYPE_ACCESS_CODE]:
				return _result(false, "Use Connector for digital access.", [], "digital_access_required")
			var required_key_id: String = str(target_object.get("required_key_id", "")).strip_edges()
			var has_required_key: bool = not required_key_id.is_empty() and Array(actor.get("collected_key_ids", [])).has(required_key_id)
			if not required_key_id.is_empty() and not has_required_key:
				return _result(false, "Key-card required.", [], "key_card_required")
			if _door_requires_key_card(target_object) and str(module.get("id", "")).is_empty():
				return _result(false, "Key-card required.", [], "key_card_required")
			var access_type: String = _get_door_access_type(target_object)
			if access_type not in [WorldObjectCatalogRef.ACCESS_TYPE_NO_KEY, WorldObjectCatalogRef.ACCESS_TYPE_KEY_CARD] and str(module.get("id", "")).is_empty():
				return _result(false, "Digital access required.", [], "digital_access_required")
			var unlock_target: Dictionary = target_object.duplicate(true)
			if unlock_power_mode in ["external", "external_power", "external power"]:
				unlock_target["power_mode"] = "internal"
			var unlock_gate: Dictionary = _validate_door_class(actor, unlock_target, true)
			if not bool(unlock_gate.get("success", false)):
				return unlock_gate
	if action_type == "open" and str(target_object.get("object_type", "")).strip_edges().to_lower() == "case" and module_id == "manipulator_heavy_claw_v1":
		return _result(false, "Heavy Claw cannot open cases.", [], "heavy_claw_cannot_open_case")
	if action_type == "break_breachable_wall":
		if str(target_object.get("object_group", "")) != "wall" or str(target_object.get("wall_archetype", "")) != "breachable":
			return _result(false, "Target is not a Breachable Wall.", [], "not_breachable_wall")
		if str(module.get("id", "")) != "manipulator_heavy_claw_v1":
			return _result(false, "Heavy Claw required.", [], "heavy_claw_required")
		if not Array(target_object.get("breach_tools", [])).has("heavy_claw"):
			return _result(false, "Heavy Claw cannot breach this wall.", [], "tool_not_allowed")
		var wall_position: Vector2i = Vector2i(target_object.get("position", actor.get("target_position", Vector2i(-1, -1))))
		var actor_position: Vector2i = Vector2i(actor.get("actor_position", Vector2i(-1, -1)))
		var rules_wall: Dictionary = target_object.duplicate(true)
		rules_wall["is_breachable"] = true
		rules_wall["wall_state"] = str(target_object.get("wall_state", target_object.get("breach_state", target_object.get("state", "intact"))))
		rules_wall["crack_side"] = WorldObjectCatalogRef.get_grid_side_for_breachable_wall_breach_side(target_object.get("breach_side", target_object.get("crack_side", "sw")))
		var breach_check: Dictionary = BreachableWallRulesServiceRef.can_heavy_claw_breach(rules_wall, actor_position - wall_position, true)
		if not bool(breach_check.get("ok", false)):
			return _result(false, str(breach_check.get("message", "Heavy Claw must attack the cracked side.")), [], "wrong_breach_side")
	if action_type == "connect" or action_type == "apply_digital_key" or action_type == "input_password" or action_type.begins_with("access_code_"):
		if not bool(target_object.get("has_connector_jack", false)):
			return _result(false, "Connector jack unavailable.", [], "connector_jack_required")
		var connection_type: String = str(target_object.get("connection_type", "wired"))
		var interface_field := "%s_connector_level" % connection_type
		if str(module.get("id", "")).is_empty() or int(actor.get(interface_field, actor.get("connector_level", 0))) < int(target_object.get("required_connector_level", 1)):
			return _result(false, "Connector Version too low.", [], "connector_level_too_low")
	if action_type == "pickup":
		if module_id == "manipulator_heavy_claw_v1":
			return _result(false, "Heavy Claw cannot pick up items.", [], "heavy_claw_cannot_pickup")
		pass
	if action_type == "remove_fuse":
		if not module_id.begins_with("manipulator_arm_v"):
			return _result(false, "Manipulator required.", [], "manipulator_required")
	if action_type in ["switch", "plug_in", "plug_out", "circuit_1", "circuit_2", "circuit_3"]:
		if not module_id.begins_with("manipulator_arm_v"):
			return _result(false, "Manipulator required.", [], "manipulator_required")
	if action_type in ["circuit_1", "circuit_2", "circuit_3"] and str(target_object.get("object_type", "")) == "power_switcher":
		var switcher_lines: Array[Dictionary] = WorldObjectCatalogRef.normalize_switcher_lines(target_object)
		var line_index: int = int(action_type.trim_prefix("circuit_")) - 1
		if WorldObjectCatalogRef.normalize_switcher_type(target_object) != WorldObjectCatalogRef.SWITCHER_TYPE_POWER_SWITCHER or line_index < 0 or line_index >= switcher_lines.size():
			return _result(false, "Switcher line unavailable.", [], "switcher_line_unavailable")
	if action_type == "plug_in":
		if not _object_supports_external_power_input(target_object):
			return _result(false, "Target cannot receive external power.", [], "target_not_connectable")
		if not _actor_has_valid_cable_reel_end(actor):
			return _result(false, "Nothing to plug in.", [], "nothing_to_plug_in")
	if action_type in ["connect_wire_end", "connect_wire_1", "connect_wire_2"]:
		if not _actor_has_valid_cable_reel_end(actor):
			return _result(false, "Nothing to plug in.", [], "cable_reel_end_required")
	if action_type == "insert_fuse":
		var fuse_match: bool = _actor_held_item_matches(actor, "fuse")

		if not fuse_match:
			return _result(false, "FUSE_GATE: Fuse required.", [], "fuse_required")
	if action_type == "cut" and module_id != "plasma_cutter_v1":
		return _result(false, "Plasma Cutter required.", [], "plasma_cutter_required")
	if action_type == "cut" and _is_cable_object(target_object) and _is_broken_cable_object(target_object):
		return _result(false, "Cable already broken.", [], "cable_already_broken")
	if action_type == "repair" and module_id != "repair_kit":
		return _result(false, "Repair kit required.", [], "repair_kit_required")
	if action_type == "hack" and actor.get("processor_level", 0) < target_object.get("required_processor_level", 1):
		return _result(false, "Hacking impossible")
	if action_type == "download":
		if str(module.get("id", "")) != "storage_buffer":
			return _result(false, "Storage buffer required.")
		var is_information_terminal_payload: bool = str(target_object.get("object_group", "")) == "terminal" and str(target_object.get("terminal_type", "")).strip_edges().to_lower() == "information" and str(target_object.get("stored_data_type", target_object.get("digital_payload_type", ""))).strip_edges().to_lower() in ["none", "access_code", "digital_key", "data_file"]
		if not is_information_terminal_payload and str(target_object.get("state", "")) != "hacked" and not bool(target_object.get("download_unlocked", false)):
			return _result(false, "Hack device first.")
		var record_id: String = str(target_object.get("stored_key_id", target_object.get("access_key_id", target_object.get("download_record_id", "")))).strip_edges()
		if record_id.is_empty():
			for field_name in ["stored_key_ids", "stored_access_ids", "stored_item_ids", "digital_key_ids", "access_code_ids"]:
				var stored_ids_value: Variant = target_object.get(field_name, [])
				if stored_ids_value is Array and not Array(stored_ids_value).is_empty():
					record_id = str(Array(stored_ids_value)[0]).strip_edges()
					break
		if record_id.is_empty() and not is_information_terminal_payload:
			return _result(false, "No downloadable key or data found.")
	return _result(true, "Action possible.")

static func apply_action(actor: Dictionary, module: Dictionary, target_object: Dictionary, action_type: String) -> Dictionary:
	action_type = normalize_action_id(action_type)
	var can := can_apply_action(actor, module, target_object, action_type)
	if not can.success:
		return can
	if _is_door_object(target_object):
		target_object = _normalize_runtime_door_data(target_object)

	match action_type:
		"open":
			target_object["state"] = "open"
			target_object["is_open"] = true
			target_object["is_closed"] = false
			target_object["blocks_movement"] = false
			return _result(true, "Opened.", [{"type":"set_state","state":"open"},{"type":"set_bool","field":"blocks_movement","value":false},{"type":"normalize_door_state"}])
		"close":
			target_object["state"] = "closed"
			target_object["is_open"] = false
			target_object["is_closed"] = true
			target_object["blocks_movement"] = true
			return _result(true, "Closed.", [{"type":"set_state","state":"closed"},{"type":"set_bool","field":"blocks_movement","value":true},{"type":"normalize_door_state"}])
		"unlock":
			target_object["state"] = "closed"
			target_object["is_locked"] = false
			target_object["locked"] = false
			return _result(true, "Unlocked.", [{"type":"set_state","state":"closed"},{"type":"set_bool","field":"is_locked","value":false},{"type":"set_bool","field":"locked","value":false},{"type":"normalize_door_state"}])
		"input_password":
			var entered_code: String = str(target_object.get("access_code_entry", ""))
			var expected_code: String = str(target_object.get("access_code", target_object.get("password", target_object.get("access_code_value", ""))))
			if expected_code.is_empty() or entered_code != expected_code:
				return _result(false, "Access code rejected.", [], "access_code_rejected")
			target_object["state"] = "closed"
			target_object["is_locked"] = false
			target_object["locked"] = false
			target_object["access_code_entry"] = ""
			return _result(true, "Access code accepted.", [{"type":"set_state","state":"closed"},{"type":"set_bool","field":"is_locked","value":false},{"type":"set_bool","field":"locked","value":false},{"type":"set_field","field":"access_code_entry","value":""},{"type":"normalize_door_state"}])
		"apply_digital_key":
			target_object["state"] = "closed"
			target_object["is_locked"] = false
			target_object["locked"] = false
			return _result(true, "Digital key applied.", [{"type":"set_state","state":"closed"},{"type":"set_bool","field":"is_locked","value":false},{"type":"set_bool","field":"locked","value":false},{"type":"normalize_door_state"}])
		"access_code_0", "access_code_1", "access_code_2", "access_code_3", "access_code_4", "access_code_5", "access_code_6", "access_code_7", "access_code_8", "access_code_9":
			var digit: String = action_type.trim_prefix("access_code_")
			var current_entry: String = str(target_object.get("access_code_entry", ""))
			if current_entry.length() >= 4:
				current_entry = ""
			current_entry += digit
			return _result(true, "Digit entered.", [{"type":"set_field","field":"access_code_entry","value":current_entry}])
		"cut":
			if _is_cable_object(target_object):
				target_object["state"] = "broken"
				target_object["cable_health_state"] = "broken"
				target_object["health_state"] = "broken"
				target_object["broken"] = true
				target_object["is_broken"] = true
				target_object["damaged"] = true
				target_object["cut"] = false
				return _result(true, "Cable broken.", [{"type":"set_state","state":"broken"},{"type":"set_field","field":"cable_health_state","value":"broken"},{"type":"set_field","field":"health_state","value":"broken"},{"type":"set_bool","field":"broken","value":true},{"type":"set_bool","field":"is_broken","value":true},{"type":"set_bool","field":"damaged","value":true},{"type":"set_bool","field":"cut","value":false},{"type":"power_recalc_needed"}])
			return _result(true, "Cut applied.", [{"type":"set_state","state":"cut"},{"type":"set_bool","field":"blocks_movement","value":false}])
		"impact":
			return _result(true, "Impact applied.", [{"type":"set_state","state":"damaged"}])
		"force_open":
			target_object["state"] = "open"
			target_object["blocks_movement"] = false
			return _result(true, "Forced open.", [{"type":"set_state","state":"open"},{"type":"set_bool","field":"blocks_movement","value":false}])
		"connect":
			target_object["connected"] = true
			return _result(true, "Connected.", [{"type":"set_bool","field":"connected","value":true}])
		"download":
			return _result(true, "Downloaded.", [{"type":"download_payload"}])
		"pickup":
			return _result(true, "Picked up.")
		"use_item":
			return _result(true, "Item used.")
		"insert_fuse":
			target_object["state"] = "installed"
			target_object["fuse_installed"] = true
			target_object["fuse_present"] = true
			return _result(true, "Fuse installed.", [{"type":"set_state","state":"installed"},{"type":"set_bool","field":"fuse_installed","value":true},{"type":"set_bool","field":"fuse_present","value":true},{"type":"power_recalc_needed"}])
		"remove_fuse":
			target_object["state"] = "empty"
			target_object["fuse_installed"] = false
			target_object["fuse_present"] = false
			return _result(true, "Fuse removed.", [{"type":"set_state","state":"empty"},{"type":"set_bool","field":"fuse_installed","value":false},{"type":"set_bool","field":"fuse_present","value":false},{"type":"grant_item","item_type":"fuse"},{"type":"power_recalc_needed"}])
		"repair":
			if _is_cable_object(target_object):
				target_object["state"] = "normal"
				target_object["cable_health_state"] = "normal"
				target_object["health_state"] = "normal"
				target_object["broken"] = false
				target_object["is_broken"] = false
				target_object["damaged"] = false
				target_object["cut"] = false
				return _result(true, "Cable repaired.", [{"type":"set_state","state":"normal"},{"type":"set_field","field":"cable_health_state","value":"normal"},{"type":"set_field","field":"health_state","value":"normal"},{"type":"set_bool","field":"broken","value":false},{"type":"set_bool","field":"is_broken","value":false},{"type":"set_bool","field":"damaged","value":false},{"type":"set_bool","field":"cut","value":false},{"type":"power_recalc_needed"}])
			return _result(true, "Repaired.", [{"type":"set_state","state":"active"},{"type":"set_bool","field":"damaged","value":false}])
		"switch":
			var next_on: bool = not bool(target_object.get("is_on", false))
			target_object["is_on"] = next_on
			target_object["switch_state"] = "on" if next_on else "off"
			target_object["state"] = "switch_on" if next_on else "switch_off"
			var switcher_type: String = WorldObjectCatalogRef.normalize_switcher_type(target_object) if str(target_object.get("object_type", "")) == "power_switcher" else "power_breaker"
			if switcher_type == WorldObjectCatalogRef.SWITCHER_TYPE_LIGHT:
				return _result(true, "Light switch toggled.", [{"type":"set_bool","field":"is_on","value":next_on},{"type":"set_field","field":"switch_state","value":"on" if next_on else "off"},{"type":"set_state","state":"switch_on" if next_on else "switch_off"},{"type":"toggle_linked_lights","is_on":next_on}])
			return _result(true, "Breaker toggled.", [{"type":"set_bool","field":"is_on","value":next_on},{"type":"set_field","field":"switch_state","value":"on" if next_on else "off"},{"type":"set_state","state":"switch_on" if next_on else "switch_off"},{"type":"power_recalc_needed"}])
		"plug_in":
			target_object["plugged"] = true
			return _result(true, "Cable plugged in.", [{"type":"set_bool","field":"plugged","value":true},{"type":"connect_cable_end_to_target"},{"type":"power_recalc_needed"}])
		"plug_out":
			target_object["plugged"] = false
			return _result(true, "Plug removed.", [{"type":"set_bool","field":"plugged","value":false},{"type":"disconnect_cable"},{"type":"power_recalc_needed"}])
		"take_end_1", "take_end_2":
			if not _is_cable_reel_object(target_object):
				return _result(false, "Cable reel required.", [], "cable_reel_required")
			if bool(actor.get("manipulator_occupied", false)):
				return _result(false, "Hand occupied.", [], "hand_occupied")
			var take_end_index: int = 1 if action_type == "take_end_1" else 2
			var take_end_state: String = str(target_object.get("end_%d_state" % take_end_index, "on_reel")).strip_edges().to_lower()
			if take_end_state == "connected" or not str(target_object.get("end_%d_target_id" % take_end_index, "")).strip_edges().is_empty():
				return _result(false, "Cable end already connected.", [], "reel_end_already_connected")
			if not (take_end_state in ["on_reel", "disconnected", "free", ""]):
				return _result(false, "Cable end unavailable.", [], "reel_end_unavailable")
			return _result(true, "Cable end taken.", [{"type":"take_cable_end","end_index":take_end_index}])
		"connect_wire_end", "connect_wire_1", "connect_wire_2":
			var connect_end_index: int = 0
			if action_type == "connect_wire_1":
				connect_end_index = 1
			elif action_type == "connect_wire_2":
				connect_end_index = 2
			return _result(true, "Wire connected.", [{"type":"connect_cable","end_index":connect_end_index},{"type":"power_recalc_needed"}])
		"disconnect_power_wire", "disconnect_wire_1", "disconnect_wire_2":
			var disconnect_end_index: int = 0
			if action_type == "disconnect_wire_1":
				disconnect_end_index = 1
			elif action_type == "disconnect_wire_2":
				disconnect_end_index = 2
			return _result(true, "Wire disconnected.", [{"type":"disconnect_cable","end_index":disconnect_end_index},{"type":"power_recalc_needed"}])
		"circuit_1", "circuit_2", "circuit_3":
			var circuit_index: int = int(action_type.trim_prefix("circuit_"))
			target_object["active_circuit"] = circuit_index
			target_object["active_output_index"] = circuit_index
			if str(target_object.get("object_type", "")) == "power_switcher":
				if WorldObjectCatalogRef.normalize_switcher_type(target_object) != WorldObjectCatalogRef.SWITCHER_TYPE_POWER_SWITCHER:
					return _result(false, "Switcher line unavailable.", [], "switcher_line_unavailable")
				var switcher_lines: Array[Dictionary] = WorldObjectCatalogRef.normalize_switcher_lines(target_object)
				var line_index: int = circuit_index - 1
				if line_index < 0 or line_index >= switcher_lines.size():
					return _result(false, "Switcher line unavailable.", [], "switcher_line_unavailable")
				var selected_line: Dictionary = switcher_lines[line_index]
				target_object["active_line_id"] = str(selected_line.get("line_id", ""))
				target_object["active_circuit_id"] = str(selected_line.get("circuit_id", ""))
				target_object["line_color_id"] = str(selected_line.get("color_id", ""))
				return _result(true, "%s selected." % str(selected_line.get("label", "Line")), [{"type":"set_field","field":"active_circuit","value":circuit_index},{"type":"set_field","field":"active_output_index","value":circuit_index},{"type":"set_field","field":"active_line_id","value":target_object["active_line_id"]},{"type":"set_field","field":"active_circuit_id","value":target_object["active_circuit_id"]},{"type":"set_field","field":"line_color_id","value":target_object["line_color_id"]},{"type":"power_recalc_needed"}])
			return _result(true, "Circuit %d selected." % circuit_index, [{"type":"set_field","field":"active_circuit","value":circuit_index},{"type":"set_field","field":"active_output_index","value":circuit_index},{"type":"power_recalc_needed"}])
		"open_door":
			return _result(true, "Door opened by terminal.", [{"type":"terminal_open_door"}])
		"close_door":
			return _result(true, "Door closed by terminal.", [{"type":"terminal_close_door"}])
		"unlock_door":
			return _result(true, "Door unlocked by terminal.", [{"type":"terminal_unlock_door"}])
		"hack":
			target_object["state"] = "hacked"
			return _result(true, "Hacked.", [{"type":"set_state","state":"hacked"},{"type":"set_bool","field":"download_unlocked","value":true}])
		"scan":
			target_object["scan_level"] = max(2, int(target_object.get("scan_level", 0)))
			return _result(true, "Scan complete.", [{"type":"set_int","field":"scan_level","value":int(target_object.get("scan_level", 2))}])
		"drain_energy":
			return _result(true, "Energy drained.", [{"type":"drain_energy","amount":5}])
		"push":
			return _result(true, "Pushed.", [{"type":"object_move","mode":"push","direction":actor.get("facing_direction", Vector2i.ZERO)}])
		"pull":
			return _result(true, "Pulled.", [{"type":"object_move","mode":"pull","direction":actor.get("facing_direction", Vector2i.ZERO)}])
		"break_breachable_wall":
			return _result(true, "Breachable wall broken.", [{"type":"break_breachable_wall"}])
		"attack":
			return _result(true, "Attack resolved.", [{"type":"damage","amount":1}])
		"stun":
			return _result(true, "Stun resolved.", [{"type":"set_state","state":"stunned"}])
		"repair_ally":
			return _result(true, "Ally repaired.", [{"type":"repair_ally"}])
	return _result(false, "No effect")

static func _normalize_runtime_door_data(door: Dictionary) -> Dictionary:
	if door.is_empty():
		return door
	return WorldObjectCatalogRef.normalize_door_state_fields(door)

static func _is_door_object(target_object: Dictionary) -> bool:
	var object_group: String = str(target_object.get("object_group", "")).strip_edges().to_lower()
	var object_type: String = str(target_object.get("object_type", "")).strip_edges().to_lower()
	return object_group == "door" or object_type == "door" or WorldObjectCatalogRef.is_legacy_door_object_type(object_type)

static func _get_door_access_type(target_object: Dictionary) -> String:
	return WorldObjectCatalogRef.normalize_access_type(target_object.get("access_type", target_object.get("lock_type", "")))

static func _door_requires_key_card(target_object: Dictionary) -> bool:
	return _get_door_access_type(target_object) == WorldObjectCatalogRef.ACCESS_TYPE_KEY_CARD

static func _door_requires_terminal(target_object: Dictionary) -> bool:
	return str(target_object.get("control_type", target_object.get("control_mode", "internal"))).strip_edges().to_lower() in ["external", "external_control", "external control", "terminal"]

static func _validate_door_class(actor: Dictionary, target_object: Dictionary, allow_unlock: bool = false) -> Dictionary:
	var door_class: int = int(target_object.get("door_class", 1))
	var power_class: String = str(actor.get("power_class", "scout"))
	var can_handle_class: bool = power_class == "juggernaut" or door_class <= 1 or (power_class == "engineer" and door_class <= 2)
	if not can_handle_class and not allow_unlock:
		return _result(false, "Door class too heavy.", [], "door_class_too_heavy")
	return _result(true, "Door class accepted.")

static func _is_keycard_item(target_object: Dictionary) -> bool:
	return WorldObjectCatalogRef.is_key_card_item(target_object)

static func _result(success: bool, message: String, effects: Array = [], reason: String = "") -> Dictionary:
	return {"success": success, "message": message, "effects": effects, "reason": reason}

static func normalize_action_result(action_result: Dictionary, target_object: Dictionary, action_id: String = "") -> Dictionary:
	if action_result.is_empty():
		return _result(false, "Action failed.")
	if not action_result.has("success") and action_result.has("can_interact"):
		action_result["success"] = bool(action_result.get("can_interact", false))
	if not action_result.has("message"):
		action_result["message"] = str(action_result.get("reason", "Action complete." if bool(action_result.get("success", false)) else "Action failed."))
	if not action_result.has("effects"):
		action_result["effects"] = []
	if action_id == "break_breachable_wall" and bool(action_result.get("success", false)) and Array(action_result.get("effects", [])).is_empty():
		action_result["effects"] = [{"type":"break_breachable_wall"}]
	if str(target_object.get("object_group", "")) == "door" and bool(action_result.get("success", false)):
		target_object = WorldObjectCatalogRef.normalize_door_state_fields(target_object)
	return action_result
