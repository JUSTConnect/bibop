extends RefCounted

const ObjectStatusModelRef = preload("res://scripts/domain/object_status_model.gd")
const ObjectInspectorViewModelRef = preload("res://scripts/presentation/object_inspector_view_model.gd")
const ObjectInspectorBuilderRef = preload("res://scripts/ui/object_inspector/object_inspector_builder.gd")
const ObjectActionsViewModelRef = preload("res://scripts/presentation/object_actions_view_model.gd")
const ObjectActionPanelRef = preload("res://scripts/ui/object_actions/object_action_panel.gd")

var content: VBoxContainer = null
var palette: RefCounted = null
var map_editor: RefCounted = null
var on_world_changed: Callable = Callable()
var on_status: Callable = Callable()
var on_action: Callable = Callable()

func setup(
	new_content: VBoxContainer,
	palette_controller: RefCounted,
	map_editor_controller: RefCounted,
	world_changed_callback: Callable,
	status_callback: Callable,
	action_callback: Callable = Callable()
) -> void:
	content = new_content
	palette = palette_controller
	map_editor = map_editor_controller
	on_world_changed = world_changed_callback
	on_status = status_callback
	on_action = action_callback

func render() -> void:
	if content == null:
		return
	var definition: Dictionary = _get_inspected_definition()
	var data: Dictionary = _get_inspected_data(definition)
	if definition.is_empty() or data.is_empty():
		_render_empty()
		return
	var entity_kind: String = str(map_editor.call("selected_entity_kind"))
	var entity_id: String = str(data.get("id", ""))
	var status: Dictionary = ObjectStatusModelRef.build_status(data)
	var view_model: Dictionary = ObjectInspectorViewModelRef.create(
		entity_kind,
		entity_id,
		definition,
		data,
		status,
		_get_link_target_options(entity_id)
	)
	ObjectInspectorBuilderRef.fill_content(content, view_model, Callable(self, "apply_row_update"))
	if entity_kind == "placed_object":
		var actions_vm: Dictionary = ObjectActionsViewModelRef.create(data)
		content.add_child(ObjectActionPanelRef.build(actions_vm, Callable(self, "_handle_action")))

func apply_row_update(row: Dictionary, value: Variant) -> void:
	var entity_kind: String = str(row.get("entity_kind", ""))
	var entity_id: String = str(row.get("entity_id", ""))
	var field_id: String = str(row.get("id", ""))
	if entity_id.is_empty() or field_id.is_empty():
		return
	if str(row.get("row_kind", "")) == "link_field":
		_apply_link(entity_kind, entity_id, field_id, str(row.get("link_type", "")), value)
		return
	if entity_kind == "placed_object":
		map_editor.call("patch_instance", entity_id, {field_id: value})
		_emit_world_changed()
		_emit_status("%s updated." % str(row.get("label", field_id)))
		return
	palette.call("patch_preview", entity_id, {field_id: value})
	_emit_status("%s updated in palette preview." % str(row.get("label", field_id)))
	render()

func _apply_link(entity_kind: String, instance_id: String, link_id: String, link_type: String, value: Variant) -> void:
	if entity_kind != "placed_object":
		_emit_status("Links can be edited only on placed objects.")
		return
	var data: Dictionary = Dictionary(map_editor.call("get_instance_data", instance_id))
	if data.is_empty():
		return
	var links: Dictionary = Dictionary(data.get("links", {})).duplicate(true)
	links[link_id] = _normalize_link_value(value, link_type)
	map_editor.call("change_links", instance_id, links)
	_emit_world_changed()
	_emit_status("Link updated: %s" % link_id)

func _handle_action(action_id: String) -> void:
	if on_action.is_valid():
		on_action.call(action_id)

func _normalize_link_value(value: Variant, link_type: String) -> Variant:
	if link_type != "object_ref_array":
		return str(value)
	if value is Array:
		return Array(value)
	var result: Array[String] = []
	for part: String in str(value).split(",", false):
		var item: String = part.strip_edges()
		if not item.is_empty():
			result.append(item)
	return result

func _get_inspected_definition() -> Dictionary:
	if str(map_editor.call("selected_entity_kind")) == "placed_object":
		var data: Dictionary = Dictionary(map_editor.call("get_selected_instance_data"))
		return Dictionary(palette.call("get_definition", str(data.get("definition_id", ""))))
	return Dictionary(palette.call("get_selected_definition"))

func _get_inspected_data(definition: Dictionary) -> Dictionary:
	if str(map_editor.call("selected_entity_kind")) == "placed_object":
		return Dictionary(map_editor.call("get_selected_instance_data"))
	return Dictionary(palette.call("get_preview_data", str(definition.get("id", ""))))

func _get_link_target_options(current_entity_id: String) -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	for object_data: Dictionary in Array(map_editor.call("get_placed_objects")):
		var target_id: String = str(object_data.get("id", ""))
		if target_id.is_empty() or target_id == current_entity_id:
			continue
		targets.append({
			"id": target_id,
			"display_name": str(object_data.get("display_name", target_id)),
			"object_type": str(object_data.get("object_type", "object")),
		})
	return targets

func _render_empty() -> void:
	for child: Node in content.get_children():
		child.queue_free()
	var label := Label.new()
	label.text = "No object selected."
	content.add_child(label)

func _emit_world_changed() -> void:
	if on_world_changed.is_valid():
		on_world_changed.call()

func _emit_status(text: String) -> void:
	if on_status.is_valid():
		on_status.call(text)
