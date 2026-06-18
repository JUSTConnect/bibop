extends RefCounted

const ObjectDefinitionCatalogRef = preload("res://scripts/domain/object_definition_catalog.gd")
const ObjectDataFactoryRef = preload("res://scripts/domain/object_data_factory.gd")
const ObjectStatusModelRef = preload("res://scripts/domain/object_status_model.gd")
const ObjectInspectorViewModelRef = preload("res://scripts/presentation/object_inspector_view_model.gd")
const ObjectInspectorBuilderRef = preload("res://scripts/ui/object_inspector/object_inspector_builder.gd")
const MapEditStateRef = preload("res://scripts/map_constructor/map_edit_state.gd")
const ObjectVisualFactoryRef = preload("res://scripts/rendering/object_visual_factory.gd")
const ObjectInteractionSystemRef = preload("res://scripts/systems/object_interaction_system.gd")
const ObjectPowerSystemRef = preload("res://scripts/systems/object_power_system.gd")
const AppLayoutBuilderRef = preload("res://scripts/app/app_layout_builder.gd")

const OBJECT_DEFINITION_PATHS: Array[String] = ["res://data/objects/power_source_basic.json", "res://data/objects/terminal_basic.json", "res://data/objects/door_basic.json"]
const MAP_COLUMNS := 6
const MAP_ROWS := 5
const SNAPSHOT_PATH := "user://newbip_map_snapshot.json"
const WARNING := Color(0.95, 0.7, 0.18, 1.0)

var root: Control
var object_definition_catalog: RefCounted
var map_edit_state: RefCounted
var object_definitions: Array[Dictionary] = []
var definitions_by_id: Dictionary = {}
var working_preview_data_by_id: Dictionary = {}
var selected_index := 0
var object_list: VBoxContainer
var map_canvas: Control
var selected_palette_label: Label
var tool_mode_label: Label
var inspector_content: VBoxContainer
var status_label: Label

func setup(new_root: Control) -> void:
	root = new_root
	map_edit_state = MapEditStateRef.new()
	_load_object_definitions()
	_build_layout()
	_select_palette_definition(0)

func _build_layout() -> void:
	var refs := AppLayoutBuilderRef.build(root, {"reload": Callable(self, "_reload_all"), "place": Callable(self, "_set_place_tool"), "erase": Callable(self, "_set_erase_tool"), "use": Callable(self, "_use_selected_object"), "clear": Callable(self, "_clear_map"), "save": Callable(self, "_save_snapshot"), "load": Callable(self, "_load_snapshot"), "cell_pressed": Callable(self, "_handle_map_cell_pressed")})
	object_list = refs["object_list"]
	map_canvas = refs["map_canvas"]
	selected_palette_label = refs["selected_palette_label"]
	tool_mode_label = refs["tool_mode_label"]
	inspector_content = refs["inspector_content"]
	status_label = refs["status_label"]
	_rebuild_palette_list()
	_refresh_map_canvas()
	_update_tool_mode_label()

func _load_object_definitions() -> void:
	object_definition_catalog = ObjectDefinitionCatalogRef.new()
	object_definitions = object_definition_catalog.load_paths(OBJECT_DEFINITION_PATHS)
	definitions_by_id.clear()
	working_preview_data_by_id.clear()
	map_edit_state.reset()
	for definition: Dictionary in object_definitions:
		var object_id := str(definition.get("id", ""))
		definitions_by_id[object_id] = definition
		working_preview_data_by_id[object_id] = ObjectDataFactoryRef.make_initial_object_data(definition)
	if not object_definitions.is_empty():
		selected_index = clampi(selected_index, 0, object_definitions.size() - 1)
		map_edit_state.set_selected_definition(str(object_definitions[selected_index].get("id", "")))

func _reload_all() -> void:
	_load_object_definitions()
	_rebuild_palette_list()
	_select_palette_definition(clampi(selected_index, 0, max(0, object_definitions.size() - 1)))
	_set_status("Definitions reloaded. Map cleared.")

func _rebuild_palette_list() -> void:
	if object_list == null:
		return
	for child in object_list.get_children():
		child.queue_free()
	for index in range(object_definitions.size()):
		var definition: Dictionary = object_definitions[index]
		var button := Button.new()
		button.text = "%s\n%s" % [str(definition.get("display_name", definition.get("id", "Object"))), str(definition.get("object_type", "unknown"))]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.pressed.connect(func() -> void:
			_select_palette_definition(index)
		)
		object_list.add_child(button)

func _refresh_map_canvas() -> void:
	if map_canvas != null:
		map_canvas.call("set_cell_visuals", MAP_COLUMNS, MAP_ROWS, _build_cell_visuals(), Vector2i(map_edit_state.selected_cell))

func _build_cell_visuals() -> Dictionary:
	var visuals: Dictionary = {}
	for y in range(MAP_ROWS):
		for x in range(MAP_COLUMNS):
			var cell := Vector2i(x, y)
			visuals[_cell_key(cell)] = _get_cell_visual(cell)
	return visuals

func _get_cell_visual(cell: Vector2i) -> Dictionary:
	var instance_id := str(map_edit_state.get_instance_id_at_cell(cell))
	if instance_id.is_empty():
		return ObjectVisualFactoryRef.create_empty_cell_visual(cell)
	var data: Dictionary = Dictionary(map_edit_state.get_instance_data(instance_id))
	var definition: Dictionary = Dictionary(definitions_by_id.get(str(data.get("definition_id", "")), {}))
	return ObjectVisualFactoryRef.create_map_visual(data, definition, bool(map_edit_state.is_selected_instance(instance_id)))

func _handle_map_cell_pressed(cell: Vector2i) -> void:
	if str(map_edit_state.active_tool_mode) == "erase":
		var erased: Dictionary = Dictionary(map_edit_state.erase_cell(cell))
		_refresh_after_world_change()
		_set_status("Nothing to erase." if erased.is_empty() else "Erased: %s" % str(erased.get("display_name", erased.get("id", "object"))))
		return
	var existed := bool(map_edit_state.has_instance_at_cell(cell))
	var result: Dictionary = Dictionary(map_edit_state.place_or_select_cell(cell, _get_selected_definition()))
	_refresh_after_world_change()
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
	var definition_id := str(definition.get("id", ""))
	map_edit_state.set_selected_definition(definition_id)
	_set_tool_mode("place", false)
	_update_selected_palette_label()
	_refresh_map_canvas()
	_render_selected_object_inspector()
	_set_status("Palette selected: %s. Click a map cell to place it." % str(definition.get("display_name", definition_id)))

func _update_selected_palette_label() -> void:
	if selected_palette_label == null:
		return
	var definition: Dictionary = _get_selected_definition()
	selected_palette_label.text = "Selected: none" if definition.is_empty() else "Selected palette:\n%s" % str(definition.get("display_name", definition.get("id", "Object")))

func _set_place_tool() -> void:
	_set_tool_mode("place")

func _set_erase_tool() -> void:
	_set_tool_mode("erase")

func _set_tool_mode(tool_mode: String, show_status := true) -> void:
	map_edit_state.set_tool_mode(tool_mode)
	_update_tool_mode_label()
	if show_status:
		_set_status("Tool: %s" % str(map_edit_state.active_tool_mode).capitalize())

func _update_tool_mode_label() -> void:
	if tool_mode_label != null:
		tool_mode_label.text = "Tool: %s" % str(map_edit_state.active_tool_mode).capitalize()

func _use_selected_object() -> void:
	var selected_data: Dictionary = Dictionary(map_edit_state.get_selected_instance_data())
	if selected_data.is_empty():
		_set_status("Select a placed object before Use.")
		return
	var result: Dictionary = ObjectInteractionSystemRef.use_object(selected_data, map_edit_state.get_placed_objects())
	_apply_system_patches(Array(result.get("patches", [])))
	_refresh_after_world_change()
	_set_status(str(result.get("message", "Use finished.")))

func _refresh_after_world_change() -> void:
	_run_power_system()
	_refresh_map_canvas()
	_render_selected_object_inspector()

func _run_power_system() -> void:
	_apply_system_patches(ObjectPowerSystemRef.evaluate_all(map_edit_state.get_placed_objects()))

func _apply_system_patches(patches: Array) -> void:
	for patch_variant in patches:
		var info: Dictionary = Dictionary(patch_variant)
		var instance_id := str(info.get("instance_id", ""))
		var patch: Dictionary = Dictionary(info.get("patch", {}))
		if not instance_id.is_empty() and not patch.is_empty():
			map_edit_state.patch_instance(instance_id, patch)

func _clear_map() -> void:
	map_edit_state.clear_map_keep_palette()
	_refresh_map_canvas()
	_render_selected_object_inspector()
	_set_status("Map cleared.")

func _save_snapshot() -> void:
	var file := FileAccess.open(SNAPSHOT_PATH, FileAccess.WRITE)
	if file == null:
		_set_status("Cannot save snapshot: %s" % SNAPSHOT_PATH)
		return
	file.store_string(JSON.stringify(map_edit_state.make_snapshot(), "\t"))
	_set_status("Snapshot saved: %s" % SNAPSHOT_PATH)

func _load_snapshot() -> void:
	if not FileAccess.file_exists(SNAPSHOT_PATH):
		_set_status("Snapshot not found: %s" % SNAPSHOT_PATH)
		return
	var file := FileAccess.open(SNAPSHOT_PATH, FileAccess.READ)
	if file == null:
		_set_status("Cannot load snapshot: %s" % SNAPSHOT_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_set_status("Snapshot JSON is invalid.")
		return
	map_edit_state.load_snapshot(Dictionary(parsed))
	_ensure_selected_definition_is_valid()
	_sync_selected_index_from_state()
	_update_selected_palette_label()
	_update_tool_mode_label()
	_refresh_after_world_change()
	_set_status("Snapshot loaded.")

func _ensure_selected_definition_is_valid() -> void:
	var definition_id := str(map_edit_state.selected_definition_id)
	if definitions_by_id.has(definition_id) or object_definitions.is_empty():
		return
	map_edit_state.set_selected_definition(str(object_definitions[0].get("id", "")))

func _sync_selected_index_from_state() -> void:
	var definition_id := str(map_edit_state.selected_definition_id)
	for index in range(object_definitions.size()):
		if str(object_definitions[index].get("id", "")) == definition_id:
			selected_index = index
			return
	selected_index = 0

func _get_selected_definition() -> Dictionary:
	if object_definitions.is_empty():
		return {}
	var definition_id := str(map_edit_state.selected_definition_id)
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
	var definition: Dictionary = _get_inspected_definition()
	var data: Dictionary = _get_inspected_data(definition)
	if definition.is_empty() or data.is_empty():
		_render_empty_inspector()
		return
	var entity_kind := str(map_edit_state.selected_entity_kind)
	var entity_id := str(data.get("id", ""))
	var status: Dictionary = ObjectStatusModelRef.build_status(data)
	var view_model: Dictionary = ObjectInspectorViewModelRef.create(entity_kind, entity_id, definition, data, status, _get_link_target_options(entity_id))
	ObjectInspectorBuilderRef.fill_content(inspector_content, view_model, Callable(self, "_apply_view_model_row_update"))

func _get_inspected_definition() -> Dictionary:
	if map_edit_state.selected_entity_kind == "placed_object":
		var placed_data: Dictionary = Dictionary(map_edit_state.get_selected_instance_data())
		return Dictionary(definitions_by_id.get(str(placed_data.get("definition_id", "")), {}))
	return _get_selected_definition()

func _get_inspected_data(definition: Dictionary) -> Dictionary:
	if map_edit_state.selected_entity_kind == "placed_object":
		return Dictionary(map_edit_state.get_selected_instance_data())
	return Dictionary(working_preview_data_by_id.get(str(definition.get("id", "")), {}))

func _apply_view_model_row_update(row_view_model: Dictionary, value: Variant) -> void:
	var entity_kind := str(row_view_model.get("entity_kind", ""))
	var entity_id := str(row_view_model.get("entity_id", ""))
	var field_id := str(row_view_model.get("id", ""))
	if entity_id.is_empty() or field_id.is_empty():
		return
	if str(row_view_model.get("row_kind", "")) == "link_field":
		_apply_placed_object_link_patch(entity_kind, entity_id, field_id, str(row_view_model.get("link_type", "")), value)
		return
	if entity_kind == "placed_object":
		_apply_placed_object_patch(entity_id, {field_id: value}, "%s updated." % str(row_view_model.get("label", field_id)))
	else:
		_apply_preview_patch(entity_id, {field_id: value}, "%s updated in palette preview." % str(row_view_model.get("label", field_id)))

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
	_refresh_after_world_change()
	_set_status(message)

func _apply_placed_object_link_patch(entity_kind: String, instance_id: String, link_id: String, link_type: String, value: Variant) -> void:
	if entity_kind != "placed_object":
		_set_status("Links can be edited only on placed objects.")
		return
	var data: Dictionary = Dictionary(map_edit_state.get_instance_data(instance_id))
	if data.is_empty():
		return
	var links: Dictionary = Dictionary(data.get("links", {})).duplicate(true)
	links[link_id] = _normalize_link_value(value, link_type)
	map_edit_state.patch_instance(instance_id, {"links": links})
	_refresh_after_world_change()
	_set_status("Link updated: %s" % link_id)

func _normalize_link_value(value: Variant, link_type: String) -> Variant:
	if link_type == "object_ref_array":
		if value is Array:
			return Array(value)
		var result: Array[String] = []
		for part in str(value).split(",", false):
			var item := String(part).strip_edges()
			if not item.is_empty():
				result.append(item)
		return result
	return str(value)

func _get_link_target_options(current_entity_id: String) -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	for object_data in map_edit_state.get_placed_objects():
		var target_id := str(object_data.get("id", ""))
		if not target_id.is_empty() and target_id != current_entity_id:
			targets.append({"id": target_id, "display_name": str(object_data.get("display_name", target_id)), "object_type": str(object_data.get("object_type", "object"))})
	return targets

func _cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]

func _set_status(text: String) -> void:
	if status_label != null:
		status_label.text = text
