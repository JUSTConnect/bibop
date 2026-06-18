extends Node2D

# Target class: WorldRenderer
# Draws world from render model. Does not mutate gameplay state.

var current_render_model: Dictionary = {}

func render(render_model: Dictionary) -> void:
	current_render_model = render_model.duplicate(true)
	queue_redraw()

func _draw() -> void:
	pass
