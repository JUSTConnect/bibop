extends RefCounted

# Target class: CommonPanelBuilder
# Builds a generic panel from CommonPanelDefinition.

static func build_panel(definition: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = str(definition.get("id", "CommonPanel"))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	margin.add_child(stack)
	var title := Label.new()
	title.text = str(definition.get("title", ""))
	stack.add_child(title)
	return panel
