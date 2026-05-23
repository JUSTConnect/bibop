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
			if group == "door" and target_object.get("state", "") in ["closed", "unpowered"]:
				target_object["state"] = "open"
				target_object["blocks_movement"] = false
				return _result(true, "Door opened.", ["door_opened"])
		"unlock":
			if module_id == "mechanical_keycard" or module_id == "digital_key_opened":
				target_object["state"] = "closed"
				return _result(true, "Door unlocked.", ["door_unlocked"])
			if module_id == "digital_key_encrypted":
				return _result(false, "File rejected: encrypted.")
			if module_id == "digital_key_damaged":
				return _result(false, "File rejected: damaged.")
		"input_password":
			target_object["state"] = "closed"
			return _result(true, "Password accepted.")
		"cut":
			if target_object.get("object_type", "") == "power_cable":
				target_object["state"] = "damaged"
				target_object["is_powered"] = false
				return _result(true, "Cable cut.", ["power_recalc_needed"])
			if group == "door" and target_object.get("material", "") in ["steel", "reinforced_steel"] and module_id == "plasma_cutter_v1":
				target_object["state"] = "damaged"
				return _result(true, "Door has been cut and damaged.")
		"impact":
			if module_id == "sledgehammer_v1":
				target_object["durability_current"] = maxi(0, int(target_object.get("durability_current", 0)) - 2)
				if target_object["durability_current"] == 0:
					target_object["state"] = "damaged"
				return _result(true, "Impact applied.")
		"force_open":
			if group == "door" and target_object.get("state", "") in ["damaged", "half_open", "jammed"] and module_id == "manipulator_heavy_claw_v1":
				target_object["state"] = "open"
				target_object["blocks_movement"] = false
				return _result(true, "Door forced open.")
		"connect":
			if group == "terminal":
				var expected = {"wired":"wired_interface","optical":"optical_interface_v1","wireless":"wireless_interface_v1","high_bandwidth":"high_bandwidth_interface_v1"}
				var needed = expected.get(target_object.get("connection_type", "wired"), "wired_interface")
				if module_id.find(needed) == -1:
					return _result(false, "Item does not fit this device.")
				target_object["connected"] = true
				return _result(true, "Terminal connected.")
		"hack":
			target_object["state"] = "hacked"
			return _result(true, "Hack successful.")
		"drain_energy":
			if target_object.get("drained_this_turn", false):
				return _result(false, "Already drained this turn.")
			target_object["drained_this_turn"] = true
			return _result(true, "+5 energy drained.", ["energy:+5"])
		"pickup":
			if actor.get("pocket_full", false):
				return _result(false, "Pocket is full.")
			return _result(true, "Item picked up.")
		"use_item":
			if module_id == "mechanical_keycard" and actor.get("manipulator_occupied", false):
				return _result(false, "Free manipulator to use key.")
		"insert_fuse":
			target_object["state"] = "installed"
			return _result(true, "Fuse installed.")
		"repair":
			target_object["state"] = "active"
			target_object["durability_current"] = target_object.get("durability_max", 1)
			return _result(true, "Object repaired.")
		"push", "pull":
			if target_object.get("weight_class", "normal") == "block" and actor.get("power_class", "scout") != "juggernaut":
				return _result(false, "Object is too heavy.")
			if module_id == "magnetic_manipulator_v1":
				if actor.get("magnetic_path_blocked", false):
					return _result(false, "Magnetic path blocked.")
				if actor.get("target_is_grate", false):
					return _result(false, "Cannot pull through grate.")
			return _result(true, "Object moved.")
	return _result(true, "Action executed as foundation stub.")

static func _result(success: bool, message: String, effects: Array = []) -> Dictionary:
	return {"success": success, "message": message, "effects": effects}
