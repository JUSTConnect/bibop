extends RefCounted
class_name InteractionSystem
const WorldObjectCatalog = preload("res://scripts/world/world_object_catalog.gd")

const SUPPORTED_ACTIONS := ["open","unlock","input_password","cut","impact","force_open","connect","scan","hack","drain_energy","pickup","use_item","insert_fuse","repair","push","pull","switch","disable","enable","attack","stun","repair_ally"]

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
				return _result(true, "Door opened.", [{"type":"door_opened"},{"type":"set_state","state":"open"},{"type":"set_blocks_movement","value":false}])
		"unlock":
			if group != "door":
				return _result(false, "Cannot unlock this object.")
			var door_gate := _validate_door_class(actor, target_object)
			if not door_gate.success:
				return door_gate
			if module_id in ["mechanical_keycard", "digital_key_opened"]:
				target_object["state"] = "closed"
				return _result(true, "Door unlocked.", [{"type":"door_unlocked"},{"type":"set_state","state":"closed"}])
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
				var hits := int(target_object.get("impact_hits", 0)) + 1
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
			if group == "terminal":
				WorldObjectCatalog.update_world_object_heat_state(target_object)
				if String(target_object.get("state", "")) == "overheated":
					return _result(false, "Terminal overheated. Hack failed.", [{"type":"terminal_overheated","heat_breakdown":WorldObjectCatalog.get_world_object_heat_breakdown(target_object, 0)}])
				var hack_heat := maxi(0, int(target_object.get("hack_heat", 1)))
				if WorldObjectCatalog.would_world_object_overheat_with_temporary_heat(target_object, hack_heat):
					return _result(false, "Terminal overheated. Hack failed.", [{"type":"terminal_overheated","heat_breakdown":WorldObjectCatalog.get_world_object_heat_breakdown(target_object, hack_heat)}])
			target_object["state"] = "hacked"
			if group == "threat":
				return _result(true, "Hack successful.", [{"type":"set_state","state":"hacked"},{"type":"set_behavior_state","behavior_state":"idle"}])
			return _result(true, "Hack successful.", [{"type":"terminal_hacked"},{"type":"apply_terminal_controls"},{"type":"set_state","state":"hacked"}])
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
			var facing := Vector2i(actor.get("facing_direction", Vector2i.ZERO))
			var direction := facing
			if action_type == "pull":
				direction = -facing
			return _result(true, "Object moved.", [{"type":"object_move","mode":action_type,"direction":direction,"dx":direction.x,"dy":direction.y}])
		"insert_fuse":
			if module_id != "fuse":
				return _result(false, "Fuse required.")
			target_object["state"] = "installed"
			return _result(true, "Fuse installed.", [{"type":"set_state","state":"installed"},{"type":"power_recalc_needed"}])
		"repair":
			if module_id != "repair_v1":
				return _result(false, "Repair tool required.")
			if String(target_object.get("state", "")) != "damaged":
				return _result(false, "Object is not damaged.")
			target_object["state"] = "active"
			var effects := [{"type":"set_state","state":"active"}]
			var object_group := String(target_object.get("object_group", ""))
			if target_object.has("power_network_id") or object_group in ["power", "terminal"]:
				effects.append({"type":"power_recalc_needed"})
			return _result(true, "Object repaired.", effects)
		"switch":
			var state := String(target_object.get("state", "switch_off"))
			var next_state := "switch_on" if state == "switch_off" else "switch_off"
			target_object["state"] = next_state
			return _result(true, "Switch toggled.", [{"type":"set_state","state":next_state},{"type":"power_recalc_needed"}])

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
				return _result(true, "Platform terminal activated.", [{"type":"activate_platform"}])
		"pickup":
			if group == "item":
				return _result(true, "Item picked up.")
			return _result(false, "Cannot pick up this object.")

		"attack":
			if group != "threat":
				return _result(false, "Cannot attack this object.")
			var attack_damage := 0
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
			var pool := int(target_object.get("drain_energy_pool", 0))
			if pool <= 0:
				return _result(false, "No energy left to drain.")
			var drained := mini(5, pool)
			return _result(true, "Energy drained.", [{"type":"drain_energy","amount":drained}])
		"disable":
			if group != "threat":
				return _result(false, "Cannot disable this object.")
			return _result(true, "Target disabled.", [{"type":"set_state","state":"disabled"},{"type":"set_behavior_state","behavior_state":"idle"}])
		"repair_ally":
			return _result(false, "No ally repair target.")
	return _result(false, "No available action for this object.")

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
