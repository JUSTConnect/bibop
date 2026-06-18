extends Node
class_name MapConstructorInspectorStructureLayerService

const CHECK_INTERVAL := 0.25
const SEPARATOR_GROUP := "map_constructor_inspector_structure_separator"
const SEPARATOR_NAME_PREFIX := "InspectorBlockSeparator"
const IDENTITY_SECTION_NAME := "SharedIdentitySection"

var _check_timer: float = 0.0

func _process(delta: float) -> void:
	_check_timer -= delta
	if _check_timer > 0.0:
		return
	_check_timer = CHECK_INTERVAL
	var ui: Object = _get_game_ui()
	if ui == null or not is_instance_valid(ui):
		return
	var panel: Control = _get_property(ui, "runtime_map_constructor_inspector_panel") as Control
	if panel == null or not is_instance_valid(panel):
		return
	var content: VBoxContainer = _find_inspector_content(panel)
	if content == null or not is_instance_valid(content):
		return
	_ensure_identity_first(ui, content)
	_rebuild_block_separators(ui, content)


func _get_game_ui() -> Object:
	if get_tree() == null:
		return null
	var scene: Node = get_tree().current_scene
	if scene != null:
		var direct_ui: Node = scene.get_node_or_null("UI")
		if _looks_like_game_ui(direct_ui):
			return direct_ui
		if _looks_like_game_ui(scene):
			return scene
	var root: Window = get_tree().root
	if root != null:
		var main_ui: Node = root.get_node_or_null("Main/UI")
		if _looks_like_game_ui(main_ui):
			return main_ui
	return null


func _looks_like_game_ui(node: Object) -> bool:
	return node != null and _has_property(node, "runtime_map_constructor_inspector_panel") and _has_property(node, "mission_manager_runtime")


func _ensure_identity_first(ui: Object, content: VBoxContainer) -> void:
	var entity_kind: String = str(_get_property(ui, "selected_map_constructor_entity_kind")).strip_edges()
	var entity_id: String = str(_get_property(ui, "selected_map_constructor_entity_id")).strip_edges()
	if entity_kind.is_empty() or entity_id.is_empty():
		return
	var data: Dictionary = _get_selected_entity_data(ui, entity_kind, entity_id)
	if data.is_empty():
		return
	var identity: VBoxContainer = _find_identity_section(content)
	if identity == null or not is_instance_valid(identity):
		identity = _create_identity_section(ui, entity_kind, entity_id, data)
		content.add_child(identity)
	else:
		_ensure_identity_rows(ui, identity, entity_kind, entity_id, data)
	var target_index: int = _first_non_separator_index(content)
	if target_index < 0:
		target_index = 0
	if identity.get_index() != target_index:
		content.move_child(identity, target_index)


func _create_identity_section(ui: Object, entity_kind: String, entity_id: String, data: Dictionary) -> VBoxContainer:
	var section: VBoxContainer = null
	if ui != null and is_instance_valid(ui) and ui.has_method("_create_inspector_section"):
		section = ui.call("_create_inspector_section", "1. Identity") as VBoxContainer
	if section == null:
		section = VBoxContainer.new()
		section.add_theme_constant_override("separation", 4)
		var header := Label.new()
		header.text = "1. Identity"
		section.add_child(header)
	section.name = IDENTITY_SECTION_NAME
	_ensure_identity_rows(ui, section, entity_kind, entity_id, data)
	return section


func _ensure_identity_rows(ui: Object, section: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> void:
	if not _section_has_property_row(section, "Name"):
		if ui != null and is_instance_valid(ui) and ui.has_method("_add_text_property"):
			ui.call("_add_text_property", section, "Name", entity_kind, entity_id, "display_name", data.get("display_name", data.get("name", "")))
		else:
			_add_fallback_text_row(ui, section, "Name", str(data.get("display_name", data.get("name", entity_id))))
	if not _section_has_property_row(section, "Description"):
		if ui != null and is_instance_valid(ui) and ui.has_method("_add_map_constructor_description_editor"):
			ui.call("_add_map_constructor_description_editor", section, data, entity_kind, entity_id)
		elif ui != null and is_instance_valid(ui) and ui.has_method("_add_text_property"):
			ui.call("_add_text_property", section, "Description", entity_kind, entity_id, "description", data.get("description", ""))
		else:
			_add_fallback_text_row(ui, section, "Description", str(data.get("description", "")))


func _rebuild_block_separators(ui: Object, content: VBoxContainer) -> void:
	_remove_existing_separators(content)
	var block_indexes: Array[int] = []
	for index in range(content.get_child_count()):
		var child: Node = content.get_child(index)
		if _is_separator(child):
			continue
		if _is_inspector_block(child):
			block_indexes.append(index)
	if block_indexes.size() <= 1:
		return
	var inserted: int = 0
	for block_index_pos in range(1, block_indexes.size()):
		var separator: Control = _create_separator(ui, block_index_pos)
		var insert_index: int = block_indexes[block_index_pos] + inserted
		content.add_child(separator)
		content.move_child(separator, insert_index)
		inserted += 1


func _create_separator(ui: Object, index: int) -> Control:
	var separator := PanelContainer.new()
	separator.name = "%s%d" % [SEPARATOR_NAME_PREFIX, index]
	separator.add_to_group(SEPARATOR_GROUP)
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	separator.custom_minimum_size = Vector2(0, 9)
	separator.add_theme_stylebox_override("panel", _make_separator_style(_ui_color(ui, "UI_COLOR_BORDER", Color(0.22, 0.48, 0.62, 0.85))))
	return separator


func _make_separator_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.90)
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	return style


func _remove_existing_separators(content: VBoxContainer) -> void:
	var remove_nodes: Array[Node] = []
	for child in content.get_children():
		if _is_separator(child):
			remove_nodes.append(child)
	for node in remove_nodes:
		content.remove_child(node)
		node.queue_free()


func _is_separator(node: Node) -> bool:
	if node == null:
		return false
	return node.is_in_group(SEPARATOR_GROUP) or str(node.name).begins_with(SEPARATOR_NAME_PREFIX)


func _is_inspector_block(node: Node) -> bool:
	if node == null or not (node is Control):
		return false
	if _is_separator(node):
		return false
	var first_label: Label = _find_first_label(node)
	if first_label == null:
		return false
	var label_text: String = str(first_label.text).strip_edges()
	return not label_text.is_empty()


func _find_identity_section(content: VBoxContainer) -> VBoxContainer:
	for child in content.get_children():
		if not (child is VBoxContainer):
			continue
		var first_label: Label = _find_first_label(child)
		if first_label == null:
			continue
		var title: String = str(first_label.text).strip_edges().to_lower()
		if title == "1. identity" or title == "identity" or title.ends_with(" identity"):
			return child as VBoxContainer
	return null


func _first_non_separator_index(content: VBoxContainer) -> int:
	for index in range(content.get_child_count()):
		if not _is_separator(content.get_child(index)):
			return index
	return -1


func _section_has_property_row(section: Node, property_name: String) -> bool:
	var wanted: String = property_name.strip_edges().to_lower()
	return _node_has_label_text(section, wanted)


func _node_has_label_text(node: Node, wanted: String) -> bool:
	if node == null:
		return false
	if node is Label:
		var text: String = str((node as Label).text).strip_edges().to_lower()
		if text == wanted:
			return true
	for child in node.get_children():
		if _node_has_label_text(child, wanted):
			return true
	return false


func _add_fallback_text_row(ui: Object, section: VBoxContainer, label_text: String, value_text: String) -> void:
	var value := Label.new()
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.text = value_text
	if ui != null and is_instance_valid(ui) and ui.has_method("_create_property_row"):
		section.add_child(ui.call("_create_property_row", label_text, value))
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(140, 0)
	row.add_child(label)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(value)
	section.add_child(row)


func _get_selected_entity_data(ui: Object, entity_kind: String, entity_id: String) -> Dictionary:
	var manager: Object = _get_property(ui, "mission_manager_runtime") as Object
	if manager == null or not is_instance_valid(manager) or not manager.has_method("get_map_constructor_entity_by_id"):
		return {}
	var result_variant: Variant = manager.call("get_map_constructor_entity_by_id", entity_kind, entity_id)
	if not (result_variant is Dictionary):
		return {}
	var result: Dictionary = Dictionary(result_variant)
	if not bool(result.get("ok", false)):
		return {}
	var data_variant: Variant = result.get("data", {})
	return Dictionary(data_variant) if data_variant is Dictionary else {}


func _find_inspector_content(panel: Control) -> VBoxContainer:
	var scroll: ScrollContainer = _find_first_scroll(panel)
	if scroll == null:
		return null
	for child in scroll.get_children():
		if child is VBoxContainer:
			return child as VBoxContainer
	return null


func _find_first_scroll(node: Node) -> ScrollContainer:
	if node is ScrollContainer:
		return node as ScrollContainer
	for child in node.get_children():
		var result: ScrollContainer = _find_first_scroll(child)
		if result != null:
			return result
	return null


func _find_first_label(node: Node) -> Label:
	if node is Label:
		return node as Label
	for child in node.get_children():
		var result: Label = _find_first_label(child)
		if result != null:
			return result
	return null


func _ui_color(ui: Object, property_name: String, fallback: Color) -> Color:
	var value: Variant = _get_property(ui, property_name)
	return value if value is Color else fallback


func _get_property(target: Object, property_name: String) -> Variant:
	if target == null or not _has_property(target, property_name):
		return null
	return target.get(property_name)


func _has_property(target: Object, property_name: String) -> bool:
	if target == null:
		return false
	for property_data in target.get_property_list():
		if str(property_data.get("name", "")) == property_name:
			return true
	return false
