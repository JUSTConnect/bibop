extends RefCounted

const CatalogRef = preload("res://scripts/domain/object_definition_catalog.gd")
const TestRoomRef = preload("res://scripts/systems/first_playable_test_room.gd")

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
	var snapshot: Dictionary = TestRoomRef.make_snapshot(definitions_by_id)
	var objects: Array = Array(snapshot.get("placed_objects", []))
	if objects.size() != 3:
		errors.append("Test room must contain exactly 3 objects")
	if str(snapshot.get("selected_entity_id", "")) != "terminal_basic_002":
		errors.append("Test room must select terminal")
	return errors
