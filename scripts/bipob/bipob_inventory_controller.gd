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
		var existing_record_id := str(controller.digital_storage.keys()[0])
		var old_display_name := get_digital_record_display_name(controller, existing_record_id)
		controller.digital_storage.erase(existing_record_id)
		controller.digital_storage[record_id] = record
		controller.hint_requested.emit("Digital storage overwritten: " + old_display_name + " -> " + display_name)
		controller.status_changed.emit()
		return


static func get_first_digital_record_display_name(controller: Variant) -> String:
	if controller.digital_storage.is_empty():
		return "empty"

	var first_record_id := str(controller.digital_storage.keys()[0])
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
		var resolved_display_name := str(record_dict.get("display_name", ""))
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
		lines.append("- " + get_digital_record_display_name(controller, str(record_id)))
	return "\n".join(lines)


static func has_collected_runtime_key(controller: Variant, key_id: String) -> bool:
	if key_id.strip_edges().is_empty() or controller.mission_manager == null or not controller.mission_manager.has_method("has_collected_key"):
		return false
	return bool(controller.mission_manager.call("has_collected_key", key_id))


static func has_collected_mechanical_keycard(controller: Variant) -> bool:
	if controller.mission_manager != null and controller.mission_manager.has_method("has_keycard_access"):
		return bool(controller.mission_manager.call("has_keycard_access", "key_card"))
	if controller.mission_manager == null or not controller.mission_manager.has_method("get_inventory_state"):
		return false
	var inventory: Dictionary = controller.mission_manager.call("get_inventory_state")
	var runtime_map: Dictionary = inventory.get("world_item_runtime", {})
	var collected_key_ids: Array = inventory.get("collected_key_ids", [])
	for key_value in collected_key_ids:
		var key_id: String = str(key_value).strip_edges()
		var item_runtime: Dictionary = runtime_map.get(key_id, {})
		var item_data: Dictionary = item_runtime.get("item_data", {})
		if not item_data.has("key_kind") and item_runtime.has("key_kind"):
			item_data["key_kind"] = item_runtime.get("key_kind", "")
		if WorldObjectCatalog.is_key_card_item(item_data):
			return true
	return false


static func has_access_for_door(controller: Variant, world_object: Dictionary) -> bool:
	var access_type: String = WorldObjectCatalog.normalize_access_type(world_object.get("access_type", world_object.get("lock_type", "")))
	var required_key_id: String = str(world_object.get("required_key_id", "")).strip_edges()
	if access_type == WorldObjectCatalog.ACCESS_TYPE_NO_KEY or required_key_id.is_empty():
		return true
	return has_collected_runtime_key(controller, required_key_id)


static func get_collected_runtime_key_ids(controller: Variant) -> Array:
	if controller.mission_manager == null or not controller.mission_manager.has_method("get_inventory_state"):
		return []
	var inventory: Dictionary = Dictionary(controller.mission_manager.call("get_inventory_state"))
	return Array(inventory.get("collected_key_ids", []))


static func has_digital_world_item(controller: Variant, item_type: String, digital_state: String = "opened") -> bool:
	var record: Dictionary = controller.digital_world_records.get(item_type, {})
	if record.is_empty():
		return false
	return str(record.get("digital_state", "opened")) == digital_state


static func has_required_digital_key(controller: Variant, world_object: Dictionary) -> bool:
	var required_id: String = str(world_object.get("required_digital_key_id", "")).strip_edges()
	if required_id.is_empty():
		return has_digital_world_item(controller, "digital_key", "opened")
	if controller.digital_storage.has(required_id):
		return true
	if str(controller.buffer_item.get("id", controller.buffer_item.get("item_id", ""))).strip_edges() == required_id:
		return str(controller.buffer_item.get("digital_state", "opened")) == "opened"
	return false


static func get_available_manipulator_slots(controller: Variant) -> int:
	return clampi(controller.available_manipulator_slots, 0, get_max_manipulator_slots(controller))


static func get_max_manipulator_slots(controller: Variant) -> int:
	return controller.max_manipulator_slots


static func get_runtime_manipulator_items(controller: Variant) -> Array:
	var runtime_items: Array = []
	if controller.mission_manager != null and controller.mission_manager.has_method("get_manipulator_items"):
		var runtime_items_variant: Variant = controller.mission_manager.call("get_manipulator_items")
		if typeof(runtime_items_variant) == TYPE_ARRAY:
			runtime_items = runtime_items_variant
	if runtime_items.is_empty():
		for slot_index in range(get_available_manipulator_slots(controller)):
			runtime_items.append(controller.manipulator_items[slot_index])
	return runtime_items


static func get_available_pocket_slots(controller: Variant) -> int:
	return clampi(controller.available_pocket_slots, 0, get_max_pocket_slots(controller))


static func get_max_pocket_slots(controller: Variant) -> int:
	return controller.max_pocket_slots


static func get_available_digital_storage_slots(controller: Variant) -> int:
	return clampi(controller.available_digital_storage_slots, 0, get_max_digital_storage_slots(controller))


static func get_max_digital_storage_slots(controller: Variant) -> int:
	return controller.max_digital_storage_slots


static func get_digital_storage_items(controller: Variant) -> Array:
	var items: Array = []
	if controller.mission_manager != null and controller.mission_manager.has_method("get_inventory_state"):
		var inventory: Dictionary = Dictionary(controller.mission_manager.call("get_inventory_state"))
		var runtime_map: Dictionary = Dictionary(inventory.get("world_item_runtime", {}))
		for item_id_variant in Array(inventory.get("digital_storage", [])):
			var item_id: String = controller._runtime_inventory_value_id(item_id_variant)
			var runtime_row: Dictionary = Dictionary(runtime_map.get(item_id, {}))
			var item_data: Dictionary = Dictionary(runtime_row.get("item_data", {}))
			if item_data.is_empty():
				item_data = Dictionary(controller.digital_storage.get(item_id, {}))
			if not item_data.is_empty():
				items.append(item_data)
		if not items.is_empty():
			return items
	for storage_key in controller.digital_storage.keys():
		items.append(controller.digital_storage[storage_key])
	return items


static func get_buffer_item(controller: Variant) -> Variant:
	if not controller.buffer_item.is_empty():
		return controller.buffer_item
	if controller.mission_manager != null and controller.mission_manager.has_method("get_inventory_state"):
		var inventory: Dictionary = Dictionary(controller.mission_manager.call("get_inventory_state"))
		var buffer_items: Array = Array(inventory.get("digital_buffer", []))
		if not buffer_items.is_empty():
			var item_id: String = controller._runtime_inventory_value_id(buffer_items[0])
			var runtime_map: Dictionary = Dictionary(inventory.get("world_item_runtime", {}))
			var runtime_row: Dictionary = Dictionary(runtime_map.get(item_id, {}))
			var item_data: Dictionary = Dictionary(runtime_row.get("item_data", {}))
			if not item_data.is_empty():
				return item_data
	return null


static func is_digital_storage_item(_controller: Variant, item: Dictionary, allow_untyped_storage_record: bool = false) -> bool:
	var storage_class: String = WorldObjectCatalog.get_item_storage_class(item)
	if storage_class in [WorldObjectCatalog.ITEM_STORAGE_CLASS_PHYSICAL, WorldObjectCatalog.ITEM_STORAGE_CLASS_KEY_CARD]:
		return false
	if storage_class == WorldObjectCatalog.ITEM_STORAGE_CLASS_DIGITAL:
		return true
	var item_form: String = str(item.get("item_form", "")).strip_edges().to_lower()
	var item_type: String = str(item.get("item_type", item.get("id", ""))).strip_edges().to_lower()
	if item_form == "physical" or item_type in ["fuse", "repair_kit", "cable_end"] or item_type.contains("cable_end") or item_type.contains("wire_end"):
		return false
	for metadata_key in item.keys():
		var metadata_name: String = str(metadata_key).strip_edges().to_lower()
		if metadata_name in ["reel_id", "end_index"] or metadata_name.contains("cable") or metadata_name.contains("wire"):
			return false
	if item_form == "digital":
		return true
	if not item_form.is_empty():
		return false
	for field_name in ["item_type", "item_family", "digital_payload_type", "id"]:
		var digital_type: String = str(item.get(field_name, "")).strip_edges().to_lower()
		if digital_type.contains("route_data") or digital_type.contains("info_key") or digital_type.contains("data_file") or digital_type.contains("digital_key") or digital_type.contains("access_code"):
			return true
	return allow_untyped_storage_record


static func rotate_physical_storage(controller: Variant) -> void:
	if controller.mission_finished:
		return

	if not controller.has_any_physical_item():
		controller.hint_requested.emit("No physical items to rotate.")
		controller.status_changed.emit()
		return

	if not controller.can_spend_action(1, 0):
		return

	rotate_first_manipulator_and_pocket(controller)
	controller.spend_action(1, 0)
	controller.hint_requested.emit("Rotated physical storage.")
	controller.status_changed.emit()


static func move_buffer_to_first_free_storage(controller: Variant) -> Dictionary:
	if controller.buffer_item.is_empty():
		return {"ok": false, "message": "Buffer is empty."}
	if not is_digital_storage_item(controller, controller.buffer_item):
		return {"ok": false, "message": "This item cannot be stored in digital storage."}
	if controller.digital_storage.size() >= get_available_digital_storage_slots(controller):
		return {"ok": false, "message": "No free storage slot."}
	var record_id: String = str(controller.buffer_item.get("id", "")).strip_edges()
	if record_id.is_empty():
		return {"ok": false, "message": "Buffered record is unavailable."}
	if controller.digital_storage.has(record_id):
		return {"ok": false, "message": "Storage already contains this record."}
	controller.digital_storage[record_id] = controller.buffer_item.duplicate(true)
	controller.buffer_item.clear()
	if controller.mission_manager != null and controller.mission_manager.has_method("move_runtime_digital_buffer_to_storage"):
		controller.mission_manager.call("move_runtime_digital_buffer_to_storage", record_id)
	controller.status_changed.emit()
	return {"ok": true, "message": "Stored buffered digital record."}


static func move_or_swap_storage_slot_with_buffer(controller: Variant, storage_index: int) -> Dictionary:
	if storage_index < 0 or storage_index >= get_available_digital_storage_slots(controller):
		return {"ok": false, "message": "Storage slot is unavailable."}
	var storage_keys: Array = controller.digital_storage.keys()
	if storage_index >= storage_keys.size():
		if controller.buffer_item.is_empty():
			return {"ok": false, "message": "Storage slot is empty."}
		return move_buffer_to_first_free_storage(controller)
	var stored_record_id: Variant = storage_keys[storage_index]
	var stored_record_value: Variant = controller.digital_storage.get(stored_record_id, {})
	if typeof(stored_record_value) != TYPE_DICTIONARY:
		return {"ok": false, "message": "Storage slot is unavailable."}
	var stored_record: Dictionary = Dictionary(stored_record_value)
	if not is_digital_storage_item(controller, stored_record, true):
		return {"ok": false, "message": "Storage slot is unavailable."}
	if controller.buffer_item.is_empty():
		controller.buffer_item = stored_record.duplicate(true)
		controller.buffer_item["item_form"] = "digital"
		controller.digital_storage.erase(stored_record_id)
		if controller.mission_manager != null and controller.mission_manager.has_method("move_runtime_digital_storage_to_buffer"):
			controller.mission_manager.call("move_runtime_digital_storage_to_buffer", str(stored_record_id))
		controller.status_changed.emit()
		return {"ok": true, "message": "Loaded storage record into buffer."}
	if not is_digital_storage_item(controller, controller.buffer_item):
		return {"ok": false, "message": "This item cannot be stored in digital storage."}
	var buffered_record_id: String = str(controller.buffer_item.get("id", "")).strip_edges()
	if buffered_record_id.is_empty():
		return {"ok": false, "message": "Buffered record is unavailable."}
	if buffered_record_id != str(stored_record_id) and controller.digital_storage.has(buffered_record_id):
		return {"ok": false, "message": "Storage already contains this record."}
	var buffered_record: Dictionary = controller.buffer_item.duplicate(true)
	controller.digital_storage.erase(stored_record_id)
	controller.digital_storage[buffered_record_id] = buffered_record
	controller.buffer_item = stored_record.duplicate(true)
	controller.buffer_item["item_form"] = "digital"
	if controller.mission_manager != null and controller.mission_manager.has_method("swap_runtime_digital_buffer_and_storage"):
		controller.mission_manager.call("swap_runtime_digital_buffer_and_storage", buffered_record_id, str(stored_record_id))
	controller.status_changed.emit()
	return {"ok": true, "message": "Swapped buffer and storage records."}


static func move_manipulator_to_first_free_pocket(controller: Variant, manipulator_index: int) -> Dictionary:
	if manipulator_index == 0 and controller.mission_manager != null and controller.mission_manager.has_method("get_inventory_state"):
		var inventory: Dictionary = Dictionary(controller.mission_manager.call("get_inventory_state"))
		if not controller._runtime_inventory_value_id(inventory.get("manipulator_hold", "")).is_empty():
			var runtime_pocket: Array = Array(inventory.get("pocket_items", []))
			for pocket_index in range(get_available_pocket_slots(controller)):
				if pocket_index >= runtime_pocket.size() or controller._runtime_inventory_value_id(runtime_pocket[pocket_index]).is_empty():
					var result: Dictionary = Dictionary(controller.mission_manager.call("move_runtime_manipulator_to_pocket", pocket_index, get_available_pocket_slots(controller)))
					controller.status_changed.emit()
					return result
			return {"ok": false, "message": "No free pocket slot."}
	if manipulator_index < 0 or manipulator_index >= get_available_manipulator_slots(controller):
		return {"ok": false, "message": "Manipulator slot is unavailable."}
	if controller.manipulator_items[manipulator_index] == null:
		return {"ok": false, "message": "Manipulator is empty."}
	var free_index: int = get_first_free_pocket_index(controller)
	if free_index == -1:
		return {"ok": false, "message": "No free pocket slot."}
	controller.pocket_items[free_index] = controller.manipulator_items[manipulator_index]
	controller.manipulator_items[manipulator_index] = null
	sync_legacy_physical_slots(controller)
	controller.status_changed.emit()
	return {"ok": true, "message": "Stored manipulator item in pocket."}


static func move_or_swap_pocket_slot_with_manipulator(controller: Variant, pocket_index: int, manipulator_index: int) -> Dictionary:
	if manipulator_index == 0 and controller.mission_manager != null and controller.mission_manager.has_method("get_inventory_state"):
		var inventory: Dictionary = Dictionary(controller.mission_manager.call("get_inventory_state"))
		var runtime_pocket: Array = Array(inventory.get("pocket_items", []))
		var runtime_pocket_id: String = ""
		if pocket_index >= 0 and pocket_index < runtime_pocket.size():
			runtime_pocket_id = controller._runtime_inventory_value_id(runtime_pocket[pocket_index])
		if not controller._runtime_inventory_value_id(inventory.get("manipulator_hold", "")).is_empty() or not runtime_pocket_id.is_empty():
			var result: Dictionary = Dictionary(controller.mission_manager.call("move_or_swap_runtime_pocket_slot_with_manipulator", pocket_index, get_available_pocket_slots(controller)))
			controller.status_changed.emit()
			return result
	if pocket_index < 0 or pocket_index >= get_available_pocket_slots(controller):
		return {"ok": false, "message": "Pocket slot is unavailable."}
	if manipulator_index < 0 or manipulator_index >= get_available_manipulator_slots(controller):
		return {"ok": false, "message": "Manipulator slot is unavailable."}
	var pocket_item: BipobModule = controller.pocket_items[pocket_index]
	var manipulator_item: BipobModule = controller.manipulator_items[manipulator_index]
	if pocket_item == null and manipulator_item == null:
		return {"ok": false, "message": "Pocket slot is empty."}
	controller.pocket_items[pocket_index] = manipulator_item
	controller.manipulator_items[manipulator_index] = pocket_item
	sync_legacy_physical_slots(controller)
	controller.status_changed.emit()
	return {"ok": true, "message": "Moved or swapped pocket and manipulator items."}


static func move_digital_storage_to_buffer(controller: Variant, storage_index: int) -> bool:
	if not controller.buffer_item.is_empty():
		controller.hint_requested.emit("Digital buffer is occupied.")
		return false
	var storage_keys: Array = controller.digital_storage.keys()
	if storage_index < 0 or storage_index >= storage_keys.size():
		controller.hint_requested.emit("Storage slot is empty.")
		return false
	var record_id: Variant = storage_keys[storage_index]
	var record_data: Variant = controller.digital_storage.get(record_id, {})
	if typeof(record_data) != TYPE_DICTIONARY:
		controller.hint_requested.emit("Storage slot is unavailable.")
		return false
	var record_dictionary: Dictionary = Dictionary(record_data)
	if not is_digital_storage_item(controller, record_dictionary, true):
		controller.hint_requested.emit("Storage slot is unavailable.")
		return false
	controller.buffer_item = record_dictionary.duplicate(true)
	controller.buffer_item["item_form"] = "digital"
	controller.digital_storage.erase(record_id)
	if controller.mission_manager != null and controller.mission_manager.has_method("move_runtime_digital_storage_to_buffer"):
		controller.mission_manager.call("move_runtime_digital_storage_to_buffer", str(record_id))
	controller.hint_requested.emit("Loaded into digital buffer: %s." % str(controller.buffer_item.get("display_name", controller.buffer_item.get("id", "record"))))
	controller.status_changed.emit()
	return true


static func move_buffer_to_digital_storage(controller: Variant) -> bool:
	if controller.buffer_item.is_empty():
		controller.hint_requested.emit("Buffer is empty.")
		return false
	if not is_digital_storage_item(controller, controller.buffer_item):
		controller.hint_requested.emit("This item cannot be stored in digital storage.")
		return false
	if controller.digital_storage.size() >= get_available_digital_storage_slots(controller):
		controller.hint_requested.emit("No free digital storage slot.")
		return false
	var record_id: String = str(controller.buffer_item.get("id", "")).strip_edges()
	if record_id.is_empty():
		controller.hint_requested.emit("Buffered record is unavailable.")
		return false
	controller.digital_storage[record_id] = controller.buffer_item.duplicate(true)
	controller.buffer_item.clear()
	if controller.mission_manager != null and controller.mission_manager.has_method("move_runtime_digital_buffer_to_storage"):
		controller.mission_manager.call("move_runtime_digital_buffer_to_storage", record_id)
	controller.hint_requested.emit("Stored buffered digital record.")
	controller.status_changed.emit()
	return true


static func move_pocket_to_manipulator(controller: Variant, pocket_index: int) -> bool:
	if pocket_index < 0 or pocket_index >= get_available_pocket_slots(controller):
		return false
	if controller.pocket_items[pocket_index] == null:
		controller.hint_requested.emit("No pocket item selected.")
		return false
	var free_index: int = get_first_free_manipulator_index(controller)
	if free_index == -1:
		controller.hint_requested.emit("No free manipulator slot.")
		return false
	controller.manipulator_items[free_index] = controller.pocket_items[pocket_index]
	controller.pocket_items[pocket_index] = null
	sync_legacy_physical_slots(controller)
	controller.status_changed.emit()
	return true


static func move_manipulator_to_pocket(controller: Variant, manipulator_index: int) -> bool:
	if manipulator_index < 0 or manipulator_index >= get_available_manipulator_slots(controller):
		return false
	if controller.manipulator_items[manipulator_index] == null:
		controller.hint_requested.emit("No manipulator item selected.")
		return false
	var free_index: int = get_first_free_pocket_index(controller)
	if free_index == -1:
		controller.hint_requested.emit("No free pocket slot.")
		return false
	controller.pocket_items[free_index] = controller.manipulator_items[manipulator_index]
	controller.manipulator_items[manipulator_index] = null
	sync_legacy_physical_slots(controller)
	controller.status_changed.emit()
	return true


static func sync_legacy_physical_slots(controller: Variant) -> void:
	controller.held_module = controller.manipulator_items[0] if controller.manipulator_items.size() > 0 else null
	controller.stored_physical_module = controller.pocket_items[0] if controller.pocket_items.size() > 0 else null
	controller.physical_carry_capacity = get_available_manipulator_slots(controller) + get_available_pocket_slots(controller)


static func get_first_free_manipulator_index(controller: Variant) -> int:
	for slot_index in range(get_available_manipulator_slots(controller)):
		if controller.manipulator_items[slot_index] == null:
			return slot_index
	return -1


static func get_first_occupied_manipulator_index(controller: Variant) -> int:
	for slot_index in range(get_available_manipulator_slots(controller)):
		if controller.manipulator_items[slot_index] != null:
			return slot_index
	return -1


static func get_first_free_pocket_index(controller: Variant) -> int:
	for slot_index in range(get_available_pocket_slots(controller)):
		if controller.pocket_items[slot_index] == null:
			return slot_index
	return -1


static func get_first_occupied_pocket_index(controller: Variant) -> int:
	for slot_index in range(get_available_pocket_slots(controller)):
		if controller.pocket_items[slot_index] != null:
			return slot_index
	return -1


static func rotate_first_manipulator_and_pocket(controller: Variant) -> void:
	var hand_module: BipobModule = controller.manipulator_items[0]
	controller.manipulator_items[0] = controller.pocket_items[0]
	controller.pocket_items[0] = hand_module
	sync_legacy_physical_slots(controller)


static func drop_held_item(controller: Variant) -> void:
	if controller.mission_finished:
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

	var active_index: int = controller._get_first_occupied_manipulator_index()
	if active_index == -1:
		controller.hint_requested.emit("Hand is empty. Nothing to drop.")
		controller.status_changed.emit()
		return

	var target_position: Vector2i = controller.grid_position + controller.get_direction_vector(controller.direction)
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
