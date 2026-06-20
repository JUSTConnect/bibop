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

const REQUIRED_QUERY_METHODS: Array[String] = [
	"is_virtual_power_available",
	"is_internal_data_network_available",
	"is_external_data_network_available",
	"has_air_cooling_requiring_intake",
	"has_external_air_intake",
	"get_highest_internal_preview_heat",
	"get_damage_preview_critical_count",
	"get_damage_preview_warning_count",
	"get_constructor_consistency_issue_count",
	"has_overlay_preview_changes",
	"get_virtual_power_affected_module_ids",
	"get_internal_data_affected_module_ids",
	"get_external_data_affected_module_ids",
	"get_air_cooling_affected_module_ids",
	"get_thermal_preview_affected_module_ids",
	"get_damage_preview_affected_module_ids",
	"get_overlay_preview_affected_module_ids",
	"get_constructor_consistency_affected_module_ids"
]

static func evaluate_constructor(source: Object) -> Dictionary:
	if source == null:
		var unavailable_item := _make_item("readiness_source_unavailable", "runtime", SEVERITY_WARNING, "Constructor runtime state is unavailable.", "Constructor runtime state is unavailable.", true)
		return _build_result([unavailable_item], _empty_systems(), STATUS_NOT_READY, "NOT READY", SEVERITY_WARNING, "Constructor runtime state is unavailable.")

	var missing_methods := _get_missing_required_methods(source)
	if not missing_methods.is_empty():
		var incomplete_item := _make_item("source_contract_incomplete", "runtime", SEVERITY_WARNING, "Constructor readiness source is missing required query APIs.", "Update the runtime source to implement: %s" % ", ".join(missing_methods), true)
		return _build_result([incomplete_item], _empty_systems(), STATUS_NOT_READY, "NOT READY", SEVERITY_WARNING, "Constructor runtime state is unavailable.")

	var systems := _build_systems(source)
	var items: Array[Dictionary] = []
	_add_missing_virtual_power(source, systems, items)
	_add_missing_internal_data(source, systems, items)
	_add_missing_external_data_bridge(source, systems, items)
	_add_missing_air_intake(source, systems, items)
	_add_thermal(source, systems, items)
	_add_damage(source, items)
	_add_overlay_preview(source, items)
	_add_consistency(source, items)
	return _build_result(items, systems)

static func _get_missing_required_methods(source: Object) -> Array[String]:
	var missing: Array[String] = []
	for method_name in REQUIRED_QUERY_METHODS:
		if not source.has_method(method_name):
			missing.append(method_name)
	return missing

static func _empty_systems() -> Dictionary:
	return {
		"power": {"available": false, "status": "unavailable"},
		"internal_data": {"available": false, "status": "unavailable"},
		"external_data": {"available": false, "status": "unavailable"},
		"thermal": {"status": "unknown", "highest_heat": 0},
		"air_intake": {"required": false, "installed": false, "status": "unknown"}
	}

static func _build_systems(source: Object) -> Dictionary:
	var power_available := bool(source.call("is_virtual_power_available"))
	var internal_data_available := bool(source.call("is_internal_data_network_available"))
	var external_data_available := bool(source.call("is_external_data_network_available"))
	var air_required := bool(source.call("has_air_cooling_requiring_intake"))
	var air_installed := bool(source.call("has_external_air_intake"))
	var highest_heat := int(source.call("get_highest_internal_preview_heat"))
	var thermal_status := "ok"
	if highest_heat >= 5:
		thermal_status = "critical preview"
	elif highest_heat >= 4:
		thermal_status = "warning"
	var air_status := "not required"
	if air_required:
		air_status = "installed" if air_installed else "missing"
	return {
		"power": {"available": power_available, "status": _status_word(power_available)},
		"internal_data": {"available": internal_data_available, "status": _status_word(internal_data_available)},
		"external_data": {"available": external_data_available, "status": _status_word(external_data_available)},
		"thermal": {"status": thermal_status, "highest_heat": highest_heat},
		"air_intake": {"required": air_required, "installed": air_installed, "status": air_status}
	}

static func _status_word(value: bool) -> String:
	return "available" if value else "unavailable"

static func _build_result(items: Array[Dictionary], systems: Dictionary, forced_status: String = "", forced_label: String = "", forced_severity: String = "", forced_hint: String = "") -> Dictionary:
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
	if not forced_status.is_empty():
		status = forced_status
		label = forced_label
		severity = forced_severity
		hint = forced_hint
	elif not blocking_reasons.is_empty():
		status = STATUS_BLOCKED
		label = "BLOCKED"
		severity = SEVERITY_DANGER
		hint = "Fix critical constructor issues first."
	elif warning_count > 0 or info_count > 0:
		status = STATUS_READY_WITH_WARNINGS
		label = "READY WITH WARNINGS"
		severity = SEVERITY_WARNING if warning_count > 0 else SEVERITY_INFO
		hint = "Configuration can continue, but warnings remain."
	return {"ready": status == STATUS_READY or status == STATUS_READY_WITH_WARNINGS, "status": status, "label": label, "severity": severity, "hint": hint, "blocking_reasons": blocking_reasons, "warnings": warnings, "items": items, "danger_count": danger_count, "warning_count": warning_count, "info_count": info_count, "affected_module_ids": affected_ids, "systems": systems.duplicate(true)}

static func _make_item(code: String, category: String, severity: String, message: String, hint: String, blocking: bool, affected_module_ids: Array[String] = []) -> Dictionary:
	var ids: Array[String] = []
	for id_variant in affected_module_ids:
		var id := str(id_variant)
		if not id.is_empty() and not ids.has(id):
			ids.append(id)
	ids.sort()
	return {"code": code, "category": category, "severity": severity, "message": message, "hint": hint, "blocking": blocking, "affected_module_ids": ids}

static func _ids_query(source: Object, method_name: String) -> Array[String]:
	var ids: Array[String] = []
	for id_variant in source.call(method_name):
		var id := str(id_variant)
		if not id.is_empty() and not ids.has(id):
			ids.append(id)
	ids.sort()
	return ids

static func _add_missing_virtual_power(source: Object, systems: Dictionary, items: Array[Dictionary]) -> void:
	if not bool(systems.get("power", {}).get("available", false)):
		items.append(_make_item("missing_virtual_power", "power", SEVERITY_DANGER, "Virtual power network is incomplete.", "Install Battery and Power Block, then connect through automatic virtual wiring.", true, _ids_query(source, "get_virtual_power_affected_module_ids")))

static func _add_missing_internal_data(source: Object, systems: Dictionary, items: Array[Dictionary]) -> void:
	if not bool(systems.get("internal_data", {}).get("available", false)):
		items.append(_make_item("missing_internal_data", "data", SEVERITY_WARNING, "Internal data network is incomplete.", "Install Internal Interface and required processing/data modules.", false, _ids_query(source, "get_internal_data_affected_module_ids")))

static func _add_missing_external_data_bridge(source: Object, systems: Dictionary, items: Array[Dictionary]) -> void:
	if not bool(systems.get("external_data", {}).get("available", false)):
		items.append(_make_item("missing_external_data_bridge", "external", SEVERITY_WARNING, "External devices do not have a complete data bridge.", "Install External Interface and Internal Interface.", false, _ids_query(source, "get_external_data_affected_module_ids")))

static func _add_missing_air_intake(source: Object, systems: Dictionary, items: Array[Dictionary]) -> void:
	var air_intake: Dictionary = systems.get("air_intake", {})
	if bool(air_intake.get("required", false)) and not bool(air_intake.get("installed", false)):
		items.append(_make_item("missing_air_intake", "cooling", SEVERITY_WARNING, "Air cooling requires an external Air Intake.", "Place Air Intake Node on an external slot.", false, _ids_query(source, "get_air_cooling_affected_module_ids")))

static func _add_thermal(source: Object, systems: Dictionary, items: Array[Dictionary]) -> void:
	var heat := int(systems.get("thermal", {}).get("highest_heat", 0))
	if heat >= 5:
		items.append(_make_item("thermal_critical", "thermal", SEVERITY_DANGER, "Thermal preview reaches critical heat 5.", "Add cooling, move hot modules apart, or plan overlay cooling.", true, _ids_query(source, "get_thermal_preview_affected_module_ids")))
	elif heat >= 4:
		items.append(_make_item("thermal_warning", "thermal", SEVERITY_WARNING, "Thermal preview has high heat 4.", "Consider cooler/radiator placement before mission use.", false, _ids_query(source, "get_thermal_preview_affected_module_ids")))

static func _add_damage(source: Object, items: Array[Dictionary]) -> void:
	var critical := int(source.call("get_damage_preview_critical_count"))
	var warning := int(source.call("get_damage_preview_warning_count"))
	if critical > 0:
		items.append(_make_item("damage_critical", "damage", SEVERITY_DANGER, "Damage preview has %d critical module(s)." % critical, "Lower heat below damage threshold.", true, _ids_query(source, "get_damage_preview_affected_module_ids")))
	elif warning > 0:
		items.append(_make_item("damage_warning", "damage", SEVERITY_WARNING, "Damage preview has %d module(s) near threshold." % warning, "Add cooling or move modules before using active abilities.", false, _ids_query(source, "get_damage_preview_affected_module_ids")))

static func _add_overlay_preview(source: Object, items: Array[Dictionary]) -> void:
	if bool(source.call("has_overlay_preview_changes")):
		items.append(_make_item("overlay_preview_active", "overlay", SEVERITY_INFO, "Overlay paths may improve hypothetical thermal preview.", "Overlay effects are informational until later gameplay rules.", false, _ids_query(source, "get_overlay_preview_affected_module_ids")))

static func _add_consistency(source: Object, items: Array[Dictionary]) -> void:
	var count := int(source.call("get_constructor_consistency_issue_count"))
	if count > 0:
		items.append(_make_item("constructor_consistency_invalid", "consistency", SEVERITY_DANGER, "Constructor consistency has %d issue(s)." % count, "Run Checkpoint and fix missing metadata or invalid records.", true, _ids_query(source, "get_constructor_consistency_affected_module_ids")))
