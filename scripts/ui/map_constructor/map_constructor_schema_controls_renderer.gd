extends RefCounted
class_name MapConstructorSchemaControlsRenderer

const PropertyControlsRef = preload("res://scripts/ui/map_constructor/map_constructor_property_controls.gd")
const LinkControlsRef = preload("res://scripts/ui/map_constructor/map_constructor_link_controls.gd")

static func render_editable(ui: Variant, parent: VBoxContainer, entity_kind: String, entity_id: String, section: Dictionary, source_data: Dictionary = {}) -> void:
	var box: VBoxContainer = ui._create_inspector_section(str(section.get("label", "Properties")))
	for value in Array(section.get("rows", [])):
		if not value is Dictionary:
			continue
		var row: Dictionary = Dictionary(value)
		var field_name: String = str(row.get("field", ""))
		var label: String = str(row.get("label", field_name.replace("_", " ").capitalize()))
		var control: String = str(row.get("control", "text"))
		var schema: Dictionary = Dictionary(row.get("schema", {}))
		var current_value: Variant = row.get("value")
		match control:
			"checkbox":
				PropertyControlsRef.add_bool_property(ui, box, label, entity_kind, entity_id, field_name, current_value)
			"enum", "mount_selector", "side_selector", "routing_selector":
				PropertyControlsRef.add_enum_property(ui, box, label, entity_kind, entity_id, field_name, current_value, _enum_options(schema))
			"enum_multi":
				PropertyControlsRef.add_enum_array_property(ui, box, label, entity_kind, entity_id, field_name, current_value, Array(schema.get("values", [])))
			"number", "range":
				_render_number(ui, box, label, entity_kind, entity_id, field_name, current_value, schema)
			"current_max":
				_render_current_max(ui, box, label, entity_kind, entity_id, row, source_data)
			"entity_picker", "resource_picker", "item_picker":
				LinkControlsRef.add_single_link_property(ui, box, label, entity_kind, entity_id, field_name, current_value, str(schema.get("target_group", "")), schema)
			"entity_picker_array":
				PropertyControlsRef.add_object_ref_array_property(ui, box, label, entity_kind, entity_id, field_name, current_value)
			"read_only":
				add_label_row(ui, box, label, current_value)
			_:
				PropertyControlsRef.add_text_property(ui, box, label, entity_kind, entity_id, field_name, current_value)
	parent.add_child(box)

static func render_read_only(ui: Variant, parent: VBoxContainer, section: Dictionary) -> void:
	var box: VBoxContainer = ui._create_inspector_section(str(section.get("label", str(section.get("id", "Section")).capitalize())))
	for value in Array(section.get("rows", [])):
		if value is Dictionary:
			var row: Dictionary = Dictionary(value)
			var label: String = str(row.get("label", row.get("field", row.get("code", "Value"))))
			add_label_row(ui, box, label, _read_only_display(row))
	parent.add_child(box)

static func add_label_row(ui: Variant, box: VBoxContainer, label: String, value: Variant) -> void:
	var value_label: Label = Label.new()
	value_label.text = str(value)
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(ui._create_property_row(label, value_label))

static func current_max_descriptor(row: Dictionary, source_data: Dictionary) -> Dictionary:
	var schema: Dictionary = Dictionary(row.get("schema", {}))
	var current_field: String = str(schema.get("current_field", "")).strip_edges()
	var max_field: String = str(schema.get("max_field", "")).strip_edges()
	if current_field.is_empty() or max_field.is_empty() or current_field == max_field:
		return {
			"valid":false,
			"code":"map_constructor.schema.current_max_fields_invalid",
			"current_field":current_field,
			"max_field":max_field
		}
	return {
		"valid":true,
		"code":"map_constructor.schema.current_max_valid",
		"current_field":current_field,
		"max_field":max_field,
		"current_value":source_data.get(current_field, schema.get("current_default", 0)),
		"max_value":source_data.get(max_field, schema.get("max_default", schema.get("default", 0))),
		"current_editable":bool(schema.get("current_editable", false)),
		"max_editable":bool(schema.get("max_editable", true)),
		"min":float(schema.get("min", 0.0)),
		"max":float(schema.get("max", 999999.0)),
		"step":float(schema.get("step", 1.0)),
		"value_type":str(schema.get("value_type", "int")).strip_edges().to_lower()
	}

static func _enum_options(schema: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var labels: Dictionary = Dictionary(schema.get("labels", {}))
	for value in Array(schema.get("values", [])):
		var text: String = str(value)
		result.append({"label":str(labels.get(text, text.replace("_", " ").capitalize())), "value":text})
	return result

static func _render_number(ui: Variant, box: VBoxContainer, label: String, entity_kind: String, entity_id: String, field_name: String, current_value: Variant, schema: Dictionary) -> void:
	var spin: SpinBox = _spin_box(current_value, schema)
	spin.value_changed.connect(func(value: float) -> void:
		var next_value: Variant = value
		if str(schema.get("type", "")) == "int":
			next_value = int(value)
		ui._apply_map_constructor_property_updates(entity_kind, entity_id, {field_name:next_value})
	)
	box.add_child(ui._create_property_row(label, spin))

static func _render_current_max(ui: Variant, box: VBoxContainer, label: String, entity_kind: String, entity_id: String, row: Dictionary, source_data: Dictionary) -> void:
	var descriptor: Dictionary = current_max_descriptor(row, source_data)
	if not bool(descriptor.get("valid", false)):
		add_label_row(ui, box, label, "Invalid current/max schema")
		return
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 6)
	var schema: Dictionary = Dictionary(row.get("schema", {})).duplicate(true)
	schema["min"] = descriptor.get("min", 0.0)
	schema["max"] = descriptor.get("max", 999999.0)
	schema["step"] = descriptor.get("step", 1.0)
	var current_control: Control
	if bool(descriptor.get("current_editable", false)):
		var current_spin: SpinBox = _spin_box(descriptor.get("current_value", 0), schema)
		current_spin.value_changed.connect(func(value: float) -> void:
			ui._apply_map_constructor_property_updates(entity_kind, entity_id, {str(descriptor.get("current_field", "")):_typed_number(value, descriptor)})
		)
		current_control = current_spin
	else:
		var current_label := Label.new()
		current_label.text = str(descriptor.get("current_value", 0))
		current_control = current_label
	controls.add_child(current_control)
	var separator := Label.new()
	separator.text = "/"
	controls.add_child(separator)
	if bool(descriptor.get("max_editable", true)):
		var max_spin: SpinBox = _spin_box(descriptor.get("max_value", 0), schema)
		max_spin.value_changed.connect(func(value: float) -> void:
			ui._apply_map_constructor_property_updates(entity_kind, entity_id, {str(descriptor.get("max_field", "")):_typed_number(value, descriptor)})
		)
		controls.add_child(max_spin)
	else:
		var max_label := Label.new()
		max_label.text = str(descriptor.get("max_value", 0))
		controls.add_child(max_label)
	box.add_child(ui._create_property_row(label, controls))

static func _spin_box(value: Variant, schema: Dictionary) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = float(schema.get("min", -999999.0))
	spin.max_value = float(schema.get("max", 999999.0))
	spin.step = float(schema.get("step", 1.0))
	spin.value = float(value if value != null else schema.get("default", 0.0))
	return spin

static func _typed_number(value: float, descriptor: Dictionary) -> Variant:
	if str(descriptor.get("value_type", "int")) == "int":
		return int(value)
	return value

static func _read_only_display(row: Dictionary) -> Variant:
	if row.has("value"):
		if row.has("real_value") and row.has("forced_value"):
			return "%s (real: %s, forced: %s)" % [str(row.get("value")), str(row.get("real_value")), str(row.get("forced_value"))]
		return row.get("value")
	if row.has("fallback"):
		var hint: String = str(row.get("fix_hint", "")).strip_edges()
		return str(row.get("fallback", "")) if hint.is_empty() else "%s — %s" % [str(row.get("fallback", "")), hint]
	if row.has("role") and row.has("source_name") and row.has("target_name"):
		return "%s: %s → %s" % [str(row.get("role", "")), str(row.get("source_name", "")), str(row.get("target_name", ""))]
	if row.has("real_values") or row.has("forced_values"):
		return "real=%s forced=%s" % [str(row.get("real_values", {})), str(row.get("forced_values", {}))]
	return row
