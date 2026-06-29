extends RefCounted
class_name VersionedSnapshotMigrationService

const CURRENT_VERSION := 2
const LEGACY_VERSION := 1

static func migrate_snapshot(snapshot: Dictionary) -> Dictionary:
	var result: Dictionary = snapshot.duplicate(true)
	var version: int = int(result.get("schema_version", LEGACY_VERSION))
	if version < CURRENT_VERSION:
		result = _migrate_legacy_v1_to_v2(result)
	result["schema_version"] = CURRENT_VERSION
	return result

static func _migrate_legacy_v1_to_v2(snapshot: Dictionary) -> Dictionary:
	var result: Dictionary = snapshot.duplicate(true)
	var objects: Array = Array(result.get("objects", [])).duplicate(true)
	for index in range(objects.size()):
		if objects[index] is Dictionary:
			objects[index] = _migrate_legacy_object(Dictionary(objects[index]))
	result["objects"] = objects
	return result

static func _migrate_legacy_object(object_data: Dictionary) -> Dictionary:
	var result: Dictionary = object_data.duplicate(true)
	if result.has("legacy_object_type") and not result.has("object_type"):
		result["object_type"] = str(result.get("legacy_object_type", ""))
	if result.has("legacy_prefab_id") and not result.has("archetype_id"):
		result["archetype_id"] = str(result.get("legacy_prefab_id", ""))
	return result
