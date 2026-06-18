extends "res://scripts/game/map_constructor_object_link_layer_service_v2.gd"
class_name MapConstructorObjectLinkLayerV3

func _try_decorate_inspector(ui: Node) -> void:
	if ui == null or not _has_property(ui, "runtime_map_constructor_inspector_panel"):
		return
	var panel: Control = _get_property(ui, "runtime_map_constructor_inspector_panel") as Control
	if panel == null or not is_instance_valid(panel):
		return
	var content: VBoxContainer = _find_inspector_content(panel)
	if content == null:
		return
	var manager: Object = _get_property(ui, "mission_manager_runtime") as Object
	if manager == null or not is_instance_valid(manager) or not manager.has_method("get_map_constructor_entity_by_id"):
		_remove_legacy_link_sections_only(content)
		return
	var entity_kind: String = str(_get_property(ui, "selected_map_constructor_entity_kind")).strip_edges()
	var entity_id: String = str(_get_property(ui, "selected_map_constructor_entity_id")).strip_edges()
	_remove_legacy_link_sections_only(content)
	var existing: Node = content.get_node_or_null(SECTION_NAME)
	if existing != null:
		var same_entity: bool = str(existing.get_meta("entity_kind", "")) == entity_kind and str(existing.get_meta("entity_id", "")) == entity_id
		if same_entity:
			return
		existing.queue_free()
	if entity_kind.is_empty() or entity_id.is_empty():
		return
	var model: Dictionary = build_links_model(manager, entity_kind, entity_id)
	if not bool(model.get("visible", false)):
		return
	var section: VBoxContainer = _build_section(ui, manager, model)
	section.set_meta("entity_kind", entity_kind)
	section.set_meta("entity_id", entity_id)
	content.add_child(section)
	content.move_child(section, _find_insert_index_before_warnings(content))


func _remove_legacy_link_sections_only(content: VBoxContainer) -> void:
	for child in content.get_children():
		if child == null:
			continue
		if child.name == SECTION_NAME:
			continue
		var label: Label = _find_first_label(child)
		if label != null and str(label.text).strip_edges() == LEGACY_SECTION_TITLE:
			child.queue_free()
