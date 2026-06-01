extends SceneTree

const DEFAULT_SCAN_ROOT: String = "res://scripts"

var _scan_root: String = DEFAULT_SCAN_ROOT
var _loaded_count: int = 0
var _failed_paths: Array[String] = []

func _initialize() -> void:
	_parse_args()
	print("BIPOB GDScript parser gate: scanning %s" % _scan_root)
	var script_paths: Array[String] = []
	_collect_gd_files(_scan_root, script_paths)
	script_paths.sort()
	for script_path in script_paths:
		_parse_script(script_path)
	if _failed_paths.is_empty():
		print("BIPOB GDScript parser gate: OK, loaded %d scripts." % _loaded_count)
		quit(0)
		return
	push_error("BIPOB GDScript parser gate: FAILED, %d of %d scripts did not load." % [_failed_paths.size(), script_paths.size()])
	for failed_path in _failed_paths:
		push_error("GDScript load failed: %s" % failed_path)
	quit(1)

func _parse_args() -> void:
	for arg_variant in OS.get_cmdline_args():
		var arg: String = str(arg_variant).strip_edges()
		if arg.begins_with("--root="):
			var custom_root: String = arg.substr("--root=".length()).strip_edges()
			if not custom_root.is_empty():
				_scan_root = custom_root

func _collect_gd_files(dir_path: String, out_files: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		_failed_paths.append("%s (DirAccess.open failed: %s)" % [dir_path, error_string(DirAccess.get_open_error())])
		return
	dir.list_dir_begin()
	var entry_name: String = dir.get_next()
	while not entry_name.is_empty():
		if entry_name.begins_with("."):
			entry_name = dir.get_next()
			continue
		var child_path: String = "%s/%s" % [dir_path, entry_name]
		if dir.current_is_dir():
			_collect_gd_files(child_path, out_files)
		elif entry_name.ends_with(".gd"):
			out_files.append(child_path)
		entry_name = dir.get_next()
	dir.list_dir_end()

func _parse_script(script_path: String) -> void:
	var resource: Resource = ResourceLoader.load(script_path)
	if resource == null:
		_failed_paths.append(script_path)
		return
	_loaded_count += 1
