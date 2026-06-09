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
		if controller.has_method("classify_runtime_item"):
			is_digital_item = str(controller.call("classify_runtime_item", item)) == WorldObjectCatalogRef.ITEM_STORAGE_CLASS_DIGITAL
		if active_manipulator != null and str(active_manipulator.id).strip_edges() == "manipulator_heavy_claw_v1":
			return _build_result(false, "Heavy Claw cannot pick up items.", item_cell, item, true, "heavy_claw_cannot_pickup")
		var item_actor := {"manipulator_occupied": false}
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
		var message: String = str(pickup_result.get("message", ""))
		var routed_storage: String = str(pickup_result.get("storage", ""))
		if is_digital_item:
			var routed_item: Dictionary = Dictionary(pickup_result.get("item_data", item)).duplicate(true)
			routed_item["item_form"] = "digital"
			if routed_storage == "buffer":
				controller.buffer_item = routed_item
			elif routed_storage == "digital_storage":
				var routed_id: String = str(routed_item.get("id", item_id)).strip_edges()
				if not routed_id.is_empty():
					controller.digital_storage[routed_id] = routed_item
			var item_type := str(routed_item.get("item_type", routed_item.get("id", "")))
			var digital_state := str(routed_item.get("digital_state", routed_item.get("state", "opened")))
			var item_family := str(routed_item.get("item_family", controller.infer_digital_item_family(item_type)))
			controller.digital_world_records[item_family] = {"item_family": item_family, "item_type": item_type, "digital_state": digital_state}
			if message.is_empty():
				message = "Pickup digital: item stored."
		elif message.is_empty():
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
