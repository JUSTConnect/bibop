extends RefCounted
class_name BipobActionViewModelService

const InteractionSystemRef = preload("res://scripts/world/interaction_system.gd")
const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")


static func build_runtime_action_view_model(controller: Variant, target_object: Dictionary, target_position: Vector2i) -> Dictionary:
	var normalized_target: Dictionary = WorldObjectCatalogRef.normalize_world_object_contract(target_object)
	if String(normalized_target.get("object_group", "")) == "door":
		normalized_target = WorldObjectCatalogRef.normalize_door_contract(normalized_target)
		normalized_target = WorldObjectCatalogRef.normalize_door_state_fields(normalized_target)
	var raw_action_ids: Array = []
	if not normalized_target.is_empty():
		raw_action_ids = controller.get_available_world_actions(normalized_target, target_position)
	var action_ids: Array[String] = []
	for action_id_variant in raw_action_ids:
		var action_id: String = String(action_id_variant)
		if not action_id.is_empty():
			action_ids.append(action_id)
	var group: String = String(normalized_target.get("object_group", ""))
	var state: String = String(normalized_target.get("state", ""))
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
	var target_id: String = String(normalized_target.get("id", ""))
	var target_type: String = String(normalized_target.get("object_type", group))
	for action_id in action_ids:
		var module: Dictionary = controller.get_world_action_module(action_id, normalized_target)
		var gate: Dictionary = InteractionSystemRef.can_apply_action(actor, module, normalized_target, action_id)
		var enabled: bool = bool(gate.get("success", false))
		var reason: String = String(gate.get("reason", "ok" if enabled else "action_unavailable"))
		var requires_free_manipulator: bool = _runtime_action_requires_free_manipulator(action_id, normalized_target)
		if enabled and requires_free_manipulator and not controller.can_use_physical_hand():
			enabled = false
			reason = "free_manipulator_required"
		if enabled and group == "terminal" and action_id in ["hack", "activate_platform"] and not controller._is_terminal_powered_for_interaction(normalized_target):
			enabled = false
			reason = "unpowered"
		var label: String = controller.get_world_action_display_label(action_id, normalized_target) if enabled else _runtime_action_disabled_label(controller, action_id, reason, normalized_target)
		descriptors.append({"id":action_id, "label":label, "enabled":enabled, "reason":reason, "target_id":target_id, "target_type":target_type, "target_cell":target_position, "source":"world_object", "priority":100, "requires_free_manipulator":requires_free_manipulator})
		if enabled:
			available_action_ids.append(action_id)
	var primary: Dictionary = {}
	for descriptor in descriptors:
		if bool(descriptor.get("enabled", false)):
			primary = descriptor
			break
	if primary.is_empty() and not descriptors.is_empty():
		primary = descriptors[0]
	var disabled_reason: String = String(primary.get("reason", "target_missing" if normalized_target.is_empty() else "no_available_action"))
	return {"target":normalized_target, "actions":descriptors, "available_action_ids":available_action_ids, "primary_action_id":String(primary.get("id", "")), "primary_action_label":String(primary.get("label", "Action")), "has_available_action":not available_action_ids.is_empty(), "disabled_reason":disabled_reason}


static func _runtime_action_requires_free_manipulator(action_id: String, target_object: Dictionary) -> bool:
	if action_id == "pickup":
		return WorldObjectCatalogRef.get_item_storage_class(target_object) == WorldObjectCatalogRef.ITEM_STORAGE_CLASS_PHYSICAL
	return action_id in ["open", "close", "unlock", "switch", "force_open", "push", "pull", "insert_fuse", "repair", "cut", "impact", "take_end_1", "take_end_2", "plug_in", "plug_out", "connect_wire_end", "connect_wire_1", "connect_wire_2", "disconnect_power_wire", "disconnect_wire_1", "disconnect_wire_2"]


static func _runtime_action_disabled_label(controller: Variant, action_id: String, reason: String, target_object: Dictionary) -> String:
	match reason:
		"key_card_required": return "Key-card required"
		"free_manipulator_required": return "Free manipulator required"
		"power_must_be_cut": return "Cut power to open"
		"terminal_control_required": return "Use linked terminal"
		"digital_access_required": return "Digital access required"
		"unpowered": return "Unpowered"
	return controller.get_world_action_display_label(action_id, target_object)
