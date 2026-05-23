extends RefCounted
class_name InteractionSystem

const SUPPORTED_ACTIONS := ["open","unlock","input_password","cut","impact","force_open","connect","scan","hack","drain_energy","pickup","use_item","insert_fuse","repair","push","pull","switch","disable","enable"]

static func can_apply_action(actor: Dictionary, module: Dictionary, target_object: Dictionary, action_type: String) -> Dictionary:
	if action_type not in SUPPORTED_ACTIONS:
		return _result(false, "Action not supported.")
	if target_object.is_empty():
		return _result(false, "No target object.")
	if action_type == "pickup" and actor.get("manipulator_occupied", false):
		return _result(false, "Manipulator is occupied.")
	if action_type == "hack" and actor.get("cpu_level", 0) < target_object.get("required_cpu_level", 1):
		return _result(false, "Hacking impossible")
	return _result(true, "Action possible.")

static func apply_action(actor: Dictionary, module: Dictionary, target_object: Dictionary, action_type: String) -> Dictionary:
	var can := can_apply_action(actor, module, target_object, action_type)
	if not can.success:
		return can
	var group := target_object.get("object_group", "")
	var module_id := module.get("id", "")
	match action_type:
		"open":
			if group == "door":
				if target_object.get("state", "") == "locked":
					return _result(false, "Door is locked.")
				var gate := _validate_door_class(actor, target_object)
				if not gate.success:
					return gate
				if target_object.get("state", "") != "closed":
					return _result(false, "Door cannot be opened.")
				target_object["state"] = "open"
				target_object["blocks_movement"] = false
				return _result(true, "Door opened.", [{"type":"door_opened"},{"type":"state_set","state":"open"},{"type":"set_blocks_movement","value":false}])
		"unlock":
			if group != "door":
				return _result(false, "Cannot unlock this object.")
			var door_gate := _validate_door_class(actor, target_object)
			if not door_gate.success:
				return door_gate
			if module_id in ["mechanical_keycard", "digital_key_opened"]:
				target_object["state"] = "closed"
				return _result(true, "Door unlocked.", [{"type":"door_unlocked"},{"type":"state_set","state":"closed"}])
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
				return _result(true, "Cable cut.", [{"type":"power_recalc_needed"},{"type":"state_set","state":"damaged"}])
			if group == "door" and module_id == "plasma_cutter_v1":
				if target_object.get("object_type", "") == "energy_door" and target_object.get("is_powered", true):
					return _result(false, "Plasma cutter has no effect.")
				if target_object.get("material", "") in ["steel", "reinforced_steel"]:
					target_object["state"] = "damaged"
					return _result(true, "Door has been cut and damaged.")
				return _result(false, "Plasma cutter has no effect.")
		"impact":
			if module_id == "sledgehammer_v1" and group == "door":
				var hits := int(target_object.get("impact_hits", 0)) + 1
				target_object["impact_hits"] = hits
				match target_object.get("object_type", ""):
					"grid_door":
						if hits >= 2:
							target_object["state"] = "destroyed"
							target_object["blocks_movement"] = false
							return _result(true, "Grid door destroyed.", [{"type":"state_set","state":"destroyed"},{"type":"set_blocks_movement","value":false}])
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
		"force_open":
			if group == "door" and target_object.get("state", "") in ["damaged", "half_open", "jammed"] and module_id == "manipulator_heavy_claw_v1":
				target_object["state"] = "open"
				target_object["blocks_movement"] = false
				return _result(true, "Door forced open.", [{"type":"state_set","state":"open"},{"type":"set_blocks_movement","value":false}])
			return _result(false, "Door cannot be forced open.")
		"connect":
			if group == "terminal":
				var connection_type := target_object.get("connection_type", "wired")
				var expected = {"wired":"wired_interface","optical":"optical_interface","wireless":"wireless_interface","high_bandwidth":"high_bandwidth_interface"}
				var needed = expected.get(connection_type, "wired_interface")
				if module_id.find(needed) == -1:
					return _result(false, "Item does not fit this device.")
				var interface_field := "%s_interface_level" % connection_type
				if int(actor.get(interface_field, actor.get("interface_level", 0))) < int(target_object.get("required_interface_level", 1)):
					return _result(false, "Interface level too low.")
				target_object["connected"] = true
				return _result(true, "Terminal connected.")
		"hack":
			if int(actor.get("cpu_level", 0)) < int(target_object.get("required_cpu_level", 1)):
				return _result(false, "Hacking impossible")
			if int(target_object.get("terminal_class", 1)) >= 3 and target_object.get("can_attack", false) and not actor.get("firewall_module_v1", false):
				return _result(false, "Firewall required.", ["terminal_attack"])
			target_object["state"] = "hacked"
			return _result(true, "Hack successful.")
		"push", "pull":
			var move_gate := _validate_weight_class(actor, target_object)
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
				var material_tags: Array = target_object.get("material_tags", [])
				if not target_object.get("magnetic", false) and not material_tags.has("metal"):
					return _result(false, "Object is not magnetic.")
			return _result(true, "Object moved.")
		"insert_fuse":
			target_object["state"] = "installed"
			return _result(true, "Fuse installed.", [{"type":"state_set","state":"installed"},{"type":"power_recalc_needed"}])
	return _result(true, "Action executed as foundation stub.")

static func _validate_door_class(actor: Dictionary, target_object: Dictionary) -> Dictionary:
	if int(actor.get("manipulator_level", 0)) < int(target_object.get("required_manipulator_level", 1)):
		return _result(false, "Manipulator level too low.")
	if target_object.get("material", "") == "electromagnetic" and int(actor.get("interface_level", 0)) < int(target_object.get("required_interface_level", 0)):
		return _result(false, "Interface level too low.")
	return _result(true, "OK")

static func _validate_weight_class(actor: Dictionary, target_object: Dictionary) -> Dictionary:
	var weight_class := target_object.get("weight_class", "normal")
	var actor_power := actor.get("power_class", "scout")
	if weight_class == "heavy" and actor_power == "scout":
		return _result(false, "Object is too heavy.")
	if weight_class == "block" and actor_power != "juggernaut":
		return _result(false, "Object is too heavy.")
	return _result(true, "OK")

static func _result(success: bool, message: String, effects: Array = []) -> Dictionary:
	return {"success": success, "message": message, "effects": effects}
