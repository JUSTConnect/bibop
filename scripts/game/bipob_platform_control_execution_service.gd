extends RefCounted
class_name BipobPlatformControlExecutionService

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const InteractionActionCostServiceRef = preload("res://scripts/game/interaction/interaction_action_cost_service.gd")
const PlatformMechanismServiceRef = preload("res://scripts/game/platform/platform_mechanism_service.gd")
const PlatformMechanismRulesServiceRef = preload("res://scripts/game/platform/platform_mechanism_rules_service.gd")
const PlatformMotionServiceRef = preload("res://scripts/game/platform/platform_motion_service.gd")
const PlatformRotationServiceRef = preload("res://scripts/game/platform/platform_rotation_service.gd")
const PlatformTypesRef = preload("res://scripts/game/platform/platform_types.gd")
static func _normalize_platform_rule_token(value: Variant) -> String:
	var normalized: String = str(value).strip_edges().to_lower()
	normalized = normalized.replace(" ", "_")
	normalized = normalized.replace("-", "_")

	match normalized:
		"internal_control", "internal_power", "self_powered", "self_controlled":
			return "internal"
		"external_control", "external_power", "remote_control", "terminal_control":
			return "external"
		"no_power", "none_power", "not_required":
			return "none"

	return normalized


static func _get_platform_control_mode(platform_object: Dictionary) -> String:
	var control_value: String = str(platform_object.get("control_type", "")).strip_edges().to_lower()
	control_value = control_value.replace(" ", "_").replace("-", "_")

	if control_value.is_empty():
		control_value = str(platform_object.get("control_mode", "internal")).strip_edges().to_lower()
		control_value = control_value.replace(" ", "_").replace("-", "_")

	match control_value:
		"internal_control", "internal_power", "self_powered", "self_controlled":
			return "internal"
		"external_control", "remote_control", "terminal_control":
			return "external"

	return control_value


static func _get_platform_power_mode(platform_object: Dictionary) -> String:
	if platform_object.has("power_type"):
		return _normalize_platform_rule_token(platform_object.get("power_type", "none"))

	if platform_object.has("power_mode"):
		return _normalize_platform_rule_token(platform_object.get("power_mode", "none"))

	return "none"


static func _is_platform_self_controlled(platform_object: Dictionary) -> bool:
	var control_mode: String = _get_platform_control_mode(platform_object)

	if control_mode.is_empty():
		return true

	return control_mode in ["internal", "self", "cell", "local", "direct"]


static func _is_platform_external_controlled(platform_object: Dictionary) -> bool:
	var control_mode: String = _get_platform_control_mode(platform_object)

	if control_mode in ["external", "terminal", "remote", "device"]:
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

	if state_text in ["disabled", "damaged", "broken", "destroyed"]:
		return false

	var power_value: String = str(platform_object.get("power_type", platform_object.get("power_mode", "none"))).strip_edges().to_lower()
	power_value = power_value.replace(" ", "_").replace("-", "_")

	match power_value:
		"internal_power", "self_powered":
			power_value = "internal"
		"external_power":
			power_value = "external"
		"no_power", "none_power", "":
			power_value = "none"

	if power_value in ["none", "no", "not_required"]:
		return true

	if power_value in ["internal", "self", "battery"]:
		return bool(platform_object.get("is_powered", true))

	if power_value in ["external", "network", "power_source"]:
		if platform_object.has("is_powered"):
			return bool(platform_object.get("is_powered", false))

		var power_state: String = str(platform_object.get("power_state", "")).strip_edges().to_lower()
		return power_state in ["powered", "active", "on", "ok"]

	if state_text == "unpowered":
		return false

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
static func _carry_actor_with_elevator_if_needed(controller: Variant, platform_object: Dictionary, members: Array[Dictionary], target_level: int) -> void:
	if controller == null:
		return

	if not ("grid_position" in controller):
		return

	var actor_cell: Vector2i = Vector2i(controller.grid_position)
	var carrying_platform_id: String = ""

	for member in members:
		var member_cell: Vector2i = WorldObjectCatalogRef.to_world_cell(
			member.get("position", member.get("cell", member.get("pos", Vector2i(-1, -1)))),
			Vector2i(-1, -1)
		)

		var platform_cells: Array = Array(member.get("platform_cells", []))
		var actor_on_member: bool = member_cell == actor_cell

		for cell_variant in platform_cells:
			var platform_cell: Vector2i = WorldObjectCatalogRef.to_world_cell(cell_variant, Vector2i(-1, -1))
			if platform_cell == actor_cell:
				actor_on_member = true
				break

		if actor_on_member:
			carrying_platform_id = str(member.get("platform_id", member.get("id", ""))).strip_edges()
			break

	if carrying_platform_id.is_empty():
		var fallback_cell: Vector2i = WorldObjectCatalogRef.to_world_cell(
			platform_object.get("position", platform_object.get("cell", platform_object.get("pos", Vector2i(-1, -1)))),
			Vector2i(-1, -1)
		)

		if fallback_cell == actor_cell:
			carrying_platform_id = str(platform_object.get("platform_id", platform_object.get("id", ""))).strip_edges()

	if carrying_platform_id.is_empty():
		return

	if controller.has_method("set_platform_height_level"):
		controller.call("set_platform_height_level", target_level, carrying_platform_id)

	if controller.has_method("update_world_position"):
		controller.call("update_world_position")

	if "status_changed" in controller:
		controller.status_changed.emit()
			
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

	# Important:
	# If Bipob stands on one of the moving platform members,
	# his runtime height follows the platform height.
	_carry_actor_with_elevator_if_needed(controller, platform_object, members, target_level)

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
static func _get_platform_id(platform_data: Dictionary) -> String:
	return str(platform_data.get("platform_id", platform_data.get("id", platform_data.get("object_id", "")))).strip_edges()


static func _get_platform_mechanism_id(platform_data: Dictionary) -> String:
	return str(platform_data.get("mechanism_id", platform_data.get("platform_mechanism_id", ""))).strip_edges()


static func _get_platform_mechanism_kind(platform_data: Dictionary) -> String:
	var mode_source: String = str(platform_data.get(
		"platform_mode",
		platform_data.get(
			"mode",
			platform_data.get("platform_type", "")
		)
	)).strip_edges().to_lower()

	mode_source = mode_source.replace(" ", "_")
	mode_source = mode_source.replace("-", "_")

	var object_type: String = str(platform_data.get("object_type", platform_data.get("type", ""))).strip_edges().to_lower()
	var archetype_id: String = str(platform_data.get("archetype_id", platform_data.get("map_constructor_prefab_id", ""))).strip_edges().to_lower()

	if mode_source.is_empty():
		if object_type.contains("rotat") or archetype_id.contains("rotat"):
			return PlatformTypesRef.MODE_ROTATE

		if object_type.contains("lift") or object_type.contains("elevator") or archetype_id.contains("lift") or archetype_id.contains("elevator"):
			return PlatformTypesRef.MODE_ELEVATOR

	var normalized_mode: String = PlatformTypesRef.normalize_platform_mode(mode_source)
	if normalized_mode == PlatformTypesRef.MODE_ROTATE:
		return PlatformTypesRef.MODE_ROTATE

	return PlatformTypesRef.MODE_ELEVATOR


static func _is_same_platform_mechanism_kind(a: Dictionary, b: Dictionary) -> bool:
	return _get_platform_mechanism_kind(a) == _get_platform_mechanism_kind(b)


static func _read_platform_row_cell(row: Dictionary) -> Vector2i:
	for field_name in ["cell", "position", "grid_position", "world_cell", "target_position"]:
		if row.has(field_name):
			var cell: Vector2i = WorldObjectCatalogRef.to_world_cell(row.get(field_name), Vector2i(-1, -1))
			if cell.x >= 0 and cell.y >= 0:
				return cell

	var x_value: int = int(row.get("x", row.get("cell_x", -1)))
	var y_value: int = int(row.get("y", row.get("cell_y", -1)))

	if x_value >= 0 and y_value >= 0:
		return Vector2i(x_value, y_value)

	return Vector2i(-1, -1)


static func _build_platform_candidate_from_row(controller: Variant, row: Dictionary) -> Dictionary:
	var object_id: String = str(row.get("id", row.get("object_id", row.get("platform_id", "")))).strip_edges()
	var candidate: Dictionary = row.duplicate(true)
	var row_cell: Vector2i = _read_platform_row_cell(row)

	if not object_id.is_empty() and controller != null and controller.mission_manager != null and controller.mission_manager.has_method("get_map_constructor_entity_by_id"):
		var entity: Dictionary = Dictionary(controller.mission_manager.call("get_map_constructor_entity_by_id", "world_object", object_id))
		if bool(entity.get("ok", false)):
			candidate = Dictionary(entity.get("data", {})).duplicate(true)
			candidate["id"] = object_id

	# Preserve actual placed row data over prefab/entity data.
	# This is important because mechanism membership is edited in map constructor rows.
	for field_name in [
		"mechanism_id",
		"platform_mechanism_id",
		"platform_ids",
		"member_platform_ids",
		"mechanism_platform_ids",
		"linked_platform_ids",
		"members",
		"platform_mode",
		"platform_type",
		"platform_action",
		"operation",
		"mechanism_operation",
		"platform_level",
		"current_level",
		"height_level",
		"max_level",
		"max_height_level",
		"control_type",
		"control_mode",
		"power_type",
		"power_mode"
	]:
		if row.has(field_name):
			candidate[field_name] = row.get(field_name)

	if row_cell.x >= 0 and row_cell.y >= 0:
		candidate["position"] = row_cell
		candidate["platform_cells"] = [row_cell]

	if not object_id.is_empty():
		candidate["id"] = object_id
		if not candidate.has("platform_id"):
			candidate["platform_id"] = object_id

	return candidate
	

static func _build_platform_mechanism(controller: Variant, platform_object: Dictionary) -> Dictionary:
	var platform_ids: Array[String] = []
	var current_platform_id: String = _get_platform_id(platform_object)
	var mechanism_id: String = _get_platform_mechanism_id(platform_object)
	var mechanism_kind: String = _get_platform_mechanism_kind(platform_object)

	for field_name in [
		"platform_ids",
		"member_platform_ids",
		"mechanism_platform_ids",
		"linked_platform_ids",
		"members"
	]:
		if not platform_object.has(field_name):
			continue

		var value: Variant = platform_object.get(field_name)
		if value is Array:
			for item in Array(value):
				var platform_id: String = ""

				if item is Dictionary:
					platform_id = _get_platform_id(Dictionary(item))
				else:
					platform_id = str(item).strip_edges()

				if not platform_id.is_empty() and not platform_ids.has(platform_id):
					platform_ids.append(platform_id)

	if not current_platform_id.is_empty() and not platform_ids.has(current_platform_id):
		platform_ids.append(current_platform_id)

	# Optional summary support, but filtered by platform kind.
	if not mechanism_id.is_empty() and controller != null and controller.mission_manager != null and controller.mission_manager.has_method("get_platform_mechanism_summary"):
		var summary_variant: Variant = controller.mission_manager.call("get_platform_mechanism_summary", mechanism_id)
		if summary_variant is Dictionary:
			var summary: Dictionary = Dictionary(summary_variant)

			for platform_id_variant in Array(summary.get("platform_ids", [])):
				var platform_id_from_summary: String = str(platform_id_variant).strip_edges()
				if platform_id_from_summary.is_empty() or platform_ids.has(platform_id_from_summary):
					continue

				var member: Dictionary = {}
				if controller.mission_manager.has_method("get_platform_by_id"):
					member = Dictionary(controller.mission_manager.call("get_platform_by_id", platform_id_from_summary))

				if member.is_empty():
					continue

				if _get_platform_mechanism_kind(member) != mechanism_kind:
					continue

				platform_ids.append(platform_id_from_summary)

	var mechanism: Dictionary = PlatformMechanismRulesServiceRef.build_mechanism_from_platform(platform_object, platform_ids)

	mechanism["mechanism_id"] = mechanism_id
	mechanism["platform_mechanism_id"] = mechanism_id
	mechanism["platform_mode"] = mechanism_kind
	mechanism["mechanism_kind"] = mechanism_kind
	mechanism["platform_ids"] = platform_ids

	return mechanism

static func _collect_mechanism_members(controller: Variant, mechanism: Dictionary, platform_object: Dictionary) -> Array[Dictionary]:
	var members: Array[Dictionary] = []

	if controller == null or controller.mission_manager == null:
		members.append(platform_object.duplicate(true))
		return members

	var current_platform_id: String = _get_platform_id(platform_object)
	var mechanism_id: String = _get_platform_mechanism_id(platform_object)

	if mechanism_id.is_empty():
		mechanism_id = str(mechanism.get("mechanism_id", mechanism.get("platform_mechanism_id", ""))).strip_edges()

	var mechanism_kind: String = str(mechanism.get("mechanism_kind", mechanism.get("platform_mode", ""))).strip_edges()
	if mechanism_kind.is_empty():
		mechanism_kind = _get_platform_mechanism_kind(platform_object)

	var requested_platform_ids: Array[String] = []

	for platform_id_variant in Array(mechanism.get("platform_ids", [])):
		var platform_id_from_mechanism: String = str(platform_id_variant).strip_edges()
		if not platform_id_from_mechanism.is_empty() and not requested_platform_ids.has(platform_id_from_mechanism):
			requested_platform_ids.append(platform_id_from_mechanism)

	for field_name in [
		"platform_ids",
		"member_platform_ids",
		"mechanism_platform_ids",
		"linked_platform_ids",
		"members"
	]:
		if not platform_object.has(field_name):
			continue

		var value: Variant = platform_object.get(field_name)
		if value is Array:
			for item in Array(value):
				var platform_id_from_field: String = ""

				if item is Dictionary:
					platform_id_from_field = _get_platform_id(Dictionary(item))
				else:
					platform_id_from_field = str(item).strip_edges()

				if not platform_id_from_field.is_empty() and not requested_platform_ids.has(platform_id_from_field):
					requested_platform_ids.append(platform_id_from_field)

	if not current_platform_id.is_empty() and not requested_platform_ids.has(current_platform_id):
		requested_platform_ids.append(current_platform_id)

	# Single platform:
	# no mechanism_id and no member list means independent platform.
	# Important: do not return early if member ids exist.
	if mechanism_id.is_empty() and requested_platform_ids.size() <= 1:
		members.append(platform_object.duplicate(true))
		return members

	_append_unique_platform_member(members, platform_object)

	# 1) Explicit platform ids.
	if controller.mission_manager.has_method("get_platform_by_id"):
		for requested_platform_id in requested_platform_ids:
			var member: Dictionary = Dictionary(controller.mission_manager.call("get_platform_by_id", requested_platform_id))

			if member.is_empty() and requested_platform_id == current_platform_id:
				member = platform_object.duplicate(true)

			if member.is_empty():
				continue

			if not _is_platform_member_data(member):
				continue

			if _get_platform_mechanism_kind(member) != mechanism_kind:
				continue

			_append_unique_platform_member(members, member)

	# 2) Map constructor placed rows.
	if controller.mission_manager.has_method("get_map_constructor_placed_object_rows"):
		var rows: Array = Array(controller.mission_manager.call("get_map_constructor_placed_object_rows"))

		for row_variant in rows:
			if typeof(row_variant) != TYPE_DICTIONARY:
				continue

			var row: Dictionary = Dictionary(row_variant)
			var candidate: Dictionary = _build_platform_candidate_from_row(controller, row)

			if not _is_platform_member_data(candidate):
				continue

			if _get_platform_mechanism_kind(candidate) != mechanism_kind:
				continue

			var candidate_id: String = _get_platform_id(candidate)
			var candidate_mechanism_id: String = _get_platform_mechanism_id(candidate)
			var candidate_matches: bool = false

			if not candidate_id.is_empty() and requested_platform_ids.has(candidate_id):
				candidate_matches = true

			if not mechanism_id.is_empty() and candidate_mechanism_id == mechanism_id:
				candidate_matches = true

			for field_name in [
				"platform_ids",
				"member_platform_ids",
				"mechanism_platform_ids",
				"linked_platform_ids",
				"members"
			]:
				if candidate_matches:
					break

				if not candidate.has(field_name):
					continue

				var candidate_value: Variant = candidate.get(field_name)
				if candidate_value is Array:
					for item in Array(candidate_value):
						var listed_id: String = ""

						if item is Dictionary:
							listed_id = _get_platform_id(Dictionary(item))
						else:
							listed_id = str(item).strip_edges()

						if not current_platform_id.is_empty() and listed_id == current_platform_id:
							candidate_matches = true
							break

			if candidate_matches:
				_append_unique_platform_member(members, candidate)

	# 3) Runtime mission world objects fallback.
	var world_objects_variant: Variant = controller.mission_manager.get("mission_world_objects")
	if world_objects_variant is Array:
		for object_variant in Array(world_objects_variant):
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue

			var candidate_object: Dictionary = Dictionary(object_variant)

			if not _is_platform_member_data(candidate_object):
				continue

			if _get_platform_mechanism_kind(candidate_object) != mechanism_kind:
				continue

			var candidate_object_id: String = _get_platform_id(candidate_object)
			var candidate_object_mechanism_id: String = _get_platform_mechanism_id(candidate_object)
			var candidate_object_matches: bool = false

			if not candidate_object_id.is_empty() and requested_platform_ids.has(candidate_object_id):
				candidate_object_matches = true

			if not mechanism_id.is_empty() and candidate_object_mechanism_id == mechanism_id:
				candidate_object_matches = true

			for field_name in [
				"platform_ids",
				"member_platform_ids",
				"mechanism_platform_ids",
				"linked_platform_ids",
				"members"
			]:
				if candidate_object_matches:
					break

				if not candidate_object.has(field_name):
					continue

				var candidate_object_value: Variant = candidate_object.get(field_name)
				if candidate_object_value is Array:
					for item in Array(candidate_object_value):
						var listed_object_id: String = ""

						if item is Dictionary:
							listed_object_id = _get_platform_id(Dictionary(item))
						else:
							listed_object_id = str(item).strip_edges()

						if not current_platform_id.is_empty() and listed_object_id == current_platform_id:
							candidate_object_matches = true
							break

			if candidate_object_matches:
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

	var member_id: String = _get_platform_id(member)

	if member_id.is_empty():
		var member_cell: Vector2i = WorldObjectCatalogRef.to_world_cell(
			member.get("position", member.get("cell", member.get("pos", Vector2i(-1, -1)))),
			Vector2i(-1, -1)
		)

		if member_cell.x >= 0 and member_cell.y >= 0:
			member_id = "platform_at_%d_%d" % [member_cell.x, member_cell.y]

	for existing in members:
		var existing_id: String = _get_platform_id(existing)

		if existing_id.is_empty():
			var existing_cell: Vector2i = WorldObjectCatalogRef.to_world_cell(
				existing.get("position", existing.get("cell", existing.get("pos", Vector2i(-1, -1)))),
				Vector2i(-1, -1)
			)

			if existing_cell.x >= 0 and existing_cell.y >= 0:
				existing_id = "platform_at_%d_%d" % [existing_cell.x, existing_cell.y]

		if not member_id.is_empty() and member_id == existing_id:
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
