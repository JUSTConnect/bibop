extends RefCounted
class_name MapConstructorSchemaControlsRenderer

const PropertyControlsRef = preload("res://scripts/ui/map_constructor/map_constructor_property_controls.gd")
const LinkControlsRef = preload("res://scripts/ui/map_constructor/map_constructor_link_controls.gd")

static func render_editable(ui: Variant, parent: VBoxContainer, entity_kind: String, entity_id: String, section: Dictionary) -> void:
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
			"number", "range", "current_max":
				_render_number(ui, box, label, entity_kind, entity_id, field_name, current_value, schema)
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
			var display: Variant = row.get("value", row.get("fallback", row.get("state", row)))
			add_label_row(ui, box, label, display)
	parent.add_child(box)

static func add_label_row(ui: Variant, box: VBoxContainer, label: String, value: Variant) -> void:
	var value_label: Label = Label.new()
	value_label.text = str(value)
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(ui._create_property_row(label, value_label))

static func _enum_options(schema: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var labels: Dictionary = Dictionary(schema.get("labels", {}))
	for value in Array(schema.get("values", [])):
		var text: String = str(value)
		result.append({"label":str(labels.get(text, text.replace("_", " ").capitalize())), "value":text})
	return result

static func _render_number(ui: Variant, box: VBoxContainer, label: String, entity_kind: String, entity_id: String, field_name: String, current_value: Variant, schema: Dictionary) -> void:
	var spin: SpinBox = SpinBox.new()
	spin.min_value = float(schema.get("min", -999999.0))
	spin.max_value = float(schema.get("max", 999999.0))
	spin.step = float(schema.get("step", 1.0))
	spin.value = float(current_value if current_value != null else schema.get("default", 0.0))
	spin.value_changed.connect(func(value: float) -> void:
		var next_value: Variant = int(value) if str(schema.get("type", "")) == "int" else value
		ui._apply_map_constructor_property_updates(entity_kind, entity_id, {field_name:next_value})
	)
	box.add_child(ui._create_property_row(label, spin))
