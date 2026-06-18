extends RefCounted

# Target class: NotificationViewModel
# Message data for notification presenter.

static func create(message: String, role: String = "system") -> Dictionary:
	return {
		"message": message,
		"role": role,
		"duration": 3.0,
	}
