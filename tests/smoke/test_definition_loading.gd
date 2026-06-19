extends RefCounted

const CatalogRef = preload("res://scripts/domain/object_definition_catalog.gd")

static func run() -> Array[String]:
	var errors: Array[String] = []
	var catalog: RefCounted = CatalogRef.new()
	var definitions: Array = catalog.call("load_paths", [
		"res://data/objects/power_source_basic.json",
		"res://data/objects/terminal_basic.json",
		"res://data/objects/door_basic.json",
	])
	if definitions.size() != 3:
		errors.append("Expected 3 valid object definitions, got %d" % definitions.size())
	for value: Variant in Array(catalog.call("get_validation_errors")):
		errors.append(str(value))
	return errors
