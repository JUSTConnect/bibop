extends RefCounted

# Target class: RuntimeControlsBuilder
# Builds runtime action buttons from definitions.

const CommonButtonFactoryRef = preload("res://scripts/ui/common/common_button_factory.gd")

static func build_controls(control_definitions: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "RuntimeControlsPanel"
	row.add_theme_constant_override("separation", 6)
	for definition in control_definitions:
		row.add_child(CommonButtonFactoryRef.make_button(Dictionary(definition)))
	return row
