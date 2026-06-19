extends Control

# AppRoot
# Тонкая scene-shell. Persistence расширение живёт в AppDocumentController.

const AppControllerRef = preload("res://scripts/app/app_document_controller.gd")

var app_controller: RefCounted = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	app_controller = AppControllerRef.new()
	app_controller.setup(self)
