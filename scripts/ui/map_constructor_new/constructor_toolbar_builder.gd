extends RefCounted

# Target class: ConstructorToolbarBuilder
# Builds constructor tools from ConstructorToolDefinition list.

const CommonButtonFactoryRef = preload("res://scripts/ui/common/common_button_factory.gd")

static func build_toolbar(tool_definitions: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "ConstructorToolbar"
	row.add_theme_constant_override("separation", 6)
	for definition in tool_definitions:
		row.add_child(CommonButtonFactoryRef.make_button(Dictionary(definition)))
	return row
