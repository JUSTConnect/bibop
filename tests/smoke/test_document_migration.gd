extends RefCounted

const MigratorRef = preload("res://scripts/map_constructor/map_document_migrator.gd")
const ValidatorRef = preload("res://scripts/map_constructor/map_document_validator.gd")

static func run() -> Array[String]:
	var source: Dictionary = {
		"version": 1,
		"selected_definition_id": "door_basic",
		"placed_objects": [{"id": "door_1", "definition_id": "door_basic"}],
	}
	var migrated: Dictionary = MigratorRef.migrate(source)
	var errors: Array[String] = ValidatorRef.validate(migrated)
	if int(migrated.get("version", 0)) != 3:
		errors.append("Migration did not produce v3")
	if not migrated.has("editor_state"):
		errors.append("Migration lost editor state")
	return errors
