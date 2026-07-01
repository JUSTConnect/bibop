extends RefCounted
class_name MapConstructorInspectorStructureLayerService

const SchemaRendererRef = preload("res://scripts/ui/map_constructor/map_constructor_schema_inspector_renderer.gd")

const SEPARATOR_GROUP := "map_constructor_inspector_structure_separator"
const SEPARATOR_NAME_PREFIX := "InspectorBlockSeparator"
const META_CANONICAL_RENDER := "map_constructor_canonical_render"

static func apply_structure(ui: Object, content: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> void:
	if ui == null or not is_instance_valid(ui) or content == null or not is_instance_valid(content):
		return
	if entity_kind.strip_edges().is_empty() or entity_id.strip_edges().is_empty() or data.is_empty():
		return
	_remove_existing_separators(content)
	var canonical: Dictionary = SchemaRendererRef.render(ui, content, entity_kind, entity_id, data)
	if bool(canonical.get("handled", false)):
		content.set_meta(META_CANONICAL_RENDER, true)
		_rebuild_block_separators(ui, content)
		return
	content.set_meta(META_CANONICAL_RENDER, false)
	# A genuinely noncanonical legacy entity keeps the sections produced by the
	# existing inspector. This layer only restores visual separators; it does not
	# infer status, power, type, or readiness from raw fields.
	_rebuild_block_separators(ui, content)

static func apply_from_ui(ui: Object) -> void:
	if ui == null or not is_instance_valid(ui):
		return
	var panel: Control = _get_property(ui, "runtime_map_constructor_inspector_panel") as Control
	if panel == null or not is_instance_valid(panel):
		return
	var content: VBoxContainer = _find_inspector_content(panel)
	if content == null or not is_instance_valid(content):
		return
	var state: Object = _get_property(ui, "map_constructor_state") as Object
	var entity_kind: String = str(state.get("selected_map_constructor_entity_kind") if state != null else "").strip_edges()
	var entity_id: String = str(state.get("selected_map_constructor_entity_id") if state != null else "").strip_edges()
	if entity_kind.is_empty() or entity_id.is_empty():
		return
	apply_structure(ui, content, entity_kind, entity_id, _get_selected_entity_data(ui, entity_kind, entity_id))

static func _rebuild_block_separators(ui: Object, content: VBoxContainer) -> void:
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

static func _create_separator(ui: Object, index: int) -> Control:
	var separator := PanelContainer.new()
	separator.name = "%s%d" % [SEPARATOR_NAME_PREFIX, index]
	separator.add_to_group(SEPARATOR_GROUP)
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	separator.custom_minimum_size = Vector2(0, 9)
	separator.add_theme_stylebox_override("panel", _make_separator_style(_ui_color(ui, "UI_COLOR_BORDER", Color(0.22, 0.48, 0.62, 0.85))))
	return separator

static func _make_separator_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.90)
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	return style

static func _remove_existing_separators(content: VBoxContainer) -> void:
	var remove_nodes: Array[Node] = []
	for child in content.get_children():
		if _is_separator(child):
			remove_nodes.append(child)
	for node in remove_nodes:
		content.remove_child(node)
		node.queue_free()

static func _is_separator(node: Node) -> bool:
	if node == null:
		return false
	return node.is_in_group(SEPARATOR_GROUP) or str(node.name).begins_with(SEPARATOR_NAME_PREFIX)

static func _is_inspector_block(node: Node) -> bool:
	if node == null or not (node is Control) or _is_separator(node):
		return false
	var first_label: Label = _find_first_label(node)
	return first_label != null and not str(first_label.text).strip_edges().is_empty()

static func _get_selected_entity_data(ui: Object, entity_kind: String, entity_id: String) -> Dictionary:
	var manager: Object = _get_property(ui, "mission_manager_runtime") as Object
	if manager == null or not is_instance_valid(manager) or not manager.has_method("get_map_constructor_entity_by_id"):
		return {}
	var result_variant: Variant = manager.call("get_map_constructor_entity_by_id", entity_kind, entity_id)
	if not result_variant is Dictionary:
		return {}
	var result: Dictionary = Dictionary(result_variant)
	if not bool(result.get("ok", false)):
		return {}
	var data_variant: Variant = result.get("data", {})
	return Dictionary(data_variant).duplicate(true) if data_variant is Dictionary else {}

static func _find_inspector_content(panel: Control) -> VBoxContainer:
	var scroll: ScrollContainer = _find_first_scroll(panel)
	if scroll == null:
		return null
	for child in scroll.get_children():
		if child is VBoxContainer:
			return child as VBoxContainer
	return null

static func _find_first_scroll(node: Node) -> ScrollContainer:
	if node is ScrollContainer:
		return node as ScrollContainer
	for child in node.get_children():
		var result: ScrollContainer = _find_first_scroll(child)
		if result != null:
			return result
	return null

static func _find_first_label(node: Node) -> Label:
	if node is Label:
		return node as Label
	for child in node.get_children():
		var result: Label = _find_first_label(child)
		if result != null:
			return result
	return null

static func _ui_color(ui: Object, property_name: String, fallback: Color) -> Color:
	var value: Variant = _get_property(ui, property_name)
	return value if value is Color else fallback

static func _get_property(target: Object, property_name: String) -> Variant:
	if target == null or not _has_property(target, property_name):
		return null
	return target.get(property_name)

static func _has_property(target: Object, property_name: String) -> bool:
	if target == null:
		return false
	for property_data in target.get_property_list():
		if str(property_data.get("name", "")) == property_name:
			return true
	return false
