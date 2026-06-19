extends RefCounted

const MAX_LINES := 350
const CHECKED_PATHS: Array[String] = [
	"res://scripts/app/editor_app_controller.gd",
	"res://scripts/app/app_layout_builder.gd",
	"res://scripts/app/map_editor_controller.gd",
	"res://scripts/app/object_inspector_controller.gd",
	"res://scripts/app/world_runtime_controller.gd",
	"res://scripts/world/world_object_repository.gd",
	"res://scripts/power/power_graph.gd",
	"res://scripts/power/power_network_solver.gd",
]

static func run() -> Array[String]:
	var errors: Array[String] = []
	for path: String in CHECKED_PATHS:
		if not FileAccess.file_exists(path):
			errors.append("Missing size-checked file: %s" % path)
			continue
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file == null:
			errors.append("Cannot read size-checked file: %s" % path)
			continue
		var line_count: int = file.get_as_text().split("\n").size()
		if line_count > MAX_LINES:
			errors.append("%s has %d lines; maximum is %d" % [path, line_count, MAX_LINES])
	return errors
