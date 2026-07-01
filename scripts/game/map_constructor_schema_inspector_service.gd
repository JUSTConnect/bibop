extends RefCounted
class_name MapConstructorSchemaInspectorService

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const EntityStatusEvaluatorRef = preload("res://scripts/world/entity_status_evaluator.gd")
const IssueContractRef = preload("res://scripts/game/map_constructor_issue_contract.gd")

const SECTION_ORDER: Array[String] = [
	"identity", "editable_fields", "capabilities", "computed_status", "logical_bindings",
	"physical_topology", "issues", "test_override"
]

const CONTROL_BY_SCHEMA_TYPE: Dictionary = {
	"bool":"checkbox",
	"enum":"enum",
	"enum_array":"enum_multi",
	"int":"number",
	"float":"number",
	"number":"number",
	"range":"range",
	"current_max":"current_max",
	"object_ref":"entity_picker",
	"object_ref_array":"entity_picker_array",
	"mount_selector":"mount_selector",
	"side_selector":"side_selector",
	"routing_selector":"routing_selector",
	"resource_picker":"resource_picker",
	"item_picker":"item_picker",
	"read_only":"read_only",
	"readonly":"read_only",
	"computed":"read_only",
	"string":"text",
	"text":"text"
}

static func control_kind_for_schema(row: Dictionary) -> String:
	var field_type: String = str(row.get("type", "string")).strip_edges().to_lower()
	return str(CONTROL_BY_SCHEMA_TYPE.get(field_type, "text"))

static func build(entity: Dictionary, context: Dictionary = {}) -> Dictionary:
	var source: Dictionary = entity.duplicate(true)
	var definition: Dictionary = _definition(source, context)
	var contract: Dictionary = Dictionary(definition.get("entity_contract", WorldObjectCatalogRef.get_entity_definition_contract_for_object(source))).duplicate(true)
	var capabilities: Dictionary = Dictionary(contract.get("capabilities", {})).duplicate(true)
	var status_context: Dictionary = _status_context(context)
	var status_result: Dictionary = EntityStatusEvaluatorRef.evaluate_synthetic_for_test(source, contract, status_context)
	var entity_id: String = str(source.get("id", "")).strip_edges()
	var entities_by_id: Dictionary = Dictionary(context.get("entities_by_id", {})).duplicate(true)
	if not entity_id.is_empty() and not entities_by_id.has(entity_id):
		entities_by_id[entity_id] = source.duplicate(true)

	var sections_by_id: Dictionary = {}
	sections_by_id["identity"] = _identity_section(source, definition, contract)
	var editable: Dictionary = _editable_section(source, definition)
	if not Array(editable.get("rows", [])).is_empty():
		sections_by_id["editable_fields"] = editable
	var capability_section: Dictionary = _capability_section(capabilities)
	if not Array(capability_section.get("rows", [])).is_empty():
		sections_by_id["capabilities"] = capability_section
	var status_section: Dictionary = _status_section(status_result, bool(context.get("debug", false)))
	if not Array(status_section.get("rows", [])).is_empty():
		sections_by_id["computed_status"] = status_section
	var binding_section: Dictionary = _binding_section(entity_id, Array(context.get("bindings", [])), entities_by_id)
	if not Array(binding_section.get("rows", [])).is_empty():
		sections_by_id["logical_bindings"] = binding_section
	var physical_section: Dictionary = _physical_section(Dictionary(context.get("physical_topology", {})))
	if not Array(physical_section.get("rows", [])).is_empty():
		sections_by_id["physical_topology"] = physical_section
	var issue_section: Dictionary = _issue_section(Array(context.get("issues", [])), entity_id)
	if not Array(issue_section.get("rows", [])).is_empty():
		sections_by_id["issues"] = issue_section
	var override_section: Dictionary = _test_override_section(capabilities, context, status_result)
	if not Array(override_section.get("rows", [])).is_empty():
		sections_by_id["test_override"] = override_section

	var sections: Array[Dictionary] = []
	for section_id in SECTION_ORDER:
		if sections_by_id.has(section_id):
			sections.append(Dictionary(sections_by_id[section_id]).duplicate(true))
	var snapshot: Dictionary = {
		"entity_id":entity_id,
		"sections":sections,
		"section_ids":_section_ids(sections),
		"signature":""
	}
	var unsigned: Dictionary = snapshot.duplicate(true)
	unsigned.erase("signature")
	snapshot["signature"] = str(hash(JSON.stringify(_canonical(unsigned))))
	return snapshot

static func _definition(source: Dictionary, context: Dictionary) -> Dictionary:
	var supplied: Variant = context.get("definition", {})
	if supplied is Dictionary and not Dictionary(supplied).is_empty():
		return Dictionary(supplied).duplicate(true)
	var prefab_id: String = str(source.get("map_constructor_prefab_id", source.get("archetype_id", source.get("object_type", source.get("item_type", ""))))).strip_edges()
	return WorldObjectCatalogRef.get_constructor_prefab_definition(prefab_id)

static func _status_context(context: Dictionary) -> Dictionary:
	var result: Dictionary = Dictionary(context.get("status_context", {})).duplicate(true)
	var mode: String = str(context.get("mode", "")).strip_edges().to_lower()
	if not mode.is_empty():
		result["mode"] = mode
	var override: Variant = context.get("test_override", {})
	if override is Dictionary and not Dictionary(override).is_empty():
		var raw_forced: Variant = Dictionary(override).get("forced_values", override)
		if raw_forced is Dictionary:
			result["supports_test_override"] = true
			result["forced_values"] = _normalized_forced_values(Dictionary(raw_forced))
	return result

static func _normalized_forced_values(values: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var aliases: Dictionary = {
		"intent":"intent_state",
		"operational":"operational_state",
		"health":"health_state",
		"thermal":"thermal_state"
	}
	for key in values.keys():
		var field_name: String = str(key).strip_edges().to_lower()
		field_name = str(aliases.get(field_name, field_name))
		result[field_name] = values[key]
	return result

static func _identity_section(source: Dictionary, definition: Dictionary, contract: Dictionary) -> Dictionary:
	var rows: Array[Dictionary] = [
		{"field":"display_name", "label":"Name", "value":str(source.get("display_name", source.get("name", definition.get("display_name_template", "Entity")))), "control":"read_only"},
		{"field":"entity_type", "label":"Type", "value":str(contract.get("entity_type", "")), "control":"read_only"}
	]
	var subtype: String = str(contract.get("entity_subtype", "")).strip_edges()
	if not subtype.is_empty():
		rows.append({"field":"entity_subtype", "label":"Subtype", "value":subtype, "control":"read_only"})
	var description: String = str(source.get("description", definition.get("description", ""))).strip_edges()
	if not description.is_empty():
		rows.append({"field":"description", "label":"Description", "value":description, "control":"read_only"})
	return {"id":"identity", "label":"Identity", "rows":rows}

static func _editable_section(source: Dictionary, definition: Dictionary) -> Dictionary:
	var rows: Array[Dictionary] = []
	for value in Array(definition.get("property_schema", [])):
		if not value is Dictionary:
			continue
		var schema: Dictionary = Dictionary(value).duplicate(true)
		if bool(schema.get("internal", false)) or bool(schema.get("legacy", false)):
			continue
		var field_name: String = str(schema.get("field", "")).strip_edges()
		if field_name.is_empty():
			continue
		rows.append({
			"field":field_name,
			"label":str(schema.get("label", field_name.replace("_", " ").capitalize())),
			"control":control_kind_for_schema(schema),
			"value":source.get(field_name, schema.get("default")),
			"schema":schema
		})
	return {"id":"editable_fields", "label":"Properties", "rows":rows}

static func _capability_section(capabilities: Dictionary) -> Dictionary:
	var rows: Array[Dictionary] = []
	var keys: Array = capabilities.keys()
	keys.sort()
	for key in keys:
		if bool(capabilities[key]):
			rows.append({"field":str(key), "label":str(key).replace("_", " ").capitalize(), "value":true, "control":"read_only"})
	return {"id":"capabilities", "label":"Capabilities", "rows":rows}

static func _status_section(result: Dictionary, debug_enabled: bool) -> Dictionary:
	var rows: Array[Dictionary] = []
	var sections: Dictionary = Dictionary(result.get("sections", {}))
	var keys: Array = sections.keys()
	keys.sort()
	for key in keys:
		var source_row: Dictionary = Dictionary(sections[key])
		var row: Dictionary = {"field":str(key), "label":str(key).replace("_", " ").capitalize(), "value":source_row.get("value"), "control":"read_only"}
		if source_row.has("real_value"):
			row["real_value"] = source_row.get("real_value")
		if source_row.has("forced_value"):
			row["forced_value"] = source_row.get("forced_value")
		if debug_enabled:
			row["reason_code"] = str(result.get("reason_code", ""))
		rows.append(row)
	return {"id":"computed_status", "label":"Computed Status", "rows":rows}

static func _binding_section(entity_id: String, bindings: Array, entities_by_id: Dictionary) -> Dictionary:
	var rows: Array[Dictionary] = []
	for value in bindings:
		if not value is Dictionary:
			continue
		var binding: Dictionary = Dictionary(value)
		var source_id: String = str(binding.get("source_id", ""))
		var target_id: String = str(binding.get("target_id", ""))
		if source_id != entity_id and target_id != entity_id:
			continue
		rows.append({
			"binding_id":str(binding.get("id", "")),
			"role":str(binding.get("role", "")),
			"source_id":source_id,
			"source_name":_entity_name(Dictionary(entities_by_id.get(source_id, {}))),
			"target_id":target_id,
			"target_name":_entity_name(Dictionary(entities_by_id.get(target_id, {}))),
			"parameters":Dictionary(binding.get("parameters", {})).duplicate(true),
			"control":"read_only"
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return "%s|%s|%s" % [a.get("role", ""), a.get("source_id", ""), a.get("target_id", "")] < "%s|%s|%s" % [b.get("role", ""), b.get("source_id", ""), b.get("target_id", "")])
	return {"id":"logical_bindings", "label":"Logical Bindings", "rows":rows}

static func _physical_section(topology: Dictionary) -> Dictionary:
	var rows: Array[Dictionary] = []
	var keys: Array = topology.keys()
	keys.sort()
	for key in keys:
		rows.append({"field":str(key), "label":str(key).replace("_", " ").capitalize(), "value":topology[key], "control":"read_only"})
	return {"id":"physical_topology", "label":"Physical Topology", "rows":rows}

static func _issue_section(values: Array, entity_id: String) -> Dictionary:
	var rows: Array[Dictionary] = []
	for issue in IssueContractRef.canonicalize_all(values):
		if not entity_id.is_empty() and not str(issue.get("entity_id", "")).is_empty() and str(issue.get("entity_id", "")) != entity_id:
			continue
		rows.append(issue)
	return {"id":"issues", "label":"Warnings and Problems", "rows":rows}

static func _test_override_section(capabilities: Dictionary, context: Dictionary, status_result: Dictionary) -> Dictionary:
	var mode: String = str(context.get("mode", "")).strip_edges().to_lower()
	if not bool(capabilities.get("test_override", false)) or mode not in ["map_constructor", "task_test"]:
		return {"id":"test_override", "label":"Test Override", "rows":[]}
	var override: Dictionary = Dictionary(context.get("test_override", {})).duplicate(true)
	if override.is_empty():
		return {"id":"test_override", "label":"Test Override", "rows":[]}
	var forced_values: Dictionary = Dictionary(status_result.get("forced_values", {})).duplicate(true)
	if forced_values.is_empty():
		forced_values = _normalized_forced_values(Dictionary(override.get("forced_values", override)))
	return {
		"id":"test_override",
		"label":"Test Override",
		"rows":[{
			"field":"test_override",
			"control":"read_only",
			"real_values":Dictionary(status_result.get("real_values", {})).duplicate(true),
			"forced_values":forced_values
		}]
	}

static func _entity_name(entity: Dictionary) -> String:
	if entity.is_empty():
		return "Missing entity"
	return str(entity.get("display_name", entity.get("name", entity.get("object_type", "Entity"))))

static func _section_ids(sections: Array[Dictionary]) -> Array[String]:
	var result: Array[String] = []
	for section in sections:
		result.append(str(section.get("id", "")))
	return result

static func _canonical(value: Variant) -> Variant:
	if value is Dictionary:
		var keys: Array = Dictionary(value).keys()
		keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
		var result: Dictionary = {}
		for key in keys:
			result[str(key)] = _canonical(Dictionary(value)[key])
		return result
	if value is Array:
		var result_array: Array = []
		for item in Array(value):
			result_array.append(_canonical(item))
		return result_array
	if value is Vector2i:
		return {"x":value.x, "y":value.y}
	if value is Vector2:
		return {"x":value.x, "y":value.y}
	return value
