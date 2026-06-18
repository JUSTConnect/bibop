extends RefCounted

# Target class: CommonSeparatorFactory
# Единая разделительная полоса между секциями.

static func make_section_separator() -> Control:
	var panel := PanelContainer.new()
	panel.name = "SectionSeparator"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = Vector2(0, 8)
	return panel
