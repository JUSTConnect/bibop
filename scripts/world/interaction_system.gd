extends RefCounted
class_name InteractionSystem
const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")

const SUPPORTED_ACTIONS := ["open","close","unlock","input_password","cut","impact","force_open","connect","scan","hack","download","drain_energy","pickup","use_item","insert_fuse","remove_fuse","repair","plug_in","plug_out","take_end_1","take_end_2","connect_wire_end","disconnect_power_wire","circuit_1","circuit_2","circuit_3","push","pull","switch","disable","enable","attack","stun","repair_ally"]

static func can_apply_action(actor: Dictionary, module: Dictionary, target_object: Dictionary, action_type: String) -> Dictionary:
	if action_type not in SUPPORTED_ACTIONS:
		return _result(false, "Action not supported.")
	if target_object.is_empty():
		return _result(false, "No target object.")
	if action_type == "pickup" and actor.get("manipulator_occupied", false):
		return _result(false, "Manipulator is occupied.")
	if action_type == "hack" and actor.get("processor_level", 0) < target_object.get("required_processor_level", 1):
		return _result(false, "Hacking impossible")
	if action_type == "download":
		if String(module.get("id", "")) != "storage_buffer":
			return _result(false, "Storage buffer required.")
		if String(target_object.get("state", "")) != "hacked" and not bool(target_object.get("download_unlocked", false)):
			return _result(false, "Hack device first.")
		var record_id: String = String(target_object.get("stored_key_id", target_object.get("access_key_id", target_object.get("download_record_id", "")))).strip_edges()
		if record_id.is_empty():
			for field_name in ["stored_key_ids", "stored_access_ids", "stored_item_ids", "digital_key_ids", "access_code_ids"]:
				var stored_ids_value: Variant = target_object.get(field_name, [])
				if stored_ids_value is Array and not Array(stored_ids_value).is_empty():
					record_id = String(Array(stored_ids_value)[0]).strip_edges()
					break
		if record_id.is_empty():
			return _result(false, "No downloadable key or data found.")
	return _result(true, "Action possible.")

static func apply_action(actor: Dictionary, module: Dictionary, target_object: Dictionary, action_type: String) -> Dictionary:
	var can := can_apply_action(actor, module, target_object, action_type)
	if not can.success:
		return can
	if String(target_object.get("object_group", "")) == "door":
		target_object = WorldObjectCatalogRef.normalize_door_state_fields(target_object)
	var group: String = String(target_object.get("object_group", ""))
	var module_id: String = String(module.get("id", ""))
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
				target_object["is_open"] = true
				target_object["is_closed"] = false
				target_object["is_locked"] = false
				target_object["locked"] = false
				target_object["is_closed"] = false
				target_object["blocks_movement"] = false
				return _result(true, "Door opened.", [{"type":"door_opened"},{"type":"set_state","state":"open"},{"type":"set_blocks_movement","value":false},{"type":"set_bool","field":"is_open","value":true},{"type":"set_bool","field":"is_closed","value":false},{"type":"set_bool","field":"is_locked","value":false},{"type":"set_bool","field":"locked","value":false}])
		"close":
			if group != "door":
				return _result(false, "Cannot close this object.")
			var close_gate: Dictionary = _validate_door_class(actor, target_object)
			if not close_gate.success:
				return close_gate
			if target_object.get("state", "") != "open":
				return _result(false, "Door is not open.")
			target_object["state"] = "closed"
			target_object["is_open"] = false
			target_object["is_closed"] = true
			target_object["blocks_movement"] = true
			return _result(true, "Door closed.", [{"type":"set_state","state":"closed"},{"type":"set_blocks_movement","value":true},{"type":"set_bool","field":"is_open","value":false},{"type":"set_bool","field":"is_closed","value":true}])
		"unlock":
			if group != "door":
				return _result(false, "Cannot unlock this object.")
			var unlock_power_mode: String = String(target_object.get("power_mode", "internal")).strip_edges().to_lower()
			if unlock_power_mode in ["external", "external_power", "external power"] and bool(target_object.get("is_powered", false)):
				return _result(false, "Door is connected to power source.")
			elif unlock_power_mode in ["external", "external_power", "external power"]:
				target_object["power_mode"] = "internal"
			var door_gate: Dictionary = _validate_door_class(actor, target_object)
			if not door_gate.success:
				return door_gate
			var required_key_id: String = String(target_object.get("required_key_id", "")).strip_edges()
			var has_required_key := not required_key_id.is_empty() and Array(actor.get("collected_key_ids", [])).has(required_key_id)
			if String(target_object.get("access_type", target_object.get("lock_type", ""))).strip_edges().to_lower() in ["terminal_access"]:
				return _result(false, "Door is controlled by linked terminal.")
			if not required_key_id.is_empty() and not has_required_key:
				return _result(false, "No matching key.")
			if required_key_id.is_empty() and String(target_object.get("access_type", target_object.get("lock_type", ""))).strip_edges().to_lower() in ["none", "no_key", ""]:
				target_object["state"] = "closed"
				target_object["is_locked"] = false
				target_object["locked"] = false
				target_object["is_open"] = false
				target_object["is_closed"] = true
				target_object["blocks_movement"] = true
				return _result(true, "Door unlocked.", [{"type":"door_unlocked"},{"type":"set_state","state":"closed"},{"type":"set_blocks_movement","value":true},{"type":"set_bool","field":"is_locked","value":false},{"type":"set_bool","field":"locked","value":false},{"type":"set_bool","field":"is_open","value":false},{"type":"set_bool","field":"is_closed","value":true}])
			if module_id in ["mechanical_keycard", "digital_key_opened"]:
				target_object["state"] = "closed"
				target_object["is_locked"] = false
				target_object["locked"] = false
				target_object["is_open"] = false
				target_object["is_closed"] = true
				target_object["blocks_movement"] = true
				target_object = WorldObjectCatalogRef.normalize_door_state_fields(target_object)
				var unlock_message := "Door unlocked with key." if has_required_key else "Door unlocked."
				return _result(true, unlock_message, [{"type":"door_unlocked"},{"type":"set_state","state":"closed"},{"type":"set_blocks_movement","value":true},{"type":"set_bool","field":"is_locked","value":false},{"type":"set_bool","field":"locked","value":false},{"type":"set_bool","field":"is_open","value":false},{"type":"set_bool","field":"is_closed","value":true}])
			if module_id == "digital_key_encrypted":
				return _result(false, "File rejected: encrypted.")
			if module_id == "digital_key_damaged":
				return _result(false, "File rejected: damaged.")
		"input_password":
			if target_object.get("lock_type", "") != "password":
				return _result(false, "Password lock not present.")
			if module.get("input_password", "") == target_object.get("password", "") and module.get("input_password", "") != "":
				target_object["state"] = "closed"
				return _result(true, "Password accepted.")
			return _result(false, "Password rejected.")
		"cut":
			if target_object.get("object_type", "") == "power_cable":
				target_object["state"] = "damaged"
				target_object["is_powered"] = false
				return _result(true, "Cable cut.", [{"type":"power_recalc_needed"},{"type":"set_state","state":"damaged"}])
			if group == "door" and module_id == "plasma_cutter_v1":
				if target_object.get("object_type", "") == "energy_door" and target_object.get("is_powered", true):
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
				match target_object.get("object_type", ""):
					"grid_door":
						if hits >= 2:
							target_object["state"] = "destroyed"
							target_object["blocks_movement"] = false
							return _result(true, "Grid door destroyed.", [{"type":"set_state","state":"destroyed"},{"type":"set_blocks_movement","value":false}])
					"steel_door":
						if hits >= 2:
							target_object["state"] = "damaged"
							return _result(true, "Steel door damaged.")
					"reinforced_steel_door":
						if hits >= 3:
							target_object["state"] = "damaged"
							return _result(true, "Reinforced steel door damaged.")
					"titanium_door":
						return _result(false, "Impact ineffective.")
				return _result(true, "Impact applied.")
			if module_id == "sledgehammer_v1" and group == "wall":
				if String(target_object.get("state", "")) == "damaged":
					target_object["state"] = "destroyed"
					target_object["blocks_movement"] = false
					return _result(true, "Wall destroyed.", [{"type":"set_state","state":"destroyed"},{"type":"set_blocks_movement","value":false}])
				target_object["state"] = "damaged"
				return _result(true, "Wall damaged.", [{"type":"set_state","state":"damaged"}])
		"force_open":
			if group == "door" and target_object.get("state", "") in ["damaged", "half_open", "jammed"] and module_id == "manipulator_heavy_claw_v1":
				target_object["state"] = "open"
				target_object["blocks_movement"] = false
				return _result(true, "Door forced open.", [{"type":"set_state","state":"open"},{"type":"set_blocks_movement","value":false}])
			if group == "wall" and module_id == "manipulator_heavy_claw_v1" and String(target_object.get("state", "")) == "damaged":
				target_object["state"] = "open"
				target_object["blocks_movement"] = false
				return _result(true, "Wall opening forced.", [{"type":"set_state","state":"open"},{"type":"set_blocks_movement","value":false}])
			return _result(false, "Door cannot be forced open.")
		"connect":
			if group in ["terminal", "door"] or bool(target_object.get("is_digital_device", false)):
				var connection_type: String = String(target_object.get("connection_type", "wired"))
				var expected = {"wired":"wired_connector","optical":"optical_connector","wireless":"wireless_connector","high_bandwidth":"high_bandwidth_connector"}
				var needed = expected.get(connection_type, "wired_connector")
				if module_id.find(needed) == -1:
					return _result(false, "Item does not fit this device.")
				var interface_field := "%s_connector_level" % connection_type
				if int(actor.get(interface_field, actor.get("connector_level", 0))) < int(target_object.get("required_connector_level", 1)):
					return _result(false, "Connector level too low.")
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
				if String(target_object.get("state", "")) == "overheated":
					return _result(false, "Terminal overheated. Hack failed.", [{"type":"terminal_overheated","heat_breakdown":WorldObjectCatalogRef.get_world_object_heat_breakdown(target_object, 0)}])
				var hack_heat: int = maxi(0, int(target_object.get("hack_heat", 1)))
				if WorldObjectCatalogRef.would_world_object_overheat_with_temporary_heat(target_object, hack_heat):
					return _result(false, "Terminal overheated. Hack failed.", [{"type":"terminal_overheated","heat_breakdown":WorldObjectCatalogRef.get_world_object_heat_breakdown(target_object, hack_heat)}])
			if group == "door":
				target_object["state"] = "closed"
				target_object["is_locked"] = false
				target_object["locked"] = false
				target_object["is_open"] = false
				target_object["is_closed"] = true
				target_object["blocks_movement"] = true
				target_object["download_unlocked"] = true
				return _result(true, "Door hack successful. Door unlocked.", [{"type":"set_state","state":"closed"},{"type":"set_bool","field":"is_locked","value":false},{"type":"set_bool","field":"locked","value":false},{"type":"set_bool","field":"is_open","value":false},{"type":"set_bool","field":"is_closed","value":true},{"type":"set_blocks_movement","value":true},{"type":"set_bool","field":"download_unlocked","value":true}])
			target_object["state"] = "hacked"
			if group == "threat":
				return _result(true, "Hack successful.", [{"type":"set_state","state":"hacked"},{"type":"set_behavior_state","behavior_state":"idle"}])
			return _result(true, "Hack successful.", [{"type":"terminal_hacked"},{"type":"apply_terminal_controls"},{"type":"set_state","state":"hacked"}])
		"download":
			var record_id: String = String(target_object.get("stored_key_id", target_object.get("access_key_id", target_object.get("download_record_id", "")))).strip_edges()
			if record_id.is_empty():
				for field_name in ["stored_key_ids", "stored_access_ids", "stored_item_ids", "digital_key_ids", "access_code_ids"]:
					var stored_ids_value: Variant = target_object.get(field_name, [])
					if stored_ids_value is Array and not Array(stored_ids_value).is_empty():
						record_id = String(Array(stored_ids_value)[0]).strip_edges()
						break
			var record_name: String = String(target_object.get("download_display_name", record_id)).strip_edges()
			return _result(true, "Downloaded %s." % record_name, [{"type":"store_digital_record","record_id":record_id,"display_name":record_name,"description":"Downloaded from %s" % String(target_object.get("display_name", target_object.get("id", "device")))}])
		"push", "pull":
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
			return _result(true, "Object moved.", [{"type":"object_move","mode":action_type,"direction":direction,"dx":direction.x,"dy":direction.y}])
		"insert_fuse":
			if not String(target_object.get("object_type", "")).begins_with("fuse_box") and String(target_object.get("object_type", "")) != "fuse_block":
				return _result(false, "Cannot insert fuse here.")
			if bool(target_object.get("fuse_installed", false)) or String(target_object.get("state", "")) == "installed":
				return _result(false, "Fuse already installed.")
			if module_id != "fuse":
				return _result(false, "Manipulator does not contain a fuse.")
			target_object["state"] = "installed"
			target_object["fuse_installed"] = true
			return _result(true, "Fuse installed.", [{"type":"set_state","state":"installed"},{"type":"set_bool","field":"fuse_installed","value":true},{"type":"power_recalc_needed"}])
		"remove_fuse":
			if not String(target_object.get("object_type", "")).begins_with("fuse_box") and String(target_object.get("object_type", "")) != "fuse_block":
				return _result(false, "Cannot remove fuse here.")
			if not bool(target_object.get("fuse_installed", String(target_object.get("state", "")) == "installed")):
				return _result(false, "No fuse installed.")
			target_object["state"] = "empty"
			target_object["fuse_installed"] = false
			return _result(true, "Fuse removed.", [{"type":"set_state","state":"empty"},{"type":"set_bool","field":"fuse_installed","value":false},{"type":"grant_item","item_type":"fuse"},{"type":"power_recalc_needed"}])
		"repair":
			if module_id != "repair_v1" and module_id != "repair_kit":
				return _result(false, "Repair module or repair kit not found.")
			if String(target_object.get("state", "")) != "damaged":
				return _result(false, "Object is not damaged.")
			target_object["state"] = "active"
			var effects: Array = [{"type":"set_state","state":"ok" if String(target_object.get("object_type", "")) == "power_cable" else "active"},{"type":"set_bool","field":"damaged","value":false},{"type":"set_bool","field":"broken","value":false}]
			var object_group: String = String(target_object.get("object_group", ""))
			if target_object.has("power_network_id") or object_group in ["power", "terminal"]:
				effects.append({"type":"power_recalc_needed"})
			return _result(true, "Object repaired.", effects)
		"switch":
			var state: String = String(target_object.get("state", "switch_off"))
			var next_state: String = "switch_on" if state in ["switch_off", "off", "open"] else "switch_off"
			target_object["state"] = next_state
			target_object["is_on"] = next_state == "switch_on"
			return _result(true, "Switch toggled.", [{"type":"set_state","state":next_state},{"type":"set_bool","field":"is_on","value":next_state == "switch_on"},{"type":"power_recalc_needed"}])
		"circuit_1", "circuit_2", "circuit_3":
			if String(target_object.get("object_type", "")) != "circuit_switch":
				return _result(false, "Circuit output unavailable.")
			var output_index: int = int(action_type.replace("circuit_", ""))
			if String(target_object.get("output_%d_wire_id" % output_index, target_object.get("output_%d_direction" % output_index, "none"))).strip_edges().to_lower() in ["", "none"]:
				return _result(false, "Circuit output unavailable.")
			target_object["active_output_index"] = output_index
			return _result(true, "Circuit %d selected." % output_index, [{"type":"set_int","field":"active_output_index","value":output_index},{"type":"power_recalc_needed"}])
		"plug_in":
			target_object["plugged"] = true
			return _result(true, "Wire connected.", [{"type":"set_bool","field":"plugged","value":true},{"type":"power_recalc_needed"}])
		"plug_out":
			target_object["plugged"] = false
			target_object.erase("plugged_cable_end")
			return _result(true, "Wire disconnected.", [{"type":"set_bool","field":"plugged","value":false},{"type":"power_recalc_needed"}])
		"take_end_1", "take_end_2":
			var end_index: String = "1" if action_type == "take_end_1" else "2"
			return _result(true, "Cable end %s taken." % end_index, [{"type":"take_cable_end","end_index":int(end_index)}])
		"connect_wire_end":
			target_object["cable_power_connected"] = true
			return _result(true, "Wire connected.", [{"type":"set_bool","field":"cable_power_connected","value":true},{"type":"power_recalc_needed"}])
		"disconnect_power_wire":
			target_object["cable_power_connected"] = false
			return _result(true, "Power wire disconnected.", [{"type":"set_bool","field":"cable_power_connected","value":false},{"type":"power_recalc_needed"}])

		"activate_platform", "switch_platform":
			if group == "platform":
				if String(target_object.get("state", "active")) in ["unpowered", "disabled", "damaged"] or not bool(target_object.get("is_powered", true)):
					return _result(false, "Platform is unpowered.")
				if String(target_object.get("control_type", "internal")) == "internal":
					if int(actor.get("manipulator_level", 0)) < 1:
						return _result(false, "Manipulator required.")
					if not bool(actor.get("platform_switch_access", false)):
						return _result(false, "Platform switch is not accessible.")
				return _result(true, "Platform activated.", [{"type":"activate_platform"}])
			if group == "terminal" and String(target_object.get("terminal_type", "")) == "platform":
				if String(target_object.get("state", "active")) in ["unpowered", "disabled", "damaged"] or not bool(target_object.get("platform_remote_control", true)):
					return _result(false, "Platform terminal is unavailable.")
				var required_interface: int = maxi(1, int(target_object.get("required_connector_level", 1)))
				var connection_type := String(target_object.get("connection_type", "wired"))
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

static func _validate_door_class(actor: Dictionary, target_object: Dictionary) -> Dictionary:
	var control_mode := String(target_object.get("control_mode", "internal")).strip_edges().to_lower()
	if control_mode in ["external", "external_control", "external control"]:
		return _result(false, "Door is controlled by linked terminal.")
	var power_mode := String(target_object.get("power_mode", "internal")).strip_edges().to_lower()
	if power_mode in ["external", "external_power", "external power"] and not bool(target_object.get("is_powered", true)):
		return _result(false, "Door is unpowered.")
	if int(actor.get("manipulator_level", 0)) < int(target_object.get("required_manipulator_level", 1)):
		return _result(false, "Manipulator level too low.")
	if target_object.get("material", "") == "electromagnetic" and int(actor.get("connector_level", 0)) < int(target_object.get("required_connector_level", 0)):
		return _result(false, "Connector level too low.")
	return _result(true, "OK")

static func _validate_weight_class(actor: Dictionary, target_object: Dictionary) -> Dictionary:
	var weight_class: String = String(target_object.get("weight_class", "normal"))
	var actor_power: String = String(actor.get("power_class", "scout"))
	if weight_class == "heavy" and actor_power == "scout":
		return _result(false, "Object is too heavy.")
	if weight_class == "block" and actor_power != "juggernaut":
		return _result(false, "Object is too heavy.")
	return _result(true, "OK")

static func _result(success: bool, message: String, effects: Array = []) -> Dictionary:
	return {"success": success, "message": message, "effects": effects}
