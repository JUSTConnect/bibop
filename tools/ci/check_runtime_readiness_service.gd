extends SceneTree

const RuntimeReadinessServiceRef = preload("res://scripts/game/runtime_readiness_service.gd")

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
	var ids: Array[String] = []
	func is_virtual_power_available() -> bool: return virtual_power
	func is_internal_data_network_available() -> bool: return internal_data
	func is_external_data_network_available() -> bool: return external_data
	func has_air_cooling_requiring_intake() -> bool: return requires_air
	func has_external_air_intake() -> bool: return external_air
	func get_highest_internal_preview_heat() -> int: return heat
	func get_damage_preview_critical_count() -> int: return damage_critical
	func get_damage_preview_warning_count() -> int: return damage_warning
	func get_constructor_consistency_issue_count() -> int: return consistency
	func get_thermal_preview_affected_module_ids() -> Array[String]: return ids
	func get_damage_preview_affected_module_ids() -> Array[String]: return ids

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

func _check_cases() -> void:
	var source := FakeReadinessSource.new()
	var result := RuntimeReadinessServiceRef.evaluate_constructor(source)
	_check(result.get("status") == "ready", "expected ready state")
	_check(result.get("items", []).is_empty(), "expected no warnings")

	source.virtual_power = false
	result = RuntimeReadinessServiceRef.evaluate_constructor(source)
	_check(result.get("status") == "blocked", "missing power blocks")
	_check(_codes(result).has("missing_virtual_power"), "missing power code")

	source.virtual_power = true
	source.internal_data = false
	result = RuntimeReadinessServiceRef.evaluate_constructor(source)
	_check(result.get("status") == "ready_with_warnings", "internal data warns")
	_check(_codes(result).has("missing_internal_data"), "internal data code")

	source.internal_data = true
	source.external_data = false
	_check(_codes(RuntimeReadinessServiceRef.evaluate_constructor(source)).has("missing_external_data_bridge"), "external bridge code")

	source.external_data = true
	source.requires_air = true
	source.external_air = false
	_check(_codes(RuntimeReadinessServiceRef.evaluate_constructor(source)).has("missing_air_intake"), "air intake code")

	source.requires_air = false
	source.external_air = true
	source.heat = 4
	result = RuntimeReadinessServiceRef.evaluate_constructor(source)
	_check(_codes(result).has("thermal_warning"), "thermal warning at 4")
	_check(result.get("status") == "ready_with_warnings", "heat 4 warns")

	source.heat = 5
	result = RuntimeReadinessServiceRef.evaluate_constructor(source)
	_check(_codes(result).has("thermal_critical"), "thermal critical at 5")
	_check(result.get("status") == "blocked", "heat 5 blocks")

	source.heat = 0
	source.damage_warning = 1
	_check(_codes(RuntimeReadinessServiceRef.evaluate_constructor(source)).has("damage_warning"), "damage warning code")
	source.damage_critical = 1
	result = RuntimeReadinessServiceRef.evaluate_constructor(source)
	_check(_codes(result).has("damage_critical"), "damage critical code")
	_check(result.get("status") == "blocked", "damage critical blocks")

	source.damage_critical = 0
	source.damage_warning = 0
	source.consistency = 2
	_check(_codes(RuntimeReadinessServiceRef.evaluate_constructor(source)).has("constructor_consistency_invalid"), "consistency code")

	source.consistency = 0
	source.internal_data = false
	result = RuntimeReadinessServiceRef.evaluate_constructor(source)
	_check(result.get("status") == "ready_with_warnings", "ready with warnings")
	source.internal_data = true
	_check(RuntimeReadinessServiceRef.evaluate_constructor(source).get("status") == "ready", "blocked/warn recovery to ready")

	source.ids = ["z", "a", "z"]
	source.heat = 4
	var first := RuntimeReadinessServiceRef.evaluate_constructor(source)
	var second := RuntimeReadinessServiceRef.evaluate_constructor(source)
	_check(str(first) == str(second), "repeated evaluation equivalent")
	_check(first.get("affected_module_ids", []) == ["a", "z"], "affected ids deterministic and unique")
	for item in first.get("items", []):
		for key in ["code", "category", "severity", "message", "blocking", "affected_module_ids"]:
			_check(item.has(key), "item missing %s" % key)
	var counted := int(first.get("danger_count", 0)) + int(first.get("warning_count", 0)) + int(first.get("info_count", 0))
	_check(counted == first.get("items", []).size(), "warning counts match items")
