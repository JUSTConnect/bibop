extends Node
class_name ObjectStatusLayerService

const EntityStatusEvaluatorRef = preload("res://scripts/world/entity_status_evaluator.gd")
const STATUS_SECTION_NAME := "ObjectStatusLayerSection"

func evaluate_object_status(object_data: Dictionary, context: Dictionary = {}) -> Dictionary:
	return EntityStatusEvaluatorRef.evaluate(object_data, context)

func normalize_object_status(object_data: Dictionary) -> Dictionary:
	return object_data.duplicate(true)

func ensure_object_status(_manager: Object, _entity_id: String, object_data: Dictionary) -> Dictionary:
	return evaluate_object_status(object_data)

func build_status_summary(object_data: Dictionary) -> Dictionary:
	var result: Dictionary = evaluate_object_status(object_data)
	return {"applies":not Dictionary(result.get("sections", {})).is_empty(), "total_state":"ready" if bool(result.get("is_operational", false)) else "not_ready", "warnings":[] if bool(result.get("is_operational", false)) else [str(result.get("reason_code", "blocked"))]}

func get_status_display_lines(object_data: Dictionary) -> Array[String]:
	var result: Dictionary = evaluate_object_status(object_data)
	if Dictionary(result.get("sections", {})).is_empty():
		return []
	var lines: Array[String] = []
	lines.append("Effective state: %s" % str(result.get("effective_state", "operational")))
	lines.append("Operational: %s" % str(result.get("is_operational", false)))
	if not str(result.get("reason_code", "")).is_empty():
		lines.append("Reason: %s" % str(result.get("reason_code", "")))
	return lines

func applies_to_object(object_data: Dictionary) -> bool:
	return not Dictionary(evaluate_object_status(object_data).get("sections", {})).is_empty()

func build_read_only_status_section(ui: Object, object_data: Dictionary) -> VBoxContainer:
	var result: Dictionary = evaluate_object_status(object_data, {"mode":"map_constructor"})
	var section: VBoxContainer = VBoxContainer.new()
	section.name = STATUS_SECTION_NAME
	section.add_theme_constant_override("separation", 4)
	var header: Label = Label.new()
	header.text = "2. Object Status Layer"
	header.add_theme_color_override("font_color", _ui_color(ui, "UI_COLOR_ACCENT", Color(0.2, 0.76, 0.95, 1.0)))
	section.add_child(header)
	section.add_child(_create_property_row(ui, "Effective state", _read_only_label(str(result.get("effective_state", "operational")))))
	section.add_child(_create_property_row(ui, "Operational", _read_only_label(str(result.get("is_operational", false)))))
	section.add_child(_create_property_row(ui, "Reason", _read_only_label(str(result.get("reason_code", "operational")))))
	var sections: Dictionary = Dictionary(result.get("sections", {}))
	for section_key in sections.keys():
		var status_section: Dictionary = Dictionary(sections[section_key])
		var text: String = str(status_section.get("value", ""))
		if status_section.has("forced_value"):
			text = "%s (real: %s, forced: %s)" % [str(status_section.get("value", "")), str(status_section.get("real_value", "")), str(status_section.get("forced_value", ""))]
		section.add_child(_create_property_row(ui, str(section_key).capitalize(), _read_only_label(text)))
	return section

func decorate_current_inspector(ui: Object, manager: Object) -> bool:
	if ui == null or manager == null or not is_instance_valid(ui) or not is_instance_valid(manager):
		return false
	var panel: Control = _get_object_property(ui, "runtime_map_constructor_inspector_panel") as Control
	if panel == null or not is_instance_valid(panel):
		return false
	var content: VBoxContainer = _find_inspector_content(panel)
	if content == null or not is_instance_valid(content):
		return false
	if content.get_node_or_null(STATUS_SECTION_NAME) != null:
		return true
	var entity_kind: String = str(_get_object_property(ui, "selected_map_constructor_entity_kind")).strip_edges()
	var entity_id: String = str(_get_object_property(ui, "selected_map_constructor_entity_id")).strip_edges()
	if entity_kind != "world_object" or entity_id.is_empty() or not manager.has_method("get_map_constructor_entity_by_id"):
		return false
	var entity_info_variant: Variant = manager.call("get_map_constructor_entity_by_id", entity_kind, entity_id)
	if not (entity_info_variant is Dictionary):
		return false
	var entity_info: Dictionary = Dictionary(entity_info_variant)
	if not bool(entity_info.get("ok", false)):
		return false
	var data: Dictionary = Dictionary(entity_info.get("data", {}))
	if not applies_to_object(data):
		return false
	var section: VBoxContainer = build_read_only_status_section(ui, data)
	content.add_child(section)
	var insert_index: int = _find_insert_index_after_identity(content)
	content.move_child(section, insert_index)
	return true

func _read_only_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

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

func _find_insert_index_after_identity(content: VBoxContainer) -> int:
	for index in range(content.get_child_count()):
		var first_label: Label = _find_first_label(content.get_child(index))
		if first_label != null and str(first_label.text).begins_with("1."):
			return mini(index + 1, content.get_child_count() - 1)
	return 0

func _find_first_label(node: Node) -> Label:
	if node is Label:
		return node as Label
	for child in node.get_children():
		var result: Label = _find_first_label(child)
		if result != null:
			return result
	return null

func _create_property_row(ui: Object, label_text: String, control: Control) -> Control:
	if ui != null and is_instance_valid(ui) and ui.has_method("_create_property_row"):
		return ui.call("_create_property_row", label_text, control)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(150, 0)
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row

func _get_object_property(target: Object, property_name: String) -> Variant:
	if target == null:
		return null
	return target.get(property_name)

func _ui_color(ui: Object, property_name: String, fallback: Color) -> Color:
	var value: Variant = _get_object_property(ui, property_name)
	if value is Color:
		return value
	return fallback
