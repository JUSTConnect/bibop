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
		"layout_source": "mission_content_catalog",
		"world_content_source": "legacy_mission_manager",
		"runtime_source": "mission_manager",
		"canonical_runtime_source": "current MissionManager TASK TEST builder",
		"migration_status": "task_test_layout_catalogued",
		"layout": [
			[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
			[1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
			[1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1],
			[1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
			[1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1],
			[1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
			[1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1],
			[1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 1],
			[1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
			[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
		],
		"validation_suites": [],
		"notes": [
			"TASK TEST remains the mechanics validation sandbox",
			"TASK TEST layout is now catalogued.",
			"Runtime may still use the legacy GridManager layout until the next architecture PR wires layout consumption."
		]
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

func has_mission_layout(mission_id: String) -> bool:
	if not has_mission(mission_id):
		return false
	var definition: Dictionary = Dictionary(_MISSION_DEFINITIONS.get(mission_id, {}))
	if not definition.has("layout"):
		return false
	var layout: Array = Array(definition.get("layout", []))
	return not layout.is_empty()

func get_mission_layout(mission_id: String) -> Array:
	if not has_mission_layout(mission_id):
		return []
	var definition: Dictionary = Dictionary(_MISSION_DEFINITIONS.get(mission_id, {}))
	return Array(definition.get("layout", [])).duplicate(true)

func get_mission_layout_size(mission_id: String) -> Vector2i:
	var layout: Array = get_mission_layout(mission_id)
	if layout.is_empty():
		return Vector2i.ZERO
	var first_row: Array = Array(layout[0])
	return Vector2i(first_row.size(), layout.size())

func get_mission_exit_cells(mission_id: String) -> Array[Vector2i]:
	var exit_cells: Array[Vector2i] = []
	var layout: Array = get_mission_layout(mission_id)
	for y in range(layout.size()):
		var row: Array = Array(layout[y])
		for x in range(row.size()):
			if int(row[x]) == 4:
				exit_cells.append(Vector2i(x, y))
	return exit_cells

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
		if definition.has("layout"):
			var mission_layout: Array = Array(definition.get("layout", []))
			if mission_layout.is_empty():
				warnings.append("Mission '%s' layout is empty." % mission_key)
			else:
				var expected_row_width: int = -1
				for row_index in range(mission_layout.size()):
					var row_variant: Variant = mission_layout[row_index]
					if not (row_variant is Array):
						warnings.append("Mission '%s' layout row %d is not an array." % [mission_key, row_index])
						continue
					var row: Array = Array(row_variant)
					if expected_row_width == -1:
						expected_row_width = row.size()
					elif row.size() != expected_row_width:
						warnings.append("Mission '%s' layout rows must have equal width." % mission_key)
						break
				if expected_row_width <= 0 or mission_layout.size() <= 0:
					warnings.append("Mission '%s' layout size must be positive." % mission_key)

	var mission_10: Dictionary = Dictionary(_MISSION_DEFINITIONS.get("mission_10", {}))
	if mission_10.is_empty():
		warnings.append("Mission catalog is missing mission_10.")
	else:
		if String(mission_10.get("title", "")) != "TASK TEST":
			warnings.append("Mission mission_10 title must be TASK TEST.")
		if String(mission_10.get("role", "")) != "systems_testbed":
			warnings.append("Mission mission_10 role must be systems_testbed.")
		if String(mission_10.get("migration_status", "")) != "task_test_layout_catalogued":
			warnings.append("Mission mission_10 migration_status must be task_test_layout_catalogued.")
		if String(mission_10.get("layout_source", "")) != "mission_content_catalog":
			warnings.append("Mission mission_10 layout_source must be mission_content_catalog.")
		if String(mission_10.get("world_content_source", "")) != "legacy_mission_manager":
			warnings.append("Mission mission_10 world_content_source must remain legacy_mission_manager.")
		if not has_mission_layout("mission_10"):
			warnings.append("Mission mission_10 layout is required.")
		else:
			var mission_10_layout: Array = get_mission_layout("mission_10")
			var mission_10_size: Vector2i = get_mission_layout_size("mission_10")
			if mission_10_layout.is_empty():
				warnings.append("Mission mission_10 layout must not be empty.")
			if mission_10_size.x != 16:
				warnings.append("Mission mission_10 layout width must be 16.")
			if mission_10_size.y != 10:
				warnings.append("Mission mission_10 layout height must be 10.")
			if get_mission_exit_cells("mission_10").is_empty():
				warnings.append("Mission mission_10 layout must contain at least one exit tile.")

	return warnings

func get_mission_catalog_validation_text() -> String:
	var warnings: Array[String] = validate_mission_catalog()
	if warnings.is_empty():
		return "Mission content catalog validation passed."
	return "Mission content catalog warnings: %s" % ", ".join(warnings)
