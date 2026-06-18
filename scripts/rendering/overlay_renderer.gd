extends Node2D

# Target class: OverlayRenderer
# Draws debug/selection/validation overlays from render model.

var overlay_model: Dictionary = {}

func render_overlay(model: Dictionary) -> void:
	overlay_model = model.duplicate(true)
	queue_redraw()

func _draw() -> void:
	pass
