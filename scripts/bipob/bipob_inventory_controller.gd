extends RefCounted
class_name BipobInventoryController


static func can_use_physical_hand(controller: Variant) -> bool:
	if controller.is_hand_occupied() or (not controller.buffer_item.is_empty() and not controller._is_digital_storage_item(controller.buffer_item)):
		return false
	if controller.mission_manager != null and controller.mission_manager.has_method("get_inventory_state"):
		var inventory: Dictionary = Dictionary(controller.mission_manager.call("get_inventory_state"))
		if not controller._runtime_inventory_value_id(inventory.get("manipulator_hold", "")).is_empty():
			return false
	return true


static func has_held_physical_item(controller: Variant) -> bool:
	return controller._get_first_occupied_manipulator_index() != -1


static func get_held_item_display_name(controller: Variant) -> String:
	var active_index: int = controller._get_first_occupied_manipulator_index()
	if active_index == -1:
		return "empty"
	return controller.get_module_display_name(controller.manipulator_items[active_index])


static func infer_digital_item_family(_controller: Variant, item_type: String) -> String:
	if item_type.begins_with("digital_key"):
		return "digital_key"
	if item_type.begins_with("data_file"):
		return "data_file"
	return item_type


static func store_digital_record(controller: Variant, record_id: String, display_name: String, description: String = "") -> void:
	if record_id.is_empty():
		return

	if controller.digital_storage_capacity <= 0:
		controller.digital_storage.clear()
		controller.status_changed.emit()
		return

	var record := {
		"id": record_id,
		"display_name": display_name,
		"description": description,
	}

	if controller.digital_storage.has(record_id):
		controller.digital_storage[record_id] = record
		controller.hint_requested.emit("Digital record updated: " + get_digital_record_display_name(controller, record_id))
		controller.status_changed.emit()
		return

	if controller.digital_storage.size() < controller.digital_storage_capacity:
		controller.digital_storage[record_id] = record
		controller.hint_requested.emit("Digital record stored: " + display_name)
		controller.status_changed.emit()
		return

	if controller.digital_storage.size() >= controller.digital_storage_capacity:
		var existing_record_id := String(controller.digital_storage.keys()[0])
		var old_display_name := get_digital_record_display_name(controller, existing_record_id)
		controller.digital_storage.erase(existing_record_id)
		controller.digital_storage[record_id] = record
		controller.hint_requested.emit("Digital storage overwritten: " + old_display_name + " -> " + display_name)
		controller.status_changed.emit()
		return


static func get_first_digital_record_display_name(controller: Variant) -> String:
	if controller.digital_storage.is_empty():
		return "empty"

	var first_record_id := String(controller.digital_storage.keys()[0])
	return get_digital_record_display_name(controller, first_record_id)


static func has_digital_record(controller: Variant, record_id: String) -> bool:
	return controller.digital_storage.has(record_id)


static func use_digital_record(controller: Variant, record_id: String) -> bool:
	return has_digital_record(controller, record_id)


static func get_digital_record_display_name(controller: Variant, record_id: String) -> String:
	if not controller.digital_storage.has(record_id):
		return record_id

	var record_data: Variant = controller.digital_storage.get(record_id, {})
	if typeof(record_data) != TYPE_DICTIONARY:
		return record_id

	var record_dict: Dictionary = record_data
	if record_dict.has("display_name"):
		var resolved_display_name := String(record_dict.get("display_name", ""))
		if not resolved_display_name.is_empty():
			return resolved_display_name

	return record_id


static func get_digital_record_display_text(controller: Variant, record_id: String = "") -> String:
	if record_id.is_empty():
		return get_digital_storage_text(controller)
	return get_digital_record_display_name(controller, record_id)


static func get_digital_storage_text(controller: Variant) -> String:
	if controller.digital_storage.is_empty():
		return "Digital storage: empty"

	var lines := ["Digital storage:"]
	for record_id in controller.digital_storage.keys():
		lines.append("- " + get_digital_record_display_name(controller, String(record_id)))
	return "\n".join(lines)


static func drop_held_item(controller: Variant) -> void:
	if controller.mission_finished:
		return
	if controller.is_legacy_mission7_cable_drag_active():
		controller.release_mission7_cable_end()
		return

	if controller.mission_manager != null and controller.mission_manager.has_method("get_inventory_state"):
		var inventory: Dictionary = Dictionary(controller.mission_manager.call("get_inventory_state"))
		var held_world_item_id: String = controller._runtime_inventory_value_id(inventory.get("manipulator_hold", ""))
		if not held_world_item_id.is_empty():
			var target_cell: Vector2i = _get_runtime_inventory_drop_cell(controller)
			if target_cell == Vector2i(-1, -1):
				controller.hint_requested.emit("Cannot drop item here. Leave the doorway or face an empty floor cell.")
				controller.status_changed.emit()
				return
			if not controller.can_spend_action(1, 1):
				return
			var drop_result: Dictionary = Dictionary(controller.mission_manager.call("drop_inventory_item", held_world_item_id, target_cell))
			if not bool(drop_result.get("success", false)):
				controller.hint_requested.emit("Cannot drop item here.")
				controller.status_changed.emit()
				return
			controller.spend_action(1, 1)
			controller.hint_requested.emit("Dropped: %s." % held_world_item_id)
			controller.status_changed.emit()
			return

	var active_index := controller._get_first_occupied_manipulator_index()
	if active_index == -1:
		controller.hint_requested.emit("Hand is empty. Nothing to drop.")
		controller.status_changed.emit()
		return

	var target_position := controller.grid_position + controller.get_direction_vector(controller.direction)
	if not controller.grid_manager.is_in_bounds(target_position) or controller.grid_manager.get_tile(target_position) != GridManager.TILE_FLOOR:
		controller.hint_requested.emit("Cannot drop item here. Face an empty floor cell.")
		controller.status_changed.emit()
		return

	if not controller.can_spend_action(1, 1):
		return

	var module_to_drop = controller.manipulator_items[active_index]
	controller.set_field_module(target_position, module_to_drop)
	controller.spend_action(1, 1)
	controller.hint_requested.emit("Dropped: %s." % controller.get_module_display_name(module_to_drop))
	controller.manipulator_items[active_index] = null
	controller._sync_legacy_physical_slots()
	controller.status_changed.emit()


static func _is_empty_floor_cell_for_runtime_inventory_drop(controller: Variant, cell: Vector2i) -> bool:
	if controller.grid_manager == null or not controller.grid_manager.is_in_bounds(cell) or controller.grid_manager.get_tile(cell) != GridManager.TILE_FLOOR:
		return false
	if controller.mission_manager != null and controller.mission_manager.has_method("get_world_object_at_cell"):
		if not Dictionary(controller.mission_manager.call("get_world_object_at_cell", cell)).is_empty():
			return false
	if controller.mission_manager != null and controller.mission_manager.has_method("get_items_at_cell"):
		return Array(controller.mission_manager.call("get_items_at_cell", cell)).is_empty()
	return true


static func _get_runtime_inventory_drop_cell(controller: Variant) -> Vector2i:
	if controller.grid_manager == null or not controller.grid_manager.is_in_bounds(controller.grid_position):
		return Vector2i(-1, -1)
	var current_tile: int = controller.grid_manager.get_tile(controller.grid_position)
	if current_tile != GridManager.TILE_DOOR and current_tile != GridManager.TILE_DIGITAL_DOOR and current_tile != GridManager.TILE_POWERED_GATE:
		return controller.grid_position
	var direction_vector: Vector2i = controller.get_direction_vector(controller.direction)
	for candidate in [controller.grid_position + direction_vector, controller.grid_position - direction_vector]:
		if _is_empty_floor_cell_for_runtime_inventory_drop(controller, candidate):
			return candidate
	return Vector2i(-1, -1)
