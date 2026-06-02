extends RefCounted
class_name MapConstructorPanel

static func build_panel(ui: Variant) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	ui.runtime_map_constructor_palette_panel = panel
	panel.z_index = ui.Z_MAP_CONSTRUCTOR_UI
	panel.z_as_relative = false
	panel.clip_contents = true
	var palette_rect: Rect2 = ui._get_map_constructor_palette_rect()
	panel.position = palette_rect.position
	panel.size = palette_rect.size
	panel.add_theme_stylebox_override("panel", ui._make_panel_style(ui.UI_COLOR_PANEL, ui.UI_COLOR_BORDER, 1, 8))
	var palette_stack: VBoxContainer = VBoxContainer.new()
	palette_stack.clip_contents = true
	palette_stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	palette_stack.add_theme_constant_override("separation", 6)
	panel.add_child(palette_stack)
	MapConstructorTabs.add_tab_header(ui, palette_stack, palette_rect.size.x)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.clip_contents = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	palette_stack.add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.clip_contents = true
	list.add_theme_constant_override("separation", 6)
	list.custom_minimum_size = Vector2(0.0, 0.0)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll.add_child(list)
	build_active_tab_content(ui, list)
	MapConstructorTabs.restore_palette_scroll_deferred(ui, scroll, ui.map_constructor_active_tab)
	return panel

static func build_active_tab_content(ui: Variant, list: VBoxContainer) -> void:
	match ui.map_constructor_active_tab:
		"objects":
			ui._build_map_constructor_object_palette(list)
		"warnings":
			build_warnings_tab(ui, list)
		"map_settings":
			build_map_settings_tab(ui, list)

static func build_warnings_tab(ui: Variant, list: VBoxContainer) -> void:
	ui._build_map_constructor_warnings_tab(list)

static func build_map_settings_tab(ui: Variant, list: VBoxContainer) -> void:
	ui._build_map_constructor_map_settings_tab(list)

static func mount_panel(ui: Variant, panel: PanelContainer) -> void:
	ui._ensure_map_constructor_validation_overlay()
	ui.runtime_hud_root.add_child(panel)
	ui.runtime_hud_root.move_child(panel, ui.runtime_hud_root.get_child_count() - 1)

static func clear_existing_panel(ui: Variant) -> void:
	if ui.runtime_map_constructor_palette_panel != null and is_instance_valid(ui.runtime_map_constructor_palette_panel):
		ui.runtime_map_constructor_palette_panel.queue_free()
