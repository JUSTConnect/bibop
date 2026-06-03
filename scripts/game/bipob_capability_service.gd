extends RefCounted
class_name BipobCapabilityService


static func has_module_id(controller: Variant, module_id: String) -> bool:
	return controller.get_installed_module_by_id(module_id) != null


static func get_module_version_for_module_id(module_id: String) -> int:
	if module_id.contains("_v3"):
		return 3
	if module_id.contains("_v2"):
		return 2
	return 1


static func extract_module_level_by_prefix(controller: Variant, prefix: String) -> int:
	var best := 0
	for module in controller.installed_modules:
		if module == null:
			continue
		var module_id := str(module.id)
		if not module_id.begins_with(prefix):
			continue
		var version_regex: RegEx = RegEx.new()
		version_regex.compile("_v(\\d+)$")
		var found: RegExMatch = version_regex.search(module_id)
		if found != null:
			best = maxi(best, int(found.get_string(1)))
		elif module_id.ends_with("_v1"):
			best = maxi(best, 1)
	return best


static func get_installed_connector_level(controller: Variant, kind: String = "") -> int:
	var port_state: Dictionary = controller.preview_module_port_activity()
	var modules_state: Dictionary = Dictionary(port_state.get("modules", {}))
	var target_prefix := _get_connector_module_prefix_for_kind(kind)
	var best := 0
	for module in controller.installed_modules:
		if module == null:
			continue
		var module_id := str(module.id)
		if not module_id.contains("_connector_v"):
			continue
		if not target_prefix.is_empty() and not module_id.begins_with(target_prefix):
			continue
		var state: Dictionary = Dictionary(modules_state.get(module_id, {}))
		if not bool(state.get("active", false)):
			continue
		var version_regex: RegEx = RegEx.new()
		version_regex.compile("_v(\\d+)$")
		var found: RegExMatch = version_regex.search(module_id)
		if found != null:
			best = maxi(best, int(found.get_string(1)))
	return best


static func has_connector(controller: Variant, kind: String = "") -> bool:
	return get_installed_connector_level(controller, kind) > 0


static func has_manipulator_arm(controller: Variant) -> bool:
	return extract_module_level_by_prefix(controller, "manipulator_arm") > 0


static func has_heavy_claw_capability(controller: Variant) -> bool:
	if controller.has_command("heavy_claw"):
		return true
	return extract_module_level_by_prefix(controller, "manipulator_heavy_claw") > 0


static func has_heavy_claw(controller: Variant) -> bool:
	return has_heavy_claw_capability(controller)


static func can_use_physical_hand(controller: Variant) -> bool:
	if controller.is_hand_occupied() or (not controller.buffer_item.is_empty() and not controller._is_digital_storage_item(controller.buffer_item)):
		return false
	if controller.mission_manager != null and controller.mission_manager.has_method("get_inventory_state"):
		var inventory: Dictionary = Dictionary(controller.mission_manager.call("get_inventory_state"))
		if not controller._runtime_inventory_value_id(inventory.get("manipulator_hold", "")).is_empty():
			return false
	return true


static func _get_connector_module_prefix_for_kind(kind: String) -> String:
	match str(kind).strip_edges().to_lower():
		"wired":
			return "wired_connector"
		"optical":
			return "optical_connector"
		"wireless":
			return "wireless_connector"
		"high_bandwidth":
			return "high_bandwidth_connector"
		_:
			return ""
