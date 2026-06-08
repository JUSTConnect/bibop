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
	return str(item_data.get("item_type", item_data.get("object_type", item_data.get("id", fallback_id)))).strip_edges().to_lower()


static func _get_visible_held_item(controller: Variant, inventory_state: Dictionary) -> Dictionary:
	var held_id: String = _runtime_inventory_value_id(controller, inventory_state.get("manipulator_hold", ""))
	if not held_id.is_empty():
		var item_data: Dictionary = _get_runtime_item_data(inventory_state, held_id)
		return {
			"held_item_id": held_id,
			"held_item_type": _get_item_type_from_data(item_data, held_id),
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
					return {
						"held_item_id": item_id,
						"held_item_type": _get_item_type_from_data(item_dictionary, item_id),
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
					return {
						"held_item_id": object_id,
						"held_item_type": inferred_type,
						"held_item_data": {"id": object_id, "display_name": object_display_name, "item_type": inferred_type}
					}
	return {"held_item_id": "", "held_item_type": "", "held_item_data": {}}


static func build_runtime_action_actor(controller: Variant, target_object: Dictionary, target_position: Vector2i) -> Dictionary:
	var inventory_state: Dictionary = controller.get_inventory_state() if controller != null and controller.has_method("get_inventory_state") else {}
	var pocket_items: Array = Array(inventory_state.get("pocket_items", []))
	var pocket_capacity: int = controller.get_available_pocket_slots() if controller != null and controller.has_method("get_available_pocket_slots") else pocket_items.size()
	var has_free_pocket_slot: bool = false
	for slot_index in range(pocket_capacity):
		if slot_index >= pocket_items.size() or controller._runtime_inventory_value_id(pocket_items[slot_index]).is_empty():
			has_free_pocket_slot = true
			break
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
		"manipulator_occupied": not controller.can_use_physical_hand(),
		"pocket_full": not has_free_pocket_slot,
		"has_free_manipulator_slot": controller.can_use_physical_hand(),
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
