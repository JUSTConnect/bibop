extends RefCounted

const ROOTS: Array[String] = ["res://scripts", "res://tests"]

static func run() -> Array[String]:
	var errors: Array[String] = []
	var paths: Array[String] = []
	for root_path: String in ROOTS:
		_collect_scripts(root_path, paths, errors)
	for script_path: String in paths:
		var resource: Resource = ResourceLoader.load(script_path)
		if not (resource is Script):
			errors.append("Cannot load GDScript: %s" % script_path)
	return errors

static func _collect_scripts(directory_path: String, paths: Array[String], errors: Array[String]) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		errors.append("Cannot open script directory: %s" % directory_path)
		return
	directory.list_dir_begin()
	var entry_name: String = directory.get_next()
	while not entry_name.is_empty():
		if entry_name != "." and entry_name != "..":
			var entry_path: String = directory_path.path_join(entry_name)
			if directory.current_is_dir():
				_collect_scripts(entry_path, paths, errors)
			elif entry_name.ends_with(".gd"):
				paths.append(entry_path)
		entry_name = directory.get_next()
	directory.list_dir_end()
