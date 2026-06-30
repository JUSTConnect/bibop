extends RefCounted
class_name RuntimeActionViewModelBuilderV2

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const BreachableWallServiceRef = preload("res://scripts/game/wall/breachable_wall_service.gd")
const BreachableWallRulesServiceRef = preload("res://scripts/game/wall/breachable_wall_rules_service.gd")
const AccessResolverRef = preload("res://scripts/world/access_resolver.gd")
const RequirementCatalogRef = preload("res://scripts/game/presentation/runtime_requirement_catalog.gd")

static func should_hide_action(controller: Variant, world_object: Dictionary, action_id: String) -> bool:
	if action_id.strip_edges().to_lower() != "cut": return false
	var has_cutter: bool = controller != null and controller.has_method("has_module_id") and bool(controller.call("has_module_id", "plasma_cutter_v1"))
	if not has_cutter: return false
	for field_name in ["object_type", "type", "archetype_id", "map_constructor_prefab_id", "prefab_id"]:
		if str(world_object.get(field_name, "")).strip_edges().to_lower() in ["power_cable", "cable", "cable_reel", "power_cable_reel"]: return true
	return false

static func build(controller: Variant, target_object: Dictionary, target_position: Vector2i, gate_evaluator: Callable, descriptor_factory: Callable) -> Dictionary:
	var target: Dictionary = WorldObjectCatalogRef.normalize_world_object_contract(target_object)
	if BreachableWallServiceRef.is_breachable_wall_data(target): target = BreachableWallServiceRef.normalize_runtime_breachable_wall_data(target)
	if str(target.get("object_group", "")) == "door": target = WorldObjectCatalogRef.normalize_door_state_fields(WorldObjectCatalogRef.normalize_door_contract(target))
	if _is_platform(target) and not _platform_contains_actor(controller, target, target_position): return _empty(target)
	var raw_ids: Array = controller.get_available_world_actions(target, target_position) if controller != null and not target.is_empty() else []
	var action_ids: Array[String] = []
	for value in raw_ids:
		var action_id: String = str(value).strip_edges().to_lower()
		if action_id == "breach": action_id = BreachableWallServiceRef.ACTION_BREAK_BREACHABLE_WALL
		if BreachableWallServiceRef.is_breachable_wall_data(target) and action_id != BreachableWallServiceRef.ACTION_BREAK_BREACHABLE_WALL: continue
		if not action_id.is_empty() and not should_hide_action(controller, target, action_id) and not action_ids.has(action_id): action_ids.append(action_id)
	if BreachableWallServiceRef.is_active_breachable_wall_data(target) and not action_ids.has(BreachableWallServiceRef.ACTION_BREAK_BREACHABLE_WALL):
		if bool(_breach_payload(controller, target, target_position).get("show_heavy_claw", false)): action_ids.append(BreachableWallServiceRef.ACTION_BREAK_BREACHABLE_WALL)
	var state: String = str(target.get("state", ""))
	if str(target.get("object_group", "")) == "door":
		var expected: String = "close" if state == "open" else "open" if state == "closed" else "unlock" if state == "locked" else ""
		if not expected.is_empty() and not action_ids.has(expected): action_ids.append(expected)
	var actor: Dictionary = controller._build_runtime_action_actor(target, target_position) if controller != null else {}
	var descriptors: Array[Dictionary] = []
	for action_id in action_ids:
		var module: Dictionary = controller.get_world_action_module(action_id, target) if controller != null else {}
		var gate: Dictionary = Dictionary(gate_evaluator.call(actor, module, target, action_id))
		var available: bool = bool(gate.get("success", false))
		var reason_code: String = str(gate.get("reason_code", gate.get("reason", "" if available else "action_unavailable")))
		if BreachableWallServiceRef.is_breachable_wall_data(target) and action_id == BreachableWallServiceRef.ACTION_BREAK_BREACHABLE_WALL:
			var payload: Dictionary = _breach_payload(controller, target, target_position)
			if not bool(payload.get("show_heavy_claw", false)):
				available = false
				reason_code = str(payload.get("reason_code", "action_unavailable"))
		if available and str(target.get("object_group", "")) == "terminal" and action_id in ["connect", "scan", "hack", "download", "activate_platform", "apply_digital_key", "input_password"] and controller != null and not controller._is_terminal_powered_for_interaction(target):
			available = false
			reason_code = "terminal_unpowered"
		var requirements: Array[Dictionary] = _requirements(action_id, reason_code, target, module, Array(gate.get("requirements", [])))
		gate["requirements"] = requirements.duplicate(true)
		var label: String = controller.get_world_action_display_label(action_id, target) if controller != null and available else _disabled_label(controller, action_id, reason_code, target)
		descriptors.append(Dictionary(descriptor_factory.call(action_id, label, available, reason_code, requirements, target, target_position, module, gate)))
	descriptors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("action_code", "")) < str(b.get("action_code", "")))
	var primary: Dictionary = {}
	var available_ids: Array[String] = []
	for descriptor in descriptors:
		if bool(descriptor.get("available", false)):
			available_ids.append(str(descriptor.get("action_code", "")))
			if primary.is_empty(): primary = descriptor
	if primary.is_empty() and not descriptors.is_empty(): primary = descriptors[0]
	return {"target":target, "actions":descriptors, "raw_action_ids":action_ids, "unfiltered_action_ids":raw_ids, "available_action_ids":available_ids, "primary_action_id":str(primary.get("action_code", "")), "primary_action_label":str(primary.get("label", "Action")), "has_available_action":not available_ids.is_empty(), "has_interaction_target":not target.is_empty() and not descriptors.is_empty(), "disabled_reason":str(primary.get("reason_code", "target_missing" if target.is_empty() else "no_available_action"))}

static func _requirements(action_id: String, reason_code: String, target: Dictionary, module: Dictionary, explicit: Array) -> Array[Dictionary]:
	var values: Array = explicit.duplicate(true)
	match reason_code:
		"unpowered", "terminal_unpowered", "platform_unpowered", "power_must_be_cut", "power.no_reachable_source": values.append({"type":"power"})
		"terminal_control_required", "external_control", "control.binding_missing", "control.controller_unpowered": values.append({"type":"control", "mode":"external"})
		"key_card_required": values.append({"type":"credential", "credential_type":"key_card"})
		"digital_access_required": values.append({"type":"access", "access_type":AccessResolverRef.normalize_access_type(target.get("access_type", "digital_key"))})
		"free_manipulator_required", "manipulator_required", "hand_occupied": values.append({"type":"manipulator", "state":"free"})
		"wrong_breach_side", "wrong_wall_side", "wrong_front_side": values.append({"type":"side", "value":"front"})
		"heavy_claw_required": values.append({"type":"module", "module_id":"manipulator_heavy_claw_v1"})
		"plasma_cutter_required": values.append({"type":"module", "module_id":"plasma_cutter_v1"})
	if action_id == "unlock":
		var access_type: String = AccessResolverRef.normalize_access_type(target.get("access_type", target.get("lock_type", "none")))
		if access_type != "none": values.append({"type":"access", "access_type":access_type})
	var module_id: String = str(module.get("id", ""))
	if not module_id.is_empty() and reason_code.ends_with("_required"): values.append({"type":"module", "module_id":module_id})
	return RequirementCatalogRef.deduplicate(values)

static func _is_platform(target: Dictionary) -> bool:
	return str(target.get("object_group", "")) == "platform" or str(target.get("object_type", "")) in ["platform", "lifting_platform", "rotating_platform"] or not str(target.get("platform_mode", "")).is_empty()

static func _platform_contains_actor(controller: Variant, target: Dictionary, target_position: Vector2i) -> bool:
	if controller == null: return false
	var actor_cell: Vector2i = Vector2i(controller.grid_position)
	if actor_cell == target_position: return true
	for field_name in ["platform_cells", "cells"]:
		for value in Array(target.get(field_name, [])):
			if WorldObjectCatalogRef.to_world_cell(value, Vector2i(-1, -1)) == actor_cell: return true
	return WorldObjectCatalogRef.to_world_cell(target.get("position", Vector2i(-1, -1)), Vector2i(-1, -1)) == actor_cell

static func _empty(target: Dictionary) -> Dictionary:
	return {"target":target, "actions":[], "raw_action_ids":[], "unfiltered_action_ids":[], "available_action_ids":[], "primary_action_id":"", "primary_action_label":"Action", "has_available_action":false, "has_interaction_target":false, "disabled_reason":"not_on_platform"}

static func _breach_payload(controller: Variant, target: Dictionary, target_position: Vector2i) -> Dictionary:
	var rules: Dictionary = target.duplicate(true)
	rules["is_breachable"] = BreachableWallServiceRef.is_breachable_wall_data(target)
	rules["wall_state"] = str(target.get("wall_state", target.get("breach_state", target.get("state", "intact"))))
	rules["crack_side"] = WorldObjectCatalogRef.get_grid_side_for_breachable_wall_breach_side(target.get("breach_side", target.get("crack_side", "sw")))
	var direction: Vector2i = Vector2i.ZERO if controller == null else Vector2i(controller.grid_position) - target_position
	var has_claw: bool = controller != null and controller.has_method("has_heavy_claw_capability") and bool(controller.call("has_heavy_claw_capability"))
	return BreachableWallRulesServiceRef.build_action_payload(rules, direction, has_claw)

static func _disabled_label(controller: Variant, action_id: String, reason_code: String, target: Dictionary) -> String:
	var labels: Dictionary = {"key_card_required":"Key-card required", "free_manipulator_required":"Free manipulator required", "manipulator_required":"Manipulator required", "power_must_be_cut":"Cut power to open", "terminal_control_required":"Use linked terminal", "digital_access_required":"Digital access required", "unpowered":"Unpowered", "terminal_unpowered":"Terminal unpowered", "broken":"Broken", "wrong_breach_side":"Cracked side only", "heavy_claw_required":"Heavy Claw required", "external_control":"Use linked terminal", "platform_unpowered":"Platform unpowered", "platform_disabled":"Platform disabled", "platform_unavailable":"Platform control unavailable"}
	if labels.has(reason_code): return str(labels[reason_code])
	return controller.get_world_action_display_label(action_id, target) if controller != null else action_id.capitalize()
