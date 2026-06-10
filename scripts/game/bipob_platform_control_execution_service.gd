extends RefCounted
class_name BipobPlatformControlExecutionService

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const InteractionActionCostServiceRef = preload("res://scripts/game/interaction/interaction_action_cost_service.gd")
const PlatformMechanismServiceRef = preload("res://scripts/game/platform/platform_mechanism_service.gd")
const PlatformMechanismRulesServiceRef = preload("res://scripts/game/platform/platform_mechanism_rules_service.gd")
const PlatformMotionServiceRef = preload("res://scripts/game/platform/platform_motion_service.gd")
const PlatformRotationServiceRef = preload("res://scripts/game/platform/platform_rotation_service.gd")
const PlatformTypesRef = preload("res://scripts/game/platform/platform_types.gd")
static func _is_platform_self_controlled(platform_object: Dictionary) -> bool:
	var control_mode: String = str(platform_object.get("control_mode", platform_object.get("control_type", "internal"))).strip_edges().to_lower()

	if control_mode.is_empty():
		return true

	return control_mode in ["internal", "self", "cell", "local", "direct"]


static func _is_platform_external_controlled(platform_object: Dictionary) -> bool:
	var control_mode: String = str(platform_object.get("control_mode", platform_object.get("control_type", "internal"))).strip_edges().to_lower()

	if control_mode in ["external", "external_control", "terminal", "remote", "device"]:
		return true

	if bool(platform_object.get("requires_external_control", false)):
		return true

	if not str(platform_object.get("linked_terminal_id", "")).strip_edges().is_empty():
		return true

	if not str(platform_object.get("control_source_id", "")).strip_edges().is_empty():
		return true

	return false


static func _is_platform_powered(platform_object: Dictionary) -> bool:
	var state_text: String = str(platform_object.get("state", "")).strip_edges().to_lower()
	if state_text == "unpowered":
		return false

	var power_mode: String = str(platform_object.get("power_mode", platform_object.get("power_type", "internal"))).strip_edges().to_lower()

	if power_mode in ["internal", "internal_power", "self", "self_powered", ""]:
		return true

	if power_mode in ["external", "external_power", "external power"]:
		if platform_object.has("is_powered"):
			return bool(platform_object.get("is_powered", false))

		var power_state: String = str(platform_object.get("power_state", "")).strip_edges().to_lower()
		return power_state in ["powered", "active", "on", "ok"]

	if platform_object.has("is_powered"):
		return bool(platform_object.get("is_powered", true))

	return true


static func _get_runtime_block_message(platform_object: Dictionary) -> String:
	var state_text: String = str(platform_object.get("state", "")).strip_edges().to_lower()

	if state_text in ["disabled", "damaged", "broken", "destroyed"]:
		return "Platform mechanism is disabled."

	if _is_platform_external_controlled(platform_object):
		return "Platform is controlled externally."

	if not _is_platform_self_controlled(platform_object):
		return "Platform cannot be controlled locally."

	if not _is_platform_powered(platform_object):
		return "Platform mechanism has no power."

	return ""
	
static func execute_platform_control_action(controller: Variant, platform_object: Dictionary, target_position: Vector2i, action_id: String) -> Dictionary:
	if controller == null:
		return _build_result(false, "Platform control unavailable.", platform_object, target_position, "missing_controller")

	if controller.mission_manager == null:
		return _build_result(false, "Platform control unavailable.", platform_object, target_position, "missing_mission_manager")

	var normalized_platform: Dictionary = WorldObjectCatalogRef.normalize_world_object_contract(platform_object)
	if normalized_platform.is_empty():
		return _build_result(false, "Platform control unavailable.", platform_object, target_position, "not_platform")

	if str(normalized_platform.get("object_group", "")).strip_edges().to_lower() != "platform":
		return _build_result(false, "Platform control unavailable.", platform_object, target_position, "not_platform")

	var actor_standing_on_platform: bool = _is_actor_standing_on_platform_target(controller, normalized_platform, target_position)
	if not actor_standing_on_platform:
		return _build_result(false, "Stand on platform to control it.", normalized_platform, target_position, "not_on_platform")

	var runtime_block_message: String = _get_runtime_block_message(normalized_platform)
	if not runtime_block_message.is_empty():
		return _build_result(false, runtime_block_message, normalized_platform, target_position, "platform_unavailable")

	var mechanism: Dictionary = _build_platform_mechanism(controller, normalized_platform)
	if mechanism.is_empty():
		return _build_result(false, "Platform mechanism unavailable.", normalized_platform, target_position, "missing_mechanism")

	var requested_action: String = _resolve_requested_action(normalized_platform, mechanism, action_id)
	if requested_action.is_empty():
		return _build_result(false, "No platform operation configured.", normalized_platform, target_position, "missing_operation")

	if not InteractionActionCostServiceRef.can_commit_gameplay_action(controller):
		return _build_result(false, "Not enough action/energy.", normalized_platform, target_position, "insufficient_resources")

	var members: Array[Dictionary] = _collect_mechanism_members(controller, mechanism, normalized_platform)
	if members.is_empty():
		members = [normalized_platform.duplicate(true)]

	if requested_action in [PlatformTypesRef.ACTION_RAISE, PlatformTypesRef.ACTION_LOWER]:
		return _execute_elevator_action(controller, normalized_platform, target_position, mechanism, members, requested_action)

	if requested_action in [PlatformTypesRef.ACTION_ROTATE_LEFT, PlatformTypesRef.ACTION_ROTATE_RIGHT]:
		return _execute_rotation_action(controller, normalized_platform, target_position, mechanism, members, requested_action)

	return _build_result(false, "No platform operation configured.", normalized_platform, target_position, "operation_unavailable")
	
static func _is_actor_standing_on_platform_target(controller: Variant, platform_object: Dictionary, target_position: Vector2i) -> bool:
	if controller == null:
		return false

	if platform_object.is_empty():
		return false

	var object_group: String = str(platform_object.get("object_group", platform_object.get("group", ""))).strip_edges().to_lower()
	var object_type: String = str(platform_object.get("object_type", platform_object.get("type", ""))).strip_edges().to_lower()
	var platform_mode: String = str(platform_object.get("platform_mode", "")).strip_edges().to_lower()
	var platform_type: String = str(platform_object.get("platform_type", "")).strip_edges().to_lower()

	var is_platform: bool = false
	if object_group == "platform":
		is_platform = true
	if object_type == "platform":
		is_platform = true
	if object_type in ["lifting_platform", "rotating_platform"]:
		is_platform = true
	if not platform_mode.is_empty():
		is_platform = true
	if platform_type in ["lifting", "rotating", "elevator", "rotator"]:
		is_platform = true

	if not is_platform:
		return false

	var actor_cell: Vector2i = Vector2i(controller.grid_position)

	if actor_cell == target_position:
		return true

	for cell_variant in Array(platform_object.get("platform_cells", [])):
		var platform_cell: Vector2i = WorldObjectCatalogRef.to_world_cell(cell_variant, Vector2i(-1, -1))
		if platform_cell == actor_cell:
			return true

	for cell_variant in Array(platform_object.get("cells", [])):
		var cell: Vector2i = WorldObjectCatalogRef.to_world_cell(cell_variant, Vector2i(-1, -1))
		if cell == actor_cell:
			return true

	var position_cell: Vector2i = WorldObjectCatalogRef.to_world_cell(
		platform_object.get("position", platform_object.get("pos", platform_object.get("cell", Vector2i(-1, -1)))),
		Vector2i(-1, -1)
	)
	if position_cell == actor_cell:
		return true

	var x_value: int = int(platform_object.get("x", platform_object.get("cell_x", -1)))
	var y_value: int = int(platform_object.get("y", platform_object.get("cell_y", -1)))
	if x_value >= 0 and y_value >= 0:
		if Vector2i(x_value, y_value) == actor_cell:
			return true

	return false
	
static func _execute_elevator_action(controller: Variant, platform_object: Dictionary, target_position: Vector2i, mechanism: Dictionary, members: Array[Dictionary], action: String) -> Dictionary:
	var current_level: int = int(platform_object.get("platform_level", platform_object.get("current_level", platform_object.get("height_level", 0))))
	var max_level: int = maxi(int(platform_object.get("max_level", platform_object.get("max_height_level", 1))), 0)
	var target_level: int = current_level
	if action == PlatformTypesRef.ACTION_RAISE:
		target_level = mini(current_level + 1, max_level)
	elif action == PlatformTypesRef.ACTION_LOWER:
		target_level = maxi(current_level - 1, 0)
	if target_level == current_level:
		return _build_result(false, "Platform is already at the requested level.", platform_object, target_position, "already_at_target_level")
	var motion_plan: Dictionary = PlatformMotionServiceRef.build_elevator_motion_plan(members, [], action, current_level, max_level)
	var updated_count: int = _apply_platform_level_updates(controller, mechanism, members, target_level, current_level, action)
	if updated_count <= 0:
		return _build_result(false, "Platform update failed.", platform_object, target_position, "update_failed")
	if controller.has_method("set_platform_height_level"):
		var platform_ids: Array = Array(mechanism.get("platform_ids", []))
		var platform_id: String = str(platform_ids[0]) if not platform_ids.is_empty() else str(platform_object.get("platform_id", platform_object.get("id", "")))
		controller.call("set_platform_height_level", target_level, platform_id)
	return _build_success_result(platform_object, target_position, action, "Platform %s." % PlatformTypesRef.action_label(action), mechanism, {
		"height_level": target_level,
		"current_level": target_level,
		"motion_state": PlatformTypesRef.MOTION_RAISING if target_level > current_level else PlatformTypesRef.MOTION_LOWERING,
		"motion_progress": 0.0,
		"motion_plan": motion_plan
	})


static func _execute_rotation_action(controller: Variant, platform_object: Dictionary, target_position: Vector2i, mechanism: Dictionary, members: Array[Dictionary], action: String) -> Dictionary:
	var platform_cells: Array[Vector2i] = PlatformMechanismServiceRef.get_member_cells(members)
	var carried_entries: Array[Dictionary] = []
	if controller.has_method("get_grid_position"):
		var actor_cell: Vector2i = Vector2i(controller.grid_position)
		if platform_cells.has(actor_cell):
			carried_entries.append({"id": "active_bipob", "cell": actor_cell, "direction": str(controller.get_direction() if controller.has_method("get_direction") else "NORTH")})
	var rotation_plan: Dictionary = PlatformRotationServiceRef.build_rotation_plan(members, carried_entries, action, [])
	if not bool(rotation_plan.get("ok", false)):
		return _build_result(false, str(Array(rotation_plan.get("errors", ["Platform rotation failed."]))[0]), platform_object, target_position, "rotation_invalid")
	var updated_count: int = _apply_platform_rotation_updates(controller, mechanism, members, action, rotation_plan)
	if updated_count <= 0:
		return _build_result(false, "Platform update failed.", platform_object, target_position, "update_failed")
	var carried_plan: Array[Dictionary] = Array(rotation_plan.get("carried_plan", []))
	if not carried_plan.is_empty() and controller.has_method("set_direction"):
		var carried_entry: Dictionary = Dictionary(carried_plan[0])
		var target_cell: Vector2i = Vector2i(carried_entry.get("target_cell", controller.grid_position))
		controller.grid_position = target_cell
		controller.call("set_direction", str(carried_entry.get("target_direction", controller.get_direction() if controller.has_method("get_direction") else "NORTH")))
		if controller.has_method("update_world_position"):
			controller.call("update_world_position")
	var rotation_label: String = "Platform rotated."
	return _build_success_result(platform_object, target_position, action, rotation_label, mechanism, {
		"motion_state": PlatformTypesRef.MOTION_ROTATING_LEFT if action == PlatformTypesRef.ACTION_ROTATE_LEFT else PlatformTypesRef.MOTION_ROTATING_RIGHT,
		"motion_progress": 0.0,
		"rotation_plan": rotation_plan
	})


static func _resolve_requested_action(platform_object: Dictionary, mechanism: Dictionary, action_id: String) -> String:
	var normalized_action_id: String = str(action_id).strip_edges().to_lower()
	match normalized_action_id:
		"raise_platform", "raise":
			return PlatformTypesRef.ACTION_RAISE
		"lower_platform", "lower":
			return PlatformTypesRef.ACTION_LOWER
		"rotate_platform_left", "rotate_left":
			return PlatformTypesRef.ACTION_ROTATE_LEFT
		"rotate_platform_right", "rotate_right":
			return PlatformTypesRef.ACTION_ROTATE_RIGHT
		"toggle", "activate_platform", "":
			var configured_action: String = str(mechanism.get("operation", platform_object.get("platform_action", platform_object.get("operation", "toggle")))).strip_edges().to_lower()
			if configured_action in [PlatformTypesRef.ACTION_RAISE, PlatformTypesRef.ACTION_LOWER, PlatformTypesRef.ACTION_ROTATE_LEFT, PlatformTypesRef.ACTION_ROTATE_RIGHT]:
				return configured_action
			if configured_action == "toggle":
				var current_level: int = int(platform_object.get("platform_level", platform_object.get("current_level", platform_object.get("height_level", 0))))
				var max_level: int = maxi(int(platform_object.get("max_level", platform_object.get("max_height_level", 1))), 0)
				return PlatformTypesRef.ACTION_RAISE if current_level <= 0 else PlatformTypesRef.ACTION_LOWER if current_level >= max_level else PlatformTypesRef.ACTION_RAISE
			if PlatformTypesRef.platform_mode_supports_rotator(str(platform_object.get("platform_mode", platform_object.get("platform_type", "")))):
				return PlatformTypesRef.ACTION_ROTATE_RIGHT
			return PlatformTypesRef.ACTION_RAISE
	return ""


static func _build_platform_mechanism(controller: Variant, platform_object: Dictionary) -> Dictionary:
	var platform_ids: Array[String] = []
	var mechanism_id: String = str(platform_object.get("mechanism_id", platform_object.get("platform_mechanism_id", ""))).strip_edges()
	if not mechanism_id.is_empty() and controller.mission_manager != null and controller.mission_manager.has_method("get_platform_mechanism_summary"):
		var summary_variant: Variant = controller.mission_manager.call("get_platform_mechanism_summary", mechanism_id)
		if summary_variant is Dictionary:
			platform_ids = Array(Dictionary(summary_variant).get("platform_ids", []))
	if platform_ids.is_empty():
		var platform_id: String = str(platform_object.get("platform_id", platform_object.get("id", ""))).strip_edges()
		if not platform_id.is_empty():
			platform_ids.append(platform_id)
	return PlatformMechanismRulesServiceRef.build_mechanism_from_platform(platform_object, platform_ids)


static func _collect_mechanism_members(controller: Variant, mechanism: Dictionary, platform_object: Dictionary) -> Array[Dictionary]:
	var members: Array[Dictionary] = []

	if controller == null or controller.mission_manager == null:
		members.append(platform_object.duplicate(true))
		return members

	var current_platform_id: String = str(platform_object.get("platform_id", platform_object.get("id", ""))).strip_edges()
	var mechanism_id: String = str(platform_object.get("mechanism_id", platform_object.get("platform_mechanism_id", mechanism.get("mechanism_id", mechanism.get("platform_mechanism_id", ""))))).strip_edges()

	# Single platform: no mechanism_id means this platform is its own independent mechanism.
	if mechanism_id.is_empty():
		members.append(platform_object.duplicate(true))
		return members

	# Mechanism platform: collect all platforms with the same mechanism_id.
	if controller.mission_manager.has_method("get_platform_by_id"):
		for platform_id_variant in Array(mechanism.get("platform_ids", [])):
			var platform_id: String = str(platform_id_variant).strip_edges()
			if platform_id.is_empty():
				continue

			var member: Dictionary = Dictionary(controller.mission_manager.call("get_platform_by_id", platform_id))
			if member.is_empty() and platform_id == current_platform_id:
				member = platform_object.duplicate(true)

			if not member.is_empty() and _is_platform_member_data(member):
				_append_unique_platform_member(members, member)

	if controller.mission_manager.has_method("get_map_constructor_placed_object_rows"):
		var rows: Array = Array(controller.mission_manager.call("get_map_constructor_placed_object_rows"))
		for row_variant in rows:
			if typeof(row_variant) != TYPE_DICTIONARY:
				continue

			var row: Dictionary = Dictionary(row_variant)
			var object_id: String = str(row.get("id", "")).strip_edges()
			if object_id.is_empty():
				continue

			var candidate: Dictionary = row.duplicate(true)

			if controller.mission_manager.has_method("get_map_constructor_entity_by_id"):
				var entity: Dictionary = Dictionary(controller.mission_manager.call("get_map_constructor_entity_by_id", "world_object", object_id))
				if bool(entity.get("ok", false)):
					candidate = Dictionary(entity.get("data", {}))
					candidate["id"] = object_id

			if not _is_platform_member_data(candidate):
				continue

			var candidate_mechanism_id: String = str(candidate.get("mechanism_id", candidate.get("platform_mechanism_id", ""))).strip_edges()
			if candidate_mechanism_id == mechanism_id:
				_append_unique_platform_member(members, candidate)

	elif "mission_world_objects" in controller.mission_manager:
		for object_variant in Array(controller.mission_manager.mission_world_objects):
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue

			var candidate_object: Dictionary = Dictionary(object_variant)
			if not _is_platform_member_data(candidate_object):
				continue

			var candidate_mechanism_id_direct: String = str(candidate_object.get("mechanism_id", candidate_object.get("platform_mechanism_id", ""))).strip_edges()
			if candidate_mechanism_id_direct == mechanism_id:
				_append_unique_platform_member(members, candidate_object)

	if members.is_empty():
		members.append(platform_object.duplicate(true))

	return members

static func _is_platform_member_data(data: Dictionary) -> bool:
	if data.is_empty():
		return false

	var object_group: String = str(data.get("object_group", data.get("group", ""))).strip_edges().to_lower()
	var object_type: String = str(data.get("object_type", data.get("type", ""))).strip_edges().to_lower()
	var archetype_id: String = str(data.get("archetype_id", data.get("map_constructor_prefab_id", ""))).strip_edges().to_lower()
	var platform_mode: String = str(data.get("platform_mode", "")).strip_edges().to_lower()
	var platform_type: String = str(data.get("platform_type", "")).strip_edges().to_lower()

	if object_group == "platform":
		return true
	if object_type == "platform":
		return true
	if object_type in ["lifting_platform", "rotating_platform"]:
		return true
	if archetype_id == "platform":
		return true
	if not platform_mode.is_empty():
		return true
	if platform_type in ["lifting", "rotating", "elevator", "rotator"]:
		return true

	return false
static func _append_unique_platform_member(members: Array[Dictionary], member: Dictionary) -> void:
	if member.is_empty():
		return

	var member_id: String = str(member.get("id", member.get("platform_id", ""))).strip_edges()
	var member_platform_id: String = str(member.get("platform_id", member.get("id", ""))).strip_edges()

	for existing in members:
		var existing_id: String = str(existing.get("id", existing.get("platform_id", ""))).strip_edges()
		var existing_platform_id: String = str(existing.get("platform_id", existing.get("id", ""))).strip_edges()

		if not member_id.is_empty() and member_id == existing_id:
			return
		if not member_platform_id.is_empty() and member_platform_id == existing_platform_id:
			return

	members.append(member.duplicate(true))
	
static func _is_external_power_available(platform_object: Dictionary) -> bool:
	var state_text: String = str(platform_object.get("state", "")).strip_edges().to_lower()
	if state_text in ["unpowered", "disabled", "damaged", "broken", "destroyed"]:
		return false
	var power_mode: String = str(platform_object.get("power_mode", platform_object.get("power_type", PlatformMechanismRulesServiceRef.POWER_MODE_INTERNAL))).strip_edges().to_lower()
	if power_mode == PlatformMechanismRulesServiceRef.POWER_MODE_INTERNAL:
		return true
	if bool(platform_object.get("is_powered", true)):
		return true
	var power_state: String = str(platform_object.get("power_state", "")).strip_edges().to_lower()
	return power_state in ["powered", "active", "on", "ok"]


static func _apply_platform_level_updates(controller: Variant, _mechanism: Dictionary, members: Array[Dictionary], target_level: int, current_level: int, _action: String) -> int:
	var updated_count: int = 0
	for member in members:
		var member_id: String = str(member.get("id", "")).strip_edges()
		if member_id.is_empty():
			continue
		var next_member: Dictionary = member.duplicate(true)
		next_member["platform_level"] = target_level
		next_member["current_level"] = target_level
		if next_member.has("height_level"):
			next_member["height_level"] = target_level
		next_member["motion_state"] = PlatformTypesRef.MOTION_RAISING if target_level > current_level else PlatformTypesRef.MOTION_LOWERING if target_level < current_level else PlatformTypesRef.MOTION_IDLE
		next_member["motion_progress"] = 0.0
		next_member["state"] = PlatformMechanismRulesServiceRef.PLATFORM_STATE_RAISED if target_level > current_level else PlatformMechanismRulesServiceRef.PLATFORM_STATE_LOWERED if target_level < current_level else PlatformMechanismRulesServiceRef.PLATFORM_STATE_IDLE
		controller.mission_manager.update_world_object_by_id(member_id, next_member)
		updated_count += 1
	return updated_count


static func _apply_platform_rotation_updates(controller: Variant, _mechanism: Dictionary, members: Array[Dictionary], action: String, _rotation_plan: Dictionary) -> int:
	var updated_count: int = 0
	var rotation_state: String = PlatformTypesRef.MOTION_ROTATING_LEFT if action == PlatformTypesRef.ACTION_ROTATE_LEFT else PlatformTypesRef.MOTION_ROTATING_RIGHT
	for member in members:
		var member_id: String = str(member.get("id", "")).strip_edges()
		if member_id.is_empty():
			continue
		var next_member: Dictionary = member.duplicate(true)
		next_member["rotation_direction"] = "counterclockwise" if action == PlatformTypesRef.ACTION_ROTATE_LEFT else "clockwise"
		next_member["motion_state"] = rotation_state
		next_member["motion_progress"] = 0.0
		if next_member.has("facing_dir"):
			next_member["facing_dir"] = PlatformTypesRef.rotate_direction(str(next_member.get("facing_dir", "up")), action)
		if next_member.has("direction"):
			next_member["direction"] = PlatformTypesRef.rotate_direction(str(next_member.get("direction", "up")), action)
		controller.mission_manager.update_world_object_by_id(member_id, next_member)
		updated_count += 1
	return updated_count


static func _build_success_result(platform_object: Dictionary, target_position: Vector2i, action: String, message: String, mechanism: Dictionary, extra: Dictionary = {}) -> Dictionary:
	var result: Dictionary = _build_result(true, message, platform_object, target_position, "ok")
	result["message"] = message
	result["action"] = action
	result["platform_id"] = str(platform_object.get("platform_id", platform_object.get("id", "")))
	result["mechanism_id"] = str(mechanism.get("mechanism_id", mechanism.get("platform_mechanism_id", "")))
	result["pending_paid_action"] = true
	result["refresh_overlay"] = true
	result["refresh_threats"] = true
	result["refresh_action_panel"] = true
	result["emit_facing_hint"] = true
	result["emit_status"] = true
	result["clear_selected_action"] = true
	for key_variant in extra.keys():
		result[str(key_variant)] = extra[key_variant]
	return result


static func _build_result(success: bool, message: String, world_object: Dictionary, target_position: Vector2i, reason: String) -> Dictionary:
	return {
		"handled": true,
		"success": success,
		"message": message,
		"spent_action": false,
		"refresh_overlay": false,
		"refresh_threats": false,
		"refresh_action_panel": false,
		"emit_status": true,
		"emit_facing_hint": false,
		"clear_selected_action": false,
		"world_object": world_object,
		"target_position": target_position,
		"pending_paid_action": false,
		"reason": reason
	}
