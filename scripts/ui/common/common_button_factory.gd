extends RefCounted

# Target class: CommonButtonFactory
# Единое создание action buttons.

static func make_button(definition: Dictionary) -> Button:
	var button := Button.new()
	button.name = str(definition.get("id", "ActionButton"))
	button.text = str(definition.get("label", "Action"))
	button.disabled = not bool(definition.get("enabled", true))
	button.tooltip_text = str(definition.get("disabled_reason", ""))
	return button
