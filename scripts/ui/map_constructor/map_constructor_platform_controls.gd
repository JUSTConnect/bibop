extends RefCounted
class_name MapConstructorPlatformControls

const PlatformTypesRef = preload("res://scripts/game/platform/platform_types.gd")
const PlatformMechanismServiceRef = preload("res://scripts/game/platform/platform_mechanism_service.gd")
const PlatformControlServiceRef = preload("res://scripts/game/platform/platform_control_service.gd")

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
	_add_mechanism(ui, parent, entity_kind, entity_id, data)
	_add_control(ui, parent, entity_kind, entity_id, data)
	_add_power(ui, parent, entity_kind, entity_id, data)
	_add_warnings(ui, parent, data)

static func _add_identity(ui: Variant, parent: VBoxContainer, entity_id: String, data: Dictionary) -> void:
	var section: VBoxContainer = ui._create_inspector_section("1. Identity")
	var id_label := Label.new(); id_label.text = entity_id; section.add_child(ui._create_property_row("ID", id_label))
	var type_label := Label.new(); type_label.text = "platform"; section.add_child(ui._create_property_row("Object type", type_label))
	ui._add_text_property(section, "Name", "world_object", entity_id, "display_name", data.get("display_name", "Platform"))
	parent.add_child(section)

static func _add_placement(ui: Variant, parent: VBoxContainer, entity_kind: String, entity_id: String, cell: Vector2i, data: Dictionary) -> void:
	var section: VBoxContainer = ui._create_inspector_section("2. Placement")
	var cell_label := Label.new(); cell_label.text = str(cell); section.add_child(ui._create_property_row("Cell", cell_label))
	var mode_label := Label.new(); mode_label.text = MapConstructorUiSafe.safe_string(data.get("placement_mode", "object"), "object"); section.add_child(ui._create_property_row("Mode", mode_label))
	var row := HBoxContainer.new()
	var x := SpinBox.new(); x.step = 1; x.min_value = -999; x.max_value = 999; x.value = float(cell.x)
	var y := SpinBox.new(); y.step = 1; y.min_value = -999; y.max_value = 999; y.value = float(cell.y)
	var move := Button.new(); move.text = "Move"; move.pressed.connect(func() -> void: MapConstructorActions.move_entity_to_cell(ui, entity_kind, entity_id, Vector2i(int(x.value), int(y.value))))
	row.add_child(x); row.add_child(y); row.add_child(move)
	section.add_child(ui._create_property_row("Position", row))
	var delete_button := Button.new(); delete_button.text = "Delete"; delete_button.pressed.connect(func() -> void: MapConstructorActions.delete_entity_by_id(ui, entity_kind, entity_id, cell))
	section.add_child(delete_button)
	parent.add_child(section)

static func _add_configuration(ui: Variant, parent: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> void:
	var section: VBoxContainer = ui._create_inspector_section("3. Platform Configuration")
	ui._add_enum_property(section, "Mode", entity_kind, entity_id, "platform_mode", data.get("platform_mode", "elevator"), _options(["elevator", "rotator", "elevator_rotator"]))
	ui._add_text_property(section, "Platform level", entity_kind, entity_id, "platform_level", data.get("platform_level", 0))
	ui._add_text_property(section, "Max level", entity_kind, entity_id, "max_level", data.get("max_level", 1))
	parent.add_child(section)

static func _add_mechanism(ui: Variant, parent: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> void:
	var section: VBoxContainer = ui._create_inspector_section("4. Platform Mechanism")
	ui._add_text_property(section, "Mechanism ID", entity_kind, entity_id, "mechanism_id", data.get("mechanism_id", ""))
	ui._add_enum_property(section, "Role", entity_kind, entity_id, "mechanism_role", data.get("mechanism_role", "single"), _options(["single"]))
	var summary: Dictionary = _get_mechanism_summary(ui, data)
	var members := Label.new(); members.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; members.text = "Members: %d" % int(summary.get("member_count", 0))
	section.add_child(ui._create_property_row("Summary", members))
	var validate_button := Button.new(); validate_button.text = "Validate mechanism"; validate_button.pressed.connect(func() -> void:
		var validation: Dictionary = _validate_mechanism(ui, data)
		ui.show_hint("Platform mechanism valid." if bool(validation.get("ok", false)) else "Platform mechanism warnings: %s" % str(validation.get("warnings", [])))
	)
	section.add_child(validate_button)
	parent.add_child(section)

static func _add_control(ui: Variant, parent: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> void:
	var section: VBoxContainer = ui._create_inspector_section("5. Control")
	ui._add_enum_property(section, "Control type", entity_kind, entity_id, "control_type", data.get("control_type", "internal"), _options(["internal", "external"]))
	ui._add_enum_property(section, "Activation", entity_kind, entity_id, "activation_mode", data.get("activation_mode", "instant"), _options(["instant", "delayed"]))
	ui._add_text_property(section, "Delay turns", entity_kind, entity_id, "activation_delay_turns", data.get("activation_delay_turns", 0))
	ui._add_text_property(section, "Control cell X", entity_kind, entity_id, "control_cell_x", data.get("control_cell_x", 0))
	ui._add_text_property(section, "Control cell Y", entity_kind, entity_id, "control_cell_y", data.get("control_cell_y", 0))
	var actions: Dictionary = _get_actions(ui, entity_id, data)
	var action_label := Label.new(); action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; action_label.text = _format_action_labels(Array(actions.get("actions", [])))
	section.add_child(ui._create_property_row("Actions", action_label))
	parent.add_child(section)

static func _add_power(ui: Variant, parent: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> void:
	var section: VBoxContainer = ui._create_inspector_section("6. Power")
	ui._add_enum_property(section, "Power type", entity_kind, entity_id, "power_type", data.get("power_type", "none"), _options(["none", "internal", "external"]))
	var note := Label.new(); note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; note.text = "Power controls availability only. Motion and rotation still require explicit actions."
	section.add_child(note)
	parent.add_child(section)

static func _add_warnings(ui: Variant, parent: VBoxContainer, data: Dictionary) -> void:
	var section: VBoxContainer = ui._create_inspector_section("7. Warnings")
	var validation: Dictionary = _validate_mechanism(ui, data)
	var warnings: Array = Array(validation.get("warnings", []))
	if warnings.is_empty():
		var ok := Label.new(); ok.text = "No platform warnings."; section.add_child(ok)
	else:
		for warning_variant in warnings:
			var warning := Label.new(); warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; warning.text = str(warning_variant); section.add_child(warning)
	parent.add_child(section)

static func _options(values: Array[String]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in values:
		result.append({"label": value.replace("_", " ").capitalize(), "value": value})
	return result

static func _get_mechanism_summary(ui: Variant, data: Dictionary) -> Dictionary:
	var mechanism_id: String = MapConstructorUiSafe.safe_string(data.get("mechanism_id", ""))
	if ui.mission_manager_runtime != null and ui.mission_manager_runtime.has_method("get_platform_mechanism_summary"):
		return MapConstructorUiSafe.safe_dictionary(ui.mission_manager_runtime.call("get_platform_mechanism_summary", mechanism_id))
	return PlatformMechanismServiceRef.build_mechanism_summary(mechanism_id, [])

static func _validate_mechanism(ui: Variant, data: Dictionary) -> Dictionary:
	var mechanism_id: String = MapConstructorUiSafe.safe_string(data.get("mechanism_id", ""))
	if ui.mission_manager_runtime != null and ui.mission_manager_runtime.has_method("validate_platform_mechanism"):
		return MapConstructorUiSafe.safe_dictionary(ui.mission_manager_runtime.call("validate_platform_mechanism", mechanism_id))
	return PlatformMechanismServiceRef.validate_mechanism(mechanism_id, [])

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
