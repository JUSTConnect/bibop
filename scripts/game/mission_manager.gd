extends Node

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const ScanSystemRef = preload("res://scripts/world/scan_system.gd")
const InteractionSystemRef = preload("res://scripts/world/interaction_system.gd")
const PowerSystemRef = preload("res://scripts/world/power_system.gd")

var mission_world_objects: Array[Dictionary] = []
var world_objects_by_cell: Dictionary = {}
var cell_items: Dictionary = {}
var last_threat_warning_ids: Dictionary = {}
var last_world_runtime_restore_warnings: Array[String] = []
var debug_world_logs := false
var enable_debug_seed := false
var debug_world_cooling_scenario_enabled: bool = false
var debug_platform_scenario_enabled: bool = false
var active_bipob_ref: Node = null
var grid_manager: Node = null
var platform_last_tick_action_index: int = -1
var runtime_inventory_state := {
	"pocket_items": [],
	"manipulator_hold": "",
	"digital_buffer": [],
	"box_storage": [],
	"item_amounts": {},
	"consumed_item_ids": [],
	"world_item_runtime": {}
}
var _map_constructor_runtime_object_seq: int = 1
var _task_test_constructor_base_tiles: Dictionary = {}
var _map_constructor_last_cleanup_snapshot: Dictionary = {}
var _map_constructor_last_autofix_snapshot: Dictionary = {}
var _map_constructor_last_patch_snapshot: Dictionary = {}
var _map_constructor_last_batch_snapshot: Dictionary = {}
var _map_constructor_wall_material_overrides: Dictionary = {}
var _map_constructor_change_history: Array[Dictionary] = []
var _map_constructor_change_history_seq: int = 1
var current_mission_id: String = ""
var constructor_map_width: int = 16
var constructor_map_height: int = 10
var constructor_start_marker: Dictionary = {}
var constructor_exit_marker: Dictionary = {}
const MAP_CONSTRUCTOR_PRESET_DIR: String = "user://constructor_presets"

const MAP_CONSTRUCTOR_MISSION_PATCH_DIR: String = "user://constructor_mission_patches"
const MAP_CONSTRUCTOR_PATCH_SCHEMA_VERSION: int = 1

const MAP_CONSTRUCTOR_WALL_SIDE_DELTAS: Array[Dictionary] = [
	{"side":"north", "delta": Vector2i(0, -1)},
	{"side":"east", "delta": Vector2i(1, 0)},
	{"side":"south", "delta": Vector2i(0, 1)},
	{"side":"west", "delta": Vector2i(-1, 0)}
]

const MAP_CONSTRUCTOR_WALL_MOUNTED_PREFABS: Dictionary = {
	"power_cable_reel": true,
	"light_switch": true,
	"circuit_breaker": true,
	"fuse_box": true,
	"door_terminal": true,
	"platform_terminal": true,
	"firewall": true,
	"cooling_terminal": true
}

const MAP_CONSTRUCTOR_SOLID_PREFABS: Array[String] = [
	"outer_wall","brick_wall","concrete_wall","steel_wall","grate_wall",
	"mechanical_door","digital_door","powered_gate"
]

# region Typed world-object access wrappers
func _wo_id(object_data: Dictionary) -> String:
	return String(object_data.get("id", ""))

func _wo_group(object_data: Dictionary) -> String:
	return String(object_data.get("object_group", ""))

func _wo_type(object_data: Dictionary) -> String:
	return String(object_data.get("object_type", ""))

func _wo_pos(object_data: Dictionary, fallback: Vector2i = Vector2i(-1, -1)) -> Vector2i:
	return Vector2i(object_data.get("position", fallback))
# endregion

# region Lifecycle / setup
func _ready() -> void:
	if enable_debug_seed:
		_seed_debug_world_objects()

func setup_world_objects_for_mission(mission_id: String) -> void:
	current_mission_id = mission_id
	mission_world_objects.clear()
	world_objects_by_cell.clear()
	cell_items.clear()
	_map_constructor_wall_material_overrides.clear()
	if mission_id == "mission_10":
		_setup_task_test_mission_world()
		return
	if mission_id != "mission_1":
		return
	var objects: Array[Dictionary] = WorldObjectCatalogRef.create_test_set()
	var placements := {
		"door_a1": Vector2i(2, 1),
		"door_e1": Vector2i(6, 2),
		"terminal_t1": Vector2i(5, 2),
		"wall_b1": Vector2i(2, 2),
		"wall_d1": Vector2i(3, 2),
		"power_src_1": Vector2i(1, 5),
		"cable_a": Vector2i(2, 5),
		"breaker_1": Vector2i(3, 5),
		"fuse_box_1": Vector2i(4, 5),
		"fuse_box_empty_1": Vector2i(5, 5),
		"crate_n_1": Vector2i(4, 3),
		"crate_h_1": Vector2i(4, 4),
		"barrel_1": Vector2i(1, 4),
		"debris_1": Vector2i(6, 5),
		"turret_1": Vector2i(7, 1)
	}
	objects.append(WorldObjectCatalogRef.create_world_object("turret", "turret_1"))
	for object_data in objects:
		var object_id := _wo_id(object_data)
		if object_id == "terminal_t1":
			object_data["id"] = "door_terminal_1"
			object_data["controls"] = ["steel_door_1"]
		if object_id == "wall_b1":
			object_data["hidden_content"] = ["power_cable"]
		if object_id == "wall_d1":
			object_data["hidden_content"] = ["secret_passage"]
		if object_id == "door_e1":
			object_data["id"] = "steel_door_1"
			object_data["state"] = "locked"
		if _should_assign_main_power_network(object_data):
			object_data["power_network_id"] = "power_net_A"
		elif object_id == "fuse_box_empty_1":
			object_data["power_network_id"] = "power_net_broken_test"
		else:
			object_data.erase("power_network_id")
		if placements.has(object_id):
			set_world_object_at_cell(placements[object_id], object_data)
		elif _wo_group(object_data) == "item":
			match object_id:
				"keycard_a1":
					add_item_at_cell(Vector2i(1, 3), object_data)
				"digikey_a1":
					add_item_at_cell(Vector2i(5, 1), object_data)
				"fuse_item_1":
					add_item_at_cell(Vector2i(4, 1), object_data)
				"datafile_enc_1":
					add_item_at_cell(Vector2i(3, 4), object_data)
				_:
					add_item_at_cell(Vector2i(1, 3), object_data)
	PowerSystemRef.recalculate_network(mission_world_objects, "power_net_A")
	refresh_world_cooling_received()
	if debug_world_cooling_scenario_enabled:
		seed_world_cooling_debug_scenario()
	if debug_platform_scenario_enabled:
		seed_platform_debug_scenario()
	last_threat_warning_ids.clear()
	if debug_world_logs:
		var scenario_warnings := validate_world_object_scenario()
		if not scenario_warnings.is_empty():
			for warning in scenario_warnings:
				push_warning("[WorldScenario] %s" % warning)
# endregion

func _setup_task_test_mission_world() -> void:
	_capture_task_test_constructor_base_tiles()
	var validation_data := build_task_test_mission_world_objects_for_validation()
	var objects: Array[Dictionary] = validation_data.get("objects", [])
	var items_by_cell: Dictionary = validation_data.get("items_by_cell", {})
	for obj in objects:
		set_world_object_at_cell(Vector2i(obj.get("position", Vector2i.ZERO)), obj)
	for cell_variant in items_by_cell.keys():
		var cell := Vector2i(cell_variant)
		for item in Array(items_by_cell.get(cell_variant, [])):
			add_item_at_cell(cell, Dictionary(item).duplicate(true))
	PowerSystemRef.recalculate_network(mission_world_objects, "task_test_power_main")
	refresh_world_cooling_received()

func _capture_task_test_constructor_base_tiles() -> void:
	_task_test_constructor_base_tiles.clear()
	if grid_manager == null or not grid_manager.has_method("get_width") or not grid_manager.has_method("get_height") or not grid_manager.has_method("get_tile"):
		return
	var width: int = int(grid_manager.call("get_width"))
	var height: int = int(grid_manager.call("get_height"))
	for y in range(height):
		for x in range(width):
			var cell: Vector2i = Vector2i(x, y)
			_task_test_constructor_base_tiles["%d,%d" % [x, y]] = int(grid_manager.call("get_tile", cell))

func _serialize_cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]

func _deserialize_cell_key(cell_key: String) -> Vector2i:
	var parts: PackedStringArray = cell_key.split(",")
	if parts.size() != 2:
		return Vector2i(-1, -1)
	return Vector2i(int(parts[0]), int(parts[1]))

func _deserialize_cell_variant(cell_value: Variant) -> Vector2i:
	if cell_value is Vector2i:
		return Vector2i(cell_value)
	if cell_value is String:
		return _deserialize_cell_key(String(cell_value))
	if cell_value is Dictionary:
		var cell_dict: Dictionary = Dictionary(cell_value)
		if cell_dict.has("x") and cell_dict.has("y"):
			return Vector2i(int(cell_dict.get("x", -1)), int(cell_dict.get("y", -1)))
	return Vector2i(-1, -1)

func _is_valid_grid_cell(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0:
		return false
	if grid_manager != null and grid_manager.has_method("get_width") and grid_manager.has_method("get_height"):
		var width: int = int(grid_manager.call("get_width"))
		var height: int = int(grid_manager.call("get_height"))
		return cell.x < width and cell.y < height
	return true

func _is_task_test_constructor_context() -> bool:
	return String(current_mission_id) == "mission_10"

func _format_map_constructor_cell(cell: Vector2i) -> String:
	return "(%d, %d)" % [cell.x, cell.y]

func _record_map_constructor_change(action_type: String, payload: Dictionary = {}) -> void:
	if not _is_task_test_constructor_context():
		return
	var action: String = action_type.strip_edges().to_lower()
	if action.is_empty():
		action = "unknown"
	var entity_kind: String = String(payload.get("entity_kind", "")).strip_edges()
	var entity_id: String = String(payload.get("entity_id", "")).strip_edges()
	var object_type: String = String(payload.get("object_type", payload.get("prefab_id", ""))).strip_edges()
	var cell: Vector2i = _map_constructor_cell_from_variant(payload.get("cell", Vector2i(-1, -1)))
	var summary: String = String(payload.get("summary", "")).strip_edges()
	if summary.is_empty():
		summary = "Map constructor change: %s" % action
	var details: Dictionary = Dictionary(payload.get("details", {})).duplicate(true)
	var undo_hint: String = String(payload.get("undo_hint", "")).strip_edges()
	var row: Dictionary = {
		"seq": _map_constructor_change_history_seq,
		"timestamp": Time.get_datetime_string_from_system(true, true),
		"action_type": action,
		"entity_kind": entity_kind,
		"entity_id": entity_id,
		"object_type": object_type,
		"cell": cell,
		"summary": summary,
		"details": details,
		"undo_hint": undo_hint
	}
	_map_constructor_change_history_seq += 1
	_map_constructor_change_history.append(row)
	while _map_constructor_change_history.size() > 200:
		_map_constructor_change_history.remove_at(0)

func get_map_constructor_change_history(limit: int = 50) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Change history is available only in TASK TEST constructor mode.", "history": [], "total_count": 0}
	var total_count: int = _map_constructor_change_history.size()
	var safe_limit: int = maxi(1, limit)
	var start: int = maxi(0, total_count - safe_limit)
	var rows: Array[Dictionary] = []
	for i in range(start, total_count):
		rows.append(Dictionary(_map_constructor_change_history[i]).duplicate(true))
	return {"ok": true, "message": "Change history ready.", "history": rows, "total_count": total_count}

func clear_map_constructor_change_history() -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Change history clear is available only in TASK TEST constructor mode.", "cleared_count": 0}
	var cleared_count: int = _map_constructor_change_history.size()
	_map_constructor_change_history.clear()
	return {"ok": true, "message": "Change history cleared.", "cleared_count": cleared_count}

func _get_map_constructor_overview_tile_kind(tile_type: int) -> String:
	if tile_type == GridManager.TILE_FLOOR or tile_type == GridManager.TILE_STEPPED_FLOOR:
		return "floor"
	if tile_type == GridManager.TILE_WALL:
		return "wall"
	if tile_type == GridManager.TILE_DOOR or tile_type == GridManager.TILE_DIGITAL_DOOR:
		return "door"
	if tile_type == GridManager.TILE_POWERED_GATE:
		return "gate"
	if tile_type == GridManager.TILE_BLOCKED:
		return "blocked"
	return "unknown"

func _map_constructor_overview_object_matches_tags(object_data: Dictionary, tags: Array[String]) -> bool:
	var values: Array[String] = [
		String(object_data.get("object_group", "")).to_lower(),
		String(object_data.get("category", "")).to_lower(),
		String(object_data.get("object_type", "")).to_lower(),
		String(object_data.get("map_constructor_prefab_id", "")).to_lower(),
		String(object_data.get("prefab_id", "")).to_lower()
	]
	for value in values:
		if value.is_empty():
			continue
		for tag in tags:
			if value == tag or value.find(tag) >= 0:
				return true
	return false

func get_map_constructor_overview_data(options: Dictionary = {}) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Overview is available only in TASK TEST constructor mode.", "map_size": Vector2i.ZERO, "cells": [], "markers": [], "summary": {}, "legend": []}
	if grid_manager == null or not grid_manager.has_method("get_width") or not grid_manager.has_method("get_height") or not grid_manager.has_method("get_tile"):
		return {"ok": false, "message": "Grid unavailable.", "map_size": Vector2i.ZERO, "cells": [], "markers": [], "summary": {}, "legend": []}
	var width: int = int(grid_manager.call("get_width"))
	var height: int = int(grid_manager.call("get_height"))
	var cells: Array[Dictionary] = []
	var markers: Array[Dictionary] = []
	var selected_keys: Dictionary = {}
	for row_variant in Array(options.get("selected_entities", [])):
		var row: Dictionary = Dictionary(row_variant)
		var sk: String = "%s|%s" % [String(row.get("entity_kind", "")), String(row.get("entity_id", ""))]
		if not sk.ends_with("|"):
			selected_keys[sk] = true
	var sid: String = String(options.get("selected_entity_id", ""))
	var skind: String = String(options.get("selected_entity_kind", ""))
	if not sid.is_empty():
		selected_keys["%s|%s" % [skind, sid]] = true
	var issues: Array[Dictionary] = get_map_constructor_validation_issues() if bool(options.get("include_validation", true)) else []
	var include_power: bool = bool(options.get("include_power", true))
	var include_items: bool = bool(options.get("include_items", true))
	var include_wall_mounted: bool = bool(options.get("include_wall_mounted", true))
	var issue_by_cell: Dictionary = {}
	for iv in issues:
		var issue: Dictionary = Dictionary(iv)
		var c: Vector2i = Vector2i(issue.get("cell", Vector2i(-1, -1)))
		var key: String = _serialize_cell_key(c)
		if not issue_by_cell.has(key):
			issue_by_cell[key] = []
		issue_by_cell[key].append(issue)
		var sev: String = String(issue.get("severity", "error"))
		markers.append({"id":"issue_%s" % String(issue.get("id", key)), "kind":"warning" if sev == "warning" else "validation_issue", "label":String(issue.get("code", sev)), "cell":c, "entity_kind":String(issue.get("entity_kind", "")), "entity_id":String(issue.get("entity_id", "")), "status":"warning" if sev == "warning" else "error", "message":String(issue.get("message", ""))})
	var object_count: int = 0
	var item_count: int = 0
	var wall_mounted_count: int = 0
	var selected_count: int = 0
	var visible_cells: int = 0
	for y in range(height):
		for x in range(width):
			var cell: Vector2i = Vector2i(x, y)
			var cell_key: String = _serialize_cell_key(cell)
			var tile_type: int = int(grid_manager.call("get_tile", cell))
			var objects_here: Array = Array(world_objects_by_cell.get(cell, []))
			var items_here: Array = Array(cell_items.get(cell, []))
			var has_wall_mounted: bool = false
			var has_power: bool = false
			var has_terminal: bool = false
			var has_door: bool = false
			var has_selected: bool = false
			for ov in objects_here:
				if not (ov is Dictionary):
					continue
				var od: Dictionary = Dictionary(ov)
				var oid: String = String(od.get("id", ""))
				if bool(od.get("is_wall_mounted", false)):
					has_wall_mounted = true
				var og: String = String(od.get("object_group", "")).to_lower()
				if og == "power" or _map_constructor_overview_object_matches_tags(od, ["power", "fuse", "breaker", "cable"]):
					has_power = true
				if og == "terminal" or _map_constructor_overview_object_matches_tags(od, ["terminal", "console"]):
					has_terminal = true
				if og == "door" or _map_constructor_overview_object_matches_tags(od, ["door", "gate"]):
					has_door = true
				if selected_keys.has("world_object|%s" % oid):
					has_selected = true
					markers.append({"id":"selected_world_%s" % oid, "kind":"selected", "label":"Selected object", "cell":cell, "entity_kind":"world_object", "entity_id":oid, "status":"info", "message":"Selected object."})
			for it in items_here:
				if not (it is Dictionary):
					continue
				var iid: String = String(Dictionary(it).get("id", ""))
				if selected_keys.has("item|%s" % iid):
					has_selected = true
					markers.append({"id":"selected_item_%s" % iid, "kind":"selected", "label":"Selected item", "cell":cell, "entity_kind":"item", "entity_id":iid, "status":"info", "message":"Selected item."})
			var cell_issues: Array = Array(issue_by_cell.get(cell_key, []))
			var has_warning: bool = false
			var has_error: bool = false
			for iv in cell_issues:
				var sev: String = String(Dictionary(iv).get("severity", "error"))
				has_warning = has_warning or sev == "warning"
				has_error = has_error or sev != "warning"
			var has_expected_invalid: bool = false
			for ov2 in objects_here:
				var od2: Dictionary = Dictionary(ov2)
				var oid2: String = String(od2.get("id", ""))
				if not oid2.is_empty() and is_task_test_expected_invalid_object_id(oid2):
					has_expected_invalid = true
					markers.append({"id":"expected_%s" % oid2, "kind":"expected_invalid", "label":"Expected invalid", "cell":cell, "entity_kind":"world_object", "entity_id":oid2, "status":"expected_invalid", "message":"Expected invalid object."})
			var visible: bool = grid_manager.has_method("is_cell_visible") and bool(grid_manager.call("is_cell_visible", cell))
			if not has_door:
				var tile_kind: String = _get_map_constructor_overview_tile_kind(tile_type)
				has_door = tile_kind == "door" or tile_kind == "gate"
			visible_cells += 1 if visible else 0
			var density: int = objects_here.size() + items_here.size()
			cells.append({"cell":cell, "tile_type":tile_type, "tile_kind":_get_map_constructor_overview_tile_kind(tile_type), "visible":visible, "object_count":objects_here.size(), "item_count":items_here.size(), "has_world_object":objects_here.size() > 0, "has_item":items_here.size() > 0, "has_wall_mounted":has_wall_mounted, "has_power":has_power, "has_terminal":has_terminal, "has_door":has_door, "has_validation_issue":has_error, "has_warning":has_warning, "has_expected_invalid":has_expected_invalid, "has_selected":has_selected, "density":density})
			object_count += objects_here.size(); item_count += items_here.size()
			if has_wall_mounted:
				wall_mounted_count += 1
				if include_wall_mounted:
					markers.append({"id":"wall_mounted_%s" % cell_key, "kind":"wall_mounted", "label":"Wall-mounted", "cell":cell, "entity_kind":"", "entity_id":"", "status":"info", "message":"Wall-mounted object in cell."})
			if has_selected: selected_count += 1
			if objects_here.size() > 0:
				markers.append({"id":"object_%s" % cell_key, "kind":"object", "label":"Object", "cell":cell, "entity_kind":"", "entity_id":"", "status":"info", "message":"Object in cell."})
			if include_items and items_here.size() > 0:
				markers.append({"id":"item_%s" % cell_key, "kind":"item", "label":"Item", "cell":cell, "entity_kind":"", "entity_id":"", "status":"info", "message":"Item in cell."})
			if include_power and has_power:
				markers.append({"id":"power_%s" % cell_key, "kind":"power", "label":"Power", "cell":cell, "entity_kind":"", "entity_id":"", "status":"info", "message":"Power object in cell."})
			if has_terminal: markers.append({"id":"terminal_%s" % cell_key, "kind":"terminal", "label":"Terminal", "cell":cell, "entity_kind":"", "entity_id":"", "status":"info", "message":"Terminal in cell."})
			if has_door:
				markers.append({"id":"door_%s" % cell_key, "kind":"door", "label":"Door/Gate", "cell":cell, "entity_kind":"", "entity_id":"", "status":"info", "message":"Door or gate in cell."})
	if bool(options.get("include_history", true)):
		var history: Array = Array(get_map_constructor_change_history(int(options.get("max_history_markers", 20))).get("history", []))
		for rowv in history:
			var row: Dictionary = Dictionary(rowv)
			var hcell: Vector2i = Vector2i(row.get("cell", Vector2i(-1, -1)))
			if hcell.x >= 0 and hcell.y >= 0:
				markers.append({"id":"history_%s" % String(row.get("seq", "")), "kind":"history", "label":String(row.get("action_type", "change")), "cell":hcell, "entity_kind":String(row.get("entity_kind", "")), "entity_id":String(row.get("entity_id", "")), "status":"info", "message":String(row.get("summary", ""))})
	var readiness: Dictionary = get_map_constructor_mission_readiness_report()
	var summary: Dictionary = {"width":width, "height":height, "visible_cells":visible_cells, "object_count":object_count, "item_count":item_count, "wall_mounted_count":wall_mounted_count, "validation_issue_count":issues.size(), "error_count":int(Dictionary(readiness.get("summary", {})).get("error_count", 0)), "warning_count":int(Dictionary(readiness.get("summary", {})).get("warning_count", 0)), "expected_invalid_count":0, "selected_count":selected_count}
	for m in markers:
		if String(Dictionary(m).get("kind", "")) == "expected_invalid":
			summary["expected_invalid_count"] = int(summary.get("expected_invalid_count", 0)) + 1
	return {"ok": true, "message": "Overview ready.", "map_size": Vector2i(width, height), "cells": cells, "markers": markers, "summary": summary, "legend": [{"symbol":".","kind":"floor"},{"symbol":"#","kind":"wall"},{"symbol":"D","kind":"door"},{"symbol":"T","kind":"terminal"},{"symbol":"P","kind":"power"},{"symbol":"I","kind":"item"},{"symbol":"W","kind":"wall_mounted"},{"symbol":"!","kind":"error"},{"symbol":"?","kind":"warning"},{"symbol":"*","kind":"selected"},{"symbol":"X","kind":"expected_invalid"}]}

func _map_constructor_is_protected_id(entity_id: String) -> bool:
	var normalized: String = entity_id.strip_edges().to_lower()
	return normalized == "bipob" or normalized == "start_marker" or normalized == "exit_marker"

func _map_constructor_cell_from_variant(cell_variant: Variant) -> Vector2i:
	if cell_variant is Vector2i:
		return Vector2i(cell_variant)
	if cell_variant is Dictionary:
		var cell_dict: Dictionary = cell_variant
		if cell_dict.has("x") and cell_dict.has("y"):
			return Vector2i(int(cell_dict.get("x", -1)), int(cell_dict.get("y", -1)))
	if cell_variant is Array:
		var arr: Array = cell_variant
		if arr.size() >= 2:
			return Vector2i(int(arr[0]), int(arr[1]))
	if cell_variant is String:
		var text: String = String(cell_variant).strip_edges()
		if text.begins_with("(") and text.ends_with(")"):
			var parts: PackedStringArray = text.substr(1, text.length() - 2).split(",")
			if parts.size() == 2:
				return Vector2i(int(parts[0].strip_edges()), int(parts[1].strip_edges()))
	return Vector2i(-1, -1)

func export_map_constructor_runtime_patch() -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Runtime patch export works only in TASK TEST constructor mode.", "patch": {}, "json": "", "object_count": 0, "item_count": 0, "tile_edit_count": 0}
	var patch: Dictionary = {"schema_version": MAP_CONSTRUCTOR_PATCH_SCHEMA_VERSION, "mission_id": "mission_10", "created_at_runtime": str(Time.get_unix_time_from_system()), "source": "task_test_map_constructor", "objects": [], "items": [], "tile_edits": [], "links": [], "metadata": {}}
	for object_data in mission_world_objects:
		if not bool(object_data.get("created_by_map_constructor", false)):
			continue
		var object_id: String = String(object_data.get("id", "")).strip_edges()
		if object_id.is_empty() or _map_constructor_is_protected_id(object_id):
			continue
		var row: Dictionary = Dictionary(object_data).duplicate(true)
		row["position"] = _serialize_cell_key(Vector2i(row.get("position", Vector2i(-1, -1))))
		patch["objects"].append(row)
	for cell_variant in cell_items.keys():
		var cell: Vector2i = Vector2i(cell_variant)
		for item_variant in Array(cell_items.get(cell_variant, [])):
			if not (item_variant is Dictionary):
				continue
			var item: Dictionary = Dictionary(item_variant)
			if not bool(item.get("created_by_map_constructor", false)):
				continue
			var item_id: String = String(item.get("id", "")).strip_edges()
			if item_id.is_empty() or _map_constructor_is_protected_id(item_id):
				continue
			var item_row: Dictionary = item.duplicate(true)
			item_row["cell"] = _serialize_cell_key(cell)
			patch["items"].append(item_row)
	var json_text: String = JSON.stringify(patch, "\t")
	return {"ok": true, "message": "Runtime patch exported.", "patch": patch, "json": json_text, "object_count": Array(patch.get("objects", [])).size(), "item_count": Array(patch.get("items", [])).size(), "tile_edit_count": 0}

func parse_map_constructor_patch_json(patch_json: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(patch_json)
	if not (parsed is Dictionary):
		return {"ok": false, "message": "Invalid patch JSON.", "patch": {}, "warnings": []}
	var patch: Dictionary = Dictionary(parsed).duplicate(true)
	if int(patch.get("schema_version", 0)) != MAP_CONSTRUCTOR_PATCH_SCHEMA_VERSION:
		return {"ok": false, "message": "Unsupported patch schema_version.", "patch": {}, "warnings": []}
	if String(patch.get("mission_id", "")) != String(current_mission_id):
		return {"ok": false, "message": "Patch mission_id mismatch.", "patch": {}, "warnings": []}
	for row_variant in Array(patch.get("objects", [])):
		if row_variant is Dictionary:
			var row: Dictionary = row_variant
			row["position"] = _map_constructor_cell_from_variant(row.get("position", Vector2i(-1, -1)))
			row["anchor_floor_cell"] = _map_constructor_cell_from_variant(row.get("anchor_floor_cell", Vector2i(-1, -1)))
			row["attached_wall_cell"] = _map_constructor_cell_from_variant(row.get("attached_wall_cell", Vector2i(-1, -1)))
	for row_variant_item in Array(patch.get("items", [])):
		if row_variant_item is Dictionary:
			var row_item: Dictionary = row_variant_item
			row_item["cell"] = _map_constructor_cell_from_variant(row_item.get("cell", Vector2i(-1, -1)))
	return {"ok": true, "message": "Patch parsed.", "patch": patch, "warnings": []}

func _collect_map_constructor_patch_field_changes(current: Dictionary, incoming: Dictionary, entity_kind: String) -> Array[Dictionary]:
	var fields: Array[String] = [
		"object_type", "item_type", "object_group", "state", "position", "cell", "placement_mode", "wall_side",
		"anchor_floor_cell", "attached_wall_cell", "power_network_id", "target_door_id", "target_platform_id",
		"linked_terminal_id", "control_source_id", "connected_device_ids", "required_key_id", "map_constructor_prefab_id"
	]
	if entity_kind == "item":
		fields.erase("position")
	var changes: Array[Dictionary] = []
	for field_name in fields:
		var current_value: Variant = current.get(field_name, null)
		var incoming_value: Variant = incoming.get(field_name, null)
		if field_name == "position" or field_name == "cell" or field_name == "anchor_floor_cell" or field_name == "attached_wall_cell":
			if _map_constructor_cell_from_variant(current_value) == _map_constructor_cell_from_variant(incoming_value):
				continue
		if current_value == incoming_value:
			continue
		changes.append({"field": field_name, "current": current_value, "incoming": incoming_value})
	return changes

func compare_map_constructor_patch(patch: Dictionary) -> Dictionary:
	var diffs: Array[Dictionary] = []
	var warnings: Array[String] = []
	var conflicts: Array[Dictionary] = []
	var will_add: int = 0
	var will_update: int = 0
	var unchanged: int = 0
	for entity_kind in ["world_object", "item"]:
		var patch_rows: Array = Array(patch.get("objects" if entity_kind == "world_object" else "items", []))
		for row_variant in patch_rows:
			if not (row_variant is Dictionary):
				continue
			var row: Dictionary = Dictionary(row_variant)
			var entity_id: String = String(row.get("id", "")).strip_edges()
			if entity_kind == "world_object":
				row["position"] = _map_constructor_cell_from_variant(row.get("position", Vector2i(-1, -1)))
			else:
				row["cell"] = _map_constructor_cell_from_variant(row.get("cell", Vector2i(-1, -1)))
			if entity_id.is_empty() or _map_constructor_is_protected_id(entity_id):
				conflicts.append({"change_type":"conflict", "entity_kind":entity_kind, "id":entity_id, "message":"Missing/protected id."})
				continue
			var current_info: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
			if not bool(current_info.get("ok", false)):
				if entity_kind == "item":
					var incoming_cell: Vector2i = _map_constructor_cell_from_variant(row.get("cell", Vector2i(-1, -1)))
					if incoming_cell != Vector2i(-1, -1) and not Array(cell_items.get(incoming_cell, [])).is_empty():
						warnings.append("Item id %s not found; cell %s already contains items." % [entity_id, _serialize_cell_key(incoming_cell)])
				diffs.append({"change_type":"add", "entity_kind":entity_kind, "id":entity_id, "cell":row.get("position" if entity_kind == "world_object" else "cell", Vector2i(-1, -1)), "field_changes":[], "message":"Will add %s." % ("object" if entity_kind == "world_object" else "item")})
				will_add += 1
				continue
			var current: Dictionary = Dictionary(current_info.get("data", {}))
			if current.is_empty():
				current = Dictionary(current_info.get("entity", {}))
			if not bool(current.get("created_by_map_constructor", false)):
				conflicts.append({"change_type":"conflict", "entity_kind":entity_kind, "id":entity_id, "message":"ID belongs to non-constructor %s." % ("object" if entity_kind == "world_object" else "item")})
				continue
			if entity_kind == "item":
				current["cell"] = Vector2i(current_info.get("cell", Vector2i(-1, -1)))
			var field_changes: Array[Dictionary] = _collect_map_constructor_patch_field_changes(current, row, entity_kind)
			if field_changes.is_empty():
				unchanged += 1
				diffs.append({"change_type":"unchanged", "entity_kind":entity_kind, "id":entity_id, "cell":row.get("position" if entity_kind == "world_object" else "cell", Vector2i(-1, -1)), "field_changes":[], "message":"No changes."})
			else:
				will_update += 1
				diffs.append({"change_type":"update", "entity_kind":entity_kind, "id":entity_id, "cell":row.get("position" if entity_kind == "world_object" else "cell", Vector2i(-1, -1)), "field_changes":field_changes, "message":"Will update %s." % ("object" if entity_kind == "world_object" else "item")})
	var summary: Dictionary = {"will_add": will_add, "will_update": will_update, "will_delete": 0, "unchanged": unchanged, "conflicts": conflicts.size(), "warnings": warnings.size()}
	return {"ok": true, "message": "Patch compare complete.", "summary": summary, "diffs": diffs, "warnings": warnings, "conflicts": conflicts}

func preview_apply_map_constructor_patch(patch: Dictionary) -> Dictionary:
	var cmp: Dictionary = compare_map_constructor_patch(patch)
	return {"ok": bool(cmp.get("ok", false)), "message": String(cmp.get("message", "")), "can_apply": Array(cmp.get("conflicts", [])).is_empty(), "diffs": Array(cmp.get("diffs", [])), "warnings": Array(cmp.get("warnings", [])), "conflicts": Array(cmp.get("conflicts", [])), "summary": Dictionary(cmp.get("summary", {}))}

func apply_map_constructor_patch(patch: Dictionary, options: Dictionary = {}) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Patch apply works only in TASK TEST constructor mode.", "applied_count": 0, "added_count": 0, "updated_count": 0, "deleted_count": 0, "warnings": [], "conflicts": [], "patch_id": ""}
	var preview: Dictionary = preview_apply_map_constructor_patch(patch)
	if not bool(preview.get("ok", false)):
		return {"ok": false, "message": String(preview.get("message", "Preview failed.")), "applied_count": 0, "added_count": 0, "updated_count": 0, "deleted_count": 0, "warnings": [], "conflicts": Array(preview.get("conflicts", [])), "patch_id": ""}
	var warnings: Array[String] = Array(preview.get("warnings", [])).duplicate()
	if not bool(options.get("allow_conflicts", false)) and not bool(preview.get("can_apply", false)):
		return {"ok": false, "message": "Patch has conflicts.", "applied_count": 0, "added_count": 0, "updated_count": 0, "deleted_count": 0, "warnings": warnings, "conflicts": Array(preview.get("conflicts", [])), "patch_id": ""}
	_map_constructor_last_patch_snapshot = {"patch_id":"patch_%d" % int(Time.get_unix_time_from_system()), "mission_world_objects": mission_world_objects.duplicate(true), "cell_items": cell_items.duplicate(true), "world_objects_by_cell": world_objects_by_cell.duplicate(true)}
	var added_count: int = 0
	var updated_count: int = 0
	var allow_adds: bool = bool(options.get("allow_adds", true))
	var allow_updates: bool = bool(options.get("allow_updates", true))
	for diff_variant in Array(preview.get("diffs", [])):
		if not (diff_variant is Dictionary):
			continue
		var diff: Dictionary = Dictionary(diff_variant)
		var change_type: String = String(diff.get("change_type", ""))
		if change_type == "add" and not allow_adds:
			warnings.append("Skipped add for %s %s: allow_adds=false" % [String(diff.get("entity_kind", "entity")), String(diff.get("id", ""))])
			continue
		if change_type == "update" and not allow_updates:
			warnings.append("Skipped update for %s %s: allow_updates=false" % [String(diff.get("entity_kind", "entity")), String(diff.get("id", ""))])
			continue
		if change_type != "add" and change_type != "update":
			continue
		var entity_kind: String = String(diff.get("entity_kind", ""))
		var entity_id: String = String(diff.get("id", "")).strip_edges()
		if entity_id.is_empty() or _map_constructor_is_protected_id(entity_id):
			continue
		var source_rows: Array = Array(patch.get("objects" if entity_kind == "world_object" else "items", []))
		var incoming_row: Dictionary = {}
		for row_variant in source_rows:
			if row_variant is Dictionary and String(Dictionary(row_variant).get("id", "")).strip_edges() == entity_id:
				incoming_row = Dictionary(row_variant).duplicate(true)
				break
		if incoming_row.is_empty():
			warnings.append("Skipped %s %s: source row missing." % [entity_kind, entity_id])
			continue
		if entity_kind == "world_object":
			var pos: Vector2i = _map_constructor_cell_from_variant(incoming_row.get("position", Vector2i(-1, -1)))
			incoming_row["position"] = pos
			if change_type == "update":
				_remove_map_constructor_entity_by_id("world_object", entity_id)
				updated_count += 1
			else:
				added_count += 1
			set_world_object_at_cell(pos, incoming_row)
		elif entity_kind == "item":
			var cell: Vector2i = _map_constructor_cell_from_variant(incoming_row.get("cell", Vector2i(-1, -1)))
			if change_type == "update":
				_remove_map_constructor_entity_by_id("item", entity_id)
				updated_count += 1
			else:
				added_count += 1
			incoming_row.erase("cell")
			add_item_at_cell(cell, incoming_row)
	PowerSystemRef.recalculate_network(mission_world_objects, "task_test_power_main")
	refresh_world_cooling_received()
	var patch_id: String = String(_map_constructor_last_patch_snapshot.get("patch_id", ""))
	var summary_data: Dictionary = Dictionary(preview.get("summary", {}))
	_record_map_constructor_change("patch_apply", {"summary":"Applied patch: +%d / ~%d / -0" % [added_count, updated_count], "details":{"patch_id":patch_id, "added_count":added_count, "updated_count":updated_count, "summary":summary_data}, "undo_hint":"Use Rollback Last Patch."})
	return {"ok": true, "message": "Patch applied.", "applied_count": added_count + updated_count, "added_count": added_count, "updated_count": updated_count, "deleted_count": 0, "warnings": warnings, "conflicts": Array(preview.get("conflicts", [])), "patch_id": patch_id}

func rollback_last_map_constructor_patch() -> Dictionary:
	if _map_constructor_last_patch_snapshot.is_empty():
		return {"ok": false, "message": "No patch to rollback."}
	mission_world_objects = Array(_map_constructor_last_patch_snapshot.get("mission_world_objects", [])).duplicate(true)
	cell_items = Dictionary(_map_constructor_last_patch_snapshot.get("cell_items", {})).duplicate(true)
	world_objects_by_cell = Dictionary(_map_constructor_last_patch_snapshot.get("world_objects_by_cell", {})).duplicate(true)
	_map_constructor_last_patch_snapshot.clear()
	PowerSystemRef.recalculate_network(mission_world_objects, "task_test_power_main")
	refresh_world_cooling_received()
	_record_map_constructor_change("patch_rollback", {"summary":"Rolled back last patch", "undo_hint":"Apply patch again if needed."})
	return {"ok": true, "message": "Last patch rolled back."}

func create_map_constructor_empty_map(width: int, height: int) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Constructor map build works only in TASK TEST constructor mode."}
	constructor_map_width = maxi(6, width)
	constructor_map_height = maxi(6, height)
	mission_world_objects.clear()
	world_objects_by_cell.clear()
	cell_items.clear()
	constructor_start_marker.clear()
	constructor_exit_marker.clear()
	if grid_manager != null and grid_manager.has_method("build_constructor_map"):
		var grid_result: Dictionary = grid_manager.call("build_constructor_map", constructor_map_width, constructor_map_height)
		constructor_map_width = int(grid_result.get("width", constructor_map_width))
		constructor_map_height = int(grid_result.get("height", constructor_map_height))
	if grid_manager != null and grid_manager.has_method("enforce_boundary_walls"):
		grid_manager.call("enforce_boundary_walls")
	if grid_manager != null and grid_manager.has_method("request_visual_refresh"):
		grid_manager.call("request_visual_refresh")
	return {"ok": true, "message": "Constructor map created.", "width": constructor_map_width, "height": constructor_map_height}

func get_inside_cell_for_boundary_marker(cell: Vector2i) -> Dictionary:
	if grid_manager == null or not grid_manager.has_method("is_boundary_cell"):
		return {"ok": false, "inside_cell": Vector2i(-1, -1), "side": "", "message": "Grid is unavailable."}
	if not bool(grid_manager.call("is_boundary_cell", cell)):
		return {"ok": false, "inside_cell": Vector2i(-1, -1), "side": "", "message": "Marker cell must be on map boundary."}
	var width: int = int(grid_manager.call("get_width"))
	var height: int = int(grid_manager.call("get_height"))
	if (cell.x == 0 or cell.x == width - 1) and (cell.y == 0 or cell.y == height - 1):
		return {"ok": false, "inside_cell": Vector2i(-1, -1), "side": "", "message": "corner markers are not supported yet"}
	if cell.x == 0:
		return {"ok": true, "inside_cell": Vector2i(1, cell.y), "side": "west", "message": "Start marker set."}
	if cell.x == width - 1:
		return {"ok": true, "inside_cell": Vector2i(width - 2, cell.y), "side": "east", "message": "Start marker set."}
	if cell.y == 0:
		return {"ok": true, "inside_cell": Vector2i(cell.x, 1), "side": "north", "message": "Start marker set."}
	return {"ok": true, "inside_cell": Vector2i(cell.x, height - 2), "side": "south", "message": "Start marker set."}

func _set_constructor_marker(marker_type: String, cell: Vector2i) -> Dictionary:
	var inside_info: Dictionary = get_inside_cell_for_boundary_marker(cell)
	if not bool(inside_info.get("ok", false)):
		return {"ok": false, "message": String(inside_info.get("message", "Marker placement failed."))}
	var inside_cell: Vector2i = Vector2i(inside_info.get("inside_cell", Vector2i(-1, -1)))
	if grid_manager == null or int(grid_manager.call("get_tile", inside_cell)) == GridManager.TILE_WALL:
		return {"ok": false, "message": "Inside marker cell is invalid."}
	var marker: Dictionary = {"cell": _serialize_cell_key(cell), "inside_cell": _serialize_cell_key(inside_cell), "side": String(inside_info.get("side", ""))}
	if marker_type == "start":
		constructor_start_marker = marker
		return {"ok": true, "message": "Start marker set.", "marker": marker}
	constructor_exit_marker = marker
	return {"ok": true, "message": "Exit marker set.", "marker": marker}

func set_map_constructor_start_marker(cell: Vector2i) -> Dictionary:
	return _set_constructor_marker("start", cell)

func set_map_constructor_exit_marker(cell: Vector2i) -> Dictionary:
	return _set_constructor_marker("exit", cell)

func clear_map_constructor_start_marker() -> Dictionary:
	constructor_start_marker.clear()
	return {"ok": true, "message": "Start marker cleared."}

func clear_map_constructor_exit_marker() -> Dictionary:
	constructor_exit_marker.clear()
	return {"ok": true, "message": "Exit marker cleared."}

func get_map_constructor_mission_markers() -> Dictionary:
	return {"start": Dictionary(constructor_start_marker).duplicate(true), "exit": Dictionary(constructor_exit_marker).duplicate(true)}

func _sanitize_map_constructor_preset_name(raw_name: String) -> String:
	var value: String = raw_name.strip_edges().to_lower().replace(" ", "_")
	var result: String = ""
	for i in range(value.length()):
		var ch: String = value.substr(i, 1)
		if ch.unicode_at(0) >= 97 and ch.unicode_at(0) <= 122:
			result += ch
		elif ch.unicode_at(0) >= 48 and ch.unicode_at(0) <= 57:
			result += ch
		elif ch == "_" or ch == "-":
			result += ch
	if result.is_empty():
		return "preset"
	return result

func _get_map_constructor_preset_path(preset_name: String) -> String:
	return "%s/%s.json" % [MAP_CONSTRUCTOR_PRESET_DIR, _sanitize_map_constructor_preset_name(preset_name)]

func _get_map_constructor_mission_patch_path(patch_name: String) -> String:
	return "%s/%s.json" % [MAP_CONSTRUCTOR_MISSION_PATCH_DIR, _sanitize_map_constructor_preset_name(patch_name)]

func get_map_constructor_mission_patch_data(patch_name: String = "") -> Dictionary:
	var sanitized_name: String = _sanitize_map_constructor_preset_name(patch_name)
	var preset_data: Dictionary = get_map_constructor_preset_data()
	var validation_overlay: Dictionary = get_map_constructor_validation_overlay()
	var summary: Dictionary = Dictionary(validation_overlay.get("summary", {}))
	var audit_summary: Dictionary = {}
	if has_method("get_map_constructor_audit_summary"):
		audit_summary = get_map_constructor_audit_summary()
	summary["audit"] = audit_summary
	var validation: Dictionary = {
		"ok": bool(validation_overlay.get("ok", false)),
		"summary": summary
	}
	var final_name: String = sanitized_name
	if final_name.is_empty():
		final_name = "patch"
	return {
		"version": 1,
		"patch_type": "task_test_constructor_mission_patch",
		"source_mission_id": String(preset_data.get("mission_id", "mission_10")),
		"patch_name": final_name,
		"created_at_unix": int(Time.get_unix_time_from_system()),
		"world_objects": Array(preset_data.get("world_objects", [])),
		"cell_items": Array(preset_data.get("cell_items", [])),
		"map": Dictionary(preset_data.get("map", {})).duplicate(true),
		"mission_markers": Dictionary(preset_data.get("mission_markers", {})).duplicate(true),
		"grid_tiles": Array(preset_data.get("grid_tiles", [])).duplicate(true),
		"grid_overrides": Array(preset_data.get("grid_overrides", [])),
		"validation": validation,
		"notes": "TASK TEST constructor mission patch export"
	}

func export_map_constructor_mission_patch(patch_name: String) -> Dictionary:
	var sanitized_name: String = _sanitize_map_constructor_preset_name(patch_name)
	var path: String = _get_map_constructor_mission_patch_path(sanitized_name)
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Mission patch export works only in TASK TEST constructor mode.", "path": path, "patch_name": sanitized_name}
	var dir_result: Error = DirAccess.make_dir_recursive_absolute(MAP_CONSTRUCTOR_MISSION_PATCH_DIR)
	if dir_result != OK and dir_result != ERR_ALREADY_EXISTS:
		return {"ok": false, "message": "Mission patch export failed: cannot create patch directory.", "path": path, "patch_name": sanitized_name}
	var patch_data: Dictionary = get_map_constructor_mission_patch_data(sanitized_name)
	var validation: Dictionary = Dictionary(patch_data.get("validation", {}))
	var validation_summary: Dictionary = Dictionary(validation.get("summary", {}))
	var validation_error_count: int = int(validation_summary.get("error_count", 0))
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "Mission patch export failed: cannot open file.", "path": path, "patch_name": sanitized_name}
	file.store_string(JSON.stringify(patch_data, "	"))
	file.close()
	var message: String = "Mission patch '%s' exported." % sanitized_name
	if validation_error_count > 0:
		message = "%s Exported with validation errors: %d" % [message, validation_error_count]
	return {"ok": true, "message": message, "path": path, "patch_name": sanitized_name}

func list_map_constructor_mission_patches() -> Array[Dictionary]:
	var patches: Array[Dictionary] = []
	var dir: DirAccess = DirAccess.open(MAP_CONSTRUCTOR_MISSION_PATCH_DIR)
	if dir == null:
		return patches
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.to_lower().ends_with(".json"):
			var name: String = file_name.substr(0, file_name.length() - 5)
			var full_path: String = "%s/%s" % [MAP_CONSTRUCTOR_MISSION_PATCH_DIR, file_name]
			patches.append({"name": name, "path": full_path, "modified_unix": int(FileAccess.get_modified_time(full_path))})
		file_name = dir.get_next()
	dir.list_dir_end()
	patches.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("name", "")) < String(b.get("name", ""))
	)
	return patches

func delete_map_constructor_mission_patch(patch_name: String) -> Dictionary:
	var sanitized_name: String = _sanitize_map_constructor_preset_name(patch_name)
	var path: String = _get_map_constructor_mission_patch_path(sanitized_name)
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Mission patch delete works only in TASK TEST constructor mode.", "patch_name": sanitized_name}
	if not FileAccess.file_exists(path):
		return {"ok": false, "message": "Mission patch delete failed: file not found.", "patch_name": sanitized_name}
	var dir: DirAccess = DirAccess.open(MAP_CONSTRUCTOR_MISSION_PATCH_DIR)
	if dir == null:
		return {"ok": false, "message": "Mission patch delete failed: directory unavailable.", "patch_name": sanitized_name}
	var err: Error = dir.remove("%s.json" % sanitized_name)
	if err != OK:
		return {"ok": false, "message": "Mission patch delete failed.", "patch_name": sanitized_name}
	return {"ok": true, "message": "Mission patch '%s' deleted." % sanitized_name, "patch_name": sanitized_name}

func get_map_constructor_preset_data() -> Dictionary:
	var world_objects_export: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if object_data is Dictionary:
			var serialized_object: Dictionary = Dictionary(object_data).duplicate(true)
			var object_cell: Vector2i = _deserialize_cell_variant(serialized_object.get("position", Vector2i(-1, -1)))
			serialized_object["position"] = _serialize_cell_key(object_cell)
			world_objects_export.append(serialized_object)
	var cell_items_export: Array[Dictionary] = []
	for cell_variant in cell_items.keys():
		var cell: Vector2i = Vector2i(cell_variant)
		cell_items_export.append({
			"cell": _serialize_cell_key(cell),
			"items": get_items_at_cell(cell)
		})
	var grid_tiles: Array[Dictionary] = []
	var grid_overrides: Array[Dictionary] = []
	if grid_manager != null and grid_manager.has_method("get_width") and grid_manager.has_method("get_height") and grid_manager.has_method("get_tile"):
		constructor_map_width = int(grid_manager.call("get_width"))
		constructor_map_height = int(grid_manager.call("get_height"))
		for y in range(constructor_map_height):
			for x in range(constructor_map_width):
				var tile_cell: Vector2i = Vector2i(x, y)
				var tile_type: int = int(grid_manager.call("get_tile", tile_cell))
				grid_tiles.append({"cell": _serialize_cell_key(tile_cell), "tile_type": tile_type})
				var expected_type: int = GridManager.TILE_WALL if bool(grid_manager.call("is_boundary_cell", tile_cell)) else GridManager.TILE_FLOOR
				if tile_type != expected_type:
					grid_overrides.append({"cell": _serialize_cell_key(tile_cell), "tile_type": tile_type})
	return {
		"version": 1,
		"mission_id": String(current_mission_id),
		"saved_at_unix": Time.get_unix_time_from_system(),
		"world_objects": world_objects_export,
		"cell_items": cell_items_export,
		"map": {"width": constructor_map_width, "height": constructor_map_height, "boundary_wall_type": "outer_wall"},
		"mission_markers": get_map_constructor_mission_markers(),
		"grid_tiles": grid_tiles,
		"grid_overrides": grid_overrides,
		"notes": "TASK TEST constructor preset",
		"warnings": []
	}

func _validate_constructor_marker(marker: Dictionary, marker_name: String) -> Dictionary:
	if marker.is_empty():
		return {"ok": false, "message": "%s marker missing." % marker_name.capitalize()}
	var marker_cell: Vector2i = _deserialize_cell_variant(marker.get("cell", "-1,-1"))
	var inside_cell: Vector2i = _deserialize_cell_variant(marker.get("inside_cell", "-1,-1"))
	if grid_manager == null or not grid_manager.has_method("is_boundary_cell"):
		return {"ok": false, "message": "%s marker validation failed: grid unavailable." % marker_name.capitalize()}
	if not bool(grid_manager.call("is_boundary_cell", marker_cell)):
		return {"ok": false, "message": "%s marker not boundary: %s." % [marker_name.capitalize(), _serialize_cell_key(marker_cell)]}
	var inside_info: Dictionary = get_inside_cell_for_boundary_marker(marker_cell)
	if not bool(inside_info.get("ok", false)):
		return {"ok": false, "message": "%s inside cell invalid: %s." % [marker_name.capitalize(), String(inside_info.get("message", "invalid marker"))]}
	var expected_inside: Vector2i = Vector2i(inside_info.get("inside_cell", Vector2i(-1, -1)))
	if expected_inside != inside_cell:
		return {"ok": false, "message": "%s inside cell invalid: expected %s, got %s." % [marker_name.capitalize(), _serialize_cell_key(expected_inside), _serialize_cell_key(inside_cell)]}
	if int(grid_manager.call("get_tile", inside_cell)) == GridManager.TILE_WALL:
		return {"ok": false, "message": "%s inside cell invalid: %s is wall." % [marker_name.capitalize(), _serialize_cell_key(inside_cell)]}
	return {"ok": true, "message": ""}

func save_map_constructor_preset(preset_name: String) -> Dictionary:
	var sanitized_name: String = _sanitize_map_constructor_preset_name(preset_name)
	var path: String = _get_map_constructor_preset_path(sanitized_name)
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Preset save works only in TASK TEST constructor mode.", "path": path, "preset_name": sanitized_name}
	var dir_result: Error = DirAccess.make_dir_recursive_absolute(MAP_CONSTRUCTOR_PRESET_DIR)
	if dir_result != OK and dir_result != ERR_ALREADY_EXISTS:
		return {"ok": false, "message": "Preset save failed: cannot create preset directory.", "path": path, "preset_name": sanitized_name}
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "Preset save failed: cannot open file.", "path": path, "preset_name": sanitized_name}
	file.store_string(JSON.stringify(get_map_constructor_preset_data(), "\t"))
	file.close()
	return {"ok": true, "message": "Preset '%s' saved." % sanitized_name, "path": path, "preset_name": sanitized_name}

func list_map_constructor_presets() -> Array[Dictionary]:
	var presets: Array[Dictionary] = []
	var dir: DirAccess = DirAccess.open(MAP_CONSTRUCTOR_PRESET_DIR)
	if dir == null:
		return presets
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.to_lower().ends_with(".json"):
			var name: String = file_name.substr(0, file_name.length() - 5)
			var full_path: String = "%s/%s" % [MAP_CONSTRUCTOR_PRESET_DIR, file_name]
			presets.append({"name": name, "path": full_path, "modified_unix": int(FileAccess.get_modified_time(full_path))})
		file_name = dir.get_next()
	dir.list_dir_end()
	presets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("name", "")) < String(b.get("name", ""))
	)
	return presets

func load_map_constructor_preset(preset_name: String) -> Dictionary:
	var sanitized_name: String = _sanitize_map_constructor_preset_name(preset_name)
	var path: String = _get_map_constructor_preset_path(sanitized_name)
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Preset load works only in TASK TEST constructor mode.", "preset_name": sanitized_name}
	if not FileAccess.file_exists(path):
		return {"ok": false, "message": "Preset load failed: file not found.", "preset_name": sanitized_name}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "message": "Preset load failed: cannot open file.", "preset_name": sanitized_name}
	var parse_result: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parse_result is Dictionary):
		return {"ok": false, "message": "Preset load failed: invalid JSON.", "preset_name": sanitized_name}
	var preset: Dictionary = Dictionary(parse_result)
	if int(preset.get("version", 0)) != 1:
		return {"ok": false, "message": "Preset load failed: unsupported version.", "preset_name": sanitized_name}
	if String(preset.get("mission_id", "")) != "mission_10":
		return {"ok": false, "message": "Preset load failed: mission mismatch.", "preset_name": sanitized_name}
	var warnings: Array[String] = []
	var map_data: Dictionary = Dictionary(preset.get("map", {}))
	var map_width: int = int(map_data.get("width", constructor_map_width))
	var map_height: int = int(map_data.get("height", constructor_map_height))
	create_map_constructor_empty_map(map_width, map_height)
	mission_world_objects.clear()
	world_objects_by_cell.clear()
	cell_items.clear()
	for object_variant in Array(preset.get("world_objects", [])):
		if not (object_variant is Dictionary):
			continue
		var object_data: Dictionary = Dictionary(object_variant).duplicate(true)
		var object_id: String = String(object_data.get("id", "<unknown>"))
		var object_cell: Vector2i = _deserialize_cell_variant(object_data.get("position", "-1,-1"))
		if not _is_valid_grid_cell(object_cell):
			warnings.append("Skipped world object %s: invalid cell '%s'." % [object_id, String(object_data.get("position", "-1,-1"))])
			continue
		object_data["position"] = object_cell
		set_world_object_at_cell(object_cell, object_data)
	for cell_entry_variant in Array(preset.get("cell_items", [])):
		if not (cell_entry_variant is Dictionary):
			continue
		var cell_entry: Dictionary = Dictionary(cell_entry_variant)
		var cell_raw: Variant = cell_entry.get("cell", "-1,-1")
		var cell: Vector2i = _deserialize_cell_variant(cell_raw)
		if not _is_valid_grid_cell(cell):
			warnings.append("Skipped cell items entry: invalid cell '%s'." % String(cell_raw))
			continue
		for item_variant in Array(cell_entry.get("items", [])):
			if item_variant is Dictionary:
				add_item_at_cell(cell, Dictionary(item_variant).duplicate(true))
	var loaded_grid_tiles: Array = Array(preset.get("grid_tiles", []))
	for tile_variant in loaded_grid_tiles:
		if not (tile_variant is Dictionary):
			continue
		var tile_row: Dictionary = Dictionary(tile_variant)
		var tile_cell: Vector2i = _deserialize_cell_variant(tile_row.get("cell", "-1,-1"))
		if not _is_valid_grid_cell(tile_cell):
			continue
		if grid_manager != null and grid_manager.has_method("set_tile"):
			grid_manager.call("set_tile", tile_cell, int(tile_row.get("tile_type", GridManager.TILE_FLOOR)))
	if grid_manager != null and grid_manager.has_method("enforce_boundary_walls"):
		grid_manager.call("enforce_boundary_walls")
	var mission_markers: Dictionary = Dictionary(preset.get("mission_markers", {}))
	constructor_start_marker = Dictionary(mission_markers.get("start", {})).duplicate(true)
	constructor_exit_marker = Dictionary(mission_markers.get("exit", {})).duplicate(true)
	PowerSystemRef.recalculate_network(mission_world_objects, "task_test_power_main")
	var networks: Dictionary = {}
	for object_data_variant in mission_world_objects:
		if not (object_data_variant is Dictionary):
			continue
		var network_id: String = String(Dictionary(object_data_variant).get("power_network_id", "")).strip_edges()
		if not network_id.is_empty():
			networks[network_id] = true
	for network_id_variant in networks.keys():
		PowerSystemRef.recalculate_network(mission_world_objects, String(network_id_variant))
	refresh_world_cooling_received()
	return {"ok": true, "message": "Preset '%s' loaded." % sanitized_name, "preset_name": sanitized_name, "warnings": warnings}

func delete_map_constructor_preset(preset_name: String) -> Dictionary:
	var sanitized_name: String = _sanitize_map_constructor_preset_name(preset_name)
	var path: String = _get_map_constructor_preset_path(sanitized_name)
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Preset delete works only in TASK TEST constructor mode.", "preset_name": sanitized_name}
	if not FileAccess.file_exists(path):
		return {"ok": false, "message": "Preset delete failed: file not found.", "preset_name": sanitized_name}
	var dir: DirAccess = DirAccess.open(MAP_CONSTRUCTOR_PRESET_DIR)
	if dir == null:
		return {"ok": false, "message": "Preset delete failed: directory unavailable.", "preset_name": sanitized_name}
	var err: Error = dir.remove("%s.json" % sanitized_name)
	if err != OK:
		return {"ok": false, "message": "Preset delete failed.", "preset_name": sanitized_name}
	return {"ok": true, "message": "Preset '%s' deleted." % sanitized_name, "preset_name": sanitized_name}

func build_task_test_mission_world_objects_for_validation() -> Dictionary:
	var warnings: Array[String] = []
	var objects: Array[Dictionary] = []
	var specs: Array[Dictionary] = [
		# Basic doors
		{"type":"steel_door","id":"task_test_door_open_mechanical","pos":Vector2i(2, 1),"extra":{"state":"open","is_open":true,"is_locked":false}},
		{"type":"steel_door","id":"task_test_door_closed_mechanical","pos":Vector2i(3, 1),"extra":{"state":"closed","is_open":false,"is_locked":false}},
		{"type":"grid_door","id":"task_test_door_jammed","pos":Vector2i(4, 1),"extra":{"state":"jammed","damaged":true,"is_locked":true}},
		# Mechanical key doors
		{"type":"steel_door","id":"task_test_door_locked_mechanical","pos":Vector2i(6, 1),"extra":{"state":"locked","is_locked":true,"lock_type":"mechanical_key","required_key_id":"task_test_item_mechanical_keycard"}},
		# Digital key doors
		{"type":"energy_door","id":"task_test_door_open_digital","pos":Vector2i(8, 1),"extra":{"state":"open","is_open":true,"is_locked":false,"lock_type":"digital_key","required_key_id":"task_test_item_digital_key_opened","power_network_id":"task_test_power_main"}},
		{"type":"energy_door","id":"task_test_door_locked_digital","pos":Vector2i(9, 1),"extra":{"state":"locked","is_locked":true,"lock_type":"digital_key","required_key_id":"task_test_item_digital_key_encrypted","power_network_id":"task_test_power_main"}},
		# Terminal-controlled doors
		{"type":"reinforced_steel_door","id":"task_test_door_terminal_locked","pos":Vector2i(11, 1),"extra":{"state":"locked","is_locked":true,"lock_type":"terminal_lock","linked_terminal_id":"task_test_terminal_basic_door"}},
		{"type":"door_terminal","id":"task_test_terminal_basic_door","pos":Vector2i(12, 1),"extra":{"state":"active","is_powered":true,"target_door_id":"task_test_door_terminal_locked"}},
		# Powered gates
		{"type":"energy_door","id":"task_test_powered_gate_main","pos":Vector2i(2, 3),"extra":{"state":"closed","is_open":false,"is_locked":false,"requires_external_power":true,"power_network_id":"task_test_power_main"}},
		{"type":"energy_door","id":"task_test_powered_gate_unpowered","pos":Vector2i(3, 3),"extra":{"state":"unpowered","is_open":false,"is_locked":true,"requires_external_power":true,"is_powered":false,"power_network_id":"task_test_power_missing"}},
		# Power network
		{"type":"power_source_class_1","id":"task_test_source_class_1","pos":Vector2i(5, 3),"extra":{"power_network_id":"task_test_power_main","connected_device_ids":["task_test_powered_gate_main"]}},
		{"type":"power_source_class_2","id":"task_test_source_class_2","pos":Vector2i(6, 3),"extra":{"power_network_id":"task_test_power_main","connected_device_ids":["task_test_terminal_basic_door"],"current_heat":2,"working_heat":3,"overheat_threshold":6}},
		{"type":"power_source_class_3","id":"task_test_source_class_3","pos":Vector2i(7, 3),"extra":{"power_network_id":"task_test_power_main","connected_device_ids":["task_test_terminal_connector_gate"]}},
		{"type":"power_source_class_3","id":"task_test_source_overheated","pos":Vector2i(8, 3),"extra":{"power_network_id":"task_test_power_main","state":"overheated","current_heat":8,"working_heat":4,"overheat_threshold":4}},
		{"type":"circuit_breaker","id":"task_test_breaker","pos":Vector2i(9, 3),"extra":{"power_network_id":"task_test_power_main"}},
		{"type":"circuit_switch","id":"task_test_switch","pos":Vector2i(10, 3),"extra":{"power_network_id":"task_test_power_main","target_door_id":"task_test_control_switch_door"}},
		{"type":"fuse_box_empty","id":"task_test_fuse_box_empty","pos":Vector2i(11, 3),"extra":{"power_network_id":"task_test_power_main"}},
		{"type":"fuse_box_installed","id":"task_test_fuse_box_installed","pos":Vector2i(12, 3),"extra":{"power_network_id":"task_test_power_main"}},
		{"type":"power_socket","id":"task_test_power_socket_a","pos":Vector2i(13, 3),"extra":{"power_network_id":"task_test_power_main"}},
		{"type":"power_cable","id":"task_test_power_cable_main","pos":Vector2i(14, 3),"extra":{"power_network_id":"task_test_power_main"}},
		{"type":"power_cable","id":"task_test_power_cable_cut","pos":Vector2i(14, 4),"extra":{"power_network_id":"task_test_power_main","state":"cut","damaged":true}},
		{"type":"power_cable","id":"task_test_hidden_cable","pos":Vector2i(13, 4),"extra":{"hidden":true,"visible_with_xray":true,"power_network_id":"task_test_power_main"}},
		{"type":"power_socket","id":"task_test_hidden_socket","pos":Vector2i(12, 4),"extra":{"hidden":true,"visible_with_xray":true,"power_network_id":"task_test_power_main"}},
		# Cooling network
		{"type":"external_radiator","id":"task_test_radiator","pos":Vector2i(2, 5),"extra":{"cooling_device_type":"radiator","cooling_output":3}},
		{"type":"external_air_cooler","id":"task_test_air_cooler","pos":Vector2i(3, 5),"extra":{"cooling_device_type":"air_cooler","cooling_output":2,"directed_airflow":true,"facing_dir":"right"}},
		{"type":"metal_cooling_block","id":"task_test_cooling_block","pos":Vector2i(4, 5),"extra":{"cooling_device_type":"block","cooling_output":1}},
		{"type":"door_terminal","id":"task_test_terminal_heat_device","pos":Vector2i(5, 5),"extra":{"state":"active","is_powered":true,"working_heat":4,"current_heat":6,"overheat_threshold":9,"cooling_received":1,"overheated_state_before":false}},
		{"type":"door_terminal","id":"task_test_terminal_overheated","pos":Vector2i(6, 5),"extra":{"state":"overheated","is_powered":true,"working_heat":3,"current_heat":7,"overheat_threshold":5,"cooling_received":0,"overheated_state_before":true}},
		# Control network
		{"type":"steel_door","id":"task_test_control_switch_door","pos":Vector2i(8, 5),"extra":{"state":"closed","control_type":"switch","control_source_id":"task_test_switch","requires_external_control":true}},
		{"type":"lifting_platform","id":"task_test_control_terminal_platform","pos":Vector2i(9, 5),"extra":{"platform_id":"task_test_control_terminal_platform","control_type":"terminal","linked_terminal_id":"task_test_terminal_control","requires_external_control":true,"requires_terminal_enabled":true}},
		{"type":"door_terminal","id":"task_test_terminal_control","pos":Vector2i(10, 5),"extra":{"state":"active","is_powered":true,"target_platform_id":"task_test_control_terminal_platform"}},
		{"type":"rotating_platform","id":"task_test_control_missing_source","pos":Vector2i(11, 5),"extra":{"platform_id":"task_test_control_missing_source","requires_external_control":true}},
		{"type":"rotating_platform","id":"task_test_control_invalid_source","pos":Vector2i(12, 5),"extra":{"platform_id":"task_test_control_invalid_source","requires_external_control":true,"control_source_id":"task_test_missing_controller"}},
		{"type":"rotating_platform","id":"task_test_control_valid_source","pos":Vector2i(13, 5),"extra":{"platform_id":"task_test_control_valid_source","requires_external_control":true,"control_source_id":"task_test_switch"}},
		# Wall material samples
		{"type":"outer_wall","id":"task_test_outer_wall_sample","pos":Vector2i(2, 7),"extra":{"material":"outer_wall","durability":99999,"blocks_movement":true,"blocks_vision":true,"destructible":false}},
		{"type":"brick_wall","id":"task_test_brick_wall_sample","pos":Vector2i(3, 7),"extra":{"material":"brick_wall","durability":6,"blocks_movement":true,"blocks_vision":true,"destructible":true}},
		{"type":"concrete_wall","id":"task_test_concrete_wall_sample","pos":Vector2i(4, 7),"extra":{"material":"concrete_wall","durability":8,"blocks_movement":true,"blocks_vision":true,"destructible":true}},
		{"type":"steel_wall","id":"task_test_steel_wall_sample","pos":Vector2i(5, 7),"extra":{"material":"steel_wall","durability":12,"blocks_movement":true,"blocks_vision":true,"destructible":true}},
		{"type":"reinforced_steel_wall","id":"task_test_reinforced_wall_sample","pos":Vector2i(6, 7),"extra":{"material":"reinforced_steel_wall","durability":18,"blocks_movement":true,"blocks_vision":true,"destructible":false}},
		{"type":"grate_wall","id":"task_test_grate_wall_sample","pos":Vector2i(7, 7),"extra":{"material":"grate_wall","durability":4,"blocks_movement":true,"blocks_vision":false,"destructible":true}},
		{"type":"damaged_wall","id":"task_test_damaged_wall_sample","pos":Vector2i(8, 7),"extra":{"material":"damaged_wall","durability":2,"blocks_movement":true,"blocks_vision":false,"destructible":true,"hidden_content":"wiring_fragment"}},
		# Scan visibility samples
		{"type":"power_cable","id":"task_test_scan_hidden_object","pos":Vector2i(10, 7),"extra":{"hidden":true,"visible_with_xray":true,"scan_level":1}},
		{"type":"door_terminal","id":"task_test_scan_thermal_object","pos":Vector2i(11, 7),"extra":{"visible_with_thermal":true,"current_heat":5,"working_heat":2}},
		{"type":"door_terminal","id":"task_test_scan_connector_gated","pos":Vector2i(12, 7),"extra":{"required_connector_level":2,"state":"active","is_powered":true}},
		{"type":"door_terminal","id":"task_test_scan_processor_gated","pos":Vector2i(13, 7),"extra":{"required_processor_level":2,"state":"active","is_powered":true}},
		{"type":"light","id":"task_test_scan_normal_visible","pos":Vector2i(14, 8),"extra":{"hidden":false}},
		# Terminals coverage + extraction
		{"type":"door_terminal","id":"task_test_terminal_info","pos":Vector2i(1, 8),"extra":{"connection_type":"info","state":"active","is_powered":true}},
		{"type":"door_terminal","id":"task_test_terminal_unpowered","pos":Vector2i(2, 8),"extra":{"state":"unpowered","is_powered":false}},
		{"type":"door_terminal","id":"task_test_terminal_damaged","pos":Vector2i(3, 8),"extra":{"state":"damaged","damaged":true,"is_powered":false}},
		{"type":"door_terminal","id":"task_test_terminal_encrypted","pos":Vector2i(4, 8),"extra":{"state":"active","is_powered":true,"encrypts_data":true,"drain_pool":2}},
		{"type":"door_terminal","id":"task_test_terminal_connector_gate","pos":Vector2i(5, 8),"extra":{"state":"active","is_powered":true,"required_connector_level":1}},
		{"type":"door_terminal","id":"task_test_terminal_processor_gate","pos":Vector2i(6, 8),"extra":{"state":"active","is_powered":true,"required_processor_level":1}},
		
		{"type":"door_terminal","id":"task_test_terminal_main","pos":Vector2i(7, 8),"extra":{"state":"active","is_powered":true,"required_connector_level":1,"required_processor_level":1,"target_door_id":"task_test_door_terminal_locked"}},
		{"type":"steel_door","id":"task_test_door_mechanical","pos":Vector2i(5, 1),"extra":{"state":"locked","is_locked":true,"lock_type":"mechanical_key","required_key_id":"task_test_item_mechanical_keycard"}},
		{"type":"lifting_platform","id":"task_test_platform_lift","pos":Vector2i(8, 8),"extra":{"platform_id":"task_test_platform_lift","is_powered":false,"requires_external_power":true,"power_network_id":"task_test_power_missing"}},
		{"type":"power_cable","id":"task_test_xray_route_marker","pos":Vector2i(9, 8),"extra":{"hidden":true,"visible_with_xray":true}},
{"type":"energy_door","id":"task_test_extraction_door","pos":Vector2i(14, 7),"extra":{"state":"open","is_locked":false,"mission_exit":true,"extraction":true}}
	]
	for spec in specs:
		var obj: Dictionary = WorldObjectCatalogRef.create_world_object(String(spec.get("type", "")), String(spec.get("id", "")))
		if obj.is_empty():
			warnings.append("catalog_create_failed_%s" % String(spec.get("id", "")))
			continue
		obj["position"] = Vector2i(spec.get("pos", Vector2i.ZERO))
		var extra: Dictionary = Dictionary(spec.get("extra", {}))
		for key_variant in extra.keys():
			var key_name: String = String(key_variant)
			obj[key_name] = extra[key_variant]
		objects.append(obj)

	var items_by_cell: Dictionary = {}
	var key_specs: Array[Dictionary] = [
		{"type":"mechanical_keycard","id":"task_test_item_mechanical_keycard","cell":Vector2i(1, 1),"extra":{}},
		{"type":"digital_key","id":"task_test_item_digital_key_opened","cell":Vector2i(1, 3),"extra":{"digital_state":"opened"}},
		{"type":"digital_key","id":"task_test_item_digital_key_encrypted","cell":Vector2i(1, 5),"extra":{"digital_state":"encrypted"}},
		{"type":"digital_key","id":"task_test_item_digital_key_damaged","cell":Vector2i(1, 6),"extra":{"digital_state":"damaged"}},
		{"type":"access_code","id":"task_test_item_access_code","cell":Vector2i(1, 7),"extra":{}},
		{"type":"fuse","id":"task_test_item_fuse","cell":Vector2i(1, 2),"extra":{}},
		{"type":"power_cable_reel","id":"task_test_cable_reel","cell":Vector2i(2, 2),"extra":{}},
		{"type":"repair_kit","id":"task_test_item_repair_kit","cell":Vector2i(2, 6),"extra":{}}
	]
	for item_spec in key_specs:
		var item: Dictionary = WorldObjectCatalogRef.create_world_object(String(item_spec.get("type", "")), String(item_spec.get("id", "")))
		if item.is_empty():
			warnings.append("catalog_create_failed_%s" % String(item_spec.get("id", "")))
			continue
		var extra_item: Dictionary = Dictionary(item_spec.get("extra", {}))
		for item_key_variant in extra_item.keys():
			var item_key: String = String(item_key_variant)
			item[item_key] = extra_item[item_key_variant]
		var cell: Vector2i = Vector2i(item_spec.get("cell", Vector2i.ZERO))
		if not items_by_cell.has(cell):
			items_by_cell[cell] = []
		var cell_items: Array = Array(items_by_cell[cell])
		cell_items.append(item)
		items_by_cell[cell] = cell_items
	return {"objects": objects, "items_by_cell": items_by_cell, "warnings": warnings}

func set_grid_manager_ref(value: Node) -> void:
	grid_manager = value

# region Scenario validation
func validate_world_object_scenario() -> Array[String]:
	var warnings: Array[String] = []
	var ids := {}
	var occupied_cells := {}
	var turret_1: Dictionary = {}
	for object_data in mission_world_objects:
		var object_id := _wo_id(object_data)
		if not object_id.is_empty():
			ids[object_id] = true
		if object_id == "turret_1":
			turret_1 = object_data
	for object_data in mission_world_objects:
		var object_id := _wo_id(object_data)
		var pos := _wo_pos(object_data)
		if _wo_group(object_data) != "item":
			if occupied_cells.has(pos):
				warnings.append("Two world objects occupy %s." % str(pos))
			occupied_cells[pos] = object_id
		var controls: Array = object_data.get("controls", [])
		if object_data.has("controls") and controls.is_empty():
			warnings.append("Object %s has empty controls list." % object_id)
		for controlled_id in controls:
			if not ids.has(String(controlled_id)):
				warnings.append("Object %s controls missing id %s." % [object_id, String(controlled_id)])
		if object_data.has("power_network_id"):
			var network_id := String(object_data.get("power_network_id", ""))
			if network_id.is_empty():
				warnings.append("Object %s has empty power network id." % object_id)
	for required_id in ["steel_door_1", "door_terminal_1", "turret_1"]:
		if not ids.has(required_id):
			warnings.append("Required scenario id missing: %s." % required_id)
	if not turret_1.is_empty():
		if String(turret_1.get("object_group", "")) != "threat":
			warnings.append("turret_1 must use object_group threat.")
		if int(turret_1.get("detection_range", 0)) <= 0:
			warnings.append("turret_1 must have detection_range > 0.")
		var extraction_cell := Vector2i(7, 7)
		var turret_cell := _wo_pos(turret_1)
		if turret_cell == extraction_cell:
			warnings.append("turret_1 cannot be placed on extraction cell %s." % str(extraction_cell))
		var main_route := [
			Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1),
			Vector2i(5, 1), Vector2i(6, 1), Vector2i(7, 1), Vector2i(7, 2),
			Vector2i(7, 3), Vector2i(7, 4), Vector2i(7, 5), Vector2i(7, 6), Vector2i(7, 7)
		]
		if main_route.has(turret_cell):
			warnings.append("turret_1 overlaps basic mission route at %s." % str(turret_cell))
	for cell in cell_items.keys():
		var seen := {}
		for item in cell_items[cell]:
			var item_id := String(item.get("id", ""))
			if seen.has(item_id):
				warnings.append("Duplicate item id %s at cell %s." % [item_id, str(cell)])
			seen[item_id] = true
	return warnings
# endregion

func _should_assign_main_power_network(object_data: Dictionary) -> bool:
	var object_type := _wo_type(object_data)
	var object_group := _wo_group(object_data)
	if object_type in [
		"power_source_class_1",
		"power_cable",
		"circuit_breaker",
		"fuse_box_installed",
		"door_terminal",
		"energy_door",
		"energy_wall",
		"light"
	]:
		return true
	if object_group in ["terminal", "power"]:
		return object_type != "fuse_box_empty"
	return false

func _seed_debug_world_objects() -> void:
	mission_world_objects = WorldObjectCatalogRef.create_test_set()
	for object_data in mission_world_objects:
		if object_data.get("id", "") in ["wall_b1", "wall_d1"]:
			object_data["scan_level"] = 3
	if mission_world_objects.size() > 0:
		mission_world_objects[0]["power_network_id"] = "power_net_A"
	for object_data in mission_world_objects:
		if object_data.get("object_group", "") in ["door", "terminal", "power"]:
			object_data["power_network_id"] = "power_net_A"
		if object_data.get("object_type", "") == "energy_wall":
			object_data["power_network_id"] = "power_net_A"
		if object_data.get("id", "") == "fuse_box_empty_1":
			object_data["power_network_id"] = ""
	PowerSystemRef.recalculate_network(mission_world_objects, "power_net_A")
	refresh_world_cooling_received()
	if debug_world_cooling_scenario_enabled:
		seed_world_cooling_debug_scenario()
	if debug_platform_scenario_enabled:
		seed_platform_debug_scenario()
	if debug_world_logs:
		_debug_world_summary()

func _place_debug_world_object(object_type: String, object_id: String, cell: Vector2i, overrides: Dictionary = {}) -> Dictionary:
	if object_type.is_empty() or object_id.is_empty():
		return {}
	var existing := get_world_object_by_id(object_id)
	if not existing.is_empty():
		var existing_cell := Vector2i(existing.get("position", cell))
		world_objects_by_cell.erase(existing_cell)
		mission_world_objects.erase(existing)
	var object_data := WorldObjectCatalogRef.create_world_object(object_type, object_id)
	if object_data.is_empty():
		return {}
	object_data["id"] = object_id
	object_data["position"] = cell
	for key in overrides.keys():
		object_data[key] = overrides[key]
	var replaced := get_world_object_at_cell(cell)
	if not replaced.is_empty() and String(replaced.get("id", "")) == object_id:
		mission_world_objects.erase(replaced)
	world_objects_by_cell[cell] = object_data
	if not mission_world_objects.has(object_data):
		mission_world_objects.append(object_data)
	return object_data

func seed_world_cooling_debug_scenario(origin: Vector2i = Vector2i(8, 8)) -> void:
	_place_debug_world_object("information_terminal", "terminal_c2_radiator", origin + Vector2i(0, 0), {"terminal_class": 2, "working_heat": 2, "current_heat": 2, "overheat_threshold": 3, "hack_heat": 1})
	_place_debug_world_object("external_radiator", "cooling_radiator_a", origin + Vector2i(1, 0))
	_place_debug_world_object("information_terminal", "terminal_c2_radiator_metal", origin + Vector2i(0, 2), {"terminal_class": 2, "working_heat": 2, "current_heat": 2, "overheat_threshold": 3, "hack_heat": 1})
	_place_debug_world_object("external_radiator", "cooling_radiator_b", origin + Vector2i(1, 2))
	_place_debug_world_object("metal_cooling_block", "cooling_metal_block_b", origin + Vector2i(2, 2))
	_place_debug_world_object("information_terminal", "terminal_c2_air", origin + Vector2i(0, 4), {"terminal_class": 2, "working_heat": 2, "current_heat": 2, "overheat_threshold": 3, "hack_heat": 1})
	_place_debug_world_object("external_air_cooler", "cooling_air_direct_c", origin + Vector2i(-1, 4), {"facing_dir": "right"})
	_place_debug_world_object("information_terminal", "terminal_c2_water", origin + Vector2i(0, 6), {"terminal_class": 2, "working_heat": 2, "current_heat": 2, "overheat_threshold": 3, "hack_heat": 1})
	_place_debug_world_object("external_water_pipe", "cooling_water_d", origin + Vector2i(1, 6))
	_place_debug_world_object("information_terminal", "terminal_c2_duct", origin + Vector2i(3, 8), {"terminal_class": 2, "working_heat": 2, "current_heat": 2, "overheat_threshold": 3, "hack_heat": 1})
	_place_debug_world_object("external_air_cooler", "cooling_air_duct_e", origin + Vector2i(0, 8), {"facing_dir": "right"})
	_place_debug_world_object("external_air_duct", "cooling_air_duct_e1", origin + Vector2i(1, 8))
	_place_debug_world_object("external_air_duct", "cooling_air_duct_e2", origin + Vector2i(2, 8))
	_place_debug_world_object("information_terminal", "terminal_c2_air_water", origin + Vector2i(0, 10), {"terminal_class": 2, "working_heat": 2, "current_heat": 2, "overheat_threshold": 3, "hack_heat": 1})
	_place_debug_world_object("external_air_cooler", "cooling_air_combo_f", origin + Vector2i(-1, 10), {"facing_dir": "right"})
	_place_debug_world_object("external_water_pipe", "cooling_water_combo_f", origin + Vector2i(0, 11))
	_place_debug_world_object("power_source_class_3", "power_source_c3_cooled", origin + Vector2i(0, 12), {"working_heat": 3, "current_heat": 3, "overheat_threshold": 3, "state": "active"})
	_place_debug_world_object("external_water_pipe", "cooling_water_g", origin + Vector2i(1, 12))
	refresh_world_cooling_received()
	PowerSystemRef.recalculate_network(mission_world_objects, "power_net_A")
	refresh_world_cooling_received()

func validate_world_cooling_debug_scenario() -> Array[String]:
	var warnings: Array[String] = []
	# Manual validation checklist:
	# 1) Class 2 terminal without cooling should fail hack due to temporary overheat.
	# 2) Class 2 terminal with cooling 1+ should be safe from terminal temporary overheat.
	# 3) CPU internal overheat is separate and may still fail hack first.
	var expected := {
		"terminal_c2_radiator": 1,
		"terminal_c2_radiator_metal": 2,
		"terminal_c2_air": 2,
		"terminal_c2_water": 2,
		"terminal_c2_duct": 2,
		"terminal_c2_air_water": 4
	}
	for object_id in expected.keys():
		var object_data := get_world_object_by_id(String(object_id))
		if object_data.is_empty():
			warnings.append("Missing debug object: %s." % String(object_id))
			continue
		var received := int(object_data.get("cooling_received", -1))
		var target := int(expected[object_id])
		if received != target:
			warnings.append("%s cooling_received expected %d, got %d." % [String(object_id), target, received])
	var power_source := get_world_object_by_id("power_source_c3_cooled")
	if power_source.is_empty():
		warnings.append("Missing debug object: power_source_c3_cooled.")
	else:
		if String(power_source.get("state", "")) != "active":
			warnings.append("power_source_c3_cooled state expected active, got %s." % String(power_source.get("state", "")))
		var current_heat := int(power_source.get("current_heat", 999))
		var threshold := int(power_source.get("overheat_threshold", 0))
		if current_heat >= threshold:
			warnings.append("power_source_c3_cooled current_heat must be below threshold (%d >= %d)." % [current_heat, threshold])
	return warnings

func _debug_world_summary() -> void:
	for object_data in mission_world_objects:
		var scan_text := ScanSystemRef.get_scan_display_text(object_data, "visor")
		print("[WorldObject] %s (%s) state=%s" % [object_data.get("display_name", "Unknown"), object_data.get("object_type", ""), object_data.get("state", "")])
		print("[Scan] %s" % scan_text)

func debug_try_action(target_id: String, action_type: String, module_id: String = "") -> Dictionary:
	var target := _find_object(target_id)
	if target.is_empty():
		return {"success": false, "message": "Target not found.", "effects": []}
	var actor := {
		"processor_level": 1,
		"connector_level": 1,
		"manipulator_level": 1,
		"wired_connector_level": 1,
		"optical_connector_level": 1,
		"wireless_connector_level": 1,
		"high_bandwidth_connector_level": 1,
		"firewall_module_v1": false,
		"manipulator_occupied": false,
		"pocket_full": false,
		"power_class": "scout",
		"magnetic_path_blocked": false,
		"target_is_grate": false
	}
	var module := {"id": module_id}
	var result := InteractionSystemRef.apply_action(actor, module, target, action_type)
	if debug_world_logs:
		print("[Interact] %s -> %s: %s" % [target_id, action_type, result.get("message", "")])
	return result

func _find_object(target_id: String) -> Dictionary:
	for object_data in mission_world_objects:
		if object_data.get("id", "") == target_id:
			return object_data
	return {}

func get_world_object_at_cell(cell: Vector2i) -> Dictionary:
	return world_objects_by_cell.get(cell, {})


func get_runtime_cell_state(cell: Vector2i) -> Dictionary:
	var state: Dictionary = {
		"cell": cell,
		"in_bounds": false,
		"tile_type": -1,
		"tile_name": "",
		"static_walkable": false,
		"is_door_object": false,
		"is_door_tile": false,
		"is_door_cell": false,
		"has_object": false,
		"object_id": "",
		"object_type": "",
		"object_group": "",
		"display_name": "",
		"state": "",
		"is_open": false,
		"is_locked": false,
		"is_powered": false,
		"blocks_movement": false,
		"requires_key": false,
		"required_key_id": "",
		"lock_type": "",
		"power_network_id": "",
		"control_source_id": "",
		"is_passable": false,
		"block_reason": "out_of_bounds",
		"visual_profile": ""
	}
	if grid_manager == null or not grid_manager.has_method("is_in_bounds") or not bool(grid_manager.call("is_in_bounds", cell)):
		return state

	state["in_bounds"] = true
	state["block_reason"] = ""
	if grid_manager.has_method("get_tile"):
		var tile_type: int = int(grid_manager.call("get_tile", cell))
		state["tile_type"] = tile_type
		if grid_manager.has_method("get_tile_name"):
			state["tile_name"] = String(grid_manager.call("get_tile_name", tile_type))
	if grid_manager.has_method("is_walkable"):
		state["static_walkable"] = bool(grid_manager.call("is_walkable", cell))

	var object_data: Dictionary = get_world_object_at_cell(cell)
	if not object_data.is_empty():
		state["has_object"] = true
		state["object_id"] = String(object_data.get("id", ""))
		state["object_type"] = String(object_data.get("object_type", ""))
		state["object_group"] = String(object_data.get("object_group", ""))
		state["display_name"] = String(object_data.get("display_name", ""))
		state["state"] = String(object_data.get("state", "")).to_lower()
		state["is_open"] = bool(object_data.get("is_open", false))
		state["is_locked"] = bool(object_data.get("is_locked", false)) or bool(object_data.get("locked", false))
		state["is_powered"] = bool(object_data.get("is_powered", false))
		state["blocks_movement"] = bool(object_data.get("blocks_movement", false))
		state["requires_key"] = bool(object_data.get("requires_key", false))
		state["required_key_id"] = String(object_data.get("required_key_id", ""))
		state["lock_type"] = String(object_data.get("lock_type", ""))
		state["power_network_id"] = String(object_data.get("power_network_id", ""))
		state["control_source_id"] = String(object_data.get("control_source_id", object_data.get("linked_terminal_id", object_data.get("controller_id", ""))))
		state["visual_profile"] = String(object_data.get("visual_profile", ""))
		var object_group_value: String = String(state.get("object_group", "")).to_lower()
		var object_type_value: String = String(state.get("object_type", "")).to_lower()
		var lock_type_value: String = String(state.get("lock_type", ""))
		var has_door_class: bool = object_data.has("door_class")
		state["is_door_object"] = object_group_value == "door" or object_type_value.find("door") >= 0 or not lock_type_value.is_empty() or has_door_class

	var tile_type_value: int = int(state.get("tile_type", -1))
	var tile_is_wall: bool = tile_type_value == GridManager.TILE_WALL
	var tile_is_door: bool = tile_type_value == GridManager.TILE_DOOR or tile_type_value == GridManager.TILE_DIGITAL_DOOR or tile_type_value == GridManager.TILE_POWERED_GATE
	state["is_door_tile"] = tile_is_door
	state["is_door_cell"] = tile_is_door or bool(state.get("is_door_object", false))
	var object_state: String = String(state.get("state", ""))
	var is_open_state: bool = object_state == "open" or object_state == "opened"
	var canonical_open: bool = bool(state.get("is_open", false)) or is_open_state
	if bool(state.get("is_door_cell", false)):
		if canonical_open:
			state["is_passable"] = true
			state["block_reason"] = ""
			return state
		state["is_passable"] = false
		if object_state == "locked" or bool(state.get("is_locked", false)):
			state["block_reason"] = "door_locked"
		elif object_state == "unpowered":
			state["block_reason"] = "door_unpowered"
		elif object_state == "damaged" or object_state == "broken" or object_state == "destroyed":
			state["block_reason"] = "door_damaged"
		else:
			state["block_reason"] = "door_closed"
		return state
	if tile_is_wall:
		state["is_passable"] = false
		state["block_reason"] = "wall"
		return state
	if bool(state.get("has_object", false)) and bool(state.get("blocks_movement", false)):
		state["is_passable"] = false
		state["block_reason"] = "blocked_by_object"
		return state
	state["is_passable"] = bool(state.get("static_walkable", false))
	if not bool(state.get("is_passable", false)):
		state["block_reason"] = "tile_blocked"
	return state

func is_runtime_cell_passable(cell: Vector2i) -> bool:
	var state: Dictionary = get_runtime_cell_state(cell)
	return bool(state.get("is_passable", false))

func get_runtime_cell_block_reason(cell: Vector2i) -> String:
	var state: Dictionary = get_runtime_cell_state(cell)
	return String(state.get("block_reason", ""))

func set_world_object_at_cell(cell: Vector2i, object_data: Dictionary) -> void:
	if object_data.is_empty():
		return
	object_data["position"] = cell
	world_objects_by_cell[cell] = object_data
	if not mission_world_objects.has(object_data):
		mission_world_objects.append(object_data)
	refresh_world_cooling_received()

func remove_world_object_at_cell(cell: Vector2i) -> void:
	var object_data := get_world_object_at_cell(cell)
	if not object_data.is_empty():
		mission_world_objects.erase(object_data)
	world_objects_by_cell.erase(cell)
	refresh_world_cooling_received()

func get_items_at_cell(cell: Vector2i) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var raw_items: Array = Array(cell_items.get(cell, []))
	for item_variant in raw_items:
		if item_variant is Dictionary:
			result.append(Dictionary(item_variant))
	return result

func add_item_at_cell(cell: Vector2i, item_data: Dictionary) -> void:
	item_data["position"] = cell
	var items: Array[Dictionary] = get_items_at_cell(cell)
	items.append(item_data)
	cell_items[cell] = items
	if not mission_world_objects.has(item_data):
		mission_world_objects.append(item_data)

func remove_first_item_at_cell(cell: Vector2i) -> Dictionary:
	var items: Array[Dictionary] = get_items_at_cell(cell)
	if items.is_empty():
		return {}
	var item: Dictionary = items.pop_front()
	cell_items[cell] = items
	mission_world_objects.erase(item)
	return item

func get_map_constructor_prefab_catalog() -> Array[Dictionary]:
	var entries: Array[Dictionary] = [
		{"category":"Floors","id":"floor"},{"category":"Floors","id":"stepped_floor"},
		{"category":"Walls","id":"outer_wall"},{"category":"Walls","id":"brick_wall"},{"category":"Walls","id":"concrete_wall"},{"category":"Walls","id":"steel_wall"},{"category":"Walls","id":"grate_wall"},
		{"category":"Doors","id":"mechanical_door"},{"category":"Doors","id":"digital_door"},{"category":"Doors","id":"powered_gate"},
		{"category":"Terminals","id":"information_terminal"},{"category":"Terminals","id":"control_terminal"},{"category":"Terminals","id":"door_terminal"},{"category":"Terminals","id":"platform_terminal"},{"category":"Terminals","id":"cooling_terminal"},{"category":"Terminals","id":"firewall"},
		{"category":"Power","id":"power_source_class_1"},{"category":"Power","id":"power_socket"},{"category":"Power","id":"power_cable"},{"category":"Power","id":"circuit_switch"},{"category":"Power","id":"circuit_breaker"},{"category":"Power","id":"light_switch"},{"category":"Power","id":"fuse_box"},{"category":"Power","id":"power_cable_reel"},
		{"category":"Items","id":"mechanical_key"},{"category":"Items","id":"digital_key"},{"category":"Items","id":"access_code"}
	]
	for i in range(entries.size()):
		var entry: Dictionary = entries[i]
		var prefab_id: String = String(entry.get("id", ""))
		var object_template: Dictionary = WorldObjectCatalog.get_object_template(prefab_id)
		entry["label"] = String(object_template.get("name", prefab_id.replace("_", " ").capitalize()))
		entry["placement_mode"] = String(object_template.get("placement_mode", "floor"))
		entries[i] = entry
	return entries

func _get_map_constructor_prefab_metadata_catalog() -> Dictionary:
	var metadata: Dictionary = {
		"floor": {"display_name":"Floor Tile","category":"Structural","subcategory":"Floor","placement_mode":"tile","system_roles":["navigation"],"tags":["floor","walkable","structural"],"description":"Basic walkable floor tile.","placement_hint":"Use to restore walkable space.","requires_wall":false,"requires_floor":false,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"stepped_floor": {"display_name":"Stepped Floor","category":"Structural","subcategory":"Floor","placement_mode":"tile","system_roles":["navigation"],"tags":["floor","walkable","elevation"],"description":"Walkable stepped floor tile.","placement_hint":"Use for alternate floor visuals.","requires_wall":false,"requires_floor":false,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"outer_wall": {"display_name":"Outer Wall","category":"Structural","subcategory":"Wall","placement_mode":"tile","system_roles":["blocking"],"tags":["wall","solid","boundary"],"description":"Solid wall that blocks movement and vision.","placement_hint":"Place on floor to create barriers.","requires_wall":false,"requires_floor":true,"is_destructive":true,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"brick_wall": {"display_name":"Brick Wall","category":"Structural","subcategory":"Wall","placement_mode":"object","system_roles":["blocking"],"tags":["wall","brick","obstacle"],"description":"Brick obstacle wall object.","placement_hint":"Requires a floor cell.","requires_wall":false,"requires_floor":true,"is_destructive":true,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"concrete_wall": {"display_name":"Concrete Wall","category":"Structural","subcategory":"Wall","placement_mode":"object","system_roles":["blocking"],"tags":["wall","concrete","obstacle"],"description":"Concrete obstacle wall object.","placement_hint":"Requires a floor cell.","requires_wall":false,"requires_floor":true,"is_destructive":true,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"steel_wall": {"display_name":"Steel Wall","category":"Structural","subcategory":"Wall","placement_mode":"object","system_roles":["blocking"],"tags":["wall","steel","obstacle"],"description":"Durable steel wall object.","placement_hint":"Requires a floor cell.","requires_wall":false,"requires_floor":true,"is_destructive":true,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"grate_wall": {"display_name":"Grate Wall","category":"Structural","subcategory":"Wall","placement_mode":"object","system_roles":["blocking"],"tags":["wall","grate","obstacle"],"description":"Grated wall obstacle.","placement_hint":"Requires a floor cell.","requires_wall":false,"requires_floor":true,"is_destructive":true,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"mechanical_door": {"display_name":"Mechanical Door","category":"Door","subcategory":"Mechanical","placement_mode":"object","system_roles":["navigation","access_control"],"tags":["door","mechanical","locked"],"description":"Door that may require physical access.","placement_hint":"Place on floor path segments.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":true,"default_state":{"state":"closed"}},
		"digital_door": {"display_name":"Digital Door","category":"Door","subcategory":"Digital","placement_mode":"object","system_roles":["navigation","access_control","signal_control"],"tags":["door","digital","control"],"description":"Digitally controlled access door.","placement_hint":"Usually paired with control or door terminals.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{"state":"locked"}},
		"powered_gate": {"display_name":"Powered Gate","category":"Door","subcategory":"Gate","placement_mode":"object","system_roles":["navigation","access_control","power_consumer"],"tags":["gate","powered","access"],"description":"Power-driven gate for controlled routes.","placement_hint":"Set power network and controls after placement.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{"state":"locked"}},
		"information_terminal": {"display_name":"Information Terminal","category":"Terminal","subcategory":"Info","placement_mode":"object","system_roles":["terminal_interaction"],"tags":["terminal","info","device"],"description":"Read-only terminal for mission text/data.","placement_hint":"Place on floor near navigation paths.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{}},
		"control_terminal": {"display_name":"Control Terminal","category":"Control","subcategory":"Terminal","placement_mode":"object","system_roles":["terminal_interaction","signal_control"],"tags":["terminal","control","link"],"description":"Terminal used to send control signals.","placement_hint":"Configure target links in inspector.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"door_terminal": {"display_name":"Door Terminal","category":"Terminal","subcategory":"Door","placement_mode":"wall_mounted","system_roles":["terminal_interaction","access_control","signal_control"],"tags":["terminal","door","wall"],"description":"Wall terminal for door control.","placement_hint":"Requires a valid adjacent wall side.","requires_wall":true,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"platform_terminal": {"display_name":"Platform Terminal","category":"Terminal","subcategory":"Platform","placement_mode":"wall_mounted","system_roles":["terminal_interaction","signal_control"],"tags":["terminal","platform","wall"],"description":"Wall terminal for platform control.","placement_hint":"Requires a valid adjacent wall side.","requires_wall":true,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"cooling_terminal": {"display_name":"Cooling Terminal","category":"Terminal","subcategory":"Cooling","placement_mode":"wall_mounted","system_roles":["terminal_interaction","signal_control"],"tags":["terminal","cooling","wall"],"description":"Wall terminal for cooling subsystem.","placement_hint":"Requires a valid adjacent wall side.","requires_wall":true,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"firewall": {"display_name":"Firewall Node","category":"Wall-mounted","subcategory":"Security","placement_mode":"wall_mounted","system_roles":["signal_control"],"tags":["firewall","security","wall"],"description":"Wall-mounted digital security node.","placement_hint":"Requires a valid adjacent wall side.","requires_wall":true,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"power_source_class_1": {"display_name":"Power Source C1","category":"Power","subcategory":"Source","placement_mode":"object","system_roles":["power_source","power_network"],"tags":["power","source","generator"],"description":"Primary local power source.","placement_hint":"Set power_network_id in inspector after placement.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{"is_powered":true}},
		"power_socket": {"display_name":"Power Socket","category":"Power","subcategory":"Connector","placement_mode":"object","system_roles":["power_network","power_consumer"],"tags":["power","socket","connector"],"description":"Power connector point for devices.","placement_hint":"Set power_network_id in inspector after placement.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{}},
		"power_cable": {"display_name":"Power Cable","category":"Power","subcategory":"Network","placement_mode":"object","system_roles":["power_network"],"tags":["power","cable","network"],"description":"Cable segment for power routing.","placement_hint":"Set power_network_id in inspector after placement.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{}},
		"circuit_switch": {"display_name":"Circuit Switch","category":"Control","subcategory":"Power","placement_mode":"object","system_roles":["signal_control","power_network"],"tags":["switch","circuit","control"],"description":"Switch controlling power state.","placement_hint":"Configure links in inspector after placement.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"circuit_breaker": {"display_name":"Circuit Breaker","category":"Power","subcategory":"Protection","placement_mode":"wall_mounted","system_roles":["power_network","signal_control"],"tags":["breaker","power","wall"],"description":"Wall-mounted power safety breaker.","placement_hint":"Requires a valid adjacent wall side.","requires_wall":true,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"light_switch": {"display_name":"Light Switch","category":"Control","subcategory":"Lighting","placement_mode":"wall_mounted","system_roles":["signal_control","power_consumer"],"tags":["switch","light","wall"],"description":"Wall-mounted switch for lights/devices.","placement_hint":"Requires a valid adjacent wall side.","requires_wall":true,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"fuse_box": {"display_name":"Fuse Box","category":"Power","subcategory":"Protection","placement_mode":"wall_mounted","system_roles":["power_network","power_consumer"],"tags":["fuse","power","wall"],"description":"Wall-mounted fuse control box.","placement_hint":"Requires a valid adjacent wall side.","requires_wall":true,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"power_cable_reel": {"display_name":"Cable Reel","category":"Utility","subcategory":"Power Utility","placement_mode":"wall_mounted","system_roles":["power_network"],"tags":["cable","reel","wall","utility"],"description":"Wall-mounted cable utility node.","placement_hint":"Requires a valid adjacent wall side.","requires_wall":true,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{}},
		"mechanical_key": {"display_name":"Mechanical Key","category":"Item","subcategory":"Access","placement_mode":"item","system_roles":["key_item","access_control"],"tags":["item","key","mechanical"],"description":"Physical key item for locks.","placement_hint":"Place on floor as pick-up item.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{"item_type":"key"}},
		"digital_key": {"display_name":"Digital Key","category":"Item","subcategory":"Access","placement_mode":"item","system_roles":["key_item","access_control"],"tags":["item","key","digital"],"description":"Digital key credential item.","placement_hint":"Place on floor as pick-up item.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{"item_type":"digital_key"}},
		"access_code": {"display_name":"Access Code","category":"Item","subcategory":"Credential","placement_mode":"item","system_roles":["key_item","access_control"],"tags":["item","code","credential"],"description":"Code item used for access checks.","placement_hint":"Place on floor as pick-up item.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{"item_type":"access_code"}}
	}
	return metadata


func _build_map_constructor_prefab_fallback_metadata(prefab_id: String, catalog_entry: Dictionary = {}) -> Dictionary:
	var id: String = prefab_id.strip_edges()
	var category: String = String(catalog_entry.get("category", catalog_entry.get("group", ""))).strip_edges()
	if category.is_empty():
		category = "Utility"
	var placement_mode: String = String(catalog_entry.get("placement_mode", "")).strip_edges()
	if placement_mode.is_empty():
		placement_mode = "floor"
	var display_name: String = String(catalog_entry.get("label", id)).strip_edges()
	if display_name.is_empty():
		display_name = id
	var hint: String = String(catalog_entry.get("hint", "")).strip_edges()
	var expected_invalid: bool = id.find("expected_invalid") >= 0 or category.to_lower().find("expected_invalid") >= 0
	var requires_floor: bool = placement_mode != "tile"
	var fallback_tags: Array[String] = [id, category, placement_mode]
	return {
		"id": id,
		"display_name": display_name,
		"category": category,
		"subcategory": "",
		"placement_mode": placement_mode,
		"system_roles": [],
		"tags": fallback_tags,
		"description": "Constructor prefab.",
		"placement_hint": hint,
		"requires_wall": placement_mode == "wall_mounted",
		"requires_floor": requires_floor,
		"is_destructive": false,
		"is_diagnostic": false,
		"is_expected_invalid_tool": expected_invalid,
		"can_have_power_network": false,
		"can_have_links": false,
		"default_state": {}
	}

func get_map_constructor_prefab_metadata(prefab_id: String) -> Dictionary:
	var metadata_catalog: Dictionary = _get_map_constructor_prefab_metadata_catalog()
	var id: String = prefab_id.strip_edges()
	if metadata_catalog.has(id):
		var explicit_row: Dictionary = Dictionary(metadata_catalog[id]).duplicate(true)
		explicit_row["id"] = id
		return {"ok": true, "prefab": explicit_row, "message": "OK"}
	for entry in get_map_constructor_prefab_catalog():
		var catalog_entry: Dictionary = Dictionary(entry)
		if String(catalog_entry.get("id", "")).strip_edges() == id:
			return {"ok": true, "prefab": _build_map_constructor_prefab_fallback_metadata(id, catalog_entry), "message": "OK"}
	return {"ok": false, "prefab": {}, "message": "Unknown prefab id."}

func get_map_constructor_prefab_palette_rows(options: Dictionary = {}) -> Dictionary:
	var search: String = String(options.get("search", "")).strip_edges().to_lower()
	var category_filter: String = String(options.get("category", "All")).strip_edges()
	var role_filter: String = String(options.get("role", "All")).strip_edges()
	var placement_filter: String = String(options.get("placement_mode", "All")).strip_edges()
	var show_expected_invalid: bool = bool(options.get("show_expected_invalid", true))
	var show_diagnostics: bool = bool(options.get("show_diagnostics", true))
	var only_placeable: bool = bool(options.get("show_only_placeable_here", false))
	var selected_cell: Vector2i = _map_constructor_cell_from_variant(options.get("selected_cell", Vector2i(-1, -1)))
	var rows: Array[Dictionary] = []
	var categories: Array[String] = []
	var roles: Array[String] = []
	for entry in get_map_constructor_prefab_catalog():
		var catalog_entry: Dictionary = Dictionary(entry)
		var prefab_id: String = String(catalog_entry.get("id", "")).strip_edges()
		if prefab_id.is_empty():
			continue
		var meta_result: Dictionary = get_map_constructor_prefab_metadata(prefab_id)
		var meta: Dictionary = Dictionary(meta_result.get("prefab", {})).duplicate(true)
		var category: String = String(meta.get("category", ""))
		var placement_mode: String = String(meta.get("placement_mode", ""))
		var role_values: Array[String] = []
		for role in Array(meta.get("system_roles", [])):
			role_values.append(String(role))
			if not roles.has(String(role)):
				roles.append(String(role))
		if not categories.has(category):
			categories.append(category)
		if not show_expected_invalid and bool(meta.get("is_expected_invalid_tool", false)):
			continue
		if not show_diagnostics and bool(meta.get("is_diagnostic", false)):
			continue
		if category_filter != "All" and category != category_filter:
			continue
		if role_filter != "All" and not role_values.has(role_filter):
			continue
		if placement_filter != "All" and placement_mode != placement_filter:
			continue
		var haystack: String = "%s %s %s %s %s %s" % [String(meta.get("id", "")).to_lower(), String(meta.get("display_name", "")).to_lower(), category.to_lower(), " ".join(PackedStringArray(meta.get("tags", []))).to_lower(), " ".join(PackedStringArray(role_values)).to_lower(), String(meta.get("description", "")).to_lower()]
		if not search.is_empty() and haystack.find(search) < 0:
			continue
		var row: Dictionary = meta.duplicate(true)
		if selected_cell.x >= 0 and selected_cell.y >= 0:
			var place_check: Dictionary = can_place_map_constructor_prefab(String(meta.get("id", "")), selected_cell, "")
			row["placeability"] = place_check
			if only_placeable and not bool(place_check.get("ok", false)):
				continue
		rows.append(row)
	categories.sort()
	roles.sort()
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.get("display_name", a.get("id", ""))) < String(b.get("display_name", b.get("id", ""))))
	return {"ok": true, "rows": rows, "categories": categories, "roles": roles, "message": "OK"}

func is_map_constructor_item_prefab(prefab_id: String) -> bool:
	return prefab_id in ["mechanical_key", "digital_key", "access_code"]

func _map_constructor_entity_kind(object_data: Dictionary) -> String:
	var object_group: String = String(object_data.get("object_group", "")).to_lower()
	var object_type: String = String(object_data.get("object_type", "")).to_lower()
	var prefab_id: String = String(object_data.get("map_constructor_prefab_id", object_type)).to_lower()
	var classifier: String = "%s|%s|%s" % [object_group, object_type, prefab_id]
	if "door" in classifier or "gate" in classifier:
		return "door"
	if "terminal" in classifier:
		return "terminal"
	if "power" in classifier or "socket" in classifier or "cable" in classifier or "switch" in classifier or "fuse" in classifier or "cool" in classifier or "control" in classifier:
		return "power_control_cooling"
	if object_group == "item" or object_type == "item" or is_map_constructor_item_prefab(prefab_id):
		return "item"
	return "generic"

func get_default_map_constructor_field_value(field_name: String, entity_kind: String, data: Dictionary) -> Variant:
	var normalized_field: String = field_name.strip_edges()
	match normalized_field:
		"is_open":
			return false
		"is_locked":
			return false
		"is_powered":
			return true
		"requires_external_control":
			return false
		"requires_terminal_enabled":
			return false
		"requires_external_power":
			return false
		"damaged":
			return false
		"current_heat":
			return 0
		"working_heat":
			return 0
		"overheat_threshold":
			return 999999
		"required_connector_level":
			return 0
		"required_processor_level":
			return 0
		"item_type":
			if data.has("item_type"):
				return data.get("item_type")
			return "item"
	if normalized_field == "connected_device_ids":
		if entity_kind == "item":
			return null
		return []
	if normalized_field in ["state", "power_network_id", "required_key_id", "lock_type", "linked_terminal_id", "target_door_id", "target_platform_id", "control_source_id", "digital_state", "key_kind"]:
		return ""
	return null


func _is_wall_or_boundary_cell(cell: Vector2i) -> bool:
	if grid_manager == null or not grid_manager.has_method("get_tile"):
		return false
	if not _is_valid_grid_cell(cell):
		return false
	if grid_manager.has_method("is_boundary_cell") and bool(grid_manager.call("is_boundary_cell", cell)):
		return true
	return int(grid_manager.call("get_tile", cell)) == GridManager.TILE_WALL

func _get_map_constructor_wall_side_delta(side_id: String) -> Vector2i:
	match side_id.to_lower().strip_edges():
		"north":
			return Vector2i(0, -1)
		"east":
			return Vector2i(1, 0)
		"south":
			return Vector2i(0, 1)
		"west":
			return Vector2i(-1, 0)
		_:
			return Vector2i.ZERO

func _get_map_constructor_wall_side_label(side_id: String) -> String:
	match side_id.to_lower().strip_edges():
		"north":
			return "North"
		"east":
			return "East"
		"south":
			return "South"
		"west":
			return "West"
		_:
			return side_id.capitalize()

func _serialize_wall_material_override_key(cell: Vector2i, side: String) -> String:
	var normalized_side: String = side.to_lower().strip_edges()
	return "%s|%s" % [_serialize_cell_key(cell), normalized_side]

func get_map_constructor_wall_material_catalog() -> Dictionary:
	var materials: Array[Dictionary] = [
		{"id":"default_metal","display_name":"Default Metal","description":"Baseline steel alloy wall finish.","tags":["default","metal"],"style":"default","fallback_color":Color(0.33, 0.37, 0.43, 0.98),"edge_color":Color(0.62, 0.67, 0.75, 1.0),"damage_level":0,"is_default":true},
		{"id":"clean_lab","display_name":"Clean Lab","description":"Clean sterile laboratory paneling.","tags":["lab","clean"],"style":"clean","fallback_color":Color(0.66, 0.72, 0.76, 0.98),"edge_color":Color(0.86, 0.9, 0.94, 1.0),"damage_level":0,"is_default":false},
		{"id":"dark_service","display_name":"Dark Service","description":"Low-light service tunnel plating.","tags":["service","dark"],"style":"dark","fallback_color":Color(0.18, 0.2, 0.24, 0.98),"edge_color":Color(0.32, 0.36, 0.41, 1.0),"damage_level":1,"is_default":false},
		{"id":"orange_hazard","display_name":"Orange Hazard","description":"Hazard-striped industrial wall section.","tags":["hazard","orange"],"style":"hazard","fallback_color":Color(0.48, 0.31, 0.16, 0.98),"edge_color":Color(0.96, 0.57, 0.21, 1.0),"damage_level":1,"is_default":false},
		{"id":"damaged_red","display_name":"Damaged Red","description":"Damaged emergency-painted wall.","tags":["damaged","red"],"style":"damaged","fallback_color":Color(0.42, 0.19, 0.2, 0.98),"edge_color":Color(0.84, 0.34, 0.37, 1.0),"damage_level":3,"is_default":false},
		{"id":"reinforced","display_name":"Reinforced","description":"Reinforced heavy-duty support wall.","tags":["reinforced","security"],"style":"reinforced","fallback_color":Color(0.24, 0.27, 0.33, 0.98),"edge_color":Color(0.55, 0.61, 0.72, 1.0),"damage_level":0,"is_default":false},
		{"id":"power_room","display_name":"Power Room","description":"Power distribution room insulation panels.","tags":["power","utility"],"style":"power","fallback_color":Color(0.28, 0.3, 0.21, 0.98),"edge_color":Color(0.71, 0.81, 0.34, 1.0),"damage_level":1,"is_default":false},
		{"id":"diagnostic_blue","display_name":"Diagnostic Blue","description":"Diagnostic bay blue marker finish.","tags":["diagnostic","blue"],"style":"diagnostic","fallback_color":Color(0.21, 0.3, 0.49, 0.98),"edge_color":Color(0.44, 0.69, 0.97, 1.0),"damage_level":0,"is_default":false}
	]
	return {"ok": true, "materials": materials, "message": "Wall material catalog ready."}

func _is_map_constructor_wall_cell(cell: Vector2i) -> bool:
	if grid_manager == null:
		return false
	if not grid_manager.has_method("is_in_bounds") or not bool(grid_manager.call("is_in_bounds", cell)):
		return false
	if grid_manager.has_method("get_tile"):
		return int(grid_manager.call("get_tile", cell)) == GridManager.TILE_WALL
	return false

func _resolve_wall_mounted_attachment(anchor_floor_cell: Vector2i, preferred_side: String = "") -> Dictionary:
	if grid_manager == null:
		return {"ok": false, "reason": "grid_unavailable", "message": "Blocked: grid unavailable."}
	var valid_attachments: Array[Dictionary] = []
	for side_entry in MAP_CONSTRUCTOR_WALL_SIDE_DELTAS:
		var side: String = String(side_entry.get("side", ""))
		var delta: Vector2i = Vector2i(side_entry.get("delta", Vector2i.ZERO))
		var wall_cell: Vector2i = anchor_floor_cell + delta
		if _is_wall_or_boundary_cell(wall_cell):
			valid_attachments.append({"side": side, "attached_wall_cell": wall_cell})
	if valid_attachments.is_empty():
		return {"ok": false, "reason": "no_adjacent_wall", "message": "Blocked: no adjacent wall.", "anchor_floor_cell": anchor_floor_cell}
	var selected: Dictionary = valid_attachments[0]
	var normalized_preferred: String = preferred_side.to_lower().strip_edges()
	if not normalized_preferred.is_empty():
		for attachment in valid_attachments:
			if String(attachment.get("side", "")) == normalized_preferred:
				selected = attachment
				break
	var available_sides: Array[String] = []
	for attachment in valid_attachments:
		available_sides.append(String(attachment.get("side", "")))
	return {
		"ok": true,
		"anchor_floor_cell": anchor_floor_cell,
		"attached_wall_cell": Vector2i(selected.get("attached_wall_cell", Vector2i(-1, -1))),
		"wall_side": String(selected.get("side", "north")),
		"available_wall_sides": available_sides
	}

func can_place_map_constructor_prefab(prefab_id: String, cell: Vector2i, preferred_wall_side: String = "") -> Dictionary:
	var result: Dictionary = {"ok": false, "reason": "unsupported_prefab", "message": "Blocked: unsupported prefab.", "cell_state": get_runtime_cell_state(cell)}
	var is_supported: bool = false
	for entry in get_map_constructor_prefab_catalog():
		if String(entry.get("id", "")) == prefab_id:
			is_supported = true
			break
	if not is_supported:
		return result
	var cell_state: Dictionary = get_runtime_cell_state(cell)
	result["cell_state"] = cell_state
	var prefab_is_item: bool = is_map_constructor_item_prefab(prefab_id)
	var prefab_is_wall_mounted: bool = bool(MAP_CONSTRUCTOR_WALL_MOUNTED_PREFABS.get(prefab_id, false))
	if not bool(cell_state.get("in_bounds", false)):
		result["reason"] = "wall_mounted_anchor_out_of_bounds" if prefab_is_wall_mounted else "out_of_bounds"
		result["message"] = "Cannot mount here: anchor floor cell is outside the map." if prefab_is_wall_mounted else "Blocked: out of bounds."
		return result
	if active_bipob_ref != null and Vector2i(active_bipob_ref.get("grid_position", Vector2i(-1, -1))) == cell:
		result["reason"] = "blocked_by_bipob" if prefab_is_wall_mounted else "occupied_by_bipob"
		result["message"] = "Cannot mount here: anchor cell is occupied by Bipob." if prefab_is_wall_mounted else "Blocked: existing object."
		return result
	var tile_type_value: int = int(cell_state.get("tile_type", -1))
	var tile_is_wall: bool = tile_type_value == GridManager.TILE_WALL
	var tile_is_door_or_gate: bool = tile_type_value == GridManager.TILE_DOOR or tile_type_value == GridManager.TILE_DIGITAL_DOOR or tile_type_value == GridManager.TILE_POWERED_GATE
	var tile_is_exit: bool = tile_type_value == GridManager.TILE_EXIT
	var tile_is_floor_like: bool = tile_type_value == GridManager.TILE_FLOOR or tile_type_value == GridManager.TILE_STEPPED_FLOOR
	var prefab_is_wall: bool = prefab_id.ends_with("_wall") or prefab_id == "outer_wall"
	var prefab_is_door_or_gate: bool = prefab_id == "mechanical_door" or prefab_id == "digital_door" or prefab_id == "powered_gate"
	var prefab_is_floor_replacement: bool = prefab_id == "floor" or prefab_id == "stepped_floor"
	if tile_is_exit and prefab_id != "powered_gate":
		result["reason"] = "exit_cell"
		result["message"] = "Blocked: exit cell."
		return result
	var has_static_wall_or_blocked_tile: bool = tile_is_wall or (not bool(cell_state.get("static_walkable", true)) and not tile_is_door_or_gate and not tile_is_exit)
	if has_static_wall_or_blocked_tile and not prefab_is_floor_replacement:
		result["reason"] = "wall_or_static"
		result["message"] = "Blocked: wall/static obstacle."
		return result
	var prefab_can_replace_non_floor: bool = prefab_is_wall or prefab_is_door_or_gate or prefab_is_floor_replacement
	if not tile_is_floor_like and not tile_is_exit and not prefab_can_replace_non_floor:
		result["reason"] = "non_floor_tile"
		result["message"] = "Blocked: non-floor tile."
		return result
	if (prefab_is_wall or prefab_is_door_or_gate) and not tile_is_floor_like:
		result["reason"] = "non_floor_tile"
		result["message"] = "Blocked: non-floor tile."
		return result
	if prefab_is_floor_replacement and not (tile_is_wall or tile_is_door_or_gate or tile_is_floor_like):
		result["reason"] = "non_floor_tile"
		result["message"] = "Blocked: non-floor tile."
		return result
	var existing_object: Dictionary = get_world_object_at_cell(cell)
	if not prefab_is_item and not existing_object.is_empty():
		result["reason"] = "existing_object"
		result["message"] = "Blocked: existing object."
		return result
	if bool(cell_state.get("has_object", false)) and bool(cell_state.get("blocks_movement", false)) and MAP_CONSTRUCTOR_SOLID_PREFABS.has(prefab_id):
		result["reason"] = "wall_or_static"
		result["message"] = "Blocked: wall/static obstacle."
		return result
	if bool(cell_state.get("has_object", false)):
		var existing_data: Dictionary = get_world_object_at_cell(cell)
		if bool(existing_data.get("mission_exit", false)) or bool(existing_data.get("extraction", false)):
			result["reason"] = "exit_cell"
			result["message"] = "Blocked: exit cell."
			return result
	if prefab_is_wall_mounted:
		result["placement_mode"] = "wall_mounted"
		result["anchor_floor_cell"] = _serialize_cell_key(cell)
		result["attached_wall_cell"] = "-1,-1"
		var normalized_side: String = preferred_wall_side.to_lower().strip_edges()
		if not normalized_side.is_empty() and _get_map_constructor_wall_side_delta(normalized_side) == Vector2i.ZERO:
			result["reason"] = "wall_mounted_wrong_side"
			result["message"] = "Cannot mount on %s: adjacent cell is not a wall." % _get_map_constructor_wall_side_label(preferred_wall_side)
			return result
		var available_sides: Array[String] = []
		for side_entry in MAP_CONSTRUCTOR_WALL_SIDE_DELTAS:
			var side_id: String = String(side_entry.get("side", ""))
			var wall_cell: Vector2i = cell + _get_map_constructor_wall_side_delta(side_id)
			if _is_map_constructor_wall_cell(wall_cell):
				available_sides.append(side_id)
		result["available_wall_sides"] = available_sides
		if available_sides.is_empty():
			result["reason"] = "wall_mounted_no_wall"
			result["message"] = "Cannot mount here: no adjacent wall around anchor cell."
			return result
		if normalized_side.is_empty():
			normalized_side = available_sides[0]
		if not available_sides.has(normalized_side):
			result["wall_side"] = normalized_side
			result["reason"] = "wall_mounted_wrong_side"
			result["message"] = "Cannot mount on %s: adjacent cell is not a wall." % _get_map_constructor_wall_side_label(normalized_side)
			return result
		var attached_wall_cell: Vector2i = cell + _get_map_constructor_wall_side_delta(normalized_side)
		result["attached_wall_cell"] = _serialize_cell_key(attached_wall_cell)
		result["wall_side"] = normalized_side
		for object_data in mission_world_objects:
			if String(object_data.get("placement_mode", "")) != "wall_mounted":
				continue
			if _deserialize_cell_variant(object_data.get("anchor_floor_cell", "")) == cell and String(object_data.get("wall_side", "")).to_lower() == normalized_side:
				result["reason"] = "wall_mounted_side_occupied"
				result["message"] = "Cannot mount on %s: wall side already has a mounted object." % _get_map_constructor_wall_side_label(normalized_side)
				return result
	if prefab_id != "powered_gate":
		var tile_name: String = String(cell_state.get("tile_name", "")).to_lower()
		if tile_name.find("exit") >= 0 or tile_name.find("extraction") >= 0:
			result["reason"] = "exit_cell"
			result["message"] = "Blocked: exit cell."
			return result
	result["ok"] = true
	result["reason"] = "ok"
	result["message"] = "OK"
	return result

func place_map_constructor_prefab(prefab_id: String, cell: Vector2i, preferred_wall_side: String = "") -> Dictionary:
	var check: Dictionary = can_place_map_constructor_prefab(prefab_id, cell, preferred_wall_side)
	if not bool(check.get("ok", false)):
		return check
	var result: Dictionary = {"ok": true, "message": "Placed %s." % prefab_id, "object_id": "", "warnings": []}
	var previous_tile_type: int = GridManager.TILE_FLOOR
	if grid_manager != null and grid_manager.has_method("get_tile"):
		previous_tile_type = int(grid_manager.call("get_tile", cell))
	if prefab_id == "floor":
		grid_manager.call("set_tile", cell, GridManager.TILE_FLOOR)
		_record_map_constructor_change("place", {"entity_kind":"tile", "object_type":"floor", "cell":cell, "summary":"Placed floor at %s" % _format_map_constructor_cell(cell), "undo_hint":"Use constructor cleanup/reset tools if needed."})
		return result
	if prefab_id == "stepped_floor":
		grid_manager.call("set_tile", cell, GridManager.TILE_STEPPED_FLOOR)
		_record_map_constructor_change("place", {"entity_kind":"tile", "object_type":"stepped_floor", "cell":cell, "summary":"Placed stepped_floor at %s" % _format_map_constructor_cell(cell), "undo_hint":"Use constructor cleanup/reset tools if needed."})
		return result
	if is_map_constructor_item_prefab(prefab_id):
		var object_id: String = "mapedit_%s_%d" % [prefab_id, _map_constructor_runtime_object_seq]
		_map_constructor_runtime_object_seq += 1
		var item_type: String = prefab_id
		if prefab_id == "mechanical_key":
			item_type = "mechanical_keycard"
		var item_data: Dictionary = {
			"id": object_id,
			"object_group": "item",
			"object_type": "item",
			"item_type": item_type,
			"position": cell,
			"created_by_map_constructor": true,
			"map_constructor_prefab_id": prefab_id
		}
		add_item_at_cell(cell, item_data)
		PowerSystemRef.recalculate_network(mission_world_objects, "")
		refresh_world_cooling_received()
		result["object_id"] = object_id
		_record_map_constructor_change("place", {"entity_kind":"item", "entity_id":object_id, "object_type":item_type, "cell":cell, "summary":"Placed %s at %s" % [item_type, _format_map_constructor_cell(cell)], "undo_hint":"Can undo by deleting item."})
		return result
	var placed_tile_type: int = previous_tile_type
	if prefab_id.ends_with("_wall") or prefab_id == "outer_wall":
		placed_tile_type = GridManager.TILE_WALL
		grid_manager.call("set_tile", cell, placed_tile_type)
	elif prefab_id == "mechanical_door":
		placed_tile_type = GridManager.TILE_DOOR
		grid_manager.call("set_tile", cell, placed_tile_type)
	elif prefab_id == "digital_door":
		placed_tile_type = GridManager.TILE_DIGITAL_DOOR
		grid_manager.call("set_tile", cell, placed_tile_type)
	elif prefab_id == "powered_gate":
		placed_tile_type = GridManager.TILE_POWERED_GATE
		grid_manager.call("set_tile", cell, placed_tile_type)
	var object_id: String = "mapedit_%s_%d" % [prefab_id, _map_constructor_runtime_object_seq]
	_map_constructor_runtime_object_seq += 1
	var object_data: Dictionary = {
		"id": object_id,
		"object_type": prefab_id,
		"position": cell,
		"display_name": prefab_id.capitalize(),
		"state": "active",
		"created_by_map_constructor": true,
		"map_constructor_prefab_id": prefab_id,
		"map_constructor_tile_type": placed_tile_type,
		"map_constructor_previous_tile_type": previous_tile_type
	}
	if bool(MAP_CONSTRUCTOR_WALL_MOUNTED_PREFABS.get(prefab_id, false)):
		var attachment: Dictionary = _resolve_wall_mounted_attachment(cell, preferred_wall_side)
		if not bool(attachment.get("ok", false)):
			return {"ok": false, "reason": String(attachment.get("reason", "no_adjacent_wall")), "message": String(attachment.get("message", "Blocked: no adjacent wall.")), "object_id": "", "warnings": []}
		var attached_wall_cell: Vector2i = Vector2i(attachment.get("attached_wall_cell", Vector2i(-1, -1)))
		if not _is_wall_or_boundary_cell(attached_wall_cell):
			return {"ok": false, "reason": "invalid_wall_attachment", "message": "Blocked: attached wall cell is not wall/boundary.", "object_id": "", "warnings": []}
		object_data["placement_mode"] = "wall_mounted"
		object_data["anchor_floor_cell"] = _serialize_cell_key(cell)
		object_data["attached_wall_cell"] = _serialize_cell_key(attached_wall_cell)
		object_data["wall_side"] = String(attachment.get("wall_side", "north"))
	set_world_object_at_cell(cell, object_data)
	PowerSystemRef.recalculate_network(mission_world_objects, String(object_data.get("power_network_id", "")))
	refresh_world_cooling_received()
	result["object_id"] = object_id
	_record_map_constructor_change("place", {"entity_kind":"world_object", "entity_id":object_id, "object_type":prefab_id, "cell":cell, "summary":"Placed %s at %s" % [prefab_id, _format_map_constructor_cell(cell)], "undo_hint":"Can undo by deleting object."})
	return result


func _remove_map_constructor_entity_by_id(entity_kind: String, entity_id: String) -> Dictionary:
	if entity_kind == "item":
		for cell_variant in cell_items.keys():
			var cell: Vector2i = Vector2i(cell_variant)
			var items: Array[Dictionary] = get_items_at_cell(cell)
			for index in range(items.size() - 1, -1, -1):
				var item_data: Dictionary = items[index]
				if String(item_data.get("id", "")) != entity_id:
					continue
				if not bool(item_data.get("created_by_map_constructor", false)):
					return {"ok": false, "message": "Cannot remove non-constructor item.", "object_id": entity_id, "warnings": []}
				items.remove_at(index)
				cell_items[cell] = items
				mission_world_objects.erase(item_data)
				PowerSystemRef.recalculate_network(mission_world_objects, "")
				refresh_world_cooling_received()
				_record_map_constructor_change("delete", {"entity_kind":"item", "entity_id":entity_id, "object_type":String(item_data.get("item_type", item_data.get("object_type", "item"))), "cell":cell, "summary":"Deleted item %s" % entity_id, "undo_hint":"Cannot directly undo; use cleanup/autofix/patch undo systems when applicable."})
				return {"ok": true, "message": "Removed item.", "object_id": entity_id, "warnings": []}
		return {"ok": false, "message": "Nothing to remove.", "object_id": "", "warnings": []}
	var object_data: Dictionary = get_world_object_by_id(entity_id)
	if object_data.is_empty():
		return {"ok": false, "message": "Nothing to remove.", "object_id": "", "warnings": []}
	if not bool(object_data.get("created_by_map_constructor", false)):
		return {"ok": false, "message": "Cannot remove non-constructor object.", "object_id": entity_id, "warnings": []}
	var object_cell: Vector2i = Vector2i(object_data.get("position", Vector2i(-1, -1)))
	var removed_network_id: String = String(object_data.get("power_network_id", ""))
	if grid_manager != null and grid_manager.has_method("set_tile"):
		var restore_tile_type: int = GridManager.TILE_FLOOR
		if object_data.has("map_constructor_previous_tile_type"):
			restore_tile_type = int(object_data.get("map_constructor_previous_tile_type", GridManager.TILE_FLOOR))
		grid_manager.call("set_tile", object_cell, restore_tile_type)
	remove_world_object_at_cell(object_cell)
	PowerSystemRef.recalculate_network(mission_world_objects, removed_network_id)
	refresh_world_cooling_received()
	_record_map_constructor_change("delete", {"entity_kind":"world_object", "entity_id":entity_id, "object_type":String(object_data.get("object_type", "")), "cell":object_cell, "summary":"Deleted %s %s" % [String(object_data.get("object_type", "object")), entity_id], "undo_hint":"Cannot directly undo; use cleanup/autofix/patch undo systems when applicable."})
	return {"ok": true, "message": "Removed object.", "object_id": entity_id, "warnings": []}

func _clone_map_constructor_entity_data(source_data: Dictionary, target_cell: Vector2i, preferred_wall_side: String, assign_new_id: bool) -> Dictionary:
	var clone_data: Dictionary = Dictionary(source_data).duplicate(true)
	if assign_new_id:
		var prefab_id: String = String(clone_data.get("map_constructor_prefab_id", clone_data.get("object_type", "object")))
		clone_data["id"] = "mapedit_%s_%d" % [prefab_id, _map_constructor_runtime_object_seq]
		_map_constructor_runtime_object_seq += 1
	clone_data.erase("position")
	clone_data.erase("anchor_floor_cell")
	clone_data.erase("attached_wall_cell")
	clone_data.erase("wall_side")
	clone_data.erase("map_constructor_previous_tile_type")
	clone_data["position"] = target_cell
	if String(clone_data.get("placement_mode", "")) == "wall_mounted":
		var resolved_side: String = preferred_wall_side.strip_edges()
		if resolved_side.is_empty():
			resolved_side = String(source_data.get("wall_side", ""))
		var attachment: Dictionary = _resolve_wall_mounted_attachment(target_cell, resolved_side)
		if not bool(attachment.get("ok", false)):
			return {"ok": false, "message": String(attachment.get("message", "Blocked: no adjacent wall."))}
		clone_data["placement_mode"] = "wall_mounted"
		clone_data["anchor_floor_cell"] = _serialize_cell_key(target_cell)
		clone_data["attached_wall_cell"] = _serialize_cell_key(Vector2i(attachment.get("attached_wall_cell", Vector2i(-1, -1))))
		clone_data["wall_side"] = String(attachment.get("wall_side", "north"))
	return {"ok": true, "data": clone_data}

func move_map_constructor_entity_to_cell(entity_kind: String, entity_id: String, target_cell: Vector2i, preferred_wall_side: String = "") -> Dictionary:
	var entity: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
	if not bool(entity.get("ok", false)):
		return {"ok": false, "message": "Move failed: entity not found."}
	var data: Dictionary = Dictionary(entity.get("data", {}))
	var source_cell: Vector2i = Vector2i(entity.get("cell", Vector2i(-1, -1)))
	var prefab_id: String = String(data.get("map_constructor_prefab_id", data.get("object_type", "")))
	var place_check: Dictionary = can_place_map_constructor_prefab(prefab_id, target_cell, preferred_wall_side)
	if not bool(place_check.get("ok", false)):
		return {"ok": false, "message": String(place_check.get("message", "Move failed."))}
	var clone_result: Dictionary = _clone_map_constructor_entity_data(data, target_cell, preferred_wall_side, false)
	if not bool(clone_result.get("ok", false)):
		return {"ok": false, "message": String(clone_result.get("message", "Move failed."))}
	var cloned_data: Dictionary = Dictionary(clone_result.get("data", {}))
	var remove_result: Dictionary = _remove_map_constructor_entity_by_id(String(entity.get("entity_kind", entity_kind)), entity_id)
	if not bool(remove_result.get("ok", false)):
		return {"ok": false, "message": String(remove_result.get("message", "Move failed."))}
	if entity_kind == "item" or String(entity.get("entity_kind", entity_kind)) == "item":
		add_item_at_cell(target_cell, cloned_data)
		PowerSystemRef.recalculate_network(mission_world_objects, "")
		refresh_world_cooling_received()
		_record_map_constructor_change("move", {"entity_kind":"item", "entity_id":String(cloned_data.get("id", "")), "object_type":String(cloned_data.get("item_type", cloned_data.get("object_type", "item"))), "cell":target_cell, "summary":"Moved object %s from %s to %s" % [String(cloned_data.get("id", "")), _format_map_constructor_cell(source_cell), _format_map_constructor_cell(target_cell)], "details":{"from_cell":source_cell, "to_cell":target_cell}, "undo_hint":"Move back manually."})
		return {"ok": true, "message": "Moved object.", "object_id": String(cloned_data.get("id", ""))}
	var previous_tile_type: int = GridManager.TILE_FLOOR
	if grid_manager != null and grid_manager.has_method("get_tile"):
		previous_tile_type = int(grid_manager.call("get_tile", target_cell))
	cloned_data["map_constructor_previous_tile_type"] = previous_tile_type
	if grid_manager != null and grid_manager.has_method("set_tile"):
		grid_manager.call("set_tile", target_cell, int(cloned_data.get("map_constructor_tile_type", previous_tile_type)))
	set_world_object_at_cell(target_cell, cloned_data)
	PowerSystemRef.recalculate_network(mission_world_objects, String(cloned_data.get("power_network_id", "")))
	refresh_world_cooling_received()
	_record_map_constructor_change("move", {"entity_kind":"world_object", "entity_id":String(cloned_data.get("id", "")), "object_type":String(cloned_data.get("object_type", "")), "cell":target_cell, "summary":"Moved object %s from %s to %s" % [String(cloned_data.get("id", "")), _format_map_constructor_cell(source_cell), _format_map_constructor_cell(target_cell)], "details":{"from_cell":source_cell, "to_cell":target_cell}, "undo_hint":"Move back manually."})
	return {"ok": true, "message": "Moved object.", "object_id": String(cloned_data.get("id", ""))}

func duplicate_map_constructor_entity_to_cell(entity_kind: String, entity_id: String, target_cell: Vector2i, preferred_wall_side: String = "") -> Dictionary:
	var entity: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
	if not bool(entity.get("ok", false)):
		return {"ok": false, "message": "Duplicate failed: entity not found."}
	var data: Dictionary = Dictionary(entity.get("data", {}))
	var prefab_id: String = String(data.get("map_constructor_prefab_id", data.get("object_type", "")))
	var place_check: Dictionary = can_place_map_constructor_prefab(prefab_id, target_cell, preferred_wall_side)
	if not bool(place_check.get("ok", false)):
		return {"ok": false, "message": String(place_check.get("message", "Duplicate failed."))}
	var clone_result: Dictionary = _clone_map_constructor_entity_data(data, target_cell, preferred_wall_side, true)
	if not bool(clone_result.get("ok", false)):
		return {"ok": false, "message": String(clone_result.get("message", "Duplicate failed."))}
	var cloned_data: Dictionary = Dictionary(clone_result.get("data", {}))
	if entity_kind == "item" or String(entity.get("entity_kind", entity_kind)) == "item":
		add_item_at_cell(target_cell, cloned_data)
		PowerSystemRef.recalculate_network(mission_world_objects, "")
		refresh_world_cooling_received()
		_record_map_constructor_change("duplicate", {"entity_kind":"item", "entity_id":String(cloned_data.get("id", "")), "object_type":String(cloned_data.get("item_type", cloned_data.get("object_type", "item"))), "cell":target_cell, "summary":"Duplicated object %s to %s" % [entity_id, _format_map_constructor_cell(target_cell)], "details":{"source_entity_id":entity_id}, "undo_hint":"Can undo by deleting duplicate."})
		return {"ok": true, "message": "Duplicated object.", "object_id": String(cloned_data.get("id", ""))}
	var previous_tile_type: int = GridManager.TILE_FLOOR
	if grid_manager != null and grid_manager.has_method("get_tile"):
		previous_tile_type = int(grid_manager.call("get_tile", target_cell))
	cloned_data["map_constructor_previous_tile_type"] = previous_tile_type
	if grid_manager != null and grid_manager.has_method("set_tile"):
		grid_manager.call("set_tile", target_cell, int(cloned_data.get("map_constructor_tile_type", previous_tile_type)))
	set_world_object_at_cell(target_cell, cloned_data)
	PowerSystemRef.recalculate_network(mission_world_objects, String(cloned_data.get("power_network_id", "")))
	refresh_world_cooling_received()
	_record_map_constructor_change("duplicate", {"entity_kind":"world_object", "entity_id":String(cloned_data.get("id", "")), "object_type":String(cloned_data.get("object_type", "")), "cell":target_cell, "summary":"Duplicated object %s to %s" % [entity_id, _format_map_constructor_cell(target_cell)], "details":{"source_entity_id":entity_id}, "undo_hint":"Can undo by deleting duplicate."})
	return {"ok": true, "message": "Duplicated object.", "object_id": String(cloned_data.get("id", ""))}

func _normalize_map_constructor_batch_offset(options: Dictionary) -> Vector2i:
	var offset_variant: Variant = options.get("offset", Vector2i.ZERO)
	if offset_variant is Vector2i:
		return Vector2i(offset_variant)
	if offset_variant is Dictionary:
		return Vector2i(int(offset_variant.get("x", 0)), int(offset_variant.get("y", 0)))
	return Vector2i.ZERO

func _is_map_constructor_batch_protected_entity(entity_id: String) -> bool:
	return entity_id in ["bipob_start", "mission_exit", "constructor_start_marker", "constructor_exit_marker"]

func preview_map_constructor_batch_operation(operation_type: String, entities: Array[Dictionary], options: Dictionary = {}) -> Dictionary:
	if current_mission_id != "mission_10":
		return {"ok": false, "operation_type": operation_type, "message": "Batch tools available only in TASK TEST.", "affected_count": 0, "affected": [], "warnings": [], "conflicts": [], "can_apply": false}
	var op: String = operation_type.to_lower().strip_edges()
	var include_non_constructor: bool = bool(options.get("include_non_constructor", false))
	var offset: Vector2i = _normalize_map_constructor_batch_offset(options)
	var warnings: Array[String] = []
	var conflicts: Array[Dictionary] = []
	var affected: Array[Dictionary] = []
	var seen: Dictionary = {}
	for row in entities:
		var entity_kind: String = String(row.get("entity_kind", "")).to_lower()
		var entity_id: String = String(row.get("entity_id", ""))
		if entity_id.is_empty() or seen.has("%s|%s" % [entity_kind, entity_id]):
			continue
		seen["%s|%s" % [entity_kind, entity_id]] = true
		if _is_map_constructor_batch_protected_entity(entity_id):
			conflicts.append({"entity_id":entity_id, "reason":"protected_id"})
			continue
		var entity: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
		if not bool(entity.get("ok", false)):
			warnings.append("Skipped stale entity %s." % entity_id)
			continue
		var data: Dictionary = Dictionary(entity.get("data", {}))
		if not include_non_constructor and not bool(data.get("created_by_map_constructor", false)):
			conflicts.append({"entity_id":entity_id, "reason":"non_constructor"})
			continue
		var from_cell: Vector2i = Vector2i(entity.get("cell", Vector2i(-1, -1)))
		var to_cell: Vector2i = from_cell + offset
		var op_row: Dictionary = {"entity_kind":entity_kind, "entity_id":entity_id, "object_type":String(data.get("object_type", data.get("item_type", ""))), "from_cell":from_cell, "to_cell":to_cell, "operation":"update", "field_changes":[], "message":"OK"}
		if op == "delete_selected":
			op_row["operation"] = "delete"
		elif op == "assign_power_network":
			op_row["operation"] = "update"
			if entity_kind != "world_object":
				warnings.append("Item %s skipped for power assignment." % entity_id)
				continue
			op_row["field_changes"] = [{"field":"power_network_id", "new":String(options.get("power_network_id", ""))}]
		elif op == "clear_broken_references":
			op_row["operation"] = "update"
		elif op == "move_selected" or op == "duplicate_selected":
			op_row["operation"] = "move" if op == "move_selected" else "duplicate"
			var prefab_id: String = String(data.get("map_constructor_prefab_id", data.get("object_type", "")))
			var check: Dictionary = can_place_map_constructor_prefab(prefab_id, to_cell, String(data.get("wall_side", "")))
			if not bool(check.get("ok", false)):
				conflicts.append({"entity_id":entity_id, "from_cell":from_cell, "to_cell":to_cell, "reason":String(check.get("reason", "blocked")), "message":String(check.get("message", "Blocked."))})
				continue
		else:
			return {"ok": false, "operation_type": operation_type, "message": "Unsupported operation.", "affected_count": 0, "affected": [], "warnings": [], "conflicts": [], "can_apply": false}
		affected.append(op_row)
	var allow_partial: bool = bool(options.get("allow_partial", false))
	var can_apply: bool = not affected.is_empty() and (conflicts.is_empty() or allow_partial)
	return {"ok": true, "operation_type": op, "message": "Preview ready.", "affected_count": affected.size(), "affected": affected, "warnings": warnings, "conflicts": conflicts, "can_apply": can_apply}

func apply_map_constructor_batch_operation(operation_type: String, entities: Array[Dictionary], options: Dictionary = {}) -> Dictionary:
	var preview: Dictionary = preview_map_constructor_batch_operation(operation_type, entities, options)
	if not bool(preview.get("ok", false)) or not bool(preview.get("can_apply", false)):
		return {"ok": false, "message": String(preview.get("message", "Cannot apply.")), "applied_count": 0, "warnings": Array(preview.get("warnings", [])), "conflicts": Array(preview.get("conflicts", [])), "batch_id": ""}
	_map_constructor_last_batch_snapshot = {"batch_id":"batch_%d" % int(Time.get_unix_time_from_system()), "mission_world_objects": mission_world_objects.duplicate(true), "cell_items": cell_items.duplicate(true), "world_objects_by_cell": world_objects_by_cell.duplicate(true)}
	var applied_count: int = 0
	for row_variant in Array(preview.get("affected", [])):
		var row: Dictionary = Dictionary(row_variant)
		var ek: String = String(row.get("entity_kind", ""))
		var eid: String = String(row.get("entity_id", ""))
		var to_cell: Vector2i = Vector2i(row.get("to_cell", Vector2i(-1, -1)))
		match String(preview.get("operation_type", "")):
			"delete_selected":
				if bool(_remove_map_constructor_entity_by_id(ek, eid).get("ok", false)): applied_count += 1
			"move_selected":
				if bool(move_map_constructor_entity_to_cell(ek, eid, to_cell, "").get("ok", false)): applied_count += 1
			"duplicate_selected":
				if bool(duplicate_map_constructor_entity_to_cell(ek, eid, to_cell, "").get("ok", false)): applied_count += 1
			"assign_power_network":
				var update: Dictionary = apply_map_constructor_property_update(ek, eid, "power_network_id", String(options.get("power_network_id", "")))
				if bool(update.get("ok", false)):
					applied_count += 1
			"clear_broken_references":
				if ek != "world_object":
					continue
				var world_ids: Dictionary = _map_constructor_collect_world_ids()
				var item_ids: Dictionary = _map_constructor_collect_item_ids()
				var entity_info: Dictionary = get_map_constructor_entity_by_id(ek, eid)
				if not bool(entity_info.get("ok", false)):
					continue
				var data: Dictionary = Dictionary(entity_info.get("data", {}))
				var cleared_any: bool = false
				for ref_field in ["target_door_id", "target_platform_id", "linked_terminal_id", "control_source_id", "required_key_id"]:
					var ref_id: String = String(data.get(ref_field, "")).strip_edges()
					if ref_id.is_empty():
						continue
					var ref_valid: bool = world_ids.has(ref_id) or (ref_field == "required_key_id" and item_ids.has(ref_id))
					if ref_valid:
						continue
					var clear_result: Dictionary = apply_map_constructor_property_update(ek, eid, ref_field, "")
					if bool(clear_result.get("ok", false)):
						cleared_any = true
				var connected_ids: Array[String] = []
				var connected_valid_ids: Array[String] = []
				for connected_id_variant in Array(data.get("connected_device_ids", [])):
					var connected_id: String = String(connected_id_variant).strip_edges()
					if connected_id.is_empty():
						continue
					connected_ids.append(connected_id)
					if world_ids.has(connected_id) or item_ids.has(connected_id):
						connected_valid_ids.append(connected_id)
				if connected_valid_ids.size() != connected_ids.size():
					var connected_update: Dictionary = apply_map_constructor_property_update(ek, eid, "connected_device_ids", connected_valid_ids)
					if bool(connected_update.get("ok", false)):
						cleared_any = true
				if cleared_any:
					applied_count += 1
	PowerSystemRef.recalculate_network(mission_world_objects, "")
	refresh_world_cooling_received()
	_record_map_constructor_change("batch", {"summary":"Batch %s: %d affected" % [String(preview.get("operation_type", "")), applied_count], "details":{"operation_type":String(preview.get("operation_type", "")), "affected_count":applied_count}, "undo_hint":"Use Undo Last Batch."})
	return {"ok": true, "message": "Batch applied.", "applied_count": applied_count, "warnings": Array(preview.get("warnings", [])), "conflicts": Array(preview.get("conflicts", [])), "batch_id": String(_map_constructor_last_batch_snapshot.get("batch_id", ""))}

func undo_last_map_constructor_batch_operation() -> Dictionary:
	if _map_constructor_last_batch_snapshot.is_empty():
		return {"ok": false, "message": "No batch operation to undo."}
	mission_world_objects = Array(_map_constructor_last_batch_snapshot.get("mission_world_objects", [])).duplicate(true)
	cell_items = Dictionary(_map_constructor_last_batch_snapshot.get("cell_items", {})).duplicate(true)
	world_objects_by_cell = Dictionary(_map_constructor_last_batch_snapshot.get("world_objects_by_cell", {})).duplicate(true)
	_map_constructor_last_batch_snapshot.clear()
	PowerSystemRef.recalculate_network(mission_world_objects, "")
	refresh_world_cooling_received()
	_record_map_constructor_change("batch_undo", {"summary":"Undid last batch operation.", "undo_hint":"Re-apply batch manually if needed."})
	return {"ok": true, "message": "Last batch operation undone."}

func remove_map_constructor_object_at_cell(cell: Vector2i) -> Dictionary:
	var entity: Dictionary = get_map_constructor_editable_entity_at_cell(cell)
	if not bool(entity.get("ok", false)):
		return {"ok": false, "message": "Nothing to remove.", "object_id": "", "warnings": []}
	return _remove_map_constructor_entity_by_id(String(entity.get("entity_kind", "")), String(entity.get("id", "")))

func _get_map_constructor_wall_mounted_match_score(object_data: Dictionary, cell: Vector2i) -> int:
	if String(object_data.get("placement_mode", "")) != "wall_mounted":
		return -1
	var object_cell: Vector2i = Vector2i(object_data.get("position", Vector2i(-1, -1)))
	if object_cell == cell:
		return 300
	var anchor_cell: Vector2i = _deserialize_cell_variant(object_data.get("anchor_floor_cell", ""))
	if anchor_cell == cell:
		return 200
	var attached_cell: Vector2i = _deserialize_cell_variant(object_data.get("attached_wall_cell", ""))
	if attached_cell == cell:
		return 100
	return -1

func _get_map_constructor_best_wall_mounted_entity_at_cell(cell: Vector2i) -> Dictionary:
	var best_score: int = -1
	var best_entity: Dictionary = {}
	for object_data in mission_world_objects:
		var score: int = _get_map_constructor_wall_mounted_match_score(object_data, cell)
		if score > best_score:
			best_score = score
			best_entity = object_data
	if best_score < 0 or best_entity.is_empty():
		return {"ok": false, "reason": "not_found"}
	return {
		"ok": true,
		"entity_kind": "world_object",
		"id": String(best_entity.get("id", "")),
		"cell": Vector2i(best_entity.get("position", cell)),
		"data": best_entity
	}

func get_map_constructor_editable_entity_at_cell(cell: Vector2i) -> Dictionary:
	var object_data: Dictionary = get_world_object_at_cell(cell)
	if not object_data.is_empty():
		return {"ok": true, "entity_kind": "world_object", "id": String(object_data.get("id", "")), "cell": cell, "data": object_data}
	var wall_mounted_entity: Dictionary = _get_map_constructor_best_wall_mounted_entity_at_cell(cell)
	if bool(wall_mounted_entity.get("ok", false)):
		return wall_mounted_entity
	var items: Array[Dictionary] = get_items_at_cell(cell)
	if not items.is_empty():
		var item_data: Dictionary = items[0]
		return {"ok": true, "entity_kind": "item", "id": String(item_data.get("id", "")), "cell": cell, "data": item_data}
	return {"ok": false, "reason": "empty_cell"}


func get_map_constructor_wall_mounted_status(entity_kind: String, entity_id: String) -> Dictionary:
	var entity: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
	if not bool(entity.get("ok", false)):
		return {"ok": false, "reason": "missing_entity", "message": "Wall-mounted object not found."}
	var data: Dictionary = Dictionary(entity.get("data", {}))
	if String(data.get("placement_mode", "")) != "wall_mounted":
		return {"ok": true, "reason": "not_wall_mounted", "message": "Not a wall-mounted object."}
	var anchor: Vector2i = _deserialize_cell_variant(data.get("anchor_floor_cell", ""))
	var attached: Vector2i = _deserialize_cell_variant(data.get("attached_wall_cell", ""))
	var side: String = String(data.get("wall_side", "")).to_lower().strip_edges()
	var available: Array[String] = []
	for e in MAP_CONSTRUCTOR_WALL_SIDE_DELTAS:
		var s: String = String(e.get("side", ""))
		if _is_map_constructor_wall_cell(anchor + _get_map_constructor_wall_side_delta(s)):
			available.append(s)
	var base := {"ok": true, "reason": "ok", "message": "Wall-mounted object is valid.", "anchor_floor_cell": anchor, "attached_wall_cell": attached, "wall_side": side, "available_wall_sides": available}
	if not _is_valid_grid_cell(anchor):
		base["ok"]=false; base["reason"]="wall_mounted_broken_anchor"; base["message"]="Wall-mounted object has broken anchor metadata."; return base
	if _get_map_constructor_wall_side_delta(side) == Vector2i.ZERO:
		base["ok"]=false; base["reason"]="wall_mounted_wrong_side"; base["message"]="Cannot mount on %s: adjacent cell is not a wall." % _get_map_constructor_wall_side_label(side); return base
	if anchor + _get_map_constructor_wall_side_delta(side) != attached:
		base["ok"]=false; base["reason"]="wall_mounted_broken_anchor"; base["message"]="Wall-mounted object has broken anchor metadata."; return base
	if not _is_map_constructor_wall_cell(attached):
		base["ok"]=false; base["reason"]="wall_mounted_attached_wall_missing"; base["message"]="Attached wall was removed. Choose another side, move the object, or delete it."; return base
	return base

func set_map_constructor_wall_mounted_side(entity_kind: String, entity_id: String, new_wall_side: String) -> Dictionary:
	var status: Dictionary = get_map_constructor_wall_mounted_status(entity_kind, entity_id)
	if not bool(status.get("ok", false)) and String(status.get("reason", "")) != "wall_mounted_attached_wall_missing":
		return status
	var entity: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
	if not bool(entity.get("ok", false)):
		return {"ok": false, "reason": "missing_entity", "message": "Wall-mounted object not found."}
	var data: Dictionary = Dictionary(entity.get("data", {}))
	if String(data.get("placement_mode", "")) != "wall_mounted" or not bool(data.get("created_by_map_constructor", false)):
		return {"ok": false, "reason": "not_wall_mounted", "message": "Not a wall-mounted object."}
	var side: String = new_wall_side.to_lower().strip_edges()
	if _get_map_constructor_wall_side_delta(side) == Vector2i.ZERO:
		return {"ok": false, "reason": "wall_mounted_wrong_side", "message": "Cannot mount on %s: adjacent cell is not a wall." % _get_map_constructor_wall_side_label(side)}
	var anchor: Vector2i = _deserialize_cell_variant(data.get("anchor_floor_cell", ""))
	var attached: Vector2i = anchor + _get_map_constructor_wall_side_delta(side)
	if not _is_map_constructor_wall_cell(attached):
		return {"ok": false, "reason": "wall_mounted_wrong_side", "message": "Cannot mount on %s: adjacent cell is not a wall." % _get_map_constructor_wall_side_label(side)}
	for object_data in mission_world_objects:
		if String(object_data.get("id", "")) == entity_id:
			continue
		if String(object_data.get("placement_mode", "")) != "wall_mounted":
			continue
		if _deserialize_cell_variant(object_data.get("anchor_floor_cell", "")) == anchor and String(object_data.get("wall_side", "")).to_lower() == side:
			return {"ok": false, "reason": "wall_mounted_side_occupied", "message": "Cannot mount on %s: wall side already has a mounted object." % _get_map_constructor_wall_side_label(side)}
	data["wall_side"] = side
	data["attached_wall_cell"] = _serialize_cell_key(attached)
	data["position"] = anchor
	set_world_object_at_cell(anchor, data)
	PowerSystemRef.recalculate_network(mission_world_objects, String(data.get("power_network_id", "")))
	refresh_world_cooling_received()
	_record_map_constructor_change("side_change", {"entity_kind":"world_object", "entity_id":entity_id, "object_type":String(data.get("object_type", "")), "cell":anchor, "summary":"Changed wall side on %s to %s" % [entity_id, side], "undo_hint":"Can undo by switching side again."})
	return {"ok": true, "message": "Wall side changed to %s." % _get_map_constructor_wall_side_label(side), "object_id": entity_id, "wall_side": side, "attached_wall_cell": attached}

func set_map_constructor_wall_material(cell: Vector2i, side: String, material_id: String) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Wall material overrides are available only in TASK TEST constructor mode."}
	var normalized_side: String = side.to_lower().strip_edges()
	var normalized_material_id: String = material_id.to_lower().strip_edges()
	if _get_map_constructor_wall_side_delta(normalized_side) == Vector2i.ZERO:
		return {"ok": false, "message": "Invalid wall side."}
	var attached_wall_cell: Vector2i = cell + _get_map_constructor_wall_side_delta(normalized_side)
	if not _is_wall_or_boundary_cell(attached_wall_cell):
		return {"ok": false, "message": "Selected side has no wall."}
	var catalog: Dictionary = get_map_constructor_wall_material_catalog()
	var known: bool = false
	for row_variant in Array(catalog.get("materials", [])):
		var row: Dictionary = Dictionary(row_variant)
		if String(row.get("id", "")).to_lower() == normalized_material_id:
			known = true
			break
	if not known:
		return {"ok": false, "message": "Unknown wall material id: %s" % material_id}
	var key: String = _serialize_wall_material_override_key(cell, normalized_side)
	var entry: Dictionary = {"cell": cell, "side": normalized_side, "material_id": normalized_material_id}
	_map_constructor_wall_material_overrides[key] = entry
	_record_map_constructor_change("wall_material", {"cell":cell, "summary":"Set wall material %s at %s/%s" % [normalized_material_id, _format_map_constructor_cell(cell), normalized_side], "details":{"side":normalized_side, "material_id":normalized_material_id}})
	return {"ok": true, "message": "Wall material applied.", "override": entry}

func clear_map_constructor_wall_material(cell: Vector2i, side: String) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Wall material overrides are available only in TASK TEST constructor mode."}
	var normalized_side: String = side.to_lower().strip_edges()
	var key: String = _serialize_wall_material_override_key(cell, normalized_side)
	if not _map_constructor_wall_material_overrides.has(key):
		return {"ok": false, "message": "No wall material override to clear."}
	_map_constructor_wall_material_overrides.erase(key)
	_record_map_constructor_change("wall_material_clear", {"cell":cell, "summary":"Cleared wall material at %s/%s" % [_format_map_constructor_cell(cell), normalized_side], "details":{"side":normalized_side}})
	return {"ok": true, "message": "Wall material override cleared."}

func get_map_constructor_wall_material(cell: Vector2i, side: String) -> Dictionary:
	var key: String = _serialize_wall_material_override_key(cell, side)
	if not _map_constructor_wall_material_overrides.has(key):
		return {"ok": false, "message": "No wall material override.", "override": {}}
	return {"ok": true, "message": "OK", "override": Dictionary(_map_constructor_wall_material_overrides.get(key, {})).duplicate(true)}

func get_map_constructor_wall_material_for_wall_cell(wall_cell: Vector2i) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Wall material overrides are available only in TASK TEST constructor mode.", "override": {}, "material": {}}
	var catalog_by_id: Dictionary = {}
	var catalog: Dictionary = get_map_constructor_wall_material_catalog()
	for row_variant in Array(catalog.get("materials", [])):
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = Dictionary(row_variant)
		var row_id: String = String(row.get("id", "")).to_lower().strip_edges()
		if row_id.is_empty():
			continue
		catalog_by_id[row_id] = row
	var side_order: Array[String] = ["north", "east", "south", "west"]
	for side_id in side_order:
		for key_variant in _map_constructor_wall_material_overrides.keys():
			var entry: Dictionary = Dictionary(_map_constructor_wall_material_overrides.get(String(key_variant), {}))
			var override_side: String = String(entry.get("side", "")).to_lower().strip_edges()
			if override_side != side_id:
				continue
			var anchor_cell: Vector2i = _deserialize_cell_variant(entry.get("cell", Vector2i(-1, -1)))
			var attached_wall_cell: Vector2i = anchor_cell + _get_map_constructor_wall_side_delta(override_side)
			if attached_wall_cell != wall_cell:
				continue
			var material_id: String = String(entry.get("material_id", "")).to_lower().strip_edges()
			if material_id.is_empty() or not catalog_by_id.has(material_id):
				return {"ok": false, "message": "Unknown wall material id: %s" % material_id, "override": entry.duplicate(true), "material": {}}
			return {"ok": true, "message": "OK", "override": entry.duplicate(true), "material": Dictionary(catalog_by_id.get(material_id, {})).duplicate(true)}
	return {"ok": false, "message": "No wall material override.", "override": {}, "material": {}}

func get_map_constructor_wall_material_overrides() -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Wall material overrides are available only in TASK TEST constructor mode.", "overrides": []}
	var rows: Array[Dictionary] = []
	for key_variant in _map_constructor_wall_material_overrides.keys():
		rows.append(Dictionary(_map_constructor_wall_material_overrides.get(String(key_variant), {})).duplicate(true))
	return {"ok": true, "message": "OK", "overrides": rows}

func get_map_constructor_placed_object_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for object_data_variant in mission_world_objects:
		if typeof(object_data_variant) != TYPE_DICTIONARY:
			continue
		var object_data: Dictionary = Dictionary(object_data_variant)
		var row_cell: Vector2i = Vector2i(object_data.get("position", Vector2i(-1, -1)))
		var object_type: String = String(object_data.get("object_type", "object"))
		var prefab_id: String = String(object_data.get("map_constructor_prefab_id", object_type))
		var placement_mode: String = String(object_data.get("placement_mode", "floor"))
		var row: Dictionary = {
			"entity_kind": "world_object",
			"id": String(object_data.get("id", "")),
			"type_or_prefab": prefab_id,
			"cell": row_cell,
			"anchor_floor_cell": row_cell,
			"category_or_placement": String(object_data.get("category", placement_mode.capitalize())),
			"placement_mode": placement_mode,
			"attached_wall_cell": Vector2i(-1, -1),
			"wall_side": String(object_data.get("wall_side", ""))
		}
		var meta_result: Dictionary = get_map_constructor_prefab_metadata(prefab_id)
		if bool(meta_result.get("ok", false)):
			var prefab_meta: Dictionary = Dictionary(meta_result.get("prefab", {}))
			row["display_name"] = String(prefab_meta.get("display_name", prefab_id))
			row["metadata_category"] = String(prefab_meta.get("category", ""))
			row["metadata_roles"] = Array(prefab_meta.get("system_roles", []))
			row["metadata_tags"] = Array(prefab_meta.get("tags", []))
			row["is_expected_invalid_tool"] = bool(prefab_meta.get("is_expected_invalid_tool", false))
		if placement_mode == "wall_mounted":
			row["anchor_floor_cell"] = _deserialize_cell_variant(object_data.get("anchor_floor_cell", row_cell))
			row["attached_wall_cell"] = _deserialize_cell_variant(object_data.get("attached_wall_cell", Vector2i(-1, -1)))
		rows.append(row)
	for cell_variant in cell_items.keys():
		var cell: Vector2i = Vector2i(cell_variant)
		for item_variant in Array(cell_items.get(cell_variant, [])):
			if typeof(item_variant) != TYPE_DICTIONARY:
				continue
			var item_data: Dictionary = Dictionary(item_variant)
			rows.append({
				"entity_kind": "item",
				"id": String(item_data.get("id", "")),
				"type_or_prefab": String(item_data.get("item_type", item_data.get("map_constructor_prefab_id", item_data.get("object_type", "item")))),
				"cell": cell,
				"anchor_floor_cell": cell,
				"category_or_placement": "item",
				"placement_mode": "item",
				"attached_wall_cell": Vector2i(-1, -1),
				"wall_side": ""
			})
			var meta_item: Dictionary = get_map_constructor_prefab_metadata(String(item_data.get("map_constructor_prefab_id", "")))
			if bool(meta_item.get("ok", false)):
				var meta: Dictionary = Dictionary(meta_item.get("prefab", {}))
				rows[rows.size() - 1]["display_name"] = String(meta.get("display_name", rows[rows.size() - 1].get("type_or_prefab", "item")))
				rows[rows.size() - 1]["metadata_category"] = String(meta.get("category", "Item"))
				rows[rows.size() - 1]["metadata_roles"] = Array(meta.get("system_roles", []))
				rows[rows.size() - 1]["metadata_tags"] = Array(meta.get("tags", []))
				rows[rows.size() - 1]["is_expected_invalid_tool"] = bool(meta.get("is_expected_invalid_tool", false))
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ay: int = int(Vector2i(a.get("anchor_floor_cell", Vector2i.ZERO)).y)
		var by: int = int(Vector2i(b.get("anchor_floor_cell", Vector2i.ZERO)).y)
		if ay == by:
			var ax: int = int(Vector2i(a.get("anchor_floor_cell", Vector2i.ZERO)).x)
			var bx: int = int(Vector2i(b.get("anchor_floor_cell", Vector2i.ZERO)).x)
			if ax == bx:
				return String(a.get("id", "")) < String(b.get("id", ""))
			return ax < bx
		return ay < by
	)
	return rows

func get_map_constructor_entity_by_id(entity_kind: String, entity_id: String) -> Dictionary:
	if entity_kind.is_empty():
		var world_entity: Dictionary = get_map_constructor_entity_by_id("world_object", entity_id)
		if bool(world_entity.get("ok", false)):
			return world_entity
		return get_map_constructor_entity_by_id("item", entity_id)
	if entity_kind == "world_object":
		var object_data: Dictionary = get_world_object_by_id(entity_id)
		if object_data.is_empty():
			return {"ok": false, "reason": "not_found", "entity_kind": entity_kind, "id": entity_id}
		return {"ok": true, "entity_kind": entity_kind, "id": entity_id, "cell": Vector2i(object_data.get("position", Vector2i(-1, -1))), "data": object_data}
	if entity_kind == "item":
		for cell_variant in cell_items.keys():
			var cell: Vector2i = Vector2i(cell_variant)
			var items: Array[Dictionary] = get_items_at_cell(cell)
			for item_data in items:
				if String(item_data.get("id", "")) == entity_id:
					return {"ok": true, "entity_kind": entity_kind, "id": entity_id, "cell": cell, "data": item_data}
		return {"ok": false, "reason": "not_found", "entity_kind": entity_kind, "id": entity_id}
	return {"ok": false, "reason": "unsupported_entity_kind", "entity_kind": entity_kind, "id": entity_id}

func _get_map_constructor_editable_field_schema() -> Dictionary:
	return {
		"state":"string","power_network_id":"string","is_open":"bool","is_locked":"bool","is_powered":"bool",
		"required_key_id":"string","lock_type":"string","linked_terminal_id":"string","required_connector_level":"int","required_processor_level":"int",
		"control_source_id":"string","connected_device_ids":"array_string","target_door_id":"string","target_platform_id":"string","requires_external_control":"bool","requires_terminal_enabled":"bool",
		"requires_external_power":"bool","current_heat":"int","working_heat":"int","overheat_threshold":"int",
		"item_type":"string","digital_state":"string","key_kind":"string","damaged":"bool"
	}

func get_map_constructor_editable_fields_for_entity(entity_id: String, entity_kind: String = "") -> Array[Dictionary]:
	var fields: Array[Dictionary] = []
	var resolved_kind: String = entity_kind.strip_edges()
	if resolved_kind.is_empty():
		var world_entity: Dictionary = get_map_constructor_entity_by_id("world_object", entity_id)
		if bool(world_entity.get("ok", false)):
			resolved_kind = "world_object"
		else:
			resolved_kind = "item"
	var entity_info: Dictionary = get_map_constructor_entity_by_id(resolved_kind, entity_id)
	if not bool(entity_info.get("ok", false)):
		return fields
	var data: Dictionary = Dictionary(entity_info.get("data", {}))
	var schema: Dictionary = _get_map_constructor_editable_field_schema()
	for field_name_variant in schema.keys():
		var field_name: String = String(field_name_variant)
		var value: Variant = data.get(field_name, get_default_map_constructor_field_value(field_name, resolved_kind, data))
		if value == null:
			continue
		fields.append({"name": field_name, "type": String(schema[field_name]), "value": value})
	return fields

func _convert_map_constructor_field_value(field_name: String, raw_value: Variant, target_type: String) -> Dictionary:
	if target_type == "bool":
		if typeof(raw_value) == TYPE_BOOL:
			return {"ok": true, "value": raw_value}
		var lower_text: String = String(raw_value).strip_edges().to_lower()
		if lower_text in ["1", "true", "yes", "on"]:
			return {"ok": true, "value": true}
		if lower_text in ["0", "false", "no", "off", ""]:
			return {"ok": true, "value": false}
		return {"ok": false, "message": "Invalid bool for %s." % field_name}
	if target_type == "int":
		if typeof(raw_value) == TYPE_INT:
			return {"ok": true, "value": int(raw_value)}
		var number_text: String = String(raw_value).strip_edges()
		if number_text.is_empty():
			number_text = "0"
		if not number_text.is_valid_int():
			return {"ok": false, "message": "Invalid int for %s." % field_name}
		return {"ok": true, "value": int(number_text)}
	if target_type == "array_string":
		var values: Array[String] = []
		var seen: Dictionary = {}
		if raw_value is Array:
			for value_variant in Array(raw_value):
				var entry: String = String(value_variant).strip_edges()
				if entry.is_empty() or seen.has(entry):
					continue
				seen[entry] = true
				values.append(entry)
		else:
			for value_text in String(raw_value).split(",", false):
				var entry: String = String(value_text).strip_edges()
				if entry.is_empty() or seen.has(entry):
					continue
				seen[entry] = true
				values.append(entry)
		return {"ok": true, "value": values}
	return {"ok": true, "value": String(raw_value)}

func apply_map_constructor_property_update(entity_kind: String, entity_id: String, field_name: String, raw_value: Variant) -> Dictionary:
	var result: Dictionary = {"ok": false, "message": "Update failed.", "entity_id": entity_id, "field": field_name, "value": raw_value}
	var schema: Dictionary = _get_map_constructor_editable_field_schema()
	if not schema.has(field_name):
		result["message"] = "Unknown editable field."
		return result
	var resolved_kind: String = entity_kind.strip_edges()
	if resolved_kind.is_empty():
		var world_entity: Dictionary = get_map_constructor_entity_by_id("world_object", entity_id)
		if bool(world_entity.get("ok", false)):
			resolved_kind = "world_object"
		else:
			resolved_kind = "item"
	var entity_info: Dictionary = get_map_constructor_entity_by_id(resolved_kind, entity_id)
	if not bool(entity_info.get("ok", false)):
		result["message"] = "Entity not found."
		return result
	var data: Dictionary = Dictionary(entity_info.get("data", {}))
	if not data.has(field_name):
		var default_value: Variant = get_default_map_constructor_field_value(field_name, resolved_kind, data)
		if default_value == null:
			result["message"] = "Field is unavailable for this entity."
			return result
		data[field_name] = default_value
	var converted: Dictionary = _convert_map_constructor_field_value(field_name, raw_value, String(schema[field_name]))
	if not bool(converted.get("ok", false)):
		result["message"] = String(converted.get("message", "Invalid value."))
		return result
	var new_value: Variant = converted.get("value")
	var old_value: Variant = data.get(field_name)
	var old_network_id: String = String(data.get("power_network_id", ""))
	data[field_name] = new_value
	if resolved_kind == "world_object":
		update_world_object_by_id(entity_id, data)
	elif resolved_kind == "item":
		var found_item: bool = false
		for cell_variant in cell_items.keys():
			var cell: Vector2i = Vector2i(cell_variant)
			var items: Array[Dictionary] = get_items_at_cell(cell)
			for index in range(items.size()):
				var item_data: Dictionary = items[index]
				if String(item_data.get("id", "")) != entity_id:
					continue
				items[index] = data
				cell_items[cell] = items
				found_item = true
				break
			if found_item:
				break
		if not found_item:
			result["message"] = "Item not found."
			return result
	else:
		result["message"] = "Unsupported entity kind."
		return result
	var needs_power_refresh: bool = field_name == "power_network_id" or field_name in ["is_powered", "requires_external_power", "current_heat", "working_heat", "overheat_threshold"]
	if needs_power_refresh:
		PowerSystemRef.recalculate_network(mission_world_objects, old_network_id)
		PowerSystemRef.recalculate_network(mission_world_objects, String(data.get("power_network_id", "")))
	refresh_world_cooling_received()
	result["ok"] = true
	result["value"] = new_value
	result["message"] = "Updated %s." % field_name
	_record_map_constructor_change("property_update", {"entity_kind":resolved_kind, "entity_id":entity_id, "object_type":String(data.get("object_type", data.get("item_type", ""))), "cell":Vector2i(entity_info.get("cell", Vector2i(-1, -1))), "summary":"Updated %s on %s" % [field_name, entity_id], "details":{"field":field_name, "old":old_value, "new":new_value}, "undo_hint":"Can undo by setting previous value manually."})
	return result

func _map_constructor_is_item_like_world_object(object_data: Dictionary) -> bool:
	var object_group: String = String(object_data.get("object_group", "")).to_lower()
	var object_type: String = String(object_data.get("object_type", "")).to_lower()
	return object_group == "item" or object_type.contains("key") or object_type.contains("access_code")

func _map_constructor_make_link_target(target_id: String, label: String, target_kind: String, target_cell: Vector2i, status: String, reason: String) -> Dictionary:
	return {"id": target_id, "label": label, "kind": target_kind, "cell": target_cell, "status": status, "reason": reason}

func _map_constructor_add_none_target(targets: Array[Dictionary]) -> void:
	targets.append(_map_constructor_make_link_target("__none__", "<clear>", "none", Vector2i(-1, -1), "warning", "clear_value"))

func get_map_constructor_link_targets_for_field(entity_kind: String, entity_id: String, field_name: String) -> Dictionary:
	var result: Dictionary = {"ok": false, "field_name": field_name, "targets": [], "message": "Unsupported field."}
	var supported_fields: Array[String] = [
		"required_key_id", "linked_terminal_id", "target_door_id", "target_platform_id",
		"control_source_id", "connected_device_ids", "power_network_id"
	]
	if not supported_fields.has(field_name):
		return result
	var targets: Array[Dictionary] = []
	var entity_info: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
	var current_cell: Vector2i = Vector2i(entity_info.get("cell", Vector2i(-1, -1)))
	if field_name == "required_key_id":
		var ranked_items: Array[Dictionary] = []
		var other_items: Array[Dictionary] = []
		for cell_variant in cell_items.keys():
			var cell: Vector2i = Vector2i(cell_variant)
			for item_variant in Array(cell_items.get(cell_variant, [])):
				if typeof(item_variant) != TYPE_DICTIONARY:
					continue
				var item_data: Dictionary = Dictionary(item_variant)
				var item_id: String = String(item_data.get("id", "")).strip_edges()
				if item_id.is_empty():
					continue
				var item_type: String = String(item_data.get("item_type", item_data.get("object_type", ""))).to_lower()
				var target: Dictionary = _map_constructor_make_link_target(item_id, item_id, "item", cell, "valid", "item")
				if item_type in ["mechanical_keycard", "digital_key", "access_code"]:
					ranked_items.append(target)
				else:
					other_items.append(target)
		for object_data in mission_world_objects:
			if typeof(object_data) != TYPE_DICTIONARY:
				continue
			var world_data: Dictionary = Dictionary(object_data)
			if not _map_constructor_is_item_like_world_object(world_data):
				continue
			var world_id: String = String(world_data.get("id", "")).strip_edges()
			if world_id.is_empty():
				continue
			var world_cell: Vector2i = Vector2i(world_data.get("position", Vector2i(-1, -1)))
			targets.append(_map_constructor_make_link_target(world_id, world_id, "world_object", world_cell, "valid", "item_like_object"))
		targets.append_array(ranked_items)
		targets.append_array(other_items)
	elif field_name == "linked_terminal_id":
		for object_data in mission_world_objects:
			var data: Dictionary = Dictionary(object_data)
			var object_type: String = String(data.get("object_type", "")).to_lower()
			var group_text: String = String(data.get("object_group", data.get("group", ""))).to_lower()
			if object_type.contains("terminal") or group_text.contains("terminal"):
				targets.append(_map_constructor_make_link_target(String(data.get("id", "")), String(data.get("id", "")), "world_object", Vector2i(data.get("position", Vector2i(-1, -1))), "valid", "terminal_candidate"))
	elif field_name == "target_door_id":
		for object_data in mission_world_objects:
			var data_door: Dictionary = Dictionary(object_data)
			var type_door: String = String(data_door.get("object_type", "")).to_lower()
			var group_door: String = String(data_door.get("object_group", data_door.get("group", ""))).to_lower()
			if type_door.contains("door") or type_door.contains("gate") or group_door.contains("door"):
				targets.append(_map_constructor_make_link_target(String(data_door.get("id", "")), String(data_door.get("id", "")), "world_object", Vector2i(data_door.get("position", Vector2i(-1, -1))), "valid", "door_candidate"))
	elif field_name == "target_platform_id":
		for object_data in mission_world_objects:
			var data_platform: Dictionary = Dictionary(object_data)
			var type_platform: String = String(data_platform.get("object_type", "")).to_lower()
			if type_platform.contains("platform") or data_platform.has("platform_id"):
				targets.append(_map_constructor_make_link_target(String(data_platform.get("id", "")), String(data_platform.get("id", "")), "world_object", Vector2i(data_platform.get("position", Vector2i(-1, -1))), "valid", "platform_candidate"))
	elif field_name == "control_source_id":
		for object_data in mission_world_objects:
			var data_control: Dictionary = Dictionary(object_data)
			var control_id: String = String(data_control.get("id", ""))
			var type_control: String = String(data_control.get("object_type", "")).to_lower()
			if type_control.contains("switch") or type_control.contains("terminal") or type_control.contains("control") or control_id.contains("task_test_switch"):
				targets.append(_map_constructor_make_link_target(control_id, control_id, "world_object", Vector2i(data_control.get("position", Vector2i(-1, -1))), "valid", "control_candidate"))
	elif field_name == "connected_device_ids":
		for object_data in mission_world_objects:
			var data_connected: Dictionary = Dictionary(object_data)
			var connected_id: String = String(data_connected.get("id", "")).strip_edges()
			if connected_id.is_empty() or connected_id == entity_id:
				continue
			var group_connected: String = String(data_connected.get("object_group", "")).to_lower()
			if group_connected == "item":
				continue
			targets.append(_map_constructor_make_link_target(connected_id, connected_id, "world_object", Vector2i(data_connected.get("position", Vector2i(-1, -1))), "valid", "device_candidate"))
	elif field_name == "power_network_id":
		var power_first: Array[Dictionary] = []
		var others: Array[Dictionary] = []
		var seen_networks: Dictionary = {}
		for object_data in mission_world_objects:
			var data_network: Dictionary = Dictionary(object_data)
			var network_id: String = String(data_network.get("power_network_id", "")).strip_edges()
			if network_id.is_empty() or seen_networks.has(network_id):
				continue
			seen_networks[network_id] = true
			var entry: Dictionary = _map_constructor_make_link_target(network_id, network_id, "power_network", Vector2i(-1, -1), "valid", "network_id")
			if String(data_network.get("object_type", "")).to_lower().begins_with("power_source"):
				power_first.append(entry)
			else:
				others.append(entry)
		targets.append_array(power_first)
		targets.append_array(others)
	_map_constructor_add_none_target(targets)
	result["ok"] = true
	result["targets"] = targets
	result["message"] = "Targets ready for %s at %s." % [field_name, str(current_cell)]
	return result

func apply_map_constructor_link_target(entity_kind: String, entity_id: String, field_name: String, target_id: String) -> Dictionary:
	var result: Dictionary = {"ok": false, "message": "Link update failed.", "entity_id": entity_id, "field_name": field_name, "target_id": target_id}
	if field_name == "connected_device_ids":
		var entity_info: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
		if not bool(entity_info.get("ok", false)):
			result["message"] = "Entity not found."
			return result
		var data: Dictionary = Dictionary(entity_info.get("data", {}))
		var old_network_id: String = String(data.get("power_network_id", ""))
		var next_ids: Array[String] = []
		if target_id.is_empty() or target_id == "__none__":
			next_ids.clear()
		else:
			for value_variant in Array(data.get("connected_device_ids", [])):
				var existing_id: String = String(value_variant).strip_edges()
				if existing_id.is_empty() or next_ids.has(existing_id):
					continue
				next_ids.append(existing_id)
			if not next_ids.has(target_id):
				next_ids.append(target_id)
		data["connected_device_ids"] = next_ids
		if entity_kind == "world_object":
			update_world_object_by_id(entity_id, data)
		else:
			result["message"] = "connected_device_ids supports world_object only."
			return result
		PowerSystemRef.recalculate_network(mission_world_objects, old_network_id)
		PowerSystemRef.recalculate_network(mission_world_objects, String(data.get("power_network_id", "")))
		refresh_world_cooling_received()
		result["ok"] = true
		result["message"] = "Updated connected_device_ids."
		result["target_id"] = target_id
		_record_map_constructor_change("link_update", {"entity_kind":"world_object", "entity_id":entity_id, "object_type":String(data.get("object_type", "")), "cell":Vector2i(entity_info.get("cell", Vector2i(-1, -1))), "summary":"Updated connected_device_ids on %s" % entity_id, "details":{"field":"connected_device_ids","target_id":target_id}, "undo_hint":"Can undo by editing link field."})
		return result
	var applied_target: String = target_id
	if target_id.is_empty() or target_id == "__none__":
		applied_target = ""
	var apply_result: Dictionary = apply_map_constructor_property_update(entity_kind, entity_id, field_name, applied_target)
	result["ok"] = bool(apply_result.get("ok", false))
	result["message"] = String(apply_result.get("message", "Link update failed."))
	result["target_id"] = applied_target
	if bool(result.get("ok", false)):
		var entity_after: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
		_record_map_constructor_change("link_update", {"entity_kind":String(entity_after.get("entity_kind", entity_kind)), "entity_id":entity_id, "object_type":String(Dictionary(entity_after.get("data", {})).get("object_type", Dictionary(entity_after.get("data", {})).get("item_type", ""))), "cell":Vector2i(entity_after.get("cell", Vector2i(-1, -1))), "summary":"Updated %s on %s" % [field_name, entity_id], "details":{"field":field_name, "target_id":applied_target}, "undo_hint":"Can undo by setting previous link target."})
	return result

func apply_map_constructor_state_preset(entity_kind: String, entity_id: String, preset: String) -> Dictionary:
	var lower_preset: String = preset.strip_edges().to_lower()
	var updates: Array[Dictionary] = []
	match lower_preset:
		"active":
			updates.append({"field":"state", "value":"active"})
			updates.append({"field":"damaged", "value":false})
		"open":
			updates.append({"field":"state", "value":"open"})
			updates.append({"field":"is_open", "value":true})
			updates.append({"field":"is_locked", "value":false})
		"closed":
			updates.append({"field":"state", "value":"closed"})
			updates.append({"field":"is_open", "value":false})
		"locked":
			updates.append({"field":"state", "value":"locked"})
			updates.append({"field":"is_open", "value":false})
			updates.append({"field":"is_locked", "value":true})
		"unpowered":
			updates.append({"field":"state", "value":"unpowered"})
			updates.append({"field":"is_powered", "value":false})
		"damaged":
			updates.append({"field":"state", "value":"damaged"})
			updates.append({"field":"damaged", "value":true})
		"jammed":
			updates.append({"field":"state", "value":"jammed"})
		"overheated":
			updates.append({"field":"state", "value":"overheated"})
		_:
			return {"ok": false, "message": "Unknown preset.", "entity_id": entity_id, "preset": preset}
	var resolved_kind: String = entity_kind.strip_edges()
	if resolved_kind.is_empty():
		var world_entity: Dictionary = get_map_constructor_entity_by_id("world_object", entity_id)
		if bool(world_entity.get("ok", false)):
			resolved_kind = "world_object"
		else:
			resolved_kind = "item"
	var entity_info: Dictionary = get_map_constructor_entity_by_id(resolved_kind, entity_id)
	if not bool(entity_info.get("ok", false)):
		return {"ok": false, "message": "Entity not found.", "entity_id": entity_id, "preset": preset}
	var data: Dictionary = Dictionary(entity_info.get("data", {}))
	var schema: Dictionary = _get_map_constructor_editable_field_schema()
	var converted_updates: Array[Dictionary] = []
	for update_entry in updates:
		var update_field: String = String(update_entry.get("field", ""))
		if update_field.is_empty() or not schema.has(update_field):
			return {"ok": false, "message": "Preset contains unsupported field.", "entity_id": entity_id, "preset": preset}
		var field_value: Variant = data.get(update_field, get_default_map_constructor_field_value(update_field, resolved_kind, data))
		if field_value == null:
			return {"ok": false, "message": "Preset contains unsupported field.", "entity_id": entity_id, "preset": preset}
		var converted: Dictionary = _convert_map_constructor_field_value(update_field, update_entry.get("value"), String(schema[update_field]))
		if not bool(converted.get("ok", false)):
			return {"ok": false, "message": String(converted.get("message", "Invalid value.")), "entity_id": entity_id, "preset": preset}
		converted_updates.append({"field": update_field, "value": converted.get("value")})
	var old_network_id: String = String(data.get("power_network_id", ""))
	for converted_entry in converted_updates:
		data[String(converted_entry.get("field", ""))] = converted_entry.get("value")
	if resolved_kind == "world_object":
		update_world_object_by_id(entity_id, data)
	elif resolved_kind == "item":
		var updated_item: bool = false
		for cell_variant in cell_items.keys():
			var cell: Vector2i = Vector2i(cell_variant)
			var items: Array[Dictionary] = get_items_at_cell(cell)
			for index in range(items.size()):
				var item_data: Dictionary = items[index]
				if String(item_data.get("id", "")) != entity_id:
					continue
				items[index] = data
				cell_items[cell] = items
				updated_item = true
				break
			if updated_item:
				break
		if not updated_item:
			return {"ok": false, "message": "Item not found.", "entity_id": entity_id, "preset": preset}
	else:
		return {"ok": false, "message": "Unsupported entity kind.", "entity_id": entity_id, "preset": preset}
	var needs_power_refresh: bool = false
	for converted_entry in converted_updates:
		var changed_field: String = String(converted_entry.get("field", ""))
		if changed_field == "power_network_id" or changed_field in ["is_powered", "requires_external_power", "current_heat", "working_heat", "overheat_threshold"]:
			needs_power_refresh = true
			break
	if needs_power_refresh:
		PowerSystemRef.recalculate_network(mission_world_objects, old_network_id)
		PowerSystemRef.recalculate_network(mission_world_objects, String(data.get("power_network_id", "")))
	refresh_world_cooling_received()
	return {"ok": true, "message": "Preset %s applied." % lower_preset, "entity_id": entity_id, "preset": lower_preset}



func _map_constructor_matches_any_token(text: String, tokens: Array[String]) -> bool:
	var lower: String = text.to_lower()
	for token in tokens:
		if lower.contains(token):
			return true
	return false

func get_map_constructor_entity_type_group(entity_kind: String, entity_id: String) -> String:
	var entity: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
	if not bool(entity.get("ok", false)):
		return "generic"
	var data: Dictionary = Dictionary(entity.get("data", {}))
	var object_type: String = String(data.get("object_type", data.get("item_type", ""))).to_lower()
	var object_group: String = String(data.get("object_group", data.get("group", ""))).to_lower()
	var category: String = String(data.get("category", "")).to_lower()
	var placement_mode: String = String(data.get("placement_mode", "")).to_lower()
	var prefab_id: String = String(data.get("map_constructor_prefab_id", "")).to_lower()
	var join_text: String = "%s %s %s %s %s %s" % [object_type, object_group, category, placement_mode, prefab_id, entity_id.to_lower()]
	if _map_constructor_matches_any_token(join_text, ["outer_wall","brick_wall","concrete_wall","steel_wall","grate_wall"]): return "wall"
	if _map_constructor_matches_any_token(join_text, ["door","gate"]): return "door"
	if _map_constructor_matches_any_token(join_text, ["terminal"]): return "terminal"
	if _map_constructor_matches_any_token(join_text, ["power_source","power_socket","power_cable","circuit_switch","circuit_breaker","fuse_box"]): return "power"
	if _map_constructor_matches_any_token(join_text, ["control", "platform", "fan", "switch"]): return "control"
	if entity_kind == "item" or _map_constructor_matches_any_token(join_text, ["mechanical_key","digital_key","access_code","fuse","cable","datafile"]): return "item"
	return "generic"

func get_map_constructor_property_presets(entity_kind: String, entity_id: String) -> Array[Dictionary]:
	var group: String = get_map_constructor_entity_type_group(entity_kind, entity_id)
	match group:
		"door": return [{"id":"open","label":"Open","group":"Door","description":"Door is open and unlocked."},{"id":"closed","label":"Closed","group":"Door","description":"Door is closed and unlocked."},{"id":"locked","label":"Locked","group":"Door","description":"Door is closed and locked."},{"id":"jammed","label":"Jammed","group":"Door","description":"Door is jammed/damaged."}]
		"terminal": return [{"id":"linked","label":"Linked","group":"Terminal","description":"Terminal set active."},{"id":"unlinked","label":"Unlinked","group":"Terminal","description":"Clears linked targets."},{"id":"damaged","label":"Damaged","group":"Terminal","description":"Marks terminal damaged."},{"id":"encrypted","label":"Encrypted","group":"Terminal","description":"Marks terminal encrypted."}]
		"power": return [{"id":"powered","label":"Powered","group":"Power","description":"Active powered state."},{"id":"unpowered","label":"Unpowered","group":"Power","description":"Unpowered state."},{"id":"broken","label":"Broken","group":"Power","description":"Broken/damaged state."}]
		"item": return [{"id":"mechanical_key","label":"Mechanical Key","group":"Item","description":"Set item subtype to mechanical key."},{"id":"digital_key","label":"Digital Key","group":"Item","description":"Set item subtype to digital key."},{"id":"access_code","label":"Access Code","group":"Item","description":"Set item subtype to access code."},{"id":"fuse","label":"Fuse","group":"Item","description":"Set item subtype to fuse."},{"id":"cable","label":"Cable","group":"Item","description":"Set item subtype to cable."}]
	return []

func apply_map_constructor_property_preset(entity_kind: String, entity_id: String, preset_id: String) -> Dictionary:
	var updates: Dictionary = {}
	var group: String = get_map_constructor_entity_type_group(entity_kind, entity_id)
	var warning: String = ""
	match group:
		"door":
			if preset_id == "open": updates={"state":"open","is_open":true,"is_locked":false,"damaged":false}
			elif preset_id == "closed": updates={"state":"closed","is_open":false,"is_locked":false,"damaged":false}
			elif preset_id == "locked": updates={"state":"locked","is_open":false,"is_locked":true,"damaged":false}
			elif preset_id == "jammed": updates={"state":"jammed","is_open":false,"is_locked":true,"damaged":true}
		"terminal":
			if preset_id == "linked": updates={"state":"active","is_powered":true,"damaged":false,"encrypted":false}
			elif preset_id == "unlinked": updates={"state":"active","target_door_id":"","target_platform_id":"","linked_terminal_id":"","controls":[]}
			elif preset_id == "damaged": updates={"state":"damaged","damaged":true}
			elif preset_id == "encrypted": updates={"state":"encrypted","encrypted":true}
		"power":
			if preset_id == "powered": updates={"state":"active","is_powered":true,"damaged":false,"broken":false}
			elif preset_id == "unpowered": updates={"state":"unpowered","is_powered":false}
			elif preset_id == "broken": updates={"state":"broken","damaged":true,"broken":true}
		"item":
			if preset_id == "mechanical_key": updates={"item_type":"mechanical_key","object_type":"mechanical_key","key_type":"mechanical"}
			elif preset_id == "digital_key": updates={"item_type":"digital_key","object_type":"digital_key","key_type":"digital"}
			elif preset_id == "access_code": updates={"item_type":"access_code","object_type":"access_code","digital_payload_type":"access_code"}
			elif preset_id == "fuse": updates={"item_type":"fuse","object_type":"fuse"}
			elif preset_id == "cable": updates={"item_type":"power_cable","object_type":"power_cable"}
	if updates.is_empty():
		return {"ok": false, "message": "Unsupported preset.", "entity_kind": entity_kind, "entity_id": entity_id}
	var apply: Dictionary = update_map_constructor_entity_properties(entity_kind, entity_id, updates)
	if group == "terminal" and preset_id == "linked":
		var e: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
		var d: Dictionary = Dictionary(e.get("data", {}))
		if String(d.get("target_door_id", "")).is_empty() and String(d.get("target_platform_id", "")).is_empty() and String(d.get("linked_terminal_id", "")).is_empty():
			warning = "Terminal is active but no linked target selected."
	return {"ok": bool(apply.get("ok", false)), "message": warning if not warning.is_empty() else String(apply.get("message", "Preset applied.")), "entity_kind": entity_kind, "entity_id": entity_id}

func update_map_constructor_entity_properties(entity_kind: String, entity_id: String, updates: Dictionary) -> Dictionary:
	var warnings: Array[String] = []
	for k in updates.keys():
		if String(k) == "id" or String(k) == "position" or String(k) == "wall_side":
			warnings.append("Field %s is restricted." % String(k))
	var safe: Dictionary = updates.duplicate(true)
	safe.erase("id"); safe.erase("position"); safe.erase("wall_side")
	for k in safe.keys():
		var r: Dictionary = apply_map_constructor_property_update(entity_kind, entity_id, String(k), safe[k])
		if not bool(r.get("ok", false)):
			return {"ok": false, "message": String(r.get("message", "Update failed.")), "warnings": warnings}
	return {"ok": true, "message": "Updated properties.", "warnings": warnings}

func get_map_constructor_link_candidates(entity_kind: String, entity_id: String, link_type: String) -> Array[Dictionary]:
	var field_map := {"linked_door":"target_door_id","power_network":"power_network_id","control_source":"control_source_id","terminal_target":"target_door_id","platform_target":"target_platform_id"}
	if not field_map.has(link_type): return []
	var entity: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
	var current_value: String = ""
	if bool(entity.get("ok", false)):
		current_value = String(Dictionary(entity.get("data", {})).get(String(field_map[link_type]), "")).strip_edges()
	var raw: Dictionary = get_map_constructor_link_targets_for_field(entity_kind, entity_id, String(field_map[link_type]))
	var out: Array[Dictionary] = []
	for t in Array(raw.get("targets", [])):
		var td: Dictionary = Dictionary(t)
		if String(td.get("id", "")) == "__none__": continue
		var id: String = String(td.get("id",""))
		out.append({"id":id,"label":String(td.get("label","")),"cell":Vector2i(td.get("cell",Vector2i(-1,-1))),"entity_kind":"world_object","object_type":String(td.get("kind","")),"current":id == current_value})
	if link_type == "power_network":
		var known: Dictionary = {}
		for entry in out:
			known[String(Dictionary(entry).get("id", ""))] = true
		for fallback_id in ["task_test_power_main","task_test_power_missing","mapedit_power_A","mapedit_power_B", current_value]:
			var network_id: String = String(fallback_id).strip_edges()
			if network_id.is_empty() or known.has(network_id):
				continue
			out.append({"id":network_id,"label":"Network: %s" % network_id,"cell":Vector2i(-1,-1),"entity_kind":"world_object","object_type":"power_network","current":network_id == current_value})
			known[network_id] = true
	return out

func set_map_constructor_entity_link(entity_kind: String, entity_id: String, link_type: String, target_id: String) -> Dictionary:
	var field_map := {"linked_door":"target_door_id","power_network":"power_network_id","control_source":"control_source_id","terminal_target":"target_door_id","platform_target":"target_platform_id"}
	if not field_map.has(link_type): return {"ok":false,"message":"Unsupported link type.","target_id":target_id}
	var apply: Dictionary = apply_map_constructor_link_target(entity_kind, entity_id, String(field_map[link_type]), target_id)
	var target_cell: Vector2i = Vector2i(-1, -1)
	var target_entity: Dictionary = get_map_constructor_entity_by_id("world_object", target_id)
	if bool(target_entity.get("ok", false)): target_cell = Vector2i(target_entity.get("cell", Vector2i(-1, -1)))
	return {"ok":bool(apply.get("ok",false)),"message":String(apply.get("message","Link updated.")),"target_cell":target_cell,"target_id":target_id}

func validate_map_constructor_entity_links(entity_kind: String, entity_id: String) -> Dictionary:
	var warnings: Array[String] = []
	var missing: Array[String] = []
	var linked: Array[String] = []
	var entity: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
	if not bool(entity.get("ok", false)):
		return {"ok": false, "warnings": ["Entity not found."], "missing_links": [], "linked_targets": []}
	var data: Dictionary = Dictionary(entity.get("data", {}))
	for key in ["target_door_id","linked_terminal_id","control_source_id","required_key_id"]:
		var tid: String = String(data.get(key, "")).strip_edges()
		if tid.is_empty():
			continue
		linked.append(tid)
		if not bool(get_map_constructor_entity_by_id("", tid).get("ok", false)):
			warnings.append("Missing link target for %s: %s" % [key, tid]); missing.append(key)
	return {"ok": missing.is_empty(), "warnings": warnings, "missing_links": missing, "linked_targets": linked}

func _is_map_constructor_cleanup_protected_object(object_data: Dictionary) -> bool:
	var object_id: String = String(object_data.get("id", "")).to_lower()
	if object_id == "bipob" or object_id.find("bipob") >= 0:
		return true
	if object_id.find("start") >= 0 and object_id.find("marker") >= 0:
		return true
	if object_id.find("exit") >= 0 and object_id.find("marker") >= 0:
		return true
	return false

func _build_map_constructor_cleanup_row(entity_kind: String, data: Dictionary, cell: Vector2i) -> Dictionary:
	var object_id: String = String(data.get("id", ""))
	return {"entity_kind": entity_kind, "id": object_id, "object_type": String(data.get("object_type", data.get("item_type", ""))), "object_group": String(data.get("object_group", "")), "category": String(data.get("category", "")), "type_group": get_map_constructor_entity_type_group(entity_kind, object_id), "cell": cell, "created_by_map_constructor": bool(data.get("created_by_map_constructor", false))}

func get_map_constructor_cleanup_preview(cleanup_type: String, options: Dictionary = {}) -> Dictionary:
	var lower_type: String = cleanup_type.strip_edges().to_lower()
	if not _is_task_test_constructor_context():
		return {"ok": false, "cleanup_type": lower_type, "message": "Cleanup tools work only in TASK TEST runtime.", "affected_count": 0, "affected_objects": [], "warnings": []}
	var include_base: bool = bool(options.get("include_base_task_test_objects", false))
	var include_constructor_created: bool = bool(options.get("include_constructor_created", true))
	var rows: Array[Dictionary] = []
	var warnings: Array[String] = []
	for object_data in mission_world_objects:
		if typeof(object_data) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = Dictionary(object_data)
		var created: bool = bool(data.get("created_by_map_constructor", false))
		if include_constructor_created and not created and not include_base:
			continue
		if not include_constructor_created and created:
			continue
		if _is_map_constructor_cleanup_protected_object(data):
			continue
		var row: Dictionary = _build_map_constructor_cleanup_row("world_object", data, Vector2i(data.get("position", Vector2i(-1, -1))))
		var add_row: bool = false
		match lower_type:
			"items":
				add_row = row["type_group"] == "item" or _map_constructor_is_item_like_world_object(data)
			"wall_mounted":
				add_row = String(data.get("placement_mode", "")) == "wall_mounted"
			"category":
				add_row = String(row.get("category", "")).to_lower() == String(options.get("category", "")).to_lower()
			"type_group":
				add_row = String(row.get("type_group", "")) == String(options.get("type_group", "")).to_lower()
			"all_constructor_objects", "reset_runtime_map":
				add_row = created or include_base
				if lower_type == "reset_runtime_map":
					warnings.append("Full baseline reset is not available yet; constructor-created runtime edits will be cleared.")
			"invalid_references":
				var fields: Array[String] = ["target_door_id","target_platform_id","linked_terminal_id","control_source_id","required_key_id"]
				for f in fields:
					var tid: String = String(data.get(f, "")).strip_edges()
					if tid.is_empty():
						continue
					if not bool(get_map_constructor_entity_by_id("", tid).get("ok", false)):
						rows.append({"entity_kind":"world_object","id":String(data.get("id","")),"field_name":f,"invalid_value":tid,"cell":Vector2i(data.get("position", Vector2i(-1,-1))),"created_by_map_constructor":created})
				for connected_id in Array(data.get("connected_device_ids", [])):
					var cid: String = String(connected_id).strip_edges()
					if cid.is_empty():
						continue
					if not bool(get_map_constructor_entity_by_id("", cid).get("ok", false)):
						rows.append({"entity_kind":"world_object","id":String(data.get("id","")),"field_name":"connected_device_ids","invalid_value":cid,"cell":Vector2i(data.get("position", Vector2i(-1,-1))),"created_by_map_constructor":created})
			_:
				return {"ok": false, "cleanup_type": lower_type, "message": "Unsupported cleanup type.", "affected_count": 0, "affected_objects": [], "warnings": []}
		if add_row:
			rows.append(row)
	for cell_variant in cell_items.keys():
		var cell: Vector2i = Vector2i(cell_variant)
		for item_variant in Array(cell_items.get(cell_variant, [])):
			var item_data: Dictionary = Dictionary(item_variant)
			var created_item: bool = bool(item_data.get("created_by_map_constructor", false))
			if include_constructor_created and not created_item and not include_base:
				continue
			if not include_constructor_created and created_item:
				continue
			if lower_type in ["items", "all_constructor_objects", "reset_runtime_map"]:
				rows.append(_build_map_constructor_cleanup_row("item", item_data, cell))
	return {"ok": true, "cleanup_type": lower_type, "message": "Preview ready.", "affected_count": rows.size(), "affected_objects": rows, "warnings": warnings}

func apply_map_constructor_cleanup(cleanup_type: String, options: Dictionary = {}) -> Dictionary:
	var preview: Dictionary = get_map_constructor_cleanup_preview(cleanup_type, options)
	if not bool(preview.get("ok", false)):
		return {"ok": false, "message": String(preview.get("message", "Cleanup failed.")), "deleted_count": 0, "cleanup_id": "", "warnings": Array(preview.get("warnings", []))}
	var affected: Array = Array(preview.get("affected_objects", []))
	if affected.is_empty():
		return {"ok": true, "message": "Nothing to clean up.", "deleted_count": 0, "cleanup_id": "", "warnings": Array(preview.get("warnings", []))}
	_map_constructor_last_cleanup_snapshot = {"cleanup_id": "cleanup_%d" % Time.get_unix_time_from_system(), "mission_world_objects": mission_world_objects.duplicate(true), "cell_items": cell_items.duplicate(true), "world_objects_by_cell": world_objects_by_cell.duplicate(true)}
	var deleted_count: int = 0
	if String(cleanup_type).to_lower() == "invalid_references":
		var cleared: int = 0
		for row_variant in affected:
			var row: Dictionary = Dictionary(row_variant)
			var entity: Dictionary = get_map_constructor_entity_by_id(String(row.get("entity_kind", "world_object")), String(row.get("id", "")))
			if not bool(entity.get("ok", false)):
				continue
			var data: Dictionary = Dictionary(entity.get("data", {}))
			var field_name: String = String(row.get("field_name", ""))
			if field_name == "connected_device_ids":
				var filtered: Array[String] = []
				for cid in Array(data.get("connected_device_ids", [])):
					if bool(get_map_constructor_entity_by_id("", String(cid)).get("ok", false)):
						filtered.append(String(cid))
				data["connected_device_ids"] = filtered
				cleared += 1
			else:
				data[field_name] = ""
				cleared += 1
			update_world_object_by_id(String(row.get("id", "")), data)
		PowerSystemRef.recalculate_network(mission_world_objects, "")
		refresh_world_cooling_received()
		_record_map_constructor_change("cleanup", {"entity_kind":"", "entity_id":"", "summary":"Applied cleanup: %d objects affected" % cleared, "details":{"cleanup_type":String(cleanup_type).to_lower(), "affected_count":cleared}, "undo_hint":"Use Undo Last Cleanup."})
		return {"ok": true, "message": "Invalid references cleaned.", "deleted_count": cleared, "cleanup_id": String(_map_constructor_last_cleanup_snapshot.get("cleanup_id", "")), "warnings": []}
	for row_variant in affected:
		var row: Dictionary = Dictionary(row_variant)
		var remove_result: Dictionary = _remove_map_constructor_entity_by_id(String(row.get("entity_kind", "")), String(row.get("id", "")))
		if bool(remove_result.get("ok", false)):
			deleted_count += 1
	PowerSystemRef.recalculate_network(mission_world_objects, "")
	refresh_world_cooling_received()
	var message: String = "Cleanup applied."
	if String(cleanup_type).to_lower() == "reset_runtime_map":
		message = "Runtime map reset cleared constructor-created edits. Full baseline reset is not available yet."
	_record_map_constructor_change("reset" if String(cleanup_type).to_lower() == "reset_runtime_map" else "cleanup", {"entity_kind":"", "entity_id":"", "summary":"Applied cleanup: %d objects affected" % deleted_count if String(cleanup_type).to_lower() != "reset_runtime_map" else "Reset runtime map.", "details":{"cleanup_type":String(cleanup_type).to_lower(), "affected_count":deleted_count}, "undo_hint":"Use Undo Last Cleanup."})
	return {"ok": true, "message": message, "deleted_count": deleted_count, "cleanup_id": String(_map_constructor_last_cleanup_snapshot.get("cleanup_id", "")), "warnings": Array(preview.get("warnings", []))}

func undo_last_map_constructor_cleanup() -> Dictionary:
	if _map_constructor_last_cleanup_snapshot.is_empty():
		return {"ok": false, "message": "No cleanup to undo."}
	mission_world_objects = Array(_map_constructor_last_cleanup_snapshot.get("mission_world_objects", [])).duplicate(true)
	cell_items = Dictionary(_map_constructor_last_cleanup_snapshot.get("cell_items", {})).duplicate(true)
	world_objects_by_cell = Dictionary(_map_constructor_last_cleanup_snapshot.get("world_objects_by_cell", {})).duplicate(true)
	_map_constructor_last_cleanup_snapshot.clear()
	PowerSystemRef.recalculate_network(mission_world_objects, "")
	refresh_world_cooling_received()
	_record_map_constructor_change("cleanup_undo", {"summary":"Undid last cleanup.", "undo_hint":"Redo cleanup manually if needed."})
	return {"ok": true, "message": "Last cleanup undone."}
func is_task_test_expected_invalid_object_id(object_id: String) -> bool:
	match object_id:
		"task_test_control_missing_source", "task_test_control_invalid_source", "task_test_powered_gate_unpowered", "task_test_platform_lift":
			return true
		_:
			return false

func get_map_constructor_object_dependency_status(object_data: Dictionary) -> Dictionary:
	var messages: Array[String] = []
	var link_targets: Array[Dictionary] = []
	var severity: String = "none"
	var object_id: String = String(object_data.get("id", "")).strip_edges()
	var expected_invalid: bool = is_task_test_expected_invalid_object_id(object_id)
	var object_ids: Dictionary = {}
	var object_id_to_cell: Dictionary = {}
	var item_ids: Dictionary = {}
	var item_id_to_cell: Dictionary = {}
	var power_source_network_ids: Dictionary = {}
	for existing_object in mission_world_objects:
		if typeof(existing_object) != TYPE_DICTIONARY:
			continue
		var existing_data: Dictionary = Dictionary(existing_object)
		var existing_id: String = String(existing_data.get("id", "")).strip_edges()
		if not existing_id.is_empty():
			object_ids[existing_id] = true
			object_id_to_cell[existing_id] = Vector2i(existing_data.get("position", Vector2i(-1, -1)))
		var existing_type: String = String(existing_data.get("object_type", "")).to_lower()
		if existing_type.begins_with("power_source"):
			var existing_network_id: String = String(existing_data.get("power_network_id", "")).strip_edges()
			if not existing_network_id.is_empty():
				power_source_network_ids[existing_network_id] = true
	for cell_variant in cell_items.keys():
		for item_variant in Array(cell_items.get(cell_variant, [])):
			if typeof(item_variant) != TYPE_DICTIONARY:
				continue
			var item_id: String = String(Dictionary(item_variant).get("id", "")).strip_edges()
			if not item_id.is_empty():
				item_ids[item_id] = true
				item_id_to_cell[item_id] = Vector2i(cell_variant)

	for field_name in ["required_key_id", "linked_terminal_id", "target_door_id", "target_platform_id"]:
		var ref_id: String = String(object_data.get(field_name, "")).strip_edges()
		if ref_id.is_empty():
			continue
		var exists: bool = object_ids.has(ref_id) or (field_name == "required_key_id" and item_ids.has(ref_id))
		var ref_cell: Vector2i = Vector2i(-1, -1)
		if field_name == "required_key_id" and item_id_to_cell.has(ref_id):
			ref_cell = Vector2i(item_id_to_cell[ref_id])
		elif object_id_to_cell.has(ref_id):
			ref_cell = Vector2i(object_id_to_cell[ref_id])
		if exists:
			link_targets.append({"field": field_name, "target_id": ref_id, "target_cell": ref_cell, "status": "valid", "reason": "exists"})
			if severity == "none":
				severity = "valid"
		else:
			messages.append("%s points to missing id: %s" % [field_name, ref_id])
			link_targets.append({"field": field_name, "target_id": ref_id, "target_cell": ref_cell, "status": "error", "reason": "missing"})
			severity = "error"

	var control_source_id: String = String(object_data.get("control_source_id", "")).strip_edges()
	if not control_source_id.is_empty():
		var control_source_cell: Vector2i = Vector2i(object_id_to_cell.get(control_source_id, Vector2i(-1, -1)))
		if object_ids.has(control_source_id):
			link_targets.append({"field":"control_source_id","target_id":control_source_id,"target_cell":control_source_cell,"status":"valid","reason":"exists"})
			if severity == "none":
				severity = "valid"
		else:
			if expected_invalid:
				messages.append("control_source_id missing (expected test sample)")
				link_targets.append({"field":"control_source_id","target_id":control_source_id,"target_cell":control_source_cell,"status":"warning","reason":"expected_missing"})
				if severity != "error":
					severity = "warning"
			else:
				messages.append("control_source_id points to missing id: %s" % control_source_id)
				link_targets.append({"field":"control_source_id","target_id":control_source_id,"target_cell":control_source_cell,"status":"error","reason":"missing"})
				severity = "error"

	var requires_external_power: bool = bool(object_data.get("requires_external_power", false))
	var power_network_id: String = String(object_data.get("power_network_id", "")).strip_edges()
	if requires_external_power:
		if power_network_id.is_empty():
			if expected_invalid:
				messages.append("power_network_id missing (expected test sample)")
				if severity != "error":
					severity = "warning"
			else:
				messages.append("requires_external_power=true but power_network_id is empty")
				severity = "error"
		elif power_source_network_ids.has(power_network_id):
			link_targets.append({"field":"power_network_id","target_id":power_network_id,"target_cell":Vector2i(-1, -1),"status":"valid","reason":"network_found"})
			if severity == "none":
				severity = "valid"
		else:
			if expected_invalid:
				messages.append("power_network_id %s has no source (expected test sample)" % power_network_id)
				link_targets.append({"field":"power_network_id","target_id":power_network_id,"target_cell":Vector2i(-1, -1),"status":"warning","reason":"expected_missing_network"})
				if severity != "error":
					severity = "warning"
			else:
				messages.append("power_network_id %s has no power source" % power_network_id)
				link_targets.append({"field":"power_network_id","target_id":power_network_id,"target_cell":Vector2i(-1, -1),"status":"error","reason":"missing_network"})
				severity = "error"

	for connected_id_variant in Array(object_data.get("connected_device_ids", [])):
		var connected_id: String = String(connected_id_variant).strip_edges()
		if connected_id.is_empty():
			continue
		var connected_cell: Vector2i = Vector2i(object_id_to_cell.get(connected_id, Vector2i(-1, -1)))
		if object_ids.has(connected_id):
			link_targets.append({"field":"connected_device_ids","target_id":connected_id,"target_cell":connected_cell,"status":"valid","reason":"exists"})
			if severity == "none":
				severity = "valid"
		else:
			messages.append("connected_device_ids contains missing id: %s" % connected_id)
			link_targets.append({"field":"connected_device_ids","target_id":connected_id,"target_cell":connected_cell,"status":"error","reason":"missing"})
			severity = "error"

	return {"severity": severity, "messages": messages, "link_targets": link_targets}


func _map_constructor_merge_overlay_issue(overlay_objects: Dictionary, overlay_cells: Dictionary, object_id: String, severity: String, message: String) -> void:
	if not overlay_objects.has(object_id):
		return
	var row: Dictionary = Dictionary(overlay_objects[object_id])
	var messages: Array = Array(row.get("messages", []))
	messages.append(message)
	row["messages"] = messages
	var previous_severity: String = String(row.get("severity", "none"))
	if previous_severity != "error":
		if severity == "error" or (severity == "warning" and previous_severity == "none"):
			row["severity"] = severity
	overlay_objects[object_id] = row
	var object_cell: Vector2i = Vector2i(row.get("cell", Vector2i(-1, -1)))
	if overlay_cells.has(object_cell):
		var cell_row: Dictionary = Dictionary(overlay_cells[object_cell])
		var cell_messages: Array = Array(cell_row.get("messages", []))
		cell_messages.append(message)
		cell_row["messages"] = cell_messages
		var cell_prev_severity: String = String(cell_row.get("severity", "none"))
		if cell_prev_severity != "error":
			if severity == "error" or (severity == "warning" and cell_prev_severity == "none"):
				cell_row["severity"] = severity
		overlay_cells[object_cell] = cell_row

func get_map_constructor_validation_overlay() -> Dictionary:
	var overlay_cells: Dictionary = {}
	var overlay_objects: Dictionary = {}
	var audit: Dictionary = get_task_test_system_audit_report()
	for object_data in mission_world_objects:
		if typeof(object_data) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = Dictionary(object_data)
		var object_id: String = String(data.get("id", "")).strip_edges()
		if object_id.is_empty():
			continue
		var object_cell: Vector2i = Vector2i(data.get("position", Vector2i(-1, -1)))
		var dependency: Dictionary = get_map_constructor_object_dependency_status(data)
		var object_severity: String = String(dependency.get("severity", "none"))
		var object_messages: Array[String] = []
		for msg in Array(dependency.get("messages", [])):
			object_messages.append(String(msg))
		overlay_objects[object_id] = {"severity": object_severity, "cell": object_cell, "messages": object_messages, "link_targets": Array(dependency.get("link_targets", []))}
		overlay_cells[object_cell] = {"severity": object_severity, "object_id": object_id, "messages": object_messages, "link_targets": Array(dependency.get("link_targets", []))}
		if String(data.get("placement_mode", "")) == "wall_mounted":
			var anchor_cell: Vector2i = _deserialize_cell_variant(data.get("anchor_floor_cell", data.get("position", "-1,-1")))
			var attached_cell: Vector2i = _deserialize_cell_variant(data.get("attached_wall_cell", "-1,-1"))
			var wall_side: String = String(data.get("wall_side", "")).to_lower()
			var side_ok: bool = wall_side in ["north", "east", "south", "west"]
			if not side_ok:
				_map_constructor_merge_overlay_issue(overlay_objects, overlay_cells, object_id, "error", "Wall-mounted invalid wall_side.")
			if not _is_valid_grid_cell(anchor_cell):
				_map_constructor_merge_overlay_issue(overlay_objects, overlay_cells, object_id, "error", "Wall-mounted invalid anchor_floor_cell.")
			if not _is_wall_or_boundary_cell(attached_cell):
				_map_constructor_merge_overlay_issue(overlay_objects, overlay_cells, object_id, "error", "Wall-mounted attached_wall_cell is not wall/boundary.")
			if _is_valid_grid_cell(anchor_cell) and _is_wall_or_boundary_cell(attached_cell):
				if not (abs(anchor_cell.x - attached_cell.x) + abs(anchor_cell.y - attached_cell.y) == 1):
					_map_constructor_merge_overlay_issue(overlay_objects, overlay_cells, object_id, "error", "Wall-mounted anchor and attached wall are not adjacent.")
				var expected_side: String = ""
				for side_entry in MAP_CONSTRUCTOR_WALL_SIDE_DELTAS:
					var delta: Vector2i = Vector2i(side_entry.get("delta", Vector2i.ZERO))
					if anchor_cell + delta == attached_cell:
						expected_side = String(side_entry.get("side", ""))
						break
				if not expected_side.is_empty() and wall_side != expected_side:
					_map_constructor_merge_overlay_issue(overlay_objects, overlay_cells, object_id, "error", "Wall-mounted wall_side does not match attached wall cell.")

	for row_variant in Array(audit.get("invalid_links", [])):
		var row_invalid: Dictionary = Dictionary(row_variant)
		_map_constructor_merge_overlay_issue(overlay_objects, overlay_cells,String(row_invalid.get("object_id", "")), "error", "Invalid link: %s -> %s" % [String(row_invalid.get("field", "")), String(row_invalid.get("target_id", ""))])
	for row_variant in Array(audit.get("expected_invalid_links", [])):
		var row_expected: Dictionary = Dictionary(row_variant)
		_map_constructor_merge_overlay_issue(overlay_objects, overlay_cells,String(row_expected.get("object_id", "")), "warning", "Expected invalid link: %s -> %s" % [String(row_expected.get("field", "")), String(row_expected.get("target_id", ""))])
	for warning_variant in Array(audit.get("runtime_cell_warnings", [])):
		var warning_text: String = String(warning_variant)
		for object_id_variant in overlay_objects.keys():
			var object_id_text: String = String(object_id_variant)
			if warning_text.find(object_id_text) != -1:
				_map_constructor_merge_overlay_issue(overlay_objects, overlay_cells,object_id_text, "error", warning_text)
	for warning_variant in Array(audit.get("expected_runtime_warnings", [])):
		var warning_text_expected: String = String(warning_variant)
		for object_id_variant in overlay_objects.keys():
			var object_id_text_expected: String = String(object_id_variant)
			if warning_text_expected.find(object_id_text_expected) != -1:
				_map_constructor_merge_overlay_issue(overlay_objects, overlay_cells,object_id_text_expected, "warning", warning_text_expected)
	for warning_variant in Array(audit.get("duplicate_cell_warnings", [])):
		var warning_text_dup: String = String(warning_variant)
		for object_id_variant in overlay_objects.keys():
			var object_id_text_dup: String = String(object_id_variant)
			if warning_text_dup.find(object_id_text_dup) != -1:
				_map_constructor_merge_overlay_issue(overlay_objects, overlay_cells,object_id_text_dup, "error", warning_text_dup)
	for object_id_variant in Array(audit.get("objects_without_audit_tags", [])):
		_map_constructor_merge_overlay_issue(overlay_objects, overlay_cells,String(object_id_variant), "warning", "Object has no TASK TEST audit tag.")

	var summary: Dictionary = {"valid_count": 0, "warning_count": 0, "error_count": 0, "expected_warning_count": 0}
	var has_error_severity: bool = false
	for object_id_key in overlay_objects.keys():
		var object_row: Dictionary = Dictionary(overlay_objects[object_id_key])
		var final_severity: String = String(object_row.get("severity", "none"))
		if final_severity == "valid":
			summary["valid_count"] = int(summary.get("valid_count", 0)) + 1
		elif final_severity == "warning":
			summary["warning_count"] = int(summary.get("warning_count", 0)) + 1
			if is_task_test_expected_invalid_object_id(String(object_id_key)):
				summary["expected_warning_count"] = int(summary.get("expected_warning_count", 0)) + 1
		elif final_severity == "error":
			summary["error_count"] = int(summary.get("error_count", 0)) + 1
			has_error_severity = true

	for cell_row_variant in overlay_cells.values():
		var cell_row: Dictionary = Dictionary(cell_row_variant)
		if String(cell_row.get("severity", "none")) == "error":
			has_error_severity = true
			break
	var has_errors: bool = int(summary.get("error_count", 0)) > 0 or has_error_severity
	var start_validation: Dictionary = _validate_constructor_marker(constructor_start_marker, "start")
	var exit_validation: Dictionary = _validate_constructor_marker(constructor_exit_marker, "exit")
	if not bool(start_validation.get("ok", false)):
		summary["error_count"] = int(summary.get("error_count", 0)) + 1
		has_errors = true
		summary["start_marker_error"] = String(start_validation.get("message", "Start marker error."))
	if not bool(exit_validation.get("ok", false)):
		summary["error_count"] = int(summary.get("error_count", 0)) + 1
		has_errors = true
		summary["exit_marker_error"] = String(exit_validation.get("message", "Exit marker error."))
	return {"ok": not has_errors, "cells": overlay_cells, "objects": overlay_objects, "summary": summary}

func _make_map_constructor_issue(issue_id: String, severity: String, message: String, cell: Vector2i, source: String, entity_kind: String = "", entity_id: String = "", fix_hint: String = "") -> Dictionary:
	return {
		"id": issue_id,
		"severity": severity,
		"message": message,
		"cell": cell,
		"entity_kind": entity_kind,
		"entity_id": entity_id,
		"source": source,
		"fix_hint": fix_hint
	}

func get_map_constructor_validation_issues() -> Array[Dictionary]:
	var issues: Array[Dictionary] = []
	var source_name: String = "map_constructor_validation"
	var seen_object_ids: Dictionary = {}
	var seen_occupancy_cells: Dictionary = {}
	var seen_item_ids: Dictionary = {}
	var has_grid_bounds: bool = false
	if grid_manager != null and grid_manager.has_method("is_in_bounds"):
		has_grid_bounds = true
	for index in range(mission_world_objects.size()):
		var data: Dictionary = Dictionary(mission_world_objects[index])
		var entity_kind: String = _map_constructor_entity_kind(data)
		if entity_kind == "item":
			continue
		var object_id: String = String(data.get("id", "")).strip_edges()
		var object_type: String = String(data.get("object_type", "")).strip_edges()
		var object_group: String = String(data.get("object_group", "")).strip_edges()
		var object_cell: Vector2i = _deserialize_cell_variant(data.get("position", Vector2i(-1, -1)))
		if object_id.is_empty():
			issues.append(_make_map_constructor_issue("obj_missing_id_%d" % index, "error", "Object missing id.", object_cell, source_name, entity_kind, "", "Set unique id."))
		elif seen_object_ids.has(object_id):
			issues.append(_make_map_constructor_issue("obj_duplicate_id_%s_%d" % [object_id, index], "error", "Duplicate object id: %s." % object_id, object_cell, source_name, entity_kind, object_id, "Use unique ids."))
		else:
			seen_object_ids[object_id] = true
		if object_type.is_empty():
			issues.append(_make_map_constructor_issue("obj_missing_type_%d" % index, "error", "Object missing object_type.", object_cell, source_name, entity_kind, object_id))
		if object_group.is_empty():
			issues.append(_make_map_constructor_issue("obj_missing_group_%d" % index, "error", "Object missing object_group.", object_cell, source_name, entity_kind, object_id))
		if object_cell.x < 0 or object_cell.y < 0:
			issues.append(_make_map_constructor_issue("obj_invalid_cell_%d" % index, "error", "Object position invalid or negative.", object_cell, source_name, entity_kind, object_id))
		elif has_grid_bounds and not bool(grid_manager.call("is_in_bounds", object_cell)):
			issues.append(_make_map_constructor_issue("obj_out_of_bounds_%d" % index, "error", "Object out of bounds.", object_cell, source_name, entity_kind, object_id))
		var allow_overlap: bool = bool(data.get("allow_cell_overlap", false))
		if not allow_overlap and object_group != "item" and object_group != "visual" and object_cell.x >= 0 and object_cell.y >= 0:
			var occupancy_key: String = "%d,%d" % [object_cell.x, object_cell.y]
			if seen_occupancy_cells.has(occupancy_key):
				issues.append(_make_map_constructor_issue("obj_duplicate_cell_%s_%d" % [occupancy_key, index], "warning", "Duplicate non-overlap cell occupancy at %s." % occupancy_key, object_cell, source_name, entity_kind, object_id))
			else:
				seen_occupancy_cells[occupancy_key] = object_id
		if String(data.get("placement_mode", "")).to_lower() == "wall_mounted":
			var anchor_floor_cell: Vector2i = _deserialize_cell_variant(data.get("anchor_floor_cell", Vector2i(-1, -1)))
			var attached_wall_cell: Vector2i = _deserialize_cell_variant(data.get("attached_wall_cell", Vector2i(-1, -1)))
			var wall_side: String = String(data.get("wall_side", "")).strip_edges().to_lower()
			if anchor_floor_cell.x < 0 or anchor_floor_cell.y < 0:
				issues.append(_make_map_constructor_issue("wm_missing_anchor_%d" % index, "error", "Wall-mounted object missing anchor_floor_cell.", object_cell, source_name, entity_kind, object_id))
			if attached_wall_cell.x < 0 or attached_wall_cell.y < 0:
				issues.append(_make_map_constructor_issue("wm_missing_attached_%d" % index, "error", "Wall-mounted object missing attached_wall_cell.", object_cell, source_name, entity_kind, object_id))
			if wall_side.is_empty():
				issues.append(_make_map_constructor_issue("wm_missing_side_%d" % index, "error", "Wall-mounted object missing wall_side.", object_cell, source_name, entity_kind, object_id))
			if attached_wall_cell.x >= 0 and attached_wall_cell.y >= 0 and has_grid_bounds and not bool(grid_manager.call("is_in_bounds", attached_wall_cell)):
				issues.append(_make_map_constructor_issue("wm_attached_oob_%d" % index, "error", "Wall-mounted attached wall cell out of bounds.", attached_wall_cell, source_name, entity_kind, object_id))
	# validate explicit cell_items map
	for cell_variant in cell_items.keys():
		var item_cell: Vector2i = _deserialize_cell_variant(cell_variant)
		for item_variant in Array(cell_items.get(cell_variant, [])):
			var item_data: Dictionary = Dictionary(item_variant)
			var item_id: String = String(item_data.get("id", "")).strip_edges()
			if item_id.is_empty():
				issues.append(_make_map_constructor_issue("item_missing_id_%d_%d" % [item_cell.x, item_cell.y], "error", "Item missing id.", item_cell, source_name, "item", ""))
			elif seen_item_ids.has(item_id):
				issues.append(_make_map_constructor_issue("item_duplicate_id_%s" % item_id, "warning", "Duplicate item id: %s." % item_id, item_cell, source_name, "item", item_id))
			else:
				seen_item_ids[item_id] = true
			if item_cell.x < 0 or item_cell.y < 0:
				issues.append(_make_map_constructor_issue("item_invalid_cell_%s" % item_id, "error", "Item cell invalid or negative.", item_cell, source_name, "item", item_id))
	var catalog_ids: Dictionary = {}
	for row_variant in Array(get_map_constructor_wall_material_catalog().get("materials", [])):
		var row: Dictionary = Dictionary(row_variant)
		catalog_ids[String(row.get("id", "")).to_lower()] = true
	for key_variant in _map_constructor_wall_material_overrides.keys():
		var override_row: Dictionary = Dictionary(_map_constructor_wall_material_overrides.get(String(key_variant), {}))
		var override_cell: Vector2i = Vector2i(override_row.get("cell", Vector2i(-1, -1)))
		var override_side: String = String(override_row.get("side", "")).to_lower().strip_edges()
		var override_material_id: String = String(override_row.get("material_id", "")).to_lower().strip_edges()
		if not catalog_ids.has(override_material_id):
			issues.append(_make_map_constructor_issue("wall_material_unknown_%s" % String(key_variant), "warning", "Unknown wall material override id: %s." % override_material_id, override_cell, source_name, "wall_material", String(key_variant)))
		var attached_wall_cell: Vector2i = override_cell + _get_map_constructor_wall_side_delta(override_side)
		if _get_map_constructor_wall_side_delta(override_side) == Vector2i.ZERO or not _is_wall_or_boundary_cell(attached_wall_cell):
			issues.append(_make_map_constructor_issue("wall_material_missing_wall_%s" % String(key_variant), "warning", "Wall material override points to a missing wall.", override_cell, source_name, "wall_material", String(key_variant)))
	return issues

func _map_constructor_collect_world_ids() -> Dictionary:
	var ids: Dictionary = {}
	for object_data in mission_world_objects:
		if typeof(object_data) != TYPE_DICTIONARY:
			continue
		var object_id: String = String(Dictionary(object_data).get("id", "")).strip_edges()
		if not object_id.is_empty():
			ids[object_id] = true
	return ids

func _map_constructor_collect_item_ids() -> Dictionary:
	var ids: Dictionary = {}
	for cell_variant in cell_items.keys():
		for item_variant in Array(cell_items.get(cell_variant, [])):
			if typeof(item_variant) != TYPE_DICTIONARY:
				continue
			var item_id: String = String(Dictionary(item_variant).get("id", "")).strip_edges()
			if not item_id.is_empty():
				ids[item_id] = true
	return ids

func get_map_constructor_autofix_preview(fix_type: String, options: Dictionary = {}) -> Dictionary:
	var lower_type: String = String(fix_type).strip_edges().to_lower()
	var preview: Dictionary = {"ok": false, "fix_type": lower_type, "message": "Unsupported auto-fix type.", "affected_count": 0, "affected_fixes": [], "warnings": []}
	if not _is_task_test_constructor_context():
		preview["message"] = "Auto-fix works only in TASK TEST runtime constructor mode."
		return preview
	var world_ids: Dictionary = _map_constructor_collect_world_ids()
	var item_ids: Dictionary = _map_constructor_collect_item_ids()
	var fixes: Array[Dictionary] = []
	var warnings: Array[String] = []
	if lower_type in ["clear_broken_reference", "remove_invalid_reference", "clear_all_broken_references"]:
		var target_fields: Array[String] = ["target_door_id","target_platform_id","linked_terminal_id","control_source_id","required_key_id","connected_device_ids"]
		for object_data in mission_world_objects:
			var data: Dictionary = Dictionary(object_data)
			var object_id: String = String(data.get("id", ""))
			if lower_type != "clear_all_broken_references":
				if object_id != String(options.get("entity_id", "")) or String(options.get("entity_kind", "world_object")) != "world_object":
					continue
			for field_name in target_fields:
				if lower_type != "clear_all_broken_references" and not String(options.get("field_name", "")) == field_name:
					continue
				if field_name == "connected_device_ids":
					var current_ids: Array[String] = []
					var valid_ids: Array[String] = []
					for cid_variant in Array(data.get("connected_device_ids", [])):
						var cid: String = String(cid_variant).strip_edges()
						if cid.is_empty():
							continue
						current_ids.append(cid)
						if world_ids.has(cid) or item_ids.has(cid):
							valid_ids.append(cid)
					if valid_ids.size() != current_ids.size():
						fixes.append({"entity_kind":"world_object","entity_id":object_id,"field_name":field_name,"old_value":current_ids,"new_value":valid_ids,"cell":Vector2i(data.get("position", Vector2i(-1,-1))),"description":"Remove invalid connected_device_ids on %s" % object_id})
				else:
					var ref_id: String = String(data.get(field_name, "")).strip_edges()
					if ref_id.is_empty():
						continue
					var is_valid: bool = world_ids.has(ref_id) or (field_name == "required_key_id" and item_ids.has(ref_id))
					if not is_valid:
						fixes.append({"entity_kind":"world_object","entity_id":object_id,"field_name":field_name,"old_value":ref_id,"new_value":"","cell":Vector2i(data.get("position", Vector2i(-1,-1))),"description":"Clear broken %s on %s" % [field_name, object_id]})
	elif lower_type in ["repair_wall_mounted_attachment", "repair_all_wall_mounted_attachments"]:
		for object_data in mission_world_objects:
			var data: Dictionary = Dictionary(object_data)
			if String(data.get("placement_mode", "")) != "wall_mounted":
				continue
			if lower_type == "repair_wall_mounted_attachment" and String(data.get("id", "")) != String(options.get("entity_id", "")):
				continue
			var anchor: Vector2i = _deserialize_cell_variant(data.get("anchor_floor_cell", data.get("position", Vector2i(-1, -1))))
			var preferred: String = String(data.get("wall_side", ""))
			var resolved: Dictionary = _resolve_wall_mounted_attachment(anchor, preferred)
			if bool(resolved.get("ok", false)):
				var new_side: String = String(resolved.get("wall_side", ""))
				var new_wall: Vector2i = Vector2i(resolved.get("attached_wall_cell", Vector2i(-1, -1)))
				if new_side != String(data.get("wall_side", "")) or new_wall != _deserialize_cell_variant(data.get("attached_wall_cell", Vector2i(-1,-1))):
					fixes.append({"entity_kind":"world_object","entity_id":String(data.get("id","")),"field_name":"wall_attachment","old_value":{"wall_side":String(data.get("wall_side","")),"attached_wall_cell":_deserialize_cell_variant(data.get("attached_wall_cell", Vector2i(-1,-1)))},"new_value":{"wall_side":new_side,"attached_wall_cell":new_wall},"cell":anchor,"description":"Repair wall-mounted attachment on %s" % String(data.get("id",""))})
			else:
				warnings.append("Cannot repair wall-mounted attachment: no adjacent wall near anchor.")
	elif lower_type == "assign_power_network":
		var entity: Dictionary = get_map_constructor_entity_by_id(String(options.get("entity_kind", "world_object")), String(options.get("entity_id", "")))
		if bool(entity.get("ok", false)):
			var data: Dictionary = Dictionary(entity.get("data", {}))
			var new_net: String = String(options.get("new_power_network_id", "")).strip_edges()
			if new_net.is_empty():
				warnings.append("New power network id is required.")
			elif String(data.get("power_network_id", "")) != new_net:
				fixes.append({"entity_kind":String(entity.get("entity_kind", "world_object")),"entity_id":String(entity.get("id", "")),"field_name":"power_network_id","old_value":String(data.get("power_network_id","")),"new_value":new_net,"cell":Vector2i(entity.get("cell", Vector2i(-1,-1))),"description":"Assign power network on %s" % String(entity.get("id", ""))})
	elif lower_type == "create_power_network":
		var selected_ids: Array = Array(options.get("apply_to_selected_ids", []))
		if selected_ids.is_empty():
			warnings.append("Choose target objects before creating/assigning a power network.")
		else:
			var new_network_id: String = String(options.get("new_power_network_id", "")).strip_edges()
			for id_variant in selected_ids:
				var object_id: String = String(id_variant)
				var entity_info: Dictionary = get_map_constructor_entity_by_id("world_object", object_id)
				if not bool(entity_info.get("ok", false)):
					continue
				var current_data: Dictionary = Dictionary(entity_info.get("data", {}))
				if new_network_id.is_empty() or String(current_data.get("power_network_id", "")) == new_network_id:
					continue
				fixes.append({"entity_kind":"world_object","entity_id":object_id,"field_name":"power_network_id","old_value":String(current_data.get("power_network_id", "")),"new_value":new_network_id,"cell":Vector2i(entity_info.get("cell", Vector2i(-1,-1))),"description":"Assign new network %s to %s" % [new_network_id, object_id]})
	elif lower_type == "fix_missing_required_id":
		var entity_kind: String = String(options.get("entity_kind", "world_object"))
		var entity_id: String = String(options.get("entity_id", ""))
		var field_name: String = String(options.get("field_name", "id"))
		var entity_info: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
		if bool(entity_info.get("ok", false)):
			var data: Dictionary = Dictionary(entity_info.get("data", {}))
			if field_name == "required_key_id" and String(data.get("required_key_id", "")).is_empty():
				var keys: Array[String] = []
				for cell_variant in cell_items.keys():
					for item_variant in Array(cell_items.get(cell_variant, [])):
						var item: Dictionary = Dictionary(item_variant)
						var item_type: String = String(item.get("item_type", item.get("object_type", ""))).to_lower()
						if item_type in ["mechanical_keycard", "digital_key", "access_code"]:
							keys.append(String(item.get("id", "")))
				if keys.size() == 1:
					fixes.append({"entity_kind":entity_kind,"entity_id":entity_id,"field_name":"required_key_id","old_value":"","new_value":keys[0],"cell":Vector2i(entity_info.get("cell", Vector2i(-1,-1))),"description":"Set required_key_id on %s" % entity_id})
				else:
					warnings.append("Cannot safely set required_key_id: need exactly one matching key item.")
	elif lower_type == "apply_issue_fix":
		var issue_id: String = String(options.get("issue_id", "")).strip_edges()
		if issue_id.is_empty():
			warnings.append("Issue id is required.")
		else:
			var validation_issues: Array[Dictionary] = get_map_constructor_validation_issues()
			var issue_match: Dictionary = {}
			for issue_variant in validation_issues:
				var issue_data: Dictionary = Dictionary(issue_variant)
				if String(issue_data.get("id", "")).strip_edges() == issue_id:
					issue_match = issue_data
					break
			if issue_match.is_empty():
				warnings.append("Issue not found.")
			else:
				var issue_fix_options: Array[Dictionary] = get_map_constructor_issue_autofix_options(issue_match)
				var safe_options: Array[Dictionary] = []
				for option_variant in issue_fix_options:
					var option_data: Dictionary = Dictionary(option_variant)
					if String(option_data.get("danger_level", "")).to_lower() == "safe":
						safe_options.append(option_data)
				if safe_options.size() == 1:
					var selected_fix: Dictionary = Dictionary(safe_options[0])
					var nested_fix_type: String = String(selected_fix.get("fix_type", "")).strip_edges()
					var nested_options: Dictionary = Dictionary(selected_fix.get("options", {}))
					if nested_fix_type.is_empty():
						warnings.append("No safe auto-fix available for this issue.")
					else:
						var nested_preview: Dictionary = get_map_constructor_autofix_preview(nested_fix_type, nested_options)
						if bool(nested_preview.get("ok", false)):
							fixes = Array(nested_preview.get("affected_fixes", []))
							for nested_warning_variant in Array(nested_preview.get("warnings", [])):
								warnings.append(String(nested_warning_variant))
						else:
							warnings.append(String(nested_preview.get("message", "No safe auto-fix available for this issue.")))
				elif safe_options.size() > 1:
					warnings.append("Multiple fixes available; choose a specific fix.")
				else:
					warnings.append("No safe auto-fix available for this issue.")
	preview["ok"] = lower_type in ["clear_broken_reference","remove_invalid_reference","clear_all_broken_references","repair_wall_mounted_attachment","repair_all_wall_mounted_attachments","assign_power_network","create_power_network","fix_missing_required_id","apply_issue_fix"]
	preview["affected_fixes"] = fixes
	preview["affected_count"] = fixes.size()
	preview["warnings"] = warnings
	preview["message"] = "Preview ready." if preview["ok"] else "Unsupported auto-fix type."
	return preview

func apply_map_constructor_autofix(fix_type: String, options: Dictionary = {}) -> Dictionary:
	var preview: Dictionary = get_map_constructor_autofix_preview(fix_type, options)
	if not bool(preview.get("ok", false)):
		return {"ok": false, "message": String(preview.get("message", "Auto-fix failed.")), "fixed_count": 0, "fix_id": "", "warnings": Array(preview.get("warnings", []))}
	var fixes: Array = Array(preview.get("affected_fixes", []))
	if fixes.is_empty():
		return {"ok": true, "message": "Nothing to fix.", "fixed_count": 0, "fix_id": "", "warnings": Array(preview.get("warnings", []))}
	_map_constructor_last_autofix_snapshot = {"fix_id":"autofix_%d" % Time.get_unix_time_from_system(), "mission_world_objects": mission_world_objects.duplicate(true), "cell_items": cell_items.duplicate(true), "world_objects_by_cell": world_objects_by_cell.duplicate(true)}
	for row_variant in fixes:
		var row: Dictionary = Dictionary(row_variant)
		var apply_res: Dictionary = apply_map_constructor_property_update(String(row.get("entity_kind", "world_object")), String(row.get("entity_id", "")), String(row.get("field_name", "")), row.get("new_value"))
		if not bool(apply_res.get("ok", false)) and String(row.get("field_name", "")) == "wall_attachment":
			var entity: Dictionary = get_map_constructor_entity_by_id("world_object", String(row.get("entity_id", "")))
			if bool(entity.get("ok", false)):
				var d: Dictionary = Dictionary(entity.get("data", {}))
				var wall_data: Dictionary = Dictionary(row.get("new_value", {}))
				d["wall_side"] = String(wall_data.get("wall_side", d.get("wall_side", "")))
				d["attached_wall_cell"] = Vector2i(wall_data.get("attached_wall_cell", d.get("attached_wall_cell", Vector2i(-1,-1))))
				update_world_object_by_id(String(row.get("entity_id", "")), d)
	PowerSystemRef.recalculate_network(mission_world_objects, "")
	refresh_world_cooling_received()
	_record_map_constructor_change("autofix", {"summary":"Applied auto-fix: %d fields fixed" % fixes.size(), "details":{"fix_type":fix_type, "fixed_count":fixes.size()}, "undo_hint":"Use Undo Last Auto-fix."})
	return {"ok": true, "message": "Auto-fix applied.", "fixed_count": fixes.size(), "fix_id": String(_map_constructor_last_autofix_snapshot.get("fix_id", "")), "warnings": Array(preview.get("warnings", []))}

func undo_last_map_constructor_autofix() -> Dictionary:
	if _map_constructor_last_autofix_snapshot.is_empty():
		return {"ok": false, "message": "No auto-fix to undo."}
	mission_world_objects = Array(_map_constructor_last_autofix_snapshot.get("mission_world_objects", [])).duplicate(true)
	cell_items = Dictionary(_map_constructor_last_autofix_snapshot.get("cell_items", {})).duplicate(true)
	world_objects_by_cell = Dictionary(_map_constructor_last_autofix_snapshot.get("world_objects_by_cell", {})).duplicate(true)
	_map_constructor_last_autofix_snapshot.clear()
	PowerSystemRef.recalculate_network(mission_world_objects, "")
	refresh_world_cooling_received()
	_record_map_constructor_change("autofix_undo", {"summary":"Undid last auto-fix.", "undo_hint":"Re-apply auto-fix manually if needed."})
	return {"ok": true, "message": "Last auto-fix undone."}

func get_map_constructor_issue_autofix_options(issue: Dictionary) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var message: String = String(issue.get("message", "")).to_lower()
	var entity_id: String = String(issue.get("entity_id", ""))
	var entity_kind: String = String(issue.get("entity_kind", "world_object"))
	var issue_id: String = String(issue.get("id", ""))
	if message.find("missing") >= 0 and (message.find("target_door_id") >= 0 or message.find("target_platform_id") >= 0 or message.find("linked_terminal_id") >= 0 or message.find("control_source_id") >= 0 or message.find("required_key_id") >= 0):
		var field_name: String = ""
		for candidate in ["target_door_id","target_platform_id","linked_terminal_id","control_source_id","required_key_id"]:
			if message.find(candidate) >= 0:
				field_name = candidate
				break
		if not field_name.is_empty():
			options.append({"label":"Clear broken %s" % field_name, "fix_type":"clear_broken_reference", "options":{"entity_kind":entity_kind,"entity_id":entity_id,"field_name":field_name,"issue_id":issue_id}, "danger_level":"safe"})
	if String(issue_id).begins_with("wm_"):
		options.append({"label":"Repair wall mount", "fix_type":"repair_wall_mounted_attachment", "options":{"entity_kind":entity_kind,"entity_id":entity_id,"issue_id":issue_id}, "danger_level":"safe"})
	return options


func _map_constructor_issue_is_expected_invalid(issue: Dictionary) -> bool:
	var entity_id: String = String(issue.get("entity_id", "")).strip_edges()
	if entity_id.is_empty():
		return false
	return is_task_test_expected_invalid_object_id(entity_id)

func _map_constructor_build_readiness_check(issue: Dictionary, status: String) -> Dictionary:
	var count: int = 1
	var issue_id: String = String(issue.get("id", ""))
	var label: String = "Validation check"
	if issue_id.find("wm_") == 0:
		label = "Wall-mounted attachment"
	elif issue_id.find("link_") == 0:
		label = "Entity links"
	elif issue_id.find("duplicate_") == 0:
		label = "Duplicate occupancy"
	elif issue_id.find("missing_marker_") == 0:
		label = "Mission markers"
	return {
		"id": issue_id,
		"label": label,
		"status": status,
		"message": String(issue.get("message", "")),
		"count": count,
		"entity_kind": String(issue.get("entity_kind", "")),
		"entity_id": String(issue.get("entity_id", "")),
		"cell": Vector2i(issue.get("cell", Vector2i(-1, -1))),
		"issue_id": issue_id
	}

func get_map_constructor_mission_readiness_report() -> Dictionary:
	var report: Dictionary = {
		"ok": false,
		"playable": false,
		"status": "unknown",
		"summary": "Mission readiness unavailable.",
		"blocking_count": 0,
		"warning_count": 0,
		"info_count": 0,
		"expected_invalid_count": 0,
		"checks": [],
		"blocking_issues": [],
		"warning_issues": [],
		"expected_invalid_issues": [],
		"recommended_actions": []
	}
	if not _is_task_test_constructor_context():
		report["summary"] = "Readiness works only in TASK TEST constructor mode."
		return report
	var checks: Array[Dictionary] = []
	var blocking: Array[Dictionary] = []
	var warnings: Array[Dictionary] = []
	var expected_invalid: Array[Dictionary] = []
	var recommended: Array[Dictionary] = []
	var constructor_issues: Array[Dictionary] = get_map_constructor_validation_issues()
	for issue in constructor_issues:
		var issue_row: Dictionary = Dictionary(issue)
		var severity: String = String(issue_row.get("severity", "info")).to_lower()
		var expected: bool = _map_constructor_issue_is_expected_invalid(issue_row)
		if expected:
			expected_invalid.append(issue_row)
			checks.append(_map_constructor_build_readiness_check(issue_row, "expected_invalid"))
			continue
		if severity == "error":
			blocking.append(issue_row)
			checks.append(_map_constructor_build_readiness_check(issue_row, "fail"))
			var issue_fix_options: Array[Dictionary] = get_map_constructor_issue_autofix_options(issue_row)
			for fix_opt in issue_fix_options:
				var option: Dictionary = Dictionary(fix_opt)
				recommended.append({"label": String(option.get("label", "Fix issue")), "action_type": "autofix", "fix_type": String(option.get("fix_type", "")), "cleanup_type": "", "options": Dictionary(option.get("options", {})), "target_issue_id": String(issue_row.get("id", ""))})
			var message_text: String = String(issue_row.get("message", "")).to_lower()
			if message_text.find("missing") >= 0:
				recommended.append({"label":"Clean invalid references", "action_type":"cleanup", "fix_type":"", "cleanup_type":"invalid_references", "options":{}, "target_issue_id":String(issue_row.get("id", ""))})
			if message_text.find("broken") >= 0 or message_text.find("missing") >= 0:
				recommended.append({"label":"Fix broken references", "action_type":"autofix", "fix_type":"clear_all_broken_references", "cleanup_type":"", "options":{}, "target_issue_id":String(issue_row.get("id", ""))})
			if String(issue_row.get("id", "")).begins_with("wm_"):
				recommended.append({"label":"Repair wall-mounted attachments", "action_type":"autofix", "fix_type":"repair_all_wall_mounted_attachments", "cleanup_type":"", "options":{}, "target_issue_id":String(issue_row.get("id", ""))})
			recommended.append({"label":"Jump to issue", "action_type":"jump", "fix_type":"", "cleanup_type":"", "options":{}, "target_issue_id":String(issue_row.get("id", ""))})
		elif severity == "warning":
			warnings.append(issue_row)
			checks.append(_map_constructor_build_readiness_check(issue_row, "warning"))
		else:
			checks.append(_map_constructor_build_readiness_check(issue_row, "info"))
	var audit_summary: Dictionary = get_map_constructor_audit_summary()
	checks.append({"id":"audit_summary","label":"Audit coverage","status":"info","message":"missing=%d invalid=%d runtime_warn=%d duplicates=%d" % [int(audit_summary.get("missing_coverage_count",0)), int(audit_summary.get("invalid_links_count",0)), int(audit_summary.get("runtime_warnings_count",0)), int(audit_summary.get("duplicate_cell_warnings_count",0))],"count":1,"entity_kind":"","entity_id":"","cell":Vector2i(-1,-1),"issue_id":""})
	var task_audit: Dictionary = get_task_test_system_audit_report()
	var runtime_warnings: Array = Array(task_audit.get("runtime_cell_warnings", []))
	for rw in runtime_warnings:
		warnings.append({"id":"runtime_warning_%d" % warnings.size(), "severity":"warning", "message":String(rw)})
		checks.append({"id":"runtime_warning_%d" % warnings.size(),"label":"Runtime warning","status":"warning","message":String(rw),"count":1,"entity_kind":"","entity_id":"","cell":Vector2i(-1,-1),"issue_id":""})
	var blocking_count: int = blocking.size()
	var warning_count: int = warnings.size()
	var expected_count: int = expected_invalid.size()
	var info_count: int = maxi(0, checks.size() - blocking_count - warning_count - expected_count)
	var status: String = "playable"
	if blocking_count > 0:
		status = "blocked"
	elif warning_count > 0:
		status = "warning"
	report["ok"] = true
	report["playable"] = blocking_count == 0
	report["status"] = status
	report["summary"] = "Readiness %s | blocking=%d warnings=%d expected-invalid=%d info=%d" % [status.to_upper(), blocking_count, warning_count, expected_count, info_count]
	report["blocking_count"] = blocking_count
	report["warning_count"] = warning_count
	report["info_count"] = info_count
	report["expected_invalid_count"] = expected_count
	report["checks"] = checks
	report["blocking_issues"] = blocking
	report["warning_issues"] = warnings
	report["expected_invalid_issues"] = expected_invalid
	report["recommended_actions"] = recommended
	return report

func get_map_constructor_audit_summary() -> Dictionary:
	var audit: Dictionary = get_task_test_system_audit_report()
	return {
		"ok": bool(audit.get("ok", false)),
		"missing_coverage_count": Array(audit.get("missing_coverage", [])).size(),
		"invalid_links_count": Array(audit.get("invalid_links", [])).size(),
		"expected_invalid_links_count": Array(audit.get("expected_invalid_links", [])).size(),
		"runtime_warnings_count": Array(audit.get("runtime_cell_warnings", [])).size(),
		"duplicate_cell_warnings_count": Array(audit.get("duplicate_cell_warnings", [])).size(),
		"objects_without_tags_count": Array(audit.get("objects_without_audit_tags", [])).size()
	}

func get_map_constructor_audit_summary_text() -> String:
	var summary: Dictionary = get_map_constructor_audit_summary()
	var status: String = "WARN"
	if bool(summary.get("ok", false)):
		status = "OK"
	return "Audit %s | missing=%d invalid=%d runtime=%d duplicates=%d" % [
		status,
		int(summary.get("missing_coverage_count", 0)),
		int(summary.get("invalid_links_count", 0)),
		int(summary.get("runtime_warnings_count", 0)),
		int(summary.get("duplicate_cell_warnings_count", 0))
	]

func get_world_object_by_id(id: String) -> Dictionary:
	for object_data in mission_world_objects:
		if String(object_data.get("id", "")) == id:
			return object_data
	return {}

func update_world_object_by_id(id: String, data: Dictionary) -> void:
	if id.is_empty() or data.is_empty():
		return
	for index in range(mission_world_objects.size()):
		var object_data: Dictionary = mission_world_objects[index]
		if String(object_data.get("id", "")) != id:
			continue
		var old_position := Vector2i(object_data.get("position", Vector2i(-1, -1)))
		for key in data.keys():
			object_data[key] = data[key]
		mission_world_objects[index] = object_data
		var new_position := Vector2i(object_data.get("position", old_position))
		if old_position != new_position:
			world_objects_by_cell.erase(old_position)
		world_objects_by_cell[new_position] = object_data
		refresh_world_cooling_received()
		return


func move_world_object_by_heavy_claw(object_id: String, target_cell: Vector2i) -> Dictionary:
	var result := {"success": false, "message": "Cannot move object there.", "object_id": object_id, "from": Vector2i(-1, -1), "to": target_cell}
	if object_id.strip_edges().is_empty():
		result["message"] = "Object not found."
		return result
	var object_data := get_world_object_by_id(object_id)
	if object_data.is_empty():
		result["message"] = "Object not found."
		return result
	var from_cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	result["from"] = from_cell
	if not WorldObjectCatalogRef.can_world_object_be_moved_by_heavy_claw(object_data):
		result["message"] = "Object cannot be moved by Heavy Claw."
		return result
	if from_cell == target_cell:
		result["message"] = "Object already there."
		return result
	if target_cell.x < 0 or target_cell.y < 0:
		result["message"] = "Target cell is blocked."
		return result
	if grid_manager != null:
		if grid_manager.has_method("is_in_bounds") and not bool(grid_manager.is_in_bounds(target_cell)):
			result["message"] = "Target cell is blocked."
			return result
		if grid_manager.has_method("is_walkable") and not bool(grid_manager.is_walkable(target_cell)):
			result["message"] = "Target cell is blocked."
			return result
		if grid_manager.has_method("get_tile"):
			var tile := int(grid_manager.get_tile(target_cell))
			if tile == grid_manager.TILE_WALL:
				result["message"] = "Target cell is blocked."
				return result
	if from_cell.x < 0 or from_cell.y < 0:
		result["message"] = "Object not found."
		return result
	var target_object := get_world_object_at_cell(target_cell)
	if not target_object.is_empty():
		result["message"] = "Target cell is occupied."
		return result
	if cell_items.has(target_cell) and not Array(cell_items.get(target_cell, [])).is_empty():
		result["message"] = "Target cell contains items."
		return result
	world_objects_by_cell.erase(from_cell)
	object_data["position"] = target_cell
	world_objects_by_cell[target_cell] = object_data
	refresh_world_cooling_received()
	PowerSystemRef.recalculate_network(mission_world_objects, "power_net_A")
	refresh_world_cooling_received()
	result["success"] = true
	result["message"] = "Moved %s." % String(object_data.get("display_name", "Object"))
	return result

func refresh_world_cooling_received() -> void:
	for object_data in mission_world_objects:
		if not WorldObjectCatalogRef.can_world_object_receive_cooling(object_data):
			continue
		var target_position := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
		var cooling_received := WorldObjectCatalogRef.calculate_world_cooling_received_for_target(object_data, target_position, mission_world_objects)
		object_data["cooling_received"] = cooling_received
		WorldObjectCatalogRef.update_world_object_heat_state(object_data)

func preview_cooling_application(filter: String = "") -> Dictionary:
	var resolved_filter := _resolve_power_graph_filter_to_network_id(filter.strip_edges())
	var report := {"filter": filter.strip_edges(), "resolved_filter": resolved_filter, "cooling_sources": [], "targets": [], "changes": [], "warnings": []}
	for object_data in mission_world_objects:
		if not WorldObjectCatalogRef.can_world_object_receive_cooling(object_data):
			continue
		var object_network := _get_power_network_id(object_data)
		if not resolved_filter.is_empty() and object_network != resolved_filter:
			continue
		var object_id := String(object_data.get("id", ""))
		var previous_cooling := maxi(0, int(object_data.get("cooling_received", 0)))
		var previous_heat := maxi(0, int(object_data.get("current_heat", 0)))
		var previous_state := String(object_data.get("state", ""))
		var target_position := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
		var next_cooling := WorldObjectCatalogRef.calculate_world_cooling_received_for_target(object_data, target_position, mission_world_objects)
		var projected_heat := maxi(0, int(object_data.get("working_heat", previous_heat)) + int(object_data.get("heat_from_connections", 0)) - next_cooling)
		var threshold := maxi(0, int(object_data.get("overheat_threshold", 0)))
		var next_state := previous_state
		if threshold > 0 and projected_heat >= threshold:
			next_state = "overheated"
		elif previous_state == "overheated":
			next_state = String(object_data.get("overheated_state_before", object_data.get("powered_state_before_unpowered", "active")))
		var reason := "stable"
		if next_cooling > 0:
			reason = "cooled"
		report["targets"].append({"object_id": object_id, "cooling_received": next_cooling, "previous_heat": previous_heat, "new_heat": projected_heat, "previous_state": previous_state, "new_state": next_state, "reason": reason})
		if previous_cooling != next_cooling or previous_heat != projected_heat or previous_state != next_state:
			report["changes"].append({"object_id": object_id, "cooling_received": next_cooling, "previous_heat": previous_heat, "new_heat": projected_heat, "previous_state": previous_state, "new_state": next_state, "reason": reason})
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) != "cooling":
			continue
		var object_network := _get_power_network_id(object_data)
		if not resolved_filter.is_empty() and object_network != resolved_filter:
			continue
		report["cooling_sources"].append({"object_id": String(object_data.get("id", "")), "cooling_output": maxi(0, int(object_data.get("cooling_output", 0))), "cooling_device_type": String(object_data.get("cooling_device_type", "")), "facing_dir": String(object_data.get("facing_dir", "")), "state": String(object_data.get("state", ""))})
	return report

func apply_cooling_application(filter: String = "") -> Dictionary:
	var preview := preview_cooling_application(filter)
	for target_variant in preview.get("targets", []):
		if typeof(target_variant) != TYPE_DICTIONARY:
			continue
		var target: Dictionary = target_variant
		var object_id := String(target.get("object_id", "")).strip_edges()
		if object_id.is_empty():
			continue
		var object_data := get_world_object_by_id(object_id)
		if object_data.is_empty():
			continue
		if not WorldObjectCatalogRef.can_world_object_receive_cooling(object_data):
			continue
		object_data["cooling_received"] = maxi(0, int(target.get("cooling_received", 0)))
		WorldObjectCatalogRef.update_world_object_heat_state(object_data)
	return preview

func update_cooling_for_network_or_area(filter: String = "") -> Dictionary:
	return apply_cooling_application(filter)

func get_cooling_debug_report_text(filter: String = "") -> String:
	var preview := preview_cooling_application(filter)
	var lines: Array[String] = []
	lines.append("Cooling sources:")
	for source_variant in preview.get("cooling_sources", []):
		var source: Dictionary = source_variant
		lines.append("- %s type=%s output=%d facing=%s state=%s" % [String(source.get("object_id", "")), String(source.get("cooling_device_type", "")), int(source.get("cooling_output", 0)), String(source.get("facing_dir", "-")), String(source.get("state", ""))])
	lines.append("Cooling targets:")
	for target_variant in preview.get("targets", []):
		var target: Dictionary = target_variant
		lines.append("- %s heat %d->%d cooling=%d state %s->%s reason=%s" % [String(target.get("object_id", "")), int(target.get("previous_heat", 0)), int(target.get("new_heat", 0)), int(target.get("cooling_received", 0)), String(target.get("previous_state", "")), String(target.get("new_state", "")), String(target.get("reason", ""))])
	lines.append("Preview changes:")
	lines.append("- %d" % Array(preview.get("changes", [])).size())
	lines.append("Warnings:")
	for warning in preview.get("warnings", []):
		lines.append("- %s" % String(warning))
	return "\n".join(lines)

func get_hidden_objects_at_cell(cell: Vector2i) -> Array[Dictionary]:
	var object_data := get_world_object_at_cell(cell)
	if object_data.is_empty():
		return []
	var hidden: Array[Dictionary] = []
	for hidden_id in object_data.get("hidden_content", []):
		hidden.append({"id": hidden_id, "display_name": String(hidden_id).capitalize()})
	return hidden

func get_threats() -> Array[Dictionary]:
	var threats: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) == "threat":
			threats.append(object_data)
	return threats

func is_threat_active(threat: Dictionary) -> bool:
	if threat.is_empty():
		return false
	if String(threat.get("object_group", "")) != "threat":
		return false
	var state := String(threat.get("state", "active"))
	if state in ["destroyed", "disabled", "hacked", "stunned", "unpowered"]:
		return false
	if String(threat.get("behavior_state", "")) == "disabled":
		return false
	if String(threat.get("power_mode", "")) == "external_power" and not bool(threat.get("is_powered", true)):
		return false
	return true

func can_threat_detect_bipop(threat: Dictionary, bipob_cell: Vector2i, grid_manager_ref: Node) -> bool:
	return bool(get_threat_detection_result(threat, bipob_cell, grid_manager_ref).get("detected", false))

func get_threat_detection_result(threat: Dictionary, bipob_cell: Vector2i, grid_manager_ref: Node) -> Dictionary:
	var result := {"detected":false, "threat_id":String(threat.get("id", "")), "threat_name":String(threat.get("display_name", "Threat")), "detection_mode":"", "distance":999, "message":"Threat cannot detect Bipop."}
	if threat.is_empty() or not is_threat_active(threat):
		result["message"] = "Threat inactive."
		return result
	var threat_position := Vector2i(threat.get("position", Vector2i(-1, -1)))
	var distance: int = abs(threat_position.x - bipob_cell.x) + abs(threat_position.y - bipob_cell.y)
	result["distance"] = distance
	var max_range := int(threat.get("detection_range", 0))
	if distance > max_range:
		result["message"] = "%s is out of detection range." % result["threat_name"]
		return result
	for mode_variant in Array(threat.get("detection_modes", [])):
		var mode := String(mode_variant)
		var mode_range := int(threat.get("%s_range" % mode, max_range))
		if mode_range <= 0 or distance > mode_range:
			continue
		if _can_detect_by_mode(mode, threat_position, bipob_cell, grid_manager_ref):
			result["detected"] = true
			result["detection_mode"] = mode
			result["message"] = "%s detected Bipop by %s." % [result["threat_name"], mode]
			return result
	result["message"] = "%s has no clear detection path." % result["threat_name"]
	return result

func _can_detect_by_mode(mode: String, from_cell: Vector2i, to_cell: Vector2i, grid_manager_ref: Node) -> bool:
	if grid_manager_ref == null:
		return false
	return _has_cardinal_clear_path(from_cell, to_cell, grid_manager_ref, mode, mode != "vision")

func _has_cardinal_clear_path(from_cell: Vector2i, to_cell: Vector2i, grid_manager_ref: Node, scan_type: String, allow_wall_pass: bool) -> bool:
	var threat := get_world_object_at_cell(from_cell)
	var detection_shape := String(threat.get("detection_shape", "cardinal"))
	if detection_shape == "cardinal" and from_cell.x != to_cell.x and from_cell.y != to_cell.y:
		return false
	if detection_shape == "radius":
		if from_cell.x != to_cell.x and from_cell.y != to_cell.y:
			return true
	var step := Vector2i(signi(to_cell.x - from_cell.x), signi(to_cell.y - from_cell.y))
	var current := from_cell + step
	while current != to_cell:
		if not grid_manager_ref.is_in_bounds(current):
			return false
		var tile := int(grid_manager_ref.get_tile(current))
		if tile == grid_manager_ref.TILE_WALL:
			return false
		var blocker := get_world_object_at_cell(current)
		if blocker.is_empty():
			current += step
			continue
		if bool(blocker.get("blocks_vision", false)):
			if not allow_wall_pass:
				return false
			if not ScanSystemRef.can_scan_through_wall(blocker, scan_type):
				return false
		current += step
	return true


func reset_world_object_turn_flags() -> void:
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) != "threat":
			continue
		object_data["drained_this_turn"] = false
		var stunned_turns := int(object_data.get("stunned_turns", 0))
		if stunned_turns > 0:
			stunned_turns -= 1
			object_data["stunned_turns"] = stunned_turns
			if stunned_turns <= 0 and String(object_data.get("state", "")) == "stunned":
				var previous_state := String(object_data.get("state_before_stun", ""))
				var previous_behavior := String(object_data.get("behavior_before_stun", ""))
				if previous_state.is_empty() or previous_state in ["destroyed", "hacked", "disabled", "unpowered", "stunned"]:
					object_data["state"] = "active"
				else:
					object_data["state"] = previous_state
				if previous_behavior.is_empty():
					object_data["behavior_state"] = "idle"
				else:
					object_data["behavior_state"] = previous_behavior
				object_data.erase("state_before_stun")
				object_data.erase("behavior_before_stun")

func get_world_object_debug_summary() -> String:
	var world_count := mission_world_objects.size()
	var items_count := 0
	var threats_count := 0
	var powered_count := 0
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) == "item":
			items_count += 1
		if String(object_data.get("object_group", "")) == "threat":
			threats_count += 1
		if bool(object_data.get("is_powered", false)):
			powered_count += 1
	var warning_count := last_threat_warning_ids.size()
	return "WorldObjects: %d | Items: %d | Threats: %d | Powered: %d | Warnings: %d" % [world_count, items_count, threats_count, powered_count, warning_count]

func _is_power_network_object(object_data: Dictionary) -> bool:
	if object_data.is_empty():
		return false
	var object_group := String(object_data.get("object_group", "")).strip_edges().to_lower()
	if object_group == "power":
		return true
	var object_type := String(object_data.get("object_type", "")).strip_edges().to_lower()
	if object_type in [
		"power_source",
		"power_cable",
		"power_socket",
		"cable_reel",
		"circuit_breaker",
		"circuit_switch",
		"fuse_box",
		"light",
		"light_switch",
		"energy_door"
	]:
		return true
	return object_data.has("power_network_id") or object_data.has("network_id") or object_data.has("connected_power_source_id")

func _get_power_network_id(object_data: Dictionary) -> String:
	for key in ["power_network_id", "network_id", "connected_power_source_id"]:
		var value := String(object_data.get(key, "")).strip_edges()
		if not value.is_empty():
			return value
	return ""

func _get_power_event_filter_for_object(object_data: Dictionary) -> String:
	var network_id := _get_power_network_id(object_data)
	if not network_id.is_empty():
		return network_id
	var object_id := String(object_data.get("id", "")).strip_edges()
	if not object_id.is_empty():
		return object_id
	return ""

func _is_power_source_object(object_data: Dictionary) -> bool:
	var object_type := String(object_data.get("object_type", "")).strip_edges().to_lower()
	var power_role := String(object_data.get("power_role", "")).strip_edges().to_lower()
	return object_type == "power_source" or power_role == "source" or object_type in ["power_source_class_1", "power_source_class_2", "power_source_class_3"]

func _collect_power_network_objects() -> Dictionary:
	var power_objects: Array[Dictionary] = []
	var networks := {}
	var sources_by_id := {}
	for object_data in mission_world_objects:
		if not _is_power_network_object(object_data):
			continue
		power_objects.append(object_data)
		var network_id := _get_power_network_id(object_data)
		if not networks.has(network_id):
			networks[network_id] = []
		networks[network_id].append(object_data)
		if _is_power_source_object(object_data):
			var source_id := String(object_data.get("id", "")).strip_edges()
			if not source_id.is_empty():
				sources_by_id[source_id] = object_data
	return {"objects": power_objects, "networks": networks, "sources_by_id": sources_by_id}

func _is_power_source_available(source: Dictionary) -> bool:
	if not _is_power_source_object(source):
		return false
	var state := String(source.get("state", "")).strip_edges().to_lower()
	var is_powered := bool(source.get("is_powered", false))
	var damaged_or_broken := bool(source.get("damaged", false)) or bool(source.get("broken", false))
	if state in ["overheated", "damaged", "broken", "destroyed"]:
		return false
	if damaged_or_broken:
		return false
	if is_powered:
		return true
	return state in ["active", "switch_on", "connected"]

func _normalize_power_gate_text(raw_value: Variant) -> String:
	return String(raw_value).strip_edges().to_lower().replace(" ", "_").replace("-", "_")

func _normalize_power_consumer_text(raw_value: Variant) -> String:
	return _normalize_power_gate_text(raw_value)

func _is_terminal_object(object_data: Dictionary) -> bool:
	var object_group := _normalize_power_consumer_text(object_data.get("object_group", ""))
	var object_type := _normalize_power_consumer_text(object_data.get("object_type", ""))
	if object_group == "terminal":
		return true
	return object_type in ["terminal", "door_terminal", "information_terminal", "info_terminal", "cooling_terminal", "platform_terminal", "elevator_terminal", "turret_terminal", "security_terminal"]

func _is_terminal_powered_for_interaction(object_data: Dictionary) -> bool:
	var state := _normalize_power_consumer_text(object_data.get("state", ""))
	if bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)) or bool(object_data.get("destroyed", false)):
		return false
	if state in ["damaged", "broken", "destroyed", "overheated", "unpowered"]:
		return false
	if object_data.has("is_powered"):
		return bool(object_data.get("is_powered", true))
	return true

func _is_power_reactive_door_object(object_data: Dictionary) -> bool:
	var object_group := _normalize_power_consumer_text(object_data.get("object_group", ""))
	var object_type := _normalize_power_consumer_text(object_data.get("object_type", ""))
	var material := _normalize_power_consumer_text(object_data.get("material", ""))
	if object_type in ["energy_door", "grid_door", "power_door", "electromagnetic_door"]:
		return true
	if object_group == "door" and (material in ["electromagnetic", "energy", "grid"] or object_type.find("electromagnetic") != -1 or object_type.find("energy") != -1 or object_type.find("grid") != -1):
		return true
	return false

func _is_platform_power_consumer(object_data: Dictionary) -> bool:
	var object_group := _normalize_power_consumer_text(object_data.get("object_group", ""))
	var object_type := _normalize_power_consumer_text(object_data.get("object_type", ""))
	return object_group == "platform" or object_type in ["platform", "lifting_platform", "rotating_platform"]

func update_terminal_power_state_from_is_powered(object_data: Dictionary) -> Dictionary:
	var state := _normalize_power_consumer_text(object_data.get("state", ""))
	var previous_state := String(object_data.get("state", ""))
	var report := {"changed": false, "object_id": String(object_data.get("id", "")), "previous_state": previous_state, "new_state": previous_state, "reason": "not_terminal"}
	if not _is_terminal_object(object_data):
		return report
	if state in ["damaged", "broken", "destroyed", "overheated"] or bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)):
		report["reason"] = "terminal_blocked_state"
		return report
	if not bool(object_data.get("is_powered", false)):
		if not state in ["unpowered", "damaged", "broken", "destroyed", "overheated"]:
			object_data["powered_state_before_unpowered"] = previous_state
		if state != "unpowered":
			object_data["state"] = "unpowered"
			report["changed"] = true
			report["new_state"] = "unpowered"
		report["reason"] = "terminal_unpowered"
		return report
	if state == "unpowered":
		var restore_state := _normalize_power_consumer_text(object_data.get("powered_state_before_unpowered", ""))
		if restore_state in ["", "unpowered", "damaged", "broken", "destroyed", "overheated"]:
			restore_state = "active"
		object_data["state"] = restore_state
		report["changed"] = true
		report["new_state"] = restore_state
		report["reason"] = "terminal_power_restored"
		return report
	report["reason"] = "terminal_already_powered"
	return report

func update_power_door_state_from_is_powered(object_data: Dictionary) -> Dictionary:
	var previous_state := String(object_data.get("state", ""))
	var state := _normalize_power_consumer_text(previous_state)
	var report := {"changed": false, "object_id": String(object_data.get("id", "")), "previous_state": previous_state, "new_state": previous_state, "reason": "not_power_reactive_door"}
	if not _is_power_reactive_door_object(object_data):
		return report
	if state in ["damaged", "broken", "destroyed", "sealed"] or bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)):
		report["reason"] = "door_blocked_state"
		return report
	if not bool(object_data.get("is_powered", false)):
		if not state in ["unpowered", "disabled", "damaged", "broken", "destroyed", "sealed"]:
			object_data["powered_state_before_unpowered"] = previous_state
		if state != "unpowered":
			object_data["state"] = "unpowered"
			report["changed"] = true
			report["new_state"] = "unpowered"
		report["reason"] = "door_unpowered"
		return report
	if state in ["unpowered", "disabled"]:
		var restore_state := _normalize_power_consumer_text(object_data.get("powered_state_before_unpowered", ""))
		if restore_state in ["", "unpowered", "disabled", "damaged", "broken", "destroyed", "sealed"]:
			restore_state = "closed"
		object_data["state"] = restore_state
		report["changed"] = true
		report["new_state"] = restore_state
		report["reason"] = "door_power_restored"
		return report
	report["reason"] = "door_already_powered"
	return report

func update_platform_power_state_from_is_powered(object_data: Dictionary) -> Dictionary:
	var previous_state := String(object_data.get("state", ""))
	var state := _normalize_power_consumer_text(previous_state)
	var report := {"changed": false, "object_id": String(object_data.get("id", "")), "previous_state": previous_state, "new_state": previous_state, "reason": "not_platform_consumer"}
	if not _is_platform_power_consumer(object_data):
		return report
	if state in ["damaged", "broken", "destroyed"] or bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)) or bool(object_data.get("destroyed", false)):
		report["reason"] = "platform_blocked_state"
		return report
	if not bool(object_data.get("is_powered", false)):
		if not state in ["unpowered", "disabled", "damaged", "broken", "destroyed"]:
			object_data["powered_state_before_unpowered"] = previous_state
		if state != "unpowered":
			object_data["state"] = "unpowered"
			report["changed"] = true
			report["new_state"] = "unpowered"
		report["reason"] = "platform_unpowered"
		return report
	if state in ["unpowered", "disabled"]:
		var restore_state := _normalize_power_consumer_text(object_data.get("powered_state_before_unpowered", ""))
		if restore_state in ["", "unpowered", "disabled", "damaged", "broken", "destroyed"]:
			restore_state = "active"
		object_data["state"] = restore_state
		report["changed"] = true
		report["new_state"] = restore_state
		report["reason"] = "platform_power_restored"
		return report
	report["reason"] = "platform_already_powered"
	return report

func _get_power_gate_state(object_data: Dictionary) -> Dictionary:
	var object_type := _normalize_power_gate_text(object_data.get("object_type", ""))
	var state := _normalize_power_gate_text(object_data.get("state", ""))
	var damaged_or_broken := bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false))
	if state in ["cut", "damaged", "broken"] or damaged_or_broken:
		if object_type in ["switch", "light_switch", "circuit_switch", "circuit_breaker", "fuse_box", "power_cable", "cable", "cable_reel"]:
			return {"is_gate": true, "gate_type": object_type, "is_closed": false, "reason": state if not state.is_empty() else "damaged"}
	var closed_states := {}
	var open_states := {}
	var is_gate := false
	if object_type in ["switch", "light_switch", "circuit_switch", "circuit_breaker"]:
		is_gate = true
		closed_states = {"switch_on": true, "on": true, "active": true, "closed": true}
		open_states = {"switch_off": true, "off": true, "inactive": true, "open": true}
	elif object_type == "fuse_box":
		is_gate = true
		closed_states = {"installed": true, "fuse_installed": true, "active": true}
		open_states = {"empty": true, "missing_fuse": true, "open": true}
	elif object_type in ["power_cable", "cable", "cable_reel"]:
		is_gate = true
		closed_states = {"connected": true, "installed": true, "active": true}
		open_states = {"disconnected": true, "cut": true, "damaged": true, "broken": true}
	if not is_gate:
		return {"is_gate": false, "gate_type": "", "is_closed": true, "reason": "not_gate"}
	if open_states.has(state):
		return {"is_gate": true, "gate_type": object_type, "is_closed": false, "reason": state}
	if closed_states.has(state):
		return {"is_gate": true, "gate_type": object_type, "is_closed": true, "reason": state}
	return {"is_gate": true, "gate_type": object_type, "is_closed": true, "reason": "default_closed"}

func _is_power_gate_closed(object_data: Dictionary) -> bool:
	var gate_state := _get_power_gate_state(object_data)
	return bool(gate_state.get("is_closed", true))

func _resolve_power_graph_filter_to_network_id(filter: String) -> String:
	var filter_text := filter.strip_edges()
	if filter_text.is_empty():
		return ""
	var collected := _collect_power_network_objects()
	var networks: Dictionary = collected.get("networks", {})
	if networks.has(filter_text):
		return filter_text
	for network_id_variant in networks.keys():
		var network_id := String(network_id_variant)
		var network_objects: Array = networks.get(network_id, [])
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			if String(object_data.get("id", "")).strip_edges() == filter_text:
				return network_id
	return filter_text

func _is_power_load_gate_object(object_data: Dictionary) -> bool:
	var object_type := _normalize_power_gate_text(object_data.get("object_type", ""))
	return object_type in ["switch", "light_switch", "circuit_switch", "circuit_breaker", "fuse_box", "power_cable", "cable", "cable_reel"]

func _is_power_load_consumer_object(object_data: Dictionary) -> bool:
	if _is_power_source_object(object_data):
		return false
	if _is_power_load_gate_object(object_data):
		return false
	var state := _normalize_power_gate_text(object_data.get("state", ""))
	var damaged_or_broken := bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false))
	if damaged_or_broken or state in ["damaged", "broken", "destroyed"]:
		return false
	var object_type := _normalize_power_gate_text(object_data.get("object_type", ""))
	var object_group := _normalize_power_gate_text(object_data.get("object_group", ""))
	if bool(object_data.get("consumes_power", false)):
		return true
	if object_group == "terminal" or object_type in ["terminal", "door_terminal", "information_terminal"]:
		return true
	if object_type in ["energy_door", "energy_wall", "electromagnetic_door", "electromagnetic_wall", "grid_door", "grid_wall"]:
		return true
	if object_type in ["platform", "lifting_platform", "rotating_platform", "lift"]:
		return true
	if object_type in ["light", "camera", "alarm", "turret"]:
		return true
	if object_type.find("cooling") != -1:
		return true
	return false

func _get_power_source_capacity_for_load(source: Dictionary) -> int:
	if source.has("source_capacity"):
		return maxi(1, int(source.get("source_capacity", 1)))
	if source.has("allowed_socket_connections"):
		return maxi(1, int(source.get("allowed_socket_connections", 1)))
	if source.has("allowed_connections"):
		return maxi(1, int(source.get("allowed_connections", 1)))
	if source.has("source_class"):
		var source_class := int(source.get("source_class", 1))
		return maxi(1, mini(3, source_class))
	var object_type := String(source.get("object_type", "")).strip_edges().to_lower()
	if object_type == "power_source_class_1":
		return 1
	if object_type == "power_source_class_2":
		return 2
	if object_type == "power_source_class_3":
		return 3
	if object_type.find("class_2") != -1:
		return 2
	if object_type.find("class_3") != -1:
		return 3
	return 1

func preview_power_source_load_heat_for_network(filter: String = "") -> Dictionary:
	var collected := _collect_power_network_objects()
	var networks: Dictionary = collected.get("networks", {})
	var resolved_filter := _resolve_power_graph_filter_to_network_id(filter.strip_edges())
	var source_reports: Array[Dictionary] = []
	var warnings: Array[String] = []
	var report := {
		"updated": 0,
		"sources": source_reports,
		"warnings": warnings
	}
	for network_id_variant in networks.keys():
		var network_id := String(network_id_variant)
		if not resolved_filter.is_empty() and network_id != resolved_filter:
			continue
		var network_objects: Array = networks.get(network_id, [])
		var consumer_count := 0
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			if _is_power_load_consumer_object(object_data):
				consumer_count += 1
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var source: Dictionary = object_variant
			if not _is_power_source_object(source):
				continue
			var source_capacity := _get_power_source_capacity_for_load(source)
			var overheat_threshold := int(source.get("overheat_threshold", 0))
			var current_heat := int(source.get("current_heat", 0))
			var source_overloaded := consumer_count > source_capacity
			var heat_from_connections := maxi(0, consumer_count - source_capacity)
			var projected_heat := maxi(0, current_heat - int(source.get("cooling_received", 0))) + int(source.get("working_heat", 0)) + heat_from_connections
			var projected_state := String(source.get("state", "")).strip_edges().to_lower()
			if overheat_threshold > 0 and projected_heat >= overheat_threshold:
				projected_state = "overheated"
			source_reports.append({
				"object_id": String(source.get("id", "")),
				"network_id": network_id,
				"source_load": consumer_count,
				"source_capacity": source_capacity,
				"source_overloaded": source_overloaded,
				"current_heat": projected_heat,
				"overheat_threshold": overheat_threshold,
				"state": projected_state
			})
			report["updated"] = int(report.get("updated", 0)) + 1
	return report

func update_power_source_load_heat_for_network(filter: String = "") -> Dictionary:
	var collected := _collect_power_network_objects()
	var networks: Dictionary = collected.get("networks", {})
	var resolved_filter := _resolve_power_graph_filter_to_network_id(filter.strip_edges())
	var source_reports: Array[Dictionary] = []
	var warnings: Array[String] = []
	var report := {
		"updated": 0,
		"sources": source_reports,
		"warnings": warnings
	}
	for network_id_variant in networks.keys():
		var network_id := String(network_id_variant)
		if not resolved_filter.is_empty() and network_id != resolved_filter:
			continue
		var network_objects: Array = networks.get(network_id, [])
		var consumer_count := 0
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			if _is_power_load_consumer_object(object_data):
				consumer_count += 1
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var source: Dictionary = object_variant
			if not _is_power_source_object(source):
				continue
			var source_capacity := _get_power_source_capacity_for_load(source)
			source["source_load"] = consumer_count
			source["source_capacity"] = source_capacity
			source["source_overloaded"] = consumer_count > source_capacity
			source["heat_from_connections"] = maxi(0, consumer_count - source_capacity)
			WorldObjectCatalogRef.update_world_object_heat_state(source)
			source_reports.append({
				"object_id": String(source.get("id", "")),
				"network_id": network_id,
				"source_load": int(source.get("source_load", 0)),
				"source_capacity": int(source.get("source_capacity", source_capacity)),
				"source_overloaded": bool(source.get("source_overloaded", false)),
				"current_heat": int(source.get("current_heat", 0)),
				"overheat_threshold": int(source.get("overheat_threshold", 0)),
				"state": String(source.get("state", ""))
			})
			report["updated"] = int(report.get("updated", 0)) + 1
	return report

func preview_power_graph_state_application(filter: String = "") -> Dictionary:
	var collected := _collect_power_network_objects()
	var networks: Dictionary = collected.get("networks", {})
	var filter_text := filter.strip_edges()
	var resolved_filter := _resolve_power_graph_filter_to_network_id(filter_text)
	var source_load_report := preview_power_source_load_heat_for_network(filter_text)
	var warnings: Array[String] = []
	var changes: Array[Dictionary] = []
	var blocked_entries: Array[Dictionary] = []
	var sources: Array[Dictionary] = []
	var nodes: Array[String] = []
	var reachable: Array[String] = []
	var result: Dictionary = {
		"filter": filter_text,
		"resolved_filter": resolved_filter,
		"sources": sources,
		"nodes": nodes,
		"reachable_object_ids": reachable,
		"blocked": blocked_entries,
		"changes": changes,
		"warnings": warnings,
		"source_load_report": source_load_report
	}
	warnings.append("Power graph MVP uses network-level gate blocking; adjacency traversal not available yet.")
	for network_id_variant in networks.keys():
		var network_id := String(network_id_variant)
		if not resolved_filter.is_empty() and network_id != resolved_filter:
			continue
		var network_objects: Array = networks.get(network_id, [])
		var has_available_source := false
		var network_open_gate := false
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			var object_id := String(object_data.get("id", "")).strip_edges()
			if not object_id.is_empty():
				nodes.append(object_id)
			if _is_power_source_object(object_data) and _is_power_source_available(object_data):
				has_available_source = true
				sources.append({"object_id": object_id, "network_id": network_id})
			var gate_state := _get_power_gate_state(object_data)
			if bool(gate_state.get("is_gate", false)) and not bool(gate_state.get("is_closed", true)):
				network_open_gate = true
				blocked_entries.append({
					"object_id": object_id,
					"network_id": network_id,
					"gate_type": String(gate_state.get("gate_type", "")),
					"reason": String(gate_state.get("reason", "blocked_by_gate"))
				})
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			if _is_power_source_object(object_data):
				continue
			var object_id := String(object_data.get("id", "")).strip_edges()
			var current_is_powered := bool(object_data.get("is_powered", false))
			var state := _normalize_power_gate_text(object_data.get("state", ""))
			var damaged_or_broken := bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false))
			var preview_is_powered := current_is_powered
			var reason := "no_powered_source"
			if state == "cut":
				preview_is_powered = false
				reason = "cut"
			elif state == "broken" or damaged_or_broken:
				preview_is_powered = false
				reason = "broken" if state == "broken" else "damaged"
			elif state == "damaged":
				preview_is_powered = false
				reason = "damaged"
			elif not has_available_source:
				preview_is_powered = false
				reason = "no_powered_source"
			elif network_open_gate:
				preview_is_powered = false
				reason = "blocked_by_gate"
			else:
				preview_is_powered = true
				reason = "graph_powered_source_reachable"
			if preview_is_powered:
				reachable.append(object_id)
			if preview_is_powered == current_is_powered:
				continue
			changes.append({
				"object_id": object_id,
				"network_id": network_id,
				"current_is_powered": current_is_powered,
				"preview_is_powered": preview_is_powered,
				"reason": reason
			})
	return result

func get_power_graph_preview_text(filter: String = "") -> String:
	var preview := preview_power_graph_state_application(filter)
	var lines: Array[String] = []
	lines.append("PowerGraphPreview: filter=%s sources=%d reachable=%d blocked=%d changes=%d warnings=%d" % [
		String(preview.get("filter", "")),
		(preview.get("sources", []) as Array).size(),
		(preview.get("reachable_object_ids", []) as Array).size(),
		(preview.get("blocked", []) as Array).size(),
		(preview.get("changes", []) as Array).size(),
		(preview.get("warnings", []) as Array).size()
	])
	for source_variant in preview.get("sources", []):
		if typeof(source_variant) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = source_variant
		lines.append("SOURCE: object=%s network=%s" % [String(source.get("object_id", "")), String(source.get("network_id", ""))])
	for blocked_variant in preview.get("blocked", []):
		if typeof(blocked_variant) != TYPE_DICTIONARY:
			continue
		var blocked: Dictionary = blocked_variant
		lines.append("BLOCKED: object=%s network=%s gate=%s reason=%s" % [String(blocked.get("object_id", "")), String(blocked.get("network_id", "")), String(blocked.get("gate_type", "")), String(blocked.get("reason", ""))])
	for change_variant in preview.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		lines.append("WOULD_APPLY: object=%s network=%s is_powered %s -> %s reason=%s" % [String(change.get("object_id", "")), String(change.get("network_id", "")), str(bool(change.get("current_is_powered", false))).to_lower(), str(bool(change.get("preview_is_powered", false))).to_lower(), String(change.get("reason", ""))])
	for warning_variant in preview.get("warnings", []):
		lines.append("WARNING: %s" % String(warning_variant))
	return "\n".join(lines)

func apply_power_graph_state_from_preview(filter: String = "") -> Dictionary:
	var source_load_report := update_power_source_load_heat_for_network(filter)
	var preview := preview_power_graph_state_application(filter)
	var applied_changes: Array[Dictionary] = []
	for change_variant in preview.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		var object_id := String(change.get("object_id", "")).strip_edges()
		var object_data := get_world_object_by_id(object_id)
		if object_data.is_empty() or _is_power_source_object(object_data):
			continue
		var previous_is_powered := bool(object_data.get("is_powered", false))
		var next_is_powered := bool(change.get("preview_is_powered", false))
		var state := _normalize_power_gate_text(object_data.get("state", ""))
		var damaged_or_broken := bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false))
		if next_is_powered and (state in ["damaged", "broken", "cut"] or damaged_or_broken):
			next_is_powered = false
		if previous_is_powered == next_is_powered:
			continue
		object_data["is_powered"] = next_is_powered
		if next_is_powered:
			object_data.erase("power_unavailable_reason")
		else:
			object_data["power_unavailable_reason"] = String(change.get("reason", ""))
		var applied_change := {"object_id": object_id, "network_id": String(change.get("network_id", "")), "previous_is_powered": previous_is_powered, "new_is_powered": next_is_powered, "reason": String(change.get("reason", ""))}
		var consumer_state_report := {}
		if _is_terminal_object(object_data):
			consumer_state_report = update_terminal_power_state_from_is_powered(object_data)
		elif _is_power_reactive_door_object(object_data):
			consumer_state_report = update_power_door_state_from_is_powered(object_data)
		elif _is_platform_power_consumer(object_data):
			consumer_state_report = update_platform_power_state_from_is_powered(object_data)
		if not consumer_state_report.is_empty():
			applied_change["consumer_state_report"] = consumer_state_report
		applied_changes.append(applied_change)
	return {"applied": applied_changes.size(), "changes": applied_changes, "warnings": preview.get("warnings", []), "source_load_report": source_load_report}

func execute_power_graph_apply_and_get_report_text(filter: String = "") -> String:
	var report := apply_power_graph_state_from_preview(filter)
	var lines: Array[String] = []
	lines.append("PowerGraphApply: filter=%s applied=%d warnings=%d" % [filter, int(report.get("applied", 0)), (report.get("warnings", []) as Array).size()])
	for change_variant in report.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		var line := "APPLIED: object=%s network=%s is_powered %s -> %s reason=%s" % [String(change.get("object_id", "")), String(change.get("network_id", "")), str(bool(change.get("previous_is_powered", false))).to_lower(), str(bool(change.get("new_is_powered", false))).to_lower(), String(change.get("reason", ""))]
		var consumer_state_report_variant: Variant = change.get("consumer_state_report", {})
		if consumer_state_report_variant is Dictionary:
			var consumer_state_report: Dictionary = consumer_state_report_variant
			if bool(consumer_state_report.get("changed", false)):
				line += " state %s -> %s" % [String(consumer_state_report.get("previous_state", "")), String(consumer_state_report.get("new_state", ""))]
		lines.append(line)
	for warning_variant in report.get("warnings", []):
		lines.append("WARNING: %s" % String(warning_variant))
	return "\n".join(lines)

func preview_power_network_state_application(filter: String = "") -> Dictionary:
	var collected := _collect_power_network_objects()
	var power_objects: Array[Dictionary] = collected.get("objects", [])
	var networks: Dictionary = collected.get("networks", {})
	var sources_by_id: Dictionary = collected.get("sources_by_id", {})
	var changes: Array[Dictionary] = []
	var warnings: Array[String] = []
	var filter_text := filter.strip_edges().to_lower()
	var all_network_ids: Array[String] = []
	for network_id_variant in networks.keys():
		all_network_ids.append(String(network_id_variant))
	all_network_ids.sort()
	for network_id in all_network_ids:
		var network_objects: Array = networks.get(network_id, [])
		var network_has_available_source := false
		var has_powered_consumer := false
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var source_candidate: Dictionary = object_variant
			if not _is_power_source_object(source_candidate):
				continue
			if _is_power_source_available(source_candidate):
				network_has_available_source = true
			else:
				var source_state := String(source_candidate.get("state", "")).strip_edges().to_lower()
				var source_damaged := bool(source_candidate.get("damaged", false)) or bool(source_candidate.get("broken", false))
				if source_state in ["overheated", "damaged"] or source_damaged:
					var source_id := String(source_candidate.get("id", "")).strip_edges()
					warnings.append("Source %s in network %s is unavailable: overheated/damaged." % [source_id, network_id if not network_id.is_empty() else "-"])
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			if _is_power_source_object(object_data):
				continue
			if bool(object_data.get("is_powered", false)):
				has_powered_consumer = true
				break
		if has_powered_consumer and not network_has_available_source:
			warnings.append("Network %s has powered consumers but no available source." % (network_id if not network_id.is_empty() else "-"))
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			var object_id := String(object_data.get("id", "")).strip_edges()
			var object_state := String(object_data.get("state", "")).strip_edges().to_lower()
			var object_damaged := bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false))
			var current_is_powered := bool(object_data.get("is_powered", false))
			var preview_is_powered := current_is_powered
			var reason := "source"
			if _is_power_source_object(object_data):
				preview_is_powered = current_is_powered
				reason = "source"
			elif object_state == "damaged" or object_damaged:
				preview_is_powered = false
				reason = "damaged"
			elif object_state == "overheated":
				preview_is_powered = false
				reason = "overheated"
			else:
				preview_is_powered = network_has_available_source
				reason = "powered_source_available" if network_has_available_source else "no_powered_source"
			var connected_source_id := String(object_data.get("connected_power_source_id", "")).strip_edges()
			if not connected_source_id.is_empty() and not sources_by_id.has(connected_source_id):
				warnings.append("Power object %s connected_power_source_id points to missing source %s." % [object_id, connected_source_id])
			if network_id.is_empty():
				warnings.append("Power object %s has no network id." % object_id)
			if preview_is_powered == current_is_powered:
				continue
			var change_line := "object=%s network=%s reason=%s" % [object_id, network_id, reason]
			if not filter_text.is_empty() and change_line.to_lower().find(filter_text) == -1:
				continue
			changes.append({
				"object_id": object_id,
				"network_id": network_id,
				"current_is_powered": current_is_powered,
				"preview_is_powered": preview_is_powered,
				"reason": reason
			})
	var filtered_warnings: Array[String] = []
	for warning in warnings:
		if filter_text.is_empty() or warning.to_lower().find(filter_text) != -1:
			filtered_warnings.append(warning)
	return {"networks": networks.size(), "objects": power_objects.size(), "changes": changes, "warnings": filtered_warnings}

func get_power_network_state_preview_text(filter: String = "") -> String:
	var preview := preview_power_network_state_application(filter)
	var changes: Array = preview.get("changes", [])
	var warnings: Array = preview.get("warnings", [])
	var lines: Array[String] = []
	lines.append("PowerNetworkStatePreview: networks=%d objects=%d changes=%d warnings=%d" % [
		int(preview.get("networks", 0)),
		int(preview.get("objects", 0)),
		changes.size(),
		warnings.size()
	])
	for change_variant in changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		lines.append("CHANGE: object=%s network=%s is_powered %s -> %s reason=%s" % [
			String(change.get("object_id", "")),
			String(change.get("network_id", "")),
			str(bool(change.get("current_is_powered", false))).to_lower(),
			str(bool(change.get("preview_is_powered", false))).to_lower(),
			String(change.get("reason", ""))
		])
	for warning in warnings:
		lines.append("WARNING: %s" % warning)
	return "\n".join(lines)

func apply_power_network_state_from_preview(filter: String = "") -> Dictionary:
	var preview := preview_power_network_state_application(filter)
	var preview_changes: Array = preview.get("changes", [])
	var applied_changes: Array[Dictionary] = []
	var warnings: Array[String] = []
	for change_variant in preview_changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		var object_id := String(change.get("object_id", "")).strip_edges()
		if object_id.is_empty():
			continue
		var object_data := get_world_object_by_id(object_id)
		if object_data.is_empty():
			warnings.append("Power apply skipped missing object %s." % object_id)
			continue
		if not _is_power_network_object(object_data):
			warnings.append("Power apply skipped non-power object %s." % object_id)
			continue
		if _is_power_source_object(object_data):
			continue
		var previous_is_powered := bool(object_data.get("is_powered", false))
		var preview_is_powered := bool(change.get("preview_is_powered", false))
		var object_state := String(object_data.get("state", "")).strip_edges().to_lower()
		var object_damaged := bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false))
		var blocked_from_power_up := object_state in ["damaged", "overheated"] or object_damaged
		var new_is_powered := preview_is_powered
		if blocked_from_power_up and preview_is_powered:
			new_is_powered = false
		if previous_is_powered == new_is_powered:
			continue
		object_data["is_powered"] = new_is_powered
		applied_changes.append({
			"object_id": object_id,
			"network_id": String(change.get("network_id", "")),
			"previous_is_powered": previous_is_powered,
			"new_is_powered": new_is_powered,
			"reason": String(change.get("reason", ""))
		})
	for preview_warning in preview.get("warnings", []):
		var warning_text := String(preview_warning).strip_edges()
		if warning_text.is_empty():
			continue
		warnings.append(warning_text)
	return {"applied": applied_changes.size(), "changes": applied_changes, "warnings": warnings}



func _apply_graph_power_after_world_object_power_change(object_data: Dictionary, reason: String) -> Dictionary:
	var filter := _get_power_event_filter_for_object(object_data)
	return apply_power_network_after_explicit_power_event(reason, filter)

func preview_cable_path(cable_reel_id: String, target_id: String) -> Dictionary:
	var reel := get_world_object_by_id(cable_reel_id.strip_edges())
	var target := get_world_object_by_id(target_id.strip_edges())
	if reel.is_empty() or target.is_empty():
		return {"valid": false, "reason": "target_not_connectable", "length": 0, "max_length": 0, "path_cells": []}
	var reel_cell := WorldObjectCatalogRef.to_world_cell(reel.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	var target_cell := WorldObjectCatalogRef.to_world_cell(target.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	var path_cells: Array = []
	var x_step := signi(target_cell.x - reel_cell.x)
	var y_step := signi(target_cell.y - reel_cell.y)
	var current := reel_cell
	while current.x != target_cell.x:
		current = Vector2i(current.x + x_step, current.y)
		path_cells.append(current)
	while current.y != target_cell.y:
		current = Vector2i(current.x, current.y + y_step)
		path_cells.append(current)
	return validate_cable_path(reel, target, path_cells)

func validate_cable_path(cable_reel: Dictionary, target: Dictionary, path_cells: Array = []) -> Dictionary:
	if cable_reel.is_empty() or target.is_empty():
		return {"valid": false, "reason": "target_not_connectable", "length": 0, "max_length": 0, "path_cells": []}
	if bool(cable_reel.get("cut", false)):
		return {"valid": false, "reason": "cable_cut", "length": 0, "max_length": 0, "path_cells": path_cells}
	if bool(cable_reel.get("damaged", false)):
		return {"valid": false, "reason": "cable_damaged", "length": 0, "max_length": 0, "path_cells": path_cells}
	if not bool(target.get("can_connect_cable", false)) and String(target.get("object_type", "")) != "power_source":
		return {"valid": false, "reason": "no_socket", "length": 0, "max_length": 0, "path_cells": path_cells}
	var max_length := maxi(1, int(cable_reel.get("max_cable_length", 5)))
	var length := path_cells.size()
	if length > max_length:
		return {"valid": false, "reason": "too_far", "length": length, "max_length": max_length, "path_cells": path_cells}
	for path_cell_variant in path_cells:
		if typeof(path_cell_variant) != TYPE_VECTOR2I:
			continue
		var path_cell: Vector2i = path_cell_variant
		var blocker := get_world_object_at_cell(path_cell)
		if blocker.is_empty():
			continue
		if bool(blocker.get("blocks_movement", false)) or String(blocker.get("state", "")) == "closed":
			return {"valid": false, "reason": "path_blocked", "length": length, "max_length": max_length, "path_cells": path_cells}
	return {"valid": true, "reason": "ok", "length": length, "max_length": max_length, "path_cells": path_cells}

func can_connect_cable_reel_to_target(cable_reel: Dictionary, target: Dictionary) -> Dictionary:
	var path_report := preview_cable_path(String(cable_reel.get("id", "")), String(target.get("id", "")))
	if not bool(path_report.get("valid", false)):
		return path_report
	return {"valid": true, "reason": "ok", "length": int(path_report.get("length", 0)), "max_length": int(path_report.get("max_length", 0)), "path_cells": path_report.get("path_cells", [])}

func connect_cable_reel_to_target(cable_reel_id: String, target_id: String) -> Dictionary:
	var cable_reel := get_world_object_by_id(cable_reel_id.strip_edges())
	var target := get_world_object_by_id(target_id.strip_edges())
	if cable_reel.is_empty() or target.is_empty():
		return {"success": false, "reason": "target_not_connectable"}
	var can_connect := can_connect_cable_reel_to_target(cable_reel, target)
	if not bool(can_connect.get("valid", false)):
		return {"success": false, "reason": String(can_connect.get("reason", "target_not_connectable")), "path": can_connect}
	cable_reel["connected"] = true
	cable_reel["disconnected"] = false
	cable_reel["cut"] = false
	cable_reel["state"] = "connected"
	cable_reel["cable_endpoint_a_id"] = String(cable_reel.get("id", ""))
	cable_reel["cable_endpoint_b_id"] = String(target.get("id", ""))
	cable_reel["cable_path_cells"] = can_connect.get("path_cells", [])
	cable_reel["cable_length"] = int(can_connect.get("length", 0))
	cable_reel["cable_max_length"] = int(can_connect.get("max_length", 0))
	var report := _apply_graph_power_after_world_object_power_change(cable_reel, "cable_connected")
	return {"success": true, "reason": "ok", "apply": report, "path": can_connect}

func disconnect_cable_from_target(cable_id_or_reel_id: String, target_id: String = "") -> Dictionary:
	var cable := get_world_object_by_id(cable_id_or_reel_id.strip_edges())
	if cable.is_empty():
		return {"success": false, "reason": "target_not_connectable"}
	if not target_id.strip_edges().is_empty() and String(cable.get("cable_endpoint_b_id", "")) != target_id.strip_edges():
		return {"success": false, "reason": "target_not_connectable"}
	cable["connected"] = false
	cable["disconnected"] = true
	cable["state"] = "disconnected"
	var report := _apply_graph_power_after_world_object_power_change(cable, "cable_disconnected")
	return {"success": true, "reason": "ok", "apply": report}

func cut_power_cable(cable_id: String) -> Dictionary:
	var cable := get_world_object_by_id(cable_id.strip_edges())
	if cable.is_empty():
		return {"success": false, "reason": "target_not_connectable"}
	cable["state"] = "cut"
	cable["cut"] = true
	cable["connected"] = false
	cable["disconnected"] = true
	var report := _apply_graph_power_after_world_object_power_change(cable, "cable_cut")
	return {"success": true, "reason": "cable_cut", "apply": report}

func repair_power_cable(cable_id: String) -> Dictionary:
	var cable := get_world_object_by_id(cable_id.strip_edges())
	if cable.is_empty():
		return {"success": false, "reason": "target_not_connectable"}
	if not bool(cable.get("cut", false)) and not bool(cable.get("damaged", false)):
		return {"success": false, "reason": "ok"}
	cable["cut"] = false
	cable["damaged"] = false
	cable["connected"] = false
	cable["disconnected"] = true
	cable["state"] = "repaired"
	var report := _apply_graph_power_after_world_object_power_change(cable, "cable_repaired")
	return {"success": true, "reason": "cable_repaired", "apply": report}

func reconnect_power_cable(cable_id: String) -> Dictionary:
	var cable := get_world_object_by_id(cable_id.strip_edges())
	if cable.is_empty():
		return {"success": false, "reason": "target_not_connectable"}
	if bool(cable.get("cut", false)) or bool(cable.get("damaged", false)):
		return {"success": false, "reason": "cable_damaged"}
	cable["connected"] = true
	cable["disconnected"] = false
	cable["state"] = "connected"
	var report := _apply_graph_power_after_world_object_power_change(cable, "cable_reconnected")
	return {"success": true, "reason": "cable_reconnected", "apply": report}

func update_power_source_overheat_recovery_for_network(filter: String = "") -> Dictionary:
	var resolved_filter := _resolve_power_graph_filter_to_network_id(filter.strip_edges())
	var recovered: Array[Dictionary] = []
	var warnings: Array[String] = []
	for object_data in mission_world_objects:
		if not _is_power_source_object(object_data):
			continue
		var network_id := _get_power_network_id(object_data)
		if not resolved_filter.is_empty() and network_id != resolved_filter:
			continue
		var prev_state := String(object_data.get("state", "")).strip_edges().to_lower()
		var prev_is_powered := bool(object_data.get("is_powered", false))
		var prev_overheated_state_before := String(object_data.get("overheated_state_before", object_data.get("powered_state_before_unpowered", "active"))).strip_edges().to_lower()
		var prev_damaged_flag := bool(object_data.get("damaged", false))
		var prev_broken_flag := bool(object_data.get("broken", false))
		var prev_destroyed_flag := bool(object_data.get("destroyed", false))
		var prev_current_heat := int(object_data.get("current_heat", 0))
		var prev_threshold := int(object_data.get("overheat_threshold", 0))
		var has_prev_damage_flags := prev_damaged_flag or prev_broken_flag or prev_destroyed_flag
		var prev_state_is_damage := prev_state in ["damaged", "broken", "destroyed"]
		var prev_overheated_state_is_damage := prev_overheated_state_before in ["damaged", "broken", "destroyed"]
		WorldObjectCatalogRef.update_world_object_heat_state(object_data)
		var next_state := String(object_data.get("state", "")).strip_edges().to_lower()
		var threshold := int(object_data.get("overheat_threshold", 0))
		var heat := int(object_data.get("current_heat", 0))
		if prev_state != "overheated":
			continue
		if has_prev_damage_flags or prev_state_is_damage or prev_overheated_state_is_damage or bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)) or bool(object_data.get("destroyed", false)) or next_state in ["damaged", "broken", "destroyed"]:
			if prev_overheated_state_is_damage:
				object_data["state"] = prev_overheated_state_before
			elif prev_state_is_damage:
				object_data["state"] = prev_state
			elif has_prev_damage_flags and next_state == "active":
				object_data["state"] = "unpowered"
			object_data["is_powered"] = false
			object_data["power_unavailable_reason"] = "source_damage_state"
			warnings.append("Source %s remains unavailable due to source_damage_state." % String(object_data.get("id", "")))
			continue
		if threshold > 0 and heat >= threshold:
			continue
		var restore_state := prev_overheated_state_before
		if restore_state in ["", "unpowered", "overheated", "damaged", "broken", "destroyed"]:
			restore_state = "active"
		object_data["state"] = restore_state
		object_data["power_unavailable_reason"] = ""
		recovered.append({
			"object_id": String(object_data.get("id", "")),
			"network_id": network_id,
			"previous_state": prev_state,
			"new_state": restore_state,
			"current_heat": heat,
			"overheat_threshold": threshold,
			"previous_is_powered": prev_is_powered,
			"previous_overheated_state_before": prev_overheated_state_before,
			"previous_damage_flags": {"damaged": prev_damaged_flag, "broken": prev_broken_flag, "destroyed": prev_destroyed_flag},
			"previous_current_heat": prev_current_heat,
			"previous_overheat_threshold": prev_threshold
		})
	return {"filter": filter.strip_edges(), "resolved_filter": resolved_filter, "recovered": recovered, "warnings": warnings}

func execute_power_source_recovery_apply(filter: String = "") -> Dictionary:
	var recovery := update_power_source_overheat_recovery_for_network(filter)
	var apply := apply_power_network_after_explicit_power_event("source_cooling_recovered", String(recovery.get("resolved_filter", filter)))
	return {"recovery": recovery, "apply": apply}

func apply_power_network_after_explicit_power_event(reason: String = "", filter: String = "") -> Dictionary:
	var report := apply_power_graph_state_from_preview(filter)
	return {
		"event_reason": reason,
		"applied": int(report.get("applied", 0)),
		"changes": report.get("changes", []),
		"warnings": report.get("warnings", [])
	}

func execute_power_event_apply_and_get_report_text(reason: String = "", filter: String = "") -> String:
	var report := apply_power_network_after_explicit_power_event(reason, filter)
	var changes: Array = report.get("changes", [])
	var warnings: Array = report.get("warnings", [])
	var lines: Array[String] = []
	lines.append("PowerEventApply: reason=%s applied=%d warnings=%d" % [reason, int(report.get("applied", 0)), warnings.size()])
	for change_variant in changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		lines.append("APPLIED: object=%s network=%s is_powered %s -> %s reason=%s" % [
			String(change.get("object_id", "")),
			String(change.get("network_id", "")),
			str(bool(change.get("previous_is_powered", false))).to_lower(),
			str(bool(change.get("new_is_powered", false))).to_lower(),
			String(change.get("reason", ""))
		])
	for warning in warnings:
		lines.append("WARNING: %s" % String(warning))
	return "\n".join(lines)

func get_power_event_apply_preview_text(reason: String = "", filter: String = "") -> String:
	var preview := preview_power_network_state_application(filter)
	var changes: Array = preview.get("changes", [])
	var warnings: Array = preview.get("warnings", [])
	var lines: Array[String] = []
	lines.append("PowerEventApplyPreview: reason=%s changes=%d warnings=%d" % [reason, changes.size(), warnings.size()])
	for change_variant in changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		lines.append("WOULD_APPLY: object=%s network=%s is_powered %s -> %s reason=%s" % [
			String(change.get("object_id", "")),
			String(change.get("network_id", "")),
			str(bool(change.get("current_is_powered", false))).to_lower(),
			str(bool(change.get("preview_is_powered", false))).to_lower(),
			String(change.get("reason", ""))
		])
	for warning in warnings:
		lines.append("WARNING: %s" % String(warning))
	return "\n".join(lines)

func execute_power_network_apply_and_get_report_text(filter: String = "") -> String:
	var report := apply_power_network_state_from_preview(filter)
	var changes: Array = report.get("changes", [])
	var warnings: Array = report.get("warnings", [])
	var lines: Array[String] = []
	lines.append("PowerNetworkApply: applied=%d warnings=%d" % [int(report.get("applied", 0)), warnings.size()])
	for change_variant in changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		lines.append("APPLIED: object=%s network=%s is_powered %s -> %s reason=%s" % [
			String(change.get("object_id", "")),
			String(change.get("network_id", "")),
			str(bool(change.get("previous_is_powered", false))).to_lower(),
			str(bool(change.get("new_is_powered", false))).to_lower(),
			String(change.get("reason", ""))
		])
	for warning in warnings:
		lines.append("WARNING: %s" % String(warning))
	return "\n".join(lines)

func execute_power_network_apply_debug_command(filter: String = "") -> String:
	return execute_power_network_apply_and_get_report_text(filter)

func get_power_network_apply_debug_preview_text(filter: String = "") -> String:
	return get_power_network_apply_preview_report_text(filter)

func get_power_network_apply_preview_report_text(filter: String = "") -> String:
	var preview := preview_power_network_state_application(filter)
	var changes: Array = preview.get("changes", [])
	var warnings: Array = preview.get("warnings", [])
	var lines: Array[String] = []
	lines.append("PowerNetworkApplyPreview: changes=%d warnings=%d" % [changes.size(), warnings.size()])
	for change_variant in changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		lines.append("WOULD_APPLY: object=%s network=%s is_powered %s -> %s reason=%s" % [
			String(change.get("object_id", "")),
			String(change.get("network_id", "")),
			str(bool(change.get("current_is_powered", false))).to_lower(),
			str(bool(change.get("preview_is_powered", false))).to_lower(),
			String(change.get("reason", ""))
		])
	for warning in warnings:
		lines.append("WARNING: %s" % String(warning))
	return "\n".join(lines)

func _get_power_network_summary_lines(filter: String = "") -> Array[String]:
	var grouped := {}
	for object_data in mission_world_objects:
		if not _is_power_network_object(object_data):
			continue
		var network_id := _get_power_network_id(object_data)
		if not grouped.has(network_id):
			grouped[network_id] = []
		grouped[network_id].append(object_data)
	var ids: Array[String] = []
	for key in grouped.keys():
		ids.append(String(key))
	ids.sort()
	var filter_text := filter.strip_edges().to_lower()
	var lines: Array[String] = []
	for network_id in ids:
		var objects: Array = grouped.get(network_id, [])
		var object_count := 0
		var source_count := 0
		var cable_count := 0
		var socket_count := 0
		var network_powered := false
		var overheated_sources := 0
		var damaged_count := 0
		var connection_count := 0
		for object_variant in objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			object_count += 1
			var object_type := String(object_data.get("object_type", "")).strip_edges().to_lower()
			var state := String(object_data.get("state", "")).strip_edges().to_lower()
			var is_source := _is_power_source_object(object_data)
			if is_source:
				source_count += 1
			if object_type.find("cable") != -1 or object_type == "power_cable":
				cable_count += 1
			if object_type.find("socket") != -1 or object_type == "power_socket":
				socket_count += 1
			if bool(object_data.get("is_powered", false)) or state in ["active", "switch_on", "connected"]:
				network_powered = true
			var threshold := int(object_data.get("overheat_threshold", 0))
			var current_heat := int(object_data.get("current_heat", 0))
			if is_source and (state == "overheated" or (threshold > 0 and current_heat >= threshold)):
				overheated_sources += 1
			if state == "damaged" or bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)):
				damaged_count += 1
			if state == "connected" or bool(object_data.get("connected", false)):
				connection_count += 1
		var network_text := network_id if not network_id.is_empty() else "-"
		var line := "network=%s | objects=%d | sources=%d | cables=%d | sockets=%d | powered=%s | overheated_sources=%d | damaged=%d | connections=%d" % [
			network_text, object_count, source_count, cable_count, socket_count, str(network_powered).to_lower(), overheated_sources, damaged_count, connection_count
		]
		if not filter_text.is_empty() and line.to_lower().find(filter_text) == -1:
			continue
		lines.append(line)
	return lines

func get_power_network_debug_summary_text(filter: String = "") -> String:
	var lines := _get_power_network_summary_lines(filter)
	if lines.is_empty():
		return "PowerNetworkSummary:\nnone" if filter.strip_edges().is_empty() else "PowerNetworkSummary:\nnone (filter=%s)" % filter.strip_edges().to_lower()
	return "PowerNetworkSummary:\n%s" % "\n".join(lines)

func _build_power_network_debug_object(object_id: String, object_type: String, network_id: String, overrides: Dictionary = {}) -> Dictionary:
	var object_data := {
		"id": object_id,
		"object_group": "power",
		"object_type": object_type,
		"power_network_id": network_id,
		"state": "active",
		"is_powered": false,
		"current_heat": 0,
		"overheat_threshold": 0,
		"connected": false
	}
	for key in overrides.keys():
		object_data[key] = overrides[key]
	return object_data

func validate_power_network_runtime_state() -> Dictionary:
	var warnings: Array[String] = []
	var errors: Array[String] = []
	var collected := _collect_power_network_objects()
	var power_objects: Array[Dictionary] = collected.get("objects", [])
	var networks: Dictionary = collected.get("networks", {})
	var sources_by_id: Dictionary = collected.get("sources_by_id", {})
	var source_ids := {}
	for source_id in sources_by_id.keys():
		source_ids[String(source_id)] = true
	var network_has_powered_source := {}
	for object_data in power_objects:
		var object_id := String(object_data.get("id", "")).strip_edges()
		var network_id := _get_power_network_id(object_data)
		if network_id.is_empty():
			warnings.append("Power object %s has no network id." % object_id)
		if _is_power_source_object(object_data):
			var state := String(object_data.get("state", "")).strip_edges().to_lower()
			var powered_source := bool(object_data.get("is_powered", false)) and state != "overheated"
			if powered_source:
				network_has_powered_source[network_id] = true
	for object_data in power_objects:
		var object_id := String(object_data.get("id", "")).strip_edges()
		var current_heat := int(object_data.get("current_heat", 0))
		var threshold := int(object_data.get("overheat_threshold", 0))
		if current_heat < 0:
			errors.append("Power object %s has negative current_heat (%d)." % [object_id, current_heat])
		if threshold < 0:
			errors.append("Power object %s has negative overheat_threshold (%d)." % [object_id, threshold])
		var state_text := String(object_data.get("state", "")).strip_edges().to_lower()
		var damaged_or_broken := bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false))
		if _is_power_source_object(object_data):
			if threshold > 0 and current_heat >= threshold and state_text != "overheated":
				warnings.append("Power source %s current_heat >= overheat_threshold but state is not overheated." % object_id)
			if threshold > 0 and state_text == "overheated" and current_heat < threshold and not damaged_or_broken:
				warnings.append("Power source %s state is overheated but current_heat < overheat_threshold and object is not damaged/broken." % object_id)
		var linked_source_id := String(object_data.get("connected_power_source_id", "")).strip_edges()
		if not linked_source_id.is_empty() and not source_ids.has(linked_source_id):
			warnings.append("Power object %s connected_power_source_id points to missing source %s." % [object_id, linked_source_id])
	for network_id in networks.keys():
		var objects: Array = networks[network_id]
		var has_source := false
		var has_cable_or_socket := false
		var has_powered_source := bool(network_has_powered_source.get(network_id, false))
		for object_variant in objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			var object_id := String(object_data.get("id", "")).strip_edges()
			var object_type := String(object_data.get("object_type", "")).strip_edges().to_lower()
			var state := String(object_data.get("state", "")).strip_edges().to_lower()
			var connected := state == "connected" or bool(object_data.get("connected", false))
			var is_source := _is_power_source_object(object_data)
			if is_source:
				has_source = true
				if object_data.has("allowed_connections"):
					var allowed := int(object_data.get("allowed_connections", -1))
					if allowed >= 0:
						var source_connections := 0
						for object_variant_2 in objects:
							if typeof(object_variant_2) != TYPE_DICTIONARY:
								continue
							var connected_object: Dictionary = object_variant_2
							var connected_source_id := String(connected_object.get("connected_power_source_id", "")).strip_edges()
							if connected_source_id == object_id:
								source_connections += 1
						if source_connections > allowed:
							warnings.append("Power source %s connections (%d) exceed allowed_connections (%d)." % [object_id, source_connections, allowed])
			if object_type.find("cable") != -1 or object_type.find("socket") != -1:
				has_cable_or_socket = true
			if connected and not has_powered_source:
				warnings.append("Connected power object %s is in network %s but no source is powered." % [object_id, String(network_id if not String(network_id).is_empty() else "-")])
			if bool(object_data.get("is_powered", false)) and not has_powered_source:
				warnings.append("Power object %s is_powered=true but network %s has no powered source." % [object_id, String(network_id if not String(network_id).is_empty() else "-")])
		if has_cable_or_socket and not has_source:
			warnings.append("Network %s has cables/sockets but no source." % String(network_id if not String(network_id).is_empty() else "-"))
	return {"valid": errors.is_empty(), "networks": networks.size(), "objects": power_objects.size(), "warnings": warnings, "errors": errors}

func get_power_network_validation_text() -> String:
	var validation := validate_power_network_runtime_state()
	var warnings: Array[String] = validation.get("warnings", [])
	var errors: Array[String] = validation.get("errors", [])
	var lines: Array[String] = []
	lines.append("PowerNetworkValidation: valid=%s networks=%d objects=%d warnings=%d errors=%d" % [
		str(bool(validation.get("valid", false))).to_lower(),
		int(validation.get("networks", 0)),
		int(validation.get("objects", 0)),
		warnings.size(),
		errors.size()
	])
	for warning in warnings:
		lines.append("WARNING: %s" % warning)
	for err in errors:
		lines.append("ERROR: %s" % err)
	return "\n".join(lines)

func validate_power_network_debug_scenario() -> Array[String]:
	var warnings: Array[String] = []
	var temp_objects: Array[Dictionary] = []
	var temp_ids := {}
	var base_size := mission_world_objects.size()
	var unchanged_snapshot: Array = []
	for object_data in mission_world_objects:
		unchanged_snapshot.append(object_data)
	temp_objects.append(_build_power_network_debug_object("power_debug_source_no_threshold", "power_source", "power_debug_no_threshold", {
		"is_powered": true,
		"current_heat": 0
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_overheated", "power_source", "power_debug_overheated", {
		"state": "overheated",
		"is_powered": false,
		"current_heat": 0,
		"overheat_threshold": 3
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_cable_before_source", "power_cable", "power_debug_order", {
		"state": "connected",
		"connected": true,
		"connected_power_source_id": "power_debug_source_order"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_order", "power_source", "power_debug_order", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_cable_missing_source", "power_cable", "power_debug_missing_source", {
		"state": "connected",
		"connected": true,
		"connected_power_source_id": "power_debug_source_missing"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_limit", "power_source", "power_debug_limit", {
		"allowed_connections": 1,
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_cable_limit_a", "power_cable", "power_debug_limit", {
		"state": "connected",
		"connected": true,
		"connected_power_source_id": "power_debug_source_limit"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_cable_limit_b", "power_cable", "power_debug_limit", {
		"state": "connected",
		"connected": true,
		"connected_power_source_id": "power_debug_source_limit"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_generic_connected", "power_source", "power_debug_generic_connected", {
		"allowed_connections": 0
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_cable_generic_connected", "power_cable", "power_debug_generic_connected", {
		"state": "connected",
		"connected": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_negative_heat", "power_cable", "power_debug_negative_heat", {
		"current_heat": -1
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_preview_source", "power_source", "power_debug_preview_active", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_preview_cable", "power_cable", "power_debug_preview_active", {
		"is_powered": false
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_preview_source_overheated", "power_source", "power_debug_preview_overheated", {
		"state": "overheated",
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_preview_cable_overheated", "power_cable", "power_debug_preview_overheated", {
		"is_powered": false
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_preview_source_damaged_consumer", "power_source", "power_debug_preview_damaged_consumer", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_preview_consumer_damaged", "power_cable", "power_debug_preview_damaged_consumer", {
		"is_powered": false,
		"state": "damaged"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_preview_consumer_damaged_powered", "power_cable", "power_debug_preview_damaged_consumer", {
		"is_powered": true,
		"state": "damaged"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_a_source", "power_source", "power_debug_apply_case_a", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_a_consumer", "power_cable", "power_debug_apply_case_a", {
		"is_powered": false
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_b_source", "power_source", "power_debug_apply_case_b", {
		"is_powered": true,
		"state": "overheated"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_b_consumer", "power_cable", "power_debug_apply_case_b", {
		"is_powered": false
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_c_source", "power_source", "power_debug_apply_case_c", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_c_consumer", "power_cable", "power_debug_apply_case_c", {
		"is_powered": true,
		"state": "damaged"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_d_source_on", "power_source", "power_debug_apply_case_d", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_d_source_off", "power_source", "power_debug_apply_case_d", {
		"is_powered": false
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_d_consumer", "power_cable", "power_debug_apply_case_d", {
		"is_powered": false
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_event_apply_source", "power_source", "power_debug_event_apply", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_event_apply_consumer", "power_cable", "power_debug_event_apply", {
		"is_powered": false
	}))
	var debug_switch_object := _build_power_network_debug_object("power_debug_switch_toggle_object", "circuit_switch", "power_debug_switch_toggle", {
		"state": "switch_off",
		"is_powered": false
	})
	temp_objects.append(debug_switch_object)
	temp_objects.append(_build_power_network_debug_object("power_debug_switch_toggle_source", "power_source", "power_debug_switch_toggle", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_switch_toggle_consumer", "power_cable", "power_debug_switch_toggle", {
		"is_powered": false
	}))
	var debug_fuse_object := _build_power_network_debug_object("power_debug_fuse_box", "fuse_box", "power_debug_fuse_event", {
		"state": "empty",
		"is_powered": false
	})
	temp_objects.append(debug_fuse_object)
	temp_objects.append(_build_power_network_debug_object("power_debug_fuse_source", "power_source", "power_debug_fuse_event", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_fuse_consumer", "power_cable", "power_debug_fuse_event", {
		"is_powered": false
	}))
	var debug_cable_object := _build_power_network_debug_object("power_debug_cable_object", "power_cable", "power_debug_cable_event", {
		"state": "disconnected",
		"is_powered": false
	})
	temp_objects.append(debug_cable_object)
	temp_objects.append(_build_power_network_debug_object("power_debug_cable_source", "power_source", "power_debug_cable_event", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_cable_consumer", "power_socket", "power_debug_cable_event", {
		"is_powered": false
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_closed_gate_source", "power_source", "power_debug_graph_closed_gate", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_closed_gate_switch", "circuit_switch", "power_debug_graph_closed_gate", {"state": "switch_on"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_closed_gate_consumer", "power_socket", "power_debug_graph_closed_gate", {"is_powered": false}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_open_switch_source", "power_source", "power_debug_graph_open_switch", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_open_switch_gate", "circuit_switch", "power_debug_graph_open_switch", {"state": "switch_off"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_open_switch_consumer", "power_socket", "power_debug_graph_open_switch", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_empty_fuse_source", "power_source", "power_debug_graph_empty_fuse", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_empty_fuse_gate", "fuse_box", "power_debug_graph_empty_fuse", {"state": "empty"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_empty_fuse_consumer", "power_socket", "power_debug_graph_empty_fuse", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_cut_cable_source", "power_source", "power_debug_graph_cut_cable", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_cut_cable_gate", "power_cable", "power_debug_graph_cut_cable", {"state": "cut"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_cut_cable_consumer", "power_socket", "power_debug_graph_cut_cable", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_no_source_source", "power_source", "power_debug_graph_no_source", {"is_powered": false, "state": "off"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_no_source_consumer", "power_socket", "power_debug_graph_no_source", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_damaged_consumer_source", "power_source", "power_debug_graph_damaged_consumer", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_damaged_consumer", "power_socket", "power_debug_graph_damaged_consumer", {"is_powered": false, "state": "damaged"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_powered_source", "power_source", "power_debug_terminal_powered", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_powered_switch", "circuit_switch", "power_debug_terminal_powered", {"state": "switch_on"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_powered_terminal", "information_terminal", "power_debug_terminal_powered", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_blocked_source", "power_source", "power_debug_terminal_blocked", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_blocked_switch", "circuit_switch", "power_debug_terminal_blocked", {"state": "switch_off"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_blocked_terminal", "information_terminal", "power_debug_terminal_blocked", {"is_powered": true, "state": "active"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_damaged_source", "power_source", "power_debug_terminal_damaged", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_damaged_terminal", "information_terminal", "power_debug_terminal_damaged", {"is_powered": false, "state": "damaged"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_energy_door_blocked_source", "power_source", "power_debug_energy_door_blocked", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_energy_door_blocked_switch", "circuit_switch", "power_debug_energy_door_blocked", {"state": "switch_off"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_energy_door_blocked_door", "energy_door", "power_debug_energy_door_blocked", {"is_powered": true, "state": "closed"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_energy_door_powered_source", "power_source", "power_debug_energy_door_powered", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_energy_door_powered_switch", "circuit_switch", "power_debug_energy_door_powered", {"state": "switch_on"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_energy_door_powered_door", "energy_door", "power_debug_energy_door_powered", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_blocked_source", "power_source", "power_debug_platform_blocked", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_blocked_switch", "circuit_switch", "power_debug_platform_blocked", {"state": "switch_off"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_blocked_platform", "lifting_platform", "power_debug_platform_blocked", {"is_powered": true, "state": "active", "height_level": 1}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_powered_source", "power_source", "power_debug_platform_powered", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_powered_switch", "circuit_switch", "power_debug_platform_powered", {"state": "switch_on"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_powered_platform", "lifting_platform", "power_debug_platform_powered", {"is_powered": false, "state": "unpowered", "height_level": 1}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_damaged_source", "power_source", "power_debug_platform_damaged", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_damaged_switch", "circuit_switch", "power_debug_platform_damaged", {"state": "switch_off"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_damaged_platform", "lifting_platform", "power_debug_platform_damaged", {"is_powered": true, "state": "damaged", "height_level": 2, "damaged": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_load_ok", "power_source_class_2", "power_debug_source_load_ok", {"is_powered": true, "state": "active", "source_capacity": 2, "current_heat": 0, "overheat_threshold": 10}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_load_ok_terminal", "information_terminal", "power_debug_source_load_ok", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_load_ok_door", "energy_door", "power_debug_source_load_ok", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_fallback_class2_source", "power_source_class_2", "power_debug_source_fallback_class2", {"is_powered": true, "state": "active", "current_heat": 0, "overheat_threshold": 10}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_fallback_class2_terminal_a", "information_terminal", "power_debug_source_fallback_class2", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_fallback_class2_terminal_b", "information_terminal", "power_debug_source_fallback_class2", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_fallback_class3_source", "power_source_class_3", "power_debug_source_fallback_class3", {"is_powered": true, "state": "active", "current_heat": 0, "overheat_threshold": 10}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_fallback_class3_terminal_a", "information_terminal", "power_debug_source_fallback_class3", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_fallback_class3_terminal_b", "information_terminal", "power_debug_source_fallback_class3", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_fallback_class3_terminal_c", "information_terminal", "power_debug_source_fallback_class3", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_overloaded_source", "power_source_class_1", "power_debug_source_overloaded", {"is_powered": true, "state": "active", "source_capacity": 1, "current_heat": 0, "overheat_threshold": 10}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_overloaded_terminal", "information_terminal", "power_debug_source_overloaded", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_overloaded_platform", "lifting_platform", "power_debug_source_overloaded", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_overheat_shutdown_source", "power_source_class_1", "power_debug_source_overheat_shutdown", {"is_powered": true, "state": "active", "source_capacity": 1, "current_heat": 0, "overheat_threshold": 2, "working_heat": 1}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_overheat_shutdown_terminal", "information_terminal", "power_debug_source_overheat_shutdown", {"is_powered": true, "state": "active"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_overheat_shutdown_platform", "lifting_platform", "power_debug_source_overheat_shutdown", {"is_powered": true, "state": "active"}))
	for object_data in temp_objects:
		mission_world_objects.append(object_data)
		var object_id := String(object_data.get("id", "")).strip_edges()
		if not object_id.is_empty():
			temp_ids[object_id] = true
	var validation := validate_power_network_runtime_state()
	var runtime_warnings: Array = validation.get("warnings", [])
	var runtime_errors: Array = validation.get("errors", [])
	var summary_text := get_power_network_debug_summary_text()
	if summary_text.find("network=power_debug_no_threshold") == -1:
		warnings.append("Expected debug network summary for power_debug_no_threshold.")
	if summary_text.find("network=power_debug_no_threshold") != -1 and summary_text.find("network=power_debug_no_threshold |") != -1:
		var no_threshold_summary := get_power_network_debug_summary_text("network=power_debug_no_threshold")
		if no_threshold_summary.find("overheated_sources=1") != -1:
			warnings.append("No-threshold source regression: power_debug_no_threshold incorrectly counted overheated source.")
	var no_threshold_warning := "Power source power_debug_source_no_threshold current_heat >= overheat_threshold but state is not overheated."
	if runtime_warnings.has(no_threshold_warning):
		warnings.append("No-threshold source regression: unexpected overheat threshold warning for power_debug_source_no_threshold.")
	var overheated_summary := get_power_network_debug_summary_text("network=power_debug_overheated")
	if overheated_summary.find("overheated_sources=1") == -1:
		warnings.append("Expected overheated source count for power_debug_overheated.")
	var order_missing_source_warning := "Power object power_debug_cable_before_source connected_power_source_id points to missing source power_debug_source_order."
	if runtime_warnings.has(order_missing_source_warning):
		warnings.append("Connected object before source produced false missing-source warning.")
	var true_missing_source_warning := "Power object power_debug_cable_missing_source connected_power_source_id points to missing source power_debug_source_missing."
	if not runtime_warnings.has(true_missing_source_warning):
		warnings.append("Missing-source warning not reported for power_debug_cable_missing_source.")
	var source_limit_warning := "Power source power_debug_source_limit connections (2) exceed allowed_connections (1)."
	if not runtime_warnings.has(source_limit_warning):
		warnings.append("Expected allowed_connections warning for power_debug_source_limit.")
	var generic_limit_warning := "Power source power_debug_source_generic_connected connections (1) exceed allowed_connections (0)."
	if runtime_warnings.has(generic_limit_warning):
		warnings.append("Generic connected object without connected_power_source_id incorrectly counted toward source limit.")
	var negative_heat_error := "Power object power_debug_negative_heat has negative current_heat (-1)."
	if not runtime_errors.has(negative_heat_error):
		warnings.append("Expected negative current_heat error for power_debug_negative_heat.")
	var preview_result := preview_power_network_state_application()
	var preview_changes: Array = preview_result.get("changes", [])
	var saw_power_up_change := false
	var saw_overheated_power_up_change := false
	var saw_damaged_consumer_change := false
	var saw_damaged_powered_change := false
	var damaged_powered_reason_ok := false
	for change_variant in preview_changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		var changed_id := String(change.get("object_id", ""))
		var preview_powered := bool(change.get("preview_is_powered", false))
		if changed_id == "power_debug_preview_cable" and preview_powered:
			saw_power_up_change = true
		if changed_id == "power_debug_preview_cable_overheated" and preview_powered:
			saw_overheated_power_up_change = true
		if changed_id == "power_debug_preview_consumer_damaged":
			saw_damaged_consumer_change = true
		if changed_id == "power_debug_preview_consumer_damaged_powered":
			saw_damaged_powered_change = true
			if not preview_powered and String(change.get("reason", "")) == "damaged":
				damaged_powered_reason_ok = true
	if not saw_power_up_change:
		warnings.append("Preview regression: powered source did not predict power-up for connected consumer.")
	if saw_overheated_power_up_change:
		warnings.append("Preview regression: overheated source incorrectly predicted consumer power-up.")
	if saw_damaged_consumer_change:
		warnings.append("Preview regression: damaged consumer should remain unpowered with no change entry.")
	if not saw_damaged_powered_change:
		warnings.append("Preview regression: powered damaged consumer did not emit power-down change.")
	elif not damaged_powered_reason_ok:
		warnings.append("Preview regression: powered damaged consumer change missing reason=damaged.")
	var preview_cable_object := get_world_object_by_id("power_debug_preview_cable")
	var preview_cable_before := bool(preview_cable_object.get("is_powered", false))
	preview_power_network_state_application()
	var preview_cable_after := bool(preview_cable_object.get("is_powered", false))
	if preview_cable_before != preview_cable_after:
		warnings.append("Preview mutated temporary object state for power_debug_preview_cable.")
	var apply_case_a_consumer := get_world_object_by_id("power_debug_apply_case_a_consumer")
	var apply_case_a_before_preview_report := bool(apply_case_a_consumer.get("is_powered", false))
	var apply_preview_report_text := get_power_network_apply_debug_preview_text("power_debug_apply_case_a")
	if apply_preview_report_text.find("WOULD_APPLY") == -1:
		warnings.append("Apply preview report regression: missing WOULD_APPLY entry for case A.")
	if apply_preview_report_text.find("APPLIED") != -1:
		warnings.append("Apply preview report regression: preview text must not include APPLIED entries.")
	var apply_case_a_after_preview_report := bool(apply_case_a_consumer.get("is_powered", false))
	if apply_case_a_before_preview_report != apply_case_a_after_preview_report:
		warnings.append("Apply preview report regression: report mutated apply_case_a_consumer before apply.")
	var apply_execute_report_text := execute_power_network_apply_debug_command("power_debug_apply_case_a")
	if apply_execute_report_text.find("PowerNetworkApply") == -1:
		warnings.append("Apply debug execute regression: missing PowerNetworkApply header for case A.")
	if apply_execute_report_text.find("APPLIED") == -1:
		warnings.append("Apply debug execute regression: missing APPLIED entry for case A.")
	if not bool(apply_case_a_consumer.get("is_powered", false)):
		warnings.append("Apply regression A: powered source did not power unpowered consumer.")
	if apply_execute_report_text.find("object=power_debug_apply_case_a_consumer") == -1:
		warnings.append("Apply debug execute regression: report missing applied consumer power-up.")
	var apply_case_b_consumer := get_world_object_by_id("power_debug_apply_case_b_consumer")
	var apply_case_b_before := bool(apply_case_b_consumer.get("is_powered", false))
	var apply_result_b := apply_power_network_state_from_preview("power_debug_apply_case_b")
	var apply_case_b_after := bool(apply_case_b_consumer.get("is_powered", false))
	if apply_case_b_before != apply_case_b_after or apply_case_b_after:
		warnings.append("Apply regression B: consumer power changed with overheated source.")
	for change_variant in apply_result_b.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if String(change.get("object_id", "")) == "power_debug_apply_case_b_consumer" and bool(change.get("new_is_powered", false)):
			warnings.append("Apply regression B: report included invalid consumer power-up.")
			break
	var apply_case_c_consumer := get_world_object_by_id("power_debug_apply_case_c_consumer")
	var apply_result_c := apply_power_network_state_from_preview("power_debug_apply_case_c")
	if bool(apply_case_c_consumer.get("is_powered", false)):
		warnings.append("Apply regression C: damaged consumer remained powered.")
	var apply_case_c_reason_ok := false
	for change_variant in apply_result_c.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if String(change.get("object_id", "")) != "power_debug_apply_case_c_consumer":
			continue
		if not bool(change.get("new_is_powered", false)) and String(change.get("reason", "")) == "damaged":
			apply_case_c_reason_ok = true
			break
	if not apply_case_c_reason_ok:
		warnings.append("Apply regression C: damaged consumer power-down missing reason=damaged.")
	var apply_case_d_source_on := get_world_object_by_id("power_debug_apply_case_d_source_on")
	var apply_case_d_source_off := get_world_object_by_id("power_debug_apply_case_d_source_off")
	var source_on_before := bool(apply_case_d_source_on.get("is_powered", false))
	var source_off_before := bool(apply_case_d_source_off.get("is_powered", false))
	apply_power_network_state_from_preview("power_debug_apply_case_d")
	var source_on_after := bool(apply_case_d_source_on.get("is_powered", false))
	var source_off_after := bool(apply_case_d_source_off.get("is_powered", false))
	if source_on_before != source_on_after or source_off_before != source_off_after:
		warnings.append("Apply regression D: source object is_powered mutated by apply.")
	var event_apply_consumer := get_world_object_by_id("power_debug_event_apply_consumer")
	var event_preview_before := bool(event_apply_consumer.get("is_powered", false))
	var event_preview_text := get_power_event_apply_preview_text("debug_event", "power_debug_event_apply")
	if event_preview_text.find("PowerEventApplyPreview") == -1:
		warnings.append("Event apply preview regression: missing PowerEventApplyPreview header.")
	if event_preview_text.find("WOULD_APPLY") == -1:
		warnings.append("Event apply preview regression: missing WOULD_APPLY entry.")
	if event_preview_text.find("APPLIED") != -1:
		warnings.append("Event apply preview regression: preview text must not include APPLIED entries.")
	var event_preview_after := bool(event_apply_consumer.get("is_powered", false))
	if event_preview_before != event_preview_after:
		warnings.append("Event apply preview regression: preview mutated consumer state.")
	var event_execute_text := execute_power_event_apply_and_get_report_text("debug_event", "power_debug_event_apply")
	if event_execute_text.find("PowerEventApply") == -1:
		warnings.append("Event apply execute regression: missing PowerEventApply header.")
	if event_execute_text.find("reason=debug_event") == -1:
		warnings.append("Event apply execute regression: missing reason=debug_event in header.")
	if event_execute_text.find("APPLIED") == -1:
		warnings.append("Event apply execute regression: missing APPLIED entry.")
	if not bool(event_apply_consumer.get("is_powered", false)):
		warnings.append("Event apply execute regression: consumer did not become powered.")
	var event_dict_report := apply_power_network_after_explicit_power_event("debug_event_dict", "power_debug_event_apply")
	if int(event_dict_report.get("applied", -1)) != 0:
		warnings.append("Event apply dictionary regression: expected applied=0 after execute.")
	if String(event_dict_report.get("event_reason", "")) != "debug_event_dict":
		warnings.append("Event apply dictionary regression: event_reason mismatch.")
	var switch_toggle_consumer := get_world_object_by_id("power_debug_switch_toggle_consumer")
	var switch_toggle_before := bool(switch_toggle_consumer.get("is_powered", false))
	debug_switch_object["state"] = "switch_on"
	var switch_filter := _get_power_event_filter_for_object(debug_switch_object)
	if switch_filter != "power_debug_switch_toggle":
		warnings.append("Power event filter helper regression: expected power_debug_switch_toggle for switch object.")
	var switch_toggle_report := apply_power_network_after_explicit_power_event("switch_toggled", switch_filter)
	if String(switch_toggle_report.get("event_reason", "")) != "switch_toggled":
		warnings.append("Switch toggle event apply regression: event_reason mismatch.")
	if not bool(switch_toggle_consumer.get("is_powered", false)):
		warnings.append("Switch toggle event apply regression: consumer did not become powered.")
	if switch_toggle_before == bool(switch_toggle_consumer.get("is_powered", false)):
		warnings.append("Switch toggle event apply regression: consumer power state did not change.")
	var fuse_consumer := get_world_object_by_id("power_debug_fuse_consumer")
	var fuse_filter := _get_power_event_filter_for_object(debug_fuse_object)
	if fuse_filter != "power_debug_fuse_event":
		warnings.append("Power event filter helper regression: expected power_debug_fuse_event for fuse object.")
	debug_fuse_object["state"] = "installed"
	var fuse_insert_report := apply_power_network_after_explicit_power_event("fuse_inserted", fuse_filter)
	if String(fuse_insert_report.get("event_reason", "")) != "fuse_inserted":
		warnings.append("Fuse insert event apply regression: event_reason mismatch.")
	if not bool(fuse_consumer.get("is_powered", false)):
		warnings.append("Fuse insert event apply regression: consumer did not become powered.")
	fuse_consumer["is_powered"] = true
	debug_fuse_object["state"] = "empty"
	var fuse_remove_report := apply_power_network_after_explicit_power_event("fuse_removed", fuse_filter)
	if String(fuse_remove_report.get("event_reason", "")) != "fuse_removed":
		warnings.append("Fuse remove event apply regression: event_reason mismatch.")
	var debug_cable_consumer := get_world_object_by_id("power_debug_cable_consumer")
	debug_cable_object["state"] = "connected"
	debug_cable_object["connected"] = true
	var cable_filter := _get_power_event_filter_for_object(debug_cable_object)
	if cable_filter != "power_debug_cable_event":
		warnings.append("Power event filter helper regression: expected power_debug_cable_event for cable object.")
	var cable_connect_report := apply_power_network_after_explicit_power_event("cable_connected", cable_filter)
	if String(cable_connect_report.get("event_reason", "")) != "cable_connected":
		warnings.append("Cable connect event apply regression: event_reason mismatch.")
	if not bool(debug_cable_consumer.get("is_powered", false)):
		warnings.append("Cable connect event apply regression: consumer did not become powered.")
	debug_cable_consumer["is_powered"] = true
	debug_cable_object["state"] = "disconnected"
	debug_cable_object["connected"] = false
	var cable_disconnect_report := apply_power_network_after_explicit_power_event("cable_disconnected", cable_filter)
	if String(cable_disconnect_report.get("event_reason", "")) != "cable_disconnected":
		warnings.append("Cable disconnect event apply regression: event_reason mismatch.")
	var graph_closed_source := get_world_object_by_id("power_debug_graph_closed_gate_source")
	var graph_closed_gate := get_world_object_by_id("power_debug_graph_closed_gate_switch")
	var graph_closed_consumer := get_world_object_by_id("power_debug_graph_closed_gate_consumer")
	var graph_closed_source_before_preview := bool(graph_closed_source.get("is_powered", false))
	var graph_closed_gate_state_before_preview := String(graph_closed_gate.get("state", ""))
	var graph_closed_gate_power_before_preview := bool(graph_closed_gate.get("is_powered", false))
	var graph_closed_consumer_before_preview := bool(graph_closed_consumer.get("is_powered", false))
	var graph_closed_preview := preview_power_graph_state_application("power_debug_graph_closed_gate")
	var graph_closed_preview_changes: Array = graph_closed_preview.get("changes", [])
	var graph_closed_preview_reason_ok := false
	for change_variant in graph_closed_preview_changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if String(change.get("object_id", "")) == "power_debug_graph_closed_gate_consumer" and String(change.get("reason", "")) == "graph_powered_source_reachable":
			graph_closed_preview_reason_ok = true
			break
	if not graph_closed_preview_reason_ok:
		warnings.append("Graph closed gate scenario regression: expected reason=graph_powered_source_reachable.")
	if graph_closed_source_before_preview != bool(graph_closed_source.get("is_powered", false)) or graph_closed_consumer_before_preview != bool(graph_closed_consumer.get("is_powered", false)) or graph_closed_gate_state_before_preview != String(graph_closed_gate.get("state", "")) or graph_closed_gate_power_before_preview != bool(graph_closed_gate.get("is_powered", false)):
		warnings.append("Graph preview regression: preview mutated closed-gate objects.")
	var graph_closed_apply := apply_power_graph_state_from_preview("power_debug_graph_closed_gate")
	if int(graph_closed_apply.get("applied", 0)) <= 0:
		warnings.append("Graph closed gate scenario regression: expected apply changes.")
	if not bool(graph_closed_consumer.get("is_powered", false)):
		warnings.append("Graph closed gate scenario regression: consumer did not become powered.")
	if not bool(graph_closed_source.get("is_powered", false)):
		warnings.append("Graph closed gate scenario regression: source mutated from powered state.")
	for change_variant in graph_closed_apply.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if String(change.get("object_id", "")) == "power_debug_graph_closed_gate_source":
			warnings.append("Graph apply regression: source object appeared in applied changes.")
			break
	var graph_open_source := get_world_object_by_id("power_debug_graph_open_switch_source")
	var graph_open_gate := get_world_object_by_id("power_debug_graph_open_switch_gate")
	var graph_open_consumer := get_world_object_by_id("power_debug_graph_open_switch_consumer")
	var graph_open_source_before_preview := bool(graph_open_source.get("is_powered", false))
	var graph_open_gate_state_before_preview := String(graph_open_gate.get("state", ""))
	var graph_open_gate_power_before_preview := bool(graph_open_gate.get("is_powered", false))
	var graph_open_consumer_before_preview := bool(graph_open_consumer.get("is_powered", false))
	var graph_open_preview := preview_power_graph_state_application("power_debug_graph_open_switch")
	if String(get_power_graph_preview_text("power_debug_graph_open_switch")).find("blocked=1") == -1:
		warnings.append("Graph open switch scenario regression: blocked gate not reported.")
	if str(graph_open_preview).find("blocked_by_gate") == -1:
		warnings.append("Graph open switch scenario regression: reason blocked_by_gate missing.")
	if graph_open_source_before_preview != bool(graph_open_source.get("is_powered", false)) or graph_open_consumer_before_preview != bool(graph_open_consumer.get("is_powered", false)) or graph_open_gate_state_before_preview != String(graph_open_gate.get("state", "")) or graph_open_gate_power_before_preview != bool(graph_open_gate.get("is_powered", false)):
		warnings.append("Graph preview regression: preview mutated open-gate objects.")
	var graph_open_blocked_ok := false
	for blocked_variant in graph_open_preview.get("blocked", []):
		if typeof(blocked_variant) != TYPE_DICTIONARY:
			continue
		var blocked: Dictionary = blocked_variant
		if String(blocked.get("object_id", "")) == "power_debug_graph_open_switch_gate":
			graph_open_blocked_ok = true
			break
	if not graph_open_blocked_ok:
		warnings.append("Graph open switch scenario regression: blocked entry missing switch gate.")
	var graph_open_apply := apply_power_graph_state_from_preview("power_debug_graph_open_switch")
	if bool(graph_open_consumer.get("is_powered", false)):
		warnings.append("Graph open switch scenario regression: consumer should be unpowered.")
	if not bool(graph_open_source.get("is_powered", false)):
		warnings.append("Graph open switch scenario regression: source mutated from powered state.")
	var graph_open_reason_ok := false
	for change_variant in graph_open_apply.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if String(change.get("object_id", "")) == "power_debug_graph_open_switch_consumer":
			if String(change.get("reason", "")) == "blocked_by_gate":
				graph_open_reason_ok = true
		elif String(change.get("object_id", "")) == "power_debug_graph_open_switch_source":
			warnings.append("Graph apply regression: source object appeared in open-switch changes.")
	if not graph_open_reason_ok:
		warnings.append("Graph open switch scenario regression: missing reason=blocked_by_gate.")
	var graph_empty_fuse_source := get_world_object_by_id("power_debug_graph_empty_fuse_source")
	var graph_empty_fuse_consumer := get_world_object_by_id("power_debug_graph_empty_fuse_consumer")
	var graph_empty_fuse_preview := preview_power_graph_state_application("power_debug_graph_empty_fuse")
	var graph_empty_fuse_blocked_ok := false
	for blocked_variant in graph_empty_fuse_preview.get("blocked", []):
		if typeof(blocked_variant) != TYPE_DICTIONARY:
			continue
		var blocked: Dictionary = blocked_variant
		if String(blocked.get("object_id", "")) == "power_debug_graph_empty_fuse_gate":
			graph_empty_fuse_blocked_ok = true
			break
	if not graph_empty_fuse_blocked_ok:
		warnings.append("Graph empty fuse scenario regression: blocked entry missing fuse gate.")
	var graph_empty_fuse_apply := apply_power_graph_state_from_preview("power_debug_graph_empty_fuse")
	if bool(graph_empty_fuse_consumer.get("is_powered", false)):
		warnings.append("Graph empty fuse scenario regression: consumer should be unpowered.")
	if not bool(graph_empty_fuse_source.get("is_powered", false)):
		warnings.append("Graph empty fuse scenario regression: source mutated from powered state.")
	var graph_empty_fuse_reason_ok := false
	for change_variant in graph_empty_fuse_apply.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if String(change.get("object_id", "")) == "power_debug_graph_empty_fuse_consumer" and String(change.get("reason", "")) == "blocked_by_gate":
			graph_empty_fuse_reason_ok = true
		elif String(change.get("object_id", "")) == "power_debug_graph_empty_fuse_source":
			warnings.append("Graph apply regression: source object appeared in empty-fuse changes.")
	if not graph_empty_fuse_reason_ok:
		warnings.append("Graph empty fuse scenario regression: missing reason=blocked_by_gate.")
	var graph_cut_cable_source := get_world_object_by_id("power_debug_graph_cut_cable_source")
	var graph_cut_cable_consumer := get_world_object_by_id("power_debug_graph_cut_cable_consumer")
	var graph_cut_cable_preview := preview_power_graph_state_application("power_debug_graph_cut_cable")
	var graph_cut_cable_blocked_ok := false
	for blocked_variant in graph_cut_cable_preview.get("blocked", []):
		if typeof(blocked_variant) != TYPE_DICTIONARY:
			continue
		var blocked: Dictionary = blocked_variant
		if String(blocked.get("object_id", "")) == "power_debug_graph_cut_cable_gate":
			graph_cut_cable_blocked_ok = true
			break
	if not graph_cut_cable_blocked_ok:
		warnings.append("Graph cut cable scenario regression: blocked entry missing cable gate.")
	var graph_cut_cable_apply := apply_power_graph_state_from_preview("power_debug_graph_cut_cable")
	if bool(graph_cut_cable_consumer.get("is_powered", false)):
		warnings.append("Graph cut cable scenario regression: consumer should be unpowered.")
	if not bool(graph_cut_cable_source.get("is_powered", false)):
		warnings.append("Graph cut cable scenario regression: source mutated from powered state.")
	var graph_cut_cable_reason_ok := false
	for change_variant in graph_cut_cable_apply.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if String(change.get("object_id", "")) == "power_debug_graph_cut_cable_consumer":
			var change_reason := String(change.get("reason", ""))
			if change_reason == "blocked_by_gate" or change_reason == "cut":
				graph_cut_cable_reason_ok = true
		elif String(change.get("object_id", "")) == "power_debug_graph_cut_cable_source":
			warnings.append("Graph apply regression: source object appeared in cut-cable changes.")
	if not graph_cut_cable_reason_ok:
		warnings.append("Graph cut cable scenario regression: missing reason=blocked_by_gate/cut.")
	var graph_no_source_consumer := get_world_object_by_id("power_debug_graph_no_source_consumer")
	var graph_no_source_apply := apply_power_graph_state_from_preview("power_debug_graph_no_source")
	if bool(graph_no_source_consumer.get("is_powered", false)):
		warnings.append("Graph no source scenario regression: consumer should be unpowered.")
	var graph_no_source_reason_ok := false
	for change_variant in graph_no_source_apply.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if String(change.get("object_id", "")) == "power_debug_graph_no_source_consumer" and String(change.get("reason", "")) == "no_powered_source":
			graph_no_source_reason_ok = true
			break
	if not graph_no_source_reason_ok:
		warnings.append("Graph no source scenario regression: missing reason=no_powered_source.")
	var graph_damaged_consumer := get_world_object_by_id("power_debug_graph_damaged_consumer")
	var graph_damaged_preview := preview_power_graph_state_application("power_debug_graph_damaged_consumer")
	var graph_damaged_apply := apply_power_graph_state_from_preview("power_debug_graph_damaged_consumer")
	if bool(graph_damaged_consumer.get("is_powered", false)):
		warnings.append("Graph damaged consumer scenario regression: damaged consumer became powered.")
	for change_variant in graph_damaged_apply.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if String(change.get("object_id", "")) == "power_debug_graph_damaged_consumer_source":
			warnings.append("Graph apply regression: source object appeared in damaged-consumer changes.")
	for change_variant in graph_damaged_preview.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if String(change.get("object_id", "")) == "power_debug_graph_damaged_consumer" and String(change.get("reason", "")) != "damaged":
			warnings.append("Graph damaged consumer scenario regression: expected reason=damaged for preview change.")
	var terminal_powered := get_world_object_by_id("power_debug_terminal_powered_terminal")
	apply_power_graph_state_from_preview("power_debug_terminal_powered")
	if not bool(terminal_powered.get("is_powered", false)) or String(terminal_powered.get("state", "")) != "active":
		warnings.append("Terminal powered restore regression: terminal did not restore active powered state.")
	var terminal_blocked := get_world_object_by_id("power_debug_terminal_blocked_terminal")
	apply_power_graph_state_from_preview("power_debug_terminal_blocked")
	if bool(terminal_blocked.get("is_powered", true)) or String(terminal_blocked.get("state", "")) != "unpowered":
		warnings.append("Terminal blocked regression: terminal should become unpowered.")
	var terminal_damaged := get_world_object_by_id("power_debug_terminal_damaged_terminal")
	apply_power_graph_state_from_preview("power_debug_terminal_damaged")
	if String(terminal_damaged.get("state", "")) != "damaged" or _is_terminal_powered_for_interaction(terminal_damaged):
		warnings.append("Terminal damaged regression: damaged terminal must remain non-interactable.")
	var terminal_legacy := {"object_type": "terminal", "state": "active"}
	if not _is_terminal_powered_for_interaction(terminal_legacy):
		warnings.append("Terminal legacy default regression: missing is_powered must remain interactable.")
	var terminal_explicit_unpowered := {"object_type": "terminal", "state": "active", "is_powered": false}
	if _is_terminal_powered_for_interaction(terminal_explicit_unpowered):
		warnings.append("Terminal explicit unpowered regression: is_powered=false must block interaction.")
	var energy_door_blocked := get_world_object_by_id("power_debug_energy_door_blocked_door")
	apply_power_graph_state_from_preview("power_debug_energy_door_blocked")
	if bool(energy_door_blocked.get("is_powered", true)) or not String(energy_door_blocked.get("state", "")) in ["unpowered", "disabled"]:
		warnings.append("Energy door blocked regression: powered barrier did not disable when unpowered.")
	var energy_door_powered := get_world_object_by_id("power_debug_energy_door_powered_door")
	apply_power_graph_state_from_preview("power_debug_energy_door_powered")
	if not bool(energy_door_powered.get("is_powered", false)) or not String(energy_door_powered.get("state", "")) in ["closed", "active", "powered"]:
		warnings.append("Energy door powered regression: barrier did not restore.")
	var platform_blocked := get_world_object_by_id("power_debug_platform_blocked_platform")
	var platform_blocked_height_before := int(platform_blocked.get("height_level", 0))
	apply_power_graph_state_from_preview("power_debug_platform_blocked")
	if bool(platform_blocked.get("is_powered", true)) or not String(platform_blocked.get("state", "")) in ["unpowered", "disabled"] or int(platform_blocked.get("height_level", 0)) != platform_blocked_height_before:
		warnings.append("Platform blocked regression: platform power-off should disable without movement.")
	var platform_powered := get_world_object_by_id("power_debug_platform_powered_platform")
	var platform_powered_height_before := int(platform_powered.get("height_level", 0))
	apply_power_graph_state_from_preview("power_debug_platform_powered")
	if not bool(platform_powered.get("is_powered", false)) or not String(platform_powered.get("state", "")) in ["active", "idle"] or int(platform_powered.get("height_level", 0)) != platform_powered_height_before:
		warnings.append("Platform powered regression: platform should restore and not move.")
	var platform_damaged := get_world_object_by_id("power_debug_platform_damaged_platform")
	var platform_damaged_state_before := String(platform_damaged.get("state", ""))
	apply_power_graph_state_from_preview("power_debug_platform_damaged")
	if String(platform_damaged.get("state", "")) != platform_damaged_state_before or String(platform_damaged.get("state", "")) == "unpowered" or String(platform_damaged.get("state", "")) == "active":
		warnings.append("Platform damaged regression: damaged platform state must be preserved when unpowered.")
	var platform_damaged_switch := get_world_object_by_id("power_debug_platform_damaged_switch")
	platform_damaged_switch["state"] = "switch_on"
	apply_power_graph_state_from_preview("power_debug_platform_damaged")
	if String(platform_damaged.get("state", "")) != platform_damaged_state_before:
		warnings.append("Platform damaged restore regression: power restore must not heal damaged platform.")
	var graph_filter_source := get_world_object_by_id("power_debug_graph_open_switch_source")
	var graph_filter_gate := get_world_object_by_id("power_debug_graph_open_switch_gate")
	var graph_filter_consumer := get_world_object_by_id("power_debug_graph_open_switch_consumer")
	var graph_filter_source_before_preview := bool(graph_filter_source.get("is_powered", false))
	var graph_filter_gate_state_before_preview := String(graph_filter_gate.get("state", ""))
	var graph_filter_gate_power_before_preview := bool(graph_filter_gate.get("is_powered", false))
	var graph_filter_consumer_before_preview := bool(graph_filter_consumer.get("is_powered", false))
	var graph_filter_object_preview := preview_power_graph_state_application("power_debug_graph_open_switch_gate")
	if int((graph_filter_object_preview.get("sources", []) as Array).size()) != 1:
		warnings.append("Graph filter fallback regression: object-id filter did not resolve to network.")
	if graph_filter_source_before_preview != bool(graph_filter_source.get("is_powered", false)) or graph_filter_consumer_before_preview != bool(graph_filter_consumer.get("is_powered", false)) or graph_filter_gate_state_before_preview != String(graph_filter_gate.get("state", "")) or graph_filter_gate_power_before_preview != bool(graph_filter_gate.get("is_powered", false)):
		warnings.append("Graph preview regression: object-id filter preview mutated open-switch objects.")
	var load_ok_source := get_world_object_by_id("power_debug_source_load_ok")
	var _load_ok_preview := preview_power_graph_state_application("power_debug_source_load_ok")
	if int(load_ok_source.get("source_load", -1)) != -1:
		warnings.append("Source load preview regression: preview mutated source load fields.")
	var load_ok_apply := apply_power_graph_state_from_preview("power_debug_source_load_ok")
	if int(load_ok_source.get("source_load", -1)) != 2 or int(load_ok_source.get("source_capacity", -1)) != 2 or bool(load_ok_source.get("source_overloaded", true)):
		warnings.append("Source load scenario A regression: expected load=2 capacity=2 overloaded=false.")
	if String(load_ok_source.get("state", "")).to_lower() == "overheated":
		warnings.append("Source load scenario A regression: source should not overheat.")
	if int(load_ok_apply.get("applied", 0)) < 2:
		warnings.append("Source load scenario A regression: expected consumers to be powered.")
	var fallback_class2_source := get_world_object_by_id("power_debug_source_fallback_class2_source")
	var fallback_class2_preview := preview_power_graph_state_application("power_debug_source_fallback_class2")
	if int(fallback_class2_source.get("source_capacity", -1)) != -1:
		warnings.append("Source fallback class2 preview regression: preview mutated source capacity fields.")
	var fallback_class2_preview_sources: Array = fallback_class2_preview.get("source_load_report", {}).get("sources", [])
	var fallback_class2_preview_capacity_ok := false
	for source_variant in fallback_class2_preview_sources:
		if typeof(source_variant) != TYPE_DICTIONARY:
			continue
		var source_entry: Dictionary = source_variant
		if String(source_entry.get("object_id", "")) == "power_debug_source_fallback_class2_source" and int(source_entry.get("source_capacity", -1)) == 2:
			fallback_class2_preview_capacity_ok = true
			break
	if not fallback_class2_preview_capacity_ok:
		warnings.append("Source fallback class2 preview regression: expected source_capacity=2 from object_type fallback.")
	apply_power_graph_state_from_preview("power_debug_source_fallback_class2")
	if int(fallback_class2_source.get("source_capacity", -1)) != 2:
		warnings.append("Source fallback class2 apply regression: expected source_capacity=2.")
	var fallback_class3_source := get_world_object_by_id("power_debug_source_fallback_class3_source")
	var fallback_class3_preview := preview_power_graph_state_application("power_debug_source_fallback_class3")
	if int(fallback_class3_source.get("source_capacity", -1)) != -1:
		warnings.append("Source fallback class3 preview regression: preview mutated source capacity fields.")
	var fallback_class3_preview_sources: Array = fallback_class3_preview.get("source_load_report", {}).get("sources", [])
	var fallback_class3_preview_capacity_ok := false
	for source_variant in fallback_class3_preview_sources:
		if typeof(source_variant) != TYPE_DICTIONARY:
			continue
		var source_entry: Dictionary = source_variant
		if String(source_entry.get("object_id", "")) == "power_debug_source_fallback_class3_source" and int(source_entry.get("source_capacity", -1)) == 3:
			fallback_class3_preview_capacity_ok = true
			break
	if not fallback_class3_preview_capacity_ok:
		warnings.append("Source fallback class3 preview regression: expected source_capacity=3 from object_type fallback.")
	apply_power_graph_state_from_preview("power_debug_source_fallback_class3")
	if int(fallback_class3_source.get("source_capacity", -1)) != 3:
		warnings.append("Source fallback class3 apply regression: expected source_capacity=3.")
	var overloaded_source := get_world_object_by_id("power_debug_source_overloaded_source")
	apply_power_graph_state_from_preview("power_debug_source_overloaded")
	if int(overloaded_source.get("source_load", 0)) <= int(overloaded_source.get("source_capacity", 0)) or not bool(overloaded_source.get("source_overloaded", false)) or int(overloaded_source.get("heat_from_connections", 0)) <= 0:
		warnings.append("Source load scenario B regression: expected overloaded source with heat_from_connections.")
	var overheat_source := get_world_object_by_id("power_debug_source_overheat_shutdown_source")
	var overheat_terminal := get_world_object_by_id("power_debug_source_overheat_shutdown_terminal")
	var overheat_platform := get_world_object_by_id("power_debug_source_overheat_shutdown_platform")
	var overheat_preview_before := preview_power_graph_state_application("power_debug_source_overheat_shutdown")
	if str(overheat_preview_before).find("source_load_report") == -1 and int((overheat_preview_before.get("source_load_report", {}).get("updated", 0))) <= 0:
		warnings.append("Source load preview regression: missing source_load_report in graph preview.")
	if int(overheat_source.get("source_load", -1)) != -1:
		warnings.append("Source load preview regression: source overheat preview mutated source fields.")
	var overheat_apply := apply_power_graph_state_from_preview("power_debug_source_overheat_shutdown")
	if String(overheat_source.get("state", "")).to_lower() != "overheated":
		warnings.append("Source load scenario C regression: source did not overheat.")
	if bool(overheat_terminal.get("is_powered", true)) or bool(overheat_platform.get("is_powered", true)):
		warnings.append("Source load scenario C regression: dependent consumers should be unpowered.")
	for change_variant in overheat_apply.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if String(change.get("object_id", "")) == "power_debug_source_overheat_shutdown_source":
			warnings.append("Source load scenario C regression: source appeared in applied changes.")
			break
	var allowed_fuse_remove_fields := {
		"is_powered": true,
		"current_heat": true,
		"working_heat": true,
		"cooling_received": true,
		"heat_from_connections": true,
		"state": true
	}
	for change_variant in fuse_remove_report.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		for key_variant in change.keys():
			var key := String(key_variant)
			if not allowed_fuse_remove_fields.has(key):
				warnings.append("Fuse remove event apply regression: unexpected change field %s." % key)
				break
	var index := mission_world_objects.size() - 1
	while index >= 0:
		var object_data: Dictionary = mission_world_objects[index]
		var object_id := String(object_data.get("id", "")).strip_edges()
		if temp_ids.has(object_id):
			mission_world_objects.remove_at(index)
		index -= 1
	for object_data in mission_world_objects:
		var object_id := String(object_data.get("id", "")).strip_edges()
		if temp_ids.has(object_id):
			warnings.append("Temporary debug power object remained after cleanup: %s." % object_id)
	if mission_world_objects.size() != base_size:
		warnings.append("Mission world object count changed after debug scenario cleanup (expected %d, got %d)." % [base_size, mission_world_objects.size()])
	if mission_world_objects.size() == unchanged_snapshot.size():
		for i in range(mission_world_objects.size()):
			if mission_world_objects[i] != unchanged_snapshot[i]:
				warnings.append("Mission world object at index %d changed during debug scenario." % i)
				break
	return warnings

func get_power_network_debug_validation_text() -> String:
	var warnings := validate_power_network_debug_scenario()
	var lines: Array[String] = []
	lines.append("PowerNetworkDebugScenario: warnings=%d" % warnings.size())
	for warning in warnings:
		lines.append("WARNING: %s" % warning)
	return "\n".join(lines)



func get_power_network_full_debug_report_text(filter: String = "") -> String:
	var preview := preview_power_graph_state_application(filter)
	var lines: Array[String] = []
	lines.append("PowerNetworkFullDebug: filter=%s resolved_filter=%s" % [filter.strip_edges(), String(preview.get("resolved_filter", ""))])
	lines.append("Sources:")
	for source_variant in preview.get("source_load_report", {}).get("sources", []):
		if typeof(source_variant) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = source_variant
		var obj := get_world_object_by_id(String(source.get("object_id", "")))
		lines.append("- %s state=%s available=%s load=%d/%d heat=%d/%d overloaded=%s" % [String(source.get("object_id", "")), String(source.get("state", obj.get("state", ""))), str(_is_power_source_available(obj)).to_lower(), int(source.get("source_load", 0)), int(source.get("source_capacity", 0)), int(source.get("current_heat", 0)), int(source.get("overheat_threshold", 0)), str(bool(source.get("source_overloaded", false))).to_lower()])
	lines.append("Gates:")
	for object_data in mission_world_objects:
		if not _is_power_network_object(object_data):
			continue
		if not _resolve_power_graph_filter_to_network_id(filter).is_empty() and _get_power_network_id(object_data) != _resolve_power_graph_filter_to_network_id(filter):
			continue
		var gate := _get_power_gate_state(object_data)
		if not bool(gate.get("is_gate", false)):
			continue
		lines.append("- %s type=%s state=%s closed=%s reason=%s" % [String(object_data.get("id", "")), String(gate.get("gate_type", "")), String(object_data.get("state", "")), str(bool(gate.get("is_closed", true))).to_lower(), String(gate.get("reason", ""))])
	lines.append("Consumers:")
	for object_data in mission_world_objects:
		if _is_power_source_object(object_data) or not _is_power_network_object(object_data):
			continue
		if not _resolve_power_graph_filter_to_network_id(filter).is_empty() and _get_power_network_id(object_data) != _resolve_power_graph_filter_to_network_id(filter):
			continue
		lines.append("- %s type=%s powered=%s state=%s reason=%s" % [String(object_data.get("id", "")), String(object_data.get("object_type", "")), str(bool(object_data.get("is_powered", false))).to_lower(), String(object_data.get("state", "")), String(object_data.get("power_unavailable_reason", ""))])
	lines.append("Blocked:")
	for b in preview.get("blocked", []):
		lines.append("- %s" % str(b))
	lines.append("Preview changes:")
	for c in preview.get("changes", []):
		lines.append("- %s" % str(c))
	lines.append("Source load preview:")
	lines.append(str(preview.get("source_load_report", {})))
	lines.append("Warnings:")
	for w in preview.get("warnings", []):
		lines.append("- %s" % String(w))
	return "\n".join(lines)

func validate_full_power_system_runtime() -> Array[String]:
	var warnings := validate_power_network_debug_scenario()
	var runtime_validation := validate_power_network_runtime_state()
	for warning in runtime_validation.get("warnings", []):
		warnings.append("runtime: %s" % String(warning))
	for err in runtime_validation.get("errors", []):
		warnings.append("runtime_error: %s" % String(err))
	var temp_objects: Array[Dictionary] = []
	var cleanup_ids: Array[String] = []
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_source", "power_source_class_1", "power_debug_source_recovery", {"state": "overheated", "is_powered": false, "overheated_state_before": "active", "current_heat": 4, "working_heat": 1, "heat_from_connections": 2, "cooling_received": 5, "overheat_threshold": 4}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_terminal", "information_terminal", "power_debug_source_recovery", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_door", "energy_door", "power_debug_source_recovery", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_platform", "lifting_platform", "power_debug_source_recovery", {"is_powered": false, "state": "unpowered", "height_level": 1}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_damaged_source", "power_source_class_1", "power_debug_source_recovery_damaged", {"state": "overheated", "is_powered": false, "overheated_state_before": "damaged", "current_heat": 4, "working_heat": 1, "cooling_received": 6, "overheat_threshold": 4}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_damaged_terminal", "information_terminal", "power_debug_source_recovery_damaged", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_broken_source", "power_source_class_1", "power_debug_source_recovery_broken", {"state": "overheated", "is_powered": false, "broken": true, "overheated_state_before": "active", "current_heat": 4, "working_heat": 1, "cooling_received": 6, "overheat_threshold": 4}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_broken_terminal", "information_terminal", "power_debug_source_recovery_broken", {"is_powered": false, "state": "unpowered"}))
	for object_data in temp_objects:
		mission_world_objects.append(object_data)
		cleanup_ids.append(String(object_data.get("id", "")))
	var recovery_a := execute_power_source_recovery_apply("power_debug_source_recovery")
	var source_a := get_world_object_by_id("power_debug_source_recovery_source")
	if String(source_a.get("state", "")).to_lower() != "active":
		warnings.append("power_debug_source_recovery: expected source state active after valid cooling recovery.")
	if not _is_power_source_available(source_a):
		warnings.append("power_debug_source_recovery: expected source available after valid cooling recovery.")
	var recovery_a_changes: Array = recovery_a.get("apply", {}).get("changes", [])
	for change_variant in recovery_a_changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		if String(Dictionary(change_variant).get("object_id", "")) == "power_debug_source_recovery_source":
			warnings.append("power_debug_source_recovery: source should not be included in consumer apply changes.")
			break
	for object_id in ["power_debug_source_recovery_terminal", "power_debug_source_recovery_door", "power_debug_source_recovery_platform"]:
		var consumer := get_world_object_by_id(object_id)
		if not bool(consumer.get("is_powered", false)):
			warnings.append("power_debug_source_recovery: expected %s to become powered after valid recovery." % object_id)
	var recovery_b := execute_power_source_recovery_apply("power_debug_source_recovery_damaged")
	var source_b := get_world_object_by_id("power_debug_source_recovery_damaged_source")
	if String(source_b.get("state", "")).to_lower() == "active":
		warnings.append("power_debug_source_recovery_damaged: source unexpectedly recovered to active from damaged pre-overheat state.")
	if _is_power_source_available(source_b):
		warnings.append("power_debug_source_recovery_damaged: expected source to remain unavailable.")
	if String(source_b.get("power_unavailable_reason", "")) != "source_damage_state":
		warnings.append("power_debug_source_recovery_damaged: expected power_unavailable_reason=source_damage_state.")
	if bool(get_world_object_by_id("power_debug_source_recovery_damaged_terminal").get("is_powered", false)):
		warnings.append("power_debug_source_recovery_damaged: consumer should remain unpowered.")
	if Array(recovery_b.get("recovery", {}).get("warnings", [])).is_empty():
		warnings.append("power_debug_source_recovery_damaged: expected recovery warning for blocked damaged restore.")
	var _recovery_c := execute_power_source_recovery_apply("power_debug_source_recovery_broken")
	var source_c := get_world_object_by_id("power_debug_source_recovery_broken_source")
	if String(source_c.get("state", "")).to_lower() == "active":
		warnings.append("power_debug_source_recovery_broken: source unexpectedly recovered while broken=true.")
	if bool(get_world_object_by_id("power_debug_source_recovery_broken_terminal").get("is_powered", false)):
		warnings.append("power_debug_source_recovery_broken: consumer should remain unpowered.")
	var report_snapshot := {}
	for object_id in ["power_debug_source_recovery_source", "power_debug_source_recovery_terminal", "power_debug_source_recovery_door", "power_debug_source_recovery_platform"]:
		var obj := get_world_object_by_id(object_id)
		report_snapshot[object_id] = {"state": String(obj.get("state", "")), "is_powered": bool(obj.get("is_powered", false)), "power_unavailable_reason": String(obj.get("power_unavailable_reason", "")), "connected": bool(obj.get("connected", false))}
	get_power_network_full_debug_report_text("power_debug_source_recovery")
	for object_id in report_snapshot.keys():
		var obj := get_world_object_by_id(String(object_id))
		var snap: Dictionary = report_snapshot[object_id]
		if String(obj.get("state", "")) != String(snap.get("state", "")) or bool(obj.get("is_powered", false)) != bool(snap.get("is_powered", false)) or String(obj.get("power_unavailable_reason", "")) != String(snap.get("power_unavailable_reason", "")) or bool(obj.get("connected", false)) != bool(snap.get("connected", false)):
			warnings.append("power_debug_source_recovery: full debug report mutated runtime state for %s." % String(object_id))
	var runtime_object := _build_power_network_debug_object("power_debug_runtime_save_fields", "information_terminal", "power_debug_runtime_save")
	runtime_object["state"] = "unpowered"
	runtime_object["is_powered"] = false
	runtime_object["current_heat"] = 3
	runtime_object["working_heat"] = 2
	runtime_object["cooling_received"] = 1
	runtime_object["heat_from_connections"] = 4
	runtime_object["overheat_threshold"] = 5
	runtime_object["source_load"] = 1
	runtime_object["source_capacity"] = 2
	runtime_object["source_overloaded"] = false
	runtime_object["power_unavailable_reason"] = "network_blocked"
	runtime_object["connected"] = true
	runtime_object["disconnected"] = false
	runtime_object["cut"] = false
	runtime_object["damaged"] = true
	runtime_object["broken"] = false
	runtime_object["destroyed"] = false
	runtime_object["state_before_unpowered"] = "active"
	runtime_object["powered_state_before_unpowered"] = "active"
	mission_world_objects.append(runtime_object)
	cleanup_ids.append("power_debug_runtime_save_fields")
	var runtime_snapshot := get_world_object_runtime_state()
	var saved_entry: Dictionary = runtime_snapshot.get("power_debug_runtime_save_fields", {})
	for field_name in ["state", "is_powered", "current_heat", "working_heat", "cooling_received", "heat_from_connections", "overheat_threshold", "source_load", "source_capacity", "source_overloaded", "power_unavailable_reason", "connected", "disconnected", "cut", "damaged", "broken", "destroyed", "state_before_unpowered", "powered_state_before_unpowered"]:
		if not saved_entry.has(field_name):
			warnings.append("power_debug_runtime_save_fields: runtime snapshot missing field %s." % field_name)
	for i in range(mission_world_objects.size() - 1, -1, -1):
		var object_id := String(mission_world_objects[i].get("id", "")).strip_edges()
		if cleanup_ids.has(object_id):
			mission_world_objects.remove_at(i)
	for warning in validate_cooling_runtime():
		warnings.append(String(warning))
	for warning in validate_cooling_and_cable_runtime():
		warnings.append(String(warning))
	if has_method("validate_platform_scan_visibility_runtime"):
		for warning in validate_platform_scan_visibility_runtime():
			warnings.append(String(warning))
	return warnings

func validate_cooling_runtime() -> Array[String]:
	var warnings: Array[String] = []
	var preview := preview_cooling_application("")
	if typeof(preview.get("targets", [])) != TYPE_ARRAY:
		warnings.append("Cooling preview regression: targets missing.")
	var apply_snapshot := preview_cooling_application("")
	if str(preview) != str(apply_snapshot):
		warnings.append("Cooling preview regression: read-only preview produced unstable results.")
	return warnings

func validate_cooling_and_cable_runtime() -> Array[String]:
	var warnings: Array[String] = []
	var snapshot := get_world_object_runtime_state()
	var source := {"id":"temp_cooling_source", "object_group":"power", "object_type":"power_source", "position":Vector2i(130, 100), "is_powered":true, "state":"active"}
	var radiator := {"id":"temp_cooling_radiator", "object_group":"cooling", "object_type":"cooling_radiator", "position":Vector2i(131, 100), "cooling_device_type":"radiator", "cooling_output":2, "state":"active", "is_powered":true}
	var cable := {"id":"temp_validation_cable", "object_group":"cable", "object_type":"power_cable", "position":Vector2i(132, 100), "connected":true, "disconnected":false, "cut":false, "state":"active"}
	for obj in [source, radiator, cable]:
		mission_world_objects.append(obj)
		world_objects_by_cell[Vector2i(obj.get("position", Vector2i(-1, -1)))] = obj
	var cool_preview_before := str(get_world_object_runtime_state())
	preview_cooling_application("")
	if str(get_world_object_runtime_state()) != cool_preview_before:
		warnings.append("cooling_preview_mutated_state")
	cable["cut"] = true
	cable["connected"] = false
	cable["disconnected"] = true
	if bool(cable.get("connected", true)):
		warnings.append("cut_cable_should_disconnect")
	var repair_item := {"id":"temp_repair_kit_cable", "object_group":"item", "object_type":"item", "position":Vector2i(133, 100), "item_type":"repair_kit"}
	mission_world_objects.append(repair_item)
	world_objects_by_cell[Vector2i(133, 100)] = repair_item
	cable["damaged"] = true
	use_inventory_item_on_world_object("temp_repair_kit_cable", "temp_validation_cable")
	if not bool(cable.get("disconnected", false)):
		warnings.append("cable_repair_should_not_reconnect")
	for i in range(mission_world_objects.size() - 1, -1, -1):
		var oid := String(mission_world_objects[i].get("id", ""))
		if oid.begins_with("temp_"):
			world_objects_by_cell.erase(WorldObjectCatalogRef.to_world_cell(mission_world_objects[i].get("position", Vector2i(-1, -1)), Vector2i(-1, -1)))
			mission_world_objects.remove_at(i)
	apply_world_object_runtime_state(snapshot)
	for object_id_variant in snapshot.keys():
		var object_id := String(object_id_variant)
		var entry: Dictionary = snapshot.get(object_id_variant, {})
		if entry.has("cable_path_cells") and not entry.has("cable_length"):
			warnings.append("Runtime cable serialization regression: cable_length missing for %s." % object_id)
	return warnings

func get_cooling_and_cable_validation_text() -> String:
	var warnings := validate_cooling_and_cable_runtime()
	if warnings.is_empty():
		return "CoolingCableValidation: ok"
	return "CoolingCableValidation:\n- " + "\n- ".join(warnings)

func get_full_power_system_validation_text() -> String:
	var warnings := validate_full_power_system_runtime()
	var lines: Array[String] = ["FullPowerValidation: warnings=%d" % warnings.size()]
	for warning in warnings:
		lines.append("WARNING: %s" % warning)
	return "\n".join(lines)


func _has_xray_capability() -> Dictionary:
	if active_bipob_ref != null and active_bipob_ref.has_method("has_module_id") and bool(active_bipob_ref.call("has_module_id", "xray_v1")):
		return {"ok": true, "reason": "ok"}
	return {"ok": false, "reason": "xray_capability_unavailable", "debug_reason": "debug_xray_allowed"}

func is_world_object_visible_to_player(object_data: Dictionary, scan_mode: String = "basic") -> bool:
	var cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	var cell_visible := true
	if grid_manager != null and grid_manager.has_method("is_cell_visible"):
		cell_visible = bool(grid_manager.call("is_cell_visible", cell))
	var hidden := bool(object_data.get("hidden", false))
	if scan_mode == "xray":
		return cell_visible or bool(object_data.get("revealed", false)) or bool(object_data.get("discovered", false)) or bool(object_data.get("revealed_by_scan", false)) or bool(object_data.get("visible_with_xray", false))
	if hidden:
		return cell_visible and (bool(object_data.get("discovered", false)) or bool(object_data.get("revealed", false)) or bool(object_data.get("revealed_by_scan", false)))
	return cell_visible or bool(object_data.get("revealed", false)) or bool(object_data.get("discovered", false))

func get_visible_world_objects_for_scan(scan_mode: String = "basic") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if is_world_object_visible_to_player(object_data, scan_mode): out.append(object_data)
	return out

func get_xray_visible_objects(filter: String = "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if not bool(object_data.get("hidden", false)): continue
		if not bool(object_data.get("visible_with_xray", false)) and not bool(object_data.get("hidden_cable", false)): continue
		if not filter.strip_edges().is_empty() and String(object_data.get("power_network_id", "")) != filter.strip_edges(): continue
		out.append(object_data)
	return out

func reveal_xray_objects(filter: String = "") -> Dictionary:
	var cap := _has_xray_capability()
	var targets := get_xray_visible_objects(filter)
	for target in targets:
		target["revealed"] = true
		target["discovered"] = true
		target["revealed_by_scan"] = true
	return {"success": true, "reason": String(cap.get("reason", "ok")), "debug_reason": String(cap.get("debug_reason", "")), "revealed": targets.size()}

func get_world_object_debug_info(object_id: String) -> Dictionary:
	var normalized_id := object_id.strip_edges()
	if normalized_id.is_empty():
		return {}
	var object_data := get_world_object_by_id(normalized_id)
	if object_data.is_empty():
		return {}
	var info := {}
	for key in ["id", "object_type", "display_name", "object_group", "state"]:
		if object_data.has(key):
			info[key] = object_data[key]
	info["position"] = _debug_cell_to_array(WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1)))
	for key in [
		"is_powered",
		"current_heat",
		"working_heat",
		"cooling_received",
		"heat_from_connections",
		"overheat_threshold",
		"connected_device_ids",
		"power_network_id",
		"facing_dir",
		"movable",
		"heavy_claw_movable",
		"cooling_device_type",
		"cooling_output",
		"cooling_amplifier",
		"material",
		"storage_type",
		"storage_capacity",
		"storage_locked",
		"lock_type",
		"lock_difficulty",
		"access_level",
		"required_access_level"
	]:
		if object_data.has(key):
			info[key] = object_data[key]
	for key in ["platform_height_level", "carried_by_platform_id"]:
		if object_data.has(key):
			info[key] = object_data[key]
	if _is_power_network_object(object_data):
		info["power_network_id"] = _get_power_network_id(object_data)
		info["current_heat"] = int(object_data.get("current_heat", 0))
		info["overheat_threshold"] = int(object_data.get("overheat_threshold", 0))
		info["is_powered"] = bool(object_data.get("is_powered", false))
		info["connected_power_source_id"] = String(object_data.get("connected_power_source_id", "")).strip_edges()
		var network_summary_lines := _get_power_network_summary_lines(_get_power_network_id(object_data))
		if not network_summary_lines.is_empty():
			info["power_network_summary_line"] = network_summary_lines[0]
	if String(object_data.get("object_group", "")) == "platform":
		info["platform_state_summary"] = get_platform_state_summary(object_data)
		info["platform_occupant_summary"] = get_platform_occupant_summary(object_data)
	return info

func _get_debug_tile_info(cell: Vector2i) -> Variant:
	if grid_manager == null:
		return null
	if not grid_manager.has_method("get_tile"):
		return null
	var tile_variant: Variant = grid_manager.get_tile(cell)
	match typeof(tile_variant):
		TYPE_NIL:
			return null
		TYPE_INT:
			return int(tile_variant)
		TYPE_FLOAT:
			return float(tile_variant)
		TYPE_STRING:
			return String(tile_variant)
		TYPE_DICTIONARY:
			return Dictionary(tile_variant).duplicate(true)
		TYPE_ARRAY:
			var tile_array := Array(tile_variant)
			if tile_array.size() <= 16:
				return tile_array.duplicate(true)
			return str(tile_array)
		_:
			return str(tile_variant)

func _get_wall_tile_id() -> Variant:
	if grid_manager == null:
		return null
	if not grid_manager.has_method("get_property_list"):
		return null
	for property_data in grid_manager.get_property_list():
		if typeof(property_data) != TYPE_DICTIONARY:
			continue
		if String(property_data.get("name", "")) == "TILE_WALL":
			return grid_manager.get("TILE_WALL")
	return null

func get_world_cell_debug_info(cell: Vector2i) -> Dictionary:
	var info := {"cell": _debug_cell_to_array(cell)}
	info["height_level"] = get_cell_height_level(cell)
	if grid_manager != null:
		if grid_manager.has_method("is_in_bounds"):
			info["in_bounds"] = bool(grid_manager.is_in_bounds(cell))
		if grid_manager.has_method("is_walkable"):
			info["walkable"] = bool(grid_manager.is_walkable(cell))
		var tile_info: Variant = _get_debug_tile_info(cell)
		if tile_info != null:
			info["tile"] = tile_info
			if typeof(tile_info) == TYPE_DICTIONARY:
				var tile_data: Dictionary = Dictionary(tile_info)
				if String(tile_data.get("type", "")) == "wall":
					info["is_wall"] = true
			elif typeof(tile_info) == TYPE_INT:
				var wall_tile_id: Variant = _get_wall_tile_id()
				if wall_tile_id != null and typeof(wall_tile_id) == TYPE_INT:
					info["is_wall"] = int(tile_info) == int(wall_tile_id)
	var object_data := get_world_object_at_cell(cell)
	if not object_data.is_empty():
		info["world_object_id"] = String(object_data.get("id", ""))
		info["world_object_type"] = String(object_data.get("object_type", ""))
		if _is_power_network_object(object_data):
			var power_network_id := _get_power_network_id(object_data)
			info["power_network_id"] = power_network_id
			var network_summary_lines := _get_power_network_summary_lines(power_network_id)
			if not network_summary_lines.is_empty():
				info["power_network_debug_summary_line"] = network_summary_lines[0]
		if String(object_data.get("object_group", "")) == "platform":
			info["platform_id"] = String(object_data.get("platform_id", ""))
			info["platform_state_summary"] = get_platform_state_summary(object_data)
			info["platform_occupant_summary"] = get_platform_occupant_summary(object_data)
	var items: Array = cell_items.get(cell, [])
	info["item_count"] = items.size()
	if not items.is_empty():
		var item_ids: Array[String] = []
		var item_types: Array[String] = []
		for item_variant in items:
			if typeof(item_variant) != TYPE_DICTIONARY:
				continue
			var item_data := Dictionary(item_variant)
			item_ids.append(String(item_data.get("id", "")))
			item_types.append(String(item_data.get("object_type", "")))
		info["item_ids"] = item_ids
		info["item_types"] = item_types
	return info

func get_world_objects_debug_table_text(filter: String = "") -> String:
	if mission_world_objects.is_empty():
		return "world_objects: none"
	var filter_text := filter.strip_edges().to_lower()
	var object_rows: Array[String] = []
	for object_data in mission_world_objects:
		var object_id := String(object_data.get("id", ""))
		var object_type := String(object_data.get("object_type", ""))
		var object_group := String(object_data.get("object_group", ""))
		var state := String(object_data.get("state", ""))
		if not filter_text.is_empty():
			var match_blob := ("%s|%s|%s|%s" % [object_id, object_type, object_group, state]).to_lower()
			if match_blob.find(filter_text) == -1:
				continue
		object_rows.append(_format_world_object_debug_row(object_data))
	if object_rows.is_empty():
		return "world_objects: none (filter=%s)" % filter_text
	object_rows.sort()
	var lines: Array[String] = []
	lines.append("id | type | pos | state | heat | cooling | powered | facing | movable")
	lines.append_array(object_rows)
	if has_method("get_world_runtime_restore_warnings"):
		var warnings: Array = get_world_runtime_restore_warnings()
		lines.append("restore_warnings=%d" % warnings.size())
	return "\n".join(lines)

func _format_world_object_debug_row(object_data: Dictionary) -> String:
	var object_id := String(object_data.get("id", ""))
	var object_type := String(object_data.get("object_type", ""))
	var state := String(object_data.get("state", ""))
	var cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	var position_text := "[%d,%d]" % [cell.x, cell.y]
	var heat_text := "-"
	if object_data.has("current_heat") or object_data.has("overheat_threshold"):
		heat_text = "%d/%d" % [int(object_data.get("current_heat", 0)), int(object_data.get("overheat_threshold", 0))]
	var cooling_text := "-"
	if object_data.has("cooling_received"):
		cooling_text = str(int(object_data.get("cooling_received", 0)))
	var powered_text := "-"
	if object_data.has("is_powered"):
		powered_text = str(bool(object_data.get("is_powered", false)))
	var facing_text := "-"
	if object_data.has("facing_dir"):
		facing_text = String(object_data.get("facing_dir", "")).strip_edges()
		if facing_text.is_empty():
			facing_text = "-"
	var movable_text := str(WorldObjectCatalogRef.can_world_object_be_moved_by_heavy_claw(object_data))
	if object_data.has("heavy_claw_movable"):
		movable_text = str(bool(object_data.get("heavy_claw_movable", false)))
	elif object_data.has("movable"):
		movable_text = str(bool(object_data.get("movable", false)))
	return "%s | %s | %s | %s | heat=%s | cool=%s | powered=%s | facing=%s | movable=%s" % [
		object_id,
		object_type,
		position_text,
		state,
		heat_text,
		cooling_text,
		powered_text,
		facing_text,
		movable_text
	]

func _debug_cell_to_array(cell: Vector2i) -> Array[int]:
	return [cell.x, cell.y]

func get_world_heat_debug_summary_text() -> String:
	var terminals_count := 0
	var overheated_terminals := 0
	var power_sources_count := 0
	var overheated_power_sources := 0
	var invalid_heat_metadata := 0
	var missing_threshold := 0
	var cooling_devices_count := 0
	var cooled_heat_targets := 0
	var max_cooling_received := 0
	var invalid_cooling_metadata := 0
	var has_cooling_debug_scenario := not get_world_object_by_id("terminal_c2_radiator").is_empty()
	for object_data in mission_world_objects:
		var group := String(object_data.get("object_group", ""))
		var object_type := String(object_data.get("object_type", ""))
		var is_power_source := object_type in ["power_source", "power_source_class_1", "power_source_class_2", "power_source_class_3"]
		if group == "cooling":
			cooling_devices_count += 1
		var heat_enabled := object_data.has("working_heat") or object_data.has("overheat_threshold")
		if group == "terminal":
			terminals_count += 1
			if String(object_data.get("state", "")) == "overheated":
				overheated_terminals += 1
		elif is_power_source:
			power_sources_count += 1
			if String(object_data.get("state", "")) == "overheated":
				overheated_power_sources += 1
		if heat_enabled:
			var cooling_value := maxi(0, int(object_data.get("cooling_received", 0)))
			if cooling_value > 0:
				cooled_heat_targets += 1
			max_cooling_received = maxi(max_cooling_received, cooling_value)
			if not object_data.has("overheat_threshold"):
				missing_threshold += 1
			var threshold := int(object_data.get("overheat_threshold", 0))
			if threshold < 0 or int(object_data.get("working_heat", 0)) < 0:
				invalid_heat_metadata += 1
		var object_cooling_type := String(object_data.get("cooling_device_type", ""))
		if group == "cooling":
			if object_cooling_type.is_empty():
				invalid_cooling_metadata += 1
			elif not object_cooling_type in ["radiator", "air_cooler", "water_pipe", "air_duct"]:
				invalid_cooling_metadata += 1
		if object_cooling_type == "air_cooler" and not object_data.has("facing_dir"):
			invalid_cooling_metadata += 1
	var summary := "WorldHeat: terminals=%d overheated=%d | power_sources=%d overheated=%d | invalid_heat=%d | missing_threshold=%d | cooling_devices=%d | cooled_targets=%d | max_cooling=%d | invalid_cooling=%d" % [
		terminals_count,
		overheated_terminals,
		power_sources_count,
		overheated_power_sources,
		invalid_heat_metadata,
		missing_threshold,
		cooling_devices_count,
		cooled_heat_targets,
		max_cooling_received,
		invalid_cooling_metadata
	]
	if has_cooling_debug_scenario:
		var validation_warnings := validate_world_cooling_debug_scenario()
		if debug_world_logs and not validation_warnings.is_empty():
			for warning in validation_warnings:
				push_warning("[WorldCoolingValidation] %s" % warning)
		summary += " | cooling_validation_issues=%d" % validation_warnings.size()
	return summary

func get_world_object_runtime_state() -> Dictionary:
	# Runtime-only snapshot helper for future save manager integration.
	var runtime_state := {}
	var runtime_fields := [
		"state",
		"is_powered",
		"current_heat",
		"working_heat",
		"cooling_received",
		"heat_from_connections",
		"connected_device_ids",
		"overheated_state_before",
		"overheated_powered_before",
		"facing_dir",
		"power_network_id",
		"drain_pool",
		"platform_id",
		"platform_type",
		"platform_cells",
		"local_switch_cell",
		"local_switch_facing_dir",
		"linked_terminal_id",
		"requires_terminal_enabled",
		"control_type",
		"power_type",
		"height_level",
		"min_height_level",
		"max_height_level",
		"activation_mode",
		"timer_turns",
		"timer_remaining_turns",
		"period_turns",
		"periodic_active",
		"permanent_state",
		"pending_activation",
		"rotation_direction",
		"platform_height_level",
		"carried_by_platform_id",
		"target_platform_id",
		"platform_control_enabled",
		"platform_remote_control",
		"state_before_unpowered",
		"powered_state_before_unpowered",
		"source_load",
		"source_capacity",
		"source_overloaded",
		"overheat_threshold",
		"power_unavailable_reason",
		"connected",
		"disconnected",
		"cut",
		"cable_endpoint_a_id",
		"cable_endpoint_b_id",
		"cable_path_cells",
		"cable_length",
		"cable_max_length",
		"cooling_source_ids",
		"cooling_reason",
		"damaged",
		"broken",
		"destroyed",
		"revealed",
		"discovered",
		"revealed_by_scan",
		"visible_with_xray",
		"hidden_cable",
		"requires_xray",
		"platform_rotation",
		"local_switch_enabled",
		"terminal_control_enabled"
	]
	for object_data in mission_world_objects:
		var object_id := String(object_data.get("id", "")).strip_edges()
		if object_id.is_empty():
			continue
		var serialized := {}
		if object_data.has("object_type"):
			serialized["object_type"] = String(object_data.get("object_type", ""))
		if object_data.has("position"):
			var world_cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
			serialized["position"] = [world_cell.x, world_cell.y]
		for field_name in runtime_fields:
			if object_data.has(field_name):
				serialized[field_name] = object_data[field_name]
		if not serialized.is_empty():
			runtime_state[object_id] = serialized
	return runtime_state

func get_inventory_state() -> Dictionary:
	return runtime_inventory_state.duplicate(true)

func get_actor_capability_levels() -> Dictionary:
	var defaults := {
		"manipulator_level": 0,
		"connector_level": 0,
		"processor_level": 0,
		"connector_types": [],
		"power_class": "none",
		"modules": [],
		"tools": [],
		"port_state": {}
	}
	if active_bipob_ref == null:
		return defaults
	defaults["manipulator_level"] = int(active_bipob_ref.call("get_installed_manipulator_arm_level")) if active_bipob_ref.has_method("get_installed_manipulator_arm_level") else 0
	defaults["power_class"] = String(active_bipob_ref.call("get_bipob_power_class")) if active_bipob_ref.has_method("get_bipob_power_class") else "none"
	var port_state: Dictionary = active_bipob_ref.call("preview_module_port_activity") if active_bipob_ref.has_method("preview_module_port_activity") else {}
	defaults["port_state"] = port_state
	var modules_state: Dictionary = Dictionary(port_state.get("modules", {}))
	var installed_modules: Array = Array(active_bipob_ref.installed_modules) if _active_bipob_has_property("installed_modules") else []
	var modules: Array[String] = []
	var tools: Array[String] = []
	var tool_seen := {}
	var connector_types: Array[String] = []
	var connector_kind_seen := {}
	var connector_level := 0
	var processor_level := 0
	var level_regex := RegEx.new()
	level_regex.compile("_v(\\d+)$")
	for module_id_variant in modules_state.keys():
		var module_id := String(module_id_variant)
		var module_state: Dictionary = Dictionary(modules_state.get(module_id_variant, {}))
		if not bool(module_state.get("active", false)):
			continue
		modules.append(module_id)
		if module_id.contains("_connector_v"):
			var found := level_regex.search(module_id)
			if found != null:
				connector_level = maxi(connector_level, int(found.get_string(1)))
			var connector_type := ""
			if module_id.begins_with("external_interface_connector_"):
				connector_type = "physical"
			elif module_id.begins_with("optical_connector_"):
				connector_type = "optical"
			elif module_id.begins_with("wireless_connector_"):
				connector_type = "wireless"
			elif module_id.begins_with("high_bandwidth_connector_"):
				connector_type = "high_bandwidth"
			if not connector_type.is_empty() and not connector_kind_seen.has(connector_type):
				connector_kind_seen[connector_type] = true
				connector_types.append(connector_type)
		elif module_id.begins_with("processor_"):
			var pfound := level_regex.search(module_id)
			if pfound != null:
				processor_level = maxi(processor_level, int(pfound.get_string(1)))
	for module_variant in installed_modules:
		if module_variant == null:
			continue
		var module_id := String(module_variant.id).strip_edges()
		if module_id.is_empty():
			continue
		if String(module_variant.category) != "Tools":
			continue
		var module_state: Dictionary = Dictionary(modules_state.get(module_id, {}))
		if not bool(module_state.get("active", false)):
			continue
		var tool_action := String(module_variant.tool_action).strip_edges()
		var tool_id := tool_action if not tool_action.is_empty() else module_id
		if tool_seen.has(tool_id):
			continue
		tool_seen[tool_id] = true
		tools.append(tool_id)
	defaults["modules"] = modules
	defaults["tools"] = tools
	defaults["connector_types"] = connector_types
	defaults["connector_level"] = connector_level
	defaults["processor_level"] = processor_level
	return defaults

func check_world_object_requirements(object_id: String, action: String = "") -> Dictionary:
	var object_data := get_world_object_by_id(object_id)
	var capabilities := get_actor_capability_levels()
	var requirements: Dictionary = {}
	var reasons: Array[String] = []
	if object_data.is_empty():
		return {"allowed": false, "object_id": object_id, "action": action, "requirements": requirements, "capabilities": capabilities, "reasons": ["object_missing"]}
	for key in ["required_manipulator_level", "required_connector_level", "required_processor_level", "required_bipob_power_class", "fits_targets", "required_tool", "required_item_id", "lock_type", "terminal_class", "door_class", "item_form", "storage_type"]:
		if object_data.has(key):
			requirements[key] = object_data[key]
	if int(requirements.get("required_manipulator_level", 0)) > int(capabilities.get("manipulator_level", 0)): reasons.append("manipulator_level_too_low")
	if int(requirements.get("required_connector_level", 0)) > int(capabilities.get("connector_level", 0)): reasons.append("connector_level_too_low")
	if int(requirements.get("required_processor_level", 0)) > int(capabilities.get("processor_level", 0)): reasons.append("processor_level_too_low")
	var required_power_class := String(requirements.get("required_bipob_power_class", "")).strip_edges()
	if not required_power_class.is_empty() and required_power_class != String(capabilities.get("power_class", "none")):
		reasons.append("power_class_too_low")
	if not String(requirements.get("required_tool", "")).strip_edges().is_empty() and not Array(capabilities.get("tools", [])).has(String(requirements.get("required_tool", ""))):
		reasons.append("required_tool_missing")
	if not String(requirements.get("required_item_id", "")).strip_edges().is_empty():
		var inv := get_inventory_state()
		var all_items: Array = Array(inv.get("pocket_items", [])) + [String(inv.get("manipulator_hold", ""))] + Array(inv.get("digital_buffer", []))
		if not all_items.has(String(requirements.get("required_item_id", ""))):
			reasons.append("required_item_missing")
	if reasons.is_empty():
		reasons.append("ok")
	return {"allowed": reasons.size() == 1 and reasons[0] == "ok", "object_id": object_id, "action": action, "requirements": requirements, "capabilities": capabilities, "reasons": reasons}

func can_pickup_world_item(item_id: String) -> Dictionary:
	var item := get_world_object_by_id(item_id)
	if item.is_empty():
		return {"success": false, "reasons": ["item_missing"], "item_id": item_id}
	if not bool(item.get("can_pickup", true)):
		return {"success": false, "reasons": ["item_does_not_fit"], "item_id": item_id}
	return {"success": true, "reasons": ["ok"], "item_id": item_id}

func pickup_world_item(item_id: String) -> Dictionary:
	var gate := can_pickup_world_item(item_id)
	if not bool(gate.get("success", false)):
		return gate
	var item := get_world_object_by_id(item_id)
	var storage_type := String(item.get("storage_type", "pocket"))
	if String(item.get("item_form", "physical")) == "digital":
		return place_item_in_digital_buffer(item_id)
	if storage_type == "manipulator_hold":
		return hold_item_in_manipulator(item_id)
	var pocket: Array = runtime_inventory_state.get("pocket_items", [])
	pocket.append(item_id)
	runtime_inventory_state["pocket_items"] = pocket
	runtime_inventory_state["world_item_runtime"][item_id] = {"picked_up": true, "in_inventory": true, "carried_by": "bipob"}
	return {"success": true, "reasons": ["ok"], "item_id": item_id}

func can_drop_inventory_item(item_id: String) -> Dictionary:
	var inv := get_inventory_state()
	var has_item := Array(inv.get("pocket_items", [])).has(item_id) or String(inv.get("manipulator_hold", "")) == item_id
	return {"success": has_item, "item_id": item_id, "reasons": ["ok"] if has_item else ["item_missing"]}

func drop_inventory_item(item_id: String, target_cell: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	var gate := can_drop_inventory_item(item_id)
	if not bool(gate.get("success", false)):
		return gate
	var pocket: Array = runtime_inventory_state.get("pocket_items", [])
	pocket.erase(item_id)
	runtime_inventory_state["pocket_items"] = pocket
	if String(runtime_inventory_state.get("manipulator_hold", "")) == item_id:
		runtime_inventory_state["manipulator_hold"] = ""
	runtime_inventory_state["world_item_runtime"][item_id] = {"picked_up": false, "in_inventory": false, "carried_by": "", "position": [target_cell.x, target_cell.y]}
	return {"success": true, "item_id": item_id, "target_cell": target_cell, "reasons": ["ok"]}

func can_hold_item_in_manipulator(item_id: String) -> Dictionary:
	if String(runtime_inventory_state.get("manipulator_hold", "")) != "":
		return {"success": false, "item_id": item_id, "reasons": ["item_does_not_fit"]}
	return {"success": true, "item_id": item_id, "reasons": ["ok"]}

func hold_item_in_manipulator(item_id: String) -> Dictionary:
	var gate := can_hold_item_in_manipulator(item_id)
	if not bool(gate.get("success", false)):
		return gate
	runtime_inventory_state["manipulator_hold"] = item_id
	return {"success": true, "item_id": item_id, "reasons": ["ok"]}

func can_place_item_in_digital_buffer(item_id: String) -> Dictionary:
	var item := get_world_object_by_id(item_id)
	if item.is_empty():
		return {"success": false, "item_id": item_id, "reasons": ["item_missing"]}
	if not bool(item.get("can_place_in_digital_buffer", false)):
		return {"success": false, "item_id": item_id, "reasons": ["item_does_not_fit"]}
	return {"success": true, "item_id": item_id, "reasons": ["ok"]}

func place_item_in_digital_buffer(item_id: String) -> Dictionary:
	var gate := can_place_item_in_digital_buffer(item_id)
	if not bool(gate.get("success", false)):
		return gate
	var buffer: Array = runtime_inventory_state.get("digital_buffer", [])
	if not buffer.has(item_id):
		buffer.append(item_id)
	runtime_inventory_state["digital_buffer"] = buffer
	return {"success": true, "item_id": item_id, "reasons": ["ok"]}

func _add_world_runtime_restore_warning(message: String) -> void:
	if message.strip_edges().is_empty():
		return
	last_world_runtime_restore_warnings.append(message)

func _extract_saved_world_runtime_position(saved_data: Dictionary, object_id: String, fallback_position: Vector2i) -> Dictionary:
	if not saved_data.has("position"):
		return {"ok": true, "position": fallback_position}
	var position_variant: Variant = saved_data.get("position")
	var parsed_position := WorldObjectCatalogRef.to_world_cell(position_variant, Vector2i(-1, -1))
	if parsed_position.x < 0 and parsed_position.y < 0:
		_add_world_runtime_restore_warning("Restore skipped for %s: invalid position data." % object_id)
		return {"ok": false}
	if parsed_position.x < 0 or parsed_position.y < 0:
		_add_world_runtime_restore_warning("Restore skipped for %s: position has negative coordinate %s." % [object_id, str(parsed_position)])
		return {"ok": false}
	if grid_manager != null and grid_manager.has_method("is_in_bounds") and not bool(grid_manager.call("is_in_bounds", parsed_position)):
		_add_world_runtime_restore_warning("Restore skipped for %s: position %s is out of bounds." % [object_id, str(parsed_position)])
		return {"ok": false}
	if grid_manager != null and grid_manager.has_method("is_walkable") and not bool(grid_manager.call("is_walkable", parsed_position)):
		_add_world_runtime_restore_warning("Restore skipped for %s: position %s is not walkable." % [object_id, str(parsed_position)])
		return {"ok": false}
	if grid_manager != null and grid_manager.has_method("get_tile"):
		var tile_variant: Variant = grid_manager.call("get_tile", parsed_position)
		if typeof(tile_variant) == TYPE_DICTIONARY:
			var tile_data: Dictionary = tile_variant
			if String(tile_data.get("type", "")) == "wall":
				_add_world_runtime_restore_warning("Restore skipped for %s: position %s is a wall tile." % [object_id, str(parsed_position)])
				return {"ok": false}
	return {"ok": true, "position": parsed_position}

func apply_world_object_runtime_state(saved_state: Dictionary) -> void:
	last_world_runtime_restore_warnings.clear()
	if saved_state.is_empty():
		return
	for object_id_variant in saved_state.keys():
		var object_id := String(object_id_variant).strip_edges()
		if object_id.is_empty():
			continue
		var saved_data_variant: Variant = saved_state.get(object_id_variant, {})
		if typeof(saved_data_variant) != TYPE_DICTIONARY:
			_add_world_runtime_restore_warning("Restore skipped for %s: runtime entry is not a dictionary." % object_id)
			continue
		var saved_data: Dictionary = saved_data_variant
		var existing_object := get_world_object_by_id(object_id)
		var is_new_object := existing_object.is_empty()
		var candidate_object := existing_object
		if is_new_object:
			var object_type := String(saved_data.get("object_type", "")).strip_edges()
			if object_type.is_empty():
				_add_world_runtime_restore_warning("Restore skipped for %s: missing object_type for unknown object id." % object_id)
				continue
			var created := WorldObjectCatalogRef.create_world_object(object_type, object_id)
			if created.is_empty():
				_add_world_runtime_restore_warning("Restore skipped for %s: failed to create object_type %s." % [object_id, object_type])
				continue
			created["id"] = object_id
			candidate_object = created
		var old_position := WorldObjectCatalogRef.to_world_cell(candidate_object.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
		var parsed_position_info := _extract_saved_world_runtime_position(saved_data, object_id, old_position)
		if not bool(parsed_position_info.get("ok", false)):
			continue
		var new_position := Vector2i(parsed_position_info.get("position", old_position))
		var replaced := get_world_object_at_cell(new_position)
		if not replaced.is_empty() and String(replaced.get("id", "")) != object_id:
			_add_world_runtime_restore_warning("Restore skipped for %s: target cell occupied by %s." % [object_id, String(replaced.get("id", ""))])
			continue
		var runtime_updates: Dictionary = {}
		for key_variant in saved_data.keys():
			var key := String(key_variant)
			if String(key) == "position":
				continue
			runtime_updates[key] = saved_data[key_variant]
		for key in runtime_updates.keys():
			candidate_object[key] = runtime_updates[key]
		candidate_object["id"] = object_id
		candidate_object["position"] = new_position
		if not is_new_object and old_position != new_position:
			world_objects_by_cell.erase(old_position)
		world_objects_by_cell[new_position] = candidate_object
		if is_new_object and not mission_world_objects.has(candidate_object):
			mission_world_objects.append(candidate_object)
	refresh_world_cooling_received()
	PowerSystemRef.recalculate_network(mission_world_objects, "power_net_A")
	refresh_world_cooling_received()

func get_world_runtime_persistence_debug_summary_text() -> String:
	var serialized := get_world_object_runtime_state()
	var moved_objects := 0
	var heat_enabled_objects := 0
	var powered_objects := 0
	var connection_state_objects := 0
	for object_data in mission_world_objects:
		var current_position := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
		if object_data.has("original_position"):
			var original_position := WorldObjectCatalogRef.to_world_cell(object_data.get("original_position", current_position), current_position)
			if original_position != current_position:
				moved_objects += 1
		if object_data.has("working_heat") or object_data.has("overheat_threshold") or object_data.has("current_heat"):
			heat_enabled_objects += 1
		if bool(object_data.get("is_powered", false)):
			powered_objects += 1
		if object_data.has("connected_device_ids") or object_data.has("heat_from_connections"):
			connection_state_objects += 1
	return "WorldRuntimePersistence: serialized=%d | moved=%d | heat_enabled=%d | powered=%d | connection_state=%d | restore_warnings=%d" % [
		serialized.size(),
		moved_objects,
		heat_enabled_objects,
		powered_objects,
		connection_state_objects,
		last_world_runtime_restore_warnings.size()
	]

func get_world_runtime_restore_warnings_text() -> String:
	if last_world_runtime_restore_warnings.is_empty():
		return "No world runtime restore warnings."
	return "\n".join(last_world_runtime_restore_warnings)

func get_world_runtime_restore_warnings() -> Array[String]:
	return last_world_runtime_restore_warnings.duplicate()


func set_active_bipob_ref(bipob: Node) -> void:
	active_bipob_ref = bipob

func get_platform_by_id(platform_id: String) -> Dictionary:
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) != "platform":
			continue
		if String(object_data.get("platform_id", "")) == platform_id:
			return object_data
	return {}

func get_platform_for_cell(cell: Vector2i) -> Dictionary:
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) != "platform":
			continue
		for platform_cell_variant in Array(object_data.get("platform_cells", [])):
			var platform_cell := WorldObjectCatalogRef.to_world_cell(platform_cell_variant, Vector2i(-1, -1))
			if platform_cell == cell:
				return object_data
	return {}

func get_cell_height_level(cell: Vector2i) -> int:
	var platform := get_platform_for_cell(cell)
	if platform.is_empty() or String(platform.get("platform_type", "")) != "lifting":
		return 0
	return int(platform.get("height_level", 0))

func refresh_world_object_platform_height_state(object_data: Dictionary) -> void:
	if object_data.is_empty():
		return
	var object_cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	if object_cell.x < 0 or object_cell.y < 0:
		return
	var platform := get_platform_for_cell(object_cell)
	if not platform.is_empty() and String(platform.get("platform_type", "")) == "lifting":
		object_data["platform_height_level"] = int(platform.get("height_level", 0))
		object_data["carried_by_platform_id"] = String(platform.get("platform_id", ""))
		return
	object_data["platform_height_level"] = get_cell_height_level(object_cell)
	object_data.erase("carried_by_platform_id")

func get_world_object_height_level(object_data: Dictionary) -> int:
	if object_data.is_empty():
		return 0
	if object_data.has("platform_height_level"):
		return int(object_data.get("platform_height_level", 0))
	var object_cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	return get_cell_height_level(object_cell)

func get_actor_height_level(actor_cell: Vector2i, actor: Node = null) -> int:
	var cell_height := get_cell_height_level(actor_cell)
	if actor == null:
		return cell_height
	if actor.has_method("get_carried_by_platform_id"):
		var carried_platform_id := String(actor.call("get_carried_by_platform_id")).strip_edges()
		if carried_platform_id.is_empty():
			return cell_height
		var current_platform := get_platform_for_cell(actor_cell)
		if current_platform.is_empty():
			return cell_height
		var current_platform_id := String(current_platform.get("platform_id", "")).strip_edges()
		if current_platform_id != carried_platform_id:
			return cell_height
		if actor.has_method("get_platform_height_level"):
			return int(actor.call("get_platform_height_level"))
		return cell_height
	if actor.has_method("get_platform_height_level"):
		return int(actor.call("get_platform_height_level"))
	return get_cell_height_level(actor_cell)

func can_move_between_height_levels(from_cell: Vector2i, to_cell: Vector2i, actor: Node = null) -> bool:
	var from_height := get_actor_height_level(from_cell, actor)
	var to_height := get_cell_height_level(to_cell)
	if from_height == to_height:
		return true
	if actor != null and actor.has_method("get_carried_by_platform_id"):
		var carried_platform_id := String(actor.call("get_carried_by_platform_id")).strip_edges()
		if not carried_platform_id.is_empty():
			var target_platform := get_platform_for_cell(to_cell)
			if not target_platform.is_empty() and String(target_platform.get("platform_id", "")).strip_edges() == carried_platform_id:
				return true
	return false

func get_platform_occupants(platform_id: String) -> Dictionary:
	var platform := get_platform_by_id(platform_id)
	if platform.is_empty():
		return {"world_objects": [], "items": [], "bipobs": []}
	var cells: Array = []
	for c in Array(platform.get("platform_cells", [])):
		cells.append(WorldObjectCatalogRef.to_world_cell(c, Vector2i(-1, -1)))
	var occupants := {"world_objects": [], "items": [], "bipobs": []}
	for object_data in mission_world_objects:
		if String(object_data.get("id", "")) == String(platform.get("id", "")):
			continue
		var pos := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
		if cells.has(pos):
			occupants["world_objects"].append(object_data)
	for cell in cells:
		for item in get_items_at_cell(cell):
			occupants["items"].append(item)
	if active_bipob_ref != null and active_bipob_ref.has_method("get_grid_position"):
		var bipob_cell: Vector2i = active_bipob_ref.get_grid_position()
		if cells.has(bipob_cell):
			var bipob_direction := "up"
			if active_bipob_ref.has_method("get_direction"):
				bipob_direction = String(active_bipob_ref.get_direction())
			occupants["bipobs"].append({"id":"active_bipob","position":bipob_cell,"direction":bipob_direction})
	return occupants

func can_bipob_access_platform_switch(platform: Dictionary, actor_cell: Vector2i, facing_dir: String) -> bool:
	if platform.is_empty():
		return false
	if String(platform.get("object_group", "")) != "platform":
		return false
	if String(platform.get("control_type", "internal")) != "internal":
		return false
	if not platform.has("local_switch_cell"):
		return false
	var local_switch_cell := WorldObjectCatalogRef.to_world_cell(platform.get("local_switch_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
	if local_switch_cell.x < 0 or local_switch_cell.y < 0:
		return false
	var facing_vector := _facing_to_vector(facing_dir)
	return actor_cell + facing_vector == local_switch_cell

func activate_platform_by_id(platform_id: String, source: String = "") -> Dictionary:
	var platform := get_platform_by_id(platform_id)
	if platform.is_empty():
		return {"success":false, "message":"Platform not found."}
	if String(platform.get("state", "active")) in ["unpowered", "disabled"] or not bool(platform.get("is_powered", true)):
		return {"success":false, "message":"Platform is unpowered."}
	if bool(platform.get("requires_terminal_enabled", false)):
		var terminal := get_world_object_by_id(String(platform.get("linked_terminal_id", "")))
		if terminal.is_empty() or String(terminal.get("state", "active")) in ["unpowered", "disabled", "damaged"] or not bool(terminal.get("platform_control_enabled", true)) or not bool(terminal.get("is_powered", true)):
			return {"success":false, "message":"Platform terminal is unavailable."}
	var mode := String(platform.get("activation_mode", "instant"))
	if mode == "timer":
		platform["pending_activation"] = true
		platform["timer_remaining_turns"] = maxi(1, int(platform.get("timer_turns", 1)))
		return {"success":true, "message":"Platform timer armed."}
	if mode == "periodic":
		platform["periodic_active"] = not bool(platform.get("periodic_active", false))
		platform["timer_remaining_turns"] = maxi(1, int(platform.get("period_turns", 1)))
		return {"success":true, "message":"Platform periodic toggled."}
	if mode == "permanent":
		platform["permanent_state"] = not bool(platform.get("permanent_state", false))
	return _execute_platform_action(platform, source)


func get_platform_action_availability(platform_id: String, action: String = "") -> Dictionary:
	var normalized_action := action.strip_edges().to_lower()
	var result := {"available": false, "platform_id": platform_id, "action": normalized_action, "reasons": [], "state": "", "is_powered": false, "control_type": "", "power_type": ""}
	var valid_actions := ["", "activate", "raise", "lower", "toggle", "rotate_clockwise", "rotate_counterclockwise"]
	if not valid_actions.has(normalized_action):
		result["reasons"] = ["invalid_action"]
		return result
	var platform := get_platform_by_id(platform_id)
	if platform.is_empty():
		result["reasons"] = ["platform_missing"]
		return result
	if String(platform.get("object_group", "")) != "platform":
		result["reasons"] = ["not_platform"]
		return result
	result["state"] = String(platform.get("state", ""))
	result["is_powered"] = bool(platform.get("is_powered", false))
	result["control_type"] = String(platform.get("control_type", "internal"))
	result["power_type"] = String(platform.get("power_type", "external"))
	var reasons: Array[String] = []
	if bool(platform.get("damaged", false)) or String(platform.get("state", "")) == "damaged": reasons.append("platform_damaged")
	if bool(platform.get("broken", false)) or String(platform.get("state", "")) == "broken": reasons.append("platform_broken")
	if bool(platform.get("destroyed", false)) or String(platform.get("state", "")) == "destroyed": reasons.append("platform_destroyed")
	if not bool(platform.get("is_powered", true)) or String(platform.get("state", "")) in ["unpowered", "disabled"] or String(platform.get("power_type", "external")) == "external" and not bool(platform.get("is_powered", false)):
		reasons.append("platform_unpowered")
	if not bool(platform.get("local_switch_enabled", true)): reasons.append("local_switch_disabled")
	if not bool(platform.get("terminal_control_enabled", true)): reasons.append("terminal_control_disabled")
	if bool(platform.get("requires_terminal_enabled", false)):
		var terminal := get_world_object_by_id(String(platform.get("linked_terminal_id", "")))
		if terminal.is_empty() or not bool(terminal.get("platform_control_enabled", true)) or String(terminal.get("state", "")) in ["unpowered", "disabled", "damaged"]:
			reasons.append("linked_terminal_unavailable")
	if reasons.is_empty(): reasons.append("ok")
	result["reasons"] = reasons
	result["available"] = reasons.size() == 1 and reasons[0] == "ok"
	return result

func get_lifting_platform_carry_targets(platform_id: String) -> Array[Dictionary]:
	var platform := get_platform_by_id(platform_id)
	if platform.is_empty() or String(platform.get("platform_type", "")) != "lifting":
		return []
	var targets: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if String(object_data.get("id", "")) == String(platform.get("id", "")):
			continue
		if String(object_data.get("object_group", "")) in ["wall", "door", "terminal"] and not bool(object_data.get("rotate_with_platform", false)):
			continue
		if bool(object_data.get("destroyed", false)):
			continue
		var object_cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
		var on_platform := false
		for platform_cell_variant in Array(platform.get("platform_cells", [])):
			if WorldObjectCatalogRef.to_world_cell(platform_cell_variant, Vector2i(-1, -1)) == object_cell:
				on_platform = true
				break
		if on_platform or String(object_data.get("carried_by_platform_id", "")) == platform_id:
			targets.append(object_data)
	return targets

func apply_lifting_platform_height_change(platform_id: String, delta: int, controller_id: String = "") -> Dictionary:
	var platform := get_platform_by_id(platform_id)
	if platform.is_empty(): return {"success": false, "reason": "platform_missing"}
	var current := int(platform.get("height_level", 0))
	var min_h := int(platform.get("min_height_level", 0))
	var max_h := int(platform.get("max_height_level", 1))
	var target := clampi(current + delta, min_h, max_h)
	if target == current:
		return {"success": false, "reason": "already_at_max_height" if delta > 0 else "already_at_min_height", "height_level": current}
	platform["height_level"] = target
	for obj in get_lifting_platform_carry_targets(platform_id):
		obj["platform_height_level"] = target
		obj["height_level"] = target
		obj["carried_by_platform_id"] = platform_id
	if active_bipob_ref != null and active_bipob_ref.has_method("set_platform_height_level") and _is_active_bipob_on_platform(platform):
		active_bipob_ref.call("set_platform_height_level", target, platform_id)
	return {"success": true, "reason": "ok", "height_level": target, "controller_id": controller_id}

func apply_rotating_platform_rotation(platform_id: String, clockwise: bool = true, controller_id: String = "") -> Dictionary:
	var platform := get_platform_by_id(platform_id)
	if platform.is_empty(): return {"success": false, "reason": "platform_missing"}
	var occupants := get_platform_occupants(platform_id)
	platform["rotation_direction"] = "clockwise" if clockwise else "counterclockwise"
	if platform.has("facing_dir"):
		platform["facing_dir"] = _rotate_facing(String(platform.get("facing_dir", "up")), clockwise)
	for obj in Array(occupants.get("world_objects", [])):
		if String(obj.get("object_type", "")) in ["external_air_cooler", "external_air_duct"] or bool(obj.get("rotate_with_platform", false)):
			if obj.has("facing_dir"):
				obj["facing_dir"] = _rotate_facing(String(obj.get("facing_dir", "up")), clockwise)
	var filter := String(platform.get("power_network_id", ""))
	apply_cooling_application(filter)
	execute_power_source_recovery_apply(filter)
	return {"success": true, "reason": "ok", "rotation_direction": platform["rotation_direction"], "controller_id": controller_id}

func execute_platform_action(platform_id: String, action: String = "", controller_id: String = "") -> Dictionary:
	var availability := get_platform_action_availability(platform_id, action)
	if not bool(availability.get("available", false)):
		return {"success": false, "platform_id": platform_id, "action": action, "reason": String((availability.get("reasons", ["blocked"]) as Array)[0]), "availability": availability}
	var normalized := action.strip_edges().to_lower()
	if normalized in ["", "activate", "toggle"]:
		var r := activate_platform_by_id(platform_id, controller_id)
		r["reason"] = "ok" if bool(r.get("success", false)) else "invalid_action"
		return r
	if normalized == "raise": return apply_lifting_platform_height_change(platform_id, 1, controller_id)
	if normalized == "lower": return apply_lifting_platform_height_change(platform_id, -1, controller_id)
	if normalized == "rotate_clockwise": return apply_rotating_platform_rotation(platform_id, true, controller_id)
	if normalized == "rotate_counterclockwise": return apply_rotating_platform_rotation(platform_id, false, controller_id)
	return {"success": false, "platform_id": platform_id, "action": action, "reason": "invalid_action"}

func _is_active_bipob_on_platform(platform: Dictionary) -> bool:
	if active_bipob_ref == null:
		return false
	if not active_bipob_ref.has_method("get_grid_position"):
		return false
	var actor_cell: Variant = active_bipob_ref.call("get_grid_position")
	if typeof(actor_cell) != TYPE_VECTOR2I:
		return false
	for platform_cell_variant in Array(platform.get("platform_cells", [])):
		var platform_cell := WorldObjectCatalogRef.to_world_cell(platform_cell_variant, Vector2i(-1, -1))
		if platform_cell == actor_cell:
			return true
	return false

func _execute_platform_action(platform: Dictionary, source: String = "") -> Dictionary:
	var platform_id := String(platform.get("platform_id", platform.get("id", "")))
	var platform_type := String(platform.get("platform_type", ""))
	var activation_mode := String(platform.get("activation_mode", "instant"))
	var normalized_source := source
	var result := {
		"success": false,
		"message": "",
		"platform_id": platform_id,
		"platform_type": platform_type,
		"activation_mode": activation_mode,
		"source": normalized_source,
		"height_level": -1,
		"rotation_direction": ""
	}
	if platform_type == "rotating":
		var rotation_direction := String(platform.get("rotation_direction", "clockwise"))
		result["rotation_direction"] = rotation_direction
		var occupants := get_platform_occupants(String(platform.get("platform_id", "")))
		for obj in Array(occupants.get("world_objects", [])):
			if obj.has("facing_dir"):
				obj["facing_dir"] = _rotate_facing(String(obj.get("facing_dir", "up")), rotation_direction != "counterclockwise")
		if _is_active_bipob_on_platform(platform) and active_bipob_ref.has_method("set_direction"):
			var current_direction := "up"
			if active_bipob_ref.has_method("get_direction"):
				current_direction = String(active_bipob_ref.get_direction())
			active_bipob_ref.set_direction(_rotate_facing(current_direction, rotation_direction != "counterclockwise"))
		refresh_world_cooling_received()
		result["success"] = true
		var affected_count := Array(occupants.get("world_objects", [])).size() + Array(occupants.get("items", [])).size() + Array(occupants.get("bipobs", [])).size()
		if affected_count > 0:
			result["message"] = "Platform %s rotated %s; occupants affected: %d." % [platform_id, rotation_direction, affected_count]
		else:
			result["message"] = "Platform %s rotated %s." % [platform_id, rotation_direction]
		platform["last_activation_source"] = normalized_source
		platform["last_activation_message"] = String(result.get("message", ""))
		return result
	if platform_type == "lifting":
		var min_h := int(platform.get("min_height_level", 0))
		var max_h := int(platform.get("max_height_level", 1))
		var previous_height := int(platform.get("height_level", min_h))
		platform["height_level"] = max_h if previous_height <= min_h else min_h
		var current_height := int(platform.get("height_level", min_h))
		result["height_level"] = current_height
		var occupants := get_platform_occupants(String(platform.get("platform_id", "")))
		for obj in Array(occupants.get("world_objects", [])):
			refresh_world_object_platform_height_state(obj)
		if active_bipob_ref != null and active_bipob_ref.has_method("set_platform_height_level") and active_bipob_ref.has_method("get_grid_position"):
			var actor_cell: Vector2i = active_bipob_ref.call("get_grid_position")
			for platform_cell_variant in Array(platform.get("platform_cells", [])):
				var platform_cell := WorldObjectCatalogRef.to_world_cell(platform_cell_variant, Vector2i(-1, -1))
				if platform_cell == actor_cell:
					active_bipob_ref.call("set_platform_height_level", int(platform.get("height_level", 0)), String(platform.get("platform_id", "")))
					break
		result["success"] = true
		if current_height > previous_height:
			result["message"] = "Platform %s lifted to height %d." % [platform_id, current_height]
		elif current_height < previous_height:
			result["message"] = "Platform %s lowered to height %d." % [platform_id, current_height]
		else:
			result["message"] = "Platform %s stayed at height %d." % [platform_id, current_height]
		platform["last_activation_source"] = normalized_source
		platform["last_activation_message"] = String(result.get("message", ""))
		return result
	result["message"] = "Unknown platform type."
	return result

func _rotate_facing(facing: String, clockwise: bool) -> String:
	var dirs := ["up", "right", "down", "left"]
	var idx := dirs.find(facing)
	if idx == -1:
		idx = 0
	idx = posmod(idx + (1 if clockwise else -1), 4)
	return dirs[idx]

func _facing_to_vector(facing_dir: String) -> Vector2i:
	match facing_dir:
		"up":
			return Vector2i(0, -1)
		"down":
			return Vector2i(0, 1)
		"left":
			return Vector2i(-1, 0)
		"right":
			return Vector2i(1, 0)
	return Vector2i.ZERO

func process_platform_turn_tick() -> Array[String]:
	var events: Array[String] = []
	var platforms: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) == "platform":
			platforms.append(object_data)
	if platforms.is_empty():
		return events
	platforms.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_key := "%s|%s" % [String(a.get("platform_id", "")), String(a.get("id", ""))]
		var b_key := "%s|%s" % [String(b.get("platform_id", "")), String(b.get("id", ""))]
		return a_key < b_key
	)
	for platform in platforms:
		var mode := String(platform.get("activation_mode", "instant"))
		if mode == "timer":
			if not bool(platform.get("pending_activation", false)):
				continue
			var timer_turns := int(platform.get("timer_turns", 0))
			var timer_remaining := int(platform.get("timer_remaining_turns", 0))
			if timer_turns <= 0 and timer_remaining <= 0:
				platform["pending_activation"] = false
				continue
			var next_timer := maxi(0, int(platform.get("timer_remaining_turns", 0)) - 1)
			platform["timer_remaining_turns"] = next_timer
			if next_timer == 0:
				platform["pending_activation"] = false
				var result := _execute_platform_action(platform, "timer")
				if bool(result.get("success", false)):
					var result_message := String(result.get("message", "")).strip_edges()
					if not result_message.is_empty():
						events.append(result_message)
					else:
						events.append("%s activated (timer)." % String(platform.get("display_name", platform.get("platform_id", platform.get("id", "Platform")))))
		elif mode == "periodic":
			if not bool(platform.get("periodic_active", false)):
				continue
			var period_turns := int(platform.get("period_turns", 0))
			if period_turns <= 0:
				continue
			var next_periodic_timer := maxi(0, int(platform.get("timer_remaining_turns", 0)) - 1)
			platform["timer_remaining_turns"] = next_periodic_timer
			if next_periodic_timer == 0:
				var periodic_result := _execute_platform_action(platform, "periodic")
				platform["timer_remaining_turns"] = maxi(1, period_turns)
				if bool(periodic_result.get("success", false)):
					var periodic_message := String(periodic_result.get("message", "")).strip_edges()
					if not periodic_message.is_empty():
						events.append(periodic_message)
					else:
						events.append("%s activated (periodic)." % String(platform.get("display_name", platform.get("platform_id", platform.get("id", "Platform")))))
	return events

func process_platform_turn_tick_once(action_index: int) -> Array[String]:
	if action_index == platform_last_tick_action_index:
		return []
	platform_last_tick_action_index = action_index
	return process_platform_turn_tick()

func get_platform_last_tick_action_index() -> int:
	return platform_last_tick_action_index

func get_platform_timer_debug_summary_text() -> String:
	var lines: Array[String] = []
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) != "platform":
			continue
		lines.append("%s mode=%s pending=%s periodic=%s remaining=%d" % [String(object_data.get("platform_id", object_data.get("id", ""))), String(object_data.get("activation_mode", "instant")), str(bool(object_data.get("pending_activation", false))), str(bool(object_data.get("periodic_active", false))), int(object_data.get("timer_remaining_turns", 0))])
	return "\n".join(lines) if not lines.is_empty() else "No platforms."

func get_platform_state_summary(platform: Dictionary) -> String:
	var platform_id := String(platform.get("platform_id", platform.get("id", ""))).strip_edges()
	if platform_id.is_empty():
		platform_id = "-"
	var platform_type := String(platform.get("platform_type", "")).strip_edges()
	if platform_type.is_empty():
		platform_type = "-"
	var activation_mode := String(platform.get("activation_mode", "instant")).strip_edges()
	if activation_mode.is_empty():
		activation_mode = "instant"
	var state := String(platform.get("state", "active")).strip_edges()
	if state.is_empty():
		state = "active"
	var powered_text := str(bool(platform.get("is_powered", true))).to_lower()
	var details: Array[String] = []
	if platform_type == "lifting":
		details.append("height=%d" % int(platform.get("height_level", 0)))
	elif platform_type == "rotating":
		var rotation_direction := String(platform.get("rotation_direction", "")).strip_edges()
		if rotation_direction.is_empty():
			rotation_direction = "-"
		details.append("rotation=%s" % rotation_direction)
	if activation_mode == "timer":
		details.append("timer=%d/%d" % [int(platform.get("timer_remaining_turns", 0)), int(platform.get("timer_turns", 0))])
	elif activation_mode == "periodic":
		details.append("timer=%d/%d" % [int(platform.get("timer_remaining_turns", 0)), int(platform.get("period_turns", 0))])
	details.append("pending=%s" % str(bool(platform.get("pending_activation", false))).to_lower())
	details.append("periodic=%s" % str(bool(platform.get("periodic_active", false))).to_lower())
	var control_type := String(platform.get("control_type", "internal")).strip_edges()
	if control_type.is_empty():
		control_type = "internal"
	details.append("control=%s" % control_type)
	var terminal_id := String(platform.get("linked_terminal_id", "")).strip_edges()
	if terminal_id.is_empty():
		terminal_id = "-"
	details.append("terminal=%s" % terminal_id)
	var last_source := String(platform.get("last_activation_source", "")).strip_edges()
	var last_message := String(platform.get("last_activation_message", "")).strip_edges()
	var last_text := "-"
	if not last_source.is_empty() and not last_message.is_empty():
		last_text = "%s:%s" % [last_source, last_message]
	elif not last_message.is_empty():
		last_text = last_message
	elif not last_source.is_empty():
		last_text = last_source
	details.append("last=%s" % last_text)
	return "Platform %s | %s | mode=%s | state=%s | powered=%s | %s" % [
		platform_id,
		platform_type,
		activation_mode,
		state,
		powered_text,
		" | ".join(details)
	]

func get_platform_state_summary_table_text(filter: String = "") -> String:
	var filter_text := filter.strip_edges().to_lower()
	var platforms: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) == "platform":
			platforms.append(object_data)
	platforms.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_id := String(a.get("platform_id", a.get("id", ""))).strip_edges()
		var b_id := String(b.get("platform_id", b.get("id", ""))).strip_edges()
		if a_id == b_id:
			return String(a.get("id", "")) < String(b.get("id", ""))
		return a_id < b_id
	)
	var lines: Array[String] = ["PlatformStateSummary:"]
	for platform in platforms:
		var summary := get_platform_state_summary(platform)
		if not filter_text.is_empty() and summary.to_lower().find(filter_text) == -1:
			continue
		lines.append(summary)
	if lines.size() == 1:
		if filter_text.is_empty():
			lines.append("none")
		else:
			lines.append("none (filter=%s)" % filter_text)
	return "\n".join(lines)

func get_platform_occupant_summary(platform: Dictionary) -> String:
	var platform_id := String(platform.get("platform_id", platform.get("id", ""))).strip_edges()
	if platform_id.is_empty():
		platform_id = "-"
	var cells_count := Array(platform.get("platform_cells", [])).size()
	var occupants := get_platform_occupants(platform_id) if platform_id != "-" else {"world_objects": [], "items": [], "bipobs": []}
	var world_objects: Array = Array(occupants.get("world_objects", []))
	var items_count := Array(occupants.get("items", [])).size()
	var bipobs_count := Array(occupants.get("bipobs", [])).size()
	var is_lifting_platform := String(platform.get("platform_type", "")) == "lifting"
	var carried_world_objects := 0
	var stale_world_objects := 0
	for object_data_variant in world_objects:
		if typeof(object_data_variant) != TYPE_DICTIONARY:
			continue
		var object_data: Dictionary = object_data_variant
		var carried_id := String(object_data.get("carried_by_platform_id", "")).strip_edges()
		if carried_id == platform_id:
			carried_world_objects += 1
		elif is_lifting_platform:
			stale_world_objects += 1
	if not is_lifting_platform:
		stale_world_objects = 0
	var carry_required := str(is_lifting_platform).to_lower()
	var active_bipob_on_platform := str(_is_active_bipob_on_platform(platform)).to_lower()
	return "Occupants %s | cells=%d | world_objects=%d | items=%d | bipobs=%d | carry_required=%s | carried_world_objects=%d | stale_world_objects=%d | active_bipop_on_platform=%s" % [
		platform_id,
		cells_count,
		world_objects.size(),
		items_count,
		bipobs_count,
		carry_required,
		carried_world_objects,
		stale_world_objects,
		active_bipob_on_platform
	]

func get_platform_occupant_summary_table_text(filter: String = "") -> String:
	var filter_text := filter.strip_edges().to_lower()
	var platforms: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) == "platform":
			platforms.append(object_data)
	platforms.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_id := String(a.get("platform_id", a.get("id", ""))).strip_edges()
		var b_id := String(b.get("platform_id", b.get("id", ""))).strip_edges()
		if a_id == b_id:
			return String(a.get("id", "")) < String(b.get("id", ""))
		return a_id < b_id
	)
	var lines: Array[String] = ["PlatformOccupantSummary:"]
	for platform in platforms:
		var summary := get_platform_occupant_summary(platform)
		if not filter_text.is_empty() and summary.to_lower().find(filter_text) == -1:
			continue
		lines.append(summary)
	if lines.size() == 1:
		lines.append("none" if filter_text.is_empty() else "none (filter=%s)" % filter_text)
	return "\n".join(lines)

func validate_platform_runtime_state() -> Dictionary:
	var warnings: Array[String] = []
	var errors: Array[String] = []
	var platforms: Array[Dictionary] = []
	var terminals: Array[Dictionary] = []
	var platform_cell_owner := {}
	var platform_ids := {}
	var terminal_targets_count := {}
	for object_data in mission_world_objects:
		var group := String(object_data.get("object_group", ""))
		if group == "platform":
			platforms.append(object_data)
			continue
		if String(object_data.get("object_type", "")) == "platform_terminal":
			terminals.append(object_data)
	for platform in platforms:
		var object_id := String(platform.get("id", ""))
		var platform_id := String(platform.get("platform_id", "")).strip_edges()
		if platform_id.is_empty():
			errors.append("Platform %s has empty platform_id." % object_id)
		else:
			platform_ids[platform_id] = true
		var platform_type := String(platform.get("platform_type", ""))
		if not platform_type in ["rotating", "lifting"]:
			errors.append("Platform %s has invalid platform_type %s." % [platform_id if not platform_id.is_empty() else object_id, platform_type])
		var raw_cells: Array = platform.get("platform_cells", [])
		if raw_cells.is_empty():
			errors.append("Platform %s has empty platform_cells." % (platform_id if not platform_id.is_empty() else object_id))
		var local_cells := {}
		for cell_variant in raw_cells:
			var world_cell := WorldObjectCatalogRef.to_world_cell(cell_variant, Vector2i(-1, -1))
			if world_cell.x < 0 or world_cell.y < 0:
				errors.append("Platform %s has invalid cell %s." % [platform_id if not platform_id.is_empty() else object_id, str(world_cell)])
				continue
			if local_cells.has(world_cell):
				errors.append("Platform %s has duplicate cell %s." % [platform_id if not platform_id.is_empty() else object_id, str(world_cell)])
				continue
			local_cells[world_cell] = true
			if platform_cell_owner.has(world_cell):
				errors.append("Cell %s is claimed by multiple platforms (%s and %s)." % [str(world_cell), String(platform_cell_owner[world_cell]), platform_id])
			else:
				platform_cell_owner[world_cell] = platform_id
		var control_type := String(platform.get("control_type", ""))
		if not control_type in ["internal", "external"]:
			errors.append("Platform %s has invalid control_type %s." % [platform_id, control_type])
		var power_type := String(platform.get("power_type", ""))
		if not power_type in ["internal", "external"]:
			errors.append("Platform %s has invalid power_type %s." % [platform_id, power_type])
		if control_type == "internal":
			var local_switch := WorldObjectCatalogRef.to_world_cell(platform.get("local_switch_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
			if local_switch.x < 0 or local_switch.y < 0:
				errors.append("Platform %s has invalid local_switch_cell %s." % [platform_id, str(local_switch)])
		if platform_type == "rotating":
			var rotation_direction := String(platform.get("rotation_direction", ""))
			if not rotation_direction in ["clockwise", "counterclockwise"]:
				errors.append("Platform %s has invalid rotation_direction %s." % [platform_id, rotation_direction])
			if not platform.has("rotation_direction"):
				warnings.append("Platform %s (rotating) is missing rotation_direction." % platform_id)
		if platform_type == "lifting":
			var min_h := int(platform.get("min_height_level", 0))
			var max_h := int(platform.get("max_height_level", 0))
			if typeof(platform.get("height_level", 0)) != TYPE_INT:
				errors.append("Platform %s has non-int height_level." % platform_id)
			var height := int(platform.get("height_level", 0))
			if min_h > height or height > max_h:
				errors.append("Platform %s has invalid height range min=%d height=%d max=%d." % [platform_id, min_h, height, max_h])
			if not platform.has("height_level"):
				warnings.append("Platform %s (lifting) is missing height_level." % platform_id)
		for timer_key in ["timer_turns", "timer_remaining_turns", "period_turns"]:
			if int(platform.get(timer_key, 0)) < 0:
				errors.append("Platform %s has negative %s." % [platform_id, timer_key])
		var activation_mode := String(platform.get("activation_mode", "instant"))
		if activation_mode == "timer":
			if int(platform.get("timer_turns", 0)) <= 0:
				warnings.append("Platform %s uses timer mode with timer_turns <= 0." % platform_id)
			if bool(platform.get("pending_activation", false)) and int(platform.get("timer_remaining_turns", 0)) <= 0:
				warnings.append("Platform %s has pending timer activation with timer_remaining_turns <= 0." % platform_id)
		if activation_mode == "periodic":
			if int(platform.get("period_turns", 0)) <= 0:
				warnings.append("Platform %s uses periodic mode with period_turns <= 0." % platform_id)
			if bool(platform.get("periodic_active", false)) and int(platform.get("timer_remaining_turns", 0)) <= 0 and int(platform.get("period_turns", 0)) > 0:
				warnings.append("Platform %s has periodic_active with timer_remaining_turns <= 0." % platform_id)
		var last_source := String(platform.get("last_activation_source", ""))
		if not last_source in ["", "timer", "periodic", "terminal", "local_switch", "debug", "direct"]:
			warnings.append("Platform %s has unexpected last_activation_source %s." % [platform_id, last_source])
		if platform.has("last_activation_message") and typeof(platform.get("last_activation_message", "")) != TYPE_STRING:
			warnings.append("Platform %s has non-string last_activation_message." % platform_id)
		var has_pending_activation := bool(platform.get("pending_activation", false))
		if has_pending_activation and not activation_mode in ["timer", "permanent"]:
			warnings.append("Platform %s has pending_activation outside timer/permanent mode." % platform_id)
		var has_periodic_active := bool(platform.get("periodic_active", false))
		if has_periodic_active and activation_mode != "periodic":
			warnings.append("Platform %s has periodic_active outside periodic mode." % platform_id)
		if bool(platform.get("requires_terminal_enabled", false)):
			var linked_terminal_id := String(platform.get("linked_terminal_id", "")).strip_edges()
			if linked_terminal_id.is_empty():
				errors.append("Platform %s requires terminal but linked_terminal_id is empty." % platform_id)
			else:
				var linked_terminal := get_world_object_by_id(linked_terminal_id)
				if linked_terminal.is_empty():
					errors.append("Platform %s linked terminal %s is missing." % [platform_id, linked_terminal_id])
				else:
					if String(linked_terminal.get("terminal_type", "")) != "platform":
						errors.append("Platform %s linked terminal %s has invalid terminal_type." % [platform_id, linked_terminal_id])
					if String(linked_terminal.get("target_platform_id", "")) != platform_id:
						errors.append("Platform %s linked terminal %s targets %s." % [platform_id, linked_terminal_id, String(linked_terminal.get("target_platform_id", ""))])
	for terminal in terminals:
		var terminal_id := String(terminal.get("id", ""))
		var target_platform_id := String(terminal.get("target_platform_id", "")).strip_edges()
		if target_platform_id.is_empty():
			errors.append("Platform terminal %s has empty target_platform_id." % terminal_id)
			continue
		terminal_targets_count[target_platform_id] = int(terminal_targets_count.get(target_platform_id, 0)) + 1
		if get_platform_by_id(target_platform_id).is_empty():
			errors.append("Platform terminal %s targets missing platform %s." % [terminal_id, target_platform_id])
	for target_id in terminal_targets_count.keys():
		var count := int(terminal_targets_count[target_id])
		if count > 1:
			warnings.append("Multiple terminals (%d) target platform %s." % [count, String(target_id)])
	for object_data in mission_world_objects:
		var object_id := String(object_data.get("id", ""))
		var carried_platform_id := String(object_data.get("carried_by_platform_id", "")).strip_edges()
		if carried_platform_id.is_empty():
			var object_cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
			var object_platform := get_platform_for_cell(object_cell)
			if not object_platform.is_empty() and String(object_platform.get("platform_type", "")) == "lifting":
				var expected_platform_id := String(object_platform.get("platform_id", "")).strip_edges()
				warnings.append("Object %s stands on lifting platform %s but carried_by_platform_id is missing." % [object_id, expected_platform_id])
			continue
		if not platform_ids.has(carried_platform_id):
			warnings.append("Object %s references missing carried_by_platform_id %s." % [object_id, carried_platform_id])
			continue
		var object_cell_with_carried := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
		var current_platform := get_platform_for_cell(object_cell_with_carried)
		if current_platform.is_empty():
			warnings.append("Object %s references carried_by_platform_id %s but is not on a platform cell." % [object_id, carried_platform_id])
			continue
		var current_platform_id := String(current_platform.get("platform_id", "")).strip_edges()
		var current_platform_type := String(current_platform.get("platform_type", ""))
		if current_platform_type != "lifting":
			warnings.append("Object %s references carried_by_platform_id %s but stands on non-lifting platform %s." % [object_id, carried_platform_id, current_platform_id])
			continue
		if current_platform_id != carried_platform_id:
			warnings.append("Object %s references carried_by_platform_id %s but stands on lifting platform %s." % [object_id, carried_platform_id, current_platform_id])
		if object_data.has("platform_height_level"):
			var carried_platform := get_platform_by_id(carried_platform_id)
			if not carried_platform.is_empty():
				var platform_height := int(carried_platform.get("height_level", 0))
				var object_height := int(object_data.get("platform_height_level", 0))
				if object_height != platform_height:
					warnings.append("Object %s platform_height_level %d differs from platform %s height %d." % [object_id, object_height, carried_platform_id, platform_height])
	for platform in platforms:
		var platform_id := String(platform.get("platform_id", "")).strip_edges()
		if platform_id.is_empty():
			continue
		var occupants := get_platform_occupants(platform_id)
		var platform_cells: Array = []
		for cell_variant in Array(platform.get("platform_cells", [])):
			var platform_cell := WorldObjectCatalogRef.to_world_cell(cell_variant, Vector2i(-1, -1))
			if platform_cell.x >= 0 and platform_cell.y >= 0:
				platform_cells.append(platform_cell)
		var is_lifting_platform := String(platform.get("platform_type", "")) == "lifting"
		var platform_height := int(platform.get("height_level", 0))
		for world_object_variant in Array(occupants.get("world_objects", [])):
			if typeof(world_object_variant) != TYPE_DICTIONARY:
				continue
			var world_object: Dictionary = world_object_variant
			var world_object_id := String(world_object.get("id", ""))
			var world_object_carried_id := String(world_object.get("carried_by_platform_id", "")).strip_edges()
			if is_lifting_platform and world_object_carried_id != platform_id:
				warnings.append("World object %s is on lifting platform %s but carried_by_platform_id is stale." % [world_object_id, platform_id])
			if is_lifting_platform and int(world_object.get("platform_height_level", 0)) != platform_height:
				warnings.append("World object %s has platform_height_level mismatch on lifting platform %s." % [world_object_id, platform_id])
		for world_object in mission_world_objects:
			if String(world_object.get("carried_by_platform_id", "")).strip_edges() != platform_id:
				continue
			var object_cell := WorldObjectCatalogRef.to_world_cell(world_object.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
			if not platform_cells.has(object_cell):
				warnings.append("World object %s is carried by platform %s but is not on its cells." % [String(world_object.get("id", "")), platform_id])
		if active_bipob_ref != null and active_bipob_ref.has_method("get_grid_position"):
			var active_cell_variant: Variant = active_bipob_ref.call("get_grid_position")
			if typeof(active_cell_variant) == TYPE_VECTOR2I:
				var active_cell: Vector2i = active_cell_variant
				var active_on_platform := platform_cells.has(active_cell)
				var has_bipob_carried_getter := active_bipob_ref.has_method("get_carried_by_platform_id")
				var has_bipob_height_getter := active_bipob_ref.has_method("get_platform_height_level")
				var bipob_carried_id := ""
				if has_bipob_carried_getter:
					bipob_carried_id = String(active_bipob_ref.call("get_carried_by_platform_id")).strip_edges()
				if is_lifting_platform and active_on_platform and has_bipob_carried_getter and bipob_carried_id != platform_id:
					warnings.append("Active Bipop is on lifting platform %s but carried_by_platform_id is stale." % platform_id)
				if has_bipob_carried_getter and bipob_carried_id == platform_id and not active_on_platform:
					warnings.append("Active Bipop is carried by platform %s but is not on its cells." % platform_id)
				if is_lifting_platform and active_on_platform and has_bipob_height_getter:
					var bipob_height := int(active_bipob_ref.call("get_platform_height_level"))
					if bipob_height != platform_height:
						warnings.append("Active Bipop platform_height_level mismatch on lifting platform %s." % platform_id)
	return {
		"valid": errors.is_empty(),
		"platforms": platforms.size(),
		"terminals": terminals.size(),
		"warnings": warnings,
		"errors": errors
	}

func get_platform_runtime_validation_text() -> String:
	var validation := validate_platform_runtime_state()
	var warnings: Array[String] = validation.get("warnings", [])
	var errors: Array[String] = validation.get("errors", [])
	var lines: Array[String] = []
	lines.append("PlatformRuntimeValidation: valid=%s | platforms=%d | terminals=%d | errors=%d | warnings=%d" % [
		str(bool(validation.get("valid", false))).to_lower(),
		int(validation.get("platforms", 0)),
		int(validation.get("terminals", 0)),
		errors.size(),
		warnings.size()
	])
	for error in errors:
		lines.append("ERROR: %s" % error)
	for warning in warnings:
		lines.append("WARNING: %s" % warning)
	return "\n".join(lines)

func get_platform_runtime_table_text(filter: String = "") -> String:
	var filter_text := filter.strip_edges().to_lower()
	var platforms: Array[Dictionary] = []
	var terminals: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) == "platform":
			platforms.append(object_data)
		elif String(object_data.get("object_type", "")) == "platform_terminal":
			terminals.append(object_data)
	platforms.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_key := "%s|%s" % [String(a.get("platform_id", "")), String(a.get("id", ""))]
		var b_key := "%s|%s" % [String(b.get("platform_id", "")), String(b.get("id", ""))]
		return a_key < b_key
	)
	terminals.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("id", "")) < String(b.get("id", ""))
	)
	var lines: Array[String] = []
	lines.append("Platforms:")
	for platform in platforms:
		var platform_id := String(platform.get("platform_id", platform.get("id", "")))
		var terminal_id := String(platform.get("linked_terminal_id", "none"))
		if terminal_id.strip_edges().is_empty():
			terminal_id = "none"
		var occupants := get_platform_occupants(platform_id)
		var occ_obj := Array(occupants.get("world_objects", [])).size()
		var occ_item := Array(occupants.get("items", [])).size()
		var occ_bipob := Array(occupants.get("bipobs", [])).size()
		var mode := String(platform.get("activation_mode", "instant"))
		var timer_remaining := int(platform.get("timer_remaining_turns", 0))
		var height := "-"
		if String(platform.get("platform_type", "")) == "lifting":
			height = str(int(platform.get("height_level", 0)))
		var last_source := String(platform.get("last_activation_source", "")).strip_edges()
		var last_message := String(platform.get("last_activation_message", "")).strip_edges()
		var last_fragment := "last=-"
		if not last_source.is_empty() or not last_message.is_empty():
			last_fragment = "last=%s:%s" % [last_source if not last_source.is_empty() else "-", last_message if not last_message.is_empty() else "-"]
		var line := "%s | %s | cells=%d | %s | powered=%s | %s/%s | terminal=%s | %s | pending=%s | periodic=%s | timer_turns=%d | period_turns=%d | timer=%d | height=%s | occupants obj=%d item=%d bipob=%d" % [
			platform_id,
			String(platform.get("platform_type", "")),
			Array(platform.get("platform_cells", [])).size(),
			String(platform.get("state", "active")),
			str(bool(platform.get("is_powered", true))).to_lower(),
			String(platform.get("power_type", "internal")),
			String(platform.get("control_type", "internal")),
			terminal_id,
			mode,
			str(bool(platform.get("pending_activation", false))).to_lower(),
			str(bool(platform.get("periodic_active", false))).to_lower(),
			int(platform.get("timer_turns", 0)),
			int(platform.get("period_turns", 0)),
			timer_remaining,
			height,
			occ_obj,
			occ_item,
			occ_bipob
		]
		line = "%s | %s" % [line, last_fragment]
		var haystack := "%s %s %s %s %s" % [platform_id, String(platform.get("id", "")), String(platform.get("platform_type", "")), String(platform.get("state", "")), terminal_id]
		if filter_text.is_empty() or haystack.to_lower().find(filter_text) != -1:
			lines.append(line)
	lines.append("Terminals:")
	for terminal in terminals:
		var line := "%s | target=%s | %s | powered=%s | enabled=%s | remote=%s | interface=%s" % [
			String(terminal.get("id", "")),
			String(terminal.get("target_platform_id", "")),
			String(terminal.get("state", "active")),
			str(bool(terminal.get("is_powered", true))).to_lower(),
			str(bool(terminal.get("platform_control_enabled", true))).to_lower(),
			str(bool(terminal.get("platform_remote_control", true))).to_lower(),
			String(terminal.get("terminal_interface", "standard"))
		]
		var haystack := "%s %s %s" % [String(terminal.get("id", "")), String(terminal.get("target_platform_id", "")), String(terminal.get("state", ""))]
		if filter_text.is_empty() or haystack.to_lower().find(filter_text) != -1:
			lines.append(line)
	return "\n".join(lines)

func seed_platform_debug_scenario(origin: Vector2i = Vector2i(10, 2)) -> void:
	_place_debug_world_object("rotating_platform", "rotating_platform_debug", origin, {"platform_id":"platform_rot_a","platform_cells":[[origin.x, origin.y],[origin.x+1, origin.y]],"control_type":"external","linked_terminal_id":"platform_terminal_debug","requires_terminal_enabled":true})
	_place_debug_world_object("lifting_platform", "lifting_platform_debug", origin + Vector2i(0, 3), {"platform_id":"platform_lift_a","platform_cells":[[origin.x, origin.y+3]],"control_type":"internal","local_switch_cell":[origin.x-1, origin.y+3],"height_level":0,"min_height_level":0,"max_height_level":1})
	_place_debug_world_object("platform_terminal", "platform_terminal_debug", origin + Vector2i(-2, 0), {"target_platform_id":"platform_rot_a","platform_control_enabled":true})
	_place_debug_world_object("external_air_cooler", "platform_air_cooler_debug", origin, {"facing_dir":"right"})

func _snapshot_platform_debug_fields(object_data: Dictionary, fields: Array[String]) -> Dictionary:
	var snapshot := {}
	for field in fields:
		var had_field := object_data.has(field)
		var value = null
		if had_field:
			value = object_data[field]
			if value is Dictionary or value is Array:
				value = value.duplicate(true)
		snapshot[field] = {"had_field": had_field, "value": value}
	return snapshot

func _restore_platform_debug_fields(object_data: Dictionary, snapshot: Dictionary) -> void:
	for field in snapshot.keys():
		var field_state: Dictionary = snapshot[field]
		if bool(field_state.get("had_field", false)):
			var restored_value = field_state.get("value")
			if restored_value is Dictionary or restored_value is Array:
				restored_value = restored_value.duplicate(true)
			object_data[field] = restored_value
		else:
			object_data.erase(field)

func _find_debug_floor_cell_near_platform(platform_cells: Array, origin_cell: Vector2i) -> Vector2i:
	var platform_world_cells: Array[Vector2i] = []
	for cell in platform_cells:
		var world_cell := WorldObjectCatalogRef.to_world_cell(cell, Vector2i(-1, -1))
		if world_cell != Vector2i(-1, -1):
			platform_world_cells.append(world_cell)
	var candidate_offsets: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2),
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
	]
	for offset in candidate_offsets:
		var candidate := origin_cell + offset
		if platform_world_cells.has(candidate):
			continue
		if not get_platform_for_cell(candidate).is_empty():
			continue
		if grid_manager != null and grid_manager.has_method("is_in_bounds") and not grid_manager.is_in_bounds(candidate):
			continue
		if grid_manager != null and grid_manager.has_method("is_walkable") and not grid_manager.is_walkable(candidate):
			continue
		return candidate
	return Vector2i(-1, -1)


func _build_platform_timer_tick_debug_platform(platform_id: String, mode: String, cell: Vector2i, overrides: Dictionary = {}) -> Dictionary:
	var platform: Dictionary = {
		"id": "platform_timer_tick_debug_%s" % platform_id,
		"object_group": "platform",
		"object_type": "platform_debug_helper",
		"platform_id": platform_id,
		"platform_type": "rotating",
		"platform_cells": [[cell.x, cell.y]],
		"control_type": "internal",
		"power_type": "internal",
		"state": "active",
		"is_powered": true,
		"height_level": 0,
		"min_height_level": 0,
		"max_height_level": 1,
		"rotation_direction": "clockwise",
		"permanent_state": "active",
		"activation_mode": mode,
		"timer_turns": 0,
		"period_turns": 0,
		"timer_remaining_turns": 0,
		"pending_activation": false,
		"periodic_active": false
	}
	for key in overrides.keys():
		platform[key] = overrides[key]
	return platform

func _cleanup_platform_timer_tick_debug_state(temp_platforms: Array[Dictionary], original_platform_snapshots: Dictionary, original_last_tick_action_index: int) -> void:
	for temp_platform in temp_platforms:
		mission_world_objects.erase(temp_platform)
	for object_data in original_platform_snapshots.keys():
		_restore_platform_debug_fields(object_data, original_platform_snapshots[object_data])
	platform_last_tick_action_index = original_last_tick_action_index


func validate_platform_timer_tick_debug_scenario() -> Array[String]:
	var warnings: Array[String] = []
	var fields_to_snapshot: Array[String] = [
		"activation_mode",
		"pending_activation",
		"periodic_active",
		"timer_turns",
		"period_turns",
		"timer_remaining_turns",
		"height_level",
		"rotation_direction",
		"permanent_state",
		"platform_last_tick_action_index"
	]
	var original_last_tick_action_index := platform_last_tick_action_index
	var original_platform_snapshots := {}
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) != "platform":
			continue
		original_platform_snapshots[object_data] = _snapshot_platform_debug_fields(object_data, fields_to_snapshot)

	var temp_platforms: Array[Dictionary] = []
	temp_platforms.append(_build_platform_timer_tick_debug_platform("debug_timer_tick_timer", "timer", Vector2i(80, 80), {"pending_activation": true, "timer_turns": 2, "timer_remaining_turns": 2}))
	temp_platforms.append(_build_platform_timer_tick_debug_platform("debug_timer_tick_periodic", "periodic", Vector2i(82, 80), {"periodic_active": true, "period_turns": 2, "timer_remaining_turns": 2}))
	temp_platforms.append(_build_platform_timer_tick_debug_platform("debug_timer_tick_periodic_invalid", "periodic", Vector2i(84, 80), {"periodic_active": true, "period_turns": 0, "timer_remaining_turns": 2}))
	temp_platforms.append(_build_platform_timer_tick_debug_platform("debug_timer_tick_timer_invalid", "timer", Vector2i(86, 80), {"pending_activation": true, "timer_turns": 0, "timer_remaining_turns": 0}))
	temp_platforms.append(_build_platform_timer_tick_debug_platform("debug_timer_tick_instant", "instant", Vector2i(88, 80), {"height_level": 0}))
	temp_platforms.append(_build_platform_timer_tick_debug_platform("debug_timer_tick_permanent", "permanent", Vector2i(90, 80), {"pending_activation": true, "permanent_state": "active", "height_level": 0}))
	for temp_platform in temp_platforms:
		mission_world_objects.append(temp_platform)
	var temp_cells := {}
	var has_temp_overlap := false
	for temp_platform in temp_platforms:
		var platform_cells: Array = temp_platform.get("platform_cells", [])
		if platform_cells.is_empty():
			continue
		var world_cell := WorldObjectCatalogRef.to_world_cell(platform_cells[0], Vector2i(-1, -1))
		if world_cell == Vector2i(-1, -1):
			continue
		if temp_cells.has(world_cell):
			has_temp_overlap = true
			break
		temp_cells[world_cell] = true
	if has_temp_overlap:
		warnings.append("Timer tick debug platforms overlap cells.")

	var instant_platform := get_platform_by_id("debug_timer_tick_instant")
	var permanent_platform := get_platform_by_id("debug_timer_tick_permanent")
	var instant_height_before := int(instant_platform.get("height_level", 0)) if not instant_platform.is_empty() else 0
	var permanent_height_before := int(permanent_platform.get("height_level", 0)) if not permanent_platform.is_empty() else 0

	process_platform_turn_tick_once(100)
	process_platform_turn_tick_once(100)

	var timer_platform := get_platform_by_id("debug_timer_tick_timer")
	if timer_platform.is_empty():
		warnings.append("Missing timer validation platform.")
	else:
		if int(timer_platform.get("timer_remaining_turns", -1)) != 1:
			warnings.append("Timer platform ticked more than once for the same action index.")
	process_platform_turn_tick_once(101)
	if timer_platform.is_empty():
		timer_platform = get_platform_by_id("debug_timer_tick_timer")
	if timer_platform.is_empty():
		warnings.append("Timer platform missing after second tick.")
	else:
		if int(timer_platform.get("timer_remaining_turns", -1)) != 0:
			warnings.append("Timer platform did not complete after two distinct action indices.")
		if bool(timer_platform.get("pending_activation", true)):
			warnings.append("Timer platform pending_activation did not clear after activation.")

	var periodic_platform := get_platform_by_id("debug_timer_tick_periodic")
	if periodic_platform.is_empty():
		warnings.append("Missing periodic validation platform.")
	else:
		if int(periodic_platform.get("timer_remaining_turns", -1)) != 2:
			warnings.append("Periodic platform did not reactivate every two distinct action indices.")

	var periodic_invalid_platform := get_platform_by_id("debug_timer_tick_periodic_invalid")
	if periodic_invalid_platform.is_empty():
		warnings.append("Missing invalid periodic validation platform.")
	else:
		if int(periodic_invalid_platform.get("timer_remaining_turns", -1)) != 2:
			warnings.append("Periodic platform with period_turns <= 0 ticked unexpectedly.")

	var timer_invalid_platform := get_platform_by_id("debug_timer_tick_timer_invalid")
	if timer_invalid_platform.is_empty():
		warnings.append("Missing invalid timer validation platform.")
	else:
		if bool(timer_invalid_platform.get("pending_activation", true)):
			warnings.append("Timer platform with invalid turns did not clear pending_activation.")
		if int(timer_invalid_platform.get("timer_remaining_turns", -1)) != 0:
			warnings.append("Timer platform with invalid turns changed timer_remaining_turns unexpectedly.")

	if not instant_platform.is_empty() and int(instant_platform.get("height_level", 0)) != instant_height_before:
		warnings.append("Instant platform tick changed height unexpectedly.")
	if not permanent_platform.is_empty() and int(permanent_platform.get("height_level", 0)) != permanent_height_before:
		warnings.append("Permanent platform tick changed height unexpectedly.")

	_cleanup_platform_timer_tick_debug_state(temp_platforms, original_platform_snapshots, original_last_tick_action_index)
	return warnings

func get_platform_timer_tick_validation_text() -> String:
	var warnings := validate_platform_timer_tick_debug_scenario()
	var lines: Array[String] = ["PlatformTimerTickValidation: warnings=%d" % warnings.size()]
	for warning in warnings:
		lines.append("WARNING: %s" % warning)
	return "\n".join(lines)
func validate_platform_debug_scenario() -> Array[String]:
	var warnings: Array[String] = []
	var rotating_platform := get_platform_by_id("platform_rot_a")
	if rotating_platform.is_empty(): warnings.append("Missing rotating platform.")
	var lifting_platform := get_platform_by_id("platform_lift_a")
	if lifting_platform.is_empty(): warnings.append("Missing lifting platform.")
	var terminal := get_world_object_by_id("platform_terminal_debug")
	if terminal.is_empty() or String(terminal.get("target_platform_id", "")) != "platform_rot_a": warnings.append("Platform terminal link invalid.")
	var air_cooler := get_world_object_by_id("platform_air_cooler_debug")
	if air_cooler.is_empty():
		warnings.append("Missing air cooler on rotating platform.")
	var old_requires_terminal_enabled := bool(rotating_platform.get("requires_terminal_enabled", false))
	var air_cooler_snapshot := {}
	var lifting_platform_snapshot := {}
	var terminal_snapshot := {}
	var rotating_platform_snapshot := {}
	if not air_cooler.is_empty():
		air_cooler_snapshot = _snapshot_platform_debug_fields(air_cooler, ["facing_dir"])
	if not lifting_platform.is_empty():
		lifting_platform_snapshot = _snapshot_platform_debug_fields(lifting_platform, ["height_level", "carried_by_platform_id"])
	if not terminal.is_empty():
		terminal_snapshot = _snapshot_platform_debug_fields(terminal, ["state", "is_powered", "platform_control_enabled"])
	if not rotating_platform.is_empty():
		rotating_platform_snapshot = _snapshot_platform_debug_fields(rotating_platform, ["timer_remaining_turns", "pending_activation", "periodic_active", "requires_terminal_enabled", "permanent_state", "activation_mode", "timer_turns", "period_turns", "rotation_direction"])
	if not rotating_platform.is_empty() and not air_cooler.is_empty():
		var before_facing := String(air_cooler.get("facing_dir", ""))
		var rotate_result := activate_platform_by_id("platform_rot_a", "debug_validation")
		if not bool(rotate_result.get("success", false)):
			warnings.append("Rotating platform activation failed during validation.")
		var after_facing := String(air_cooler.get("facing_dir", ""))
		if before_facing == after_facing:
			warnings.append("Rotating platform action did not rotate air cooler.")
	if not lifting_platform.is_empty():
		var before_height := int(lifting_platform.get("height_level", 0))
		var lift_result := activate_platform_by_id("platform_lift_a", "debug_validation")
		if not bool(lift_result.get("success", false)):
			warnings.append("Lifting platform activation failed during validation.")
		var after_height := int(lifting_platform.get("height_level", before_height))
		if before_height == after_height:
			warnings.append("Lifting platform action did not toggle height_level.")
		var switch_cell := WorldObjectCatalogRef.to_world_cell(lifting_platform.get("local_switch_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
		var wrong_access := can_bipob_access_platform_switch(lifting_platform, switch_cell + Vector2i(2, 0), "left")
		if wrong_access:
			warnings.append("Internal switch access returned true from wrong position.")
		var actor_cell := switch_cell - _facing_to_vector(String(lifting_platform.get("local_switch_facing_dir", "right")))
		var right_access := can_bipob_access_platform_switch(lifting_platform, actor_cell, String(lifting_platform.get("local_switch_facing_dir", "right")))
		if not right_access:
			warnings.append("Internal switch access returned false from valid position.")
	if not rotating_platform.is_empty() and not terminal.is_empty():
		rotating_platform["requires_terminal_enabled"] = true
		terminal["platform_control_enabled"] = false
		var blocked := activate_platform_by_id("platform_rot_a", "debug_validation_block")
		if bool(blocked.get("success", false)):
			warnings.append("Terminal unavailable did not block rotating platform activation.")
	if not air_cooler.is_empty():
		_restore_platform_debug_fields(air_cooler, air_cooler_snapshot)
	if not lifting_platform.is_empty():
		_restore_platform_debug_fields(lifting_platform, lifting_platform_snapshot)
	if not terminal.is_empty():
		_restore_platform_debug_fields(terminal, terminal_snapshot)
	if not rotating_platform.is_empty():
		rotating_platform["requires_terminal_enabled"] = old_requires_terminal_enabled
		_restore_platform_debug_fields(rotating_platform, rotating_platform_snapshot)
		if rotating_platform.get("requires_terminal_enabled", false) != old_requires_terminal_enabled:
			warnings.append("Validation restore mismatch: rotating platform terminal gate flag.")
	if debug_platform_scenario_enabled:
		warnings.append_array(validate_platform_height_gating_debug_scenario())
		warnings.append_array(validate_platform_timer_tick_debug_scenario())
	refresh_world_cooling_received()
	return warnings

func validate_platform_height_gating_debug_scenario() -> Array[String]:
	var warnings: Array[String] = []
	var lifting_platform := get_platform_by_id("platform_lift_a")
	if lifting_platform.is_empty():
		warnings.append("Missing lifting platform for height gating validation.")
		return warnings
	var platform_cells: Array = Array(lifting_platform.get("platform_cells", []))
	if platform_cells.is_empty():
		warnings.append("Lifting platform has no platform cells.")
		return warnings
	var platform_cell := WorldObjectCatalogRef.to_world_cell(platform_cells[0], Vector2i(-1, -1))
	if platform_cell == Vector2i(-1, -1):
		warnings.append("Lifting platform first platform cell is invalid.")
		return warnings
	var floor_cell := _find_debug_floor_cell_near_platform(platform_cells, platform_cell)
	if floor_cell == Vector2i(-1, -1):
		warnings.append("No normal floor cell found near lifting platform for height gating validation.")
		return warnings
	var same_height_platform_cell := platform_cell
	if platform_cells.size() > 1:
		same_height_platform_cell = WorldObjectCatalogRef.to_world_cell(platform_cells[1], platform_cell)
	var original_height := int(lifting_platform.get("height_level", 0))
	var platform_snapshot := _snapshot_platform_debug_fields(lifting_platform, ["height_level"])
	lifting_platform["height_level"] = original_height
	if get_cell_height_level(platform_cell) != original_height:
		warnings.append("Platform cell height does not match platform.height_level.")
	if get_cell_height_level(floor_cell) != 0:
		warnings.append("Normal floor cell did not resolve to height 0.")
	lifting_platform["height_level"] = 1
	if can_move_between_height_levels(platform_cell, floor_cell, null):
		warnings.append("Height gating failed: platform->floor movement allowed on mismatch (1->0).")
	if can_move_between_height_levels(floor_cell, platform_cell, null):
		warnings.append("Height gating failed: floor->platform movement allowed on mismatch (0->1).")
	if not can_move_between_height_levels(platform_cell, same_height_platform_cell, null):
		warnings.append("Height gating failed: movement between same-height platform cells blocked.")
	var candidate_object: Dictionary = {}
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) == "platform":
			continue
		if String(object_data.get("object_group", "")) == "item":
			continue
		candidate_object = object_data
		break
	if candidate_object.is_empty():
		warnings.append("No world object available for platform height validation.")
		_restore_platform_debug_fields(lifting_platform, platform_snapshot)
		return warnings
	var object_snapshot := _snapshot_platform_debug_fields(candidate_object, ["position", "platform_height_level", "carried_by_platform_id"])
	candidate_object["position"] = platform_cell
	refresh_world_object_platform_height_state(candidate_object)
	var carried_platform_id := String(candidate_object.get("carried_by_platform_id", "")).strip_edges()
	if carried_platform_id != String(lifting_platform.get("platform_id", "")).strip_edges():
		warnings.append("Object on lifting platform did not receive matching carried_by_platform_id.")
	if int(candidate_object.get("platform_height_level", -1)) != int(lifting_platform.get("height_level", -1)):
		warnings.append("Object platform height on lifting platform does not match platform height.")
	candidate_object["position"] = floor_cell
	refresh_world_object_platform_height_state(candidate_object)
	if String(candidate_object.get("carried_by_platform_id", "")).strip_edges() != "":
		warnings.append("Object moved off lifting platform kept carried_by_platform_id.")
	candidate_object["position"] = platform_cell
	refresh_world_object_platform_height_state(candidate_object)
	if String(candidate_object.get("carried_by_platform_id", "")).strip_edges() != String(lifting_platform.get("platform_id", "")).strip_edges():
		warnings.append("Object moved onto lifting platform did not get carried_by_platform_id.")
	_restore_platform_debug_fields(candidate_object, object_snapshot)
	_restore_platform_debug_fields(lifting_platform, platform_snapshot)
	return warnings

func get_platform_height_gating_validation_text() -> String:
	var warnings := validate_platform_height_gating_debug_scenario()
	var lines: Array[String] = ["PlatformHeightGatingValidation: warnings=%d" % warnings.size()]
	for warning in warnings:
		lines.append("WARNING: %s" % warning)
	return "\n".join(lines)

func get_terminal_hack_requirements(terminal_id: String) -> Dictionary:
	var terminal := get_world_object_by_id(terminal_id)
	var required_connector_level := int(terminal.get("required_connector_level", max(0, int(terminal.get("terminal_class", 1)) - 1))) if not terminal.is_empty() else 0
	var required_processor_level := int(terminal.get("required_processor_level", max(0, int(terminal.get("terminal_class", 1)) - 1))) if not terminal.is_empty() else 0
	var capabilities := get_actor_capability_levels()
	var available_connector_level := int(capabilities.get("connector_level", 0))
	var available_processor_level := int(capabilities.get("processor_level", 0))
	var reasons: Array[String] = []
	if terminal.is_empty():
		reasons.append("terminal_missing")
	else:
		if not _is_terminal_powered_for_interaction(terminal):
			reasons.append("terminal_unpowered")
		if bool(terminal.get("damaged", false)) or String(terminal.get("state", "")).to_lower() == "damaged":
			reasons.append("terminal_damaged")
	if available_connector_level < required_connector_level:
		reasons.append("connector_level_too_low")
	if available_processor_level < required_processor_level:
		reasons.append("processor_level_too_low")
	var heat_preview := {"would_overheat": false, "current_heat": 0, "hack_heat": 0, "overheat_threshold": 0, "projected_heat": 0}
	if not terminal.is_empty():
		var current_heat := int(terminal.get("current_heat", terminal.get("working_heat", 0)))
		var hack_heat := int(terminal.get("hack_heat", 0))
		var threshold := int(terminal.get("overheat_threshold", 99999))
		var projected := current_heat + hack_heat
		heat_preview = {"would_overheat": projected > threshold, "current_heat": current_heat, "hack_heat": hack_heat, "overheat_threshold": threshold, "projected_heat": projected}
	if bool(heat_preview.get("would_overheat", false)):
		reasons.append("hack_would_overheat")
	if reasons.is_empty():
		reasons.append("ok")
	return {"can_hack": reasons.size() == 1 and reasons[0] == "ok", "terminal_id": terminal_id, "required_connector_level": required_connector_level, "required_processor_level": required_processor_level, "available_connector_level": available_connector_level, "available_processor_level": available_processor_level, "reasons": reasons, "heat_preview": heat_preview}

func get_terminal_action_availability(terminal_id: String, action: String = "") -> Dictionary:
	var report := {"available": false, "terminal_id": terminal_id, "action": action, "reasons": [], "requirements": {}, "state": "", "is_powered": true}
	var terminal := get_world_object_by_id(terminal_id)
	if terminal.is_empty():
		report["reasons"] = ["terminal_missing"]
		return report
	if not _is_terminal_object(terminal):
		report["reasons"] = ["not_terminal"]
		return report
	var state := String(terminal.get("state", "active")).strip_edges().to_lower()
	report["state"] = state
	var powered := bool(terminal.get("is_powered", true)) if terminal.has("is_powered") else true
	report["is_powered"] = powered
	var reasons: Array[String] = []
	if bool(terminal.get("damaged", false)) or state == "damaged": reasons.append("terminal_damaged")
	if bool(terminal.get("broken", false)) or state == "broken": reasons.append("terminal_broken")
	if bool(terminal.get("destroyed", false)) or state == "destroyed": reasons.append("terminal_destroyed")
	if state == "overheated": reasons.append("terminal_overheated")
	if state in ["unpowered", "disabled"] or (terminal.has("is_powered") and not powered): reasons.append("terminal_unpowered")
	var req: Dictionary = get_terminal_hack_requirements(terminal_id) if action == "hack" else {}
	report["requirements"] = req
	if action == "hack":
		if req.get("reasons", []).has("connector_level_too_low"): reasons.append("connector_level_too_low")
		if req.get("reasons", []).has("processor_level_too_low"): reasons.append("processor_level_too_low")
	if reasons.is_empty():
		report["available"] = true
		report["reasons"] = ["ok"]
	else:
		report["reasons"] = reasons
	return report

func attempt_terminal_hack(terminal_id: String) -> Dictionary:
	var terminal := get_world_object_by_id(terminal_id)
	var before := String(terminal.get("state", "")) if not terminal.is_empty() else ""
	var req: Dictionary = get_terminal_hack_requirements(terminal_id)
	if not bool(req.get("can_hack", false)):
		return {"success": false, "terminal_id": terminal_id, "reasons": req.get("reasons", []), "state_before": before, "state_after": before, "heat_report": req.get("heat_preview", {})}
	if String(terminal.get("state", "")) == "hacked":
		return {"success": false, "terminal_id": terminal_id, "reasons": ["already_hacked"], "state_before": before, "state_after": before, "heat_report": req.get("heat_preview", {})}
	terminal["state"] = "hacked"
	terminal["hacked"] = true
	terminal["hack_attempts"] = int(terminal.get("hack_attempts", 0)) + 1
	return {"success": true, "terminal_id": terminal_id, "reasons": ["ok"], "state_before": before, "state_after": "hacked", "heat_report": req.get("heat_preview", {})}


func get_terminal_control_targets(terminal_id: String) -> Array[Dictionary]:
	var terminal := get_world_object_by_id(terminal_id)
	if terminal.is_empty(): return []
	var out: Array[Dictionary] = []
	for key in ["target_door_id","target_platform_id","target_object_id","linked_object_id"]:
		var tid := String(terminal.get(key, "")).strip_edges()
		if tid != "": out.append({"target_id":tid, "source":key})
	for tidv in Array(terminal.get("controlled_object_ids", [])):
		var tid := String(tidv).strip_edges()
		if tid != "": out.append({"target_id":tid, "source":"controlled_object_ids"})
	return out

func execute_terminal_control_action(terminal_id: String, target_id: String = "", action: String = "") -> Dictionary:
	var avail := get_terminal_action_availability(terminal_id, action)
	if not bool(avail.get("available", false)): return {"success":false, "terminal_id":terminal_id, "target_id":target_id, "action":action, "reasons":avail.get("reasons", [])}
	var targets := get_terminal_control_targets(terminal_id)
	var allowed := target_id.strip_edges().is_empty()
	for t in targets:
		if String(t.get("target_id", "")) == target_id: allowed = true
	if not allowed: return {"success":false, "terminal_id":terminal_id, "target_id":target_id, "action":action, "reasons":["target_invalid"]}
	var target := get_world_object_by_id(target_id) if target_id != "" else {}
	if action == "open_door" and not target.is_empty(): target["state"] = "open"; target["is_open"] = true; target["is_locked"] = false; target["locked"] = false; target["blocks_movement"] = false
	elif action == "close_door" and not target.is_empty(): target["state"] = "closed"; target["is_open"] = false; target["blocks_movement"] = true
	elif action == "unlock_door" and not target.is_empty(): target["is_locked"] = false; target["locked"] = false
	elif action == "lock_door" and not target.is_empty(): target["is_locked"] = true; target["locked"] = true
	elif action in ["activate_platform","toggle_platform","rotate_platform"] and not target.is_empty():
		activate_platform_by_id(String(target.get("platform_id", target_id)), "terminal")
	elif action == "enable_cooling":
		apply_cooling_application()
	elif action == "reset_source_overheat":
		execute_power_source_recovery_apply()
	return {"success":true, "terminal_id":terminal_id, "target_id":target_id, "action":action, "reasons":["ok"]}

func get_door_access_state(door_id: String) -> Dictionary:
	var door := get_world_object_by_id(door_id)
	if door.is_empty(): return {"door_id":door_id, "can_open":false, "can_unlock":false, "is_locked":true, "is_open":false, "is_powered":false, "reasons":["door_missing"], "lock_type":"", "door_class":0}
	var lock_type := String(door.get("lock_type", "none"))
	var is_locked := bool(door.get("is_locked", door.get("locked", lock_type != "none")))
	var is_open := String(door.get("state", "closed")) == "open"
	var powered := bool(door.get("is_powered", true))
	var reasons: Array[String] = []
	if String(door.get("state", "")).to_lower() == "destroyed": reasons.append("door_destroyed")
	elif is_locked: reasons.append("locked")
	else: reasons.append("ok")
	return {"door_id":door_id, "can_open":reasons.has("ok"), "can_unlock":is_locked, "is_locked":is_locked, "is_open":is_open, "is_powered":powered, "reasons":reasons, "lock_type":lock_type, "door_class":int(door.get("door_class", 1))}

func can_use_access_item_on_door(item_id: String, door_id: String) -> Dictionary:
	var door := get_world_object_by_id(door_id)
	var item := get_world_object_by_id(item_id)
	if item.is_empty(): return {"success":false, "item_id":item_id, "door_id":door_id, "reasons":["item_missing"]}
	if door.is_empty(): return {"success":false, "item_id":item_id, "door_id":door_id, "reasons":["door_missing"]}
	var lock_type := String(door.get("lock_type", "none"))
	var digital_state := String(item.get("digital_state", ""))
	if item_id.find("damaged") != -1 or digital_state == "damaged": return {"success":false, "item_id":item_id, "door_id":door_id, "reasons":["digital_key_damaged"]}
	if item_id.find("encrypted") != -1 or digital_state == "encrypted": return {"success":false, "item_id":item_id, "door_id":door_id, "reasons":["digital_key_encrypted"]}
	if lock_type == "mechanical_key" and String(item.get("key_kind", "")) != "mechanical": return {"success":false, "item_id":item_id, "door_id":door_id, "reasons":["wrong_key_type"]}
	return {"success":true, "item_id":item_id, "door_id":door_id, "reasons":["ok"]}

func use_access_item_on_door(item_id: String, door_id: String) -> Dictionary:
	var gate := can_use_access_item_on_door(item_id, door_id)
	var door := get_world_object_by_id(door_id)
	var before := String(door.get("state", "")) if not door.is_empty() else ""
	if not bool(gate.get("success", false)): return {"success":false, "item_id":item_id, "door_id":door_id, "reasons":gate.get("reasons", []), "door_state_before":before, "door_state_after":before, "consumed":false}
	door["state"] = "open"; door["is_open"] = true; door["is_locked"] = false; door["locked"] = false; door["blocks_movement"] = false
	return {"success":true, "item_id":item_id, "door_id":door_id, "reasons":["ok"], "door_state_before":before, "door_state_after":"open", "consumed":false}

func use_inventory_item_on_world_object(item_id: String, target_id: String, action: String = "") -> Dictionary:
	var out := {"success": false, "item_id": item_id, "target_id": target_id, "action": action, "reasons": [], "consumed": false, "target_state_before": "", "target_state_after": "", "side_effects": {}}
	var item := get_world_object_by_id(item_id)
	var target := get_world_object_by_id(target_id)
	if item.is_empty():
		out["reasons"] = ["item_missing"]
		return out
	if target.is_empty():
		out["reasons"] = ["target_missing"]
		return out
	var item_type := String(item.get("item_type", item.get("object_type", item_id)))
	var before := String(target.get("state", ""))
	out["target_state_before"] = before
	if item_type == "fuse" and String(target.get("object_type", "")) in ["fuse_box_empty", "fuse_box_installed"]:
		if String(target.get("state", "")) == "installed":
			out["reasons"] = ["fuse_already_installed"]
			return out
		target["state"] = "installed"
		out["side_effects"] = apply_power_network_after_explicit_power_event("fuse_inserted", String(target.get("power_network_id", "")))
		out["success"] = true
		out["consumed"] = bool(item.get("consumable", true))
		out["reasons"] = ["ok"]
	elif item_type == "repair_kit":
		if bool(target.get("destroyed", false)) or String(target.get("state", "")) == "destroyed":
			out["reasons"] = ["target_destroyed"]
			return out
		if not (bool(target.get("damaged", false)) or bool(target.get("broken", false)) or String(target.get("state", "")) in ["damaged", "broken"]):
			out["reasons"] = ["already_repaired"]
			return out
		target["damaged"] = false
		target["broken"] = false
		if String(target.get("state", "")) in ["damaged", "broken"]:
			target["state"] = "active"
		if String(target.get("object_type", "")) == "power_cable":
			target["disconnected"] = true
			target["connected"] = false
		out["success"] = true
		out["consumed"] = bool(item.get("consumable", true))
		out["reasons"] = ["ok"]
	elif item_type == "power_cable_reel":
		var report := connect_cable_reel_to_target(item_id, target_id)
		out["success"] = bool(report.get("success", false))
		out["reasons"] = report.get("reasons", ["cable_connect_failed"])
		out["side_effects"] = report
	elif item_type in ["mechanical_keycard", "digital_key", "access_code"]:
		var access_report := use_access_item_on_door(item_id, target_id)
		out["success"] = bool(access_report.get("success", false))
		out["reasons"] = access_report.get("reasons", ["access_denied"])
		out["side_effects"] = access_report
	else:
		out["reasons"] = ["wrong_item_type"]
		return out
	out["target_state_after"] = String(target.get("state", before))
	return out

func get_door_debug_report_text(door_id: String = "") -> String:
	var ids: Array[String] = []
	if door_id.strip_edges() != "": ids.append(door_id)
	else:
		for obj in mission_world_objects:
			if String(obj.get("object_group", "")) == "door": ids.append(String(obj.get("id", "")))
	var lines: Array[String] = []
	for id in ids:
		var st := get_door_access_state(id)
		lines.append("%s | lock=%s | locked=%s | powered=%s | reasons=%s" % [id, String(st.get("lock_type", "")), str(bool(st.get("is_locked", false))), str(bool(st.get("is_powered", true))), ",".join(Array(st.get("reasons", [])))])
	return "\n".join(lines)

func validate_terminal_and_door_runtime() -> Array[String]:
	var warnings: Array[String] = []
	var base_size := mission_world_objects.size()
	var world_snapshot := get_world_object_runtime_state()
	var temp_ids: Array[String] = []
	var terminal_id := "temp_validation_terminal"
	var linked_door_id := "temp_validation_door_linked"
	var unlinked_door_id := "temp_validation_door_unlinked"
	var mechanical_door_id := "temp_validation_door_mechanical"
	var digital_door_id := "temp_validation_door_digital"
	var terminal := {"id": terminal_id, "object_group": "terminal", "object_type": "terminal", "position": Vector2i(100, 100), "state": "active", "is_powered": true, "required_connector_level": 0, "required_processor_level": 0, "target_door_id": linked_door_id}
	var linked_door := {"id": linked_door_id, "object_group": "door", "object_type": "door", "position": Vector2i(101, 100), "state": "closed", "is_locked": true, "lock_type": "terminal_lock", "is_powered": true}
	var unlinked_door := {"id": unlinked_door_id, "object_group": "door", "object_type": "door", "position": Vector2i(102, 100), "state": "closed", "is_locked": true, "lock_type": "terminal_lock", "is_powered": true}
	var mechanical_door := {"id": mechanical_door_id, "object_group": "door", "object_type": "door", "position": Vector2i(103, 100), "state": "closed", "is_locked": true, "lock_type": "mechanical_key", "is_powered": true}
	var digital_door := {"id": digital_door_id, "object_group": "door", "object_type": "door", "position": Vector2i(104, 100), "state": "closed", "is_locked": true, "lock_type": "access_code", "is_powered": true}
	for obj in [terminal, linked_door, unlinked_door, mechanical_door, digital_door]:
		mission_world_objects.append(obj)
		world_objects_by_cell[Vector2i(obj.get("position", Vector2i(-1, -1)))] = obj
		temp_ids.append(String(obj.get("id", "")))
	var av := get_terminal_action_availability(terminal_id, "hack")
	if not bool(av.get("available", false)): warnings.append("active_powered_terminal_unavailable")
	terminal["is_powered"] = false
	var unpowered := get_terminal_action_availability(terminal_id, "hack")
	if not Array(unpowered.get("reasons", [])).has("terminal_unpowered"): warnings.append("terminal_unpowered_reason_missing")
	terminal["is_powered"] = true
	terminal["damaged"] = true
	if not Array(get_terminal_action_availability(terminal_id, "hack").get("reasons", [])).has("terminal_damaged"): warnings.append("terminal_damaged_reason_missing")
	terminal["damaged"] = false
	terminal["required_connector_level"] = 1
	if not Array(get_terminal_action_availability(terminal_id, "hack").get("reasons", [])).has("connector_level_too_low"): warnings.append("connector_level_gate_missing")
	terminal["required_connector_level"] = 0
	terminal["required_processor_level"] = 1
	if not Array(get_terminal_action_availability(terminal_id, "hack").get("reasons", [])).has("processor_level_too_low"): warnings.append("processor_level_gate_missing")
	terminal["required_processor_level"] = 0
	var before_preview := str(get_world_object_runtime_state().get(terminal_id, {}))
	get_terminal_hack_requirements(terminal_id)
	if str(get_world_object_runtime_state().get(terminal_id, {})) != before_preview: warnings.append("terminal_hack_preview_mutated_state")
	terminal["required_connector_level"] = 2
	var before_fail := str(get_world_object_runtime_state().get(terminal_id, {}))
	attempt_terminal_hack(terminal_id)
	if str(get_world_object_runtime_state().get(terminal_id, {})) != before_fail: warnings.append("failed_hack_mutated_state")
	terminal["required_connector_level"] = 0
	terminal["state"] = "hacked"
	if not Array(attempt_terminal_hack(terminal_id).get("reasons", [])).has("already_hacked"): warnings.append("already_hacked_reason_missing")
	terminal["state"] = "active"
	if not bool(execute_terminal_control_action(terminal_id, linked_door_id, "unlock_door").get("success", false)): warnings.append("linked_door_control_failed")
	if bool(execute_terminal_control_action(terminal_id, unlinked_door_id, "unlock_door").get("success", false)): warnings.append("unlinked_door_control_should_fail")
	var mechanical_key := {"id":"temp_validation_mechanical_key", "object_group":"item", "object_type":"item", "position":Vector2i(105, 100), "key_kind":"mechanical", "item_type":"mechanical_keycard"}
	var wrong_key := {"id":"temp_validation_wrong_key", "object_group":"item", "object_type":"item", "position":Vector2i(106, 100), "item_type":"digital_key"}
	var damaged_key := {"id":"temp_validation_damaged_key", "object_group":"item", "object_type":"item", "position":Vector2i(107, 100), "item_type":"digital_key", "digital_state":"damaged"}
	var encrypted_key := {"id":"temp_validation_encrypted_key", "object_group":"item", "object_type":"item", "position":Vector2i(108, 100), "item_type":"digital_key", "digital_state":"encrypted"}
	var good_digital := {"id":"temp_validation_good_digital", "object_group":"item", "object_type":"item", "position":Vector2i(109, 100), "item_type":"access_code"}
	for key_obj in [mechanical_key, wrong_key, damaged_key, encrypted_key, good_digital]:
		mission_world_objects.append(key_obj); world_objects_by_cell[Vector2i(key_obj.get("position", Vector2i(-1, -1)))] = key_obj; temp_ids.append(String(key_obj.get("id", "")))
	if not bool(can_use_access_item_on_door(mechanical_key["id"], mechanical_door_id).get("success", false)): warnings.append("mechanical_key_gate_failed")
	var wrong_before := str(get_world_object_runtime_state().get(mechanical_door_id, {}))
	if bool(use_access_item_on_door(wrong_key["id"], mechanical_door_id).get("success", false)): warnings.append("wrong_key_should_fail")
	if str(get_world_object_runtime_state().get(mechanical_door_id, {})) != wrong_before: warnings.append("wrong_key_mutated_door")
	if not Array(use_access_item_on_door(damaged_key["id"], digital_door_id).get("reasons", [])).has("digital_key_damaged"): warnings.append("digital_key_damaged_missing")
	if not Array(use_access_item_on_door(encrypted_key["id"], digital_door_id).get("reasons", [])).has("digital_key_encrypted"): warnings.append("digital_key_encrypted_missing")
	if not bool(use_access_item_on_door(good_digital["id"], digital_door_id).get("success", false)): warnings.append("digital_access_open_failed")
	var door_debug_before := str(get_world_object_runtime_state())
	get_door_debug_report_text()
	if str(get_world_object_runtime_state()) != door_debug_before: warnings.append("door_debug_mutated_state")
	var runtime_snap := get_world_object_runtime_state()
	if not Dictionary(runtime_snap.get(terminal_id, {})).has("state"): warnings.append("runtime_snapshot_terminal_state_missing")
	if not Dictionary(runtime_snap.get(digital_door_id, {})).has("is_locked"): warnings.append("runtime_snapshot_door_lock_missing")
	for i in range(mission_world_objects.size() - 1, -1, -1):
		var object_id := String(mission_world_objects[i].get("id", "")).strip_edges()
		if temp_ids.has(object_id):
			world_objects_by_cell.erase(WorldObjectCatalogRef.to_world_cell(mission_world_objects[i].get("position", Vector2i(-1, -1)), Vector2i(-1, -1)))
			mission_world_objects.remove_at(i)
	apply_world_object_runtime_state(world_snapshot)
	if mission_world_objects.size() != base_size:
		warnings.append("terminal_door_cleanup_world_size_changed")
	return warnings

func get_terminal_and_door_validation_text() -> String:
	var warnings := validate_terminal_and_door_runtime()
	return "TerminalDoorValidation: warnings=%d" % warnings.size()

func get_scan_result_for_object(object_id: String, scan_mode: String = "basic") -> Dictionary:
	var object_data := get_world_object_by_id(object_id)
	if object_data.is_empty():
		return {"ok": false, "reason": "object_missing", "scan_mode": scan_mode}
	if not is_world_object_visible_to_player(object_data, scan_mode):
		return {"ok": false, "reason": "not_visible", "scan_mode": scan_mode}
	var result := {"ok": true, "scan_mode": scan_mode, "object_id": object_id, "object_type": String(object_data.get("object_type", "")), "state": String(object_data.get("state", ""))}
	if scan_mode in ["diagnostic", "power", "platform"]:
		result["power_reason"] = String(object_data.get("power_unavailable_reason", ""))
	if scan_mode in ["diagnostic", "cooling"]:
		result["cooling_received"] = int(object_data.get("cooling_received", 0))
		result["cooling_source_ids"] = object_data.get("cooling_source_ids", [])
	if scan_mode in ["diagnostic", "platform"] and String(object_data.get("object_group", "")) == "platform":
		result["platform"] = get_platform_action_availability(String(object_data.get("platform_id", "")), "activate")
	if scan_mode == "xray":
		result["xray_objects"] = get_xray_visible_objects(String(object_data.get("power_network_id", "")))
	return result

func get_scan_result_for_cell(cell: Vector2i, scan_mode: String = "basic") -> Dictionary:
	var object_data := get_world_object_at_cell(cell)
	if object_data.is_empty():
		return {"ok": true, "scan_mode": scan_mode, "cell": [cell.x, cell.y], "object": {}}
	return get_scan_result_for_object(String(object_data.get("id", "")), scan_mode)

func get_scan_text_for_object(object_id: String, scan_mode: String = "basic") -> String:
	return JSON.stringify(get_scan_result_for_object(object_id, scan_mode))

func validate_platform_scan_visibility_runtime() -> Array[String]:
	var warnings: Array[String] = []
	var platform := get_platform_by_id("platform_lift_a")
	if not platform.is_empty():
		var av := get_platform_action_availability(String(platform.get("platform_id", "")), "activate")
		if not av.has("available"):
			warnings.append("platform availability helper missing fields")
	var snapshot_a := str(get_world_object_runtime_state())
	get_scan_result_for_cell(Vector2i.ZERO, "basic")
	var snapshot_b := str(get_world_object_runtime_state())
	if snapshot_a != snapshot_b:
		warnings.append("scan/report helpers are not read-only")
	var hidden_cable := {"id":"temp_hidden_cable", "object_group":"cable", "object_type":"power_cable", "position":Vector2i(140, 100), "hidden":true, "hidden_cable":true, "visible_with_xray":true}
	mission_world_objects.append(hidden_cable)
	world_objects_by_cell[Vector2i(140, 100)] = hidden_cable
	var basic_visible := is_world_object_visible_to_player(hidden_cable, "basic")
	var xray_result := get_scan_result_for_object("temp_hidden_cable", "xray")
	if basic_visible:
		warnings.append("basic_scan_should_hide_hidden_cable")
	if not bool(xray_result.get("ok", false)):
		warnings.append("xray_scan_should_report_hidden_cable")
	var reveal_before := str(get_world_object_runtime_state().get("temp_hidden_cable", {}))
	reveal_xray_objects("")
	var reveal_after: Dictionary = get_world_object_runtime_state().get("temp_hidden_cable", {})
	if not bool(reveal_after.get("revealed", false)) or not bool(reveal_after.get("discovered", false)):
		warnings.append("reveal_xray_objects_did_not_mark_revealed_discovered")
	if reveal_before == str(reveal_after):
		warnings.append("reveal_xray_objects_no_effect")
	for i in range(mission_world_objects.size() - 1, -1, -1):
		if String(mission_world_objects[i].get("id", "")) == "temp_hidden_cable":
			world_objects_by_cell.erase(WorldObjectCatalogRef.to_world_cell(mission_world_objects[i].get("position", Vector2i(-1, -1)), Vector2i(-1, -1)))
			mission_world_objects.remove_at(i)
	return warnings

func get_platform_scan_visibility_validation_text() -> String:
	var warnings := validate_platform_scan_visibility_runtime()
	if warnings.is_empty():
		return "PlatformScanVisibilityValidation: ok"
	return "PlatformScanVisibilityValidation:\n- " + "\n- ".join(warnings)

func validate_inventory_tools_modules_runtime() -> Array[String]:
	var warnings: Array[String] = []
	var inventory_snapshot := runtime_inventory_state.duplicate(true)
	var world_snapshot := get_world_object_runtime_state()
	var temp_ids: Array[String] = []
	var caps := get_actor_capability_levels()
	if not caps.has("manipulator_level") or not caps.has("connector_level") or not caps.has("processor_level"):
		warnings.append("capability_defaults_missing")
	var req_obj := {"id":"temp_req_obj", "object_group":"item", "object_type":"item", "position":Vector2i(120, 100), "required_manipulator_level":1, "required_connector_level":1, "required_processor_level":1}
	mission_world_objects.append(req_obj); world_objects_by_cell[Vector2i(120, 100)] = req_obj; temp_ids.append("temp_req_obj")
	var req := check_world_object_requirements("temp_req_obj", "use")
	for r in ["manipulator_level_too_low","connector_level_too_low","processor_level_too_low"]:
		if not Array(req.get("reasons", [])).has(r): warnings.append("requirements_missing_%s" % r)
	var physical_item := {"id":"temp_item_physical", "object_group":"item", "object_type":"item", "position":Vector2i(121, 100), "item_type":"fuse", "item_form":"physical", "can_pickup":true}
	var digital_item := {"id":"temp_item_digital", "object_group":"item", "object_type":"item", "position":Vector2i(122, 100), "item_form":"digital", "can_place_in_digital_buffer":true}
	var digital_blocked := {"id":"temp_item_digital_blocked", "object_group":"item", "object_type":"item", "position":Vector2i(123, 100), "item_form":"digital", "can_place_in_digital_buffer":false}
	for obj in [physical_item, digital_item, digital_blocked]:
		mission_world_objects.append(obj); world_objects_by_cell[Vector2i(obj.get("position", Vector2i(-1, -1)))] = obj; temp_ids.append(String(obj.get("id", "")))
	if not bool(pickup_world_item("temp_item_physical").get("success", false)): warnings.append("physical_pickup_failed")
	if not bool(pickup_world_item("temp_item_digital").get("success", false)): warnings.append("digital_pickup_allowed_failed")
	if bool(pickup_world_item("temp_item_digital_blocked").get("success", false)): warnings.append("digital_pickup_block_missing")
	runtime_inventory_state["manipulator_hold"] = "occupied_slot"
	if bool(hold_item_in_manipulator("temp_item_physical").get("success", false)): warnings.append("manipulator_single_item_gate_missing")
	runtime_inventory_state["manipulator_hold"] = ""
	var inv_before_fail := str(get_inventory_state())
	drop_inventory_item("missing_item")
	if str(get_inventory_state()) != inv_before_fail: warnings.append("failed_inventory_action_mutated_state")
	for i in range(mission_world_objects.size() - 1, -1, -1):
		var oid := String(mission_world_objects[i].get("id", ""))
		if temp_ids.has(oid):
			world_objects_by_cell.erase(WorldObjectCatalogRef.to_world_cell(mission_world_objects[i].get("position", Vector2i(-1, -1)), Vector2i(-1, -1)))
			mission_world_objects.remove_at(i)
	apply_world_object_runtime_state(world_snapshot)
	runtime_inventory_state = inventory_snapshot.duplicate(true)
	return warnings

func get_inventory_tools_modules_validation_text() -> String:
	var warnings := validate_inventory_tools_modules_runtime()
	return "InventoryToolsModulesValidation: ok" if warnings.is_empty() else "InventoryToolsModulesValidation:\n- " + "\n- ".join(warnings)

func validate_full_runtime_persistence() -> Array[String]:
	var warnings: Array[String] = []
	var snap := get_world_object_runtime_state()
	if snap.is_empty() and not mission_world_objects.is_empty():
		warnings.append("world_runtime_snapshot_empty")
	var inv := get_inventory_state()
	for field_name in ["pocket_items", "manipulator_hold", "digital_buffer", "item_amounts", "consumed_item_ids", "world_item_runtime"]:
		if not inv.has(field_name):
			warnings.append("inventory_field_missing_%s" % field_name)
	return warnings

func _get_mission10_layout_for_validation() -> Array:
	if grid_manager != null and grid_manager.has_method("get_mission10_layout"):
		return Array(grid_manager.call("get_mission10_layout"))
	var temporary_grid: GridManager = GridManager.new()
	var layout: Array = Array(temporary_grid.get_mission10_layout())
	temporary_grid.free()
	return layout

func validate_task_test_mission_runtime() -> Array[String]:
	var warnings: Array[String] = []
	var built: Dictionary = build_task_test_mission_world_objects_for_validation()
	warnings.append_array(Array(built.get("warnings", [])))
	var task_objects: Array[Dictionary] = built.get("objects", [])
	var task_items_by_cell: Dictionary = built.get("items_by_cell", {})
	var task_ids := {}
	var occupied_cells := {}
	for obj in task_objects:
		var oid := String(obj.get("id", "")).strip_edges()
		if not oid.begins_with("task_test_"):
			continue
		if task_ids.has(oid):
			warnings.append("duplicate_task_test_id_%s" % oid)
		task_ids[oid] = true
		if String(obj.get("object_type", "")).strip_edges() == "":
			warnings.append("task_test_object_missing_type_%s" % oid)
		if String(obj.get("object_group", "")).strip_edges() == "":
			warnings.append("task_test_object_missing_group_%s" % oid)
		var cell: Vector2i = Vector2i(obj.get("position", Vector2i.ZERO))
		if not bool(obj.get("allow_cell_overlap", false)) and occupied_cells.has(cell):
			warnings.append("duplicate_task_test_cell_%s_between_%s_and_%s" % [str(cell), String(occupied_cells[cell]), oid])
		occupied_cells[cell] = oid
	for required_id in ["task_test_extraction_door","task_test_source_class_1","task_test_radiator","task_test_terminal_main","task_test_door_mechanical","task_test_platform_lift","task_test_hidden_cable","task_test_item_repair_kit","task_test_cable_reel"]:
		if not task_ids.has(required_id):
			var exists_item := false
			for cell in task_items_by_cell.keys():
				for item in Array(task_items_by_cell[cell]):
					if String(item.get("id", "")) == required_id:
						exists_item = true
						break
				if exists_item:
					break
			if not exists_item:
				warnings.append("missing_%s" % required_id)
	var extraction: Dictionary = {}
	for obj in task_objects:
		if String(obj.get("id", "")) == "task_test_extraction_door":
			extraction = obj
			break
	if extraction.is_empty() or not bool(extraction.get("mission_exit", false)):
		warnings.append("task_test_extraction_not_flagged")
	else:
		if not bool(extraction.get("extraction", false)):
			warnings.append("task_test_extraction_missing_extraction_flag")
		if String(extraction.get("state", "")) != "open":
			warnings.append("task_test_extraction_not_open")
		if bool(extraction.get("is_locked", false)):
			warnings.append("task_test_extraction_locked")
	var xray_exists := task_ids.has("task_test_xray_route_marker")
	if not xray_exists:
		warnings.append("task_test_xray_route_marker_missing")
	var exit_cell := Vector2i(14, 7)
	var extraction_cell := Vector2i(extraction.get("position", Vector2i(-999, -999)))
	if extraction_cell != exit_cell and extraction_cell.distance_to(exit_cell) > 1.0:
		warnings.append("task_test_extraction_not_on_or_adjacent_to_exit")
	var mission_layout: Array = _get_mission10_layout_for_validation()
	var exit_tiles := 0
	var layout_exit_cell := Vector2i(-999, -999)
	for y in range(mission_layout.size()):
		for x in range(Array(mission_layout[y]).size()):
			if int(Array(mission_layout[y])[x]) == GridManager.TILE_EXIT:
				exit_tiles += 1
				layout_exit_cell = Vector2i(x, y)
	if exit_tiles != 1:
		warnings.append("task_test_layout_exit_tile_count_%d" % exit_tiles)
	elif extraction_cell != layout_exit_cell and extraction_cell.distance_to(layout_exit_cell) > 1.0:
		warnings.append("task_test_extraction_cell_not_matching_layout_exit")
	return warnings

func get_task_test_required_system_coverage_spec() -> Dictionary:
	return {
		"movement": {"required":["runtime_door_passability_checks"],"optional":[],"intentionally_invalid":[]},
		"doors": {"required":["open_mechanical_door","closed_mechanical_door","locked_mechanical_key_door","open_digital_door","locked_digital_key_door","terminal_locked_door","powered_gate","unpowered_gate","damaged_or_jammed_door"],"optional":[],"intentionally_invalid":[]},
		"keys": {"required":["mechanical_key","digital_key_opened","digital_key_encrypted","digital_key_damaged"],"optional":["access_code"],"intentionally_invalid":[]},
		"power": {"required":["power_source","power_socket","power_cable","power_cable_cut","hidden_power_cable","external_power_required"],"optional":[],"intentionally_invalid":["task_test_powered_gate_unpowered","task_test_platform_lift"]},
		"control": {"required":["control_switch","control_terminal","external_control_required"],"optional":[],"intentionally_invalid":["task_test_control_missing_source","task_test_control_invalid_source"]},
		"cooling": {"required":["cooling_device","heat_producer","overheated_device"],"optional":[],"intentionally_invalid":[]},
		"terminals": {"required":["terminal_info","terminal_unpowered","terminal_damaged","terminal_encrypted","terminal_connector_gated","terminal_processor_gated"],"optional":[],"intentionally_invalid":[]},
		"wall_materials": {"required":["wall_outer","wall_brick","wall_concrete","wall_steel","wall_reinforced","wall_grate","wall_damaged"],"optional":[],"intentionally_invalid":[]},
		"scan_visibility": {"required":["scan_xray_hidden","scan_thermal_visible","scan_connector_gated","scan_processor_gated"],"optional":[],"intentionally_invalid":[]},
		"items": {"required":["mechanical_key","digital_key_opened","digital_key_encrypted","digital_key_damaged"],"optional":["access_code","fuse","repair_kit"],"intentionally_invalid":[]},
		"extraction": {"required":["extraction"],"optional":[],"intentionally_invalid":[]},
		"runtime_cell_state": {"required":["door_open_passable","door_closed_not_passable"],"optional":[],"intentionally_invalid":[]},
		"negative_samples": {"required":[],"optional":[],"intentionally_invalid":["task_test_control_missing_source","task_test_control_invalid_source","task_test_powered_gate_unpowered","task_test_platform_lift"]}
	}

func classify_task_test_object_for_audit(object_data: Dictionary) -> Array[String]:
	var tags: Array[String] = []
	var object_id: String = String(object_data.get("id", ""))
	var group: String = String(object_data.get("object_group", ""))
	var object_type: String = String(object_data.get("object_type", ""))
	var item_type: String = String(object_data.get("item_type", object_type))
	var state: String = String(object_data.get("state", "")).to_lower()
	var lock_type: String = String(object_data.get("lock_type", "")).to_lower()
	if group == "door":
		var is_open := state == "open" or bool(object_data.get("is_open", false))
		var is_closed := state == "closed"
		var is_damaged_or_jammed := state in ["damaged", "jammed"] or bool(object_data.get("damaged", false))
		if is_open:
			tags.append("door_open")
			if object_type in ["steel_door", "mechanical_door", "reinforced_steel_door", "grid_door"]:
				tags.append("open_mechanical_door")
			if object_type in ["energy_door", "digital_door"]:
				tags.append("open_digital_door")
		if is_closed:
			tags.append("door_closed")
			if object_type in ["steel_door", "mechanical_door", "reinforced_steel_door", "grid_door"]:
				tags.append("closed_mechanical_door")
		if lock_type == "mechanical_key":
			tags.append("door_locked_mechanical")
			tags.append("locked_mechanical_key_door")
		if lock_type == "digital_key":
			tags.append("door_locked_digital")
			tags.append("locked_digital_key_door")
		if lock_type == "terminal_lock":
			tags.append("door_terminal_locked")
			tags.append("terminal_locked_door")
		if bool(object_data.get("requires_external_power", false)):
			tags.append("door_powered_gate")
			tags.append("powered_gate")
		if state == "unpowered" or not bool(object_data.get("is_powered", true)):
			tags.append("door_unpowered")
			tags.append("unpowered_gate")
		if is_damaged_or_jammed:
			tags.append("door_damaged")
			tags.append("damaged_or_jammed_door")
	if group == "item":
		if item_type == "mechanical_keycard":
			tags.append("mechanical_key")
			tags.append("key_mechanical")
		if item_type == "digital_key":
			var dstate: String = String(object_data.get("digital_state", "")).to_lower()
			if dstate == "opened":
				tags.append("digital_key_opened")
				tags.append("key_digital_opened")
			if dstate == "encrypted":
				tags.append("digital_key_encrypted")
				tags.append("key_digital_encrypted")
			if dstate == "damaged":
				tags.append("digital_key_damaged")
				tags.append("key_digital_damaged")
	if object_type.begins_with("power_source"): tags.append("power_source")
	if object_type == "power_socket": tags.append("power_socket")
	if object_type == "power_cable":
		tags.append("power_cable")
		if state == "cut" or bool(object_data.get("damaged", false)): tags.append("power_cable_cut")
		if bool(object_data.get("hidden", false)): tags.append("hidden_power_cable")
	if bool(object_data.get("requires_external_power", false)): tags.append("external_power_required")
	if object_type in ["circuit_switch","circuit_breaker"]: tags.append("control_switch")
	if group == "terminal": tags.append("control_terminal")
	if bool(object_data.get("requires_external_control", false)): tags.append("external_control_required")
	if object_id == "task_test_control_missing_source": tags.append("control_missing_expected")
	if object_id == "task_test_control_invalid_source": tags.append("control_invalid_expected")
	if object_data.has("cooling_device_type"): tags.append("cooling_device")
	if int(object_data.get("working_heat", 0)) > 0: tags.append("heat_producer")
	if int(object_data.get("current_heat", 0)) >= int(object_data.get("overheat_threshold", 999999)): tags.append("overheated_device")
	if group == "terminal":
		if String(object_data.get("connection_type", "")) == "info": tags.append("terminal_info")
		if state == "unpowered": tags.append("terminal_unpowered")
		if state == "damaged": tags.append("terminal_damaged")
		if bool(object_data.get("encrypts_data", false)): tags.append("terminal_encrypted")
		if int(object_data.get("required_connector_level", 0)) > 0: tags.append("terminal_connector_gated")
		if int(object_data.get("required_processor_level", 0)) > 0: tags.append("terminal_processor_gated")
	var material: String = String(object_data.get("material", ""))
	if material == "outer_wall": tags.append("wall_outer")
	if material == "brick_wall": tags.append("wall_brick")
	if material == "concrete_wall": tags.append("wall_concrete")
	if material == "steel_wall": tags.append("wall_steel")
	if material == "reinforced_steel_wall": tags.append("wall_reinforced")
	if material == "grate_wall": tags.append("wall_grate")
	if material == "damaged_wall": tags.append("wall_damaged")
	if bool(object_data.get("hidden", false)) and bool(object_data.get("visible_with_xray", false)): tags.append("scan_xray_hidden")
	if bool(object_data.get("visible_with_thermal", false)): tags.append("scan_thermal_visible")
	if int(object_data.get("required_connector_level", 0)) > 0: tags.append("scan_connector_gated")
	if int(object_data.get("required_processor_level", 0)) > 0: tags.append("scan_processor_gated")
	if bool(object_data.get("mission_exit", false)) or bool(object_data.get("extraction", false)): tags.append("extraction")
	if item_type == "access_code": tags.append("access_code")
	if item_type == "fuse": tags.append("fuse")
	if item_type == "repair_kit": tags.append("repair_kit")
	return tags

func get_task_test_system_coverage_report_text() -> String:
	return get_task_test_system_audit_report_text()

func get_task_test_system_coverage_report() -> Dictionary:
	var audit: Dictionary = get_task_test_system_audit_report()
	return {"total_objects": int(audit.get("summary", {}).get("total_objects", 0)), "coverage": Dictionary(audit.get("coverage", {}))}

func get_task_test_system_audit_report() -> Dictionary:
	var object_ids: Dictionary = {}
	var item_ids: Dictionary = {}
	var coverage_hits: Dictionary = {}
	var valid_links: Array[Dictionary] = []
	var invalid_links: Array[Dictionary] = []
	var expected_invalid_links: Array[Dictionary] = []
	var duplicate_cell_warnings: Array[String] = []
	var objects_without_audit_tags: Array[String] = []
	var notes: Array[String] = []
	var occupied: Dictionary = {}
	for object_data in mission_world_objects:
		var object_id: String = String(object_data.get("id", ""))
		object_ids[object_id] = true
	for cell_variant in cell_items.keys():
		for item_variant in Array(cell_items.get(cell_variant, [])):
			var item_data: Dictionary = Dictionary(item_variant)
			item_ids[String(item_data.get("id", ""))] = true
	var spec: Dictionary = get_task_test_required_system_coverage_spec()
	var expected_invalid_ids: Dictionary = {}
	for entry_variant in Array(spec.get("negative_samples", {}).get("intentionally_invalid", [])):
		expected_invalid_ids[String(entry_variant)] = true
	var has_open_passable_door: bool = false
	var has_closed_not_passable_door: bool = false
	for object_data in mission_world_objects:
		var object_id: String = String(object_data.get("id", ""))
		var tags: Array[String] = classify_task_test_object_for_audit(object_data)
		var group: String = String(object_data.get("object_group", ""))
		var cell: Vector2i = Vector2i(object_data.get("position", Vector2i.ZERO))
		if group == "door":
			var runtime_state: Dictionary = get_runtime_cell_state(cell)
			var is_passable := bool(runtime_state.get("is_passable", false))
			var state: String = String(object_data.get("state", "")).to_lower()
			var lock_type: String = String(object_data.get("lock_type", "")).to_lower()
			if (state == "open" or bool(object_data.get("is_open", false))) and is_passable:
				tags.append("door_open_passable")
				has_open_passable_door = true
			var closed_like := state in ["closed", "locked", "unpowered", "damaged", "jammed"] or bool(object_data.get("is_locked", false))
			if lock_type in ["mechanical_key", "digital_key", "terminal_lock"]:
				closed_like = true
			if closed_like and not is_passable:
				tags.append("door_closed_not_passable")
				has_closed_not_passable_door = true
		if tags.is_empty():
			objects_without_audit_tags.append(object_id)
		for tag in tags:
			coverage_hits[String(tag)] = true
		if group != "item":
			if occupied.has(cell):
				duplicate_cell_warnings.append("duplicate_world_object_cell_%s_%s_%s" % [str(cell), String(occupied[cell]), object_id])
			else:
				occupied[cell] = object_id
		for field_name in ["power_network_id", "control_source_id", "linked_terminal_id", "controller_id", "target_door_id", "target_platform_id", "required_key_id"]:
			var ref_id: String = String(object_data.get(field_name, "")).strip_edges()
			if ref_id.is_empty():
				continue
			var exists: bool = object_ids.has(ref_id) or item_ids.has(ref_id) or field_name == "power_network_id"
			var link_row: Dictionary = {"object_id": object_id, "field": field_name, "target_id": ref_id}
			if exists:
				valid_links.append(link_row)
			elif expected_invalid_ids.has(object_id):
				expected_invalid_links.append(link_row)
			else:
				invalid_links.append(link_row)
		var ctrls: Array = Array(object_data.get("controls", []))
		for ctrl_target in ctrls:
			var ctrl_id: String = String(ctrl_target).strip_edges()
			if ctrl_id.is_empty():
				continue
			var ctrl_row: Dictionary = {"object_id": object_id, "field": "controls", "target_id": ctrl_id}
			if object_ids.has(ctrl_id):
				valid_links.append(ctrl_row)
			elif expected_invalid_ids.has(object_id):
				expected_invalid_links.append(ctrl_row)
			else:
				invalid_links.append(ctrl_row)
	if has_open_passable_door and has_closed_not_passable_door:
		coverage_hits["runtime_door_passability_checks"] = true
	var expected_runtime_warnings: Array[String] = []
	var unexpected_runtime_warnings: Array[String] = []
	for runtime_warning in validate_task_test_runtime_cell_states():
		var warning_text: String = String(runtime_warning)
		var matched_expected: bool = false
		for expected_id_variant in expected_invalid_ids.keys():
			var expected_id: String = String(expected_id_variant)
			if not expected_id.is_empty() and warning_text.find(expected_id) != -1:
				matched_expected = true
				break
		if matched_expected:
			expected_runtime_warnings.append(warning_text)
		else:
			unexpected_runtime_warnings.append(warning_text)
	var runtime_cell_warnings: Array[String] = unexpected_runtime_warnings
	var coverage: Dictionary = {}
	var missing_coverage: Array[String] = []
	for section_name in spec.keys():
		var section_spec: Dictionary = Dictionary(spec.get(section_name, {}))
		var required_items: Array = Array(section_spec.get("required", []))
		var covered: Array[String] = []
		var missing: Array[String] = []
		for req in required_items:
			var req_key: String = String(req)
			if coverage_hits.has(req_key):
				covered.append(req_key)
			else:
				missing.append(req_key)
				missing_coverage.append("%s:%s" % [String(section_name), req_key])
		coverage[String(section_name)] = {"ok": missing.is_empty(), "covered": covered, "missing": missing, "object_ids": []}
	var summary: Dictionary = {"total_objects": mission_world_objects.size(), "total_items": item_ids.size(), "missing_coverage_count": missing_coverage.size()}
	var ok: bool = missing_coverage.is_empty() and invalid_links.is_empty() and unexpected_runtime_warnings.is_empty() and duplicate_cell_warnings.is_empty()
	notes.append("Expected invalid links are represented explicitly and do not count as valid.")
	return {"ok": ok, "summary": summary, "coverage": coverage, "missing_coverage": missing_coverage, "valid_links": valid_links, "invalid_links": invalid_links, "expected_invalid_links": expected_invalid_links, "expected_runtime_warnings": expected_runtime_warnings, "unexpected_runtime_warnings": unexpected_runtime_warnings, "runtime_cell_warnings": runtime_cell_warnings, "duplicate_cell_warnings": duplicate_cell_warnings, "objects_without_audit_tags": objects_without_audit_tags, "notes": notes}

func get_task_test_system_audit_report_text() -> String:
	var report: Dictionary = get_task_test_system_audit_report()
	var lines: Array[String] = []
	lines.append("TASK TEST SYSTEM AUDIT")
	lines.append("OK: %s" % String(report.get("ok", false)))
	lines.append("")
	lines.append("Coverage:")
	for section_name in ["movement","doors","keys","power","control","cooling","terminals","wall_materials","scan_visibility","runtime_cell_state","extraction"]:
		var section: Dictionary = Dictionary(Dictionary(report.get("coverage", {})).get(section_name, {}))
		lines.append("- %s: %s missing=%s" % [section_name.capitalize(), "OK" if bool(section.get("ok", false)) else "MISSING", JSON.stringify(section.get("missing", []))])
	lines.append("Invalid links:")
	for row in Array(report.get("invalid_links", [])):
		lines.append("- %s" % JSON.stringify(row))
	lines.append("Expected invalid samples:")
	for row in Array(report.get("expected_invalid_links", [])):
		lines.append("- %s" % JSON.stringify(row))
	for warning in Array(report.get("expected_runtime_warnings", [])):
		lines.append("- %s" % String(warning))
	lines.append("Runtime cell warnings:")
	for warning in Array(report.get("unexpected_runtime_warnings", [])):
		lines.append("- %s" % String(warning))
	lines.append("Objects without audit tags:")
	for object_id in Array(report.get("objects_without_audit_tags", [])):
		lines.append("- %s" % String(object_id))
	return "\n".join(lines)

func validate_task_test_runtime_cell_states() -> Array[String]:
	var warnings: Array[String] = []
	var task_item_ids: Array[String] = []
	var object_ids := {}
	var power_source_network_ids := {}
	for object_data in mission_world_objects:
		if typeof(object_data) != TYPE_DICTIONARY:
			continue
		var existing_object_id := String(object_data.get("id", "")).strip_edges()
		if not existing_object_id.is_empty():
			object_ids[existing_object_id] = true
		var existing_type := String(object_data.get("object_type", "")).to_lower()
		if existing_type.begins_with("power_source"):
			var existing_network_id := String(object_data.get("power_network_id", "")).strip_edges()
			if not existing_network_id.is_empty():
				power_source_network_ids[existing_network_id] = true
	for cell_variant in cell_items.keys():
		for item_variant in Array(cell_items.get(cell_variant, [])):
			if typeof(item_variant) != TYPE_DICTIONARY:
				continue
			task_item_ids.append(String(Dictionary(item_variant).get("id", "")))
	for object_data in mission_world_objects:
		if typeof(object_data) != TYPE_DICTIONARY:
			continue
		var object_id: String = String(object_data.get("id", ""))
		var object_type: String = String(object_data.get("object_type", "")).to_lower()
		var cell: Vector2i = Vector2i(object_data.get("position", Vector2i.ZERO))
		var runtime_state: Dictionary = get_runtime_cell_state(cell)
		if not bool(runtime_state.get("has_object", false)):
			warnings.append("object_exists_but_runtime_has_no_object_%s" % object_id)
		var state_name: String = String(object_data.get("state", "")).to_lower()
		var canonical_open: bool = state_name == "open" or state_name == "opened" or bool(object_data.get("is_open", false))
		var is_door_object: bool = bool(runtime_state.get("is_door_object", false))
		var is_door: bool = bool(runtime_state.get("is_door_cell", false))
		if is_door_object and canonical_open and not bool(runtime_state.get("is_passable", false)):
			warnings.append("door_open_not_passable_%s" % object_id)
		var blocked_door_state: bool = state_name in ["closed", "locked", "unpowered", "damaged", "broken", "destroyed"] or bool(object_data.get("is_locked", false))
		if is_door_object and blocked_door_state and bool(runtime_state.get("is_passable", false)):
			warnings.append("door_closed_or_locked_but_passable_%s" % object_id)
		if is_door_object:
			var tile_type_value: int = int(runtime_state.get("tile_type", -1))
			if tile_type_value == GridManager.TILE_WALL or tile_type_value == GridManager.TILE_FLOOR or tile_type_value == GridManager.TILE_EXIT:
				warnings.append("door_object_on_non_door_tile_%s" % object_id)
			if not bool(runtime_state.get("is_door_cell", false)):
				warnings.append("door_object_tile_mismatch_%s" % object_id)
		if bool(object_data.get("requires_external_power", false)):
			var power_network_id: String = String(object_data.get("power_network_id", "")).strip_edges()
			if power_network_id.is_empty():
				warnings.append("external_power_missing_network_%s" % object_id)
			elif not power_source_network_ids.has(power_network_id):
				warnings.append("external_power_invalid_network_%s_%s" % [object_id, power_network_id])
		if bool(object_data.get("requires_external_control", false)):
			var ctrl: String = String(object_data.get("control_source_id", object_data.get("linked_terminal_id", object_data.get("controller_id", "")))).strip_edges()
			if ctrl.is_empty():
				warnings.append("external_control_missing_reference_%s" % object_id)
			elif not object_ids.has(ctrl):
				warnings.append("external_control_invalid_reference_%s_%s" % [object_id, ctrl])
		for control_ref_field in ["control_source_id", "linked_terminal_id", "controller_id"]:
			var control_ref_id: String = String(object_data.get(control_ref_field, "")).strip_edges()
			if control_ref_id.is_empty():
				continue
			if not object_ids.has(control_ref_id):
				warnings.append("external_control_invalid_reference_%s_%s" % [object_id, control_ref_id])
		var target_door_id: String = String(object_data.get("target_door_id", "")).strip_edges()
		if not target_door_id.is_empty() and not object_ids.has(target_door_id):
			warnings.append("target_door_missing_%s_%s" % [object_id, target_door_id])
		var target_platform_id: String = String(object_data.get("target_platform_id", "")).strip_edges()
		if not target_platform_id.is_empty() and not object_ids.has(target_platform_id):
			warnings.append("target_platform_missing_%s_%s" % [object_id, target_platform_id])
		var linked_terminal_id: String = String(object_data.get("linked_terminal_id", "")).strip_edges()
		if not linked_terminal_id.is_empty() and not object_ids.has(linked_terminal_id):
			warnings.append("linked_terminal_missing_%s_%s" % [object_id, linked_terminal_id])
		if (bool(object_data.get("requires_key", false)) or String(object_data.get("lock_type", "")) == "mechanical_key" or String(object_data.get("lock_type", "")) == "digital_key") and String(object_data.get("required_key_id", "")).is_empty():
			warnings.append("key_locked_door_missing_required_key_%s" % object_id)
		var required_key_id: String = String(object_data.get("required_key_id", ""))
		if not required_key_id.is_empty() and not task_item_ids.has(required_key_id):
			warnings.append("required_key_not_in_task_items_%s_%s" % [object_id, required_key_id])
		if bool(object_data.get("blocks_movement", false)) and bool(runtime_state.get("is_passable", false)) and not (is_door and canonical_open):
			warnings.append("blocking_object_marked_passable_%s" % object_id)
	return warnings


func validate_task_test_universal_systems_coverage() -> Array[String]:
	return validate_task_test_system_audit()

func validate_task_test_system_audit() -> Array[String]:
	var warnings: Array[String] = []
	var report: Dictionary = get_task_test_system_audit_report()
	warnings.append_array(Array(report.get("missing_coverage", [])))
	for row in Array(report.get("invalid_links", [])):
		warnings.append("unexpected_invalid_link_%s" % JSON.stringify(row))
	warnings.append_array(Array(report.get("runtime_cell_warnings", [])))
	warnings.append_array(Array(report.get("duplicate_cell_warnings", [])))
	var expected_neutral: Dictionary = {"task_test_scan_normal_visible":true}
	for object_id in Array(report.get("objects_without_audit_tags", [])):
		var tagless_id: String = String(object_id)
		if not expected_neutral.has(tagless_id):
			warnings.append("object_without_audit_tags_%s" % tagless_id)
	return warnings

func get_task_test_mission_validation_text() -> String:
	var warnings: Array[String] = validate_task_test_mission_runtime()
	var base_text: String = "TaskTestValidation: ok"
	if not warnings.is_empty():
		base_text = "TaskTestValidation:\n- " + "\n- ".join(warnings)
	var audit: Dictionary = get_task_test_system_audit_report()
	var audit_summary: String = "Audit: ok=%s missing=%d invalid_links=%d runtime_warnings=%d" % [
		String(audit.get("ok", false)),
		Array(audit.get("missing_coverage", [])).size(),
		Array(audit.get("invalid_links", [])).size(),
		Array(audit.get("runtime_cell_warnings", [])).size()
	]
	return base_text + "\n" + audit_summary




func _build_task_test_module_port_specs() -> Array[Dictionary]:
	# TASK TEST module-port scenario data shared across validation checks.
	return [
		{"id":"task_test_internal_interface_v1","module_id":"internal_interface_v1"},
		{"id":"task_test_external_interface_v1","module_id":"external_interface_v1"},
		{"id":"task_test_power_block_v1","module_id":"power_block_v1"},
		{"id":"task_test_processor_v1","module_id":"processor_v1"},
		{"id":"task_test_processor_v2","module_id":"processor_v2"},
		{"id":"task_test_wired_connector_v1","module_id":"wired_connector_v1"},
		{"id":"task_test_optical_connector_v1","module_id":"optical_connector_v1"},
		{"id":"task_test_extra_external_tool","module_id":"repair_v1"},
		{"id":"task_test_battery_v1","module_id":"battery_v1"},
		{"id":"task_test_cooler_v1","module_id":"cooler_v1"},
		{"id":"task_test_radiator_v1","module_id":"radiator_v1"}
	]

func _simulate_task_test_port_state(specs: Array[Dictionary], active_module_ids: Array[String], internal_ports_total: int, external_ports_total: int, power_ports_total: int) -> Dictionary:
	# Static fallback simulation kept for compatibility/safety when runtime mutation is unavailable.
	var modules: Dictionary = {}
	var sorted_specs := specs.duplicate()
	sorted_specs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pa := int(active_bipob_ref.call("_get_module_port_priority", String(a.get("module_id", ""))))
		var pb := int(active_bipob_ref.call("_get_module_port_priority", String(b.get("module_id", ""))))
		if pa == pb:
			return String(a.get("id", "")) < String(b.get("id", ""))
		return pa < pb
	)
	var internal_remaining := maxi(0, internal_ports_total)
	var external_remaining := maxi(0, external_ports_total)
	var power_remaining := maxi(0, power_ports_total)
	for spec in sorted_specs:
		var tid := String(spec.get("id", ""))
		var module_id := String(spec.get("module_id", ""))
		if not active_module_ids.has(tid):
			modules[tid] = {"id":tid,"active":false,"inactive_reason":"module_not_installed","port_priority":int(active_bipob_ref.call("_get_module_port_priority", module_id))}
			continue
		var needs_internal := bool(active_bipob_ref.call("_module_requires_internal_interface_port", module_id))
		var needs_external := bool(active_bipob_ref.call("_module_requires_external_interface_port", module_id))
		var needs_power := bool(active_bipob_ref.call("_module_requires_power_block_port", module_id))
		var active := true
		var reason := "ok"
		if needs_internal and internal_remaining <= 0:
			active = false
			reason = "internal_interface_port_missing"
		elif needs_external and external_remaining <= 0:
			active = false
			reason = "external_interface_port_missing"
		elif needs_power and power_remaining <= 0:
			active = false
			reason = "power_block_port_missing"
		if active:
			if needs_internal:
				internal_remaining -= 1
			if needs_external:
				external_remaining -= 1
			if needs_power:
				power_remaining -= 1
		modules[tid] = {"id":tid,"active":active,"inactive_reason":reason,"port_priority":int(active_bipob_ref.call("_get_module_port_priority", module_id))}
	return {"modules":modules, "internal_remaining":internal_remaining, "external_remaining":external_remaining, "power_remaining":power_remaining}

func _active_bipob_has_property(property_name: String) -> bool:
	if active_bipob_ref == null:
		return false
	for property_info in Array(active_bipob_ref.get_property_list()):
		if String(Dictionary(property_info).get("name", "")) == property_name:
			return true
	return false

func _snapshot_installed_modules_for_validation() -> Dictionary:
	if not _active_bipob_has_property("installed_modules"):
		return {"ok": false, "reason": "installed_modules_unavailable"}
	return {"ok": true, "installed_modules": Array(active_bipob_ref.installed_modules).duplicate()}

func _restore_installed_modules_from_snapshot(snapshot: Dictionary) -> bool:
	if not bool(snapshot.get("ok", false)) or not _active_bipob_has_property("installed_modules"):
		return false
	active_bipob_ref.installed_modules = Array(snapshot.get("installed_modules", [])).duplicate()
	return true

func _is_internal_runtime_module_id(module_id: String) -> bool:
	for prefix in ["internal_interface_","external_interface_","power_block_","processor_","memory_","gpu_","hard_drive_","charger_","battery_","cooler_","radiator_","water_tube_","air_duct_"]:
		if module_id.begins_with(prefix):
			return true
	return false

func _build_runtime_modules_by_id(module_ids: Array[String]) -> Array:
	var modules: Array = []
	for module_id in module_ids:
		var module = null
		if _is_internal_runtime_module_id(module_id):
			module = active_bipob_ref.call("create_internal_module", module_id, module_id, Vector3i.ONE)
		else:
			module = active_bipob_ref.call("create_external_module_by_id", module_id)
		if module == null:
			return []
		modules.append(module)
	return modules

func _preview_module_port_activity_for_module_ids(module_ids: Array[String]) -> Dictionary:
	var snapshot := _snapshot_installed_modules_for_validation()
	if not bool(snapshot.get("ok", false)):
		return {"ok": false, "reason": String(snapshot.get("reason", "snapshot_failed"))}
	var runtime_modules := _build_runtime_modules_by_id(module_ids)
	if runtime_modules.is_empty() and not module_ids.is_empty():
		_restore_installed_modules_from_snapshot(snapshot)
		return {"ok": false, "reason": "create_test_modules_failed"}
	active_bipob_ref.installed_modules = runtime_modules
	var state: Dictionary = active_bipob_ref.call("preview_module_port_activity")
	var restored := _restore_installed_modules_from_snapshot(snapshot)
	if not restored:
		return {"ok": false, "reason": "restore_failed", "state": state}
	return {"ok": true, "state": state}

func validate_module_port_network_runtime() -> Array[String]:
	var warnings: Array[String] = []
	if active_bipob_ref == null or not active_bipob_ref.has_method("preview_module_port_activity"):
		return ["active_bipob_missing"]
	for helper_name in ["_get_module_port_priority", "_module_requires_external_interface_port", "_module_requires_internal_interface_port", "_module_requires_power_block_port", "create_external_module_by_id", "create_internal_module"]:
		if not active_bipob_ref.has_method(helper_name):
			warnings.append("module_ports_helper_missing_%s" % helper_name)
	if warnings.any(func(warning: String) -> bool: return warning.begins_with("module_ports_helper_missing_")):
		return warnings

	var baseline: Dictionary = active_bipob_ref.call("preview_module_port_activity")
	for key in ["modules", "internal_interface", "external_interface", "power_block"]:
		if not baseline.has(key):
			warnings.append("module_ports_missing_%s" % key)
	if not active_bipob_ref.has_method("get_module_port_debug_report"):
		warnings.append("module_ports_debug_report_missing")
	if not active_bipob_ref.has_method("get_module_port_debug_report_text"):
		warnings.append("module_ports_debug_report_text_missing")
	if warnings.has("module_ports_debug_report_missing") or warnings.has("module_ports_debug_report_text_missing"):
		return warnings
	var debug_report_a: Dictionary = Dictionary(active_bipob_ref.call("get_module_port_debug_report"))
	var debug_report_b: Dictionary = Dictionary(active_bipob_ref.call("get_module_port_debug_report"))
	for report_key in ["internal_ports_total", "internal_ports_used", "internal_ports_remaining", "external_ports_total", "external_ports_used", "external_ports_remaining", "power_ports_total", "power_ports_used", "power_ports_remaining", "active_modules", "inactive_modules", "modules"]:
		if not debug_report_a.has(report_key):
			warnings.append("module_ports_debug_report_missing_%s" % report_key)
	var debug_text: String = String(active_bipob_ref.call("get_module_port_debug_report_text"))
	if debug_text.strip_edges().is_empty():
		warnings.append("module_ports_debug_report_text_empty")
	if str(debug_report_a) != str(debug_report_b):
		warnings.append("module_ports_debug_report_not_read_only")
	var internal_ports_total: int = int(debug_report_a.get("internal_ports_total", 0))
	var internal_ports_used: int = int(debug_report_a.get("internal_ports_used", 0))
	var internal_ports_remaining: int = int(debug_report_a.get("internal_ports_remaining", 0))
	if internal_ports_remaining != maxi(0, internal_ports_total - internal_ports_used):
		warnings.append("module_ports_debug_report_internal_accounting_mismatch")
	var external_ports_total: int = int(debug_report_a.get("external_ports_total", 0))
	var external_ports_used: int = int(debug_report_a.get("external_ports_used", 0))
	var external_ports_remaining: int = int(debug_report_a.get("external_ports_remaining", 0))
	if external_ports_remaining != maxi(0, external_ports_total - external_ports_used):
		warnings.append("module_ports_debug_report_external_accounting_mismatch")
	var power_ports_total: int = int(debug_report_a.get("power_ports_total", 0))
	var power_ports_used: int = int(debug_report_a.get("power_ports_used", 0))
	var power_ports_remaining: int = int(debug_report_a.get("power_ports_remaining", 0))
	if power_ports_remaining != maxi(0, power_ports_total - power_ports_used):
		warnings.append("module_ports_debug_report_power_accounting_mismatch")
	var external_interface_link_ports_reserved: int = int(debug_report_a.get("external_interface_link_ports_reserved", 0))
	if external_interface_link_ports_reserved > 0 and external_ports_used < external_interface_link_ports_reserved:
		warnings.append("module_ports_debug_report_external_reserved_accounting_mismatch")
	var internal_interface_link_ports_reserved: int = int(debug_report_a.get("internal_interface_link_ports_reserved", 0))
	if internal_interface_link_ports_reserved > 0 and internal_ports_used < internal_interface_link_ports_reserved:
		warnings.append("module_ports_debug_report_internal_reserved_accounting_mismatch")

	var _known_reason_keys := ["ok","connector_missing","connector_level_too_low","processor_missing","processor_level_too_low","internal_interface_missing","internal_interface_port_missing","internal_interface_link_missing","external_interface_missing","external_interface_port_missing","external_interface_link_missing","power_block_missing","power_block_port_missing","power_block_link_missing","power_block_overloaded","module_installed_but_inactive","module_not_installed"]
	var observed_runtime_reason_keys: Dictionary = {}
	var scenarios := [
		{"id":"processor_active","modules":["internal_interface_v1","power_block_v1","processor_v1"],"module":"processor_v1","active":true,"reason":"ok"},
		{"id":"memory_active_without_external_interface","modules":["internal_interface_v1","power_block_v1","memory_v1"],"module":"memory_v1","active":true,"reason":"ok"},
		{"id":"gpu_active_without_external_interface","modules":["internal_interface_v1","power_block_v1","gpu_v1"],"module":"gpu_v1","active":true,"reason":"ok"},
		{"id":"hard_drive_active_without_external_interface","modules":["internal_interface_v1","power_block_v1","hard_drive_v1"],"module":"hard_drive_v1","active":true,"reason":"ok"},
		{"id":"charger_active_without_external_interface","modules":["internal_interface_v1","power_block_v1","charger_v1"],"module":"charger_v1","active":true,"reason":"ok"},
		{"id":"cooler_active_without_external_interface","modules":["internal_interface_v1","power_block_v1","cooler_v1"],"module":"cooler_v1","active":true,"reason":"ok"},
		{"id":"connector_active","modules":["internal_interface_v1","external_interface_v1","power_block_v1","external_interface_connector_v1"],"module":"external_interface_connector_v1","active":true,"reason":"ok"},
		{"id":"external_interface_missing","modules":["internal_interface_v1","power_block_v1","external_interface_connector_v1"],"module":"external_interface_connector_v1","active":false,"reason":"external_interface_missing"},
		{"id":"external_interface_port_missing","modules":["internal_interface_v1","internal_interface_v1","external_interface_v1","power_block_v1","external_interface_connector_v1","optical_connector_v1","wireless_connector_v1","high_bandwidth_connector_v1","visor_v1","radar_v1"],"module":"radar_v1","active":false,"reason":"external_interface_port_missing"},
		{"id":"internal_interface_missing","modules":["power_block_v1","processor_v1"],"module":"processor_v1","active":false,"reason":"internal_interface_missing"},
		{"id":"internal_interface_port_missing","modules":["internal_interface_v1","power_block_v1","processor_v1","processor_v2","processor_v3","memory_v1","memory_v2","memory_v3","hard_drive_v1","cooler_v1"],"module":"cooler_v1","active":false,"reason":"internal_interface_port_missing"},
		{"id":"power_block_missing","modules":["internal_interface_v1","battery_v1"],"module":"battery_v1","active":false,"reason":"power_block_missing"},
		{"id":"power_block_port_missing","modules":["internal_interface_v1","internal_interface_v1","power_block_v1","external_interface_v1","processor_v1","processor_v2","processor_v3","memory_v1","memory_v2","memory_v3","hard_drive_v1","charger_v1","cooler_v1","gpu_v1","external_interface_connector_v1","optical_connector_v1","wireless_connector_v1","high_bandwidth_connector_v1","manipulator_arm_v1","visor_v1","radar_v1"],"module":"manipulator_arm_v1","active":false,"reason":"power_block_port_missing"},
		{"id":"radiator_no_internal_or_power","modules":["radiator_v1"],"module":"radiator_v1","active":true,"reason":"ok"},
		{"id":"battery_no_internal_required","modules":["power_block_v1","battery_v1"],"module":"battery_v1","active":true,"reason":"ok"},
		{"id":"power_block_requires_internal_interface","modules":["power_block_v1"],"module":"power_block_v1","active":false,"reason":"internal_interface_missing"},
		{"id":"power_block_active_with_internal_interface","modules":["internal_interface_v1","power_block_v1"],"module":"power_block_v1","active":true,"reason":"ok"},
		{"id":"internal_interface_v1_capacity","modules":["internal_interface_v1"],"internal_ports_total":6},
		{"id":"priority_tie","modules":["internal_interface_v1","power_block_v1","processor_v1","memory_v1","gpu_v1","hard_drive_v1","charger_v1","cooler_v1","processor_v2"],"priority":true}
	]

	for scenario in scenarios:
		var runtime: Dictionary = _preview_module_port_activity_for_module_ids(Array(scenario.get("modules", [])))
		if not bool(runtime.get("ok", false)):
			warnings.append("module_ports_runtime_preview_unavailable_%s" % String(runtime.get("reason", "unknown")))
			break
		var state: Dictionary = Dictionary(runtime.get("state", {}))
		var modules: Dictionary = Dictionary(state.get("modules", {}))
		if scenario.has("internal_ports_total"):
			var internal_interface_state := Dictionary(state.get("internal_interface", {}))
			if int(internal_interface_state.get("ports_total", -1)) != int(scenario.get("internal_ports_total", -1)):
				warnings.append("module_ports_internal_interface_capacity_mismatch_%s" % String(scenario.get("id", "")))
			continue
		if bool(scenario.get("priority", false)):
			var p1 := Dictionary(modules.get("processor_v1", {}))
			var p2 := Dictionary(modules.get("processor_v2", {}))
			var p1_active := bool(p1.get("active", false))
			var p2_active := bool(p2.get("active", false))
			if p1_active and p2_active:
				continue
			if p1_active == p2_active:
				warnings.append("task_test_processor_priority_tie_break_not_deterministic")
				continue
			if not p1_active and p2_active:
				warnings.append("task_test_processor_priority_tie_break_unstable_order")
			continue
		var module_id := String(scenario.get("module", ""))
		var module_state: Dictionary = Dictionary(modules.get(module_id, {}))
		if module_state.is_empty():
			warnings.append("module_not_installed")
			continue
		var expected_active := bool(scenario.get("active", false))
		var expected_reason := String(scenario.get("reason", "ok"))
		if bool(module_state.get("active", false)) != expected_active:
			warnings.append("module_ports_runtime_active_mismatch_%s" % String(scenario.get("id", "")))
		var actual_reason := String(module_state.get("inactive_reason", "module_installed_but_inactive"))
		observed_runtime_reason_keys[actual_reason] = true
		if actual_reason != expected_reason:
			warnings.append("module_ports_runtime_reason_mismatch_%s_%s" % [String(scenario.get("id", "")), actual_reason])
	return warnings

func _get_module_port_reason_coverage_gaps() -> Array[String]:
	if active_bipob_ref == null or not active_bipob_ref.has_method("preview_module_port_activity"):
		return []
	for helper_name in ["_get_module_port_priority", "_module_requires_external_interface_port", "_module_requires_internal_interface_port", "_module_requires_power_block_port", "create_external_module_by_id", "create_internal_module"]:
		if not active_bipob_ref.has_method(helper_name):
			return []

	var known_reason_keys := ["ok","connector_missing","connector_level_too_low","processor_missing","processor_level_too_low","internal_interface_missing","internal_interface_port_missing","internal_interface_link_missing","external_interface_missing","external_interface_port_missing","external_interface_link_missing","power_block_missing","power_block_port_missing","power_block_link_missing","power_block_overloaded","module_installed_but_inactive","module_not_installed"]
	var observed_runtime_reason_keys: Dictionary = {}
	var scenarios := [
		{"modules":["internal_interface_v1","power_block_v1","processor_v1"],"module":"processor_v1"},
		{"modules":["internal_interface_v1","power_block_v1","memory_v1"],"module":"memory_v1"},
		{"modules":["internal_interface_v1","power_block_v1","gpu_v1"],"module":"gpu_v1"},
		{"modules":["internal_interface_v1","power_block_v1","hard_drive_v1"],"module":"hard_drive_v1"},
		{"modules":["internal_interface_v1","power_block_v1","charger_v1"],"module":"charger_v1"},
		{"modules":["internal_interface_v1","power_block_v1","cooler_v1"],"module":"cooler_v1"},
		{"modules":["internal_interface_v1","external_interface_v1","power_block_v1","external_interface_connector_v1"],"module":"external_interface_connector_v1"},
		{"modules":["internal_interface_v1","power_block_v1","external_interface_connector_v1"],"module":"external_interface_connector_v1"},
		{"modules":["internal_interface_v1","internal_interface_v1","external_interface_v1","power_block_v1","external_interface_connector_v1","optical_connector_v1","wireless_connector_v1","high_bandwidth_connector_v1","visor_v1","radar_v1"],"module":"radar_v1"},
		{"modules":["power_block_v1","processor_v1"],"module":"processor_v1"},
		{"modules":["internal_interface_v1","power_block_v1","processor_v1","processor_v2","processor_v3","memory_v1","memory_v2","memory_v3","hard_drive_v1","cooler_v1"],"module":"cooler_v1"},
		{"modules":["internal_interface_v1","battery_v1"],"module":"battery_v1"},
		{"modules":["internal_interface_v1","internal_interface_v1","power_block_v1","external_interface_v1","processor_v1","processor_v2","processor_v3","memory_v1","memory_v2","memory_v3","hard_drive_v1","charger_v1","cooler_v1","gpu_v1","external_interface_connector_v1","optical_connector_v1","wireless_connector_v1","high_bandwidth_connector_v1","manipulator_arm_v1","visor_v1","radar_v1"],"module":"manipulator_arm_v1"},
		{"modules":["radiator_v1"],"module":"radiator_v1"},
		{"modules":["power_block_v1","battery_v1"],"module":"battery_v1"},
		{"modules":["power_block_v1"],"module":"power_block_v1"},
		{"modules":["internal_interface_v1","power_block_v1"],"module":"power_block_v1"},
	]
	for scenario in scenarios:
		var runtime := _preview_module_port_activity_for_module_ids(Array(scenario.get("modules", [])))
		if not bool(runtime.get("ok", false)):
			return []
		var state: Dictionary = Dictionary(runtime.get("state", {}))
		var module_id := String(scenario.get("module", ""))
		var module_state: Dictionary = Dictionary(Dictionary(state.get("modules", {})).get(module_id, {}))
		if module_state.is_empty():
			continue
		var actual_reason := String(module_state.get("inactive_reason", "module_installed_but_inactive"))
		observed_runtime_reason_keys[actual_reason] = true

	var gaps: Array[String] = []
	for reason_key in known_reason_keys:
		if not observed_runtime_reason_keys.has(reason_key):
			gaps.append("module_port_reason_key_coverage_gap_%s" % reason_key)
	return gaps

func get_module_port_reason_coverage_gap_text() -> String:
	var gaps := _get_module_port_reason_coverage_gaps()
	return "ModulePortReasonCoverage: complete" if gaps.is_empty() else "ModulePortReasonCoverage:\n- " + "\n- ".join(gaps)

func get_module_port_network_validation_text() -> String:
	var warnings := validate_module_port_network_runtime()
	var coverage_gaps := _get_module_port_reason_coverage_gaps()
	var lines: Array[String] = ["ModulePortNetworkValidation: ok" if warnings.is_empty() else "ModulePortNetworkValidation:"]
	if not warnings.is_empty():
		lines.append("- " + "\n- ".join(warnings))
	if not coverage_gaps.is_empty():
		lines.append("Coverage gaps (informational):")
		lines.append("- " + "\n- ".join(coverage_gaps))
	if active_bipob_ref != null and active_bipob_ref.has_method("get_module_port_debug_report_text"):
		lines.append("")
		lines.append(String(active_bipob_ref.call("get_module_port_debug_report_text")))
	return "\n".join(lines)

func validate_connector_processor_migration() -> Array[String]:
	var warnings: Array[String] = []
	var caps := get_actor_capability_levels()
	for key in ["processor_level", "connector_level", "connector_types", "modules", "tools", "port_state"]:
		if not caps.has(key):
			warnings.append("capability_report_missing_%s" % key)
	if caps.has("processor_level") and not (caps["processor_level"] is int):
		warnings.append("capability_report_invalid_processor_level_type")
	if caps.has("connector_level") and not (caps["connector_level"] is int):
		warnings.append("capability_report_invalid_connector_level_type")
	if caps.has("connector_types"):
		if not (caps["connector_types"] is Array):
			warnings.append("capability_report_invalid_connector_types_type")
		else:
			for entry in Array(caps["connector_types"]):
				if not (entry is String):
					warnings.append("capability_report_invalid_connector_types_entry")
					break
	if caps.has("modules"):
		if not (caps["modules"] is Array):
			warnings.append("capability_report_invalid_modules_type")
		else:
			for entry in Array(caps["modules"]):
				if not (entry is String):
					warnings.append("capability_report_invalid_modules_entry")
					break
	if caps.has("tools"):
		if not (caps["tools"] is Array):
			warnings.append("capability_report_invalid_tools_type")
		else:
			for entry in Array(caps["tools"]):
				if not (entry is String):
					warnings.append("capability_report_invalid_tools_entry")
					break
			var tools_array: Array = Array(caps["tools"])
			var non_tool_module_ids := {
				"internal_interface_v1": true,
				"power_block_v1": true,
				"processor_v1": true,
				"memory_v1": true,
				"external_interface_v1": true,
				"external_interface_connector_v1": true
			}
			for entry in tools_array:
				var tool_entry: String = String(entry)
				if non_tool_module_ids.has(tool_entry):
					warnings.append("capability_report_tools_contains_non_tool_module_id_%s" % tool_entry)
					break
	if caps.has("port_state") and not (caps["port_state"] is Dictionary):
		warnings.append("capability_report_invalid_port_state_type")

	var cap_port_state: Dictionary = Dictionary(caps.get("port_state", {}))
	var cap_modules_state: Dictionary = Dictionary(cap_port_state.get("modules", {}))
	var external_connector_active := false
	if cap_modules_state.has("external_interface_connector_v1"):
		external_connector_active = bool(Dictionary(cap_modules_state.get("external_interface_connector_v1", {})).get("active", false))
	if external_connector_active and not Array(caps.get("connector_types", [])).has("physical"):
		warnings.append("capability_report_missing_physical_connector_type_for_external_interface")
	for legacy_key in ["cpu_level", "required_cpu_level", "interface_level", "required_interface_level"]:
		if caps.has(legacy_key):
			warnings.append("capability_report_uses_legacy_%s" % legacy_key)

	var task := build_task_test_mission_world_objects_for_validation()
	for obj in Array(task.get("objects", [])):
		var obj_dict: Dictionary = Dictionary(obj)
		var obj_id: String = String(obj_dict.get("id", ""))
		if not obj_id.begins_with("task_test_terminal"):
			continue
		if obj_dict.has("required_interface_level"):
			warnings.append("task_test_uses_required_interface_level")
		if obj_dict.has("required_cpu_level"):
			warnings.append("task_test_uses_required_cpu_level")
		if not obj_dict.has("required_connector_level"):
			warnings.append("task_test_terminal_missing_required_connector_level")
		if not obj_dict.has("required_processor_level") and String(obj_dict.get("state", "")).to_lower() not in ["damaged", "unpowered"]:
			warnings.append("task_test_terminal_missing_required_processor_level")

	if active_bipob_ref != null and active_bipob_ref.has_method("get_world_action_module"):
		var module: Dictionary = Dictionary(active_bipob_ref.call("get_world_action_module", "connect", {"connection_type":"wired"}))
		if not String(Dictionary(module).get("id", "")).contains("_connector_v"):
			warnings.append("connect_action_not_connector_id")

	var req: Dictionary = get_terminal_hack_requirements("task_test_terminal_main")
	for key in ["required_connector_level", "required_processor_level", "available_connector_level", "available_processor_level"]:
		if not req.has(key):
			warnings.append("terminal_requirements_missing_%s" % key)
	for legacy_key in ["required_cpu_level", "required_interface_level", "cpu_level", "interface_level"]:
		if req.has(legacy_key):
			warnings.append("terminal_requirements_uses_legacy_%s" % legacy_key)
	if req.is_empty():
		warnings.append("terminal_requirements_empty")
	elif active_bipob_ref != null and (int(caps.get("connector_level", 0)) > 0 or int(caps.get("processor_level", 0)) > 0):
		if int(req.get("available_connector_level", 0)) <= 0 and int(caps.get("connector_level", 0)) > 0:
			warnings.append("terminal_available_connector_level_zero_with_modules")
		if int(req.get("available_processor_level", 0)) <= 0 and int(caps.get("processor_level", 0)) > 0:
			warnings.append("terminal_available_processor_level_zero_with_modules")
	return warnings

func get_connector_processor_migration_validation_text() -> String:
	var warnings := validate_connector_processor_migration()
	return "ConnectorProcessorMigrationValidation: ok" if warnings.is_empty() else "ConnectorProcessorMigrationValidation:
- " + "
- ".join(warnings)

func _to_stable_validation_summary(value: Variant) -> String:
	if value == null:
		return "null"
	if value is Dictionary:
		var dict_value: Dictionary = Dictionary(value)
		var keys: Array[String] = []
		for key_variant in dict_value.keys():
			keys.append(String(key_variant))
		keys.sort()
		var parts: Array[String] = []
		for key in keys:
			parts.append("%s:%s" % [key, _to_stable_validation_summary(dict_value.get(key, null))])
		return "{%s}" % ",".join(parts)
	if value is Array:
		var arr_value: Array = Array(value)
		var items: Array[String] = []
		for item in arr_value:
			items.append(_to_stable_validation_summary(item))
		return "[%s]" % ",".join(items)
	return str(value)

func _build_developer_validation_runtime_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	snapshot["mission_id"] = "unavailable"
	snapshot["mission_state"] = "unavailable"
	snapshot["world_objects"] = _to_stable_validation_summary(mission_world_objects)
	snapshot["inventory"] = _to_stable_validation_summary(runtime_inventory_state)
	snapshot["cell_items"] = _to_stable_validation_summary(cell_items)
	if active_bipob_ref != null and _active_bipob_has_property("installed_modules"):
		snapshot["installed_modules"] = _to_stable_validation_summary(active_bipob_ref.installed_modules)
	else:
		snapshot["installed_modules"] = "unavailable"
	if active_bipob_ref != null and active_bipob_ref.has_method("preview_module_port_activity"):
		snapshot["port_state"] = _to_stable_validation_summary(active_bipob_ref.call("preview_module_port_activity"))
	else:
		snapshot["port_state"] = "unavailable"
	snapshot["capability_report"] = _to_stable_validation_summary(get_actor_capability_levels())
	var task_state: Dictionary = {}
	var property_names: Dictionary = {}
	for property_data in get_property_list():
		var property_dict: Dictionary = Dictionary(property_data)
		var property_name: String = String(property_dict.get("name", ""))
		if property_name.is_empty():
			continue
		property_names[property_name] = true
	for task_field in ["task_test_started", "task_test_completed", "task_test_failed", "task_test_turns_left", "task_test_auto_seeded", "task_test_progress", "task_test_state"]:
		if property_names.has(task_field):
			task_state[task_field] = get(task_field)
	snapshot["task_state"] = _to_stable_validation_summary(task_state)
	return snapshot


func get_developer_systems_logic_audit() -> Dictionary:
	var systems: Array[Dictionary] = [
		{
			"id":"power",
			"display_name":"Power",
			"status":"implemented",
			"has_runtime_logic":true,
			"has_validation":true,
			"has_task_test_coverage":true,
			"related_validation_suite":"power",
			"notes":["Power graph, sources, consumers, and propagation are validated in developer suites."],
			"gaps":[]
		},
		{"id":"cooling","display_name":"Cooling","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"cooling_cable","notes":["Cooling runtime behavior is covered together with cable flow checks."],"gaps":[]},
		{"id":"cable_socket_reel","display_name":"Cable / Socket / Cable Reel","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"cooling_cable","notes":["Cable connectivity, socket linking, and reel interactions are checked by runtime validation."],"gaps":[]},
		{"id":"terminal_hacking","display_name":"Terminal / Hacking","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"terminal_door","notes":["Terminal operations and access interactions are included in terminal/door checks."],"gaps":[]},
		{"id":"doors_access","display_name":"Doors / Access","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"terminal_door","notes":["Door lock/access behavior is covered by runtime door validation."],"gaps":[]},
		{"id":"inventory_items","display_name":"Inventory / Items","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"inventory_tools_modules","notes":["Inventory and item interactions are checked in inventory/tools/modules suite."],"gaps":[]},
		{"id":"tools_modules","display_name":"Tools / Modules","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"inventory_tools_modules","notes":["Tool usage and module workflows have runtime validation coverage."],"gaps":[]},
		{"id":"module_ports","display_name":"Module Ports","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"module_ports","notes":["Module port activation and network mapping are validated."],"gaps":[]},
		{"id":"connector_processor_requirements","display_name":"Connector / Processor Requirements","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"connector_processor_migration","notes":["Connector/processor migration and requirements are validated."],"gaps":[]},
		{"id":"platforms","display_name":"Platforms","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"platform_scan_visibility","notes":["Platform activation, timing, and gating are covered in runtime validation."],"gaps":[]},
		{"id":"scan_visibility_xray","display_name":"Scan / Visibility / X-Ray","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"platform_scan_visibility","notes":["Scanning and visibility logic are covered alongside platform validation."],"gaps":[]},
		{"id":"persistence","display_name":"Persistence","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":false,"related_validation_suite":"persistence","notes":["Runtime persistence consistency is validated."],"gaps":["persistence_task_test_coverage_missing"]},
		{"id":"task_test","display_name":"TASK TEST","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"task_test","notes":["TASK TEST scenario and mission checks are part of developer validation."],"gaps":[]},
		{"id":"extraction","display_name":"Extraction","status":"partial","has_runtime_logic":true,"has_validation":false,"has_task_test_coverage":true,"related_validation_suite":"","notes":["Extraction flow exists but is not represented as a dedicated validation suite yet."],"gaps":["extraction_validation_missing"]},
		{"id":"visual_isometric_floor_walls_objects","display_name":"Visual Isometric Floor / Walls / Objects","status":"visual_only","has_runtime_logic":false,"has_validation":false,"has_task_test_coverage":false,"related_validation_suite":"","notes":["Rendering layer is visual-first and intentionally decoupled from gameplay mutation logic."],"gaps":["visual_isometric_objects_validation_missing"]}
	]
	return {"systems": systems}

func validate_developer_systems_logic_audit() -> Array[String]:
	var warnings: Array[String] = []
	var report: Dictionary = get_developer_systems_logic_audit()
	var systems: Array = Array(report.get("systems", []))
	if systems.is_empty():
		warnings.append("audit_report_empty")
		return warnings
	var required_fields: Array[String] = ["id", "display_name", "status", "has_runtime_logic", "has_validation", "has_task_test_coverage", "related_validation_suite", "notes", "gaps"]
	var allowed_status: Dictionary = {"implemented":true, "partial":true, "data_only":true, "visual_only":true, "missing":true}
	var ids: Dictionary = {}
	for entry_variant in systems:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			warnings.append("audit_system_missing_required_field_unknown_id")
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var system_id: String = String(entry.get("id", ""))
		if not system_id.is_empty():
			ids[system_id] = true
		for field_name in required_fields:
			if not entry.has(field_name):
				warnings.append("audit_system_missing_required_field_%s_%s" % [system_id, field_name])
		var status: String = String(entry.get("status", ""))
		if not allowed_status.has(status):
			warnings.append("audit_system_invalid_status_%s" % system_id)
	if not ids.has("power"):
		warnings.append("audit_system_missing_power")
	if not ids.has("terminal_hacking"):
		warnings.append("audit_system_missing_terminal")
	if not ids.has("module_ports"):
		warnings.append("audit_system_missing_module_ports")
	if not ids.has("task_test"):
		warnings.append("audit_system_missing_task_test")
	return warnings

func get_developer_systems_logic_audit_text() -> String:
	var report: Dictionary = get_developer_systems_logic_audit()
	var systems: Array = Array(report.get("systems", []))
	var lines: Array[String] = ["DeveloperSystemsLogicAudit:"]
	var gaps: Array[String] = []
	for entry_variant in systems:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var status: String = String(entry.get("status", "missing"))
		var logic_flag: String = "yes" if bool(entry.get("has_runtime_logic", false)) else "no"
		var validation_flag: String = "yes" if bool(entry.get("has_validation", false)) else "no"
		var task_test_flag: String = "yes" if bool(entry.get("has_task_test_coverage", false)) else "no"
		lines.append("- %s: %s logic=%s validation=%s task_test=%s" % [String(entry.get("id", "unknown")), status, logic_flag, validation_flag, task_test_flag])
		for gap_variant in Array(entry.get("gaps", [])):
			var gap_id: String = String(gap_variant)
			if gap_id.is_empty():
				continue
			if gaps.has(gap_id):
				continue
			gaps.append(gap_id)
	if not gaps.is_empty():
		lines.append("")
		lines.append("Gaps:")
		for gap in gaps:
			lines.append("- %s" % gap)
	return "\n".join(lines)

func validate_developer_validation_no_mutation() -> Array[String]:
	var warnings: Array[String] = []
	var baseline: Dictionary = _build_developer_validation_runtime_snapshot()
	get_developer_validation_suite_text("module_ports")
	get_developer_validation_suite_text("connector_processor_migration")
	_get_developer_validation_suite_text_internal("all", false)
	run_developer_validation_suite("module_ports")
	run_developer_validation_suite("connector_processor_migration")
	_run_developer_validation_suite_internal("all", false)
	var after: Dictionary = _build_developer_validation_runtime_snapshot()
	if String(after.get("mission_id", "")) != String(baseline.get("mission_id", "")):
		warnings.append("developer_validation_mutated_mission_id")
	if String(after.get("mission_state", "")) != String(baseline.get("mission_state", "")):
		warnings.append("developer_validation_mutated_mission_state")
	if String(after.get("world_objects", "")) != String(baseline.get("world_objects", "")):
		warnings.append("developer_validation_mutated_world_objects")
	if String(after.get("inventory", "")) != String(baseline.get("inventory", "")):
		warnings.append("developer_validation_mutated_inventory")
	if String(after.get("installed_modules", "")) != String(baseline.get("installed_modules", "")):
		warnings.append("developer_validation_mutated_installed_modules")
	if String(after.get("port_state", "")) != String(baseline.get("port_state", "")):
		warnings.append("developer_validation_mutated_port_state")
	if String(after.get("capability_report", "")) != String(baseline.get("capability_report", "")):
		warnings.append("developer_validation_mutated_capability_report")
	if String(after.get("task_state", "")) != String(baseline.get("task_state", "")):
		warnings.append("developer_validation_mutated_task_state")
	return warnings

func get_developer_validation_no_mutation_text() -> String:
	var warnings: Array[String] = validate_developer_validation_no_mutation()
	if warnings.is_empty():
		return "DeveloperValidationNoMutation: ok"
	return "DeveloperValidationNoMutation:\n- " + "\n- ".join(warnings)

func run_developer_validation_suite(suite: String = "all") -> Dictionary:
	return _run_developer_validation_suite_internal(suite, true)

func _run_developer_validation_suite_internal(suite: String = "all", include_no_mutation: bool = true) -> Dictionary:
	var suites: Array[String] = ["power", "cooling_cable", "terminal_door", "platform_scan_visibility", "inventory_tools_modules", "persistence", "task_test", "module_ports", "connector_processor_migration", "systems_audit"]
	if include_no_mutation:
		suites.append("no_mutation")
	var selected: Array = suites if suite == "all" else [suite]
	var warnings_by_suite: Dictionary = {}
	var suites_run := 0
	for suite_id in selected:
		var warnings: Array[String] = []
		match suite_id:
			"power": warnings = validate_full_power_system_runtime()
			"cooling_cable": warnings = validate_cooling_and_cable_runtime()
			"terminal_door": warnings = validate_terminal_and_door_runtime()
			"platform_scan_visibility": warnings = validate_platform_scan_visibility_runtime()
			"inventory_tools_modules": warnings = validate_inventory_tools_modules_runtime()
			"persistence": warnings = validate_full_runtime_persistence()
			"task_test": warnings = validate_task_test_mission_runtime()
			"module_ports": warnings = validate_module_port_network_runtime()
			"connector_processor_migration": warnings = validate_connector_processor_migration()
			"systems_audit": warnings = validate_developer_systems_logic_audit()
			"no_mutation": warnings = validate_developer_validation_no_mutation()
			_: warnings = ["suite_missing"]
		warnings_by_suite[suite_id] = warnings
		suites_run += 1
	var warnings_count: int = 0
	for k in warnings_by_suite.keys():
		warnings_count += Array(warnings_by_suite[k]).size()
	return {"suite": suite, "suites_run": suites_run, "warnings_count": warnings_count, "warnings_by_suite": warnings_by_suite}

func get_developer_validation_menu_text() -> String:
	return "Validation suites: all, power, cooling_cable, terminal_door, platform_scan_visibility, inventory_tools_modules, persistence, task_test, module_ports, connector_processor_migration, systems_audit, no_mutation"

func get_developer_validation_suite_text(suite: String = "all") -> String:
	return _get_developer_validation_suite_text_internal(suite, true)

func _get_developer_validation_suite_text_internal(suite: String = "all", include_no_mutation: bool = true) -> String:
	if suite == "no_mutation":
		return get_developer_validation_no_mutation_text()
	if suite == "systems_audit":
		return get_developer_systems_logic_audit_text()
	var report: Dictionary = _run_developer_validation_suite_internal(suite, include_no_mutation)
	var lines: Array[String] = ["DeveloperValidation suite=%s suites_run=%d warnings=%d" % [suite, int(report.get("suites_run", 0)), int(report.get("warnings_count", 0))]]
	var by_suite: Dictionary = Dictionary(report.get("warnings_by_suite", {}))
	for suite_id_variant in by_suite.keys():
		var suite_id: String = String(suite_id_variant)
		var suite_warnings: Array = Array(by_suite.get(suite_id_variant, []))
		lines.append("- %s: %d warning(s)" % [suite_id, suite_warnings.size()])
		for warning in suite_warnings:
			lines.append("  • %s" % String(warning))
	return "\n".join(lines)

var _map_constructor_last_kit_snapshot: Dictionary = {}
var _map_constructor_last_template_snapshot: Dictionary = {}

func _map_constructor_transform_template_offset(offset: Vector2i, options: Dictionary = {}) -> Vector2i:
	var transformed: Vector2i = Vector2i(offset)
	if bool(options.get("mirror_x", false)):
		transformed.x = -transformed.x
	if bool(options.get("mirror_y", false)):
		transformed.y = -transformed.y
	var rotation: int = int(options.get("rotation", 0))
	match rotation:
		0:
			return transformed
		90:
			return Vector2i(-transformed.y, transformed.x)
		180:
			return Vector2i(-transformed.x, -transformed.y)
		270:
			return Vector2i(transformed.y, -transformed.x)
		_:
			push_warning("Map constructor template: unsupported rotation=%d; treated as 0." % rotation)
			return transformed

func _map_constructor_filter_entry_rows(entries: Array, warnings: Array[String], removed_missing_ids: Array[String]) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	var catalog_ids: Dictionary = {}
	for catalog_row in get_map_constructor_prefab_catalog():
		var catalog_entry: Dictionary = Dictionary(catalog_row)
		catalog_ids[String(catalog_entry.get("id", ""))] = true
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var prefab_id: String = String(entry.get("prefab_id", "")).strip_edges()
		if not catalog_ids.has(prefab_id):
			if not removed_missing_ids.has(prefab_id):
				removed_missing_ids.append(prefab_id)
			continue
		filtered.append(entry)
	if not removed_missing_ids.is_empty():
		warnings.append("Removed missing prefab ids: %s" % ", ".join(removed_missing_ids))
	return filtered

func get_map_constructor_prefab_kits() -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "kits": [], "message": "Prefab kits are available only in TASK TEST constructor mode."}
	var kits: Array[Dictionary] = [
		{"id":"locked_door_kit","display_name":"Locked Door Kit","category":"security","description":"Door + terminal + access key.","tags":["door","terminal","key"],"default_options":{"allow_overwrite":false},"entries":[{"prefab_id":"digital_door","offset":Vector2i(0,0),"wall_side":"","properties":{},"link_group":"door_a"},{"prefab_id":"door_terminal","offset":Vector2i(-1,0),"wall_side":"","properties":{},"link_group":"door_a"},{"prefab_id":"access_code","offset":Vector2i(-2,0),"wall_side":"","properties":{},"link_group":""}]},
		{"id":"power_gate_kit","display_name":"Power Gate Kit","category":"power","description":"Power chain to powered gate.","tags":["power","gate"],"default_options":{"allow_overwrite":false},"entries":[{"prefab_id":"power_source_class_1","offset":Vector2i(-2,0),"wall_side":"","properties":{},"link_group":""},{"prefab_id":"power_cable","offset":Vector2i(-1,0),"wall_side":"","properties":{},"link_group":""},{"prefab_id":"power_socket","offset":Vector2i(0,0),"wall_side":"","properties":{},"link_group":""},{"prefab_id":"powered_gate","offset":Vector2i(1,0),"wall_side":"","properties":{},"link_group":""}]},
		{"id":"wall_terminal_kit","display_name":"Wall Terminal Kit","category":"control","description":"Wall-mounted terminal chain.","tags":["wall_mounted","terminal"],"default_options":{"allow_overwrite":false},"entries":[{"prefab_id":"door_terminal","offset":Vector2i(0,0),"wall_side":"north","properties":{},"link_group":"terminal_group"}]},
		{"id":"diagnostic_device_kit","display_name":"Diagnostic Device Kit","category":"diagnostic","description":"Diagnostic fixtures.","tags":["diagnostic"],"default_options":{"allow_overwrite":false},"entries":[{"prefab_id":"firewall","offset":Vector2i(0,0),"wall_side":"east","properties":{},"link_group":""}]},
		{"id":"expected_invalid_refs_kit","display_name":"Expected Invalid Refs Kit","category":"expected_invalid","description":"Creates expected invalid test rows.","tags":["expected_invalid"],"default_options":{"allow_overwrite":false},"entries":[{"prefab_id":"broken_reference_probe","offset":Vector2i(0,0),"wall_side":"","properties":{},"link_group":""}],"warning":"Some entries unavailable"},
		{"id":"cooling_test_kit","display_name":"Cooling Test Kit","category":"power","description":"Cooling and power test objects.","tags":["cooling","power"],"default_options":{"allow_overwrite":false},"entries":[{"prefab_id":"cooling_terminal","offset":Vector2i(0,0),"wall_side":"south","properties":{},"link_group":""}]},
		{"id":"control_chain_kit","display_name":"Control Chain Kit","category":"control","description":"Control + power chain.","tags":["control","power"],"default_options":{"allow_overwrite":false},"entries":[{"prefab_id":"circuit_breaker","offset":Vector2i(0,0),"wall_side":"","properties":{},"link_group":"control_a"},{"prefab_id":"light_switch","offset":Vector2i(1,0),"wall_side":"west","properties":{},"link_group":"control_a"}]}
	]
	var filtered_kits: Array[Dictionary] = []
	for kit_variant in kits:
		var kit: Dictionary = Dictionary(kit_variant).duplicate(true)
		var row_warnings: Array[String] = []
		var entries: Array = Array(kit.get("entries", []))
		var removed_missing_ids: Array[String] = []
		kit["entries"] = _map_constructor_filter_entry_rows(entries, row_warnings, removed_missing_ids)
		if not row_warnings.is_empty():
			var existing_warning: String = String(kit.get("warning", "")).strip_edges()
			var joined_warnings: String = "; ".join(row_warnings)
			kit["warning"] = joined_warnings if existing_warning.is_empty() else "%s; %s" % [existing_warning, joined_warnings]
		if Array(kit.get("entries", [])).is_empty():
			continue
		filtered_kits.append(kit)
	return {"ok":true,"kits":filtered_kits,"message":"OK"}

func preview_map_constructor_prefab_kit(kit_id: String, anchor_cell: Vector2i, options: Dictionary = {}) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "kit_id": kit_id, "anchor_cell": anchor_cell, "affected": [], "warnings": [], "conflicts": [], "can_apply": false, "message": "Kit preview is available only in TASK TEST constructor mode."}
	var kits: Array = Array(get_map_constructor_prefab_kits().get("kits", []))
	var kit: Dictionary = {}
	for row in kits:
		if String(row.get("id", "")) == kit_id:
			kit = Dictionary(row)
			break
	if kit.is_empty():
		return {"ok":false,"kit_id":kit_id,"anchor_cell":anchor_cell,"affected":[],"warnings":[],"conflicts":[],"can_apply":false,"message":"Kit not found."}
	var preview: Dictionary = _preview_map_constructor_entry_set(Array(kit.get("entries", [])), anchor_cell, options)
	preview["kit_id"] = kit_id
	return preview

func apply_map_constructor_prefab_kit(kit_id: String, anchor_cell: Vector2i, options: Dictionary = {}) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Kit apply is available only in TASK TEST constructor mode."}
	var kits: Array = Array(get_map_constructor_prefab_kits().get("kits", []))
	var kit: Dictionary = {}
	for row in kits:
		if String(Dictionary(row).get("id", "")) == kit_id:
			kit = Dictionary(row)
			break
	if kit.is_empty():
		return {"ok": false, "message": "Kit not found."}
	_map_constructor_last_kit_snapshot = {"mission_world_objects": mission_world_objects.duplicate(true), "cell_items": cell_items.duplicate(true), "world_objects_by_cell": world_objects_by_cell.duplicate(true)}
	var apply_result: Dictionary = _apply_map_constructor_entry_set(Array(kit.get("entries", [])), anchor_cell, options)
	if not bool(apply_result.get("ok", false)):
		return apply_result
	var placed: int = int(apply_result.get("placed_count", 0))
	_record_map_constructor_change("kit", {"summary":"Applied kit %s: %d entries" % [kit_id, placed]})
	return {"ok":true,"message":"Kit applied.","placed_count":placed,"warnings":Array(apply_result.get("warnings", []))}

func undo_last_map_constructor_prefab_kit() -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Kit undo is available only in TASK TEST constructor mode."}
	if _map_constructor_last_kit_snapshot.is_empty():
		return {"ok":false,"message":"No kit snapshot."}
	mission_world_objects = Array(_map_constructor_last_kit_snapshot.get("mission_world_objects", [])).duplicate(true)
	cell_items = Dictionary(_map_constructor_last_kit_snapshot.get("cell_items", {})).duplicate(true)
	world_objects_by_cell = Dictionary(_map_constructor_last_kit_snapshot.get("world_objects_by_cell", {})).duplicate(true)
	_map_constructor_last_kit_snapshot.clear()
	_record_map_constructor_change("kit_undo", {"summary":"Undid last kit."})
	return {"ok":true,"message":"Kit undo completed."}

func get_map_constructor_room_templates() -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "templates": [], "message": "Room templates are available only in TASK TEST constructor mode."}
	var templates: Array[Dictionary] = [
		{"id":"small_locked_room","display_name":"Small Locked Room","category":"room","description":"Compact room with locked door.","size":Vector2i(4,4),"entries":[{"prefab_id":"digital_door","offset":Vector2i(1,0),"wall_side":"","properties":{},"link_group":"d"},{"prefab_id":"door_terminal","offset":Vector2i(0,1),"wall_side":"north","properties":{},"link_group":"d"}],"tile_edits":[],"tags":["room"],"default_options":{"rotation":0,"mirror_x":false,"mirror_y":false,"allow_overwrite":false}},
		{"id":"power_room","display_name":"Power Room","category":"room","description":"Small power setup.","size":Vector2i(4,4),"entries":[{"prefab_id":"power_source_class_1","offset":Vector2i(1,1),"wall_side":"","properties":{},"link_group":""}],"tile_edits":[],"tags":["power"],"default_options":{"rotation":0,"mirror_x":false,"mirror_y":false,"allow_overwrite":false}},
		{"id":"corridor_with_door","display_name":"Corridor With Door","category":"corridor","description":"Corridor section with a door.","size":Vector2i(5,3),"entries":[{"prefab_id":"digital_door","offset":Vector2i(2,1),"wall_side":"","properties":{},"link_group":""}],"tile_edits":[],"tags":["corridor"],"default_options":{"rotation":0,"mirror_x":false,"mirror_y":false,"allow_overwrite":false}},
		{"id":"terminal_alcove","display_name":"Terminal Alcove","category":"room","description":"Alcove with wall terminal.","size":Vector2i(3,3),"entries":[{"prefab_id":"door_terminal","offset":Vector2i(1,1),"wall_side":"east","properties":{},"link_group":""}],"tile_edits":[],"tags":["terminal"],"default_options":{"rotation":0,"mirror_x":false,"mirror_y":false,"allow_overwrite":false}},
		{"id":"diagnostic_test_bay","display_name":"Diagnostic Test Bay","category":"test","description":"Diagnostics layout.","size":Vector2i(5,4),"entries":[{"prefab_id":"firewall","offset":Vector2i(2,1),"wall_side":"west","properties":{},"link_group":""}],"tile_edits":[],"tags":["diagnostic"],"default_options":{"rotation":0,"mirror_x":false,"mirror_y":false,"allow_overwrite":false}},
		{"id":"empty_test_chamber","display_name":"Empty Test Chamber","category":"test","description":"Open chamber with tile edits only.","size":Vector2i(4,4),"entries":[],"tile_edits":[{"offset":Vector2i(1,1),"tile_id":0}],"tags":["empty"],"default_options":{"rotation":0,"mirror_x":false,"mirror_y":false,"allow_overwrite":true}},
		{"id":"wall_mounted_test_wall","display_name":"Wall-mounted Test Wall","category":"test","description":"Wall-mounted placement checks.","size":Vector2i(4,2),"entries":[{"prefab_id":"door_terminal","offset":Vector2i(1,0),"wall_side":"north","properties":{},"link_group":"wall"}],"tile_edits":[],"tags":["wall_mounted"],"default_options":{"rotation":0,"mirror_x":false,"mirror_y":false,"allow_overwrite":false}}
	]
	var filtered_templates: Array[Dictionary] = []
	for template_variant in templates:
		var template: Dictionary = Dictionary(template_variant).duplicate(true)
		var template_warnings: Array[String] = []
		var removed_missing_ids: Array[String] = []
		template["entries"] = _map_constructor_filter_entry_rows(Array(template.get("entries", [])), template_warnings, removed_missing_ids)
		if not template_warnings.is_empty():
			template["warning"] = "; ".join(template_warnings)
		if Array(template.get("entries", [])).is_empty() and Array(template.get("tile_edits", [])).is_empty():
			continue
		filtered_templates.append(template)
	return {"ok":true,"templates":filtered_templates,"message":"OK"}

func preview_map_constructor_room_template(template_id: String, anchor_cell: Vector2i, options: Dictionary = {}) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "template_id": template_id, "anchor_cell": anchor_cell, "affected": [], "warnings": [], "conflicts": [], "can_apply": false, "message": "Template preview is available only in TASK TEST constructor mode."}
	var tpls: Array = Array(get_map_constructor_room_templates().get("templates", []))
	for t in tpls:
		if String(Dictionary(t).get("id", "")) == template_id:
			var template: Dictionary = Dictionary(t)
			var preview: Dictionary = _preview_map_constructor_entry_set(Array(template.get("entries", [])), anchor_cell, options)
			var tile_edits_preview: Dictionary = preview_map_constructor_tile_edits(Array(template.get("tile_edits", [])), anchor_cell, options)
			preview["affected"] = Array(preview.get("affected", [])) + Array(tile_edits_preview.get("affected", []))
			preview["warnings"] = Array(preview.get("warnings", [])) + Array(tile_edits_preview.get("warnings", []))
			preview["conflicts"] = Array(preview.get("conflicts", [])) + Array(tile_edits_preview.get("conflicts", []))
			preview["can_apply"] = bool(preview.get("can_apply", false)) and bool(tile_edits_preview.get("can_apply", false))
			preview["template_id"] = template_id
			return preview
	return {"ok":false,"template_id":template_id,"anchor_cell":anchor_cell,"affected":[],"warnings":[],"conflicts":[],"can_apply":false,"message":"Template not found."}

func apply_map_constructor_room_template(template_id: String, anchor_cell: Vector2i, options: Dictionary = {}) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Template apply is available only in TASK TEST constructor mode."}
	var templates: Array = Array(get_map_constructor_room_templates().get("templates", []))
	var template: Dictionary = {}
	for row in templates:
		if String(Dictionary(row).get("id", "")) == template_id:
			template = Dictionary(row)
			break
	if template.is_empty():
		return {"ok": false, "message": "Template not found."}
	var tile_snapshot: Array[Dictionary] = []
	if not Array(template.get("tile_edits", [])).is_empty():
		if grid_manager == null or not grid_manager.has_method("get_tile"):
			return {"ok": false, "message": "Tile edits not applied: safe tile snapshot getter unavailable.", "warnings": ["Tile edits not applied: safe tile snapshot getter unavailable."]}
		var seen_cells: Dictionary = {}
		for tile_edit_variant in Array(template.get("tile_edits", [])):
			var tile_edit: Dictionary = Dictionary(tile_edit_variant)
			var transformed_offset: Vector2i = _map_constructor_transform_template_offset(Vector2i(tile_edit.get("offset", Vector2i.ZERO)), options)
			var target_cell: Vector2i = anchor_cell + transformed_offset
			var cell_key: String = _serialize_cell_key(target_cell)
			if seen_cells.has(cell_key):
				continue
			seen_cells[cell_key] = true
			tile_snapshot.append({"cell": target_cell, "tile_id": int(grid_manager.call("get_tile", target_cell))})
	_map_constructor_last_template_snapshot = {"mission_world_objects": mission_world_objects.duplicate(true), "cell_items": cell_items.duplicate(true), "world_objects_by_cell": world_objects_by_cell.duplicate(true), "tile_snapshot": tile_snapshot}
	var result: Dictionary = _apply_map_constructor_entry_set(Array(template.get("entries", [])), anchor_cell, options)
	if not bool(result.get("ok", false)):
		return result
	var tile_apply: Dictionary = apply_map_constructor_tile_edits(Array(template.get("tile_edits", [])), anchor_cell, options)
	result["warnings"] = Array(result.get("warnings", [])) + Array(tile_apply.get("warnings", []))
	if not bool(tile_apply.get("ok", false)):
		result["ok"] = false
		result["message"] = String(tile_apply.get("message", "Template tile edits failed."))
		return result
	if bool(result.get("ok", false)):
		_record_map_constructor_change("template", {"summary":"Applied template %s" % template_id})
	return result

func preview_map_constructor_tile_edits(tile_edits: Array, anchor_cell: Vector2i, options: Dictionary = {}) -> Dictionary:
	var allow_overwrite: bool = bool(options.get("allow_overwrite", false))
	var affected: Array[Dictionary] = []
	var conflicts: Array[Dictionary] = []
	var warnings: Array[String] = []
	var rotation: int = int(options.get("rotation", 0))
	if rotation != 0 and rotation != 90 and rotation != 180 and rotation != 270:
		warnings.append("Unsupported rotation=%d treated as 0." % rotation)
	for tile_edit_variant in tile_edits:
		var tile_edit: Dictionary = Dictionary(tile_edit_variant)
		var offset: Vector2i = Vector2i(tile_edit.get("offset", Vector2i.ZERO))
		var cell: Vector2i = anchor_cell + _map_constructor_transform_template_offset(offset, options)
		var conflict_reason: String = ""
		var object_here: Dictionary = Dictionary(world_objects_by_cell.get(cell, {}))
		if not allow_overwrite and not object_here.is_empty():
			conflict_reason = "cell_has_world_object"
		var items_here: Array[Dictionary] = get_items_at_cell(cell)
		if conflict_reason.is_empty() and not allow_overwrite and not items_here.is_empty():
			conflict_reason = "cell_has_items"
		if not conflict_reason.is_empty():
			conflicts.append({"operation":"tile_edit","cell":cell,"reason":conflict_reason,"message":"Tile edit blocked at %s." % str(cell)})
		affected.append({"operation":"tile_edit","cell":cell,"tile_id":int(tile_edit.get("tile_id", GridManager.TILE_FLOOR))})
	return {"ok": true, "affected": affected, "warnings": warnings, "conflicts": conflicts, "can_apply": conflicts.is_empty() or allow_overwrite}

func apply_map_constructor_tile_edits(tile_edits: Array, anchor_cell: Vector2i, options: Dictionary = {}) -> Dictionary:
	if grid_manager == null or not grid_manager.has_method("set_tile"):
		return {"ok": false, "warnings": ["Tile edits not applied: safe tile setter unavailable."], "message": "Tile edits not applied: safe tile setter unavailable."}
	if grid_manager == null or not grid_manager.has_method("get_tile"):
		return {"ok": false, "warnings": ["Tile edits not applied: safe tile snapshot getter unavailable."], "message": "Tile edits not applied: safe tile snapshot getter unavailable."}
	var preview: Dictionary = preview_map_constructor_tile_edits(tile_edits, anchor_cell, options)
	if not bool(preview.get("can_apply", false)):
		return {"ok": false, "warnings": [], "message": "Tile edits blocked by conflicts.", "conflicts": Array(preview.get("conflicts", []))}
	for affected_variant in Array(preview.get("affected", [])):
		var affected_row: Dictionary = Dictionary(affected_variant)
		grid_manager.call("set_tile", Vector2i(affected_row.get("cell", Vector2i(-1, -1))), int(affected_row.get("tile_id", GridManager.TILE_FLOOR)))
	return {"ok": true, "warnings": [], "message": "Tile edits applied."}

func undo_last_map_constructor_room_template() -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Template undo is available only in TASK TEST constructor mode."}
	if _map_constructor_last_template_snapshot.is_empty():
		return {"ok":false,"message":"No template snapshot."}
	mission_world_objects = Array(_map_constructor_last_template_snapshot.get("mission_world_objects", [])).duplicate(true)
	cell_items = Dictionary(_map_constructor_last_template_snapshot.get("cell_items", {})).duplicate(true)
	world_objects_by_cell = Dictionary(_map_constructor_last_template_snapshot.get("world_objects_by_cell", {})).duplicate(true)
	var warnings: Array[String] = []
	var tile_snapshot: Array = Array(_map_constructor_last_template_snapshot.get("tile_snapshot", []))
	if not tile_snapshot.is_empty():
		if grid_manager == null or not grid_manager.has_method("set_tile"):
			warnings.append("Template undo warning: tile snapshot exists but safe tile setter unavailable.")
		else:
			for snapshot_variant in tile_snapshot:
				var snapshot_row: Dictionary = Dictionary(snapshot_variant)
				grid_manager.call("set_tile", Vector2i(snapshot_row.get("cell", Vector2i(-1, -1))), int(snapshot_row.get("tile_id", GridManager.TILE_FLOOR)))
			if grid_manager.has_method("recalculate_visibility"):
				grid_manager.call("recalculate_visibility")
			if grid_manager.has_method("request_visual_refresh"):
				grid_manager.call("request_visual_refresh")
	_map_constructor_last_template_snapshot.clear()
	_record_map_constructor_change("template_undo", {"summary":"Undid last template."})
	if not warnings.is_empty():
		return {"ok": false, "warnings": warnings, "message": "Template undo partial: tile restore unavailable."}
	return {"ok":true,"warnings":[],"message":"Template undo completed."}

func export_map_constructor_design_notes(options: Dictionary = {}) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Design notes export is available only in TASK TEST constructor mode."}
	var patch_export: Dictionary = export_map_constructor_runtime_patch()
	var readiness: Dictionary = get_map_constructor_mission_readiness_report()
	var validation: Array = get_map_constructor_validation_issues()
	var wall_overrides: Array = Array(get_map_constructor_wall_material_overrides().get("overrides", []))
	var wall_counts: Dictionary = {}
	for row_variant in wall_overrides:
		var row: Dictionary = Dictionary(row_variant)
		var material_id: String = String(row.get("material_id", "unknown")).to_lower()
		wall_counts[material_id] = int(wall_counts.get(material_id, 0)) + 1
	var notes: Dictionary = {"schema_version":1,"source":"task_test_map_constructor","mission_id":"mission_10","generated_at_runtime":str(Time.get_unix_time_from_system()),"summary":{"object_count":mission_world_objects.size(),"wall_material_override_count":wall_overrides.size(),"wall_material_counts":wall_counts},"readiness":readiness,"validation":{"issues":validation},"objects":mission_world_objects.duplicate(true),"items":cell_items.values(),"tile_edits":Array(patch_export.get("patch", {}).get("tile_edits", [])),"links":Array(patch_export.get("patch", {}).get("links", [])),"patch":Dictionary(patch_export.get("patch", {})),"wall_material_overrides":wall_overrides,"history_summary":Array(get_map_constructor_change_history(20).get("history", [])),"overview_summary":Dictionary(get_map_constructor_overview_data().get("summary", {})),"recommended_next_steps":["Manual promotion required. No mission files were modified."]}
	var text: String = "# Design Notes\nMission: mission_10\nReadiness: %s\nValidation issues: %d\nPatch summary: objects=%d items=%d tiles=%d\nManual promotion required. No mission files were modified." % [String(readiness.get("status", "unknown")), validation.size(), int(patch_export.get("object_count", 0)), int(patch_export.get("item_count", 0)), int(patch_export.get("tile_edit_count", 0))]
	return {"ok":true,"message":"OK","notes":notes,"text":text}

func get_map_constructor_production_pipeline_report(options: Dictionary = {}) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "status": "blocked", "message": "Production pipeline report is available only in TASK TEST constructor mode.", "checks": []}
	var readiness: Dictionary = get_map_constructor_mission_readiness_report()
	var notes: Dictionary = export_map_constructor_design_notes()
	var patch_export: Dictionary = export_map_constructor_runtime_patch()
	var checks: Array[Dictionary] = []
	var validation_issues: Array = Array(get_map_constructor_validation_issues())
	var non_expected_errors: int = 0
	var warning_count: int = 0
	for issue_variant in validation_issues:
		var issue: Dictionary = Dictionary(issue_variant)
		var severity: String = String(issue.get("severity", "warning")).to_lower()
		var expected: bool = bool(issue.get("expected_invalid", false))
		if severity == "error" and not expected:
			non_expected_errors += 1
		if severity == "warning":
			warning_count += 1
	checks.append({"label":"TASK TEST constructor context active","status":"pass"})
	checks.append({"label":"readiness playable","status":"pass" if String(readiness.get("status", "")) == "playable" else "fail"})
	checks.append({"label":"validation blocking errors","status":"pass" if non_expected_errors <= 0 else "fail"})
	checks.append({"label":"patch export ok","status":"pass" if bool(patch_export.get("ok", false)) else "fail"})
	checks.append({"label":"design notes ok","status":"pass" if bool(notes.get("ok", false)) else "fail"})
	checks.append({"label":"validation warnings","status":"warning" if warning_count > 0 else "pass"})
	checks.append({"label":"readiness diagnostics","status":"info","message":"not checked"})
	var blocked: bool = String(readiness.get("status", "")) == "blocked" or not bool(readiness.get("ok", true)) or not bool(patch_export.get("ok", false)) or not bool(notes.get("ok", false)) or non_expected_errors > 0
	var has_warnings: bool = warning_count > 0
	var status: String = "blocked" if blocked else ("warning" if has_warnings else "ready")
	return {"ok":true,"status":status,"message":"Manual promotion required. No mission files were modified.","checks":checks,"promotion_package":{"patch":Dictionary(patch_export.get("patch", {})),"design_notes":Dictionary(notes.get("notes", {})),"summary":{"readiness":String(readiness.get("status", "unknown")),"wall_material_overrides":Array(get_map_constructor_wall_material_overrides().get("overrides", []))},"manual_steps":["Review design notes","Review patch JSON","Promote manually in controlled pipeline"],"warnings":[]},"recommended_actions":[]}

func _preview_map_constructor_entry_set(entries: Array, anchor_cell: Vector2i, options: Dictionary = {}) -> Dictionary:
	var conflicts: Array[Dictionary] = []
	var affected: Array[Dictionary] = []
	var warnings: Array[String] = []
	var allow_overwrite: bool = bool(options.get("allow_overwrite", false))
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var transformed_offset: Vector2i = _map_constructor_transform_template_offset(Vector2i(entry.get("offset", Vector2i.ZERO)), options)
		var cell: Vector2i = anchor_cell + transformed_offset
		var wall_side: String = String(entry.get("wall_side", ""))
		if bool(MAP_CONSTRUCTOR_WALL_MOUNTED_PREFABS.get(String(entry.get("prefab_id", "")), false)) and wall_side.is_empty():
			conflicts.append({"prefab_id":String(entry.get("prefab_id", "")), "cell": cell, "reason":"missing_wall_side", "message":"Wall-mounted prefab requires wall_side."})
			continue
		var check: Dictionary = can_place_map_constructor_prefab(String(entry.get("prefab_id", "")), cell, wall_side)
		if not bool(check.get("ok", false)):
			conflicts.append({"prefab_id":String(entry.get("prefab_id", "")),"cell":cell,"reason":String(check.get("reason", "blocked")),"message":String(check.get("message", "Blocked."))})
		affected.append({"prefab_id":String(entry.get("prefab_id", "")), "cell": cell})
		if not String(entry.get("link_group", "")).is_empty():
			warnings.append("Link group metadata preserved for %s; link resolver not applied." % String(entry.get("prefab_id", "")))
	return {"ok": true, "anchor_cell": anchor_cell, "affected": affected, "warnings": warnings, "conflicts": conflicts, "can_apply": conflicts.is_empty() or allow_overwrite, "message": "Preview ready."}

func _apply_map_constructor_entry_set(entries: Array, anchor_cell: Vector2i, options: Dictionary = {}) -> Dictionary:
	var preview: Dictionary = _preview_map_constructor_entry_set(entries, anchor_cell, options)
	var warnings: Array[String] = Array(preview.get("warnings", []))
	if not bool(preview.get("can_apply", false)):
		preview["ok"] = false
		preview["message"] = "Apply blocked by conflicts."
		return preview
	var placed_count: int = 0
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var transformed_offset: Vector2i = _map_constructor_transform_template_offset(Vector2i(entry.get("offset", Vector2i.ZERO)), options)
		var cell: Vector2i = anchor_cell + transformed_offset
		var wall_side: String = String(entry.get("wall_side", ""))
		var placed: Dictionary = place_map_constructor_prefab(String(entry.get("prefab_id", "")), cell, wall_side)
		if bool(placed.get("ok", false)):
			placed_count += 1
			var properties: Dictionary = Dictionary(entry.get("properties", {}))
			if not properties.is_empty():
				var placed_object_id: String = String(placed.get("object_id", ""))
				if placed_object_id.is_empty():
					warnings.append("Properties not applied: placement result did not include entity id.")
				else:
					for property_name_variant in properties.keys():
						var property_name: String = String(property_name_variant)
						var update_result: Dictionary = apply_map_constructor_property_update("world_object", placed_object_id, property_name, properties.get(property_name_variant))
						if not bool(update_result.get("ok", false)):
							warnings.append("Property '%s' not applied for %s." % [property_name, placed_object_id])
	return {"ok": true, "placed_count": placed_count, "warnings": warnings}
