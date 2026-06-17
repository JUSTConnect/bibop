extends RefCounted
class_name MapConstructorObjectRefListControl

static func add_object_ref_array_property(ui: Variant, section: VBoxContainer, label: String, entity_kind: String, entity_id: String, field_name: String, current_value: Variant) -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var selected: Array = MapConstructorUiSafe.safe_array(current_value).duplicate()
	var requires_self_membership: bool = field_name == "cooling_contour_member_ids"
	if requires_self_membership and not selected.has(entity_id):
		selected.append(entity_id)
	var options: Array = []
	if ui.mission_manager_runtime != null and ui.mission_manager_runtime.has_method("get_map_constructor_object_ref_options"):
		options = MapConstructorUiSafe.safe_array(ui.mission_manager_runtime.call("get_map_constructor_object_ref_options", entity_kind, entity_id, field_name))
	if options.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No compatible objects."
		box.add_child(empty_label)
	for option_variant in options:
		var row: Dictionary = MapConstructorUiSafe.safe_dictionary(option_variant)
		var option_id: String = MapConstructorUiSafe.safe_string(row.get("id", "")).strip_edges()
		if option_id.is_empty():
			continue
		var check: CheckBox = CheckBox.new()
		var option_label: String = MapConstructorUiSafe.safe_string(row.get("label", "")).strip_edges()
		if option_label.is_empty() or option_label == option_id:
			option_label = MapConstructorUiSafe.safe_string(row.get("display_name", row.get("name", option_id)), option_id)
		check.text = option_label
		check.tooltip_text = option_id
		check.button_pressed = selected.has(option_id) or bool(row.get("checked", false))
		check.disabled = bool(row.get("disabled", false))
		check.toggled.connect(func(pressed: bool) -> void:
			if pressed and not selected.has(option_id):
				selected.append(option_id)
			elif not pressed and selected.has(option_id):
				selected.erase(option_id)
			if requires_self_membership and not selected.has(entity_id):
				selected.append(entity_id)
			ui._apply_map_constructor_property_updates(entity_kind, entity_id, {field_name:selected.duplicate()})
		)
		box.add_child(check)
	section.add_child(MapConstructorPropertyControls.create_property_row(ui, label, box, true))
