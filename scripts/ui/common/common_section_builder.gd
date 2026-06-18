extends RefCounted

# Target class: CommonSectionBuilder
# Builds reusable section blocks for all menus.

static func build_section(definition: Dictionary) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.name = str(definition.get("id", "CommonSection"))
	section.add_theme_constant_override("separation", 4)
	var header := Label.new()
	header.text = str(definition.get("title", ""))
	section.add_child(header)
	return section
