extends Control

# AppRoot
# Touchable vertical slice: Palette + Map Canvas + Placed Object Inspector.

const ObjectDefinitionCatalogRef = preload("res://scripts/domain/object_definition_catalog.gd")
const ObjectDataFactoryRef = preload("res://scripts/domain/object_data_factory.gd")
const ObjectStatusModelRef = preload("res://scripts/domain/object_status_model.gd")
const ObjectInspectorViewModelRef = preload("res://scripts/presentation/object_inspector_view_model.gd")
const ObjectInspectorBuilderRef = preload("res://scripts/ui/object_inspector/object_inspector_builder.gd")
const MapEditStateRef = preload("res://scripts/map_constructor/map_edit_state.gd")

const OBJECT_DEFINITION_PATHS: Array[String] = [
	"res://data/objects/power_source_basic.json",
	"res://data/objects/terminal_basic.json",
	"res://data/objects/door_basic.json"
]
const MAP_COLUMNS := 6
const MAP_ROWS := 5

const UI_BG := Color(0.055, 0.065, 0.085, 1.0)
const PANEL_BG := Color(0.09, 0.105, 0.135, 1.0)
const CELL_BG := Color(0.075, 0.09, 0.12, 1.0)
const CELL_SELECTED := Color(0.12, 0.22, 0.28, 1.0)
const BORDER := Color(0.25, 0.5, 0.62, 0.85)
const ACCENT := Color(0.25, 0.78, 0.95, 1.0)
const WARNING := Color(0.95, 0.7, 0.18, 1.0)

var object_definition_catalog: RefCounted = null
var map_edit_state: RefCounted = null
var object_definitions: Array[Dictionary] = []
var definitions_by_id: Dictionary = {}
var working_preview_data_by_id: Dictionary = {}
var selected_index: int = 0

var object_list: VBoxContainer = null
var map_grid: GridContainer = null
var selected_palette_label: Label = null
var inspector_content: VBoxContainer = null
var status_label: Label = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_edit_state = MapEditStateRef.new()
	_load_object_definitions()
	_build_layout()
	_select_palette_definition(0)


func _load_object_definitions() -> void:
	object_definition_catalog = ObjectDefinitionCatalogRef.new()
	object_definitions = object_definition_catalog.load_paths(OBJECT_DEFINITION_PATHS)
	definitions_by_id.clear()
	working_preview_data_by_id.clear()
	map_edit_state.reset()
	for definition in object_definitions:
		var object_id: String = str(definition.get("id", ""))
		definitions_by_id[object_id] = definition
		working_preview_data_by_id[object_id] = ObjectDataFactoryRef.make_initial_object_data(definition)
	if not object_definitions.is_empty():
		selected_index = clampi(selected_index, 0, object_definitions.size() - 1)
		map_edit_state.set_selected_definition(str(object_definitions[selected_index].get("id", "")))


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

	var left_panel := _build_palette_panel()
	left_panel.custom_minimum_size = Vector2(260, 0)
	body.add_child(left_panel)

	var center_panel := _build_map_canvas_panel()
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(center_panel)

	var right_panel := _build_inspector_panel()
	right_panel.custom_minimum_size = Vector2(420, 0)
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(right_panel)

	status_label = Label.new()
	status_label.text = "Select object in palette, then click a map cell."
	status_label.add_theme_color_override("font_color", ACCENT)
	main_stack.add_child(status_label)


func _build_header() -> Control:
	var panel := _make_panel_container()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(_wrap_margin(row, 12, 8))

	var title := Label.new()
	title.text = "NewBIP / Touch Test / Palette + Map Canvas + Inspector"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)

	var reload_button := Button.new()
	reload_button.text = "Reload definitions / Clear map"
	reload_button.pressed.connect(func() -> void:
		_load_object_definitions()
		_rebuild_palette_list()
		_refresh_map_grid()
		_select_palette_definition(clampi(selected_index, 0, max(0, object_definitions.size() - 1)))
		_set_status("Definitions reloaded. Map cleared.")
	)
	row.add_child(reload_button)
	return panel


func _build_palette_panel() -> PanelContainer:
	var panel := _make_panel_container()
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	panel.add_child(_wrap_margin(stack, 10, 10))

	var title := Label.new()
	title.text = "Object Palette"
	title.add_theme_color_override("font_color", ACCENT)
	stack.add_child(title)

	selected_palette_label = Label.new()
	selected_palette_label.text = "Selected: none"
	selected_palette_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(selected_palette_label)

	object_list = VBoxContainer.new()
	object_list.add_theme_constant_override("separation", 6)
	object_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(object_list)
	_rebuild_palette_list()
	return panel


func _build_map_canvas_panel() -> PanelContainer:
	var panel := _make_panel_container()
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(_wrap_margin(stack, 12, 10))

	var title := Label.new()
	title.text = "Map Canvas / click empty cell to place / click occupied cell to select"
	title.add_theme_color_override("font_color", ACCENT)
	stack.add_child(title)

	map_grid = GridContainer.new()
	map_grid.columns = MAP_COLUMNS
	map_grid.add_theme_constant_override("h_separation", 8)
	map_grid.add_theme_constant_override("v_separation", 8)
	map_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(map_grid)
	_refresh_map_grid()
	return panel


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


func _rebuild_palette_list() -> void:
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
			_select_palette_definition(index)
		)
		object_list.add_child(button)


func _refresh_map_grid() -> void:
	if map_grid == null:
		return
	for child in map_grid.get_children():
		child.queue_free()
	for y in range(MAP_ROWS):
		for x in range(MAP_COLUMNS):
			var cell := Vector2i(x, y)
			map_grid.add_child(_build_map_cell_button(cell))


func _build_map_cell_button(cell: Vector2i) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(96, 68)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.text = _get_cell_text(cell)
	button.add_theme_stylebox_override("normal", _make_panel_style(_get_cell_color(cell), BORDER, 1, 5))
	button.add_theme_stylebox_override("hover", _make_panel_style(CELL_SELECTED, BORDER, 1, 5))
	button.pressed.connect(func() -> void:
		_handle_map_cell_pressed(cell)
	)
	return button


func _get_cell_text(cell: Vector2i) -> String:
	var instance_id: String = map_edit_state.get_instance_id_at_cell(cell)
	if instance_id.is_empty():
		return "%d,%d\n+" % [cell.x, cell.y]
	var data: Dictionary = map_edit_state.get_instance_data(instance_id)
	var definition_id: String = str(data.get("definition_id", ""))
	var marker := "*" if map_edit_state.is_selected_instance(instance_id) else ""
	return "%s%s\n%s" % [marker, str(data.get("display_name", instance_id)), str(definitions_by_id.get(definition_id, {}).get("object_type", "object"))]


func _get_cell_color(cell: Vector2i) -> Color:
	var instance_id: String = map_edit_state.get_instance_id_at_cell(cell)
	if not instance_id.is_empty() and map_edit_state.is_selected_instance(instance_id):
		return CELL_SELECTED
	return CELL_BG


func _handle_map_cell_pressed(cell: Vector2i) -> void:
	var definition := _get_selected_definition()
	var existed := map_edit_state.has_instance_at_cell(cell)
	var result: Dictionary = map_edit_state.place_or_select_cell(cell, definition)
	_refresh_map_grid()
	_render_selected_object_inspector()
	if result.is_empty():
		_set_status("No palette object selected.")
	elif existed:
		_set_status("Selected placed object: %s" % str(result.get("display_name", result.get("id", "object"))))
	else:
		_set_status("Placed object: %s" % str(result.get("display_name", result.get("id", "object"))))


func _select_palette_definition(index: int) -> void:
	if object_definitions.is_empty():
		_render_empty_inspector()
		return
	selected_index = clampi(index, 0, object_definitions.size() - 1)
	var definition: Dictionary = object_definitions[selected_index]
	var definition_id: String = str(definition.get("id", ""))
	map_edit_state.set_selected_definition(definition_id)
	_update_selected_palette_label()
	_refresh_map_grid()
	_render_selected_object_inspector()
	_set_status("Palette selected: %s. Click a map cell to place it." % str(definition.get("display_name", definition_id)))


func _update_selected_palette_label() -> void:
	if selected_palette_label == null:
		return
	var definition := _get_selected_definition()
	if definition.is_empty():
		selected_palette_label.text = "Selected: none"
		return
	selected_palette_label.text = "Selected palette:\n%s" % str(definition.get("display_name", definition.get("id", "Object")))


func _get_selected_definition() -> Dictionary:
	if object_definitions.is_empty():
		return {}
	var definition_id: String = str(map_edit_state.selected_definition_id)
	if definitions_by_id.has(definition_id):
		return Dictionary(definitions_by_id[definition_id])
	return Dictionary(object_definitions[clampi(selected_index, 0, object_definitions.size() - 1)])


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
	if inspector_content == null:
		return
	var definition := _get_inspected_definition()
	var data := _get_inspected_data(definition)
	if definition.is_empty() or data.is_empty():
		_render_empty_inspector()
		return
	var entity_kind: String = str(map_edit_state.selected_entity_kind)
	var entity_id: String = str(data.get("id", ""))
	var status: Dictionary = ObjectStatusModelRef.build_status(data)
	var inspector_view_model: Dictionary = ObjectInspectorViewModelRef.create(entity_kind, entity_id, definition, data, status)
	ObjectInspectorBuilderRef.fill_content(inspector_content, inspector_view_model, Callable(self, "_apply_view_model_row_update"))


func _get_inspected_definition() -> Dictionary:
	if map_edit_state.selected_entity_kind == "placed_object":
		var placed_data: Dictionary = map_edit_state.get_selected_instance_data()
		var definition_id: String = str(placed_data.get("definition_id", ""))
		return Dictionary(definitions_by_id.get(definition_id, {}))
	return _get_selected_definition()


func _get_inspected_data(definition: Dictionary) -> Dictionary:
	if map_edit_state.selected_entity_kind == "placed_object":
		return map_edit_state.get_selected_instance_data()
	var definition_id: String = str(definition.get("id", ""))
	return Dictionary(working_preview_data_by_id.get(definition_id, {}))


func _apply_view_model_row_update(row_view_model: Dictionary, value: Variant) -> void:
	var entity_kind: String = str(row_view_model.get("entity_kind", ""))
	var entity_id: String = str(row_view_model.get("entity_id", ""))
	var field_id: String = str(row_view_model.get("id", ""))
	if entity_id.is_empty() or field_id.is_empty():
		return
	var label: String = str(row_view_model.get("label", field_id))
	if entity_kind == "placed_object":
		_apply_placed_object_patch(entity_id, {field_id: value}, "%s updated." % label)
	else:
		_apply_preview_patch(entity_id, {field_id: value}, "%s updated in palette preview." % label)


func _apply_preview_patch(definition_id: String, patch: Dictionary, message: String) -> void:
	var data: Dictionary = Dictionary(working_preview_data_by_id.get(definition_id, {})).duplicate(true)
	for key in patch.keys():
		data[key] = patch[key]
	data["power_state"] = ObjectDataFactoryRef.infer_power_state(data)
	working_preview_data_by_id[definition_id] = data
	_set_status(message)
	_render_selected_object_inspector()


func _apply_placed_object_patch(instance_id: String, patch: Dictionary, message: String) -> void:
	map_edit_state.patch_instance(instance_id, patch)
	_refresh_map_grid()
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
