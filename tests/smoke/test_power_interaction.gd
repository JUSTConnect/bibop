extends RefCounted

const CatalogRef = preload("res://scripts/domain/object_definition_catalog.gd")
const TestRoomRef = preload("res://scripts/systems/first_playable_test_room.gd")
const MapEditorRef = preload("res://scripts/app/map_editor_controller.gd")
const InteractionRef = preload("res://scripts/systems/object_interaction_system.gd")
const PowerRef = preload("res://scripts/systems/object_power_system.gd")

static func run() -> Array[String]:
	var errors: Array[String] = []
	var catalog: RefCounted = CatalogRef.new()
	catalog.call("load_paths", [
		"res://data/objects/power_source_basic.json",
		"res://data/objects/terminal_basic.json",
		"res://data/objects/door_basic.json",
		"res://data/objects/power_cable_basic.json",
	])
	var definitions_by_id: Dictionary = {}
	for value: Variant in Array(catalog.call("get_all_definitions")):
		var definition: Dictionary = Dictionary(value)
		definitions_by_id[str(definition.get("id", ""))] = definition
	var snapshot: Dictionary = TestRoomRef.make_snapshot(definitions_by_id)
	var objects: Array = Array(snapshot.get("placed_objects", []))
	var terminal_data: Dictionary = Dictionary(objects[2])
	terminal_data["links"] = {"power_source": "", "controlled_targets": ["door_basic_004"]}
	objects[2] = terminal_data
	snapshot["placed_objects"] = objects
	var editor: RefCounted = MapEditorRef.new()
	editor.call("setup")
	editor.call("load_snapshot", snapshot)
	_apply_patches(editor, PowerRef.evaluate_all(_objects(editor)))
	var terminal: Dictionary = Dictionary(editor.call("get_instance_data", "terminal_basic_003"))
	if str(terminal.get("power_state", "")) != "powered":
		errors.append("Cable graph must power terminal")
	var source: Dictionary = Dictionary(editor.call("get_instance_data", "power_source_basic_001"))
	var use_result: Dictionary = InteractionRef.use_object(source, _objects(editor))
	_apply_patches(editor, Array(use_result.get("patches", [])))
	_apply_patches(editor, PowerRef.evaluate_all(_objects(editor)))
	terminal = Dictionary(editor.call("get_instance_data", "terminal_basic_003"))
	if str(terminal.get("power_state", "")) != "unpowered":
		errors.append("Terminal must become unpowered when cable source is off")
	return errors

static func _objects(editor: RefCounted) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value: Variant in Array(editor.call("get_placed_objects")):
		result.append(Dictionary(value))
	return result

static func _apply_patches(editor: RefCounted, patches: Array) -> void:
	for value: Variant in patches:
		var info: Dictionary = Dictionary(value)
		editor.call("apply_runtime_patch", str(info.get("instance_id", "")), Dictionary(info.get("patch", {})))
