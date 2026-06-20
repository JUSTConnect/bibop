extends RefCounted
class_name RuntimeReadinessService

const STATUS_READY := "ready"
const STATUS_READY_WITH_WARNINGS := "ready_with_warnings"
const STATUS_NOT_READY := "not_ready"
const STATUS_BLOCKED := "blocked"
const SEVERITY_OK := "ok"
const SEVERITY_INFO := "info"
const SEVERITY_WARNING := "warning"
const SEVERITY_DANGER := "danger"

static func evaluate_constructor(source: Object) -> Dictionary:
	var items: Array[Dictionary] = []
	if source != null:
		_add_missing_virtual_power(source, items)
		_add_missing_internal_data(source, items)
		_add_missing_external_data_bridge(source, items)
		_add_missing_air_intake(source, items)
		_add_thermal(source, items)
		_add_damage(source, items)
		_add_overlay_preview(source, items)
		_add_consistency(source, items)
	return _build_result(items)

static func _build_result(items: Array[Dictionary]) -> Dictionary:
	var warnings: Array[Dictionary] = []
	var blocking_reasons: Array[Dictionary] = []
	var danger_count := 0
	var warning_count := 0
	var info_count := 0
	var affected_ids: Array[String] = []
	for item in items:
		var severity := str(item.get("severity", SEVERITY_WARNING))
		if severity == SEVERITY_DANGER:
			danger_count += 1
		elif severity == SEVERITY_WARNING:
			warning_count += 1
		elif severity == SEVERITY_INFO:
			info_count += 1
		if bool(item.get("blocking", false)):
			blocking_reasons.append(item)
		else:
			warnings.append(item)
		for id_variant in item.get("affected_module_ids", []):
			var id := str(id_variant)
			if not id.is_empty() and not affected_ids.has(id):
				affected_ids.append(id)
	affected_ids.sort()
	var status := STATUS_READY
	var label := "READY"
	var severity := SEVERITY_OK
	var hint := "Configuration passes current constructor readiness checks."
	if not blocking_reasons.is_empty():
		status = STATUS_BLOCKED
		label = "BLOCKED"
		severity = SEVERITY_DANGER
		hint = "Fix critical constructor issues first."
	elif warning_count > 0 or info_count > 0:
		status = STATUS_READY_WITH_WARNINGS
		label = "READY WITH WARNINGS"
		severity = SEVERITY_WARNING if warning_count > 0 else SEVERITY_INFO
		hint = "Configuration can continue, but warnings remain."
	return {"ready": status != STATUS_BLOCKED and status != STATUS_NOT_READY, "status": status, "label": label, "severity": severity, "hint": hint, "blocking_reasons": blocking_reasons, "warnings": warnings, "items": items, "danger_count": danger_count, "warning_count": warning_count, "info_count": info_count, "affected_module_ids": affected_ids}

static func _make_item(code: String, category: String, severity: String, message: String, hint: String, blocking: bool, affected_module_ids: Array[String] = []) -> Dictionary:
	var ids: Array[String] = []
	for id_variant in affected_module_ids:
		var id := str(id_variant)
		if not id.is_empty() and not ids.has(id):
			ids.append(id)
	ids.sort()
	return {"code": code, "category": category, "severity": severity, "message": message, "hint": hint, "blocking": blocking, "affected_module_ids": ids}

static func _bool_query(source: Object, method_name: String, default_value: bool) -> bool:
	if source != null and source.has_method(method_name):
		return bool(source.call(method_name))
	return default_value

static func _int_query(source: Object, method_name: String, default_value: int = 0) -> int:
	if source != null and source.has_method(method_name):
		return int(source.call(method_name))
	return default_value

static func _ids_query(source: Object, method_name: String) -> Array[String]:
	var ids: Array[String] = []
	if source != null and source.has_method(method_name):
		for id_variant in source.call(method_name):
			var id := str(id_variant)
			if not id.is_empty() and not ids.has(id):
				ids.append(id)
	ids.sort()
	return ids

static func _add_missing_virtual_power(source: Object, items: Array[Dictionary]) -> void:
	if not _bool_query(source, "is_virtual_power_available", true):
		items.append(_make_item("missing_virtual_power", "power", SEVERITY_DANGER, "Virtual power network is incomplete.", "Install Battery and Power Block, then connect through automatic virtual wiring.", true, _ids_query(source, "get_virtual_power_affected_module_ids")))

static func _add_missing_internal_data(source: Object, items: Array[Dictionary]) -> void:
	if not _bool_query(source, "is_internal_data_network_available", true):
		items.append(_make_item("missing_internal_data", "data", SEVERITY_WARNING, "Internal data network is incomplete.", "Install Internal Interface and required processing/data modules.", false, _ids_query(source, "get_internal_data_affected_module_ids")))

static func _add_missing_external_data_bridge(source: Object, items: Array[Dictionary]) -> void:
	if not _bool_query(source, "is_external_data_network_available", true):
		items.append(_make_item("missing_external_data_bridge", "external", SEVERITY_WARNING, "External devices do not have a complete data bridge.", "Install External Interface and Internal Interface.", false, _ids_query(source, "get_external_data_affected_module_ids")))

static func _add_missing_air_intake(source: Object, items: Array[Dictionary]) -> void:
	if _bool_query(source, "has_air_cooling_requiring_intake", false) and not _bool_query(source, "has_external_air_intake", true):
		items.append(_make_item("missing_air_intake", "cooling", SEVERITY_WARNING, "Air cooling requires an external Air Intake.", "Place Air Intake Node on an external slot.", false, _ids_query(source, "get_air_cooling_affected_module_ids")))

static func _add_thermal(source: Object, items: Array[Dictionary]) -> void:
	var heat := _int_query(source, "get_highest_internal_preview_heat", 0)
	if heat >= 5:
		items.append(_make_item("thermal_critical", "thermal", SEVERITY_DANGER, "Thermal preview reaches critical heat 5.", "Add cooling, move hot modules apart, or plan overlay cooling.", true, _ids_query(source, "get_thermal_preview_affected_module_ids")))
	elif heat >= 4:
		items.append(_make_item("thermal_warning", "thermal", SEVERITY_WARNING, "Thermal preview has high heat 4.", "Consider cooler/radiator placement before mission use.", false, _ids_query(source, "get_thermal_preview_affected_module_ids")))

static func _add_damage(source: Object, items: Array[Dictionary]) -> void:
	var critical := _int_query(source, "get_damage_preview_critical_count", 0)
	var warning := _int_query(source, "get_damage_preview_warning_count", 0)
	if critical > 0:
		items.append(_make_item("damage_critical", "damage", SEVERITY_DANGER, "Damage preview has %d critical module(s)." % critical, "Lower heat below damage threshold.", true, _ids_query(source, "get_damage_preview_affected_module_ids")))
	elif warning > 0:
		items.append(_make_item("damage_warning", "damage", SEVERITY_WARNING, "Damage preview has %d module(s) near threshold." % warning, "Add cooling or move modules before using active abilities.", false, _ids_query(source, "get_damage_preview_affected_module_ids")))

static func _add_overlay_preview(source: Object, items: Array[Dictionary]) -> void:
	if source.has_method("get_overlay_heat_diff_compact_text"):
		var overlay_text := str(source.call("get_overlay_heat_diff_compact_text"))
		if not overlay_text.contains("changed 0"):
			items.append(_make_item("overlay_preview_active", "overlay", SEVERITY_INFO, "Overlay paths may improve hypothetical thermal preview.", "Overlay effects are informational until later gameplay rules.", false, _ids_query(source, "get_overlay_preview_affected_module_ids")))

static func _add_consistency(source: Object, items: Array[Dictionary]) -> void:
	var count := _int_query(source, "get_constructor_consistency_issue_count", 0)
	if count > 0:
		items.append(_make_item("constructor_consistency_invalid", "consistency", SEVERITY_DANGER, "Constructor consistency has %d issue(s)." % count, "Run Checkpoint and fix missing metadata or invalid records.", true, _ids_query(source, "get_constructor_consistency_affected_module_ids")))
