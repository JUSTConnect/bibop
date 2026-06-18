extends Node

# Target class: NotificationBus
# Единственный global notification bus. UI отображает через NotificationPresenter.

signal notification_pushed(message: Dictionary)

func push(message: String, role: String = "system") -> void:
	notification_pushed.emit({"message": message, "role": role, "duration": 3.0})
