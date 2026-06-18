extends RefCounted

# Target class: NotificationPresenter
# Displays notification messages in one HUD notification area.

static func show_message(label: Label, message: Dictionary) -> void:
	if label == null or not is_instance_valid(label):
		return
	label.text = str(message.get("message", ""))
	label.visible = not label.text.is_empty()
