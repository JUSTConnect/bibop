extends Node2D

# Target class: PreviewRenderer
# Draws placement/link/route previews. Read-only.

var preview_model: Dictionary = {}

func render_preview(model: Dictionary) -> void:
	preview_model = model.duplicate(true)
	queue_redraw()

func clear_preview() -> void:
	preview_model.clear()
	queue_redraw()
