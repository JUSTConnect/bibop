extends RefCounted

const MAX_LINES := 350
const REQUIRED_CONTROLLERS: Array[String] = [
	"res://scripts/app/editor_app_controller.gd",
	"res://scripts/app/palette_controller.gd",
	"res://scripts/app/map_editor_controller.gd",
	"res://scripts/app/object_inspector_controller.gd",
	"res://scripts/app/world_runtime_controller.gd",
]

static func run() -> Array[String]:
	var errors: Array[String] = []
	for path: String in REQUIRED_CONTROLLERS:
		if not FileAccess.file_exists(path):
			errors.append("Missing controller: %s" % path)
			continue
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file == null:
			errors.append("Cannot read controller: %s" % path)
			continue
		var line_count: int = file.get_as_text().split("\n").size()
		if line_count > MAX_LINES:
			errors.append("Controller exceeds %d lines: %s (%d)" % [MAX_LINES, path, line_count])
	var root_file: FileAccess = FileAccess.open("res://scripts/app/app_root.gd", FileAccess.READ)
	if root_file == null or not root_file.get_as_text().contains("editor_app_controller.gd"):
		errors.append("AppRoot must use editor_app_controller.gd")
	return errors
