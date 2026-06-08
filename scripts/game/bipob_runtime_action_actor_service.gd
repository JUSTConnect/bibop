extends RefCounted
class_name BipobRuntimeActionActorService


static func build_runtime_action_actor(controller: Variant, target_object: Dictionary, target_position: Vector2i) -> Dictionary:
	var inventory_state: Dictionary = controller.get_inventory_state() if controller != null and controller.has_method("get_inventory_state") else {}
	var pocket_items: Array = Array(inventory_state.get("pocket_items", []))
	var pocket_capacity: int = controller.get_available_pocket_slots() if controller != null and controller.has_method("get_available_pocket_slots") else pocket_items.size()
	var has_free_pocket_slot: bool = false
	for slot_index in range(pocket_capacity):
		if slot_index >= pocket_items.size() or controller._runtime_inventory_value_id(pocket_items[slot_index]).is_empty():
			has_free_pocket_slot = true
			break
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
		"range_to_target": 1,
		"is_straight_line": true,
		"magnetic_path_blocked": false,
		"target_is_grate": target_object.get("object_type", "") == "grate_wall",
		"facing_direction": controller.get_direction_vector(controller.direction),
		"target_position": target_position,
		"actor_position": controller.grid_position,
		"collected_key_ids": controller.get_collected_runtime_key_ids()
	}
