extends RefCounted

static func build(view_model: Dictionary, on_action: Callable) -> VBoxContainer:
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 6)
	var title := Label.new()
	title.text = str(view_model.get("title", "Actions"))
	title.add_theme_font_size_override("font_size", 16)
	panel.add_child(title)
	for value: Variant in Array(view_model.get("actions", [])):
		var action: Dictionary = Dictionary(value)
		var button := Button.new()
		button.text = str(action.get("label", action.get("id", "Action")))
		button.disabled = not bool(action.get("enabled", true))
		button.tooltip_text = str(action.get("disabled_reason", ""))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var action_id: String = str(action.get("id", ""))
		button.pressed.connect(func() -> void:
			if on_action.is_valid():
				on_action.call(action_id)
		)
		panel.add_child(button)
	return panel
