extends SceneTree

const Renderer = preload("res://scripts/ui/map_constructor/map_constructor_schema_inspector_renderer.gd")
const Controls = preload("res://scripts/ui/map_constructor/map_constructor_schema_controls_renderer.gd")

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

func _row(section: Dictionary, field_id: String) -> Dictionary:
	for value in Array(section.get("rows", [])):
		if value is Dictionary and str(Dictionary(value).get("field", "")) == field_id:
			return Dictionary(value)
	return {}

func _run() -> void:
	await process_frame
	var definition: Dictionary = {
		"display_name_template":"Battery Device",
		"entity_contract":{
			"entity_type":"object",
			"entity_subtype":"battery_device",
			"status_profile":"object_standard",
			"capabilities":{"state":true, "power":false, "health":false, "energy":true, "overheat":false, "control":false, "access":false, "bindings":false, "mount":false, "side":false, "routing":false, "test_override":false}
		},
		"property_schema":[{
			"field":"energy_pair",
			"label":"Energy",
			"type":"current_max",
			"current_field":"energy",
			"max_field":"max_energy",
			"current_editable":false,
			"max_editable":true,
			"min":0,
			"max":100,
			"step":1,
			"value_type":"int"
		}]
	}
	var entity: Dictionary = {"id":"battery_a", "object_type":"battery_device", "display_name":"Battery A", "energy":25, "max_energy":60, "intent_state":"on", "operational_state":"operational"}
	var context: Dictionary = {"mode":"map_constructor", "definition":definition, "entities_by_id":{"battery_a":entity}}
	var before_entity: String = var_to_str(entity)
	var before_context: String = var_to_str(context)
	var first: Dictionary = Renderer.build_plan(entity, context)
	var second: Dictionary = Renderer.build_plan(entity, context)
	_check(bool(first.get("handled", false)), "canonical definition used legacy fallback")
	_check(var_to_str(entity) == before_entity and var_to_str(context) == before_context, "renderer plan mutated input")
	_check(str(Dictionary(first.get("snapshot", {})).get("signature", "")) == str(Dictionary(second.get("snapshot", {})).get("signature", "")), "renderer plan is not deterministic")
	var editable: Dictionary = _section(Dictionary(first.get("snapshot", {})), "editable_fields")
	var rows: Array = Array(editable.get("rows", []))
	_check(rows.size() == 1, "current/max row missing")
	if rows.size() == 1:
		var descriptor: Dictionary = Controls.current_max_descriptor(Dictionary(rows[0]), entity)
		_check(bool(descriptor.get("valid", false)), "explicit current/max descriptor rejected")
		_check(str(descriptor.get("current_field", "")) == "energy" and str(descriptor.get("max_field", "")) == "max_energy", "current/max field ownership changed")
		_check(int(descriptor.get("current_value", -1)) == 25 and int(descriptor.get("max_value", -1)) == 60, "current/max values not read from declared fields")
		_check(not bool(descriptor.get("current_editable", true)) and bool(descriptor.get("max_editable", false)), "current/max editability convention changed")

	var malformed_definition: Dictionary = definition.duplicate(true)
	malformed_definition["property_schema"] = [{"field":"bad_pair", "type":"current_max", "current_field":"energy"}]
	var malformed: Dictionary = Renderer.build_plan(entity, {"definition":malformed_definition})
	var malformed_issues: Array = Array(malformed.get("issues", []))
	_check(malformed_issues.size() == 1, "invalid current/max schema did not emit one canonical issue")
	if malformed_issues.size() == 1:
		_check(str(Dictionary(malformed_issues[0]).get("code", "")) == "map_constructor.schema.current_max_fields_invalid", "invalid current/max issue code changed")
		_check(bool(Dictionary(malformed_issues[0]).get("blocks_promotion", false)), "invalid current/max schema did not block promotion")

	var door_definition: Dictionary = {
		"display_name_template":"Door",
		"entity_contract":{
			"entity_type":"object",
			"entity_subtype":"door",
			"status_profile":"object_standard",
			"capabilities":{"state":true, "power":true, "health":true, "energy":false, "overheat":false, "control":true, "access":true, "bindings":true, "mount":false, "side":false, "routing":false, "test_override":true}
		},
		"property_schema":[]
	}
	var door_entity: Dictionary = {"id":"door_a", "object_type":"door", "display_name":"Door A", "intent_state":"on", "operational_state":"closed", "health_state":"healthy", "is_powered":true}
	var door_task_plan: Dictionary = Renderer.build_plan(door_entity, {
		"mode":"task_test",
		"definition":door_definition,
		"entities_by_id":{"door_a":door_entity},
		"test_override":{"forced_values":{"operational_state":"open"}}
	})
	_check(bool(door_task_plan.get("handled", false)), "canonical door used legacy fallback")
	var door_task_snapshot: Dictionary = Dictionary(door_task_plan.get("snapshot", {}))
	_check(not _section(door_task_snapshot, "identity").is_empty(), "canonical door identity section missing")
	var door_status: Dictionary = _section(door_task_snapshot, "computed_status")
	var operational_row: Dictionary = _row(door_status, "operational")
	_check(str(operational_row.get("real_value", "")) == "closed", "TASK TEST door lost real operational value")
	_check(str(operational_row.get("forced_value", "")) == "open", "TASK TEST door lost forced operational value")
	var override_section: Dictionary = _section(door_task_snapshot, "test_override")
	_check(not override_section.is_empty(), "TASK TEST door override section missing")
	if not override_section.is_empty():
		var override_row: Dictionary = _row(override_section, "test_override")
		_check(str(Dictionary(override_row.get("real_values", {})).get("operational_state", "")) == "closed", "override section lost real door state")
		_check(str(Dictionary(override_row.get("forced_values", {})).get("operational_state", "")) == "open", "override section lost forced door state")

	var door_runtime_plan: Dictionary = Renderer.build_plan(door_entity, {
		"mode":"runtime",
		"definition":door_definition,
		"test_override":{"forced_values":{"operational_state":"open"}}
	})
	var door_runtime_snapshot: Dictionary = Dictionary(door_runtime_plan.get("snapshot", {}))
	_check(_section(door_runtime_snapshot, "test_override").is_empty(), "normal runtime exposed TASK TEST override section")
	var runtime_operational_row: Dictionary = _row(_section(door_runtime_snapshot, "computed_status"), "operational")
	_check(not runtime_operational_row.has("forced_value"), "normal runtime applied TASK TEST forced value")

	var terminal_definition: Dictionary = {
		"display_name_template":"Terminal",
		"entity_contract":{
			"entity_type":"object",
			"entity_subtype":"terminal",
			"status_profile":"object_standard",
			"capabilities":{"state":true, "power":true, "health":false, "energy":false, "overheat":false, "control":true, "access":true, "bindings":true, "mount":false, "side":false, "routing":false, "test_override":false}
		},
		"property_schema":[]
	}
	var terminal_entity: Dictionary = {"id":"terminal_a", "object_type":"terminal", "display_name":"Terminal A", "intent_state":"on", "operational_state":"operational", "is_powered":true}
	var terminal_plan: Dictionary = Renderer.build_plan(terminal_entity, {"mode":"map_constructor", "definition":terminal_definition})
	_check(bool(terminal_plan.get("handled", false)), "canonical terminal used legacy fallback")
	var terminal_snapshot: Dictionary = Dictionary(terminal_plan.get("snapshot", {}))
	_check(not _section(terminal_snapshot, "identity").is_empty(), "canonical terminal identity section missing")
	_check(not _section(terminal_snapshot, "computed_status").is_empty(), "canonical terminal computed status missing")

	var legacy: Dictionary = Renderer.build_plan({"id":"legacy_a", "object_type":"unknown_legacy_fixture"}, {})
	_check(not bool(legacy.get("handled", true)), "genuinely noncanonical fixture lost legacy fallback")
	_check(str(legacy.get("code", "")) == "map_constructor.schema.legacy_fallback", "legacy fallback code changed")

	var passive_definition: Dictionary = {
		"display_name_template":"Passive Route",
		"entity_contract":{"entity_type":"object", "entity_subtype":"passive_route", "status_profile":"cooling_passive", "capabilities":{}},
		"property_schema":[]
	}
	var passive_plan: Dictionary = Renderer.build_plan({"id":"route_a", "object_type":"passive_route"}, {"definition":passive_definition})
	_check(bool(passive_plan.get("handled", false)), "canonical passive entity used legacy fallback")
	_check(_section(Dictionary(passive_plan.get("snapshot", {})), "computed_status").is_empty(), "passive entity received unsupported status section")

	if failures.is_empty():
		print("MAP_CONSTRUCTOR_SCHEMA_RENDERER_INTEGRATION_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("MAP_CONSTRUCTOR_SCHEMA_RENDERER_INTEGRATION_GATE: FAIL: %s" % failure)
	quit(1)
