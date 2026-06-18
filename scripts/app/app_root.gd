extends Control

# AppRoot
# Первый осязаемый vertical slice новой архитектуры.
# Запускается сразу и показывает: object list -> Identity -> Status -> Configurable Parameters -> Links.

const ObjectDefinitionCatalogRef = preload("res://scripts/domain/object_definition_catalog.gd")
const ObjectDataFactoryRef = preload("res://scripts/domain/object_data_factory.gd")
const ObjectStatusModelRef = preload("res://scripts/domain/object_status_model.gd")
const ObjectInspectorViewModelRef = preload("res://scripts/presentation/object_inspector_view_model.gd")
const ObjectInspectorBuilderRef = preload("res://scripts/ui/object_inspector/object_inspector_builder.gd")

const OBJECT_DEFINITION_PATHS: Array[String] = [
	"res://data/objects/power_source_basic.json",
	"res://data/objects/terminal_basic.json",
	"res://data/objects/door_basic.json"
]

const UI_BG := Color(0.055, 0.065, 0.085, 1.0)
const PANEL_BG := Color(0.09, 0.105, 0.135, 1.0)
const BORDER := Color(0.25, 0.5, 0.62, 0.85)
const ACCENT := Color(0.25, 0.78, 0.95, 1.0)
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
	if inspector_content == null:
		return
	for child in inspector_content.get_children():
		child.queue_free()
	var label := Label.new()
	label.text = "No object definitions found."
	label.add_theme_color_override("font_color", WARNING)
	inspector_content.add_child(label)


func _render_selected_object_inspector() -> void:
	var definition: Dictionary = object_definitions[selected_index]
	var object_id: String = str(definition.get("id", ""))
	var data: Dictionary = Dictionary(working_data_by_id.get(object_id, {}))
	var status: Dictionary = ObjectStatusModelRef.build_status(data)
	var inspector_view_model: Dictionary = ObjectInspectorViewModelRef.create("world_object", object_id, definition, data, status)
	ObjectInspectorBuilderRef.fill_content(inspector_content, inspector_view_model, Callable(self, "_apply_view_model_row_update"))
	_set_status("Selected: %s" % str(data.get("display_name", object_id)))


func _apply_view_model_row_update(row_view_model: Dictionary, value: Variant) -> void:
	var entity_id: String = str(row_view_model.get("entity_id", ""))
	var field_id: String = str(row_view_model.get("id", ""))
	if entity_id.is_empty() or field_id.is_empty():
		return
	var label: String = str(row_view_model.get("label", field_id))
	_apply_object_patch(entity_id, {field_id: value}, "%s updated." % label)


func _apply_object_patch(object_id: String, patch: Dictionary, message: String) -> void:
	var data: Dictionary = Dictionary(working_data_by_id.get(object_id, {})).duplicate(true)
	for key in patch.keys():
		data[key] = patch[key]
	data["power_state"] = ObjectDataFactoryRef.infer_power_state(data)
	working_data_by_id[object_id] = data
	_set_status(message)
	_render_selected_object_inspector()


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


func _set_status(text: String) -> void:
	if status_label != null:
		status_label.text = text
