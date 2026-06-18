extends RefCounted

# Target class: ValidationSectionBuilder
# Builds Validation section from ValidationReport.

const CommonSectionBuilderRef = preload("res://scripts/ui/common/common_section_builder.gd")
const CommonPropertyRowBuilderRef = preload("res://scripts/ui/common/common_property_row_builder.gd")

static func build(section_definition: Dictionary) -> VBoxContainer:
	var section := CommonSectionBuilderRef.build_section(section_definition)
	for row in Array(section_definition.get("rows", [])):
		section.add_child(CommonPropertyRowBuilderRef.build_row(Dictionary(row)))
	return section
