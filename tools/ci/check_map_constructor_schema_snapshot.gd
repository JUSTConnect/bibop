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
		"entity_contract":{
			"entity_type":"object",
			"entity_subtype":"test_device",
			"status_profile":"object_standard",
			"capabilities":{"state":true, "power":false, "health":false, "energy":false, "overheat":false, "control":false, "access":false, "bindings":true, "mount":true, "side":true, "routing":false, "test_override":true}
		},
		"property_schema":[
			{"field":"z_enabled", "type":"bool", "default":false},
			{"field":"a_mode", "type":"enum", "values":["one", "two"], "default":"one"},
			{"field":"count", "type":"int", "default":1},
			{"field":"target_id", "type":"object_ref", "default":""},
			{"field":"computed_value", "type":"computed"}
		]
	}
	var entity: Dictionary = {"id":"device_a", "display_name":"Device A", "object_type":"test_device", "z_enabled":true, "a_mode":"two", "count":2, "intent_state":"on", "operational_state":"operational"}
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
	var status_rows: Array = Array(_section(first, "computed_status").get("rows", []))
	var forced_status_found: bool = false
	for value in status_rows:
		if value is Dictionary and str(Dictionary(value).get("field", "")) == "operational":
			forced_status_found = str(Dictionary(value).get("real_value", "")) == "operational" and str(Dictionary(value).get("forced_value", "")) == "blocked"
	_check(forced_status_found, "computed status did not expose real and forced values")
	var override_section: Dictionary = _section(first, "test_override")
	_check(not override_section.is_empty(), "test override section missing")
	if not override_section.is_empty():
		var row: Dictionary = Dictionary(Array(override_section.get("rows", []))[0])
		_check(str(Dictionary(row.get("forced_values", {})).get("operational_state", "")) == "blocked", "forced value alias was not normalized")
	var runtime_context: Dictionary = context.duplicate(true)
	runtime_context["mode"] = "runtime"
	_check(_section(Inspector.build(entity, runtime_context), "test_override").is_empty(), "normal runtime exposed test override")
	var passive_definition: Dictionary = {
		"display_name_template":"Passive",
		"entity_contract":{"entity_type":"object", "entity_subtype":"passive", "status_profile":"cooling_passive", "capabilities":{}},
		"property_schema":[]
	}
	var passive: Dictionary = Inspector.build({"id":"passive_a", "object_type":"passive"}, {"definition":passive_definition})
	_check(_section(passive, "computed_status").is_empty(), "unsupported computed status section was emitted")
	_check(_section(passive, "test_override").is_empty(), "unsupported test override section was emitted")
	if failures.is_empty():
		print("MAP_CONSTRUCTOR_SCHEMA_SNAPSHOT_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("MAP_CONSTRUCTOR_SCHEMA_SNAPSHOT_GATE: FAIL: %s" % failure)
	quit(1)
