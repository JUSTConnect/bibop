extends RefCounted
class_name BipobActionController

const InteractionSystemRef = preload("res://scripts/world/interaction_system.gd")
const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const BipobActionViewModelServiceRef = preload("res://scripts/game/bipob_action_view_model_service.gd")
const BipobHeavyClawExecutionServiceRef = preload("res://scripts/game/bipob_heavy_claw_execution_service.gd")
const BipobItemPickupExecutionServiceRef = preload("res://scripts/game/bipob_item_pickup_execution_service.gd")
const BipobPlatformControlExecutionServiceRef = preload("res://scripts/game/bipob_platform_control_execution_service.gd")
const BipobRuntimeActionActorServiceRef = preload("res://scripts/game/bipob_runtime_action_actor_service.gd")
const BipobTargetingServiceRef = preload("res://scripts/game/bipob_targeting_service.gd")
const BipobTerminalControlExecutionServiceRef = preload("res://scripts/game/bipob_terminal_control_execution_service.gd")
const BipobWorldObjectExecutionServiceRef = preload("res://scripts/game/bipob_world_object_execution_service.gd")
const InteractionActionCostServiceRef = preload("res://scripts/game/interaction/interaction_action_cost_service.gd")

const DEBUG_WORLD_ACTION_TRACE := false


static func _trace_world_action_path(event_name: String, payload: Dictionary) -> void:
	if not DEBUG_WORLD_ACTION_TRACE:
		return
	print("[WorldActionPath:%s] %s" % [event_name, JSON.stringify(payload)])


static func normalize_world_action_id(action_id: String) -> String:
	match action_id.strip_edges().to_lower():
		"breach":
			return "break_breachable_wall"
		_:
			return action_id.strip_edges().to_lower()


static func get_facing_world_action_target(controller: Variant) -> Dictionary:
	return BipobTargetingServiceRef.build_action_target_context(controller)


static func get_facing_world_object(controller: Variant) -> Dictionary:
	return BipobTargetingServiceRef.get_facing_object(controller)


static func get_facing_world_item(controller: Variant) -> Dictionary:
	return BipobTargetingServiceRef.get_facing_item(controller)


static func build_runtime_action_actor(controller: Variant, target_object: Dictionary, target_position: Vector2i) -> Dictionary:
	return BipobRuntimeActionActorServiceRef.build_runtime_action_actor(controller, target_object, target_position)


static func build_runtime_action_view_model(controller: Variant, target_object: Dictionary, target_position: Vector2i) -> Dictionary:
	return BipobActionViewModelServiceRef.build_runtime_action_view_model(controller, target_object, target_position)


static func validate_runtime_action_view_model(view_model: Dictionary) -> Array[String]:
	var warnings: Array[String] = []
	var actions: Array = view_model.get("actions", [])
	var action_ids: Array[String] = []
	for action_variant in actions:
		if not action_variant is Dictionary:
			warnings.append("Action descriptor is not a dictionary.")
			continue
		var action: Dictionary = action_variant
		for required_field in ["id", "label", "enabled", "reason"]:
			if not action.has(required_field):
				warnings.append("Action descriptor missing %s." % required_field)
		var action_id: String = str(action.get("id", ""))
		if action_id.is_empty():
			warnings.append("Action descriptor has no executable id.")
		else:
			action_ids.append(action_id)
		if not bool(action.get("enabled", false)) and str(action.get("reason", "")).is_empty():
			warnings.append("Disabled action %s has no reason." % action_id)
	var primary_action_id: String = str(view_model.get("primary_action_id", ""))
	if not primary_action_id.is_empty() and not action_ids.has(primary_action_id):
		warnings.append("Primary action is absent from actions.")
	return warnings

static func _get_available_action_ids_from_target_data(target_data: Dictionary) -> Array[String]:
	var available_action_ids: Array[String] = []

	for action_id_variant in Array(target_data.get("available_action_ids", [])):
		var action_id: String = str(action_id_variant).strip_edges().to_lower()
		if not action_id.is_empty() and not available_action_ids.has(action_id):
			available_action_ids.append(action_id)

	return available_action_ids
	
static func set_selected_world_action(controller: Variant, action_id: String) -> void:
	action_id = normalize_world_action_id(action_id)
	var target_data: Dictionary = get_facing_world_action_target(controller)
	var available_action_ids: Array[String] = _get_available_action_ids_from_target_data(target_data)

	if action_id.is_empty() or available_action_ids.is_empty() or not available_action_ids.has(action_id):
		controller.selected_world_action = ""
		if not action_id.is_empty():
			controller.hint_requested.emit("Selected action is not available for this target.")
	else:
		controller.selected_world_action = action_id

	controller.emit_facing_world_object_hint()
	refresh_world_action_panel(controller)
	controller.status_changed.emit()


static func refresh_world_action_panel(controller: Variant) -> void:
	var target_data: Dictionary = get_facing_world_action_target(controller)
	var target_object: Dictionary = Dictionary(target_data.get("target_object", {}))
	var action_descriptors: Array = Array(target_data.get("actions", []))
	var available_action_ids: Array[String] = _get_available_action_ids_from_target_data(target_data)

	if target_object.is_empty():
		controller.selected_world_action = ""
		controller.world_action_panel_requested.emit({}, [], "")
		return

	if controller.selected_world_action.is_empty() or not available_action_ids.has(controller.selected_world_action):
		controller.selected_world_action = ""

	controller.world_action_panel_requested.emit(target_object, action_descriptors, controller.selected_world_action)
	
static func cycle_selected_world_action(controller: Variant) -> void:
	var target_data: Dictionary = get_facing_world_action_target(controller)
	var available_action_ids: Array[String] = _get_available_action_ids_from_target_data(target_data)

	if available_action_ids.is_empty():
		controller.selected_world_action = ""
		var view_model: Dictionary = Dictionary(target_data.get("action_view_model", {}))
		var unavailable_label: String = str(view_model.get("primary_action_label", ""))
		controller.hint_requested.emit(unavailable_label if not unavailable_label.is_empty() and unavailable_label != "Action" else "No available action for this object.")
		refresh_world_action_panel(controller)
		controller.status_changed.emit()
		return

	if controller.selected_world_action.is_empty() or not available_action_ids.has(controller.selected_world_action):
		controller.selected_world_action = available_action_ids[0]
	else:
		var selected_action_index: int = available_action_ids.find(controller.selected_world_action)
		controller.selected_world_action = available_action_ids[(selected_action_index + 1) % available_action_ids.size()]

	controller.emit_facing_world_object_hint()
	refresh_world_action_panel(controller)
	controller.status_changed.emit()

static func clear_selected_world_action_if_invalid(controller: Variant, target_object: Dictionary, target_position: Vector2i) -> void:
	if target_object.is_empty():
		controller.selected_world_action = ""
		return
	var view_model: Dictionary = build_runtime_action_view_model(controller, target_object, target_position)
	var actions: Array = Array(view_model.get("raw_action_ids", []))
	if actions.is_empty() or not actions.has(controller.selected_world_action):
		controller.selected_world_action = ""


static func get_world_object_action_for_context(controller: Variant, world_object: Dictionary, target_position: Vector2i) -> String:
	controller.selected_world_action = normalize_world_action_id(controller.selected_world_action)
	var view_model: Dictionary = build_runtime_action_view_model(controller, world_object, target_position)
	var actions: Array = Array(view_model.get("raw_action_ids", []))
	if not controller.selected_world_action.is_empty() and actions.has(controller.selected_world_action):
		if not _is_connector_workflow_action(controller.selected_world_action, world_object) or bool(controller.allow_connector_workflow_action_once):
			return controller.selected_world_action
	for action_variant in actions:
		var action_id: String = str(action_variant)
		if not _is_connector_workflow_action(action_id, world_object):
			return action_id
	return ""


static func _is_connector_workflow_action(action_id: String, world_object: Dictionary = {}) -> bool:
	if action_id == "activate_platform" and str(world_object.get("object_group", "")) == "platform":
		return false
	return action_id in ["connect", "scan", "hack", "download", "activate_platform", "open_door", "close_door", "unlock_door", "apply_digital_key", "input_password"] or action_id.begins_with("access_code_")


static func _is_terminal_control_action(action_id: String) -> bool:
	if action_id in ["open_door", "close_door", "unlock_door"]:
		return true
	return BipobTerminalControlExecutionServiceRef.is_terminal_platform_control_action(action_id)


static func handle_runtime_action_interact(controller: Variant, target_position: Vector2i, _target_tile: int) -> bool:
	if controller.mission_manager == null:
		return false
	var active_manipulator: Variant = controller.get_best_manipulator_for_interaction(target_position)
	var action_target_context: Dictionary = BipobTargetingServiceRef.build_action_target_context(controller)
	var context_target_object: Dictionary = Dictionary(action_target_context.get("target_object", {}))
	var context_target_position: Vector2i = Vector2i(action_target_context.get("target_position", target_position))
	var using_platform_context: bool = str(context_target_object.get("object_group", "")) == "platform" and Array(action_target_context.get("available_action_ids", [])).has("activate_platform")
	if using_platform_context:
		target_position = context_target_position
	if not using_platform_context:
		var pickup_execution: Dictionary = BipobItemPickupExecutionServiceRef.try_pickup_adjacent_or_current_item(controller, target_position, active_manipulator)
		if bool(pickup_execution.get("handled", false)):
			_apply_pickup_execution(controller, pickup_execution, target_position)
			return true

	var initial_world_object: Dictionary = context_target_object if using_platform_context else Dictionary(controller.mission_manager.get_world_object_at_cell(target_position))
	var world_object: Dictionary = context_target_object if using_platform_context else BipobTargetingServiceRef.resolve_runtime_action_target_for_cell(controller, target_position, initial_world_object)
	_trace_world_action_path("target_lookup", {"target_position": target_position, "actor_cell": controller.grid_position, "initial_object_id": str(initial_world_object.get("id", "")), "resolved_object_id": str(world_object.get("id", "")), "object_group": str(world_object.get("object_group", "")), "object_type": str(world_object.get("object_type", "")), "placement_mode": str(world_object.get("placement_mode", world_object.get("placement", ""))), "is_wall_mounted": bool(world_object.get("is_wall_mounted", false))})
	if world_object.is_empty():
		return false
	if controller.mission_manager.has_method("is_visual_only_floor_ground_object") and bool(controller.mission_manager.call("is_visual_only_floor_ground_object", world_object)):
		return false
	_execute_world_object_action(controller, world_object, target_position, active_manipulator)
	return true



static func _empty_direct_repair_target_context(reason: String = "No repair target.", target_position: Vector2i = Vector2i.ZERO) -> Dictionary:
	return {
		"available": false,
		"reason": reason,
		"target_kind": "",
		"target_object": {},
		"target_node": null,
		"target_position": target_position
	}


static func _variant_has_property(value: Variant, property_name: String) -> bool:
	if value is Dictionary:
		return Dictionary(value).has(property_name)
	if value is Object:
		for property_info in Array(value.get_property_list()):
			if not property_info is Dictionary:
				continue
			if str(Dictionary(property_info).get("name", "")) == property_name:
				return true
	return false


static func _variant_get_property(value: Variant, property_name: String, default_value: Variant = null) -> Variant:
	if value is Dictionary:
		return Dictionary(value).get(property_name, default_value)
	if value is Object and _variant_has_property(value, property_name):
		return value.get(property_name)
	return default_value


static func _variant_set_property(value: Variant, property_name: String, property_value: Variant) -> void:
	if value is Dictionary:
		value[property_name] = property_value
	elif value is Object and _variant_has_property(value, property_name):
		value.set(property_name, property_value)


static func _variant_has_any_property(value: Variant, property_names: Array[String]) -> bool:
	for property_name in property_names:
		if _variant_has_property(value, property_name):
			return true
	return false


static func _variant_number_below_max(value: Variant, current_property: String, max_property: String) -> bool:
	if not _variant_has_property(value, current_property) or not _variant_has_property(value, max_property):
		return false
	var current_value: Variant = _variant_get_property(value, current_property, 0)
	var max_value: Variant = _variant_get_property(value, max_property, 0)
	if typeof(current_value) != TYPE_INT and typeof(current_value) != TYPE_FLOAT:
		return false
	if typeof(max_value) != TYPE_INT and typeof(max_value) != TYPE_FLOAT:
		return false
	return float(current_value) < float(max_value)


static func _is_repairable_target_data(value: Variant) -> bool:
	if bool(_variant_get_property(value, "broken", false)):
		return true
	if bool(_variant_get_property(value, "is_broken", false)):
		return true
	if bool(_variant_get_property(value, "damaged", false)):
		return true
	if bool(_variant_get_property(value, "cut", false)):
		return true
	var state_text: String = str(_variant_get_property(value, "state", "")).strip_edges().to_lower()
	if state_text in ["broken", "damaged", "destroyed"]:
		return true
	var cable_health_text: String = str(_variant_get_property(value, "cable_health_state", "")).strip_edges().to_lower()
	if cable_health_text in ["broken", "damaged"]:
		return true
	var health_text: String = str(_variant_get_property(value, "health_state", "")).strip_edges().to_lower()
	if health_text in ["broken", "damaged"]:
		return true
	if _variant_number_below_max(value, "durability_current", "durability_max"):
		return true
	if _variant_number_below_max(value, "health_current", "health_max"):
		return true
	if _variant_number_below_max(value, "hp_current", "hp_max"):
		return true
	return false


static func _has_bipob_repair_state(value: Variant) -> bool:
	return _variant_has_any_property(value, ["broken", "is_broken", "damaged", "cut", "state", "cable_health_state", "health_state", "durability_current", "durability_max", "health_current", "health_max", "hp_current", "hp_max"])


static func _find_bipob_at_cell(controller: Variant, target_position: Vector2i) -> Variant:
	if controller == null or not controller is Node:
		return null
	var tree: SceneTree = controller.get_tree()
	if tree == null or tree.root == null:
		return null
	var pending: Array[Node] = [tree.root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node != controller:
			var node_cell: Variant = null
			if node.has_method("get_grid_position"):
				node_cell = node.call("get_grid_position")
			elif _variant_has_property(node, "grid_position"):
				node_cell = node.get("grid_position")
			if typeof(node_cell) == TYPE_VECTOR2I and Vector2i(node_cell) == target_position:
				var node_name: String = str(node.name).strip_edges().to_lower()
				var script_resource: Variant = node.get_script()
				var script_path: String = script_resource.resource_path if script_resource is Resource else ""
				if node is BipobController or node_name.find("bipob") >= 0 or script_path.ends_with("bipob_controller.gd"):
					return node
		for child in node.get_children():
			if child is Node:
				pending.append(child)
	return null


static func _build_direct_repair_context(target_kind: String, reason: String, target_object: Dictionary, target_node: Variant, target_position: Vector2i, available: bool = true) -> Dictionary:
	return {
		"available": available,
		"reason": reason,
		"target_kind": target_kind,
		"target_object": target_object,
		"target_node": target_node,
		"target_position": target_position
	}


static func get_direct_repair_target_context(controller: Variant) -> Dictionary:
	if controller == null or controller.mission_manager == null:
		return _empty_direct_repair_target_context("No repair target.")
	var target_context: Dictionary = BipobTargetingServiceRef.build_action_target_context(controller)
	var target_position: Vector2i = Vector2i(target_context.get("target_position", controller.get_facing_device_position()))
	var target_object: Dictionary = Dictionary(target_context.get("target_object", {}))
	if target_object.is_empty():
		target_object = Dictionary(controller.mission_manager.get_world_object_at_cell(target_position))
		target_object = BipobTargetingServiceRef.resolve_runtime_action_target_for_cell(controller, target_position, target_object)
	if not target_object.is_empty():
		if _is_repairable_target_data(target_object):
			return _build_direct_repair_context("world_object", "Repair facing object.", target_object, null, target_position)
		return _build_direct_repair_context("world_object", "Target does not need repair.", target_object, null, target_position, false)
	var target_bipob: Variant = _find_bipob_at_cell(controller, target_position)
	if target_bipob != null:
		if _is_repairable_target_data(target_bipob):
			return _build_direct_repair_context("bipob", "Repair facing Bipob.", {}, target_bipob, target_position)
		if not _has_bipob_repair_state(target_bipob):
			return _build_direct_repair_context("bipob", "Repair facing Bipob.", {}, target_bipob, target_position)
		return _build_direct_repair_context("bipob", "Target does not need repair.", {}, target_bipob, target_position, false)
	return _empty_direct_repair_target_context("No repair target.", target_position)


static func _method_accepts_no_arguments(target: Object, method_name: String) -> bool:
	for method_info in Array(target.get_method_list()):
		if not method_info is Dictionary:
			continue
		var method: Dictionary = method_info
		if str(method.get("name", "")) != method_name:
			continue
		return Array(method.get("args", [])).is_empty()
	return false


static func _repair_bipob_target(target_bipob: Variant) -> void:
	if target_bipob == null:
		return
	if target_bipob is Object:
		for method_name in ["repair", "repair_damage", "repair_all_damage"]:
			if target_bipob.has_method(method_name) and _method_accepts_no_arguments(target_bipob, method_name):
				target_bipob.call(method_name)
				break
	_variant_set_property(target_bipob, "damaged", false)
	_variant_set_property(target_bipob, "broken", false)
	_variant_set_property(target_bipob, "is_broken", false)
	_variant_set_property(target_bipob, "health_state", "normal")
	var state_text: String = str(_variant_get_property(target_bipob, "state", "")).strip_edges().to_lower()
	if state_text in ["damaged", "broken"]:
		_variant_set_property(target_bipob, "state", "active")
	for current_max_pair in [["durability_current", "durability_max"], ["health_current", "health_max"], ["hp_current", "hp_max"]]:
		var current_property: String = str(current_max_pair[0])
		var max_property: String = str(current_max_pair[1])
		if _variant_has_property(target_bipob, current_property) and _variant_has_property(target_bipob, max_property):
			_variant_set_property(target_bipob, current_property, _variant_get_property(target_bipob, max_property, _variant_get_property(target_bipob, current_property, 0)))


static func try_direct_repair_facing_object(controller: Variant) -> bool:
	if controller == null or controller.mission_manager == null:
		return false
	if not controller.has_module_id("repair_v1"):
		controller.hint_requested.emit("Repair Tool required.")
		controller.status_changed.emit()
		return false
	var repair_context: Dictionary = get_direct_repair_target_context(controller)
	if not bool(repair_context.get("available", false)):
		controller.hint_requested.emit(str(repair_context.get("reason", "No repair target.")))
		controller.status_changed.emit()
		return false
	if not InteractionActionCostServiceRef.can_commit_gameplay_action(controller):
		controller.hint_requested.emit("Not enough action/energy.")
		controller.status_changed.emit()
		return false
	var target_kind: String = str(repair_context.get("target_kind", ""))
	var target_position: Vector2i = Vector2i(repair_context.get("target_position", controller.get_facing_device_position()))
	if target_kind == "bipob":
		_repair_bipob_target(repair_context.get("target_node", null))
		InteractionActionCostServiceRef.commit_gameplay_action(controller, {"success": true, "message": "Bipob repaired."})
		controller.selected_world_action = ""
		controller.hint_requested.emit("Bipob repaired.")
		controller.refresh_world_object_overlay()
		controller.update_threat_detection_preview()
		controller.emit_facing_world_object_hint()
		refresh_world_action_panel(controller)
		controller.status_changed.emit()
		return true
	var target_object: Dictionary = Dictionary(repair_context.get("target_object", {}))
	var object_type: String = str(target_object.get("object_type", target_object.get("type", ""))).strip_edges().to_lower()
	var updated: Dictionary = target_object.duplicate(true)
	var object_ids: Array[String] = [
		object_type,
		str(updated.get("type", "")).strip_edges().to_lower(),
		str(updated.get("archetype_id", "")).strip_edges().to_lower(),
		str(updated.get("map_constructor_prefab_id", "")).strip_edges().to_lower(),
		str(updated.get("prefab_id", "")).strip_edges().to_lower(),
		str(updated.get("item_type", "")).strip_edges().to_lower()
	]
	var is_power_cable: bool = false
	for object_id_value in object_ids:
		if object_id_value in ["power_cable", "cable", "cable_reel", "power_cable_reel"]:
			is_power_cable = true
			break
	if is_power_cable and controller.mission_manager.has_method("repair_power_cable"):
		var target_id: String = str(updated.get("id", "")).strip_edges()
		if not target_id.is_empty():
			var repair_result: Dictionary = Dictionary(controller.mission_manager.call("repair_power_cable", target_id, true))
			if bool(repair_result.get("success", false)):
				if controller.mission_manager.has_method("get_world_object_by_id"):
					var repaired: Dictionary = Dictionary(controller.mission_manager.call("get_world_object_by_id", target_id))
					if not repaired.is_empty():
						updated = repaired
				updated["state"] = "normal"
				updated["cable_health_state"] = "normal"
				updated["health_state"] = "normal"
				updated["broken"] = false
				updated["is_broken"] = false
				updated["damaged"] = false
				updated["cut"] = false
				InteractionActionCostServiceRef.commit_gameplay_action(controller, {"success": true, "message": "Cable repaired."})
				controller.selected_world_action = ""
				controller.hint_requested.emit("Cable repaired.")
				controller.refresh_world_object_overlay()
				controller.update_threat_detection_preview()
				controller.emit_facing_world_object_hint()
				refresh_world_action_panel(controller)
				controller.status_changed.emit()
				return true
	updated["broken"] = false
	updated["is_broken"] = false
	updated["damaged"] = false
	updated["cut"] = false
	updated["health_state"] = "normal"
	if is_power_cable:
		updated["state"] = "normal"
		updated["cable_health_state"] = "normal"
	else:
		updated["state"] = "active"
	controller.mission_manager.set_world_object_at_cell(target_position, updated)
	if is_power_cable and controller.mission_manager.has_method("get_world_object_by_id"):
		var fallback_id: String = str(updated.get("id", "")).strip_edges()
		if not fallback_id.is_empty():
			var persisted: Dictionary = Dictionary(controller.mission_manager.call("get_world_object_by_id", fallback_id))
			if not persisted.is_empty():
				persisted["state"] = "normal"
				persisted["cable_health_state"] = "normal"
				persisted["health_state"] = "normal"
				persisted["broken"] = false
				persisted["is_broken"] = false
				persisted["damaged"] = false
				persisted["cut"] = false
	InteractionActionCostServiceRef.commit_gameplay_action(controller, {"success": true, "message": "Cable repaired." if is_power_cable else "Object repaired."})
	controller.selected_world_action = ""
	controller.hint_requested.emit("Cable repaired." if is_power_cable else "Object repaired.")
	controller.refresh_world_object_overlay()
	controller.update_threat_detection_preview()
	controller.emit_facing_world_object_hint()
	refresh_world_action_panel(controller)
	controller.status_changed.emit()
	return true


static func _apply_pickup_execution(controller: Variant, pickup_execution: Dictionary, target_position: Vector2i) -> void:
	if bool(pickup_execution.get("success", false)) and not InteractionActionCostServiceRef.commit_gameplay_action(controller, pickup_execution):
		controller.hint_requested.emit(str(pickup_execution.get("message", "Not enough action/energy.")))
		controller.status_changed.emit()
		return
	controller.hint_requested.emit(str(pickup_execution.get("message", "Pickup failed.")))
	if bool(pickup_execution.get("clear_selected_action", false)):
		clear_selected_world_action_if_invalid(controller, {}, Vector2i(pickup_execution.get("item_cell", target_position)))
	if bool(pickup_execution.get("refresh_threats", false)):
		controller.update_threat_detection_preview()
	if bool(pickup_execution.get("emit_facing_hint", false)):
		controller.emit_facing_world_object_hint()
	if bool(pickup_execution.get("refresh_action_panel", false)):
		refresh_world_action_panel(controller)
	if bool(pickup_execution.get("emit_status", true)):
		controller.status_changed.emit()


static func _execute_world_object_action(controller: Variant, world_object: Dictionary, target_position: Vector2i, _active_manipulator: Variant) -> void:
	var target_platform: Dictionary = Dictionary(controller.mission_manager.get_platform_for_cell(target_position))
	if str(world_object.get("object_group", "")) == "platform":
		target_platform = world_object
	var actor: Dictionary = build_runtime_action_actor(controller, world_object, target_position)
	actor["platform_switch_access"] = controller.mission_manager.can_bipob_access_platform_switch(target_platform, controller.grid_position, controller.get_direction_id(controller.direction))
	var raw_action_ids: Array[String] = controller.get_available_world_actions(world_object, target_position)
	var action_id: String = normalize_world_action_id(get_world_object_action_for_context(controller, world_object, target_position))
	controller.allow_connector_workflow_action_once = false
	var module: Dictionary = Dictionary(controller.get_world_action_module(action_id, world_object))
	var action_gate: Dictionary = InteractionSystemRef.can_apply_action(actor, module, world_object, action_id) if not action_id.is_empty() else {"success": false, "reason": "empty_action"}
	_trace_world_action_path("action_gate", {"target_object_id": str(world_object.get("id", "")), "object_group": str(world_object.get("object_group", "")), "object_type": str(world_object.get("object_type", "")), "placement_mode": str(world_object.get("placement_mode", world_object.get("placement", ""))), "is_wall_mounted": bool(world_object.get("is_wall_mounted", false)), "target_position": target_position, "actor_cell": controller.grid_position, "raw_action_ids": raw_action_ids, "selected_action_id": action_id, "module_id": str(module.get("id", "")), "can_apply_success": bool(action_gate.get("success", false)), "can_apply_reason": str(action_gate.get("reason", ""))})
	if action_id.is_empty():
		_emit_no_action_available(controller, world_object, target_position)
		return
	if not bool(action_gate.get("success", false)):
		controller.hint_requested.emit(str(action_gate.get("message", "Action unavailable.")))
		controller.status_changed.emit()
		return
	if str(world_object.get("object_group", "")) == "terminal" and (action_id == "hack" or action_id == "activate_platform") and not controller._is_terminal_powered_for_interaction(world_object):
		controller.hint_requested.emit("Terminal is unpowered.")
		controller.status_changed.emit()
		return
	if str(world_object.get("object_group", "")) == "platform":
		if str(world_object.get("state", "active")) in ["unpowered", "disabled"] or not bool(world_object.get("is_powered", true)):
			controller.hint_requested.emit("Platform is unpowered.")
			controller.status_changed.emit()
			return
	if action_id == "break_breachable_wall":
		_apply_breachable_wall_execution(controller, world_object, target_position, actor, module, action_id)
		return
	if controller.mission_manager.has_method("build_device_interaction_preflight"):
		var preflight_variant: Variant = controller.mission_manager.call("build_device_interaction_preflight", world_object, target_position, action_id, actor)
		if typeof(preflight_variant) == TYPE_DICTIONARY:
			var preflight: Dictionary = preflight_variant

			if not bool(preflight.get("preflight_ok", false)):
				controller.hint_requested.emit(str(preflight.get("message", "Action unavailable.")))
				controller.status_changed.emit()
				return
	if str(world_object.get("object_group", "")) == "platform" and action_id in ["activate_platform", "raise_platform", "lower_platform", "rotate_platform_left", "rotate_platform_right"]:
		_apply_platform_control_execution(controller, world_object, target_position, actor, module, action_id)
		return
	if str(world_object.get("object_group", "")) == "terminal" and _is_terminal_control_action(action_id):
		_apply_terminal_control_execution(controller, world_object, target_position, action_id)
		return
	if action_id in ["push", "pull"] and WorldObjectCatalogRef.can_world_object_be_moved_by_heavy_claw(world_object):
		_apply_heavy_claw_execution(controller, world_object, target_position, actor, module, action_id)
		return
	_apply_world_execution(controller, world_object, target_position, actor, module, action_id)


static func _emit_no_action_available(controller: Variant, world_object: Dictionary, target_position: Vector2i) -> void:
	var unavailable_view_model: Dictionary = build_runtime_action_view_model(controller, world_object, target_position)
	var unavailable_label: String = str(unavailable_view_model.get("primary_action_label", ""))
	if WorldObjectCatalogRef.can_world_object_be_moved_by_heavy_claw(world_object) and not controller.has_heavy_claw_capability():
		controller.hint_requested.emit("Heavy Claw required.")
	elif not unavailable_label.is_empty() and unavailable_label != "Action":
		controller.hint_requested.emit(unavailable_label)
	else:
		controller.hint_requested.emit("No available action for this object.")
	controller.status_changed.emit()


static func _apply_terminal_control_execution(controller: Variant, world_object: Dictionary, target_position: Vector2i, action_id: String) -> void:
	var terminal_execution: Dictionary = BipobTerminalControlExecutionServiceRef.execute_terminal_control_action(controller, world_object, target_position, action_id)
	controller.hint_requested.emit(str(terminal_execution.get("message", "Terminal control unavailable.")))
	if bool(terminal_execution.get("refresh_action_panel", true)):
		refresh_world_action_panel(controller)
	if bool(terminal_execution.get("emit_status", true)):
		controller.status_changed.emit()


static func _apply_platform_control_execution(controller: Variant, world_object: Dictionary, target_position: Vector2i, _actor: Dictionary, _module: Dictionary, action_id: String) -> void:
	var platform_execution: Dictionary = BipobPlatformControlExecutionServiceRef.execute_platform_control_action(controller, world_object, target_position, action_id)
	if bool(platform_execution.get("success", false)) and bool(platform_execution.get("pending_paid_action", false)):
		InteractionActionCostServiceRef.commit_gameplay_action(controller, platform_execution)
	controller.hint_requested.emit(str(platform_execution.get("message", "Platform control unavailable.")))
	if bool(platform_execution.get("clear_selected_action", false)):
		controller.selected_world_action = ""
	_apply_action_execution_refresh(controller, platform_execution)


static func _apply_breachable_wall_execution(controller: Variant, world_object: Dictionary, target_position: Vector2i, actor: Dictionary, module: Dictionary, action_id: String) -> void:
	var working_object: Dictionary = world_object.duplicate(true)
	var action_result: Dictionary = InteractionSystemRef.normalize_action_result(Dictionary(InteractionSystemRef.apply_action(actor, module, working_object, action_id)), working_object, action_id)
	if not bool(action_result.get("success", false)):
		controller.hint_requested.emit(str(action_result.get("message", "Action failed.")))
		controller.status_changed.emit()
		return
	if not InteractionActionCostServiceRef.can_commit_gameplay_action(controller):
		controller.hint_requested.emit("Not enough action/energy.")
		controller.status_changed.emit()
		return
	if controller.mission_manager == null or not controller.mission_manager.has_method("break_breachable_wall_at_cell"):
		controller.hint_requested.emit("Breachable Wall clearing is unavailable.")
		controller.status_changed.emit()
		return
	var actor_cell: Vector2i = Vector2i(actor.get("actor_position", controller.grid_position))
	var break_result: Dictionary = Dictionary(controller.mission_manager.call("break_breachable_wall_at_cell", target_position, "heavy_claw", actor_cell))
	if not bool(break_result.get("ok", false)):
		controller.hint_requested.emit(str(break_result.get("message", "Cannot break wall.")))
		controller.status_changed.emit()
		return
	var wall_execution: Dictionary = {"success": true, "message": str(break_result.get("message", "Breachable Wall broken. Passage cleared."))}
	InteractionActionCostServiceRef.commit_gameplay_action(controller, wall_execution)
	controller.selected_world_action = ""
	controller.hint_requested.emit(str(break_result.get("message", "Breachable Wall broken. Passage cleared.")))
	controller.refresh_world_object_overlay()
	controller.update_threat_detection_preview()
	controller.emit_facing_world_object_hint()
	refresh_world_action_panel(controller)
	controller.status_changed.emit()


static func _apply_heavy_claw_execution(controller: Variant, world_object: Dictionary, target_position: Vector2i, actor: Dictionary, module: Dictionary, action_id: String) -> void:
	var working_object: Dictionary = world_object.duplicate(true)
	var claw_action_result: Dictionary = InteractionSystemRef.normalize_action_result(Dictionary(InteractionSystemRef.apply_action(actor, module, working_object, action_id)), working_object, action_id)
	if not bool(claw_action_result.get("success", false)):
		controller.hint_requested.emit(str(claw_action_result.get("message", "Action failed.")))
		controller.status_changed.emit()
		return
	if not InteractionActionCostServiceRef.can_commit_gameplay_action(controller):
		controller.hint_requested.emit("Not enough action/energy.")
		controller.status_changed.emit()
		return
	var claw_execution: Dictionary = BipobHeavyClawExecutionServiceRef.execute_heavy_claw_action(controller, world_object, target_position, action_id)
	controller.hint_requested.emit(str(claw_execution.get("message", "Cannot move object there.")))
	_apply_action_execution_refresh(controller, claw_execution)


static func _apply_world_execution(controller: Variant, world_object: Dictionary, target_position: Vector2i, actor: Dictionary, module: Dictionary, action_id: String) -> void:
	var world_execution: Dictionary = BipobWorldObjectExecutionServiceRef.execute_world_object_action(controller, world_object, target_position, actor, module, action_id)
	if bool(world_execution.get("clear_selected_action", false)):
		clear_selected_world_action_if_invalid(controller, Dictionary(world_execution.get("world_object", world_object)), target_position)
	BipobWorldObjectExecutionServiceRef.finalize_world_object_action(controller, world_execution)
	controller.hint_requested.emit(str(world_execution.get("message", "Action failed.")))
	_apply_action_execution_refresh(controller, world_execution)


static func _apply_action_execution_refresh(controller: Variant, execution: Dictionary) -> void:
	if bool(execution.get("refresh_overlay", false)):
		controller.refresh_world_object_overlay()
	if bool(execution.get("refresh_threats", false)):
		controller.update_threat_detection_preview()
	if bool(execution.get("emit_facing_hint", false)):
		controller.emit_facing_world_object_hint()
	if bool(execution.get("refresh_action_panel", false)):
		refresh_world_action_panel(controller)
	if bool(execution.get("emit_status", true)):
		controller.status_changed.emit()
