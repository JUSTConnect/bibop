extends RefCounted
class_name MissionContentCatalog

const _MISSION_DEFINITIONS: Dictionary = {
	"mission_1": {
		"id": "mission_1",
		"index": 1,
		"title": "Mission 1",
		"role": "mainline",
		"layout_source": "legacy_grid_manager",
		"world_content_source": "legacy_mission_manager",
		"runtime_source": "mission_manager",
		"migration_status": "metadata_only",
		"validation_suites": [],
		"notes": []
	},
	"mission_4": {
		"id": "mission_4",
		"index": 4,
		"title": "Mission 4",
		"role": "mainline",
		"layout_source": "legacy_grid_manager",
		"world_content_source": "legacy_mission_manager",
		"runtime_source": "mission_manager",
		"migration_status": "metadata_only",
		"validation_suites": [],
		"notes": []
	},
	"mission_6": {
		"id": "mission_6",
		"index": 6,
		"title": "Mission 6",
		"role": "mainline",
		"layout_source": "legacy_grid_manager",
		"world_content_source": "legacy_mission_manager",
		"runtime_source": "mission_manager",
		"migration_status": "metadata_only",
		"validation_suites": [],
		"notes": []
	},
	"mission_7": {
		"id": "mission_7",
		"index": 7,
		"title": "Mission 7",
		"role": "mainline",
		"layout_source": "legacy_grid_manager",
		"world_content_source": "legacy_mission_manager",
		"runtime_source": "mission_manager",
		"migration_status": "metadata_only",
		"validation_suites": [],
		"notes": []
	},
	"mission_8": {
		"id": "mission_8",
		"index": 8,
		"title": "Mission 8",
		"role": "mainline",
		"layout_source": "legacy_grid_manager",
		"world_content_source": "legacy_mission_manager",
		"runtime_source": "mission_manager",
		"migration_status": "metadata_only",
		"validation_suites": [],
		"notes": []
	},
	"mission_9": {
		"id": "mission_9",
		"index": 9,
		"title": "Mission 9",
		"role": "mainline",
		"layout_source": "legacy_grid_manager",
		"world_content_source": "legacy_mission_manager",
		"runtime_source": "mission_manager",
		"migration_status": "metadata_only",
		"validation_suites": [],
		"notes": []
	},
	"mission_10": {
		"id": "mission_10",
		"index": 10,
		"title": "TASK TEST",
		"role": "systems_testbed",
		"layout_source": "legacy_grid_manager",
		"world_content_source": "legacy_mission_manager",
		"runtime_source": "mission_manager",
		"canonical_runtime_source": "current MissionManager TASK TEST builder",
		"migration_status": "metadata_only",
		"validation_suites": [],
		"notes": ["TASK TEST remains the mechanics validation sandbox"]
	}
}

func has_mission(mission_id: String) -> bool:
	return _MISSION_DEFINITIONS.has(mission_id)

func get_mission_definition(mission_id: String) -> Dictionary:
	if not has_mission(mission_id):
		return {}
	return Dictionary(_MISSION_DEFINITIONS[mission_id]).duplicate(true)

func get_all_mission_ids() -> Array[String]:
	var mission_ids: Array[String] = []
	for mission_id_variant in _MISSION_DEFINITIONS.keys():
		mission_ids.append(String(mission_id_variant))
	mission_ids.sort()
	return mission_ids

func validate_mission_catalog() -> Array[String]:
	var warnings: Array[String] = []
	var seen_indexes: Dictionary = {}
	for mission_key_variant in _MISSION_DEFINITIONS.keys():
		var mission_key: String = String(mission_key_variant)
		var definition: Dictionary = Dictionary(_MISSION_DEFINITIONS.get(mission_key, {}))
		if String(definition.get("id", "")) == "":
			warnings.append("Mission '%s' is missing id." % mission_key)
		if not definition.has("index"):
			warnings.append("Mission '%s' is missing index." % mission_key)
		if String(definition.get("title", "")) == "":
			warnings.append("Mission '%s' is missing title." % mission_key)
		if String(definition.get("id", "")) != mission_key:
			warnings.append("Mission key '%s' does not match definition id '%s'." % [mission_key, String(definition.get("id", ""))])
		if definition.has("index"):
			var mission_index: int = int(definition.get("index", -1))
			if seen_indexes.has(mission_index):
				warnings.append("Mission index %d is duplicated by '%s' and '%s'." % [mission_index, String(seen_indexes[mission_index]), mission_key])
			else:
				seen_indexes[mission_index] = mission_key

	var mission_10: Dictionary = Dictionary(_MISSION_DEFINITIONS.get("mission_10", {}))
	if mission_10.is_empty():
		warnings.append("Mission catalog is missing mission_10.")
	else:
		if String(mission_10.get("title", "")) != "TASK TEST":
			warnings.append("Mission mission_10 title must be TASK TEST.")
		if String(mission_10.get("role", "")) != "systems_testbed":
			warnings.append("Mission mission_10 role must be systems_testbed.")

	return warnings

func get_mission_catalog_validation_text() -> String:
	var warnings: Array[String] = validate_mission_catalog()
	if warnings.is_empty():
		return "Mission content catalog validation passed."
	return "Mission content catalog warnings: %s" % ", ".join(warnings)
