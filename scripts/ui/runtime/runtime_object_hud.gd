extends RefCounted
class_name RuntimeObjectHud


static func info_value(ui, object_data: Dictionary, keys: Array[String], fallback: String = "") -> String:
	for key in keys:
		var value: String = ui._safe_ui_string(object_data.get(key, "")).strip_edges()
		if not value.is_empty():
			return value
	return fallback


static func info_type_label(ui, object_data: Dictionary) -> String:
	var group: String = ui._safe_ui_string(object_data.get("object_group", "object"), "object").to_lower()
	var object_type: String = ui._safe_ui_string(object_data.get("object_type", group), group).to_lower()
	if group == "door" or object_type.contains("door") or object_type.contains("gate"):
		return "Door"
	if group == "terminal" or object_type.contains("terminal"):
		return "Terminal"
	if object_type.contains("cable"):
		return "Cable"
	if object_type.contains("switch"):
		return "Switch"
	return group.capitalize()


static func door_type_label(ui, object_data: Dictionary) -> String:
	var object_type: String = ui._safe_ui_string(object_data.get("object_type", "door")).to_lower()
	var access_type: String = ui._safe_ui_string(object_data.get("access_type", object_data.get("lock_type", ""))).to_lower()
	if object_type.contains("gate"):
		return "Powered gate"
	if access_type in ["digital", "digital_key", "access_code", "terminal_access"] or object_type.contains("digital") or bool(object_data.get("is_digital_device", false)):
		return "Digital"
	return "Mechanical"


static func access_type_label(value: String) -> String:
	match value.strip_edges().to_lower():
		"mechanical", "mechanical_key", "key", "mechanical_keycard":
			return "Mechanical key"
		"digital", "digital_key":
			return "Digital key"
		"password", "code", "access_code":
			return "Access code"
		"terminal", "terminal_access":
			return "Terminal access"
		"none", "no_key", "":
			return "No key"
	return value.capitalize()


static func position_panel(ui, panel: PanelContainer, cell: Vector2i) -> void:
	if ui == null or panel == null or not is_instance_valid(panel):
		return
	var viewport_size: Vector2 = ui.get_viewport().get_visible_rect().size
	panel.reset_size()
	var panel_size: Vector2 = panel.get_combined_minimum_size()
	var fallback_position := Vector2(maxf(8.0, viewport_size.x - panel_size.x - 16.0), 72.0)
	var target_position: Vector2 = fallback_position
	if ui.runtime_hud_root != null and is_instance_valid(ui.runtime_hud_root) and ui.field_runtime != null and is_instance_valid(ui.field_runtime):
		var renderer: Node = ui.field_runtime.get_node_or_null("RoomVisualRenderer")
		if renderer != null and is_instance_valid(renderer) and renderer.has_method("get_object_visual_center"):
			var anchor_local: Vector2 = renderer.call("get_object_visual_center", cell)
			var anchor_viewport: Vector2 = renderer.get_global_transform_with_canvas() * anchor_local
			var root_transform: Transform2D = ui.runtime_hud_root.get_global_transform_with_canvas()
			var anchor_ui: Vector2 = root_transform.affine_inverse() * anchor_viewport
			target_position = anchor_ui + Vector2(20.0, -panel_size.y * 0.5)
	var margin: float = 8.0
	panel.position = Vector2(
		clampf(target_position.x, margin, maxf(margin, viewport_size.x - panel_size.x - margin)),
		clampf(target_position.y, margin, maxf(margin, viewport_size.y - panel_size.y - margin))
	)


static func hide(ui) -> void:
	if ui.runtime_object_info_panel != null and is_instance_valid(ui.runtime_object_info_panel):
		ui.runtime_object_info_panel.queue_free()
	ui.runtime_object_info_panel = null
	ui.runtime_object_info_cell = Vector2i(-1, -1)
	if ui != null and ui.has_method("clear_runtime_selected_interaction_target"):
		ui.call("clear_runtime_selected_interaction_target")


static func clear(ui) -> void:
	hide(ui)


static func show(ui, cell: Vector2i) -> void:
	hide(ui)
	if ui.runtime_hud_root == null or not is_instance_valid(ui.runtime_hud_root):
		return
	if ui.field_runtime == null or not is_instance_valid(ui.field_runtime) or ui.bipob == null or not is_instance_valid(ui.bipob):
		return
	if ui.mission_manager_runtime == null or not is_instance_valid(ui.mission_manager_runtime):
		return
	build(ui, cell)


static func refresh(ui) -> void:
	refresh_position(ui)


static func refresh_position(ui) -> void:
	if ui == null:
		return
	if ui.runtime_object_info_panel == null or not is_instance_valid(ui.runtime_object_info_panel):
		return
	if ui.runtime_object_info_cell.x < 0 or ui.runtime_object_info_cell.y < 0:
		return
	position_panel(ui, ui.runtime_object_info_panel, ui.runtime_object_info_cell)


static func build(ui, cell: Vector2i) -> Control:
	var object_data: Dictionary = {}
	if ui.mission_manager_runtime.has_method("get_world_object_at_cell"):
		object_data = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("get_world_object_at_cell", cell))
	if object_data.is_empty() and ui.mission_manager_runtime.has_method("get_items_at_cell"):
		var items: Array = ui._safe_ui_array(ui.mission_manager_runtime.call("get_items_at_cell", cell))
		if not items.is_empty():
			object_data = ui._safe_ui_dictionary(items[0])
	if object_data.is_empty():
		return null
	if ui.has_method("_make_runtime_selected_interaction_target") and ui.has_method("set_runtime_selected_interaction_target"):
		var target: Dictionary = ui.call("_make_runtime_selected_interaction_target", object_data, "object_hud", cell)
		if not target.is_empty():
			ui.call("set_runtime_selected_interaction_target", target)
	var scan_level: int = int(object_data.get("scan_level", 0))
	var known_details: bool = scan_level >= 1 or bool(object_data.get("scanned", false)) or bool(object_data.get("visible", false))
	var lines: Array[String] = []
	var type_label: String = info_type_label(ui, object_data)
	var object_type: String = info_value(ui, object_data, ["object_type"], type_label.to_snake_case())
	lines.append("Object type: %s" % object_type)
	for class_field in ["object_class", "terminal_class", "power_source_class", "category"]:
		if object_data.has(class_field):
			lines.append("%s: %s" % [class_field.capitalize(), info_value(ui, object_data, [class_field])])
	if type_label == "Door":
		lines.append("Door type: %s" % door_type_label(ui, object_data))
		if object_data.has("door_class"):
			lines.append("Door class: %s" % info_value(ui, object_data, ["door_class"]))
		if object_data.has("required_manipulator_level"):
			lines.append("Required Manipulator Version: %s" % info_value(ui, object_data, ["required_manipulator_level"]))
		var interface_level: String = info_value(ui, object_data, ["required_interface_level_if_energy", "required_connector_level"])
		if not interface_level.is_empty() and int(interface_level) > 0:
			lines.append("Required Connector Version: %s" % interface_level)
	var material: String = info_value(ui, object_data, ["material", "wall_material", "floor_material"], "unknown")
	if known_details or material != "unknown":
		lines.append("Material: %s" % material)
	if known_details:
		var power_text: String = info_value(ui, object_data, ["power_mode", "power_type"], "internal")
		var power_source: String = info_value(ui, object_data, ["power_source_id", "power_network_id"])
		if power_text == "external" and not power_source.is_empty():
			power_text = "%s (%s)" % [power_text, power_source]
		lines.append("Power type: %s" % power_text)
		var control_text: String = info_value(ui, object_data, ["control_mode", "control_type"], "internal")
		var control_source: String = info_value(ui, object_data, ["control_terminal_id", "linked_terminal_id", "control_source_id"])
		if control_text == "external" and not control_source.is_empty():
			control_text = "%s (%s)" % [control_text, control_source]
		lines.append("Control type: %s" % control_text)
		if type_label == "Door":
			lines.append("Access type: %s" % access_type_label(info_value(ui, object_data, ["access_type", "lock_type"], "none")))
		elif type_label == "Terminal":
			lines.append("Device version: %s" % info_value(ui, object_data, ["device_version", "terminal_version", "version"], "v1"))
			lines.append("Connection type: %s" % info_value(ui, object_data, ["connection_type"], "wired"))
			var stored: Array[String] = []
			for field_name in ["stored_key_ids", "stored_access_ids", "stored_item_ids", "digital_key_ids", "access_code_ids"]:
				for value_variant in ui._safe_ui_array(object_data.get(field_name, [])):
					stored.append(str(value_variant))
			if not ui._safe_ui_string(object_data.get("stored_key_id", object_data.get("access_key_id", ""))).strip_edges().is_empty():
				stored.append(ui._safe_ui_string(object_data.get("stored_key_id", object_data.get("access_key_id", ""))))
			lines.append("Stored keys/access: %s" % (", ".join(stored) if not stored.is_empty() else "none"))
	elif lines.size() <= 2:
		lines.append("Details unknown. Scan or reveal this object for more information.")
	var panel := PanelContainer.new()
	panel.z_index = ui.Z_RUNTIME_HUD + 8
	panel.z_as_relative = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.modulate.a = 0.88
	panel.add_theme_stylebox_override("panel", ui._make_panel_style(ui.UI_COLOR_PANEL_DARK, ui.UI_COLOR_ACCENT, 1, 8))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.text = "\n".join(lines)
	label.custom_minimum_size = Vector2(320, 0)
	margin.add_child(label)
	panel.add_child(margin)
	ui.runtime_hud_root.add_child(panel)
	ui.runtime_object_info_panel = panel
	ui.runtime_object_info_cell = cell
	position_panel(ui, panel, cell)
	return panel
