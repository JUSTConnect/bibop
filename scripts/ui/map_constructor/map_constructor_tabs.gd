extends RefCounted
class_name MapConstructorTabs

static func add_tab_header(ui: Variant, parent: VBoxContainer, available_width: float) -> void:
	var tab_row: HBoxContainer = HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 4)
	tab_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(tab_row)
	var use_short_labels: bool = available_width <= 320.0
	for tab_data in [
		{"id":"map_settings", "label":"Map Settings", "short_label":"Settings", "tooltip":"Map Settings: geometry, markers, presets, templates, cleanup, patches, and overview tools."},
		{"id":"objects", "label":"Objects", "short_label":"Objects", "tooltip":"Objects: search and place prefab object cards, then inspect placed objects."},
		{"id":"warnings", "label":"Warnings", "short_label":"Warnings", "tooltip":"Warnings: mission readiness, validation issues, and recommended fixes."}
	]:
		var tab_id: String = String(tab_data.get("id", ""))
		var tab_button: Button = Button.new()
		tab_button.text = String(tab_data.get("short_label" if use_short_labels else "label", tab_id))
		tab_button.tooltip_text = String(tab_data.get("tooltip", tab_data.get("label", tab_id)))
		tab_button.clip_text = true
		tab_button.toggle_mode = true
		tab_button.button_pressed = tab_id == ui.map_constructor_active_tab
		tab_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if tab_button.button_pressed:
			tab_button.add_theme_stylebox_override("normal", ui._make_panel_style(ui.UI_COLOR_PANEL_DARK, ui.UI_COLOR_ACCENT, 2, 6))
			tab_button.add_theme_stylebox_override("pressed", ui._make_panel_style(ui.UI_COLOR_PANEL_DARK, ui.UI_COLOR_ACCENT, 2, 6))
			tab_button.add_theme_color_override("font_color", ui.UI_COLOR_ACCENT)
		else:
			tab_button.add_theme_stylebox_override("normal", ui._make_panel_style(ui.UI_COLOR_PANEL_DARK, ui.UI_COLOR_BORDER_DIM, 1, 6))
		tab_button.pressed.connect(func() -> void:
			ui._set_map_constructor_active_tab(tab_id)
		)
		tab_row.add_child(tab_button)

static func set_active_tab(ui: Variant, tab_name: String) -> void:
	if not ["map_settings", "objects", "warnings"].has(tab_name):
		return
	if tab_name == ui.map_constructor_active_tab:
		return
	remember_palette_scroll(ui)
	ui.map_constructor_active_tab = tab_name
	ui._refresh_map_constructor_panels()

static func remember_palette_scroll(ui: Variant) -> void:
	if ui.runtime_map_constructor_palette_panel == null or not is_instance_valid(ui.runtime_map_constructor_palette_panel):
		return
	var scroll: ScrollContainer = find_palette_scroll(ui.runtime_map_constructor_palette_panel)
	if scroll == null:
		return
	ui.map_constructor_tab_scroll_positions[ui.map_constructor_active_tab] = scroll.scroll_vertical

static func find_palette_scroll(root: Node) -> ScrollContainer:
	if root == null:
		return null
	if root is ScrollContainer:
		return root as ScrollContainer
	for child in root.get_children():
		var found: ScrollContainer = find_palette_scroll(child)
		if found != null:
			return found
	return null

static func restore_palette_scroll_deferred(ui: Variant, scroll: ScrollContainer, tab_name: String) -> void:
	ui.call_deferred("_restore_map_constructor_palette_scroll", scroll, tab_name)

static func restore_palette_scroll(ui: Variant, scroll: ScrollContainer, tab_name: String) -> void:
	if scroll == null or not is_instance_valid(scroll):
		return
	scroll.scroll_vertical = int(ui.map_constructor_tab_scroll_positions.get(tab_name, 0))
