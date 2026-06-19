extends RefCounted

const MapCanvasViewRef = preload("res://scripts/ui/map_constructor_new/map_canvas_view.gd")

const UI_BG := Color(0.055, 0.065, 0.085, 1.0)
const PANEL_BG := Color(0.09, 0.105, 0.135, 1.0)
const BORDER := Color(0.25, 0.5, 0.62, 0.85)
const ACCENT := Color(0.25, 0.78, 0.95, 1.0)
const OUTER_MARGIN := 12
const BODY_GAP := 10
const PANEL_PADDING := 10
const PALETTE_RATIO := 0.22
const MAP_RATIO := 0.50
const INSPECTOR_RATIO := 0.28

static func build(root: Control, callbacks: Dictionary) -> Dictionary:
	var refs: Dictionary = {}
	var background := ColorRect.new()
	background.color = UI_BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, OUTER_MARGIN)
	margin.clip_contents = true
	root.add_child(margin)

	var main_stack := VBoxContainer.new()
	main_stack.add_theme_constant_override("separation", 10)
	main_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_stack.clip_contents = true
	margin.add_child(main_stack)
	main_stack.add_child(_build_header(callbacks))

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", BODY_GAP)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.clip_contents = true
	main_stack.add_child(body)

	var palette_refs: Dictionary = _build_palette_panel()
	var left_panel: PanelContainer = palette_refs["panel"]
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_stretch_ratio = PALETTE_RATIO
	body.add_child(left_panel)
	refs.merge(palette_refs, true)

	var map_refs: Dictionary = _build_map_panel(callbacks)
	var center_panel: PanelContainer = map_refs["panel"]
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_panel.size_flags_stretch_ratio = MAP_RATIO
	body.add_child(center_panel)
	refs.merge(map_refs, true)

	var inspector_refs: Dictionary = _build_inspector_panel()
	var right_panel: PanelContainer = inspector_refs["panel"]
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_stretch_ratio = INSPECTOR_RATIO
	body.add_child(right_panel)
	refs.merge(inspector_refs, true)

	var status_label := Label.new()
	status_label.text = "Select object in palette, then click a map cell."
	status_label.add_theme_color_override("font_color", ACCENT)
	status_label.clip_text = true
	status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	main_stack.add_child(status_label)
	refs["status_label"] = status_label
	return refs

static func _build_header(callbacks: Dictionary) -> Control:
	var panel: PanelContainer = _make_panel_container()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.clip_contents = true
	panel.add_child(_wrap_margin(row, 12, 8))
	var title := Label.new()
	title.text = "NewBIP / Greenfield Editor"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(title)
	row.add_child(_make_button("Reload", 82, callbacks.get("reload", Callable())))
	row.add_child(_make_button("Test Room", 96, callbacks.get("test_room", Callable())))
	return panel

static func _build_palette_panel() -> Dictionary:
	var panel: PanelContainer = _make_panel_container()
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.clip_contents = true
	panel.add_child(_wrap_margin(stack, PANEL_PADDING, PANEL_PADDING))
	var title := Label.new()
	title.text = "Object Palette"
	title.add_theme_color_override("font_color", ACCENT)
	stack.add_child(title)
	var selected_label := Label.new()
	selected_label.text = "Selected: none"
	selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selected_label.clip_text = true
	stack.add_child(selected_label)
	var object_list := VBoxContainer.new()
	object_list.add_theme_constant_override("separation", 6)
	object_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	object_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	object_list.clip_contents = true
	stack.add_child(object_list)
	return {"panel": panel, "selected_palette_label": selected_label, "object_list": object_list}

static func _build_map_panel(callbacks: Dictionary) -> Dictionary:
	var panel: PanelContainer = _make_panel_container()
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.clip_contents = true
	panel.add_child(_wrap_margin(stack, PANEL_PADDING, PANEL_PADDING))

	var title := Label.new()
	title.text = "Map Canvas"
	title.add_theme_color_override("font_color", ACCENT)
	stack.add_child(title)

	var editor_toolbar := HBoxContainer.new()
	editor_toolbar.add_theme_constant_override("separation", 5)
	editor_toolbar.clip_contents = true
	editor_toolbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_child(editor_toolbar)
	var tool_label := Label.new()
	tool_label.custom_minimum_size = Vector2(76, 0)
	tool_label.clip_text = true
	editor_toolbar.add_child(tool_label)
	for spec: Array in [
		["Place", "place"], ["Erase", "erase"], ["Use", "use"],
		["Undo", "undo"], ["Redo", "redo"], ["Clear", "clear"]
	]:
		editor_toolbar.add_child(_make_button(str(spec[0]), 52, callbacks.get(str(spec[1]), Callable())))

	var runtime_toolbar := HBoxContainer.new()
	runtime_toolbar.add_theme_constant_override("separation", 5)
	runtime_toolbar.clip_contents = true
	runtime_toolbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_child(runtime_toolbar)
	var mode_label := Label.new()
	mode_label.custom_minimum_size = Vector2(76, 0)
	mode_label.clip_text = true
	runtime_toolbar.add_child(mode_label)
	for spec: Array in [
		["Edit", "edit_mode"], ["Play", "play_mode"], ["Reset", "reset_play"],
		["Agent", "agent_step"], ["Save", "save"], ["Load", "load"]
	]:
		runtime_toolbar.add_child(_make_button(str(spec[0]), 56, callbacks.get(str(spec[1]), Callable())))

	var map_canvas: Control = MapCanvasViewRef.new()
	map_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_canvas.custom_minimum_size = Vector2.ZERO
	var cell_callback: Callable = callbacks.get("cell_pressed", Callable())
	if cell_callback.is_valid():
		map_canvas.connect("cell_pressed", cell_callback)
	stack.add_child(map_canvas)
	return {
		"panel": panel,
		"tool_mode_label": tool_label,
		"app_mode_label": mode_label,
		"map_canvas": map_canvas,
		"editor_toolbar": editor_toolbar,
		"runtime_toolbar": runtime_toolbar,
	}

static func _build_inspector_panel() -> Dictionary:
	var panel: PanelContainer = _make_panel_container()
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.clip_contents = true
	panel.add_child(_wrap_margin(scroll, PANEL_PADDING, PANEL_PADDING))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	content.clip_contents = true
	scroll.add_child(content)
	return {"panel": panel, "inspector_content": content}

static func _make_button(text: String, width: int, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(width, 0)
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if callback.is_valid():
		button.pressed.connect(callback)
	return button

static func _make_panel_container() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", _make_panel_style(PANEL_BG, BORDER, 1, 8))
	return panel

static func _wrap_margin(child: Control, horizontal: int, vertical: int) -> MarginContainer:
	var margin := MarginContainer.new()
	for side: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_%s" % side, horizontal)
	for side: String in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, vertical)
	margin.add_child(child)
	return margin

static func _make_panel_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style
