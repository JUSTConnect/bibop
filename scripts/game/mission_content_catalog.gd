extends RefCounted
class_name MissionContentCatalog

const TASK_TEST_LAYOUT_ID := "task_test"
const TASK_TEST_MISSION_ID := "mission_10"
const _MISSION_ALIASES: Dictionary = {"mission_10": "task_test"}

const _MISSION_DEFINITIONS: Dictionary = {
	"mission_1": {
		"id": "mission_1",
		"index": 1,
		"title": "Mission 1",
		"display_name": "Mission 1",
		"short_description": "Legacy mission metadata placeholder.",
		"objective_hint": "Mission objective hint is provided by legacy BipobController logic.",
		"start_cell": Vector2i(-1, -1),
		"exit_cells": [],
		"role": "mainline",
		"layout_source": "legacy_grid_manager",
		"world_content_source": "legacy_mission_manager",
		"runtime_source": "mission_manager",
		"migration_status": "metadata_only",
		"validation_suites": [],
		"notes": ["Start/exit gameplay positions are still legacy-owned for this mission."]
	},
	"mission_2": {
		"id": "mission_2",
		"index": 2,
		"title": "Mission 2",
		"display_name": "Mission 2",
		"short_description": "Legacy mission metadata placeholder.",
		"objective_hint": "Mission objective hint is provided by legacy BipobController logic.",
		"start_cell": Vector2i(-1, -1),
		"exit_cells": [],
		"role": "mainline",
		"layout_source": "legacy_grid_manager",
		"world_content_source": "legacy_mission_manager",
		"runtime_source": "mission_manager",
		"migration_status": "metadata_only",
		"validation_suites": [],
		"notes": ["Start/exit gameplay positions are still legacy-owned for this mission."]
	},
	"mission_3": {
		"id": "mission_3",
		"index": 3,
		"title": "Mission 3",
		"display_name": "Mission 3",
		"short_description": "Legacy mission metadata placeholder.",
		"objective_hint": "Mission objective hint is provided by legacy BipobController logic.",
		"start_cell": Vector2i(-1, -1),
		"exit_cells": [],
		"role": "mainline",
		"layout_source": "legacy_grid_manager",
		"world_content_source": "legacy_mission_manager",
		"runtime_source": "mission_manager",
		"migration_status": "metadata_only",
		"validation_suites": [],
		"notes": ["Start/exit gameplay positions are still legacy-owned for this mission."]
	},
	"mission_4": {
		"id": "mission_4",
		"index": 4,
		"title": "Mission 4",
		"display_name": "Mission 4",
		"short_description": "Legacy mission metadata placeholder.",
		"objective_hint": "Mission objective hint is provided by legacy BipobController logic.",
		"start_cell": Vector2i(-1, -1),
		"exit_cells": [],
		"role": "mainline",
		"layout_source": "legacy_grid_manager",
		"world_content_source": "legacy_mission_manager",
		"runtime_source": "mission_manager",
		"migration_status": "metadata_only",
		"validation_suites": [],
		"notes": ["Start/exit gameplay positions are still legacy-owned for this mission."]
	},
	"mission_5": {
		"id": "mission_5",
		"index": 5,
		"title": "Mission 5",
		"display_name": "Mission 5",
		"short_description": "Legacy mission metadata placeholder.",
		"objective_hint": "Mission objective hint is provided by legacy BipobController logic.",
		"start_cell": Vector2i(-1, -1),
		"exit_cells": [],
		"role": "mainline",
		"layout_source": "legacy_grid_manager",
		"world_content_source": "legacy_mission_manager",
		"runtime_source": "mission_manager",
		"migration_status": "metadata_only",
		"validation_suites": [],
		"notes": ["Start/exit gameplay positions are still legacy-owned for this mission."]
	},
	"mission_6": {
		"id": "mission_6",
		"index": 6,
		"title": "Mission 6",
		"display_name": "Mission 6",
		"short_description": "Legacy mission metadata placeholder.",
		"objective_hint": "Mission objective hint is provided by legacy BipobController logic.",
		"start_cell": Vector2i(-1, -1),
		"exit_cells": [],
		"role": "mainline",
		"layout_source": "legacy_grid_manager",
		"world_content_source": "legacy_mission_manager",
		"runtime_source": "mission_manager",
		"migration_status": "metadata_only",
		"validation_suites": [],
		"notes": ["Start/exit gameplay positions are still legacy-owned for this mission."]
	},
	"mission_9": {
		"id": "mission_9",
		"index": 9,
		"title": "Mission 9",
		"display_name": "Mission 9",
		"short_description": "Legacy mission metadata placeholder.",
		"objective_hint": "Mission objective hint is provided by legacy BipobController logic.",
		"start_cell": Vector2i(-1, -1),
		"exit_cells": [],
		"role": "mainline",
		"layout_source": "legacy_grid_manager",
		"world_content_source": "legacy_mission_manager",
		"runtime_source": "mission_manager",
		"migration_status": "metadata_only",
		"validation_suites": [],
		"notes": ["Start/exit gameplay positions are still legacy-owned for this mission."]
	},
	"task_test": {
		"id": "task_test",
		"compatibility_mission_id": "mission_10",
		"index": 10,
		"title": "TASK TEST",
		"display_name": "TASK TEST",
		"short_description": "Universal mechanics validation sandbox.",
		"goal_text": "Validate runtime interaction, storage, doors, terminals, power and constructor systems.",
		"objective_hint": "Use this mission to test all core systems without adding new mission content.",
		"start_cell": Vector2i(1, 1),
		"exit_cells": [Vector2i(14, 7)],
		"role": "systems_testbed",
		"layout_source": "mission_content_catalog",
		"world_content_source": "legacy_mission_manager",
		"runtime_source": "mission_manager",
		"migration_status": "task_test_layout_catalogued",
		"validation_suites": ["task_test_layout"],
		"notes": [
			"TASK TEST remains the mechanics validation sandbox.",
			"TASK TEST world content remains in MissionManager builder.",
			"mission_10 remains accepted as a compatibility alias.",
			"Normal mission gameplay and legacy layout fallbacks remain unchanged."
		],
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
		]
	}
}

func _resolve_mission_id(mission_id: String) -> String:
	var normalized := str(mission_id).strip_edges()
	if _MISSION_DEFINITIONS.has(normalized):
		return normalized
	return str(_MISSION_ALIASES.get(normalized, "")).strip_edges()

func has_mission(mission_id: String) -> bool:
	var resolved_mission_id: String = _resolve_mission_id(mission_id)
	return not resolved_mission_id.is_empty() and _MISSION_DEFINITIONS.has(resolved_mission_id)

func get_mission_definition(mission_id: String) -> Dictionary:
	var normalized := str(mission_id).strip_edges()
	var resolved_mission_id: String = _resolve_mission_id(normalized)
	if resolved_mission_id.is_empty():
		return {}
	var definition: Dictionary = Dictionary(_MISSION_DEFINITIONS[resolved_mission_id]).duplicate(true)
	if normalized != resolved_mission_id and not normalized.is_empty():
		definition["id"] = normalized
		definition["canonical_mission_id"] = resolved_mission_id
	return definition

func get_mission_title(mission_id: String) -> String:
	return str(get_mission_definition(mission_id).get("title", "")).strip_edges()

func get_mission_display_name(mission_id: String) -> String:
	return str(get_mission_definition(mission_id).get("display_name", "")).strip_edges()

func get_mission_goal_text(mission_id: String) -> String:
	return str(get_mission_definition(mission_id).get("goal_text", "")).strip_edges()

func get_mission_objective_hint(mission_id: String) -> String:
	return str(get_mission_definition(mission_id).get("objective_hint", "")).strip_edges()

func get_mission_short_description(mission_id: String) -> String:
	return str(get_mission_definition(mission_id).get("short_description", "")).strip_edges()

func has_mission_start_cell(mission_id: String) -> bool:
	var start_cell_variant: Variant = get_mission_definition(mission_id).get("start_cell", Vector2i(-1, -1))
	var start_cell: Vector2i = Vector2i(start_cell_variant)
	return start_cell.x >= 0 and start_cell.y >= 0

func get_mission_start_cell(mission_id: String) -> Vector2i:
	if not has_mission_start_cell(mission_id):
		return Vector2i(-1, -1)
	return Vector2i(get_mission_definition(mission_id).get("start_cell", Vector2i(-1, -1)))

func get_all_mission_ids() -> Array[String]:
	var mission_ids: Array[String] = []
	for mission_id_variant in _MISSION_DEFINITIONS.keys():
		mission_ids.append(str(mission_id_variant))
	for mission_alias_variant in _MISSION_ALIASES.keys():
		var mission_alias: String = str(mission_alias_variant)
		if not mission_ids.has(mission_alias):
			mission_ids.append(mission_alias)
	mission_ids.sort()
	return mission_ids

func get_active_runtime_mission_ids() -> Array[String]:
	var mission_ids: Array[String] = get_all_mission_ids()
	var active_mission_ids: Array[String] = []
	for mission_id in mission_ids:
		active_mission_ids.append(mission_id)
	return active_mission_ids

func has_mission_layout(mission_id: String) -> bool:
	var resolved_mission_id: String = _resolve_mission_id(mission_id)
	if resolved_mission_id.is_empty():
		return false
	var definition: Dictionary = Dictionary(_MISSION_DEFINITIONS.get(resolved_mission_id, {}))
	if not definition.has("layout"):
		return false
	var layout: Array = Array(definition.get("layout", []))
	return not layout.is_empty()

func get_mission_layout(mission_id: String) -> Array:
	var resolved_mission_id: String = _resolve_mission_id(mission_id)
	if resolved_mission_id.is_empty() or not has_mission_layout(resolved_mission_id):
		return []
	var definition: Dictionary = Dictionary(_MISSION_DEFINITIONS.get(resolved_mission_id, {}))
	return Array(definition.get("layout", [])).duplicate(true)

func get_mission_layout_size(mission_id: String) -> Vector2i:
	var layout: Array = get_mission_layout(mission_id)
	if layout.is_empty():
		return Vector2i.ZERO
	var first_row: Array = Array(layout[0])
	return Vector2i(first_row.size(), layout.size())

func get_mission_exit_cells(mission_id: String) -> Array[Vector2i]:
	var definition: Dictionary = get_mission_definition(mission_id)
	var explicit_exit_cells: Array = Array(definition.get("exit_cells", []))
	if not explicit_exit_cells.is_empty():
		var resolved_exit_cells: Array[Vector2i] = []
		for exit_cell_variant in explicit_exit_cells:
			resolved_exit_cells.append(Vector2i(exit_cell_variant))
		return resolved_exit_cells
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
		var mission_key: String = str(mission_key_variant)
		var definition: Dictionary = Dictionary(_MISSION_DEFINITIONS.get(mission_key, {}))
		if str(definition.get("id", "")) == "":
			warnings.append("Mission '%s' is missing id." % mission_key)
		if not definition.has("index"):
			warnings.append("Mission '%s' is missing index." % mission_key)
		if str(definition.get("title", "")) == "":
			warnings.append("Mission '%s' is missing title." % mission_key)
		if str(definition.get("display_name", "")) == "":
			warnings.append("Mission '%s' is missing display_name." % mission_key)
		if str(definition.get("role", "")) == "":
			warnings.append("Mission '%s' is missing role." % mission_key)
		if str(definition.get("migration_status", "")) == "":
			warnings.append("Mission '%s' is missing migration_status." % mission_key)
		if str(definition.get("id", "")) != mission_key:
			warnings.append("Mission key '%s' does not match definition id '%s'." % [mission_key, str(definition.get("id", ""))])
		if definition.has("index"):
			var mission_index: int = int(definition.get("index", -1))
			if seen_indexes.has(mission_index):
				warnings.append("Mission index %d is duplicated by '%s' and '%s'." % [mission_index, str(seen_indexes[mission_index]), mission_key])
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

	var task_test: Dictionary = Dictionary(_MISSION_DEFINITIONS.get("task_test", {}))
	if task_test.is_empty():
		warnings.append("Mission catalog is missing canonical task_test.")
	else:
		if _resolve_mission_id("mission_10") != "task_test":
			warnings.append("Mission mission_10 must resolve to canonical task_test.")
		if str(task_test.get("compatibility_mission_id", "")) != "mission_10":
			warnings.append("Mission task_test compatibility_mission_id must be mission_10.")
		if str(task_test.get("display_name", "")) != "TASK TEST":
			warnings.append("Mission task_test display_name must be TASK TEST.")
		if str(task_test.get("role", "")) != "systems_testbed":
			warnings.append("Mission task_test role must be systems_testbed.")
		if str(task_test.get("goal_text", "")).strip_edges() == "":
			warnings.append("Mission task_test goal_text must not be empty.")
		if str(task_test.get("objective_hint", "")).strip_edges() == "":
			warnings.append("Mission task_test objective_hint must not be empty.")
		if str(task_test.get("migration_status", "")) != "task_test_layout_catalogued":
			warnings.append("Mission task_test migration_status must be task_test_layout_catalogued.")
		if str(task_test.get("layout_source", "")) != "mission_content_catalog":
			warnings.append("Mission task_test layout_source must be mission_content_catalog.")
		if str(task_test.get("world_content_source", "")) != "legacy_mission_manager":
			warnings.append("Mission task_test world_content_source must remain legacy_mission_manager.")
		if not has_mission_layout("task_test"):
			warnings.append("Mission task_test layout is required.")
		else:
			var task_test_layout: Array = get_mission_layout("task_test")
			var task_test_size: Vector2i = get_mission_layout_size("task_test")
			if task_test_layout.is_empty():
				warnings.append("Mission task_test layout must not be empty.")
			if task_test_size.x != 16:
				warnings.append("Mission task_test layout width must be 16.")
			if task_test_size.y != 10:
				warnings.append("Mission task_test layout height must be 10.")
			var layout_exit_cells: Array[Vector2i] = []
			for y in range(task_test_layout.size()):
				var row: Array = Array(task_test_layout[y])
				for x in range(row.size()):
					if int(row[x]) == 4:
						layout_exit_cells.append(Vector2i(x, y))
			var metadata_exit_cells: Array[Vector2i] = get_mission_exit_cells("task_test")
			if metadata_exit_cells.is_empty():
				warnings.append("Mission task_test exit_cells must not be empty.")
			if not layout_exit_cells.is_empty() and metadata_exit_cells != layout_exit_cells:
				warnings.append("Mission task_test exit_cells must match layout exit tiles.")
			if get_mission_exit_cells("mission_10") != metadata_exit_cells:
				warnings.append("Mission mission_10 alias exit_cells must match task_test.")
			if has_mission_start_cell("task_test"):
				var start_cell: Vector2i = get_mission_start_cell("task_test")
				if start_cell.x < 0 or start_cell.y < 0 or start_cell.x >= task_test_size.x or start_cell.y >= task_test_size.y:
					warnings.append("Mission task_test start_cell must be inside layout bounds.")
				elif int(Array(task_test_layout[start_cell.y])[start_cell.x]) == 1:
					warnings.append("Mission task_test start_cell must not be a wall tile.")
				if get_mission_start_cell("mission_10") != start_cell:
					warnings.append("Mission mission_10 alias start_cell must match task_test.")

	return warnings

func get_mission_catalog_validation_text() -> String:
	var warnings: Array[String] = validate_mission_catalog()
	if warnings.is_empty():
		return "Mission content catalog validation passed."
	return "Mission content catalog warnings: %s" % ", ".join(warnings)
