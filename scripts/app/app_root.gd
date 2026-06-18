extends Control

# AppRoot
# Первый осязаемый vertical slice новой архитектуры.
# Запускается сразу и показывает: object list -> Identity -> Status -> Configurable Parameters -> Links.

const ObjectDefinitionCatalogRef = preload("res://scripts/domain/object_definition_catalog.gd")
const ObjectDataFactoryRef = preload("res://scripts/domain/object_data_factory.gd")
const ObjectStatusModelRef = preload("res://scripts/domain/object_status_model.gd")
const ObjectIdentityViewModelRef = preload("res://scripts/presentation/object_identity_view_model.gd")
const ObjectStatusViewModelRef = preload("res://scripts/presentation/object_status_view_model.gd")

const OBJECT_DEFINITION_PATHS: Array[String] = [
	"res://data/objects/power_source_basic.json",
	"res://data/objects/terminal_basic.json",
	"res://data/objects/door_basic.json"
]

const UI_BG := Color(0.055, 0.065, 0.085, 1.0)
const PANEL_BG := Color(0.09, 0.105, 0.135, 1.0)
const SECTION_BG := Color(0.12, 0.14, 0.18, 1.0)
const BORDER := Color(0.25, 0.5, 0.62, 0.85)
const ACCENT := Color(0.25, 0.78, 0.95, 1.0)
const OK := Color(0.25, 0.85, 0.48, 1.0)
const WARNING := Color(0.95, 0.7, 0.18, 1.0)

var object_definition_catalog: RefCounted = null
var object_definitions: Array[Dictionary] = []
var working_data_by_id: Dictionary = {}
var selected_index: int = 0

var object_list: VBoxContainer = null
var inspector_content: VBoxContainer = null
var status_label: Label = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_load_object_definitions()
	_build_layout()
	_select_object(0)


func _load_object_definitions() -> void:
	object_definition_catalog = ObjectDefinitionCatalogRef.new()
	object_definitions = object_definition_catalog.load_paths(OBJECT_DEFINITION_PATHS)
	working_data_by_id.clear()
	for definition in object_definitions:
		var object_id: String = str(definition.get("id", ""))
		working_data_by_id[object_id] = ObjectDataFactoryRef.make_initial_object_data(definition)


func _build_layout() -> void:
	var background := ColorRect.new()
	background.color = UI_BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var main_stack := VBoxContainer.new()
	main_stack.add_theme_constant_override("separation", 12)
	main_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(main_stack)
	main_stack.add_child(_build_header())

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_stack.add_child(body)

	var left_panel := _build_object_list_panel()
	left_panel.custom_minimum_size = Vector2(300, 0)
	body.add_child(left_panel)

	var right_panel := _build_inspector_panel()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(right_panel)

	status_label = Label.new()
	status_label.text = "Ready. Select object and test inspector structure."
	status_label.add_theme_color_override("font_color", ACCENT)
	main_stack.add_child(status_label)


func _build_header() -> Control:
	var panel := _make_panel_container()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(_wrap_margin(row, 12, 8))

	var title := Label.new()
	title.text = "NewBIP / Touch Test / Object Inspector"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)

	var reload_button := Button.new()
	reload_button.text = "Reload definitions"
	reload_button.pressed.connect(func() -> void:
		_load_object_definitions()
		_rebuild_object_list()
		_select_object(clampi(selected_index, 0, max(0, object_definitions.size() - 1)))
	)
	row.add_child(reload_button)
	return panel


func _build_object_list_panel() -> PanelContainer:
	var panel := _make_panel_container()
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	panel.add_child(_wrap_margin(stack, 10, 10))

	var title := Label.new()
	title.text = "Object Definitions"
	title.add_theme_color_override("font_color", ACCENT)
	stack.add_child(title)

	object_list = VBoxContainer.new()
	object_list.add_theme_constant_override("separation", 6)
	object_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(object_list)
	_rebuild_object_list()
	return panel


func _rebuild_object_list() -> void:
	if object_list == null:
		return
	for child in object_list.get_children():
		child.queue_free()
	for index in range(object_definitions.size()):
		var definition: Dictionary = object_definitions[index]
		var button := Button.new()
		button.text = "%s\n%s" % [str(definition.get("display_name", definition.get("id", "Object"))), str(definition.get("object_type", "unknown"))]
		button.custom_minimum_size = Vector2(0, 54)
		button.pressed.connect(func() -> void:
			_select_object(index)
		)
		object_list.add_child(button)


func _build_inspector_panel() -> PanelContainer:
	var panel := _make_panel_container()
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(_wrap_margin(scroll, 12, 10))

	inspector_content = VBoxContainer.new()
	inspector_content.add_theme_constant_override("separation", 10)
	inspector_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector_content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll.add_child(inspector_content)
	return panel


func _select_object(index: int) -> void:
	if object_definitions.is_empty():
		_render_empty_inspector()
		return
	selected_index = clampi(index, 0, object_definitions.size() - 1)
	_render_selected_object_inspector()


func _render_empty_inspector() -> void:
	_clear_inspector()
	var label := Label.new()
	label.text = "No object definitions found."
	label.add_theme_color_override("font_color", WARNING)
	inspector_content.add_child(label)


func _render_selected_object_inspector() -> void:
	_clear_inspector()
	var definition: Dictionary = object_definitions[selected_index]
	var object_id: String = str(definition.get("id", ""))
	var data: Dictionary = Dictionary(working_data_by_id.get(object_id, {}))
	var status: Dictionary = ObjectStatusModelRef.build_status(data)
	var identity_view_model: Dictionary = ObjectIdentityViewModelRef.create("world_object", object_id, data)
	var status_view_model: Dictionary = ObjectStatusViewModelRef.create(status)

	inspector_content.add_child(_build_view_model_section(identity_view_model))
	inspector_content.add_child(_make_section_separator())
	inspector_content.add_child(_build_view_model_section(status_view_model))
	inspector_content.add_child(_make_section_separator())
	inspector_content.add_child(_build_config_section(object_id, definition, data))
	inspector_content.add_child(_make_section_separator())
	inspector_content.add_child(_build_links_section(definition))
	_set_status("Selected: %s" % str(data.get("display_name", object_id)))


func _clear_inspector() -> void:
	if inspector_content == null:
		return
	for child in inspector_content.get_children():
		child.queue_free()


func _build_view_model_section(section_view_model: Dictionary) -> PanelContainer:
	var section := _make_section_panel(str(section_view_model.get("title", "Section")))
	var content: VBoxContainer = section.get_meta("content") as VBoxContainer
	for row_variant in Array(section_view_model.get("rows", [])):
		content.add_child(_build_view_model_row(Dictionary(row_variant)))
	return section


func _build_view_model_row(row_view_model: Dictionary) -> Control:
	var control_type: String = str(row_view_model.get("control_type", "readonly_text"))
	var label: String = str(row_view_model.get("label", row_view_model.get("id", "Value")))
	var value: Variant = row_view_model.get("value", "")
	var apply_mode: String = str(row_view_model.get("apply_mode", ""))
	var field_id: String = str(row_view_model.get("id", ""))
	var entity_id: String = str(row_view_model.get("entity_id", ""))

	match control_type:
		"line_edit":
			var edit := LineEdit.new()
			edit.text = str(value)
			if apply_mode == "inline":
				return _make_apply_row(label, edit, func() -> void:
					_apply_object_patch(entity_id, {field_id: edit.text}, "%s updated." % label)
				)
			return _make_property_row(label, edit)
		"text_edit":
			var text_edit := TextEdit.new()
			text_edit.text = str(value)
			text_edit.custom_minimum_size = Vector2(0, 78)
			if apply_mode == "inline":
				return _make_apply_row(label, text_edit, func() -> void:
					_apply_object_patch(entity_id, {field_id: text_edit.text}, "%s updated." % label)
				)
			return _make_property_row(label, text_edit)
		_:
			return _make_readonly_row(label, str(value))


func _build_config_section(object_id: String, definition: Dictionary, data: Dictionary) -> PanelContainer:
	var section := _make_section_panel("3. Configurable Parameters")
	var content: VBoxContainer = section.get_meta("content") as VBoxContainer
	var schema_rows: Array = Array(definition.get("config_schema", []))
	if schema_rows.is_empty():
		content.add_child(_make_readonly_row("Info", "No configurable parameters."))
		return section
	for row_variant in schema_rows:
		var schema_row: Dictionary = Dictionary(row_variant)
		var field_id: String = str(schema_row.get("id", ""))
		if field_id.is_empty():
			continue
		content.add_child(_build_config_row(object_id, field_id, schema_row, data.get(field_id, schema_row.get("default", ""))))
	return section


func _build_config_row(object_id: String, field_id: String, schema_row: Dictionary, value: Variant) -> Control:
	var field_type: String = str(schema_row.get("type", "string"))
	var label: String = str(schema_row.get("label", field_id.replace("_", " ").capitalize()))
	match field_type:
		"enum":
			var option := OptionButton.new()
			var values: Array = Array(schema_row.get("values", schema_row.get("options", [])))
			var selected: int = 0
			for index in range(values.size()):
				var option_value: String = str(values[index])
				option.add_item(option_value)
				option.set_item_metadata(index, option_value)
				if option_value == str(value):
					selected = index
			option.select(selected)
			option.item_selected.connect(func(index: int) -> void:
				_apply_object_patch(object_id, {field_id: option.get_item_metadata(index)}, "%s updated." % label)
			)
			return _make_property_row(label, option)
		"int":
			var spin := SpinBox.new()
			spin.step = 1
			spin.min_value = float(schema_row.get("min", 0))
			spin.max_value = float(schema_row.get("max", 999))
			spin.value = _to_float(value, spin.min_value)
			return _make_apply_row(label, spin, func() -> void:
				_apply_object_patch(object_id, {field_id: int(spin.value)}, "%s updated." % label)
			)
		_:
			var edit := LineEdit.new()
			edit.text = str(value)
			return _make_apply_row(label, edit, func() -> void:
				_apply_object_patch(object_id, {field_id: edit.text}, "%s updated." % label)
			)


func _build_links_section(definition: Dictionary) -> PanelContainer:
	var section := _make_section_panel("4. Links")
	var content: VBoxContainer = section.get_meta("content") as VBoxContainer
	var links_schema: Array = Array(definition.get("links_schema", []))
	if links_schema.is_empty():
		content.add_child(_make_readonly_row("Info", "No links."))
		return section
	for link_variant in links_schema:
		var link: Dictionary = Dictionary(link_variant)
		content.add_child(_make_readonly_row(str(link.get("label", link.get("id", "Link"))), "type=%s" % str(link.get("type", "unknown"))))
	return section


func _apply_object_patch(object_id: String, patch: Dictionary, message: String) -> void:
	var data: Dictionary = Dictionary(working_data_by_id.get(object_id, {})).duplicate(true)
	for key in patch.keys():
		data[key] = patch[key]
	data["power_state"] = ObjectDataFactoryRef.infer_power_state(data)
	working_data_by_id[object_id] = data
	_set_status(message)
	_render_selected_object_inspector()


func _make_section_panel(title: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style(SECTION_BG, BORDER, 1, 6))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(_wrap_margin(content, 10, 8))
	panel.set_meta("content", content)

	var header := Label.new()
	header.text = title
	header.add_theme_color_override("font_color", ACCENT)
	header.add_theme_font_size_override("font_size", 18)
	content.add_child(header)
	return panel


func _make_property_row(label_text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(170, 0)
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row


func _make_apply_row(label_text: String, control: Control, callback: Callable) -> HBoxContainer:
	var row := _make_property_row(label_text, control)
	var apply_button := Button.new()
	apply_button.text = "Apply"
	apply_button.custom_minimum_size = Vector2(84, 30)
	apply_button.pressed.connect(callback)
	row.add_child(apply_button)
	return row


func _make_readonly_row(label_text: String, value_text: String) -> HBoxContainer:
	var label := Label.new()
	label.text = value_text
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if value_text == "Ready" or value_text == "powered":
		label.add_theme_color_override("font_color", OK)
	elif value_text == "Not ready" or value_text == "unpowered":
		label.add_theme_color_override("font_color", WARNING)
	return _make_property_row(label_text, label)


func _make_section_separator() -> PanelContainer:
	var separator := PanelContainer.new()
	separator.custom_minimum_size = Vector2(0, 8)
	separator.add_theme_stylebox_override("panel", _make_panel_style(BORDER, BORDER, 0, 0))
	return separator


func _make_panel_container() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style(PANEL_BG, BORDER, 1, 8))
	return panel


func _wrap_margin(child: Control, horizontal: int, vertical: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", horizontal)
	margin.add_theme_constant_override("margin_right", horizontal)
	margin.add_theme_constant_override("margin_top", vertical)
	margin.add_theme_constant_override("margin_bottom", vertical)
	margin.add_child(child)
	return margin


func _make_panel_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _to_float(value: Variant, fallback: float) -> float:
	if value is float or value is int:
		return float(value)
	var text: String = str(value)
	return float(text) if text.is_valid_float() else fallback


func _set_status(text: String) -> void:
	if status_label != null:
		status_label.text = text
