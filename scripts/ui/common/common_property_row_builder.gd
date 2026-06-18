extends RefCounted

# CommonPropertyRowBuilder
# Единый builder для всех property rows.
# Он создаёт control, но не меняет данные сам. Все изменения уходят наружу через on_apply.
# Важно: row не должен расширять основной panel. Текст и controls ужимаются внутри доступной ширины.

const OK_COLOR := Color(0.25, 0.85, 0.48, 1.0)
const WARNING_COLOR := Color(0.95, 0.7, 0.18, 1.0)
const LABEL_WIDTH := 118.0
const APPLY_WIDTH := 58.0
const ROW_SEPARATION := 6

static func build_row(row_definition: Dictionary, on_apply: Callable = Callable()) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = str(row_definition.get("id", "PropertyRow"))
	row.add_theme_constant_override("separation", ROW_SEPARATION)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.clip_contents = true

	var label := Label.new()
	label.text = str(row_definition.get("label", ""))
	label.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(label)

	var control := _build_control(row_definition, on_apply)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)

	if str(row_definition.get("apply_mode", "")) == "inline" and not bool(row_definition.get("readonly", false)):
		var apply_button := Button.new()
		apply_button.text = "Apply"
		apply_button.custom_minimum_size = Vector2(APPLY_WIDTH, 28)
		apply_button.clip_text = true
		apply_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		apply_button.pressed.connect(func() -> void:
			_emit_apply(on_apply, row_definition, _read_control_value(control))
		)
		row.add_child(apply_button)
	return row


static func _build_control(row_definition: Dictionary, on_apply: Callable) -> Control:
	if bool(row_definition.get("readonly", false)):
		return _make_readonly_label(str(row_definition.get("value", "")))

	var control_type := str(row_definition.get("control_type", "readonly_text"))
	match control_type:
		"line_edit":
			var edit := LineEdit.new()
			edit.text = str(row_definition.get("value", ""))
			edit.custom_minimum_size = Vector2(0, 0)
			return edit
		"text_edit":
			var text := TextEdit.new()
			text.text = str(row_definition.get("value", ""))
			text.custom_minimum_size = Vector2(0, 68)
			return text
		"checkbox":
			var check := CheckBox.new()
			check.button_pressed = bool(row_definition.get("value", false))
			check.toggled.connect(func(enabled: bool) -> void:
				_emit_apply(on_apply, row_definition, enabled)
			)
			return check
		"dropdown", "enum":
			var option := OptionButton.new()
			option.custom_minimum_size = Vector2(0, 0)
			var options: Array = Array(row_definition.get("options", []))
			var value_text := str(row_definition.get("value", ""))
			var selected_index := 0
			for index in range(options.size()):
				var option_value := str(options[index])
				option.add_item(option_value)
				option.set_item_metadata(index, option_value)
				if option_value == value_text:
					selected_index = index
			if options.size() > 0:
				option.select(selected_index)
			option.item_selected.connect(func(index: int) -> void:
				_emit_apply(on_apply, row_definition, option.get_item_metadata(index))
			)
			return option
		"number_spin", "int":
			var spin := SpinBox.new()
			spin.custom_minimum_size = Vector2(0, 0)
			spin.step = 1
			spin.min_value = _to_float(row_definition.get("min", 0), 0.0)
			spin.max_value = _to_float(row_definition.get("max", 999), 999.0)
			spin.value = _to_float(row_definition.get("value", spin.min_value), spin.min_value)
			return spin
		_:
			return _make_readonly_label(str(row_definition.get("value", "")))


static func _make_readonly_label(value_text: String) -> Label:
	var label := Label.new()
	label.text = value_text
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if value_text == "Ready" or value_text == "powered":
		label.add_theme_color_override("font_color", OK_COLOR)
	elif value_text == "Not ready" or value_text == "unpowered":
		label.add_theme_color_override("font_color", WARNING_COLOR)
	return label


static func _read_control_value(control: Control) -> Variant:
	if control is LineEdit:
		return (control as LineEdit).text
	if control is TextEdit:
		return (control as TextEdit).text
	if control is SpinBox:
		return int((control as SpinBox).value)
	if control is CheckBox:
		return (control as CheckBox).button_pressed
	if control is OptionButton:
		var option := control as OptionButton
		return option.get_item_metadata(option.selected) if option.selected >= 0 else ""
	return null


static func _emit_apply(on_apply: Callable, row_definition: Dictionary, value: Variant) -> void:
	if on_apply.is_valid():
		on_apply.call(row_definition, value)


static func _to_float(value: Variant, fallback: float) -> float:
	if value is float or value is int:
		return float(value)
	var text := str(value)
	return float(text) if text.is_valid_float() else fallback
