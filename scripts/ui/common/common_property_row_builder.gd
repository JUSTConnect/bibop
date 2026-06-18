extends RefCounted

# Target class: CommonPropertyRowBuilder
# Единый builder для всех property rows. Apply button всегда справа от поля.

static func build_row(row_definition: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = str(row_definition.get("id", "PropertyRow"))
	row.add_theme_constant_override("separation", 6)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = str(row_definition.get("label", ""))
	label.custom_minimum_size = Vector2(140, 0)
	row.add_child(label)
	var control := build_control(row_definition)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	if str(row_definition.get("apply_mode", "")) == "inline":
		var apply_button := Button.new()
		apply_button.text = "Apply"
		row.add_child(apply_button)
	return row

static func build_control(row_definition: Dictionary) -> Control:
	var control_type := str(row_definition.get("control_type", "readonly_text"))
	match control_type:
		"line_edit":
			var edit := LineEdit.new(); edit.text = str(row_definition.get("value", "")); return edit
		"text_edit":
			var text := TextEdit.new(); text.text = str(row_definition.get("value", "")); text.custom_minimum_size = Vector2(0, 72); return text
		"checkbox":
			var check := CheckBox.new(); check.button_pressed = bool(row_definition.get("value", false)); return check
		"dropdown", "enum":
			return OptionButton.new()
		"number_spin", "int":
			return SpinBox.new()
		_:
			var label := Label.new(); label.text = str(row_definition.get("value", "")); return label
