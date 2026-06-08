extends RefCounted
class_name BipobRuntimeActionActorService


static func _runtime_inventory_value_id(controller: Variant, value: Variant) -> String:
	if controller != null and controller.has_method("_runtime_inventory_value_id"):
		return str(controller.call("_runtime_inventory_value_id", value)).strip_edges()
	if value is Dictionary:
		var dict_value: Dictionary = value
		return str(dict_value.get("id", dict_value.get("item_id", ""))).strip_edges()
	return str(value).strip_edges()


static func _get_runtime_item_data(inventory_state: Dictionary, item_id: String) -> Dictionary:
	if item_id.is_empty():
		return {}
	var runtime_map: Dictionary = Dictionary(inventory_state.get("world_item_runtime", {}))
	var runtime_row: Dictionary = Dictionary(runtime_map.get(item_id, {}))
	var item_data: Dictionary = Dictionary(runtime_row.get("item_data", {}))
	if item_data.is_empty() and not runtime_row.is_empty():
		item_data = runtime_row.duplicate(true)
	return item_data


static func _get_item_type_from_data(item_data: Dictionary, fallback_id: String = "") -> String:
	for field_name in ["item_type", "object_type", "item_class", "id", "item_id"]:
		var value: String = str(item_data.get(field_name, "")).strip_edges().to_lower()
		if value.is_empty():
			continue

		if value == "fuse" or value.contains("fuse"):
			return "fuse"

		if value == "cable_end" or value.contains("cable_end") or value.contains("wire_end"):
			return "cable_end"

		return value

	var fallback: String = fallback_id.strip_edges().to_lower()

	if fallback == "fuse" or fallback.contains("fuse"):
		return "fuse"

	if fallback == "cable_end" or fallback.contains("cable_end") or fallback.contains("wire_end"):
		return "cable_end"

	return fallback

static func _get_visible_held_item(controller: Variant, inventory_state: Dictionary) -> Dictionary:
	var held_id: String = _runtime_inventory_value_id(controller, inventory_state.get("manipulator_hold", ""))

	if not held_id.is_empty():
		var item_data: Dictionary = _get_runtime_item_data(inventory_state, held_id)
		var held_item_type: String = _get_item_type_from_data(item_data, held_id)

		if held_item_type == "fuse":
			item_data["item_type"] = "fuse"
			item_data["item_form"] = "physical"

		return {
			"held_item_id": held_id,
			"held_item_type": held_item_type,
			"held_item_data": item_data
		}

	if controller != null and controller.has_method("get_runtime_manipulator_items"):
		var visible_items_variant: Variant = controller.call("get_runtime_manipulator_items")
		if visible_items_variant is Array:
			for item_variant in Array(visible_items_variant):
				if item_variant == null:
					continue

				if item_variant is Dictionary:
					var item_dictionary: Dictionary = Dictionary(item_variant)
					var item_id: String = str(item_dictionary.get("id", item_dictionary.get("item_id", ""))).strip_edges()
					var item_type: String = _get_item_type_from_data(item_dictionary, item_id)

					if item_type == "fuse":
						item_dictionary["item_type"] = "fuse"
						item_dictionary["item_form"] = "physical"

					return {
						"held_item_id": item_id,
						"held_item_type": item_type,
						"held_item_data": item_dictionary
					}

				var object_id: String = ""
				var object_display_name: String = ""

				if "id" in item_variant:
					object_id = str(item_variant.id).strip_edges()
				if "display_name" in item_variant:
					object_display_name = str(item_variant.display_name).strip_edges()

				if not object_id.is_empty() or not object_display_name.is_empty():
					var inferred_type: String = object_id.strip_edges().to_lower()
					if inferred_type.is_empty():
						inferred_type = object_display_name.strip_edges().to_lower().replace(" ", "_")

					if inferred_type == "fuse" or inferred_type.contains("fuse"):
						inferred_type = "fuse"

					var inferred_data: Dictionary = {
						"id": object_id,
						"display_name": object_display_name,
						"item_type": inferred_type
					}

					if inferred_type == "fuse":
						inferred_data["item_form"] = "physical"

					return {
						"held_item_id": object_id,
						"held_item_type": inferred_type,
						"held_item_data": inferred_data
					}

	return {
		"held_item_id": "",
		"held_item_type": "",
		"held_item_data": {}
	}

static func get_visible_held_item(controller: Variant) -> Dictionary:
	if controller == null:
		return {"held_item_id": "", "held_item_type": "", "held_item_data": {}}
	var inventory_state: Dictionary = controller.get_inventory_state() if controller.has_method("get_inventory_state") else {}
	return _get_visible_held_item(controller, inventory_state)


static func get_visible_held_item_type(controller: Variant) -> String:
	return str(get_visible_held_item(controller).get("held_item_type", "")).strip_edges().to_lower()


static func has_visible_held_item_type(controller: Variant, item_type: String) -> bool:
	var normalized_item_type: String = item_type.strip_edges().to_lower()
	if normalized_item_type.is_empty():
		return false

	var held_item: Dictionary = get_visible_held_item(controller)
	var held_id: String = str(held_item.get("held_item_id", "")).strip_edges().to_lower()
	var held_type: String = str(held_item.get("held_item_type", "")).strip_edges().to_lower()
	var held_data: Dictionary = Dictionary(held_item.get("held_item_data", {}))

	if held_type == normalized_item_type:
		return true

	if normalized_item_type == "fuse":
		if held_id.contains("fuse"):
			return true
		if held_type.contains("fuse"):
			return true

	for field_name in ["item_type", "object_type", "item_class", "id", "item_id", "display_name"]:
		var value: String = str(held_data.get(field_name, "")).strip_edges().to_lower()
		if value == normalized_item_type:
			return true
		if normalized_item_type == "fuse" and value.contains("fuse"):
			return true

	return false


static func consume_visible_held_item_type(controller: Variant, item_type: String) -> bool:
	if controller == null:
		return false
	if controller.has_method("consume_held_world_item_if_type"):
		return bool(controller.call("consume_held_world_item_if_type", item_type))
	return false


static func build_runtime_action_actor(controller: Variant, target_object: Dictionary, target_position: Vector2i) -> Dictionary:
	var inventory_state: Dictionary = controller.get_inventory_state() if controller != null and controller.has_method("get_inventory_state") else {}
	
	var pocket_items: Array = Array(inventory_state.get("pocket_items", []))

	var pocket_capacity: int = 0
	if controller != null and controller.has_method("get_available_pocket_slots"):
		pocket_capacity = int(controller.call("get_available_pocket_slots"))

	if pocket_capacity <= 0:
		pocket_capacity = int(inventory_state.get("pocket_capacity", 0))

	if pocket_capacity <= 0:
		pocket_capacity = int(inventory_state.get("available_pocket_slots", 0))

	if pocket_capacity <= 0 and not pocket_items.is_empty():
		pocket_capacity = pocket_items.size()

	# Временный fallback: если UI уже показывает pocket slots, но конфиг не отдал capacity,
	# не даём gameplay считать, что карманов вообще нет.
	if pocket_capacity <= 0:
		pocket_capacity = 1

	var has_free_pocket_slot: bool = false
	for slot_index in range(pocket_capacity):
		if slot_index >= pocket_items.size():
			has_free_pocket_slot = true
			break

		var pocket_item_id: String = _runtime_inventory_value_id(controller, pocket_items[slot_index])
		if pocket_item_id.is_empty():
			has_free_pocket_slot = true
			break

	var manipulator_capacity: int = 0
	if controller != null and controller.has_method("get_available_manipulator_slots"):
		manipulator_capacity = int(controller.call("get_available_manipulator_slots"))

	if manipulator_capacity <= 0:
		var visible_manipulator_items: Array = []
		if controller != null and controller.has_method("get_runtime_manipulator_items"):
			visible_manipulator_items = Array(controller.call("get_runtime_manipulator_items"))
		if not visible_manipulator_items.is_empty():
			manipulator_capacity = visible_manipulator_items.size()

	if manipulator_capacity <= 0 and controller != null:
		if "manipulator_items" in controller:
			manipulator_capacity = Array(controller.manipulator_items).size()

	# Временный fallback: если в HUD есть манипулятор, gameplay не должен считать,
	# что манипулятора нет совсем.
	if manipulator_capacity <= 0:
		manipulator_capacity = 1

	var manipulator_hold_id: String = _runtime_inventory_value_id(controller, inventory_state.get("manipulator_hold", ""))
	var has_free_manipulator_slot: bool = manipulator_capacity > 0 and manipulator_hold_id.is_empty()
	var manipulator_occupied: bool = not manipulator_hold_id.is_empty()
	
	var held_item: Dictionary = _get_visible_held_item(controller, inventory_state)
	
	return {
		"manipulator_level": controller.get_installed_manipulator_arm_level(),
		"heavy_claw_level": controller.get_installed_heavy_claw_level(),
		"connector_level": maxi(controller.get_installed_connector_level("wired"), controller.get_installed_connector_level("optical")),
		"wired_connector_level": controller.get_installed_connector_level("wired"),
		"optical_connector_level": controller.get_installed_connector_level("optical"),
		"wireless_connector_level": controller.get_installed_connector_level("wireless"),
		"high_bandwidth_connector_level": controller.get_installed_connector_level("high_bandwidth"),
		"processor_level": controller.get_installed_processor_level(),
		"firewall_module_v1": controller.has_module_id("firewall_module_v1"),
		"power_class": controller.get_bipob_power_class(),
		"manipulator_occupied": manipulator_occupied,
		"pocket_full": not has_free_pocket_slot,
		"has_free_manipulator_slot": has_free_manipulator_slot,
		"has_free_pocket_slot": has_free_pocket_slot,
		"held_item_id": str(held_item.get("held_item_id", "")),
		"held_item_type": str(held_item.get("held_item_type", "")),
		"held_item_data": Dictionary(held_item.get("held_item_data", {})),
		"range_to_target": 1,
		"is_straight_line": true,
		"magnetic_path_blocked": false,
		"target_is_grate": target_object.get("object_type", "") == "grate_wall",
		"facing_direction": controller.get_direction_vector(controller.direction),
		"target_position": target_position,
		"actor_position": controller.grid_position,
		"collected_key_ids": controller.get_collected_runtime_key_ids()
	}
