extends SceneTree
const Migration = preload("res://scripts/world/versioned_snapshot_migration_service.gd")
func _init() -> void:
	var migrated: Dictionary = Migration.migrate_snapshot({"schema_version":1, "objects":[{"legacy_object_type":"crate", "legacy_prefab_id":"crate"}]})
	var objects: Array = Array(migrated.get("objects", []))
	var ok := int(migrated.get("schema_version", 0)) == 2 and objects.size() == 1 and str(Dictionary(objects[0]).get("object_type", "")) == "crate" and str(Dictionary(objects[0]).get("archetype_id", "")) == "crate"
	quit(0 if ok else 1)
