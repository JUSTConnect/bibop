extends RefCounted
class_name MapConstructorInspector

static func show_for_selection(ui: Variant, cell: Vector2i, preferred_entity_kind: String = "", preferred_entity_id: String = "") -> void:
	var previous_entity_kind: String = ui.selected_map_constructor_entity_kind
	var previous_entity_id: String = ui.selected_map_constructor_entity_id
	var preserve_scroll_value: int = 0
	if ui.runtime_map_constructor_inspector_scroll != null and is_instance_valid(ui.runtime_map_constructor_inspector_scroll):
		preserve_scroll_value = ui.runtime_map_constructor_inspector_scroll.scroll_vertical
	if ui.runtime_map_constructor_inspector_panel != null and is_instance_valid(ui.runtime_map_constructor_inspector_panel):
		ui.runtime_map_constructor_inspector_panel.queue_free()
	ui.runtime_map_constructor_inspector_panel = null
	ui.runtime_map_constructor_inspector_scroll = null
	if not ui.map_constructor_mode_active:
		ui._set_runtime_bottom_hud_visible(true)
		return
	ui._set_runtime_bottom_hud_visible(false)
	ui._ensure_runtime_hud_root()
	if ui.mission_manager_runtime == null:
		return
	var entity_info: Dictionary = {}
	if not preferred_entity_id.is_empty() and ui.mission_manager_runtime.has_method("get_map_constructor_entity_by_id"):
		entity_info = ui.mission_manager_runtime.call("get_map_constructor_entity_by_id", preferred_entity_kind, preferred_entity_id)
	if entity_info.is_empty() and ui.mission_manager_runtime.has_method("get_map_constructor_editable_entity_at_cell"):
		entity_info = ui.mission_manager_runtime.call("get_map_constructor_editable_entity_at_cell", cell)
	if not bool(entity_info.get("ok", false)):
		ui.selected_map_constructor_entity_kind = ""
		ui.selected_map_constructor_entity_id = ""
		ui.selected_map_constructor_entity_cell = Vector2i(-1, -1)
		ui._clear_map_constructor_wall_mounted_selection()
		ui._clear_map_constructor_link_target()
		return
	var entity_kind: String = ui._safe_ui_string(entity_info.get("entity_kind", "world_object"), "world_object")
	var entity_id: String = ui._safe_ui_string(entity_info.get("id", ""))
	var data: Dictionary = {}
	var data_variant: Variant = entity_info.get("data", {})
	if data_variant is Dictionary:
		data = data_variant.duplicate(true)
	ui.selected_map_constructor_entity_kind = entity_kind
	ui.selected_map_constructor_entity_id = entity_id
	ui.selected_map_constructor_entity_cell = ui._safe_ui_vector2i(entity_info.get("cell", cell))
	var type_group: String = ui._safe_ui_string(ui.mission_manager_runtime.call("get_map_constructor_entity_type_group", entity_kind, entity_id), "generic") if ui.mission_manager_runtime.has_method("get_map_constructor_entity_type_group") else "generic"
	var preserve_scroll_after_rebuild: bool = previous_entity_kind == entity_kind and previous_entity_id == entity_id
	var panel := PanelContainer.new()
	var inspector_rect: Rect2 = ui._get_map_constructor_bottom_inspector_rect()
	panel.position = inspector_rect.position
	panel.size = inspector_rect.size
	panel.custom_minimum_size = inspector_rect.size
	panel.z_index = ui.Z_MAP_CONSTRUCTOR_UI
	panel.z_as_relative = false
	panel.add_theme_stylebox_override("panel", ui._make_panel_style(ui.UI_COLOR_PANEL_DARK, ui.UI_COLOR_BORDER, 1, 8))
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var inspector_stack := VBoxContainer.new()
	inspector_stack.add_theme_constant_override("separation", 6)
	inspector_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(inspector_stack)
	var header_row := HBoxContainer.new()
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var header_label := Label.new()
	header_label.text = "Selected %s: %s" % [entity_kind, ui._safe_ui_string(data.get("display_name", entity_id), entity_id)]
	header_label.clip_text = true
	header_label.add_theme_color_override("font_color", ui.UI_COLOR_ACCENT)
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(header_label)
	var expand_button := Button.new()
	expand_button.text = "▲" if ui.map_constructor_inspector_expanded else "▼"
	expand_button.tooltip_text = "Collapse inspector" if ui.map_constructor_inspector_expanded else "Expand inspector"
	expand_button.pressed.connect(ui._toggle_map_constructor_inspector_expanded)
	header_row.add_child(expand_button)
	inspector_stack.add_child(header_row)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ui.runtime_map_constructor_inspector_scroll = scroll
	inspector_stack.add_child(scroll)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	v.custom_minimum_size = Vector2(maxf(inspector_rect.size.x - 36.0, 1.0), 0.0)
	scroll.add_child(v)
	var identity: VBoxContainer = ui._create_inspector_section("1. Object Identity")
	var id_label: Label = Label.new(); id_label.text = entity_id; identity.add_child(ui._create_property_row("ID", id_label))
	ui._add_text_property(identity, "Name", entity_kind, entity_id, "display_name", data.get("display_name", ""))
	ui._add_map_constructor_description_editor(identity, data, entity_kind, entity_id)
	var type_label: Label = Label.new(); type_label.text = ui._safe_ui_string(data.get("object_type", data.get("item_type", "item")), "item"); identity.add_child(ui._create_property_row("Object type", type_label))
	var class_tokens: Array[String] = []
	for class_field in ["object_class", "door_class", "terminal_class", "power_source_class", "category", "subcategory"]:
		if data.has(class_field) and not ui._safe_ui_string(data.get(class_field, "")).strip_edges().is_empty():
			class_tokens.append("%s=%s" % [class_field, ui._safe_ui_string(data.get(class_field, ""))])
	var class_text: String = type_group
	if not class_tokens.is_empty():
		class_text = ""
		for class_index in range(class_tokens.size()):
			if class_index > 0:
				class_text += ", "
			class_text += class_tokens[class_index]
	var class_label: Label = Label.new(); class_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; class_label.text = class_text
	identity.add_child(ui._create_property_row("Object class", class_label))
	v.add_child(identity)
	var current_status: VBoxContainer = ui._create_inspector_section("2. Current Status")
	var state_label: Label = Label.new(); state_label.text = ui._safe_ui_string(data.get("state", "(none)"), "(none)"); current_status.add_child(ui._create_property_row("state", state_label))
	for status_field in ["is_open", "is_closed", "is_locked", "is_powered", "damaged", "broken", "blocks_movement"]:
		if data.has(status_field):
			var status_value_label: Label = Label.new()
			status_value_label.text = ui._safe_ui_string(data.get(status_field, ""))
			current_status.add_child(ui._create_property_row(status_field, status_value_label))
	if entity_kind == "world_object" and type_group == "door" and ui.mission_manager_runtime.has_method("get_map_constructor_door_visual_state"):
		var door_visual: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("get_map_constructor_door_visual_state", entity_id))
		var door_visual_label: Label = Label.new(); door_visual_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		door_visual_label.text = "visual=%s, badges=%s, note=%s" % [ui._safe_ui_string(door_visual.get("state", "unknown"), "unknown"), ui._safe_ui_string(door_visual.get("badges", [])), ui._safe_ui_string(door_visual.get("message", ""))]
		current_status.add_child(ui._create_property_row("Door visual", door_visual_label))
	if entity_kind == "world_object" and type_group == "terminal" and ui.mission_manager_runtime.has_method("get_map_constructor_terminal_visual_state"):
		var terminal_visual: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("get_map_constructor_terminal_visual_state", entity_id))
		var terminal_visual_label: Label = Label.new(); terminal_visual_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		terminal_visual_label.text = "type=%s, state=%s, badges=%s" % [ui._safe_ui_string(terminal_visual.get("terminal_type", "unknown"), "unknown"), ui._safe_ui_string(terminal_visual.get("state", "unknown"), "unknown"), ui._safe_ui_string(terminal_visual.get("badges", []))]
		current_status.add_child(ui._create_property_row("Terminal visual", terminal_visual_label))
	v.add_child(current_status)
	var placement: VBoxContainer = ui._create_inspector_section("3. Placement")
	var cell_l:=Label.new(); cell_l.text = ui._safe_ui_string(entity_info.get("cell", cell), str(cell)); placement.add_child(ui._create_property_row("Cell", cell_l))
	var pm_l:=Label.new(); pm_l.text = ui._safe_ui_string(data.get("placement_mode", "floor"), "floor"); placement.add_child(ui._create_property_row("Mode", pm_l))
	var move_row: HBoxContainer = HBoxContainer.new()
	var move_x: SpinBox = SpinBox.new(); move_x.step = 1; move_x.min_value = -999; move_x.max_value = 999; move_x.value = float(ui.selected_map_constructor_entity_cell.x)
	var move_y: SpinBox = SpinBox.new(); move_y.step = 1; move_y.min_value = -999; move_y.max_value = 999; move_y.value = float(ui.selected_map_constructor_entity_cell.y)
	var move_button: Button = Button.new(); move_button.text = "Move"
	move_button.pressed.connect(func() -> void:
		var target_cell: Vector2i = Vector2i(int(move_x.value), int(move_y.value))
		MapConstructorActions.move_entity_to_cell(ui, entity_kind, entity_id, target_cell)
	)
	move_row.add_child(move_x); move_row.add_child(move_y); move_row.add_child(move_button)
	placement.add_child(move_row)
	var dup_button: Button = Button.new(); dup_button.text = "Duplicate to X/Y"
	dup_button.pressed.connect(func() -> void:
		var duplicate_cell: Vector2i = Vector2i(int(move_x.value), int(move_y.value))
		MapConstructorActions.duplicate_entity_to_cell(ui, entity_kind, entity_id, duplicate_cell)
	)
	placement.add_child(dup_button)
	var del: Button = Button.new(); del.text = "Delete"
	del.pressed.connect(func() -> void:
		MapConstructorActions.delete_entity_at_cell(ui, ui._safe_ui_vector2i(entity_info.get("cell", cell)))
	)
	placement.add_child(del)
	v.add_child(placement)
	var configurable: VBoxContainer = ui._create_inspector_section("4. Configurable Parameters")
	var object_is_configurable: bool = bool(data.get("configurable", true))
	var object_archetype_id: String = ui._safe_ui_string(data.get("archetype_id", "")).strip_edges()
	if object_is_configurable and object_archetype_id.is_empty():
		ui._add_preset_buttons(configurable, entity_kind, entity_id)
	var rendered_archetype_schema: bool = ui._add_archetype_schema_properties(configurable, entity_kind, entity_id, data) if object_is_configurable else false
	if object_is_configurable and not rendered_archetype_schema:
		ui._add_map_constructor_active_settings(configurable, entity_kind, entity_id, data, type_group)
	if type_group == "control" or data.has("requires_external_control"):
		ui._add_bool_property(configurable, "requires_external_control", entity_kind, entity_id, "requires_external_control", data.get("requires_external_control", false))
	var inspector_object_type: String = ui._safe_ui_string(data.get("object_type", "")).to_lower()
	var uses_dedicated_power_state_selector: bool = type_group == "power" and (inspector_object_type.begins_with("power_source") or inspector_object_type in ["power_cable", "power_cable_reel"])
	if object_is_configurable and data.has("state") and not (type_group == "door" or uses_dedicated_power_state_selector):
		ui._add_text_property(configurable, "Editable state override", entity_kind, entity_id, "state", data.get("state", ""))
	if type_group == "terminal":
		ui._add_bool_property(configurable, "damaged", entity_kind, entity_id, "damaged", data.get("damaged", false))
		ui._add_bool_property(configurable, "encrypted", entity_kind, entity_id, "encrypted", data.get("encrypted", false))
	if type_group == "power":
		var power_object_type: String = ui._safe_ui_string(data.get("object_type", "")).to_lower()
		if power_object_type.begins_with("power_source"):
			var source_state_options: Array[Dictionary] = [{"label":"On", "value":"on"}, {"label":"Off", "value":"off"}, {"label":"Damaged", "value":"damaged"}, {"label":"Broken", "value":"broken"}]
			ui._add_enum_property(configurable, "Source state", entity_kind, entity_id, "state", data.get("state", "on"), source_state_options)
			var source_class_options: Array[Dictionary] = [{"label":"Class 1 (4 outlets)", "value":"1"}, {"label":"Class 2 (5 outlets)", "value":"2"}, {"label":"Class 3 (6 outlets)", "value":"3"}]
			ui._add_enum_property(configurable, "Source class", entity_kind, entity_id, "power_source_class", data.get("power_source_class", 1), source_class_options)
		elif power_object_type == "power_cable" or power_object_type == "power_cable_reel":
			var wire_state_options: Array[Dictionary] = [{"label":"Powered", "value":"ok"}, {"label":"Cut", "value":"cut"}, {"label":"Damaged", "value":"damaged"}, {"label":"Broken", "value":"broken"}]
			ui._add_enum_property(configurable, "Wire state", entity_kind, entity_id, "state", data.get("state", "ok"), wire_state_options)
			ui._add_bool_property(configurable, "Hidden installation", entity_kind, entity_id, "is_hidden", data.get("is_hidden", false))
			var route_surface_options: Array[Dictionary] = [{"label":"Floor", "value":"floor"}, {"label":"Wall", "value":"wall"}]
			ui._add_enum_property(configurable, "Route surface", entity_kind, entity_id, "route_surface", data.get("route_surface", "floor"), route_surface_options)
		elif power_object_type == "light":
			ui._add_text_property(configurable, "Brightness", entity_kind, entity_id, "brightness", data.get("brightness", "1.0"))
			ui._add_text_property(configurable, "Color", entity_kind, entity_id, "color", data.get("color", "#ffffff"))
		ui._add_bool_property(configurable, "is_powered", entity_kind, entity_id, "is_powered", data.get("is_powered", false))
		ui._add_bool_property(configurable, "damaged", entity_kind, entity_id, "damaged", data.get("damaged", false))
		ui._add_bool_property(configurable, "broken", entity_kind, entity_id, "broken", data.get("broken", false))
	if type_group == "item":
		var item_type_label: Label = Label.new()
		item_type_label.text = ui._safe_ui_string(data.get("item_type", data.get("object_type", "item")), "item")
		configurable.add_child(ui._create_property_row("Item type", item_type_label))
		if data.has("digital_payload_type") or ui._safe_ui_string(data.get("item_type", "")).findn("digital") >= 0 or ui._safe_ui_string(data.get("item_type", "")).findn("access_code") >= 0:
			ui._add_text_property(configurable, "digital_payload_type", entity_kind, entity_id, "digital_payload_type", data.get("digital_payload_type", ""))
	if configurable.get_child_count() <= 1:
		var no_config_label: Label = Label.new()
		no_config_label.text = "No configurable object-specific parameters."
		configurable.add_child(no_config_label)
	v.add_child(configurable)
	var link_section: VBoxContainer = ui._create_inspector_section("5. Links")
	ui._add_map_constructor_object_link_sections(link_section, entity_kind, entity_id, data, type_group)
	var validation_result: Dictionary = {}
	if ui.mission_manager_runtime != null and ui.mission_manager_runtime.has_method("validate_map_constructor_entity_links"):
		validation_result = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("validate_map_constructor_entity_links", entity_kind, entity_id))
		MapConstructorValidationView.add_linked_targets(ui, link_section, validation_result)
	v.add_child(link_section)
	var warning_section: VBoxContainer = ui._create_inspector_section("6. Warnings")
	MapConstructorValidationView.add_warning_entries(ui, warning_section, validation_result)
	v.add_child(warning_section)
	MapConstructorFloorWallControls.add_coverage_sections(ui, v, entity_info, cell, data, entity_kind, entity_id, type_group)
	ui.runtime_map_constructor_inspector_panel = panel
	if preserve_scroll_after_rebuild:
		ui._restore_map_constructor_inspector_scroll_deferred(scroll, preserve_scroll_value)
	ui.runtime_hud_root.add_child(panel)
	ui.runtime_hud_root.move_child(panel, ui.runtime_hud_root.get_child_count() - 1)
	ui._sync_map_constructor_overlay_visuals()
	if ui.field_runtime != null and ui.field_runtime.has_method("request_visual_refresh"):
		ui.field_runtime.call("request_visual_refresh")
