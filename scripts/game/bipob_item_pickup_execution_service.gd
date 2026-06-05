extends RefCounted
class_name BipobItemPickupExecutionService


const InteractionSystemRef = preload("res://scripts/world/interaction_system.gd")
const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const InteractionActionCostServiceRef = preload("res://scripts/game/interaction/interaction_action_cost_service.gd")


static func try_pickup_adjacent_or_current_item(controller: Variant, target_position: Vector2i, active_manipulator: Variant) -> Dictionary:
	var item_cells: Array[Vector2i] = [controller.grid_position]
	if target_position != controller.grid_position:
		item_cells.append(target_position)
	for item_cell in item_cells:
		var cell_items: Array = controller.mission_manager.get_items_at_cell(item_cell)
		if cell_items.is_empty():
			continue
		var item: Dictionary = Dictionary(cell_items[0])
		var storage_class: String = WorldObjectCatalogRef.get_item_storage_class(item)
		var is_digital_item: bool = storage_class == WorldObjectCatalogRef.ITEM_STORAGE_CLASS_DIGITAL
		var requires_free_manipulator: bool = storage_class == WorldObjectCatalogRef.ITEM_STORAGE_CLASS_PHYSICAL
		var item_actor := {"manipulator_occupied": requires_free_manipulator and not controller.can_use_physical_hand()}
		var preflight_item: Dictionary = item.duplicate(true)
		var item_result: Dictionary = InteractionSystemRef.normalize_action_result(Dictionary(InteractionSystemRef.apply_action(item_actor, {"id": active_manipulator.id if active_manipulator != null else ""}, preflight_item, "pickup")), preflight_item, "pickup")
		if not bool(item_result.get("success", false)):
			return _build_result(false, str(item_result.get("message", "Pickup failed.")), item_cell, item, true, "pickup_failed")
		if not InteractionActionCostServiceRef.can_commit_gameplay_action(controller):
			return _build_result(false, "Not enough action/energy.", item_cell, item, true, "insufficient_resources")
		var item_id: String = str(item.get("id", ""))
		var pickup_result := {"success": true, "reasons": ["ok"], "item_id": item_id}
		if controller.mission_manager.has_method("pickup_world_item"):
			pickup_result = Dictionary(controller.mission_manager.call("pickup_world_item", item_id))
		if not bool(pickup_result.get("success", false)):
			var pickup_error_message: String = str(pickup_result.get("message", "Cannot pick up item: %s" % ", ".join(Array(pickup_result.get("reasons", [])))))
			return _build_result(false, pickup_error_message, item_cell, item, false, "world_item_pickup_failed")
		var message: String
		if is_digital_item:
			controller.buffer_item = item.duplicate(true)
			controller.buffer_item["item_form"] = "digital"
			var item_type := str(item.get("item_type", item.get("id", "")))
			var digital_state := str(item.get("digital_state", item.get("state", "opened")))
			var item_family := str(item.get("item_family", controller.infer_digital_item_family(item_type)))
			controller.digital_world_records[item_family] = {"item_family": item_family, "item_type": item_type, "digital_state": digital_state}
			message = "Pickup digital: item stored."
		else:
			var pickup_message: String = str(pickup_result.get("message", ""))
			if not pickup_message.is_empty():
				message = pickup_message
			else:
				message = "Picked up %s" % str(item.get("display_name", "item"))
		var result: Dictionary = _build_result(true, message, item_cell, item, true, "ok")
		result["clear_selected_action"] = true
		result["refresh_threats"] = true
		result["emit_facing_hint"] = true
		result["refresh_action_panel"] = true
		return result
	return {"handled": false}


static func _build_result(success: bool, message: String, item_cell: Vector2i, item: Dictionary, emit_status: bool, reason: String) -> Dictionary:
	return {
		"handled": true,
		"success": success,
		"message": message,
		"item_cell": item_cell,
		"item": item,
		"clear_selected_action": false,
		"refresh_threats": false,
		"emit_facing_hint": false,
		"refresh_action_panel": false,
		"emit_status": emit_status,
		"reason": reason
	}
