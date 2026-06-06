extends RefCounted
class_name InteractionSystem
const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const ObjectFacingServiceRef = preload("res://scripts/game/object/object_facing_service.gd")

const SUPPORTED_ACTIONS := ["open","close","unlock","input_password","apply_digital_key","access_code_0","access_code_1","access_code_2","access_code_3","access_code_4","access_code_5","access_code_6","access_code_7","access_code_8","access_code_9","cut","impact","force_open","connect","scan","hack","download","drain_energy","pickup","use_item","insert_fuse","remove_fuse","repair","plug_in","plug_out","take_end_1","take_end_2","connect_wire_end","connect_wire_1","connect_wire_2","disconnect_power_wire","disconnect_wire_1","disconnect_wire_2","circuit_1","circuit_2","circuit_3","open_door","close_door","unlock_door","push","pull","breach","break_breachable_wall","switch","disable","enable","attack","stun","repair_ally"]

static func normalize_action_id(action_type: String) -> String:
	match action_type.strip_edges().to_lower():
		"breach":
			return "break_breachable_wall"
		_:
			return action_type.strip_edges().to_lower()

static func can_apply_action(actor: Dictionary, module: Dictionary, target_object: Dictionary, action_type: String) -> Dictionary:
	action_type = normalize_action_id(action_type)
	if action_type not in SUPPORTED_ACTIONS:
		return _result(false, "Action not supported.", [], "unsupported_action")
	if target_object.is_empty():
		return _result(false, "No target object.", [], "target_missing")
	var front_side_gate: Dictionary = ObjectFacingServiceRef.build_interaction_gate(
		target_object,
		WorldObjectCatalogRef.to_world_cell(target_object.get("position", actor.get("target_position", Vector2i(-1, -1))), Vector2i(-1, -1)),
		WorldObjectCatalogRef.to_world_cell(actor.get("actor_position", Vector2i(-1, -1)), Vector2i(-1, -1))
	)
	if not bool(front_side_gate.get("success", true)):
		return _result(false, str(front_side_gate.get("message", ObjectFacingServiceRef.FRONT_SIDE_HINT)), [], str(front_side_gate.get("reason", ObjectFacingServiceRef.FRONT_SIDE_REQUIRED_REASON)))
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
			if _door_requires_key_card(target_object) and bool(actor.get("manipulator_occupied", false)):
				return _result(false, "Free manipulator required.", [], "free_manipulator_required")
			var unlock_target: Dictionary = target_object.duplicate(true)
			if unlock_power_mode in ["external", "external_power", "external power"]:
				unlock_target["power_mode"] = "internal"
			var unlock_gate: Dictionary = _validate_door_class(actor, unlock_target, true)
			if not bool(unlock_gate.get("success", false)):
				return unlock_gate
	if action_type == "break_breachable_wall":
		if str(target_object.get("object_group", "")) != "wall" or str(target_object.get("wall_archetype", "")) != "breachable":
			return _result(false, "Target is not a Breachable Wall.", [], "not_breachable_wall")
		if str(module.get("id", "")) != "manipulator_heavy_claw_v1":
			return _result(false, "Heavy Claw required.", [], "heavy_claw_required")
		if not Array(target_object.get("breach_tools", [])).has("heavy_claw"):
			return _result(false, "Heavy Claw cannot breach this wall.", [], "tool_not_allowed")
		var break_actor_side: String = WorldObjectCatalogRef.get_wall_side_for_adjacent_actor(Vector2i(target_object.get("position", actor.get("target_position", Vector2i(-1, -1)))), Vector2i(actor.get("actor_position", Vector2i(-1, -1))))
		if not WorldObjectCatalogRef.can_heavy_claw_breach_wall_from_side(target_object, break_actor_side):
			return _result(false, "Heavy Claw must attack the cracked side.", [], "wrong_breach_side")
	if action_type == "connect" or action_type == "apply_digital_key" or action_type == "input_password" or action_type.begins_with("access_code_"):
		if not bool(target_object.get("has_connector_jack", false)):
			return _result(false, "Connector jack unavailable.", [], "connector_jack_required")
		var connection_type: String = str(target_object.get("connection_type", "wired"))
		var interface_field := "%s_connector_level" % connection_type
		if str(module.get("id", "")).is_empty() or int(actor.get(interface_field, actor.get("connector_level", 0))) < int(target_object.get("required_connector_level", 1)):
			return _result(false, "Connector Version too low.", [], "connector_level_too_low")
	if action_type == "pickup" and actor.get("manipulator_occupied", false) and not _is_keycard_item(target_object):
		return _result(false, "Free manipulator required.")
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
	var group: String = str(target_object.get("object_group", ""))
	var module_id: String = str(module.get("id", ""))
	match action_type:
		"open":
			if group == "door":
				if target_object.get("state", "") == "locked" or bool(target_object.get("is_locked", false)):
					return _result(false, "Door is locked. Key required.")
				var gate: Dictionary = _validate_door_class(actor, target_object)
				if not gate.success:
					return gate
				if target_object.get("state", "") != "closed":
					return _result(false, "Door cannot be opened.")
				target_object["state"] = "open"
				target_object = WorldObjectCatalogRef.normalize_door_state_fields(target_object)
				return _result(true, "Door opened.", [{"type":"door_opened"},{"type":"set_state","state":"open"},{"type":"set_blocks_movement","value":false},{"type":"set_bool","field":"blocks_vision_when_closed","value":bool(target_object.get("blocks_vision_when_closed", false))},{"type":"set_bool","field":"blocks_vision","value":bool(target_object.get("blocks_vision", false))},{"type":"set_bool","field":"is_open","value":true},{"type":"set_bool","field":"is_closed","value":false},{"type":"set_bool","field":"is_locked","value":false},{"type":"set_bool","field":"locked","value":false}])
		"close":
			if group != "door":
				return _result(false, "Cannot close this object.")
			var close_gate: Dictionary = _validate_door_class(actor, target_object)
			if not close_gate.success:
				return close_gate
			if target_object.get("state", "") != "open":
				return _result(false, "Door is not open.")
			target_object["state"] = "closed"
			target_object = WorldObjectCatalogRef.normalize_door_state_fields(target_object)
			return _result(true, "Door closed.", [{"type":"set_state","state":"closed"},{"type":"set_blocks_movement","value":true},{"type":"set_bool","field":"blocks_vision_when_closed","value":bool(target_object.get("blocks_vision_when_closed", false))},{"type":"set_bool","field":"blocks_vision","value":bool(target_object.get("blocks_vision", false))},{"type":"set_bool","field":"is_open","value":false},{"type":"set_bool","field":"is_closed","value":true}])
		"unlock":
			if group != "door":
				return _result(false, "Cannot unlock this object.")
			var unlock_power_mode: String = str(target_object.get("power_mode", "internal")).strip_edges().to_lower()
			if unlock_power_mode in ["external", "external_power", "external power"] and bool(target_object.get("is_powered", false)):
				return _result(false, "Door is connected to power source.")
			elif unlock_power_mode in ["external", "external_power", "external power"]:
				target_object["power_mode"] = "internal"
			var door_gate: Dictionary = _validate_door_class(actor, target_object, true)
			if not door_gate.success:
				return door_gate
			var required_key_id: String = str(target_object.get("required_key_id", "")).strip_edges()
			var has_required_key := not required_key_id.is_empty() and Array(actor.get("collected_key_ids", [])).has(required_key_id)
			var access_type: String = _get_door_access_type(target_object)
			if _door_requires_key_card(target_object) and bool(actor.get("manipulator_occupied", false)):
				return _result(false, "Free manipulator required.")
			if _door_requires_terminal(target_object):
				return _result(false, "Door is controlled by linked terminal.")
			if not required_key_id.is_empty() and not has_required_key:
				return _result(false, "No matching key.")
			if required_key_id.is_empty() and access_type == WorldObjectCatalogRef.ACCESS_TYPE_NO_KEY:
				target_object["state"] = "closed"
				return _result(true, "Door unlocked.", [{"type":"door_unlocked"},{"type":"set_state","state":"closed"},{"type":"set_blocks_movement","value":true},{"type":"set_bool","field":"is_locked","value":false},{"type":"set_bool","field":"locked","value":false},{"type":"set_bool","field":"is_open","value":false},{"type":"set_bool","field":"is_closed","value":true}])
			if module_id in ["mechanical_keycard", "digital_key_opened"]:
				target_object["state"] = "closed"
				target_object = WorldObjectCatalogRef.normalize_door_state_fields(target_object)
				var unlock_message := "Door unlocked with key." if has_required_key else "Door unlocked."
				return _result(true, unlock_message, [{"type":"door_unlocked"},{"type":"set_state","state":"closed"},{"type":"set_blocks_movement","value":true},{"type":"set_bool","field":"is_locked","value":false},{"type":"set_bool","field":"locked","value":false},{"type":"set_bool","field":"is_open","value":false},{"type":"set_bool","field":"is_closed","value":true}])
			if module_id == "digital_key_encrypted":
				return _result(false, "File rejected: encrypted.")
			if module_id == "digital_key_damaged":
				return _result(false, "File rejected: damaged.")
		"apply_digital_key":
			if group != "door" or _get_door_access_type(target_object) != WorldObjectCatalogRef.ACCESS_TYPE_DIGITAL_KEY:
				return _result(false, "Digital-key lock not present.")
			if not bool(target_object.get("connected", false)):
				return _result(false, "Connect to door first.")
			if module_id != "digital_key_opened":
				return _result(false, "Matching Digital Key required.")
			return _result(true, "Digital Key accepted. Door unlocked.", [{"type":"set_state","state":"closed"}])
		"input_password":
			if _get_door_access_type(target_object) != WorldObjectCatalogRef.ACCESS_TYPE_ACCESS_CODE:
				return _result(false, "Access-code lock not present.")
			if not bool(target_object.get("connected", false)):
				return _result(false, "Connect to door first.")
			var entered_code: String = str(target_object.get("access_code_entry", ""))
			var expected_code: String = str(target_object.get("access_code_value", target_object.get("password", "")))
			if entered_code.length() == 4 and entered_code == expected_code:
				return _result(true, "Access Code accepted. Door unlocked.", [{"type":"set_state","state":"closed"},{"type":"set_string","field":"access_code_entry","value":""}])
			return _result(false, "Access Code rejected.")
		"access_code_0", "access_code_1", "access_code_2", "access_code_3", "access_code_4", "access_code_5", "access_code_6", "access_code_7", "access_code_8", "access_code_9":
			if group != "door" or _get_door_access_type(target_object) != WorldObjectCatalogRef.ACCESS_TYPE_ACCESS_CODE:
				return _result(false, "Access-code lock not present.")
			if not bool(target_object.get("connected", false)):
				return _result(false, "Connect to door first.")
			var entry: String = str(target_object.get("access_code_entry", ""))
			if entry.length() >= 4:
				return _result(false, "Access Code already has four digits.")
			return _result(true, "Access Code digit entered.", [{"type":"set_string","field":"access_code_entry","value":entry + action_type.trim_prefix("access_code_")}])
		"cut":
			if target_object.get("object_type", "") == "power_cable":
				target_object["state"] = "damaged"
				target_object["is_powered"] = false
				return _result(true, "Cable cut.", [{"type":"power_recalc_needed"},{"type":"set_state","state":"damaged"}])
			if group == "door" and module_id == "plasma_cutter_v1":
				if target_object.get("material", "") == WorldObjectCatalogRef.DOOR_MATERIAL_ENERGY and target_object.get("is_powered", true):
					return _result(false, "Plasma cutter has no effect.")
				if target_object.get("material", "") in ["steel", "reinforced_steel"]:
					target_object["state"] = "damaged"
					return _result(true, "Door has been cut and damaged.")
				return _result(false, "Plasma cutter has no effect.")
			if group == "wall" and module_id == "plasma_cutter_v1":
				target_object["state"] = "damaged"
				return _result(true, "Wall cut and damaged.", [{"type":"set_state","state":"damaged"}])
		"impact":
			if module_id == "sledgehammer_v1" and group == "door":
				var hits: int = int(target_object.get("impact_hits", 0)) + 1
				target_object["impact_hits"] = hits
				var material: String = str(target_object.get("material", ""))
				if WorldObjectCatalogRef.get_legacy_source_id(target_object) == "grid_door":
					if hits >= 2:
						target_object["state"] = "destroyed"
						return _result(true, "Grid door destroyed.", [{"type":"set_state","state":"destroyed"},{"type":"set_blocks_movement","value":false}])
				elif material == WorldObjectCatalogRef.DOOR_MATERIAL_STEEL:
					if hits >= 2:
						target_object["state"] = "damaged"
						return _result(true, "Steel door damaged.")
				elif material == WorldObjectCatalogRef.DOOR_MATERIAL_REINFORCED_STEEL:
					if hits >= 3:
						target_object["state"] = "damaged"
						return _result(true, "Reinforced steel door damaged.")
				elif material == WorldObjectCatalogRef.DOOR_MATERIAL_TITANIUM:
					return _result(false, "Impact ineffective.")
				return _result(true, "Impact applied.")
			if module_id == "sledgehammer_v1" and group == "wall":
				if str(target_object.get("state", "")) == "damaged":
					target_object["state"] = "destroyed"
					return _result(true, "Wall destroyed.", [{"type":"set_state","state":"destroyed"},{"type":"set_blocks_movement","value":false}])
				target_object["state"] = "damaged"
				return _result(true, "Wall damaged.", [{"type":"set_state","state":"damaged"}])
		"force_open":
			if group == "door" and target_object.get("state", "") in ["damaged", "half_open", "jammed"] and module_id == "manipulator_heavy_claw_v1":
				target_object["state"] = "open"
				return _result(true, "Door forced open.", [{"type":"set_state","state":"open"},{"type":"set_blocks_movement","value":false}])
			if group == "wall" and module_id == "manipulator_heavy_claw_v1" and str(target_object.get("state", "")) == "damaged":
				target_object["state"] = "open"
				return _result(true, "Wall opening forced.", [{"type":"set_state","state":"open"},{"type":"set_blocks_movement","value":false}])
			return _result(false, "Door cannot be forced open.")
		"connect":
			if group in ["terminal", "door"] or bool(target_object.get("is_digital_device", false)):
				var connection_type: String = str(target_object.get("connection_type", "wired"))
				var expected = {"wired":"wired_connector","optical":"optical_connector","wireless":"wireless_connector","high_bandwidth":"high_bandwidth_connector"}
				var needed = expected.get(connection_type, "wired_connector")
				if module_id.find(needed) == -1:
					return _result(false, "Item does not fit this device.")
				var interface_field := "%s_connector_level" % connection_type
				if int(actor.get(interface_field, actor.get("connector_level", 0))) < int(target_object.get("required_connector_level", 1)):
					return _result(false, "Connector Version too low.")
				target_object["connected"] = true
				return _result(true, "Device connected.", [{"type":"set_bool","field":"connected","value":true}])
		"scan":
			if not bool(target_object.get("connected", false)):
				return _result(false, "Connect to device first.")
			target_object["scan_level"] = maxi(2, int(target_object.get("scan_level", 0)))
			target_object["scanned"] = true
			return _result(true, "Device scanned.", [{"type":"set_int","field":"scan_level","value":target_object["scan_level"]},{"type":"set_bool","field":"scanned","value":true}])
		"hack":
			if int(actor.get("processor_level", 0)) < int(target_object.get("required_processor_level", 1)):
				return _result(false, "Hacking impossible")
			if int(target_object.get("terminal_class", 1)) >= 3 and target_object.get("can_attack", false) and not actor.get("firewall_module_v1", false):
				return _result(false, "Firewall required.", ["terminal_attack"])
			if group == "terminal":
				WorldObjectCatalogRef.update_world_object_heat_state(target_object)
				if str(target_object.get("state", "")) == "overheated":
					return _result(false, "Terminal overheated. Hack failed.", [{"type":"terminal_overheated","heat_breakdown":WorldObjectCatalogRef.get_world_object_heat_breakdown(target_object, 0)}])
				var hack_heat: int = maxi(0, int(target_object.get("hack_heat", 1)))
				if WorldObjectCatalogRef.would_world_object_overheat_with_temporary_heat(target_object, hack_heat):
					return _result(false, "Terminal overheated. Hack failed.", [{"type":"terminal_overheated","heat_breakdown":WorldObjectCatalogRef.get_world_object_heat_breakdown(target_object, hack_heat)}])
			if group == "door":
				target_object["state"] = "closed"
				target_object["download_unlocked"] = true
				target_object = WorldObjectCatalogRef.normalize_door_state_fields(target_object)
				return _result(true, "Door hack successful. Door unlocked.", [{"type":"set_state","state":"closed"},{"type":"set_bool","field":"is_locked","value":false},{"type":"set_bool","field":"locked","value":false},{"type":"set_bool","field":"is_open","value":false},{"type":"set_bool","field":"is_closed","value":true},{"type":"set_blocks_movement","value":true},{"type":"set_bool","field":"download_unlocked","value":true}])
			target_object["state"] = "hacked"
			if group == "threat":
				return _result(true, "Hack successful.", [{"type":"set_state","state":"hacked"},{"type":"set_behavior_state","behavior_state":"idle"}])
			return _result(true, "Hack successful.", [{"type":"terminal_hacked"},{"type":"apply_terminal_controls"},{"type":"set_state","state":"hacked"}])
		"download":
			var record_id: String = str(target_object.get("stored_key_id", target_object.get("access_key_id", target_object.get("download_record_id", "")))).strip_edges()
			if record_id.is_empty():
				for field_name in ["stored_key_ids", "stored_access_ids", "stored_item_ids", "digital_key_ids", "access_code_ids"]:
					var stored_ids_value: Variant = target_object.get(field_name, [])
					if stored_ids_value is Array and not Array(stored_ids_value).is_empty():
						record_id = str(Array(stored_ids_value)[0]).strip_edges()
						break
			var record_name: String = str(target_object.get("download_display_name", record_id)).strip_edges()
			return _result(true, "Downloaded %s." % record_name, [{"type":"store_digital_record","record_id":record_id,"display_name":record_name,"description":"Downloaded from %s" % str(target_object.get("display_name", target_object.get("id", "device")))}])
		"break_breachable_wall":
			if group == "wall" and str(target_object.get("wall_archetype", "")) == "breachable" and module_id == "manipulator_heavy_claw_v1":
				return _result(true, "Breachable Wall broken.", [{"type":"set_state","state":"removed"},{"type":"set_blocks_movement","value":false}])
			return _result(false, "Cannot break this wall.")
		"push", "pull":
			if action_type == "push" and not WorldObjectCatalogRef.can_world_object_be_moved_by_heavy_claw(target_object):
				return _result(false, "Object cannot be moved by Heavy Claw.")
			var move_gate: Dictionary = _validate_weight_class(actor, target_object)
			if not move_gate.success:
				return move_gate
			if module_id == "magnetic_manipulator_v1":
				if int(actor.get("range_to_target", 0)) > 4:
					return _result(false, "Target out of range.")
				if not actor.get("is_straight_line", true):
					return _result(false, "Magnetic path blocked.")
				if actor.get("target_is_grate", false):
					return _result(false, "Cannot pull through grate.")
				if actor.get("magnetic_path_blocked", false):
					return _result(false, "Magnetic path blocked.")
				var material_tags: Array = Array(target_object.get("material_tags", []))
				if not target_object.get("magnetic", false) and not material_tags.has("metal"):
					return _result(false, "Object is not magnetic.")
			var facing: Vector2i = Vector2i(actor.get("facing_direction", Vector2i.ZERO))
			var direction: Vector2i = facing
			if action_type == "pull":
				direction = -facing
			if action_type == "push":
				return _result(true, "Heavy object moved.")
			return _result(true, "Object moved.", [{"type":"object_move","mode":action_type,"direction":direction,"dx":direction.x,"dy":direction.y}])
		"insert_fuse":
			if not str(target_object.get("object_type", "")).begins_with("fuse_box") and str(target_object.get("object_type", "")) != "fuse_block":
				return _result(false, "Cannot insert fuse here.")
			if bool(target_object.get("fuse_installed", false)) or str(target_object.get("state", "")) == "installed":
				return _result(false, "Fuse already installed.")
			if module_id != "fuse":
				return _result(false, "Manipulator does not contain a fuse.")
			target_object["state"] = "installed"
			target_object["fuse_installed"] = true
			return _result(true, "Fuse installed.", [{"type":"set_state","state":"installed"},{"type":"set_bool","field":"fuse_installed","value":true},{"type":"set_bool","field":"fuse_present","value":true},{"type":"power_recalc_needed"}])
		"remove_fuse":
			if not str(target_object.get("object_type", "")).begins_with("fuse_box") and str(target_object.get("object_type", "")) != "fuse_block":
				return _result(false, "Cannot remove fuse here.")
			if not bool(target_object.get("fuse_installed", str(target_object.get("state", "")) == "installed")):
				return _result(false, "No fuse installed.")
			target_object["state"] = "empty"
			target_object["fuse_installed"] = false
			return _result(true, "Fuse removed.", [{"type":"set_state","state":"empty"},{"type":"set_bool","field":"fuse_installed","value":false},{"type":"set_bool","field":"fuse_present","value":false},{"type":"grant_item","item_type":"fuse"},{"type":"power_recalc_needed"}])
		"repair":
			if module_id != "repair_v1" and module_id != "repair_kit":
				return _result(false, "Repair module or repair kit not found.")
			var repair_state: String = str(target_object.get("state", "")).strip_edges().to_lower()
			var repair_object_type: String = str(target_object.get("object_type", "")).strip_edges().to_lower()
			var is_power_cable: bool = repair_object_type == "power_cable" or repair_object_type == "power_cable_reel"
			var cable_needs_repair: bool = is_power_cable and (repair_state in ["cut", "damaged", "broken"] or bool(target_object.get("cut", false)) or bool(target_object.get("damaged", false)) or bool(target_object.get("broken", false)))
			if repair_state != "damaged" and not cable_needs_repair:
				return _result(false, "Object is not damaged.")
			var repaired_state: String = "ok" if is_power_cable else "active"
			target_object["state"] = repaired_state
			target_object["damaged"] = false
			target_object["broken"] = false
			target_object["cut"] = false
			var effects: Array = [{"type":"set_state","state":repaired_state},{"type":"set_bool","field":"damaged","value":false},{"type":"set_bool","field":"broken","value":false},{"type":"set_bool","field":"cut","value":false}]
			if is_power_cable:
				effects.append({"type":"repair_power_cable"})
			var object_group: String = str(target_object.get("object_group", ""))
			if is_power_cable or target_object.has("power_network_id") or object_group in ["power", "terminal"]:
				effects.append({"type":"power_recalc_needed"})
			return _result(true, "Object repaired.", effects)
		"switch":
			var state: String = str(target_object.get("state", "switch_off"))
			if state.strip_edges().to_lower() in ["cut", "damaged", "broken", "destroyed"] or bool(target_object.get("cut", false)) or bool(target_object.get("damaged", false)) or bool(target_object.get("broken", false)):
				return _result(false, "Switch is damaged.")
			var object_type: String = str(target_object.get("object_type", "")).strip_edges().to_lower()
			if object_type.begins_with("power_source") and not bool(target_object.get("switchable", target_object.get("can_toggle", true))):
				return _result(false, "Power source is not switchable.")
			if object_type == "circuit_switch":
				var available_outputs: Array[int] = []
				for output_index in range(1, 4):
					var output_target: String = str(target_object.get("output_%d_wire_id" % output_index, target_object.get("output_%d_direction" % output_index, ""))).strip_edges().to_lower()
					if not output_target.is_empty() and output_target != "none":
						available_outputs.append(output_index)
				if not available_outputs.is_empty():
					var active_output: int = int(target_object.get("active_output_index", 0))
					var next_output: int = available_outputs[0]
					var current_output_position: int = available_outputs.find(active_output)
					if current_output_position >= 0:
						next_output = available_outputs[(current_output_position + 1) % available_outputs.size()]
					target_object["active_output_index"] = next_output
					return _result(true, "Circuit %d selected." % next_output, [{"type":"set_int","field":"active_output_index","value":next_output},{"type":"power_recalc_needed"}])
			var source_toggle: bool = object_type.begins_with("power_source")
			var next_state: String = ("on" if state in ["off", "switch_off"] else "off") if source_toggle else ("switch_on" if state in ["switch_off", "off", "open"] else "switch_off")
			var is_on: bool = next_state in ["on", "switch_on"]
			target_object["state"] = next_state
			target_object["is_on"] = is_on
			var switch_effects: Array = [{"type":"set_state","state":next_state},{"type":"set_bool","field":"is_on","value":is_on},{"type":"set_string","field":"switch_state","value":"on" if is_on else "off"}]
			if source_toggle:
				switch_effects.append({"type":"set_bool","field":"is_powered","value":is_on})
			if object_type == "light_switch":
				switch_effects.append({"type":"toggle_linked_lights","is_on":is_on})
			switch_effects.append({"type":"power_recalc_needed"})
			return _result(true, "Power source toggled." if source_toggle else "Switch toggled.", switch_effects)
		"circuit_1", "circuit_2", "circuit_3":
			if str(target_object.get("object_type", "")) != "circuit_switch":
				return _result(false, "Circuit output unavailable.")
			var output_index: int = int(action_type.replace("circuit_", ""))
			if str(target_object.get("output_%d_wire_id" % output_index, target_object.get("output_%d_direction" % output_index, "none"))).strip_edges().to_lower() in ["", "none"]:
				return _result(false, "Circuit output unavailable.")
			target_object["active_output_index"] = output_index
			return _result(true, "Circuit %d selected." % output_index, [{"type":"set_int","field":"active_output_index","value":output_index},{"type":"power_recalc_needed"}])
		"plug_in":
			if _is_cable_unavailable(target_object):
				return _result(false, "Cable must be repaired first.")
			target_object["plugged"] = true
			return _result(true, "Wire connected.", [{"type":"set_bool","field":"plugged","value":true},{"type":"connect_cable_end_to_target","wire_side":0},{"type":"power_recalc_needed"}])
		"plug_out":
			target_object["plugged"] = false
			target_object.erase("plugged_cable_end")
			return _result(true, "Wire disconnected.", [{"type":"set_bool","field":"plugged","value":false},{"type":"disconnect_cable_end_from_target","wire_side":0},{"type":"power_recalc_needed"}])
		"take_end_1", "take_end_2":
			var end_index: int = 1 if action_type == "take_end_1" else 2
			var end_state: String = str(target_object.get("end_%d_state" % end_index, "on_reel")).strip_edges().to_lower()
			if not (end_state in ["on_reel", "disconnected", ""]):
				return _result(false, "Cable end is already in use.")
			target_object["end_%d_state" % end_index] = "held"
			target_object["end_%d_target_id" % end_index] = ""
			return _result(true, "Cable end %d taken." % end_index, [{"type":"set_state","state":str(target_object.get("state", "disconnected"))},{"type":"take_cable_end","reel_id":str(target_object.get("id", "")),"end_index":end_index}])
		"connect_wire_end", "connect_wire_1", "connect_wire_2":
			if _is_cable_unavailable(target_object):
				return _result(false, "Cable must be repaired first.")
			var wire_side: int = 0
			if action_type == "connect_wire_1":
				wire_side = 1
			elif action_type == "connect_wire_2":
				wire_side = 2
			target_object["cable_power_connected"] = true
			return _result(true, "Wire connected.", [{"type":"connect_cable_end_to_target","wire_side":wire_side},{"type":"power_recalc_needed"}])
		"disconnect_power_wire", "disconnect_wire_1", "disconnect_wire_2":
			var disconnect_side: int = 0
			if action_type == "disconnect_wire_1":
				disconnect_side = 1
			elif action_type == "disconnect_wire_2":
				disconnect_side = 2
			return _result(true, "Power wire disconnected.", [{"type":"disconnect_cable_end_from_target","wire_side":disconnect_side},{"type":"power_recalc_needed"}])

		"activate_platform", "switch_platform":
			if group == "platform":
				if str(target_object.get("state", "active")) in ["unpowered", "disabled", "damaged"] or not bool(target_object.get("is_powered", true)):
					return _result(false, "Platform is unpowered.")
				if str(target_object.get("control_type", "internal")) == "internal":
					if int(actor.get("manipulator_level", 0)) < 1:
						return _result(false, "Manipulator required.")
					if not bool(actor.get("platform_switch_access", false)):
						return _result(false, "Platform switch is not accessible.")
				return _result(true, "Platform activated.", [{"type":"activate_platform"}])
			if group == "terminal" and str(target_object.get("terminal_type", "")) == "platform":
				if str(target_object.get("state", "active")) in ["unpowered", "disabled", "damaged"] or not bool(target_object.get("platform_remote_control", true)):
					return _result(false, "Platform terminal is unavailable.")
				var required_interface: int = maxi(1, int(target_object.get("required_connector_level", 1)))
				var connection_type := str(target_object.get("connection_type", "wired"))
				var interface_key := "%s_connector_level" % connection_type
				if int(actor.get(interface_key, 0)) < required_interface:
					return _result(false, "Connector required.")
				return _result(true, "Platform terminal activated.", [{"type":"activate_platform"}])
		"pickup":
			if group == "item":
				return _result(true, "Item picked up.")
			return _result(false, "Cannot pick up this object.")

		"attack":
			if group != "threat":
				return _result(false, "Cannot attack this object.")
			var attack_damage: int = 0
			if module_id == "laser_v1":
				attack_damage = 5
			elif module_id == "sledgehammer_v1":
				attack_damage = 5
			elif module_id == "saw_v1":
				attack_damage = 6
			elif module_id == "gas_burner_v1":
				attack_damage = 4
			if attack_damage <= 0:
				return _result(false, "No valid attack module.")
			return _result(true, "Attack landed.", [{"type":"damage_target","amount":attack_damage}])
		"stun":
			if group != "threat" or module_id != "shocker_v1":
				return _result(false, "Cannot stun this object.")
			return _result(true, "Target stunned.", [{"type":"damage_target","amount":1},{"type":"set_state","state":"stunned"},{"type":"set_behavior_state","behavior_state":"idle"},{"type":"set_stunned_turns","value":1}])
		"drain_energy":
			if group != "threat" or module_id != "energy_drain_v1":
				return _result(false, "Cannot drain this object.")
			if bool(target_object.get("drained_this_turn", false)):
				return _result(false, "Target already drained this turn.")
			var pool: int = int(target_object.get("drain_energy_pool", 0))
			if pool <= 0:
				return _result(false, "No energy left to drain.")
			var drained: int = mini(5, pool)
			return _result(true, "Energy drained.", [{"type":"drain_energy","amount":drained}])
		"disable":
			if group != "threat":
				return _result(false, "Cannot disable this object.")
			return _result(true, "Target disabled.", [{"type":"set_state","state":"disabled"},{"type":"set_behavior_state","behavior_state":"idle"}])
		"repair_ally":
			return _result(false, "No ally repair target.")
	return _result(false, "No available action for this object.")

static func _is_cable_unavailable(target_object: Dictionary) -> bool:
	var state: String = str(target_object.get("state", "")).strip_edges().to_lower()
	return state in ["cut", "damaged", "broken", "destroyed"] or bool(target_object.get("cut", false)) or bool(target_object.get("damaged", false)) or bool(target_object.get("broken", false))


static func _normalize_runtime_door_data(object_data: Dictionary) -> Dictionary:
	var data: Dictionary = WorldObjectCatalogRef.normalize_world_object_contract(object_data)
	data = WorldObjectCatalogRef.normalize_door_contract(data)
	return WorldObjectCatalogRef.normalize_door_state_fields(data)

static func _is_door_object(object_data: Dictionary) -> bool:
	var data: Dictionary = WorldObjectCatalogRef.normalize_world_object_contract(object_data)
	return str(data.get("object_group", "")) == "door"

static func _get_door_access_type(object_data: Dictionary) -> String:
	return WorldObjectCatalogRef.normalize_access_type(object_data.get("access_type", object_data.get("lock_type", "")))

static func _door_requires_key_card(object_data: Dictionary) -> bool:
	return _get_door_access_type(object_data) == WorldObjectCatalogRef.ACCESS_TYPE_KEY_CARD

static func _door_requires_terminal(object_data: Dictionary) -> bool:
	return _get_door_access_type(object_data) == WorldObjectCatalogRef.ACCESS_TYPE_TERMINAL

static func _validate_door_class(actor: Dictionary, target_object: Dictionary, allow_external_control: bool = false) -> Dictionary:
	var control_mode := str(target_object.get("control_type", target_object.get("control_mode", "internal"))).strip_edges().to_lower()
	if not allow_external_control and control_mode in ["external", "external_control", "external control", "terminal"]:
		return _result(false, "Use linked terminal.", [], "terminal_control_required")
	var power_mode := str(target_object.get("power_mode", "internal")).strip_edges().to_lower()
	if power_mode in ["external", "external_power", "external power"] and not bool(target_object.get("is_powered", true)):
		return _result(false, "Door is unpowered.")
	if int(actor.get("manipulator_level", 0)) < int(target_object.get("required_manipulator_level", 1)):
		return _result(false, "Manipulator Version too low.")
	if target_object.get("material", "") == "electromagnetic" and int(actor.get("connector_level", 0)) < int(target_object.get("required_connector_level", 0)):
		return _result(false, "Connector Version too low.")
	return _result(true, "OK")

static func _validate_weight_class(actor: Dictionary, target_object: Dictionary) -> Dictionary:
	var weight_class: String = str(target_object.get("weight_class", "normal"))
	var actor_power: String = str(actor.get("power_class", "scout"))
	if weight_class == "heavy" and actor_power == "scout":
		return _result(false, "Object is too heavy.")
	if weight_class == "block" and actor_power != "juggernaut":
		return _result(false, "Object is too heavy.")
	return _result(true, "OK")

static func normalize_action_result(result: Dictionary, target_object: Dictionary, action_id: String) -> Dictionary:
	action_id = normalize_action_id(action_id)
	var normalized: Dictionary = result.duplicate(true)
	normalized["success"] = bool(result.get("success", false))
	normalized["message"] = str(result.get("message", ""))
	normalized["reason"] = str(result.get("reason", "ok" if bool(normalized["success"]) else "action_unavailable"))
	normalized["target_id"] = str(target_object.get("id", ""))
	normalized["action_id"] = action_id
	var effects_value: Variant = result.get("effects", [])
	normalized["state_changed"] = effects_value is Array and not effects_value.is_empty()
	return normalized

static func _reason_from_message(message: String, success: bool) -> String:
	if success:
		return "ok"
	var normalized_message: String = message.strip_edges().to_lower()
	if normalized_message.find("free manipulator") >= 0:
		return "free_manipulator_required"
	if normalized_message.find("key-card") >= 0 or normalized_message.find("matching key") >= 0 or normalized_message.find("key required") >= 0:
		return "key_card_required"
	if normalized_message.find("power source") >= 0:
		return "power_must_be_cut"
	if normalized_message.find("unpowered") >= 0:
		return "unpowered"
	if normalized_message.find("linked terminal") >= 0:
		return "terminal_control_required"
	if normalized_message.find("storage buffer") >= 0:
		return "storage_buffer_required"
	if normalized_message.find("hack device first") >= 0:
		return "hack_required"
	if normalized_message.find("no target") >= 0:
		return "target_missing"
	return "action_unavailable"

static func _result(success: bool, message: String, effects: Array = [], reason: String = "") -> Dictionary:
	var normalized_reason: String = reason if not reason.is_empty() else _reason_from_message(message, success)
	return {"success": success, "message": message, "reason": normalized_reason, "effects": effects}


static func _is_keycard_item(item_data: Dictionary) -> bool:
	return WorldObjectCatalogRef.is_key_card_item(item_data)
