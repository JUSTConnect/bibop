extends Node

# Target class: SceneRouter
# Отвечает за загрузку/выгрузку сцен по AppMode.
# Не содержит правил игры.

var active_scene: Node = null

func show_scene(_scene_path: String, _payload: Dictionary = {}) -> void:
	pass

func clear_scene() -> void:
	if active_scene != null and is_instance_valid(active_scene):
		active_scene.queue_free()
	active_scene = null
