extends Control

const AppControllerRef = preload("res://scripts/app/editor_app_controller.gd")

var app_controller: RefCounted = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	app_controller = AppControllerRef.new()
	app_controller.setup(self)
	app_controller.call("_load_test_room")
