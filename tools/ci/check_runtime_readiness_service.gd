extends SceneTree

const RuntimeReadinessServiceRef = preload("res://scripts/game/runtime_readiness_service.gd")
const MapConstructorUIBridgeRef = preload("res://scripts/ui/map_constructor/map_constructor_ui_bridge.gd")

class FakeReadinessSource:
	extends RefCounted
	var virtual_power := true
	var internal_data := true
	var external_data := true
	var requires_air := false
	var external_air := true
	var heat := 0
	var damage_critical := 0
	var damage_warning := 0
	var consistency := 0
	var overlay_changed := false
	var user_text := "changed 0"
	var ids_by_method := {
		"get_virtual_power_affected_module_ids": ["battery_v1", "power_block_v1"],
		"get_internal_data_affected_module_ids": ["internal_interface_v1"],
		"get_external_data_affected_module_ids": ["external_interface_v1", "internal_interface_v1"],
		"get_air_cooling_affected_module_ids": ["cooler_v1"],
		"get_thermal_preview_affected_module_ids": ["hot_module_v1", "hot_module_v1"],
		"get_damage_preview_affected_module_ids": ["fragile_module_v1"],
		"get_overlay_preview_affected_module_ids": ["overlay_module_v1"],
		"get_constructor_consistency_affected_module_ids": ["bad_module_v1"]
	}
	func is_virtual_power_available() -> bool: return virtual_power
	func is_internal_data_network_available() -> bool: return internal_data
	func is_external_data_network_available() -> bool: return external_data
	func has_air_cooling_requiring_intake() -> bool: return requires_air
	func has_external_air_intake() -> bool: return external_air
	func get_highest_internal_preview_heat() -> int: return heat
	func get_damage_preview_critical_count() -> int: return damage_critical
	func get_damage_preview_warning_count() -> int: return damage_warning
	func get_constructor_consistency_issue_count() -> int: return consistency
	func has_overlay_preview_changes() -> bool: return overlay_changed
	func get_virtual_power_affected_module_ids() -> Array[String]: return _ids("get_virtual_power_affected_module_ids")
	func get_internal_data_affected_module_ids() -> Array[String]: return _ids("get_internal_data_affected_module_ids")
	func get_external_data_affected_module_ids() -> Array[String]: return _ids("get_external_data_affected_module_ids")
	func get_air_cooling_affected_module_ids() -> Array[String]: return _ids("get_air_cooling_affected_module_ids")
	func get_thermal_preview_affected_module_ids() -> Array[String]: return _ids("get_thermal_preview_affected_module_ids")
	func get_damage_preview_affected_module_ids() -> Array[String]: return _ids("get_damage_preview_affected_module_ids")
	func get_overlay_preview_affected_module_ids() -> Array[String]: return _ids("get_overlay_preview_affected_module_ids")
	func get_constructor_consistency_affected_module_ids() -> Array[String]: return _ids("get_constructor_consistency_affected_module_ids")
	func get_overlay_heat_diff_compact_text() -> String: return user_text
	func _ids(method_name: String) -> Array[String]:
		var result: Array[String] = []
		for value in ids_by_method.get(method_name, []):
			result.append(str(value))
		return result

class IncompleteSource:
	extends RefCounted
	func is_virtual_power_available() -> bool: return true

class CacheOwner:
	extends RefCounted
	var source: FakeReadinessSource
	var latest_constructor_readiness_result: Dictionary = {}
	func _init(source_ref: FakeReadinessSource) -> void:
		source = source_ref
	func refresh() -> Dictionary:
		latest_constructor_readiness_result = RuntimeReadinessServiceRef.evaluate_constructor(source).duplicate(true)
		return latest_constructor_readiness_result
	func profile_load() -> void:
		refresh()
	func constructor_entry() -> void:
		refresh()
	func warning_panel_snapshot() -> Dictionary:
		return latest_constructor_readiness_result
	func badge_snapshot() -> Dictionary:
		return latest_constructor_readiness_result

func _initialize() -> void:
	_check_cases()
	print("RuntimeReadinessService behavior gate: OK")
	quit(0)

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)

func _codes(result: Dictionary) -> Array[String]:
	var codes: Array[String] = []
	for item in result.get("items", []):
		codes.append(str(item.get("code", "")))
	return codes

func _first_item(result: Dictionary, code: String) -> Dictionary:
	for item in result.get("items", []):
		if str(item.get("code", "")) == code:
			return item
	return {}

func _check_item(result: Dictionary, code: String, expected_ids: Array[String]) -> void:
	var item := _first_item(result, code)
	_check(not item.is_empty(), "missing item %s" % code)
	for key in ["code", "category", "severity", "message", "blocking", "affected_module_ids"]:
		_check(item.has(key), "item %s missing %s" % [code, key])
	_check(item.get("affected_module_ids", []) == expected_ids, "affected ids mismatch for %s" % code)

func _check_cases() -> void:
	var null_result := RuntimeReadinessServiceRef.evaluate_constructor(null)
	_check(null_result.get("status") == "not_ready", "null source must be not_ready")
	_check(null_result.get("ready") == false, "null source is not ready")
	_check(_codes(null_result).has("readiness_source_unavailable"), "null source item code")

	var incomplete_result := RuntimeReadinessServiceRef.evaluate_constructor(IncompleteSource.new())
	_check(incomplete_result.get("status") == "not_ready", "incomplete source must be not_ready")
	_check(_codes(incomplete_result).has("source_contract_incomplete"), "incomplete contract item code")

	var source := FakeReadinessSource.new()
	var result := RuntimeReadinessServiceRef.evaluate_constructor(source)
	_check(result.get("status") == "ready", "expected ready state")
	_check(result.get("items", []).is_empty(), "expected no warnings")
	_check(str(result.get("systems", {}).get("power", {}).get("status", "")) == "available", "systems preserve power status")

	source.virtual_power = false
	result = RuntimeReadinessServiceRef.evaluate_constructor(source)
	_check(result.get("status") == "blocked", "missing power blocks")
	_check_item(result, "missing_virtual_power", ["battery_v1", "power_block_v1"])

	source.virtual_power = true
	source.internal_data = false
	result = RuntimeReadinessServiceRef.evaluate_constructor(source)
	_check(result.get("status") == "ready_with_warnings", "internal data warns")
	_check_item(result, "missing_internal_data", ["internal_interface_v1"])

	source.internal_data = true
	source.external_data = false
	_check_item(RuntimeReadinessServiceRef.evaluate_constructor(source), "missing_external_data_bridge", ["external_interface_v1", "internal_interface_v1"])

	source.external_data = true
	source.requires_air = true
	source.external_air = false
	_check_item(RuntimeReadinessServiceRef.evaluate_constructor(source), "missing_air_intake", ["cooler_v1"])

	source.requires_air = false
	source.external_air = true
	source.heat = 4
	result = RuntimeReadinessServiceRef.evaluate_constructor(source)
	_check(result.get("status") == "ready_with_warnings", "heat 4 warns")
	_check_item(result, "thermal_warning", ["hot_module_v1"])

	source.heat = 5
	result = RuntimeReadinessServiceRef.evaluate_constructor(source)
	_check(result.get("status") == "blocked", "heat 5 blocks")
	_check_item(result, "thermal_critical", ["hot_module_v1"])

	source.heat = 0
	source.damage_warning = 1
	_check_item(RuntimeReadinessServiceRef.evaluate_constructor(source), "damage_warning", ["fragile_module_v1"])
	source.damage_critical = 1
	result = RuntimeReadinessServiceRef.evaluate_constructor(source)
	_check(result.get("status") == "blocked", "damage critical blocks")
	_check_item(result, "damage_critical", ["fragile_module_v1"])

	source.damage_critical = 0
	source.damage_warning = 0
	for consistency_kind in ["unknown", "outside", "lower", "mismatch"]:
		source.consistency = 1
		result = RuntimeReadinessServiceRef.evaluate_constructor(source)
		_check(result.get("status") == "blocked", "consistency %s blocks" % consistency_kind)
		_check_item(result, "constructor_consistency_invalid", ["bad_module_v1"])

	source.consistency = 0
	source.overlay_changed = true
	source.user_text = "Overlay Diff: changed 0 / best 0"
	result = RuntimeReadinessServiceRef.evaluate_constructor(source)
	_check(_codes(result).has("overlay_preview_active"), "overlay uses structured boolean")
	_check_item(result, "overlay_preview_active", ["overlay_module_v1"])
	source.user_text = "Overlay Diff: changed 999 / best -5"
	var result_after_text_change := RuntimeReadinessServiceRef.evaluate_constructor(source)
	_check(str(result) == str(result_after_text_change), "user text changes do not alter domain result")

	source.overlay_changed = false
	source.internal_data = false
	result = RuntimeReadinessServiceRef.evaluate_constructor(source)
	_check(result.get("status") == "ready_with_warnings", "ready with warnings")
	source.internal_data = true
	_check(RuntimeReadinessServiceRef.evaluate_constructor(source).get("status") == "ready", "blocked/warn recovery to ready")

	source.heat = 4
	var first := RuntimeReadinessServiceRef.evaluate_constructor(source)
	var second := RuntimeReadinessServiceRef.evaluate_constructor(source)
	_check(str(first) == str(second), "repeated evaluation equivalent")
	_check(first.get("affected_module_ids", []) == ["hot_module_v1"], "affected ids deterministic and unique")
	var counted := int(first.get("danger_count", 0)) + int(first.get("warning_count", 0)) + int(first.get("info_count", 0))
	_check(counted == first.get("items", []).size(), "warning counts match items")

	var owner := CacheOwner.new(source)
	source.virtual_power = true
	owner.profile_load()
	_check(owner.latest_constructor_readiness_result.get("status") == "ready_with_warnings", "profile load refreshes cached result")
	source.heat = 0
	owner.constructor_entry()
	_check(owner.latest_constructor_readiness_result.get("status") == "ready", "constructor entry refreshes cached result")
	_check(str(owner.warning_panel_snapshot()) == str(owner.badge_snapshot()), "warning panel and badges share one snapshot")

	var bridge := MapConstructorUIBridgeRef.new()
	var snapshot := RuntimeReadinessServiceRef.evaluate_constructor(source)
	var bridge_items := bridge.get_constructor_warning_items(snapshot)
	_check(bridge_items == snapshot.get("items", []), "bridge consumes supplied snapshot")

	var systems: Dictionary = snapshot.get("systems", {})
	_check(systems.has("power") and systems.has("internal_data") and systems.has("external_data") and systems.has("thermal") and systems.has("air_intake"), "old summary/compact system data preserved")
