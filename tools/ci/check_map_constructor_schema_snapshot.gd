extends SceneTree

const Inspector = preload("res://scripts/game/map_constructor_schema_inspector_service.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _section(snapshot: Dictionary, section_id: String) -> Dictionary:
	for value in Array(snapshot.get("sections", [])):
		if value is Dictionary and str(Dictionary(value).get("id", "")) == section_id:
			return Dictionary(value)
	return {}

func _run() -> void:
	await process_frame
	var definition: Dictionary = {
		"display_name_template":"Test Device",
		"entity_contract":{"entity_type":"object", "entity_subtype":"test_device", "capabilities":{"state":true, "power":false, "health":false, "energy":false, "overheat":false, "control":false, "access":false, "bindings":true, "mount":true, "side":true, "routing":false, "test_override":true}},
		"property_schema":[
			{"field":"z_enabled", "type":"bool", "default":false},
			{"field":"a_mode", "type":"enum", "values":["one", "two"], "default":"one"},
			{"field":"count", "type":"int", "default":1},
			{"field":"target_id", "type":"object_ref", "default":""},
			{"field":"computed_value", "type":"computed"}
		]
	}
	var entity: Dictionary = {"id":"device_a", "display_name":"Device A", "object_type":"test_device", "z_enabled":true, "a_mode":"two", "count":2, "intent_state":"on", "operational_state":"ready", "health_state":"healthy", "thermal_state":"normal"}
	var context: Dictionary = {
		"mode":"task_test", "definition":definition,
		"entities_by_id":{"device_a":entity, "terminal_a":{"id":"terminal_a", "display_name":"Terminal A"}},
		"bindings":[{"id":"bind_a", "role":"control_terminal", "source_id":"terminal_a", "target_id":"device_a", "parameters":{}}],
		"physical_topology":{"route_shape":"straight"},
		"issues":[{"code":"device.warning", "severity":"warning", "entity_id":"device_a", "fallback":"Warning"}],
		"test_override":{"forced_values":{"operational":"blocked"}}
	}
	var before_entity: String = var_to_str(entity)
	var before_context: String = var_to_str(context)
	var first: Dictionary = Inspector.build(entity, context)
	var second: Dictionary = Inspector.build(entity, context)
	_check(var_to_str(entity) == before_entity and var_to_str(context) == before_context, "snapshot mutated input")
	_check(str(first.get("signature", "")) == str(second.get("signature", "")), "signature is not deterministic")
	var rows: Array = Array(_section(first, "editable_fields").get("rows", []))
	_check(rows.size() == 5, "schema rows missing")
	if rows.size() == 5:
		_check(str(Dictionary(rows[0]).get("field", "")) == "z_enabled", "schema order changed")
		_check(str(Dictionary(rows[0]).get("control", "")) == "checkbox", "bool control mismatch")
		_check(str(Dictionary(rows[1]).get("control", "")) == "enum", "enum control mismatch")
		_check(str(Dictionary(rows[2]).get("control", "")) == "number", "int control mismatch")
		_check(str(Dictionary(rows[3]).get("control", "")) == "entity_picker", "object ref control mismatch")
		_check(str(Dictionary(rows[4]).get("control", "")) == "read_only", "computed control mismatch")
	_check(not _section(first, "logical_bindings").is_empty(), "logical bindings missing")
	_check(not _section(first, "physical_topology").is_empty(), "physical topology missing")
	_check(not _section(first, "issues").is_empty(), "issue section missing")
	var override_section: Dictionary = _section(first, "test_override")
	_check(not override_section.is_empty(), "test override section missing")
	if not override_section.is_empty():
		var row: Dictionary = Dictionary(Array(override_section.get("rows", []))[0])
		_check(row.has("real_values") and row.has("forced_values"), "real/forced values not both visible")
	if failures.is_empty():
		print("MAP_CONSTRUCTOR_SCHEMA_SNAPSHOT_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("MAP_CONSTRUCTOR_SCHEMA_SNAPSHOT_GATE: FAIL: %s" % failure)
	quit(1)
