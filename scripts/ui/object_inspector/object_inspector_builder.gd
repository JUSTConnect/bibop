extends RefCounted

# Target class: ObjectInspectorBuilder
# Builds inspector from ObjectInspectorViewModel. No post-process patch layers.

const CommonSectionBuilderRef = preload("res://scripts/ui/common/common_section_builder.gd")
const CommonSeparatorFactoryRef = preload("res://scripts/ui/common/common_separator_factory.gd")

static func build(view_model: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "ObjectInspectorPanel"
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	panel.add_child(stack)
	var sections: Array = Array(view_model.get("sections", []))
	for index in range(sections.size()):
		if index > 0:
			stack.add_child(CommonSeparatorFactoryRef.make_section_separator())
		stack.add_child(CommonSectionBuilderRef.build_section(Dictionary(sections[index])))
	return panel
