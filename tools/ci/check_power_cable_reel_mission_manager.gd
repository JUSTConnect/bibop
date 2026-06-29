extends SceneTree
func _init() -> void:
	var text := FileAccess.get_file_as_string("res://scripts/game/mission_manager.gd")
	quit(0 if text.contains("validate_power_cable_reel_normalization") else 1)
