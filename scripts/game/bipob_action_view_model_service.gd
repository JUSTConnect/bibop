extends RefCounted
class_name BipobActionViewModelService

const InteractionSystemRef = preload("res://scripts/world/interaction_system.gd")
const ObjectFacingServiceRef = preload("res://scripts/game/object/object_facing_service.gd")
const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const EntityStatusEvaluatorRef = preload("res://scripts/world/entity_status_evaluator.gd")
const BreachableWallServiceRef = preload("res://scripts/game/wall/breachable_wall_service.gd")
const BreachableWallRulesServiceRef = preload("res://scripts/game/wall/breachable_wall_rules_service.gd")
const WallMountedPlacementRulesServiceRef = preload("res://scripts/game/wall/wall_mounted_placement_rules_service.gd")
const BipobTargetingServiceRef = preload("res://scripts/game/bipob_targeting_service.gd")

const DEBUG_BREACHABLE_WALL_RUNTIME_TRACE := false
const DEBUG_WALL_MOUNTED_INTERACTION_TRACE := false


static func _is_cable_like_target(target_object: Dictionary) -> bool:
	for field_name in ["object_type", "type", "archetype_id", "map_constructor_prefab_id", "prefab_id"]:
		var id_value: String = str(target_object.get(field_name, "")).strip_edges().to_lower()
		if id_value in ["power_cable", "cable", "cable_reel", "power_cable_reel"]:
			return true
	return false


static func should_hide_action_from_generic_menu(controller: Variant, world_object: Dictionary, action_id: String) -> bool:
	var normalized_action_id: String = action_id.strip_edges().to_lower()
	if normalized_action_id == "cut":
		var has_direct_plasma_cutter: bool = controller != null and controller.has_method("has_module_id") and bool(controller.call("has_module_id", "plasma_cutter_v1"))
		if has_direct_plasma_cutter and _is_cable_like_target(world_object):
			return true
	if normalized_action_id == "repair":
		# Repair remains in the generic Action flow and is gated by a held repair_kit.
		# Never hide it merely because the kit exists, and never make repair_v1 a
		# runtime direct-tool/action-menu capability.
		return false
	return false


static func _is_platform_target(target_object: Dictionary) -> bool:
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


static func _platform_contains_actor_cell(controller: Variant, platform_object: Dictionary, target_position: Vector2i) -> bool:
	if controller == null:
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
	if x_value >= 0 and y_value >= 0 and Vector2i(x_value, y_value) == actor_cell:
		return true

	return false


static func _empty_platform_view_model(target_object: Dictionary) -> Dictionary:
	return {
		"target": target_object,
		"actions": [],
		"raw_action_ids": [],
		"available_action_ids": [],
		"primary_action_id": "",
		"primary_action_label": "Action",
		"has_available_action": false,
		"has_interaction_target": false,
		"disabled_reason": "not_on_platform"
	}
	
static func build_runtime_action_view_model(controller: Variant, target_object: Dictionary, target_position: Vector2i) -> Dictionary:
	var normalized_target: Dictionary = WorldObjectCatalogRef.normalize_world_object_contract(target_object)

	if BreachableWallServiceRef.is_breachable_wall_data(normalized_target):
		normalized_target = BreachableWallServiceRef.normalize_runtime_breachable_wall_data(normalized_target)

	if str(normalized_target.get("object_group", "")) == "door":
		normalized_target = WorldObjectCatalogRef.normalize_door_contract(normalized_target)
		normalized_target = WorldObjectCatalogRef.normalize_door_state_fields(normalized_target)

	if _is_platform_target(normalized_target) and not _platform_contains_actor_cell(controller, normalized_target, target_position):
		return _empty_platform_view_model(normalized_target)

	var wall_mount_gate: Dictionary = {}
	var raw_action_ids: Array = []
	if not normalized_target.is_empty():
		raw_action_ids = controller.get_available_world_actions(normalized_target, target_position)
	var action_ids: Array[String] = []
	for action_id_variant in raw_action_ids:
		var action_id: String = str(action_id_variant).strip_edges().to_lower()
		if action_id.is_empty():
			continue
		if BreachableWallServiceRef.is_breachable_wall_data(normalized_target):
			if action_id == "breach":
				action_id = BreachableWallServiceRef.ACTION_BREAK_BREACHABLE_WALL
			if action_id != BreachableWallServiceRef.ACTION_BREAK_BREACHABLE_WALL:
				continue
		if should_hide_action_from_generic_menu(controller, normalized_target, action_id):
			continue
		if not action_ids.has(action_id):
			action_ids.append(action_id)
	if BreachableWallServiceRef.is_active_breachable_wall_data(normalized_target) and not action_ids.has(BreachableWallServiceRef.ACTION_BREAK_BREACHABLE_WALL):
		var breach_payload_for_append: Dictionary = _build_breachable_wall_action_payload(controller, normalized_target, target_position)
		if bool(breach_payload_for_append.get("show_heavy_claw", false)):
			action_ids.append(BreachableWallServiceRef.ACTION_BREAK_BREACHABLE_WALL)
	var group: String = str(normalized_target.get("object_group", ""))
	var state: String = str(normalized_target.get("state", ""))
	if group == "door":
		var expected_door_action: String = ""
		if state == "open": expected_door_action = "close"
		elif state == "closed": expected_door_action = "open"
		elif state == "locked": expected_door_action = "unlock"
		if not expected_door_action.is_empty() and not action_ids.has(expected_door_action):
			action_ids.push_front(expected_door_action)
	var actor: Dictionary = controller._build_runtime_action_actor(normalized_target, target_position)
	var descriptors: Array[Dictionary] = []
	var available_action_ids: Array[String] = []
	var target_id: String = str(normalized_target.get("id", ""))
	var target_type: String = str(normalized_target.get("object_type", group))
	
	for action_id in action_ids:
		var module: Dictionary = controller.get_world_action_module(action_id, normalized_target)
		var gate: Dictionary = InteractionSystemRef.can_apply_action(actor, module, normalized_target, action_id)
		var enabled: bool = bool(gate.get("success", false))
		var reason: String = str(gate.get("reason_code", gate.get("reason", "" if enabled else "action_unavailable")))
		var requires_free_manipulator: bool = _runtime_action_requires_free_manipulator(action_id, normalized_target)
		if BreachableWallServiceRef.is_breachable_wall_data(normalized_target) and action_id == BreachableWallServiceRef.ACTION_BREAK_BREACHABLE_WALL:
			var breach_payload: Dictionary = _build_breachable_wall_action_payload(controller, normalized_target, target_position)
			if not bool(breach_payload.get("show_heavy_claw", false)):
				enabled = false
				reason = _get_breachable_wall_disabled_reason(breach_payload)
		if enabled and group == "terminal" and action_id in ["connect", "scan", "hack", "download", "activate_platform", "apply_digital_key", "input_password"] and not controller._is_terminal_powered_for_interaction(normalized_target):
			enabled = false
			reason = "terminal_unpowered"
		var label: String = controller.get_world_action_display_label(action_id, normalized_target) if enabled else _runtime_action_disabled_label(controller, action_id, reason, normalized_target)
		descriptors.append(_canonical_action_descriptor(action_id, label, enabled, reason, Array(gate.get("requirements", [])), target_id, target_type, target_position, 100, requires_free_manipulator, module, gate))
		if enabled:
			available_action_ids.append(action_id)
	var primary: Dictionary = {}
	for descriptor in descriptors:
		if bool(descriptor.get("enabled", false)):
			primary = descriptor
			break
	if primary.is_empty() and not descriptors.is_empty():
		primary = descriptors[0]
	var disabled_reason: String = str(primary.get("reason", "target_missing" if normalized_target.is_empty() else "no_available_action"))
	var has_interaction_target: bool = not normalized_target.is_empty() and (not descriptors.is_empty() or not wall_mount_gate.is_empty())
	descriptors.sort_custom(func(a, b): return _sort_action_descriptors(a, b))
	var presentation_context: Dictionary = {"mode":"runtime"}
	var view_model: Dictionary = {"target":normalized_target, "actions":descriptors, "raw_action_ids":action_ids, "unfiltered_action_ids":raw_action_ids, "available_action_ids":available_action_ids, "primary_action_id":str(primary.get("id", "")), "primary_action_label":str(primary.get("label", "Action")), "has_available_action":not available_action_ids.is_empty(), "has_interaction_target":has_interaction_target, "disabled_reason":disabled_reason}
	view_model["presentation_snapshot"] = build_runtime_presentation_snapshot(controller, normalized_target, target_position, view_model, presentation_context)
	if not wall_mount_gate.is_empty():
		_trace_wall_mounted_interaction({"target_position": target_position, "object_id": target_id, "object_type": target_type, "actor_cell": wall_mount_gate.get("actor_cell", Vector2i(-1, -1)), "wall_cell": wall_mount_gate.get("wall_cell", Vector2i(-1, -1)), "approach_direction": wall_mount_gate.get("approach_direction", Vector2i.ZERO), "wall_side": str(wall_mount_gate.get("wall_side", "")), "interaction_side": str(wall_mount_gate.get("interaction_side", "")), "available_actions": available_action_ids})
	_trace_breachable_wall_runtime_view_model(controller, target_position, normalized_target, raw_action_ids, view_model)
	_trace_runtime_action_view_model(controller, target_position, normalized_target, raw_action_ids, available_action_ids, view_model)
	return view_model


static func _canonical_action_descriptor(action_code: String, fallback_label: String, available: bool, reason_code: String, requirements: Array, target_id: String, target_type: String, target_cell: Vector2i, priority: int, requires_free_manipulator: bool, module: Dictionary, gate: Dictionary) -> Dictionary:
	var stable_requirements: Array = _sorted_requirements(requirements)
	var code: String = action_code.strip_edges().to_lower()
	var label_key: String = "action.%s.label" % code
	return {
		"action_code": code,
		"label_key": label_key,
		"available": available,
		"reason_code": reason_code,
		"requirements": stable_requirements,
		"target_id": target_id,
		"context": {"target_type": target_type, "target_cell": target_cell},
		"id": code,
		"label": fallback_label,
		"enabled": available,
		"reason": reason_code,
		"target_type": target_type,
		"target_cell": target_cell,
		"source": "world_object",
		"priority": priority,
		"requires_free_manipulator": requires_free_manipulator,
		"module_id": str(module.get("id", "")),
		"module": module.duplicate(true),
		"gate": gate.duplicate(true)
	}


static func _sort_action_descriptors(a: Dictionary, b: Dictionary) -> bool:
	var pa: int = int(a.get("priority", 100))
	var pb: int = int(b.get("priority", 100))
	if pa == pb:
		return str(a.get("action_code", a.get("id", ""))) < str(b.get("action_code", b.get("id", "")))
	return pa < pb


static func _sorted_requirements(requirements: Array) -> Array:
	var result: Array = []
	for item in requirements:
		if item is Dictionary:
			result.append(Dictionary(item).duplicate(true))
	result.sort_custom(func(a, b): return _sort_requirement_descriptors(a, b))
	return result


static func _sort_requirement_descriptors(a: Dictionary, b: Dictionary) -> bool:
	var at: String = str(a.get("type", ""))
	var bt: String = str(b.get("type", ""))
	if at == bt:
		return var_to_str(a) < var_to_str(b)
	return at < bt


static func build_runtime_presentation_snapshot(controller: Variant, target_object: Dictionary, target_position: Vector2i, action_view_model: Dictionary, context: Dictionary = {}) -> Dictionary:
	var source: Dictionary = target_object.duplicate(true)
	var debug_enabled: bool = str(context.get("mode", "")).strip_edges().to_lower() in ["task_test", "task_test_context", "debug"] or bool(context.get("debug", false))
	var contract: Dictionary = WorldObjectCatalogRef.get_entity_definition_contract_for_object(source)
	var identity: Dictionary = _build_presentation_identity(source, contract)
	var status_eval: Dictionary = EntityStatusEvaluatorRef.evaluate(source, context.duplicate(true))
	var status_rows: Array = _build_presentation_status_rows(status_eval, debug_enabled)
	var actions: Array = []
	for action_variant in Array(action_view_model.get("actions", [])):
		if action_variant is Dictionary:
			actions.append(Dictionary(action_variant).duplicate(true))
	actions.sort_custom(func(a, b): return _sort_action_descriptors(a, b))
	var requirements: Array = []
	for action in actions:
		for requirement in Array(Dictionary(action).get("requirements", [])):
			if requirement is Dictionary:
				requirements.append(Dictionary(requirement).duplicate(true))
	requirements = _sorted_requirements(requirements)
	var notification: Dictionary = _build_presentation_notification(Dictionary(context.get("notification", {})), debug_enabled)
	var snapshot: Dictionary = {"identity":identity, "status":status_rows, "requirements":requirements, "bindings":[], "actions":actions, "notification":notification, "signature":"", "debug":{}}
	if debug_enabled:
		snapshot["debug"] = {"target_position":target_position, "status_reason_code":str(status_eval.get("reason_code", "")), "real_values":Dictionary(status_eval.get("real_values", {})).duplicate(true), "forced_values":Dictionary(status_eval.get("forced_values", {})).duplicate(true)}
	var unsigned: Dictionary = snapshot.duplicate(true)
	unsigned.erase("signature")
	snapshot["signature"] = str(hash(var_to_str(unsigned)))
	return snapshot


static func _build_presentation_identity(source: Dictionary, contract: Dictionary) -> Dictionary:
	var display_name: String = str(source.get("display_name", source.get("name", contract.get("display_name_template", contract.get("name", "Interactable"))))).strip_edges()
	return {"display_name": display_name, "type_label": str(contract.get("palette_label", source.get("object_group", source.get("type", "")))), "subtype_label": str(source.get("subtype_label", "")), "object_class": str(source.get("object_group", source.get("object_type", ""))), "description": str(contract.get("description", source.get("description", "")))}


static func _build_presentation_status_rows(status_eval: Dictionary, debug_enabled: bool) -> Array:
	var order: Array[String] = ["intent", "operational", "health", "thermal", "energy", "power", "control", "access"]
	var sections: Dictionary = Dictionary(status_eval.get("sections", {}))
	var rows: Array = []
	for section_code in order:
		if not sections.has(section_code):
			continue
		var section: Dictionary = Dictionary(sections.get(section_code, {}))
		var row: Dictionary = {"label": section_code.capitalize(), "value": str(section.get("value", ""))}
		if debug_enabled:
			row["section_code"] = section_code
			row["reason_code"] = str(status_eval.get("reason_code", ""))
			row["real_values"] = Dictionary(status_eval.get("real_values", {})).duplicate(true)
			row["forced_values"] = Dictionary(status_eval.get("forced_values", {})).duplicate(true)
		rows.append(row)
	return rows


static func _build_presentation_notification(event: Dictionary, debug_enabled: bool) -> Dictionary:
	if event.is_empty():
		return {}
	var result: Dictionary = {"result":str(event.get("result", "")), "message_key":str(event.get("message_key", "")), "fallback":str(event.get("fallback", event.get("message", ""))), "player_action":str(event.get("player_action", ""))}
	if debug_enabled:
		result["event_id"] = str(event.get("event_id", ""))
		result["action_id"] = str(event.get("action_id", ""))
	return result

static func _trace_wall_mounted_interaction(payload: Dictionary) -> void:
	if not DEBUG_WALL_MOUNTED_INTERACTION_TRACE:
		return
	print("[WallMountedInteraction] %s" % JSON.stringify(payload))

static func _trace_breachable_wall_runtime_view_model(controller: Variant, target_position: Vector2i, target_object: Dictionary, raw_action_ids: Array, view_model: Dictionary) -> void:
	if not DEBUG_BREACHABLE_WALL_RUNTIME_TRACE or not BreachableWallServiceRef.is_breachable_wall_data(target_object):
		return
	var grid_position: Vector2i = Vector2i.ZERO
	if controller != null:
		grid_position = Vector2i(controller.grid_position)
	var trace: Dictionary = {
		"grid_position": grid_position,
		"target_position": target_position,
		"object_group": str(target_object.get("object_group", "")),
		"object_type": str(target_object.get("object_type", "")),
		"wall_archetype": str(target_object.get("wall_archetype", "")),
		"breach_side": str(target_object.get("breach_side", "")),
		"crack_side": BreachableWallServiceRef.get_grid_side_for_breach_side(target_object.get("breach_side", target_object.get("crack_side", "sw"))),
		"state": str(target_object.get("state", "")),
		"breach_state": str(target_object.get("breach_state", "")),
		"wall_state": str(target_object.get("wall_state", "")),
		"get_available_world_actions": raw_action_ids,
		"view_model_available_action_ids": Array(view_model.get("available_action_ids", [])),
		"primary_action_label": str(view_model.get("primary_action_label", ""))
	}
	print("[breachable_wall_runtime] %s" % var_to_str(trace))


static func _trace_runtime_action_view_model(controller: Variant, target_position: Vector2i, target_object: Dictionary, raw_action_ids: Array, filtered_action_ids: Array, view_model: Dictionary) -> void:
	if not BipobTargetingServiceRef.DEBUG_RUNTIME_ACTION_TARGET_TRACE:
		return
	var grid_position: Vector2i = Vector2i.ZERO
	var direction_text: String = ""
	if controller != null:
		grid_position = Vector2i(controller.grid_position)
		if controller.has_method("get_direction"):
			direction_text = str(controller.call("get_direction"))
	var action_descriptors: Array = Array(view_model.get("actions", []))
	var rejected_actions: Array[Dictionary] = []
	for descriptor_variant in action_descriptors:
		if descriptor_variant is Dictionary:
			var descriptor: Dictionary = Dictionary(descriptor_variant)
			if not bool(descriptor.get("enabled", false)):
				rejected_actions.append({"action_id": str(descriptor.get("id", "")), "module_id": str(descriptor.get("module_id", "")), "module": descriptor.get("module", {}), "gate": descriptor.get("gate", {}), "reason": str(descriptor.get("reason", "")), "message": str(Dictionary(descriptor.get("gate", {})).get("message", ""))})
	var trace: Dictionary = {
		"bipob_cell": grid_position,
		"facing_cell": target_position,
		"direction": direction_text,
		"raw_object": {"id": str(target_object.get("id", "")), "object_type": str(target_object.get("object_type", "")), "object_group": str(target_object.get("object_group", "")), "state": str(target_object.get("state", "")), "placement_mode": str(target_object.get("placement_mode", target_object.get("placement", "")))},
		"normalized_object": {"id": str(Dictionary(view_model.get("target", {})).get("id", target_object.get("id", ""))), "object_type": str(Dictionary(view_model.get("target", {})).get("object_type", target_object.get("object_type", ""))), "object_group": str(Dictionary(view_model.get("target", {})).get("object_group", target_object.get("object_group", ""))), "state": str(Dictionary(view_model.get("target", {})).get("state", target_object.get("state", ""))), "placement_mode": str(Dictionary(view_model.get("target", {})).get("placement_mode", Dictionary(view_model.get("target", {})).get("placement", target_object.get("placement_mode", target_object.get("placement", "")))))},
		"raw_action_ids": raw_action_ids,
		"actions_after_filtering": filtered_action_ids,
		"action_descriptors": action_descriptors,
		"rejected_or_disabled_actions": rejected_actions,
		"primary_action_id": str(view_model.get("primary_action_id", "")),
		"primary_action_label": str(view_model.get("primary_action_label", "")),
		"has_interaction_target": bool(view_model.get("has_interaction_target", false)),
		"disabled_reason": str(view_model.get("disabled_reason", ""))
	}
	print("[runtime_action_view_model] %s" % var_to_str(trace))


static func _has_heavy_claw_for_breach(controller: Variant) -> bool:
	return controller != null and controller.has_method("has_heavy_claw_capability") and bool(controller.call("has_heavy_claw_capability"))


static func _build_breachable_wall_action_payload(controller: Variant, wall_data: Dictionary, target_position: Vector2i) -> Dictionary:
	var approach_direction: Vector2i = Vector2i.ZERO
	if controller != null:
		approach_direction = Vector2i(controller.grid_position) - target_position
	var rules_wall: Dictionary = _build_rules_wall_data(wall_data)
	return BreachableWallRulesServiceRef.build_action_payload(rules_wall, approach_direction, _has_heavy_claw_for_breach(controller))


static func _build_rules_wall_data(wall_data: Dictionary) -> Dictionary:
	var rules_wall: Dictionary = wall_data.duplicate(true)
	rules_wall["is_breachable"] = BreachableWallServiceRef.is_breachable_wall_data(wall_data)
	rules_wall["wall_state"] = str(wall_data.get("wall_state", wall_data.get("breach_state", wall_data.get("state", "intact"))))
	rules_wall["crack_side"] = WorldObjectCatalogRef.get_grid_side_for_breachable_wall_breach_side(wall_data.get("breach_side", wall_data.get("crack_side", "sw")))
	return rules_wall


static func _get_breachable_wall_disabled_reason(action_payload: Dictionary) -> String:
	var reason_code: String = str(action_payload.get("reason_code", "")).strip_edges().to_lower()
	return reason_code if not reason_code.is_empty() else "action_unavailable"


static func _runtime_action_requires_free_manipulator(_action_id: String, _target_object: Dictionary) -> bool:
	return false


static func _runtime_action_disabled_label(controller: Variant, action_id: String, reason: String, target_object: Dictionary) -> String:
	match reason:
		"key_card_required": return "Key-card required"
		"free_manipulator_required": return "Free manipulator required"
		"manipulator_required": return "Manipulator required"
		"cable_required": return "Cable required"
		"cable_reel_end_required": return "Nothing to plug in"
		"nothing_to_plug_in": return "Nothing to plug in"
		"hand_occupied": return "Hand occupied"
		"reel_end_already_connected": return "Cable end already connected"
		"fuse_required": return "Fuse required"
		"repair_kit_required": return "Repair kit required"
		"plasma_cutter_required": return "Plasma Cutter required"
		"cable_already_broken": return "Cable already broken"
		"no_free_pocket_or_manipulator_slot": return "No free pocket or manipulator slot"
		"power_must_be_cut": return "Cut power to open"
		"terminal_control_required": return "Use linked terminal"
		"digital_access_required": return "Digital access required"
		"unpowered": return "Unpowered"
		"terminal_unpowered": return "Terminal unpowered"
		"broken": return "Broken"
		"wrong_breach_side": return "Cracked side only"
		"wrong_wall_side": return ObjectFacingServiceRef.FRONT_SIDE_HINT
		"wrong_front_side": return ObjectFacingServiceRef.FRONT_SIDE_HINT
		"face_object_to_attach_heavy_claw": return "Face the object to attach Heavy Claw."
		"heavy_claw_required": return "Heavy Claw required"
		"external_control": return "Use linked terminal"
		"no_control_cell": return "No platform control cell"
		"not_on_control_cell": return "Stand on platform control cell"
		"platform_unpowered": return "Platform unpowered"
		"platform_disabled": return "Platform disabled"
		"platform_unavailable": return "Platform control unavailable"
	if BreachableWallServiceRef.is_breachable_wall_data(target_object) and action_id == BreachableWallServiceRef.ACTION_BREAK_BREACHABLE_WALL:
		return "Heavy Claw required"
	return controller.get_world_action_display_label(action_id, target_object)
