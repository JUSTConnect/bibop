extends RefCounted
class_name MapConstructorSchemaInspectorRenderer

const ContextServiceRef = preload("res://scripts/ui/map_constructor/map_constructor_schema_context_service.gd")
const InspectorServiceRef = preload("res://scripts/game/map_constructor_schema_inspector_service.gd")
const ControlsRendererRef = preload("res://scripts/ui/map_constructor/map_constructor_schema_controls_renderer.gd")
const IssueContractRef = preload("res://scripts/game/map_constructor_issue_contract.gd")

const META_CANONICAL_RENDER := "map_constructor_canonical_render"
const META_SNAPSHOT_SIGNATURE := "map_constructor_schema_signature"

static func can_handle(data: Dictionary, supplied_definition: Dictionary = {}) -> bool:
	var definition: Dictionary = supplied_definition.duplicate(true)
	if definition.is_empty():
		definition = ContextServiceRef.definition_for(data)
	if definition.is_empty():
		return false
	var contract: Variant = definition.get("entity_contract", {})
	return contract is Dictionary and not Dictionary(contract).is_empty()

static func build_plan(entity: Dictionary, context: Dictionary = {}) -> Dictionary:
	var source: Dictionary = entity.duplicate(true)
	var definition: Dictionary = Dictionary(context.get("definition", {})).duplicate(true)
	if definition.is_empty():
		definition = ContextServiceRef.definition_for(source)
	if not can_handle(source, definition):
		return {
			"handled":false,
			"code":"map_constructor.schema.legacy_fallback",
			"reason_code":"map_constructor.schema.legacy_fallback",
			"snapshot":{},
			"issues":[]
		}
	var effective_context: Dictionary = context.duplicate(true)
	effective_context["definition"] = definition
	var snapshot: Dictionary = InspectorServiceRef.build(source, effective_context)
	var schema_issues: Array[Dictionary] = _schema_issues(snapshot, source)
	if not schema_issues.is_empty():
		snapshot = _with_schema_issues(snapshot, schema_issues)
	var signature_source: Dictionary = snapshot.duplicate(true)
	signature_source.erase("signature")
	snapshot["signature"] = str(hash(JSON.stringify(_canonical(signature_source))))
	return {
		"handled":true,
		"code":"map_constructor.schema.ready",
		"reason_code":"map_constructor.schema.ready",
		"definition":definition,
		"snapshot":snapshot,
		"issues":schema_issues
	}

static func render(ui: Variant, content: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> Dictionary:
	if ui == null or content == null or not is_instance_valid(content):
		return {"handled":false, "code":"map_constructor.schema.render_target_missing", "reason_code":"map_constructor.schema.render_target_missing"}
	var definition: Dictionary = ContextServiceRef.definition_for(data)
	if not can_handle(data, definition):
		return {"handled":false, "code":"map_constructor.schema.legacy_fallback", "reason_code":"map_constructor.schema.legacy_fallback"}
	var context: Dictionary = ContextServiceRef.build(ui, entity_id, data, definition)
	var plan: Dictionary = build_plan(data, context)
	if not bool(plan.get("handled", false)):
		return plan
	_clear_content(content)
	var snapshot: Dictionary = Dictionary(plan.get("snapshot", {}))
	for value in Array(snapshot.get("sections", [])):
		if not value is Dictionary:
			continue
		var section: Dictionary = Dictionary(value)
		if str(section.get("id", "")) == "editable_fields":
			ControlsRendererRef.render_editable(ui, content, entity_kind, entity_id, section, data)
		else:
			ControlsRendererRef.render_read_only(ui, content, section)
	content.set_meta(META_CANONICAL_RENDER, true)
	content.set_meta(META_SNAPSHOT_SIGNATURE, str(snapshot.get("signature", "")))
	plan["rendered_section_count"] = Array(snapshot.get("sections", [])).size()
	return plan

static func _schema_issues(snapshot: Dictionary, source: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for section_value in Array(snapshot.get("sections", [])):
		if not section_value is Dictionary:
			continue
		var section: Dictionary = Dictionary(section_value)
		if str(section.get("id", "")) != "editable_fields":
			continue
		for row_value in Array(section.get("rows", [])):
			if not row_value is Dictionary:
				continue
			var row: Dictionary = Dictionary(row_value)
			if str(row.get("control", "")) != "current_max":
				continue
			var descriptor: Dictionary = ControlsRendererRef.current_max_descriptor(row, source)
			if bool(descriptor.get("valid", false)):
				continue
			result.append(IssueContractRef.canonicalize({
				"code":str(descriptor.get("code", "map_constructor.schema.current_max_fields_invalid")),
				"severity":IssueContractRef.SEVERITY_ERROR,
				"blocks_promotion":true,
				"entity_id":str(snapshot.get("entity_id", "")),
				"field_id":str(row.get("field", "")),
				"message_key":"map_constructor.schema.current_max_fields_invalid",
				"fallback":"Current/max schema must declare two different current_field and max_field values.",
				"fix_hint":"Declare explicit current_field and max_field in the property schema.",
				"issue_type":"schema"
			}))
	return result

static func _with_schema_issues(snapshot: Dictionary, issues: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = snapshot.duplicate(true)
	var sections: Array[Dictionary] = []
	var issue_section_found: bool = false
	for value in Array(result.get("sections", [])):
		if not value is Dictionary:
			continue
		var section: Dictionary = Dictionary(value).duplicate(true)
		if str(section.get("id", "")) == "issues":
			var rows: Array = Array(section.get("rows", [])).duplicate(true)
			rows.append_array(issues)
			section["rows"] = IssueContractRef.canonicalize_all(rows)
			issue_section_found = true
		sections.append(section)
	if not issue_section_found:
		sections.append({"id":"issues", "label":"Warnings and Problems", "rows":IssueContractRef.canonicalize_all(issues)})
	result["sections"] = sections
	result["section_ids"] = _section_ids(sections)
	return result

static func _section_ids(sections: Array[Dictionary]) -> Array[String]:
	var result: Array[String] = []
	for section in sections:
		result.append(str(section.get("id", "")))
	return result

static func _clear_content(content: VBoxContainer) -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

static func _canonical(value: Variant) -> Variant:
	if value is Dictionary:
		var keys: Array = Dictionary(value).keys()
		keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
		var result: Dictionary = {}
		for key in keys:
			result[str(key)] = _canonical(Dictionary(value)[key])
		return result
	if value is Array:
		var values: Array = []
		for item in Array(value):
			values.append(_canonical(item))
		return values
	if value is Vector2i:
		return {"x":value.x, "y":value.y}
	if value is Vector2:
		return {"x":value.x, "y":value.y}
	return value
