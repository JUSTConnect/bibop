extends RefCounted

const CatalogRef = preload("res://scripts/domain/object_definition_catalog.gd")
const TestRoomRef = preload("res://scripts/systems/first_playable_test_room.gd")
const MapEditStateRef = preload("res://scripts/map_constructor/map_edit_state.gd")
const InteractionRef = preload("res://scripts/systems/object_interaction_system.gd")
const PowerRef = preload("res://scripts/systems/object_power_system.gd")

static func run() -> Array[String]:
	var errors: Array[String] = []
	var catalog: RefCounted = CatalogRef.new()
	catalog.call("load_paths", [
		"res://data/objects/power_source_basic.json",
		"res://data/objects/terminal_basic.json",
		"res://data/objects/door_basic.json",
	])
	var definitions_by_id: Dictionary = {}
	for value: Variant in Array(catalog.call("get_all_definitions")):
		var definition: Dictionary = Dictionary(value)
		definitions_by_id[str(definition.get("id", ""))] = definition
	var state: RefCounted = MapEditStateRef.new()
	state.call("load_snapshot", TestRoomRef.make_snapshot(definitions_by_id))
	_apply_patches(state, PowerRef.evaluate_all(_objects(state)))
	var source: Dictionary = Dictionary(state.call("get_instance_data", "power_source_basic_001"))
	var use_result: Dictionary = InteractionRef.use_object(source, _objects(state))
	_apply_patches(state, Array(use_result.get("patches", [])))
	_apply_patches(state, PowerRef.evaluate_all(_objects(state)))
	var terminal: Dictionary = Dictionary(state.call("get_instance_data", "terminal_basic_002"))
	if str(terminal.get("power_state", "")) != "unpowered":
		errors.append("Terminal must become unpowered when source is off")
	return errors

static func _objects(state: RefCounted) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value: Variant in Array(state.call("get_placed_objects")):
		result.append(Dictionary(value))
	return result

static func _apply_patches(state: RefCounted, patches: Array) -> void:
	for value: Variant in patches:
		var info: Dictionary = Dictionary(value)
		state.call("patch_instance", str(info.get("instance_id", "")), Dictionary(info.get("patch", {})))
