extends RefCounted
class_name MapConstructorPlatformControls

const PlatformTypesRef = preload("res://scripts/game/platform/platform_types.gd")
const PlatformMechanismServiceRef = preload("res://scripts/game/platform/platform_mechanism_service.gd")
const PlatformControlServiceRef = preload("res://scripts/game/platform/platform_control_service.gd")
const MapConstructorInspectorVisibilityServiceRef = preload("res://scripts/ui/map_constructor/map_constructor_inspector_visibility_service.gd")
const MapConstructorLinkControlsRef = preload("res://scripts/ui/map_constructor/map_constructor_link_controls.gd")

static func is_platform(data: Dictionary) -> bool:
	return PlatformTypesRef.is_platform_data(data)

static func render(ui: Variant, parent: VBoxContainer, entity_info: Dictionary, fallback_cell: Vector2i) -> void:
	var entity_kind: String = MapConstructorUiSafe.safe_string(entity_info.get("entity_kind", "world_object"), "world_object")
	var entity_id: String = MapConstructorUiSafe.safe_string(entity_info.get("id", ""))
	var data: Dictionary = PlatformTypesRef.normalize_platform_config(MapConstructorUiSafe.safe_dictionary(entity_info.get("data", {})))
	var cell: Vector2i = ui._safe_ui_vector2i(entity_info.get("cell", fallback_cell))
	ui.selected_map_constructor_entity_kind = entity_kind
	ui.selected_map_constructor_entity_id = entity_id
	ui.selected_map_constructor_entity_cell = cell
	_add_identity(ui, parent, entity_id, data)
	_add_placement(ui, parent, entity_kind, entity_id, cell, data)
	_add_configuration(ui, parent, entity_kind, entity_id, data)
	_add_mechanism(ui, parent, entity_kind, entity_id, cell, data)
	_add_control(ui, parent, entity_kind, entity_id, cell, data)
	_add_power(ui, parent, entity_kind, entity_id, data)
	_add_warnings(ui, parent, entity_id, data)

static func _add_identity(ui: Variant, parent: VBoxContainer, entity_id: String, data: Dictionary) -> void:
	var section: VBoxContainer = ui._create_inspector_section("1. Identity")
	var id_label: Label = Label.new()
	id_label.text = entity_id
	section.add_child(ui._create_property_row("ID", id_label))
	var type_label: Label = Label.new()
	type_label.text = "platform"
	section.add_child(ui._create_property_row("Object type", type_label))
	ui._add_text_property(section, "Name", "world_object", entity_id, "display_name", data.get("display_name", "Platform"))
	parent.add_child(section)

static func _add_placement(ui: Variant, parent: VBoxContainer, entity_kind: String, entity_id: String, cell: Vector2i, data: Dictionary) -> void:
	var section: VBoxContainer = ui._create_inspector_section("2. Placement")
	var cell_label: Label = Label.new()
	cell_label.text = str(cell)
	section.add_child(ui._create_property_row("Cell", cell_label))
	var mode_label: Label = Label.new()
	mode_label.text = MapConstructorUiSafe.safe_string(data.get("placement_mode", "object"), "object")
	section.add_child(ui._create_property_row("Mode", mode_label))
	var row: HBoxContainer = HBoxContainer.new()
	var x_spin: SpinBox = SpinBox.new()
	x_spin.step = 1
	x_spin.min_value = -999
	x_spin.max_value = 999
	x_spin.value = float(cell.x)
	var y_spin: SpinBox = SpinBox.new()
	y_spin.step = 1
	y_spin.min_value = -999
	y_spin.max_value = 999
	y_spin.value = float(cell.y)
	var move_button: Button = Button.new()
	move_button.text = "Move"
	move_button.pressed.connect(func() -> void: MapConstructorActions.move_entity_to_cell(ui, entity_kind, entity_id, Vector2i(int(x_spin.value), int(y_spin.value))))
	row.add_child(x_spin)
	row.add_child(y_spin)
	row.add_child(move_button)
	section.add_child(ui._create_property_row("Position", row))
	var delete_button: Button = Button.new()
	delete_button.text = "Delete"
	delete_button.pressed.connect(func() -> void: MapConstructorActions.delete_entity_by_id(ui, entity_kind, entity_id, cell))
	section.add_child(delete_button)
	parent.add_child(section)

static func _add_configuration(ui: Variant, parent: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> void:
	var section: VBoxContainer = ui._create_inspector_section("3. Platform Configuration")
	ui._add_enum_property(section, "Mode", entity_kind, entity_id, "platform_mode", data.get("platform_mode", "elevator"), _options(["elevator", "rotate"]))
	ui._add_text_property(section, "Platform level", entity_kind, entity_id, "platform_level", data.get("platform_level", 0))
	ui._add_text_property(section, "Max level", entity_kind, entity_id, "max_level", data.get("max_level", 1))
	parent.add_child(section)

static func _add_mechanism(ui: Variant, parent: VBoxContainer, entity_kind: String, entity_id: String, cell: Vector2i, data: Dictionary) -> void:
	var section: VBoxContainer = ui._create_inspector_section("4. Platform Mechanism")
	ui._add_text_property(section, "Mechanism ID", entity_kind, entity_id, "mechanism_id", data.get("mechanism_id", ""))
	var summary: Dictionary = _get_mechanism_summary(ui, entity_id, data)
	var summary_label: Label = Label.new()
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.text = _format_mechanism_summary(summary)
	section.add_child(ui._create_property_row("Summary", summary_label))
	_add_platform_member_checklist(ui, section, entity_kind, entity_id, cell, data)
	var validate_button: Button = Button.new()
	validate_button.text = "Validate mechanism"
	validate_button.pressed.connect(func() -> void:
		var validation: Dictionary = _validate_mechanism(ui, entity_id, data)
		var validation_messages: Array = Array(validation.get("errors", [])) + Array(validation.get("warnings", []))
		ui.show_hint("Platform mechanism valid." if bool(validation.get("ok", false)) else "Platform mechanism issues: %s" % str(validation_messages))
	)
	section.add_child(validate_button)
	parent.add_child(section)

static func _add_platform_member_checklist(ui: Variant, section: VBoxContainer, _entity_kind: String, entity_id: String, _cell: Vector2i, data: Dictionary) -> void:
	var member_title: Label = Label.new()
	member_title.text = "Members"
	section.add_child(member_title)
	var mechanism_id: String = _effective_mechanism_id(entity_id, data)
	var rows: Array = _get_platform_candidate_rows(ui)
	if rows.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No placed platforms found."
		section.add_child(empty_label)
		return
	for row_variant in rows:
		var row: Dictionary = MapConstructorUiSafe.safe_dictionary(row_variant)
		var platform_id: String = str(row.get("id", "")).strip_edges()
		if platform_id.is_empty():
			continue
		var platform_cell: Vector2i = ui._safe_ui_vector2i(row.get("cell", Vector2i(-1, -1)))
		var platform_data: Dictionary = MapConstructorUiSafe.safe_dictionary(row.get("data", {}))
		var platform_mechanism_id: String = _effective_mechanism_id(platform_id, platform_data)
		var checked: bool = platform_id == entity_id or platform_mechanism_id == mechanism_id
		var current_kind: String = str(PlatformTypesRef.normalize_platform_config(data).get("platform_mode", PlatformTypesRef.MODE_ELEVATOR))
		var candidate_kind: String = str(PlatformTypesRef.normalize_platform_config(platform_data).get("platform_mode", PlatformTypesRef.MODE_ELEVATOR))
		var compatible_kind: bool = current_kind == candidate_kind
		var check: CheckBox = CheckBox.new()
		check.text = "%s at (%d, %d)%s" % [platform_id, platform_cell.x, platform_cell.y, "  ✓ current" if platform_id == entity_id else ""]
		check.button_pressed = checked and compatible_kind
		check.disabled = not compatible_kind
		check.tooltip_text = "Kind mismatch: %s platform cannot share a runtime mechanism with %s platform." % [candidate_kind, current_kind] if not compatible_kind else "Checked platforms share mechanism_id: %s" % mechanism_id
		check.toggled.connect(func(enabled: bool) -> void:
			var next_mechanism_id: String = mechanism_id if enabled else ""
			if platform_id == entity_id and not enabled:
				next_mechanism_id = _single_mechanism_id(platform_id)
			if enabled and MapConstructorUiSafe.safe_string(data.get("mechanism_id", "")).strip_edges().is_empty():
				ui.mission_manager_runtime.call("apply_map_constructor_property_update", "world_object", entity_id, "mechanism_id", mechanism_id)
			var result: Dictionary = ui.mission_manager_runtime.call("apply_map_constructor_property_update", "world_object", platform_id, "mechanism_id", next_mechanism_id)
			ui.show_hint(ui._safe_ui_string(result.get("message", "Platform mechanism updated."), "Platform mechanism updated."))
			ui._refresh_map_constructor_panels()
			if ui.field_runtime != null and ui.field_runtime.has_method("request_visual_refresh"):
				ui.field_runtime.call("request_visual_refresh")
			if ui.bipob != null and ui.bipob.has_method("refresh_world_action_panel"):
				ui.bipob.call("refresh_world_action_panel")
			ui._show_map_constructor_inspector(ui.selected_map_constructor_entity_cell, ui.selected_map_constructor_entity_kind, ui.selected_map_constructor_entity_id)
		)
		section.add_child(check)

static func _add_control(ui: Variant, parent: VBoxContainer, entity_kind: String, entity_id: String, cell: Vector2i, data: Dictionary) -> void:
	var section: VBoxContainer = ui._create_inspector_section("5. Control")
	ui._add_enum_property(section, "Control type", entity_kind, entity_id, "control_type", data.get("control_type", "internal"), _options(["internal", "external"]))
	if MapConstructorInspectorVisibilityServiceRef.should_show_internal_control_settings(data, "platform"):
		ui._add_enum_property(section, "Activation", entity_kind, entity_id, "activation_mode", data.get("activation_mode", "instant"), _options(["instant", "delayed"]))
		if PlatformTypesRef.normalize_activation_mode(str(data.get("activation_mode", "instant"))) == PlatformTypesRef.ACTIVATION_DELAYED:
			ui._add_text_property(section, "Delay turns", entity_kind, entity_id, "activation_delay_turns", data.get("activation_delay_turns", 0))
		_add_control_cell_checkbox(ui, section, entity_kind, entity_id, cell, data)
		ui._add_enum_property(section, "Control side", entity_kind, entity_id, "input_direction", data.get("input_direction", "SW"), _options(["SW", "SE"]))
		var actions: Dictionary = _get_actions(ui, entity_id, data)
		var action_label: Label = Label.new()
		action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		action_label.text = _format_action_labels(Array(actions.get("actions", [])))
		section.add_child(ui._create_property_row("Actions", action_label))
	elif MapConstructorInspectorVisibilityServiceRef.should_show_external_control_selector(data):
		MapConstructorLinkControlsRef.add_link_picker(ui, section, entity_kind, entity_id, "control_terminal", "Control Terminal Binding")
	parent.add_child(section)

static func _add_control_cell_checkbox(ui: Variant, section: VBoxContainer, entity_kind: String, entity_id: String, cell: Vector2i, data: Dictionary) -> void:
	var control_cell: Vector2i = Vector2i(int(data.get("control_cell_x", 0)), int(data.get("control_cell_y", 0)))
	var is_current: bool = control_cell == cell
	var checkbox: CheckBox = CheckBox.new()
	checkbox.text = "This cell is control cell"
	checkbox.button_pressed = is_current
	checkbox.toggled.connect(func(enabled: bool) -> void:
		var target_cell: Vector2i = cell if enabled else Vector2i(0, 0)
		var result_x: Dictionary = ui.mission_manager_runtime.call("apply_map_constructor_property_update", entity_kind, entity_id, "control_cell_x", target_cell.x)
		var result_y: Dictionary = ui.mission_manager_runtime.call("apply_map_constructor_property_update", entity_kind, entity_id, "control_cell_y", target_cell.y)
		ui.show_hint("Control cell updated." if bool(result_x.get("ok", false)) and bool(result_y.get("ok", false)) else "Control cell update failed.")
		ui._refresh_map_constructor_panels()
		if ui.field_runtime != null and ui.field_runtime.has_method("request_visual_refresh"):
			ui.field_runtime.call("request_visual_refresh")
		ui._show_map_constructor_inspector(ui.selected_map_constructor_entity_cell, ui.selected_map_constructor_entity_kind, ui.selected_map_constructor_entity_id)
	)
	section.add_child(ui._create_property_row("Control Cell", checkbox))

static func _add_power(ui: Variant, parent: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> void:
	var section: VBoxContainer = ui._create_inspector_section("6. Power")
	ui._add_enum_property(section, "Power type", entity_kind, entity_id, "power_type", data.get("power_type", "none"), _options(["none", "internal", "external"]))
	if MapConstructorInspectorVisibilityServiceRef.should_show_external_power_source_selector(data):
		MapConstructorLinkControlsRef.add_link_picker(ui, section, entity_kind, entity_id, "power_source", "Power Source Binding")
		if MapConstructorInspectorVisibilityServiceRef.should_show_external_circuit_selector(data):
			MapConstructorLinkControlsRef.add_link_picker(ui, section, entity_kind, entity_id, "power_network", "Power Network")
	var note: Label = Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text = "Power controls availability only. Motion and rotation still require explicit actions."
	section.add_child(note)
	parent.add_child(section)

static func _add_warnings(ui: Variant, parent: VBoxContainer, entity_id: String, data: Dictionary) -> void:
	var section: VBoxContainer = ui._create_inspector_section("7. Warnings")
	var validation: Dictionary = _validate_mechanism(ui, entity_id, data)
	var warnings: Array = Array(validation.get("warnings", []))
	if warnings.is_empty():
		var ok_label: Label = Label.new()
		ok_label.text = "No platform warnings."
		section.add_child(ok_label)
	else:
		for warning_variant in warnings:
			var warning: Label = Label.new()
			warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			warning.text = str(warning_variant)
			section.add_child(warning)
	parent.add_child(section)

static func _options(values: Array[String]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in values:
		result.append({"label": value.replace("_", " ").capitalize(), "value": value})
	return result

static func _single_mechanism_id(platform_id: String) -> String:
	return "single:%s" % platform_id.strip_edges()

static func _effective_mechanism_id(platform_id: String, data: Dictionary) -> String:
	var mechanism_id: String = MapConstructorUiSafe.safe_string(data.get("mechanism_id", "")).strip_edges()
	if mechanism_id.is_empty():
		mechanism_id = _single_mechanism_id(platform_id)
	return mechanism_id

static func _get_platform_candidate_rows(ui: Variant) -> Array:
	if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("get_map_constructor_placed_object_rows"):
		return []
	var rows: Array = []
	for row_variant in ui._safe_ui_array(ui.mission_manager_runtime.call("get_map_constructor_placed_object_rows")):
		var row: Dictionary = ui._safe_ui_dictionary(row_variant)
		var row_data: Dictionary = ui._safe_ui_dictionary(row.get("data", {}))
		if row_data.is_empty() and ui.mission_manager_runtime.has_method("get_map_constructor_entity_by_id"):
			var entity: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("get_map_constructor_entity_by_id", "world_object", ui._safe_ui_string(row.get("id", ""))))
			row_data = ui._safe_ui_dictionary(entity.get("data", {}))
		if PlatformTypesRef.is_platform_data(row_data):
			row["data"] = row_data
			rows.append(row)
	return rows

static func _format_mechanism_summary(summary: Dictionary) -> String:
	var ids: Array = Array(summary.get("platform_ids", []))
	var parts: Array[String] = []
	parts.append("Members: 0" if ids.is_empty() else "Members: %d — %s" % [ids.size(), ", ".join(ids)])
	var errors: Array = Array(summary.get("errors", []))
	var warnings: Array = Array(summary.get("warnings", []))
	if not errors.is_empty():
		parts.append("Errors: %s" % "; ".join(errors))
	if not warnings.is_empty():
		parts.append("Warnings: %s" % "; ".join(warnings))
	return "\n".join(parts)

static func _get_mechanism_summary(ui: Variant, entity_id: String, data: Dictionary) -> Dictionary:
	var mechanism_id: String = _effective_mechanism_id(entity_id, data)
	if ui.mission_manager_runtime != null and ui.mission_manager_runtime.has_method("get_platform_mechanism_summary"):
		return MapConstructorUiSafe.safe_dictionary(ui.mission_manager_runtime.call("get_platform_mechanism_summary", mechanism_id))
	return PlatformMechanismServiceRef.build_mechanism_summary(mechanism_id, [])

static func _validate_mechanism(ui: Variant, entity_id: String, data: Dictionary) -> Dictionary:
	var mechanism_id: String = _effective_mechanism_id(entity_id, data)
	var validation: Dictionary = {}
	if ui.mission_manager_runtime != null and ui.mission_manager_runtime.has_method("validate_platform_mechanism"):
		validation = MapConstructorUiSafe.safe_dictionary(ui.mission_manager_runtime.call("validate_platform_mechanism", mechanism_id))
	else:
		validation = PlatformMechanismServiceRef.validate_mechanism(mechanism_id, [])
	var warnings: Array = Array(validation.get("warnings", []))
	var current_kind: String = str(PlatformTypesRef.normalize_platform_config(data).get("platform_mode", PlatformTypesRef.MODE_ELEVATOR))
	var requested_ids: Array[String] = [entity_id]
	for field_name in ["platform_ids", "member_platform_ids", "mechanism_platform_ids", "linked_platform_ids", "members"]:
		for requested_variant in Array(data.get(field_name, [])):
			var requested_id: String = PlatformMechanismServiceRef.get_platform_id(Dictionary(requested_variant)) if requested_variant is Dictionary else str(requested_variant).strip_edges()
			if not requested_id.is_empty() and not requested_ids.has(requested_id):
				requested_ids.append(requested_id)
	var rows: Array = _get_platform_candidate_rows(ui)
	for row_variant in rows:
		var row: Dictionary = MapConstructorUiSafe.safe_dictionary(row_variant)
		var platform_id: String = str(row.get("id", "")).strip_edges()
		var platform_data: Dictionary = MapConstructorUiSafe.safe_dictionary(row.get("data", {}))
		if platform_id.is_empty():
			warnings.append("Rejected platform candidate: missing platform id.")
			continue
		var candidate_explicitly_linked: bool = requested_ids.has(platform_id)
		for field_name in ["platform_ids", "member_platform_ids", "mechanism_platform_ids", "linked_platform_ids", "members"]:
			if candidate_explicitly_linked:
				break
			for listed_variant in Array(platform_data.get(field_name, [])):
				var listed_id: String = PlatformMechanismServiceRef.get_platform_id(Dictionary(listed_variant)) if listed_variant is Dictionary else str(listed_variant).strip_edges()
				if listed_id == entity_id:
					candidate_explicitly_linked = true
					break
		var candidate_mechanism_id: String = _effective_mechanism_id(platform_id, platform_data)
		var candidate_kind: String = str(PlatformTypesRef.normalize_platform_config(platform_data).get("platform_mode", PlatformTypesRef.MODE_ELEVATOR))
		if candidate_mechanism_id != mechanism_id:
			if candidate_explicitly_linked:
				warnings.append("Rejected %s: mechanism id mismatch (%s != %s)." % [platform_id, candidate_mechanism_id, mechanism_id])
			continue
		if candidate_kind != current_kind:
			warnings.append("Rejected %s: kind mismatch (%s != %s)." % [platform_id, candidate_kind, current_kind])
	var cells: Array[Vector2i] = []
	for cell_variant in Array(validation.get("cells", [])):
		if cell_variant is Vector2i:
			cells.append(cell_variant)
	if current_kind == PlatformTypesRef.MODE_ROTATE and not PlatformMechanismServiceRef.is_square_footprint(cells, true):
		warnings.append("Rejected rotation plan: invalid/non-square rotator footprint.")
	if not PlatformMechanismServiceRef.are_cells_orthogonally_connected(cells):
		warnings.append("Rejected mechanism: members are not orthogonally connected.")
	validation["warnings"] = warnings
	return validation

static func _get_actions(ui: Variant, entity_id: String, data: Dictionary) -> Dictionary:
	if ui.mission_manager_runtime != null and ui.mission_manager_runtime.has_method("get_platform_control_actions"):
		return MapConstructorUiSafe.safe_dictionary(ui.mission_manager_runtime.call("get_platform_control_actions", entity_id))
	return {"ok": true, "actions": PlatformControlServiceRef.get_action_labels(data)}

static func _format_action_labels(actions: Array) -> String:
	var labels: Array[String] = []
	for action_variant in actions:
		var action: Dictionary = Dictionary(action_variant)
		var label: String = str(action.get("label", "Action"))
		if bool(action.get("delayed", false)):
			label += " (%d turn delay)" % int(action.get("pending_turns", 0))
		labels.append(label)
	return ", ".join(labels) if not labels.is_empty() else "No actions available."
