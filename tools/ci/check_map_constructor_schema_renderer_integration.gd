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
