extends Node
class_name MapConstructorInspectorStructureLayerService

const CHECK_INTERVAL := 0.25
const SEPARATOR_GROUP := "map_constructor_inspector_structure_separator"
const SEPARATOR_NAME_PREFIX := "InspectorBlockSeparator"
const IDENTITY_SECTION_NAME := "SharedIdentitySection"
const STATUS_SECTION_NAME := "SharedStatusSection"
const CONFIG_SECTION_TITLE := "3. Configurable parameters"
const SECTION_META_LAYER := "map_constructor_structure_layer"
const SECTION_META_ENTITY_KIND := "entity_kind"
const SECTION_META_ENTITY_ID := "entity_id"

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
	var entity_kind: String = str(_get_property(ui, "selected_map_constructor_entity_kind")).strip_edges()
	var entity_id: String = str(_get_property(ui, "selected_map_constructor_entity_id")).strip_edges()
	if entity_kind.is_empty() or entity_id.is_empty():
		return
	var data: Dictionary = _get_selected_entity_data(ui, entity_kind, entity_id)
	if data.is_empty():
		return
	_remove_existing_separators(content)
	var identity: VBoxContainer = _ensure_identity_section(ui, content, entity_kind, entity_id, data)
	_remove_legacy_status_sections(content)
	var status: VBoxContainer = _ensure_status_section(ui, content, entity_kind, entity_id, data)
	var config: VBoxContainer = _find_configurable_section(content)
	if config != null and is_instance_valid(config):
		_set_section_title(config, CONFIG_SECTION_TITLE)
	_order_top_sections(content, [identity, status, config])
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


func _ensure_identity_section(ui: Object, content: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> VBoxContainer:
	var existing: VBoxContainer = _find_tagged_section(content, IDENTITY_SECTION_NAME)
	if existing != null and is_instance_valid(existing) and str(existing.get_meta(SECTION_META_ENTITY_KIND, "")) == entity_kind and str(existing.get_meta(SECTION_META_ENTITY_ID, "")) == entity_id:
		_remove_other_identity_sections(content, existing)
		return existing
	_remove_identity_sections(content)
	var section: VBoxContainer = _create_identity_section(ui, entity_kind, entity_id, data)
	content.add_child(section)
	return section


func _create_identity_section(ui: Object, entity_kind: String, entity_id: String, data: Dictionary) -> VBoxContainer:
	var section: VBoxContainer = _create_section_container(ui, "1. Identity")
	section.name = IDENTITY_SECTION_NAME
	section.set_meta(SECTION_META_LAYER, true)
	section.set_meta(SECTION_META_ENTITY_KIND, entity_kind)
	section.set_meta(SECTION_META_ENTITY_ID, entity_id)
	_add_identity_name_row(ui, section, entity_kind, entity_id, data)
	_add_identity_description_row(ui, section, entity_kind, entity_id, data)
	return section


func _add_identity_name_row(ui: Object, section: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> void:
	var line_edit := LineEdit.new()
	line_edit.text = str(data.get("display_name", data.get("name", "")))
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.expand_to_text_length = false
	var apply_button := Button.new()
	apply_button.text = "Apply"
	apply_button.focus_mode = Control.FOCUS_NONE
	apply_button.custom_minimum_size = Vector2(72, 30)
	var apply_update := func() -> void:
		_apply_entity_updates(ui, entity_kind, entity_id, {"display_name": line_edit.text}, "Name updated.")
	line_edit.text_submitted.connect(func(_text: String) -> void:
		apply_update.call()
	)
	apply_button.pressed.connect(func() -> void:
		apply_update.call()
	)
	var row_controls := HBoxContainer.new()
	row_controls.add_theme_constant_override("separation", 6)
	row_controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_controls.add_child(line_edit)
	row_controls.add_child(apply_button)
	section.add_child(_create_property_row(ui, "Name", row_controls))


func _add_identity_description_row(ui: Object, section: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> void:
	var desc_edit := TextEdit.new()
	desc_edit.text = str(data.get("description", data.get("custom_description", ""))).strip_edges()
	desc_edit.placeholder_text = "No description."
	desc_edit.custom_minimum_size = Vector2(0, 72)
	desc_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var apply_button := Button.new()
	apply_button.text = "Apply"
	apply_button.focus_mode = Control.FOCUS_NONE
	apply_button.custom_minimum_size = Vector2(72, 72)
	apply_button.size_flags_vertical = Control.SIZE_FILL
	apply_button.pressed.connect(func() -> void:
		_apply_entity_updates(ui, entity_kind, entity_id, {"description": desc_edit.text}, "Description updated.")
	)
	var row_controls := HBoxContainer.new()
	row_controls.add_theme_constant_override("separation", 6)
	row_controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_controls.add_child(desc_edit)
	row_controls.add_child(apply_button)
	section.add_child(_create_property_row(ui, "Description", row_controls))


func _ensure_status_section(ui: Object, content: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> VBoxContainer:
	var existing: VBoxContainer = _find_tagged_section(content, STATUS_SECTION_NAME)
	if existing == null or not is_instance_valid(existing) or str(existing.get_meta(SECTION_META_ENTITY_KIND, "")) != entity_kind or str(existing.get_meta(SECTION_META_ENTITY_ID, "")) != entity_id:
		if existing != null and is_instance_valid(existing):
			content.remove_child(existing)
			existing.queue_free()
		existing = _create_status_section(ui, entity_kind, entity_id, data)
		content.add_child(existing)
	else:
		_refresh_status_section(existing, data)
	return existing


func _create_status_section(ui: Object, entity_kind: String, entity_id: String, data: Dictionary) -> VBoxContainer:
	var section: VBoxContainer = _create_section_container(ui, "2. Status")
	section.name = STATUS_SECTION_NAME
	section.set_meta(SECTION_META_LAYER, true)
	section.set_meta(SECTION_META_ENTITY_KIND, entity_kind)
	section.set_meta(SECTION_META_ENTITY_ID, entity_id)
	_add_status_value_row(ui, section, "Object type", _get_object_type_text(data), "ObjectTypeValue")
	_add_status_value_row(ui, section, "Total state", _get_total_state_text(data), "TotalStateValue")
	_add_status_value_row(ui, section, "Power state", _get_power_state_text(data), "PowerStateValue")
	return section


func _refresh_status_section(section: VBoxContainer, data: Dictionary) -> void:
	_set_named_label_text(section, "ObjectTypeValue", _get_object_type_text(data))
	_set_named_label_text(section, "TotalStateValue", _get_total_state_text(data))
	_set_named_label_text(section, "PowerStateValue", _get_power_state_text(data))


func _add_status_value_row(ui: Object, section: VBoxContainer, label_text: String, value_text: String, value_name: String) -> void:
	var label := Label.new()
	label.name = value_name
	label.text = value_text
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	section.add_child(_create_property_row(ui, label_text, label))


func _set_named_label_text(node: Node, target_name: String, value_text: String) -> void:
	if node == null:
		return
	var label: Label = node.find_child(target_name, true, false) as Label
	if label != null and is_instance_valid(label):
		label.text = value_text


func _get_object_type_text(data: Dictionary) -> String:
	var value: String = str(data.get("object_type", data.get("item_type", data.get("type", "unknown")))).strip_edges()
	return value if not value.is_empty() else "unknown"


func _get_power_state_text(data: Dictionary) -> String:
	var explicit_state: String = str(data.get("object_power_state", data.get("power_state", ""))).strip_edges().to_lower()
	if explicit_state in ["powered", "unpowered", "none"]:
		return explicit_state
	if data.has("is_powered"):
		return "powered" if bool(data.get("is_powered", false)) else "unpowered"
	return "none"


func _get_total_state_text(data: Dictionary) -> String:
	var explicit_total: String = str(data.get("object_total_state", "")).strip_edges().to_lower()
	if explicit_total == "ready":
		return "Ready"
	if explicit_total == "not_ready":
		return "Not ready"
	var state: String = str(data.get("object_state", data.get("state", data.get("status", "on")))).strip_edges().to_lower()
	var power_state: String = _get_power_state_text(data)
	if state in ["off", "broken", "overheat", "overheated", "damaged", "disabled"]:
		return "Not ready"
	if power_state == "unpowered":
		return "Not ready"
	return "Ready"


func _find_configurable_section(content: VBoxContainer) -> VBoxContainer:
	for child in content.get_children():
		if not (child is VBoxContainer):
			continue
		if _is_tagged_identity_or_status(child):
			continue
		var title: String = _get_section_title(child).strip_edges().to_lower()
		if title.contains("configurable") or title.contains("configuration"):
			return child as VBoxContainer
	return null


func _order_top_sections(content: VBoxContainer, ordered_sections: Array) -> void:
	var index: int = 0
	for section_variant in ordered_sections:
		if section_variant == null:
			continue
		var section: Node = section_variant as Node
		if section == null or not is_instance_valid(section) or section.get_parent() != content:
			continue
		content.move_child(section, index)
		index += 1


func _remove_identity_sections(content: VBoxContainer) -> void:
	var remove_nodes: Array[Node] = []
	for child in content.get_children():
		if child is VBoxContainer and _is_identity_section(child):
			remove_nodes.append(child)
	for node in remove_nodes:
		content.remove_child(node)
		node.queue_free()


func _remove_other_identity_sections(content: VBoxContainer, keep: Node) -> void:
	var remove_nodes: Array[Node] = []
	for child in content.get_children():
		if child == keep:
			continue
		if child is VBoxContainer and _is_identity_section(child):
			remove_nodes.append(child)
	for node in remove_nodes:
		content.remove_child(node)
		node.queue_free()


func _remove_legacy_status_sections(content: VBoxContainer) -> void:
	var remove_nodes: Array[Node] = []
	for child in content.get_children():
		if not (child is VBoxContainer):
			continue
		if str(child.name) == STATUS_SECTION_NAME:
			continue
		var title: String = _get_section_title(child).strip_edges().to_lower()
		if title.contains("current status") or title.contains("object status") or title.contains("unified object status"):
			remove_nodes.append(child)
	for node in remove_nodes:
		content.remove_child(node)
		node.queue_free()


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


func _create_section_container(ui: Object, title: String) -> VBoxContainer:
	var section: VBoxContainer = null
	if ui != null and is_instance_valid(ui) and ui.has_method("_create_inspector_section"):
		section = ui.call("_create_inspector_section", title) as VBoxContainer
	if section == null:
		section = VBoxContainer.new()
		section.add_theme_constant_override("separation", 4)
		var header := Label.new()
		header.text = title
		section.add_child(header)
	_set_section_title(section, title)
	return section


func _set_section_title(section: Node, title: String) -> void:
	var label: Label = _find_first_label(section)
	if label != null and is_instance_valid(label):
		label.text = title


func _get_section_title(section: Node) -> String:
	var label: Label = _find_first_label(section)
	return str(label.text) if label != null else ""


func _is_identity_section(node: Node) -> bool:
	if node == null:
		return false
	if str(node.name) == IDENTITY_SECTION_NAME:
		return true
	var title: String = _get_section_title(node).strip_edges().to_lower()
	return title == "1. identity" or title == "identity" or title.ends_with(" identity")


func _is_tagged_identity_or_status(node: Node) -> bool:
	return str(node.name) == IDENTITY_SECTION_NAME or str(node.name) == STATUS_SECTION_NAME


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


func _create_property_row(ui: Object, label_text: String, control: Control) -> Control:
	if ui != null and is_instance_valid(ui) and ui.has_method("_create_property_row"):
		return ui.call("_create_property_row", label_text, control)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(120, 0)
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row


func _apply_entity_updates(ui: Object, entity_kind: String, entity_id: String, updates: Dictionary, hint_text: String = "Updated.") -> void:
	if ui == null or not is_instance_valid(ui):
		return
	if ui.has_method("_apply_map_constructor_property_updates"):
		ui.call("_apply_map_constructor_property_updates", entity_kind, entity_id, updates, hint_text)
		return
	var manager: Object = _get_property(ui, "mission_manager_runtime") as Object
	if manager == null or not is_instance_valid(manager):
		return
	if entity_kind == "world_object" and manager.has_method("get_map_constructor_entity_by_id") and manager.has_method("update_world_object_by_id"):
		var entity_info_variant: Variant = manager.call("get_map_constructor_entity_by_id", entity_kind, entity_id)
		if entity_info_variant is Dictionary:
			var entity_info: Dictionary = Dictionary(entity_info_variant)
			if bool(entity_info.get("ok", false)):
				var data: Dictionary = Dictionary(entity_info.get("data", {})).duplicate(true)
				for key_variant in updates.keys():
					data[str(key_variant)] = updates[key_variant]
				manager.call("update_world_object_by_id", entity_id, data)
	if ui.has_method("show_hint"):
		ui.call("show_hint", hint_text)
	if ui.has_method("_refresh_map_constructor_panels"):
		ui.call_deferred("_refresh_map_constructor_panels")


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
	if data_variant is Dictionary:
		return Dictionary(data_variant)
	return {}


func _find_tagged_section(content: VBoxContainer, section_name: String) -> VBoxContainer:
	for child in content.get_children():
		if str(child.name) == section_name and child is VBoxContainer:
			return child as VBoxContainer
	return null


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
	if value is Color:
		return value
	return fallback


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
