extends Node

# Target class: InputRouter
# Маршрутизирует input в текущий mode controller.

var current_mode_controller: Object = null

func set_mode_controller(controller: Object) -> void:
	current_mode_controller = controller

func route_input(event: InputEvent) -> void:
	if current_mode_controller != null and current_mode_controller.has_method("handle_input"):
		current_mode_controller.call("handle_input", event)
