extends RefCounted

# ObjectInspectorBuilder
# Builds inspector from ObjectInspectorViewModel. No post-process patch layers.

const CommonPropertyRowBuilderRef = preload("res://scripts/ui/common/common_property_row_builder.gd")

const SECTION_BG := Color(0.12, 0.14, 0.18, 1.0)
const BORDER := Color(0.25, 0.5, 0.62, 0.85)
const ACCENT := Color(0.25, 0.78, 0.95, 1.0)

static func fill_content(content: VBoxContainer, view_model: Dictionary, on_apply: Callable = Callable()) -> void:
	if content == null or not is_instance_valid(content):
		return
	for child in content.get_children():
		child.queue_free()
	var sections: Array = Array(view_model.get("sections", []))
	if sections.is_empty():
		content.add_child(_build_empty_section())
		return
	for index in range(sections.size()):
		if index > 0:
			content.add_child(_make_section_separator())
		content.add_child(_build_section(Dictionary(sections[index]), on_apply))


static func build(view_model: Dictionary, on_apply: Callable = Callable()) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "ObjectInspectorPanel"
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(stack)
	fill_content(stack, view_model, on_apply)
	return panel


static func _build_section(section_view_model: Dictionary, on_apply: Callable) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style(SECTION_BG, BORDER, 1, 6))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(_wrap_margin(content, 10, 8))

	var header := Label.new()
	header.text = str(section_view_model.get("title", "Section"))
	header.add_theme_color_override("font_color", ACCENT)
	header.add_theme_font_size_override("font_size", 18)
	content.add_child(header)

	var rows: Array = Array(section_view_model.get("rows", []))
	if rows.is_empty():
		content.add_child(CommonPropertyRowBuilderRef.build_row({
			"id": "empty_info",
			"label": "Info",
			"control_type": "readonly_text",
			"value": "No data.",
			"readonly": true,
		}, on_apply))
		return panel

	for row_variant in rows:
		content.add_child(CommonPropertyRowBuilderRef.build_row(Dictionary(row_variant), on_apply))
	return panel


static func _build_empty_section() -> PanelContainer:
	return _build_section({
		"id": "empty_inspector",
		"title": "Inspector",
		"rows": [{
			"id": "empty_info",
			"label": "Info",
			"control_type": "readonly_text",
			"value": "No inspector data.",
			"readonly": true,
		}],
	}, Callable())


static func _make_section_separator() -> PanelContainer:
	var separator := PanelContainer.new()
	separator.custom_minimum_size = Vector2(0, 8)
	separator.add_theme_stylebox_override("panel", _make_panel_style(BORDER, BORDER, 0, 0))
	return separator


static func _wrap_margin(child: Control, horizontal: int, vertical: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", horizontal)
	margin.add_theme_constant_override("margin_right", horizontal)
	margin.add_theme_constant_override("margin_top", vertical)
	margin.add_theme_constant_override("margin_bottom", vertical)
	margin.add_child(child)
	return margin


static func _make_panel_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style
