extends Control

# NewBIP first touchable vertical slice.
# Запускаемый тест: object list + shared object inspector.
# Цель: формировать UI правильно сразу, без post-process слоёв и patch/recovery логики.

const OBJECT_DEFINITION_PATHS: Array[String] = [
	"res://data/objects/power_source_basic.json",
	"res://data/objects/terminal_basic.json",
	"res://data/objects/door_basic.json",
]

const UI_BG := Color(0.055, 0.065, 0.085, 1.0)
const PANEL_BG := Color(0.09, 0.105, 0.135, 1.0)
const SECTION_BG := Color(0.12, 0.14, 0.18, 1.0)
const BORDER := Color(0.25, 0.5, 0.62, 0.85)
const ACCENT := Color(0.25, 0.78, 0.95, 1.0)
const OK := Color(0.25, 0.85, 0.48, 1.0)
const WARNING := Color(0.95, 0.7, 0.18, 1.0)

var object_definitions: Array[Dictionary] = []
var selected_index: int = 0
var working_data_by_id: Dictionary = {}

var object_list: VBoxContainer = null
var inspector_content: VBoxContainer = null
var status_label: Label = null
var title_label: Label = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_load_object_definitions()
	_build_layout()
	_select_object(0)


func _load_object_definitions() -> void:
	object_definitions.clear()
	working_data_by_id.clear()
	for path in OBJECT_DEFINITION_PATHS:
		var parsed: Dictionary = _load_json_dictionary(path)
		if parsed.is_empty():
			continue
		object_definitions.append(parsed)
		working_data_by_id[str(parsed.get("id", ""))] = _make_initial_object_data(parsed)


func _load_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Missing object definition: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Cannot open object definition: %s" % path)
		return {}
	var text := file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return Dictionary(parsed)
	push_warning("Invalid object definition JSON: %s" % path)
	return {}


func _make_initial_object_data(definition: Dictionary) -> Dictionary:
	var data: Dictionary = Dictionary(definition.get("base_parameters", {})).duplicate(true)
	data["id"] = str(definition.get("id", ""))
	data["object_type"] = str(definition.get("object_type", "unknown"))
	data["object_group"] = str(definition.get("object_group", "generic"))
	data["display_name"] = str(definition.get("display_name", definition.get("id", "Object")))
	data["description"] = str(definition.get("description", ""))
	data["visual_id"] = str(definition.get("visual_id", ""))
	data["power_state"] = _infer_power_state(data)
	return data


func _build_layout() -> void:
	var root_bg := ColorRect.new()
	root_bg.color = UI_BG
	root_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_bg)

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

	var header := _build_header()
	main_stack.add_child(header)

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
	status_label.text = "Ready. Select object and test Identity / Status / Configurable Parameters."
	status_label.add_theme_color_override("font_color", ACCENT)
	main_stack.add_child(status_label)


func _build_header() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style(PANEL_BG, BORDER, 1, 8))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)

	title_label = Label.new()
	title_label.text = "NewBIP / Object Inspector Test Slice"
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", ACCENT)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_label)

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
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style(PANEL_BG, BORDER, 1, 8))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	margin.add_child(stack)

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
		var definition := object_definitions[index]
		var button := Button.new()
		button.text = "%s\n%s" % [str(definition.get("display_name", definition.get("id", "Object"))), str(definition.get("object_type", "unknown"))]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 54)
		button.pressed.connect(func() -> void:
			_select_object(index)
		)
		object_list.add_child(button)


func _build_inspector_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style(PANEL_BG, BORDER, 1, 8))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

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
	var definition := object_definitions[selected_index]
	var object_id := str(definition.get("id", ""))
	var data := Dictionary(working_data_by_id.get(object_id, {}))
	var status := _build_status(data)

	inspector_content.add_child(_build_identity_section(object_id, data))
	inspector_content.add_child(_make_section_separator())
	inspector_content.add_child(_build_status_section(status))
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


func _build_identity_section(object_id: String, data: Dictionary) -> VBoxContainer:
	var section := _make_section("1. Identity")

	var name_edit := LineEdit.new()
	name_edit.text = str(data.get("display_name", ""))
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_child(_make_apply_row("Name", name_edit, func() -> void:
		_apply_object_patch(object_id, {"display_name": name_edit.text}, "Name updated.")
	))

	var description_edit := TextEdit.new()
	description_edit.text = str(data.get("description", ""))
	description_edit.custom_minimum_size = Vector2(0, 78)
	description_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_child(_make_apply_row("Description", description_edit, func() -> void:
		_apply_object_patch(object_id, {"description": description_edit.text}, "Description updated.")
	))

	return section


func _build_status_section(status: Dictionary) -> VBoxContainer:
	var section := _make_section("2. Status")
	section.add_child(_make_readonly_row("Object type", str(status.get("object_type", "unknown"))))
	section.add_child(_make_readonly_row("Total state", str(status.get("total_state", "unknown"))))
	section.add_child(_make_readonly_row("Power state", str(status.get("power_state", "none"))))
	return section


func _build_config_section(object_id: String, definition: Dictionary, data: Dictionary) -> VBoxContainer:
	var section := _make_section("3. Configurable Parameters")
	var schema_rows: Array = Array(definition.get("config_schema", []))
	if schema_rows.is_empty():
		section.add_child(_make_readonly_row("Info", "No configurable parameters."))
		return section
	for row_variant in schema_rows:
		var schema_row := Dictionary(row_variant)
		var field_id := str(schema_row.get("id", ""))
		if field_id.is_empty():
			continue
		section.add_child(_build_config_row(object_id, field_id, schema_row, data.get(field_id, schema_row.get("default", ""))))
	return section


func _build_config_row(object_id: String, field_id: String, schema_row: Dictionary, value: Variant) -> Control:
	var field_type := str(schema_row.get("type", "string"))
	var label := str(schema_row.get("label", field_id.replace("_", " ").capitalize()))
	match field_type:
		"enum":
			var option := OptionButton.new()
			var values := Array(schema_row.get("values", schema_row.get("options", [])))
			var selected := 0
			for index in range(values.size()):
				var option_value := str(values[index])
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
			spin.value = float(value) if str(value).is_valid_float() else float(schema_row.get("min", 0))
			return _make_apply_row(label, spin, func() -> void:
				_apply_object_patch(object_id, {field_id: int(spin.value)}, "%s updated." % label)
			)
		_:
			var edit := LineEdit.new()
			edit.text = str(value)
			return _make_apply_row(label, edit, func() -> void:
				_apply_object_patch(object_id, {field_id: edit.text}, "%s updated." % label)
			)


func _build_links_section(definition: Dictionary) -> VBoxContainer:
	var section := _make_section("4. Links")
	var links_schema: Array = Array(definition.get("links_schema", []))
	if links_schema.is_empty():
		section.add_child(_make_readonly_row("Info", "No links."))
		return section
	for link_variant in links_schema:
		var link := Dictionary(link_variant)
		section.add_child(_make_readonly_row(str(link.get("label", link.get("id", "Link"))), "type=%s" % str(link.get("type", "unknown"))))
	return section


func _apply_object_patch(object_id: String, patch: Dictionary, message: String) -> void:
	var data := Dictionary(working_data_by_id.get(object_id, {})).duplicate(true)
	for key in patch.keys():
		data[key] = patch[key]
	data["power_state"] = _infer_power_state(data)
	working_data_by_id[object_id] = data
	_set_status(message)
	_render_selected_object_inspector()


func _build_status(data: Dictionary) -> Dictionary:
	var power_state := _infer_power_state(data)
	var raw_state := str(data.get("state", "on")).to_lower()
	var total_state := "Ready"
	if raw_state in ["off", "broken", "overheat", "disabled"] or power_state == "unpowered":
		total_state = "Not ready"
	return {
		"object_type": str(data.get("object_type", "unknown")),
		"total_state": total_state,
		"power_state": power_state,
	}


func _infer_power_state(data: Dictionary) -> String:
	var power_mode := str(data.get("power_mode", "none")).to_lower()
	if power_mode == "none":
		return "none"
	if data.has("is_powered"):
		return "powered" if bool(data.get("is_powered")) else "unpowered"
	var state := str(data.get("state", "on")).to_lower()
	return "unpowered" if state == "off" else "powered"


func _make_section(title: String) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.name = title.replace(" ", "")
	section.add_theme_constant_override("separation", 8)
	section.add_theme_stylebox_override("panel", _make_panel_style(SECTION_BG, BORDER, 1, 6))

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style(SECTION_BG, BORDER, 1, 6))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	var header := Label.new()
	header.text = title
	header.add_theme_color_override("font_color", ACCENT)
	header.add_theme_font_size_override("font_size", 18)
	content.add_child(header)

	# Return content but keep panel wrapper by attaching content children through metadata owner.
	section.add_child(panel)
	section.set_meta("content", content)
	return _SectionProxy.new(section, content).get_section()


class _SectionProxy:
	var outer: VBoxContainer
	var content: VBoxContainer

	func _init(outer_section: VBoxContainer, content_section: VBoxContainer) -> void:
		outer = outer_section
		content = content_section

	func get_section() -> VBoxContainer:
		outer.set_meta("content_node", content)
		return outer


func _add_to_section(section: VBoxContainer, child: Node) -> void:
	var content_node: VBoxContainer = section.get_meta("content_node") as VBoxContainer
	if content_node != null:
		content_node.add_child(child)
	else:
		section.add_child(child)


func _make_property_row(label_text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(160, 0)
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
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


func _make_panel_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _set_status(text: String) -> void:
	if status_label != null:
		status_label.text = text
