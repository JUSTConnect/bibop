extends SceneTree

const WorldStateStoreRef = preload("res://scripts/world/world_state_store.gd")
const MissionManagerRef = preload("res://scripts/game/mission_manager.gd")
const BipobCableRuntimeServiceRef = preload("res://scripts/game/bipob_cable_runtime_service.gd")
const BipobAirflowRuntimeStateRef = preload("res://scripts/game/bipob_airflow_runtime_state.gd")
const FacingSideUtilsRef = preload("res://scripts/visual/facing_side_utils.gd")

var failures: Array[String] = []
var signal_events: Array[Dictionary] = []

class BoundsGridManager:
	extends Node
	var width := 2
	var height := 2
	func is_in_bounds(cell: Vector2i) -> bool:
		return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height

func _initialize() -> void:
	_run_store_checks()
	_run_mission_manager_checks()
	if failures.is_empty():
		print("World state store checks passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
	return

func _on_store_changed(change: Dictionary) -> void:
	signal_events.append(change)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _obj(id: String, cell: Vector2i, group: String = "device", object_type: String = "terminal") -> Dictionary:
	return {"id": id, "object_group": group, "object_type": object_type, "position": cell}

func _item(id: String, cell: Vector2i) -> Dictionary:
	return {"id": id, "object_group": "item", "object_type": "item", "position": cell}

func _cable(id: String, cell: Vector2i) -> Dictionary:
	return {"id": id, "object_group": "power", "object_type": "power_cable", "position": cell}

func _wall(id: String, cell: Vector2i, side: String) -> Dictionary:
	return {"id": id, "object_group": "terminal", "object_type": "terminal", "position": cell, "placement_mode": "wall_mounted", "mount": "wall", "is_wall_mounted": true, "wall_side": side}

func _platform(id: String, cell: Vector2i) -> Dictionary:
	return {"id": id, "object_group": "platform", "object_type": "platform", "position": cell, "platform_id": id, "platform_cells": [cell]}

func _occupant(id: String, cell: Vector2i) -> Dictionary:
	return {"id": id, "object_group": "physical_object", "object_type": "crate", "position": cell, "on_platform": true, "platform_id": "platform_a", "platform_placeable": true}

func _visual(id: String, cell: Vector2i) -> Dictionary:
	return {"id": id, "object_group": "floor", "object_type": "floor_stepped", "position": cell}

func _diagnostic_wall_sides_are_iso_only(snapshot: Dictionary) -> bool:
	var wall_by_side: Dictionary = Dictionary(snapshot.get("wall_by_side", {}))
	for cell in wall_by_side.keys():
		var by_side: Dictionary = Dictionary(wall_by_side.get(cell, {}))
		for side in by_side.keys():
			if not (str(side) in ["nw", "ne", "sw", "se"]):
				return false
	return true

func _objects_wall_sides_are_iso_only(objects: Array[Dictionary]) -> bool:
	for object_data in objects:
		var side := str(object_data.get("wall_side", ""))
		if side.is_empty():
			continue
		if not (side in ["nw", "ne", "sw", "se"]):
			return false
	return true

func _run_store_checks() -> void:
	_expect(FacingSideUtilsRef.is_wall_side("nw") and FacingSideUtilsRef.is_wall_side("ne") and FacingSideUtilsRef.is_wall_side("sw") and FacingSideUtilsRef.is_wall_side("se"), "FacingSideUtils owns iso wall sides")
	_expect(not FacingSideUtilsRef.is_wall_side("north") and FacingSideUtilsRef.normalize_legacy_wall_side_alias("north") == "nw", "FacingSideUtils treats north as legacy alias only")
	var store: WorldStateStore = WorldStateStoreRef.new()
	store.changed.connect(_on_store_changed)
	_expect(bool(store.add_object(_obj("door_a", Vector2i(1, 1))).get("ok", false)), "adding primary succeeds")
	_expect(bool(store.add_item(Vector2i(1, 1), _item("item_a", Vector2i(1, 1))).get("ok", false)), "primary + item coexist")
	_expect(bool(store.add_object(_cable("cable_a", Vector2i(1, 1))).get("ok", false)), "primary + cable coexist")
	_expect(bool(store.add_object(_wall("wall_nw", Vector2i(1, 1), "nw")).get("ok", false)), "primary + iso wall side coexist")
	_expect(bool(store.add_object(_wall("wall_ne", Vector2i(1, 1), "ne")).get("ok", false)), "different iso wall sides coexist")
	_expect(bool(store.add_object(_wall("wall_sw", Vector2i(1, 2), "sw")).get("ok", false)), "sw iso wall side is accepted")
	_expect(bool(store.add_object(_wall("wall_se", Vector2i(1, 2), "se")).get("ok", false)), "se iso wall side is accepted")
	_expect(bool(store.add_object(_platform("platform_a", Vector2i(2, 2))).get("ok", false)), "platform can be indexed separately")
	_expect(bool(store.add_object(_occupant("crate_a", Vector2i(2, 2))).get("ok", false)), "platform occupant coexists with platform")
	_expect(bool(store.add_object(_visual("visual_a", Vector2i(3, 3))).get("ok", false)), "visual floor can be added")
	_expect(bool(store.add_object(_obj("device_a", Vector2i(3, 3))).get("ok", false)), "visual floor + gameplay object coexist")
	var before_count := store.get_object_count()
	var before_snapshot := store.get_diagnostic_snapshot()
	var before_events := signal_events.size()
	_expect(not bool(store.add_object(_obj("door_b", Vector2i(1, 1))).get("ok", true)), "second primary fails")
	_expect(store.get_object_count() == before_count, "failed add preserves count")
	_expect(var_to_str(before_snapshot) == var_to_str(store.get_diagnostic_snapshot()), "failed add preserves indexes and order")
	_expect(signal_events.size() == before_events, "failed add emits no success event")
	_expect(not bool(store.add_object({"id":"missing_pos", "object_group":"device", "object_type":"terminal"}).get("ok", true)), "missing position is rejected")
	_expect(not bool(store.add_object({"id":"bad_pos", "object_group":"device", "object_type":"terminal", "position":"1,1"}).get("ok", true)), "malformed position is rejected")
	_expect(not bool(store.add_object(_obj("negative_pos", Vector2i(-1, 0))).get("ok", true)), "negative position is rejected")
	_expect(not bool(store.add_object({"id":"missing_side", "object_group":"terminal", "object_type":"terminal", "position":Vector2i(8, 8), "placement_mode":"wall_mounted", "mount":"wall", "is_wall_mounted":true}).get("ok", true)), "missing wall side is rejected")
	_expect(not bool(store.add_object(_wall("bad_side", Vector2i(8, 8), "ceiling")).get("ok", true)), "invalid wall side is rejected")
	_expect(not bool(store.add_object(_wall("bad_left", Vector2i(8, 8), "left")).get("ok", true)), "left wall side is rejected")
	_expect(not bool(store.add_object(_wall("bad_right", Vector2i(8, 8), "right")).get("ok", true)), "right wall side is rejected")
	var before_move_state := store.get_diagnostic_snapshot()
	before_events = signal_events.size()
	var failed_move := store.move_object("device_a", Vector2i(1, 1))
	_expect(not bool(failed_move.get("ok", true)), "moving primary into occupied primary fails")
	_expect(str(store.get_primary_object_at_cell(Vector2i(3, 3)).get("id", "")) == "device_a", "failed move leaves old primary index")
	_expect(var_to_str(before_move_state) == var_to_str(store.get_diagnostic_snapshot()), "failed move preserves indexes and order")
	_expect(signal_events.size() == before_events, "failed move emits no success event")
	var before_failed_snapshot_state := store.get_diagnostic_snapshot()
	before_events = signal_events.size()
	var failed_snapshot := store.replace_snapshot([_obj("ok", Vector2i.ZERO), _obj("bad", Vector2i.ZERO)])
	_expect(not bool(failed_snapshot.get("ok", true)), "conflicting snapshot fails")
	_expect(store.get_object_count() == before_count, "failed snapshot preserves live state")
	_expect(var_to_str(before_failed_snapshot_state) == var_to_str(store.get_diagnostic_snapshot()), "failed snapshot preserves previous state and indexes")
	_expect(signal_events.size() == before_events, "failed snapshot emits no success event")
	_expect(not bool(store.replace_snapshot([_obj("snapshot_ok", Vector2i(11, 11)), _wall("snapshot_bad_side", Vector2i(11, 11), "")]).get("ok", true)), "snapshot rejects missing wall side")
	_expect(not bool(store.move_object("door_a", Vector2i(4, 4), {"id": "hacked"}).get("ok", true)), "move id patch fails")
	_expect(not bool(store.update_object_state("door_a", {"id": "hacked"}).get("ok", true)), "state id patch fails")
	_expect(str(store.get_object_by_id("wall_nw").get("wall_side", "")) == "nw", "canonical nw side remains in object state")
	_expect(str(store.get_object_by_id("wall_ne").get("wall_side", "")) == "ne", "canonical ne side remains in object state")
	_expect(store.get_wall_mounted_objects_at_cell_side(Vector2i(1, 1), "nw").size() == 1, "side lookup returns nw object")
	_expect(store.get_wall_mounted_objects_at_cell_side(Vector2i(1, 1), "north").size() == 1, "legacy north lookup maps to nw object")
	_expect(store.get_wall_mounted_objects_at_cell_side(Vector2i(1, 1), "ne").size() == 1, "side lookup returns ne object")
	_expect(store.get_wall_mounted_objects_at_cell_side(Vector2i(1, 1), "east").size() == 1, "legacy east lookup maps to ne object")
	_expect(not bool(store.add_object(_wall("wall_n2", Vector2i(1, 1), "north")).get("ok", true)), "legacy same wall side conflict fails")
	var legacy_store: WorldStateStore = WorldStateStoreRef.new()
	_expect(bool(legacy_store.replace_snapshot([_wall("legacy_north", Vector2i(2, 1), "north"), _wall("legacy_east", Vector2i(2, 1), "east"), _wall("legacy_south", Vector2i(2, 1), "south"), _wall("legacy_west", Vector2i(2, 1), "west")]).get("ok", false)), "legacy cardinal wall sides migrate")
	_expect(str(legacy_store.get_object_by_id("legacy_north").get("wall_side", "")) == "nw", "legacy north normalizes to nw")
	_expect(str(legacy_store.get_object_by_id("legacy_east").get("wall_side", "")) == "ne", "legacy east normalizes to ne")
	_expect(str(legacy_store.get_object_by_id("legacy_south").get("wall_side", "")) == "se", "legacy south normalizes to se")
	_expect(str(legacy_store.get_object_by_id("legacy_west").get("wall_side", "")) == "sw", "legacy west normalizes to sw")
	_expect(_diagnostic_wall_sides_are_iso_only(legacy_store.get_diagnostic_snapshot()), "legacy snapshot indexes use only iso wall sides")
	_expect(_objects_wall_sides_are_iso_only(legacy_store.get_all_objects()), "legacy snapshot objects use only iso wall sides")
	var before_update_structure_state := store.get_diagnostic_snapshot()
	before_events = signal_events.size()
	_expect(not bool(store.update_object_structure("wall_ne", {"wall_side": "north"}).get("ok", true)), "legacy conflicting wall side update fails")
	_expect(var_to_str(before_update_structure_state) == var_to_str(store.get_diagnostic_snapshot()), "failed update_structure preserves indexes and order")
	_expect(signal_events.size() == before_events, "failed update_structure emits no success event")
	_expect(bool(store.update_object_structure("wall_ne", {"wall_side": "south"}).get("ok", false)), "legacy wall side update normalizes and succeeds")
	_expect(store.get_wall_mounted_objects_at_cell_side(Vector2i(1, 1), "ne").is_empty(), "old iso wall side index clears")
	_expect(store.get_wall_mounted_objects_at_cell_side(Vector2i(1, 1), "se").size() == 1, "new iso wall side index updates")
	_expect(str(store.get_object_by_id("wall_ne").get("wall_side", "")) == "se", "legacy update stores iso wall side")
	_expect(_diagnostic_wall_sides_are_iso_only(store.get_diagnostic_snapshot()), "store indexes use only iso wall sides")
	_expect(_objects_wall_sides_are_iso_only(store.get_all_objects()), "store object state uses only iso wall sides")
	var read_object := store.get_object_by_id("door_a")
	read_object["position"] = Vector2i(99, 99)
	_expect(str(store.get_primary_object_at_cell(Vector2i(1, 1)).get("id", "")) == "door_a", "get_object_by_id returns isolated copy")
	var all_objects := store.get_all_objects()
	all_objects[0]["position"] = Vector2i(99, 99)
	_expect(str(store.get_primary_object_at_cell(Vector2i(1, 1)).get("id", "")) == "door_a", "get_all_objects returns isolated copies")
	var items := store.get_items_at_cell(Vector2i(1, 1))
	items[0]["position"] = Vector2i(99, 99)
	_expect(store.get_items_at_cell(Vector2i(1, 1)).size() == 1, "get_items_at_cell returns isolated copies")
	var walls := store.get_wall_mounted_objects_at_cell(Vector2i(1, 1))
	walls[0]["position"] = Vector2i(99, 99)
	_expect(store.get_wall_mounted_objects_at_cell(Vector2i(1, 1)).size() == 2, "wall lookup returns isolated copies")
	_expect(store.validate_consistency().is_empty(), "valid operations leave consistent store")
	var invalid := WorldStateStoreRef.new()
	invalid._objects_by_id["key_a"] = {"id": "field_b", "position": Vector2i.ZERO}
	invalid._object_order.append("key_a")
	_expect(not invalid.validate_consistency().is_empty(), "key/field id mismatch detected")
	var structural_invalid := WorldStateStoreRef.new()
	structural_invalid._objects_by_id["missing_pos"] = {"id":"missing_pos", "object_group":"device", "object_type":"terminal"}
	structural_invalid._objects_by_id["malformed_pos"] = {"id":"malformed_pos", "object_group":"device", "object_type":"terminal", "position":"bad"}
	structural_invalid._objects_by_id["negative_pos"] = {"id":"negative_pos", "object_group":"device", "object_type":"terminal", "position":Vector2i(-1, 0)}
	structural_invalid._objects_by_id["missing_side"] = {"id":"missing_side", "object_group":"terminal", "object_type":"terminal", "position":Vector2i(1, 1), "placement_mode":"wall_mounted", "mount":"wall", "is_wall_mounted":true}
	structural_invalid._objects_by_id["invalid_side"] = _wall("invalid_side", Vector2i(1, 2), "ceiling")
	structural_invalid._object_order.append_array(["missing_pos", "malformed_pos", "negative_pos", "missing_side", "invalid_side"])
	var structural_warnings: Array[String] = structural_invalid.validate_consistency()
	for expected_warning in ["missing_position:missing_pos", "malformed_position:malformed_pos", "negative_position:negative_pos", "missing_wall_side:missing_side", "invalid_wall_side:invalid_side"]:
		_expect(structural_warnings.has(expected_warning), "validate_consistency reports missing_position/malformed_position/negative_position/missing_wall_side/invalid_wall_side: %s" % expected_warning)
	var bridge_store: WorldStateStore = WorldStateStoreRef.new()
	bridge_store.changed.connect(_on_store_changed)
	bridge_store.add_object(_obj("bridge_a", Vector2i(20, 20)))
	signal_events.clear()
	var bridge_snapshot := bridge_store.get_all_objects()
	bridge_snapshot[0]["is_powered"] = true
	bridge_snapshot[0]["runtime_added"] = "yes"
	_expect(not bool(bridge_store.get_object_by_id("bridge_a").get("is_powered", false)), "snapshot mutation is isolated before commit")
	var bridge_result := bridge_store.apply_non_structural_snapshot(bridge_snapshot, "test_runtime_update")
	_expect(bool(bridge_result.get("ok", false)), "non-structural snapshot commit succeeds")
	_expect(bool(bridge_store.get_object_by_id("bridge_a").get("is_powered", false)), "non-structural field change persists")
	_expect(str(bridge_store.get_object_by_id("bridge_a").get("runtime_added", "")) == "yes", "non-structural field addition persists")
	_expect(signal_events.size() == 1 and str(signal_events[0].get("action", "")) == "test_runtime_update", "batch commit emits one signal")
	signal_events.clear()
	bridge_snapshot = bridge_store.get_all_objects()
	bridge_snapshot[0].erase("runtime_added")
	_expect(bool(bridge_store.apply_non_structural_snapshot(bridge_snapshot, "test_runtime_remove").get("ok", false)), "non-structural field removal commit succeeds")
	_expect(not bridge_store.get_object_by_id("bridge_a").has("runtime_added"), "non-structural field removal persists")
	var before_bad := bridge_store.get_object_by_id("bridge_a")
	var bad_snapshot := bridge_store.get_all_objects()
	bad_snapshot[0]["position"] = Vector2i(99, 99)
	_expect(not bool(bridge_store.apply_non_structural_snapshot(bad_snapshot, "bad_position").get("ok", true)), "structural position change is rejected")
	_expect(bridge_store.get_object_by_id("bridge_a") == before_bad, "failed bridge commit leaves state unchanged")
	bad_snapshot = bridge_store.get_all_objects()
	bad_snapshot[0]["id"] = "other"
	_expect(not bool(bridge_store.apply_non_structural_snapshot(bad_snapshot, "bad_id").get("ok", true)), "id change is rejected")
	bad_snapshot = bridge_store.get_all_objects()
	bad_snapshot[0]["object_group"] = "item"
	_expect(not bool(bridge_store.apply_non_structural_snapshot(bad_snapshot, "bad_layer").get("ok", true)), "layer-changing object_group is rejected")
	_expect(not bool(bridge_store.apply_non_structural_snapshot([], "missing").get("ok", true)), "missing object is rejected")
	bad_snapshot = bridge_store.get_all_objects()
	bad_snapshot.append(_obj("extra", Vector2i.ZERO))
	_expect(not bool(bridge_store.apply_non_structural_snapshot(bad_snapshot, "extra").get("ok", true)), "extra object is rejected")
	bad_snapshot = bridge_store.get_all_objects()
	bad_snapshot.append(bad_snapshot[0].duplicate(true))
	_expect(not bool(bridge_store.apply_non_structural_snapshot(bad_snapshot, "duplicate").get("ok", true)), "duplicate object is rejected")
	var bridge_indexes := bridge_store.get_diagnostic_snapshot()
	bridge_snapshot = bridge_store.get_all_objects()
	bridge_snapshot[0]["is_powered"] = false
	bridge_store.apply_non_structural_snapshot(bridge_snapshot, "index_preserving")
	_expect(var_to_str(bridge_indexes.get("primary", {})) == var_to_str(bridge_store.get_diagnostic_snapshot().get("primary", {})), "non-structural commit does not change indexes")

	var order_store: WorldStateStore = WorldStateStoreRef.new()
	order_store.replace_snapshot([_obj("a", Vector2i(10, 10)), _item("b", Vector2i(10, 10)), _wall("c", Vector2i(10, 10), "nw")])
	_expect(Array(order_store.get_diagnostic_snapshot().get("object_ids", [])) == ["a", "b", "c"], "order remains deterministic")

func _run_mission_manager_checks() -> void:
	var manager: Node = MissionManagerRef.new()
	var bounds_grid := BoundsGridManager.new()
	manager.set_grid_manager_ref(bounds_grid)
	var out_of_bounds: Dictionary = manager.try_set_world_object_at_cell(Vector2i(4, 4), _obj("mm_oob", Vector2i(4, 4)))
	_expect(not bool(out_of_bounds.get("ok", true)), "MissionManager rejects out-of-bounds placement before store commit")
	_expect(manager.get_world_object_by_id("mm_oob").is_empty(), "out-of-bounds MissionManager placement is not committed")
	manager.add_item_at_cell(Vector2i(4, 4), _item("mm_oob_item", Vector2i(4, 4)))
	_expect(manager.get_world_object_by_id("mm_oob_item").is_empty(), "out-of-bounds item is rejected")
	manager._sync_world_item_record(_item("mm_oob_sync_item", Vector2i(4, 4)))
	_expect(manager.get_world_object_by_id("mm_oob_sync_item").is_empty(), "out-of-bounds _sync_world_item_record is rejected")
	var before_oob_snapshot: Dictionary = manager.world_state_store.get_diagnostic_snapshot()
	var rejected_snapshot: Dictionary = manager.replace_world_state_snapshot([_obj("mm_in_bounds", Vector2i(1, 1)), _obj("mm_snapshot_oob", Vector2i(4, 4))])
	_expect(not bool(rejected_snapshot.get("ok", true)), "snapshot with one out-of-bounds object is fully rejected")
	_expect(var_to_str(before_oob_snapshot) == var_to_str(manager.world_state_store.get_diagnostic_snapshot()), "failed out-of-bounds snapshot preserves state and indexes")
	_expect(manager.get_world_object_by_id("mm_in_bounds").is_empty(), "failed out-of-bounds snapshot does not partially commit")
	manager.set_grid_manager_ref(null)
	manager.set_world_object_at_cell(Vector2i(5, 5), _obj("mm_primary", Vector2i(5, 5)))
	manager.set_world_object_at_cell(Vector2i(5, 5), _wall("mm_wall", Vector2i(5, 5), "nw"))
	_expect(str(manager.get_world_object_by_id("mm_primary").get("id", "")) == "mm_primary", "adding wall does not remove primary")
	manager.set_world_object_at_cell(Vector2i(5, 5), _cable("mm_cable", Vector2i(5, 5)))
	_expect(str(manager.get_world_object_by_id("mm_primary").get("id", "")) == "mm_primary", "adding cable does not remove primary")
	manager.set_world_object_at_cell(Vector2i(6, 6), _platform("mm_platform", Vector2i(6, 6)))
	manager.set_world_object_at_cell(Vector2i(6, 6), _occupant("mm_crate", Vector2i(6, 6)))
	_expect(str(manager.get_world_object_by_id("mm_platform").get("id", "")) == "mm_platform", "adding occupant does not remove platform")
	manager.add_item_at_cell(Vector2i(5, 5), _item("mm_item", Vector2i(5, 5)))
	manager.remove_world_object_at_cell(Vector2i(5, 5))
	_expect(manager.get_world_object_by_id("mm_wall").is_empty() == false, "remove by cell preserves wall layer")
	_expect(manager.get_world_object_by_id("mm_cable").is_empty() == false, "remove by cell preserves cable layer")
	_expect(manager.get_items_at_cell(Vector2i(5, 5)).size() == 1, "remove by cell preserves item layer")
	var rendered: Array[Dictionary] = manager.get_renderable_objects_at_cell(Vector2i(5, 5))
	_expect(rendered.size() >= 3, "rendering lookup returns legal layers")
	var mm_read: Array[Dictionary] = manager.mission_world_objects
	mm_read[0]["position"] = Vector2i(99, 99)
	_expect(manager.get_world_object_by_id("mm_wall").is_empty() == false, "MissionManager compatibility getter is isolated")
	manager.replace_world_state_snapshot([
		{"id":"power_source_a", "object_group":"power", "object_type":"power_source_class_1", "position":Vector2i(20, 20), "state":"on", "power_network_id":"net_a"},
		{"id":"terminal_a", "object_group":"terminal", "object_type":"terminal", "position":Vector2i(21, 20), "state":"off", "power_network_id":"net_a"}
	])
	manager.recalculate_power_network("net_a")
	var powered_terminal: Dictionary = manager.world_state_store.get_object_by_id("terminal_a")
	_expect(powered_terminal.has("is_powered"), "PowerSystem runtime fields persist in store")
	manager.replace_world_state_snapshot([
		{"id":"generic_source", "object_group":"power", "object_type":"power_source_class_1", "position":Vector2i(30, 30), "power_network_id":"generic_net", "generic_power_runtime":true, "generic_power_role":BipobCableRuntimeServiceRef.ROLE_POWER_SOURCE, "state":"on"},
		{"id":"generic_cable", "object_group":"power", "object_type":"power_cable", "position":Vector2i(31, 30), "power_network_id":"generic_net", "generic_power_runtime":true, "generic_power_role":BipobCableRuntimeServiceRef.ROLE_CABLE_LINK, "source_object_id":"generic_source"}
	])
	var cable_report: Dictionary = manager.refresh_generic_cable_runtime_state("generic_net")
	_expect(bool(cable_report.get("ok", false)), "generic cable runtime report succeeds")
	var source_after: Dictionary = manager.world_state_store.get_object_by_id("generic_source")
	var cable_after: Dictionary = manager.world_state_store.get_object_by_id("generic_cable")
	_expect(bool(source_after.get("is_powered", false)), "generic source is_powered mismatch: %s" % var_to_str(source_after.get("is_powered", null)))
	_expect(str(source_after.get("power_state", "")) == "source_on", "generic source power_state mismatch: %s" % var_to_str(source_after.get("power_state", null)))
	_expect(cable_after.has("power_received"), "generic cable power_received missing: %s" % var_to_str(cable_after))
	_expect(cable_after.has("power_state"), "generic cable power_state missing: %s" % var_to_str(cable_after))
	manager.replace_world_state_snapshot([
		{"id":"fan_a", "object_group":"cooling", "object_type":"external_air_cooler", "position":Vector2i(40, 40), "generic_airflow_runtime":true, "generic_airflow_role":BipobAirflowRuntimeStateRef.ROLE_FAN, "airflow_network_id":"air_a", "state":"active", "fan_enabled":true, "fan_speed":1, "airflow_range":1, "fan_direction":"right", "cooling_output":1},
		{"id":"heat_a", "object_group":"terminal", "object_type":"terminal", "position":Vector2i(41, 40), "generic_airflow_runtime":true, "generic_airflow_role":BipobAirflowRuntimeStateRef.ROLE_COOLING_TARGET, "airflow_network_id":"air_a", "cooling_required":true, "working_heat":2, "current_heat":2, "overheat_threshold":5}
	])
	var airflow_report: Dictionary = manager.refresh_generic_airflow_runtime_state("air_a")
	_expect(Array(airflow_report.get("warnings", [])).is_empty(), "generic airflow runtime report has no warnings")
	var fan_after: Dictionary = manager.world_state_store.get_object_by_id("fan_a")
	var target_after: Dictionary = manager.world_state_store.get_object_by_id("heat_a")
	_expect(Array(fan_after.get("cooled_target_ids", [])).has("heat_a"), "fan cooled_target_ids mismatch: %s" % var_to_str(fan_after.get("cooled_target_ids", [])))
	_expect(Array(target_after.get("airflow_cells", [])).has(Vector2i(41, 40)), "target airflow_cells mismatch: %s" % var_to_str(target_after.get("airflow_cells", [])))
	_expect(bool(target_after.get("is_cooled", false)), "generic airflow target is_cooled mismatch: %s" % var_to_str(target_after.get("is_cooled", null)))
	_expect(int(target_after.get("cooling_received", 0)) > 0, "generic airflow target cooling_received mismatch: %s" % var_to_str(target_after.get("cooling_received", null)))
	_expect(str(target_after.get("cooling_state", "")) == "cooled", "generic airflow target cooling_state mismatch: %s" % var_to_str(target_after.get("cooling_state", null)))
	_expect(Array(target_after.get("cooling_source_ids", [])).has("fan_a"), "target cooling_source_ids mismatch: %s" % var_to_str(target_after.get("cooling_source_ids", [])))
	manager.refresh_world_cooling_received()
	var heat_after_refresh: Dictionary = manager.world_state_store.get_object_by_id("heat_a")
	_expect(int(heat_after_refresh.get("cooling_received", 0)) > 0, "cooling refresh cooling_received mismatch: %s" % var_to_str(heat_after_refresh.get("cooling_received", null)))
	_expect(bool(heat_after_refresh.get("is_cooled", false)), "cooling refresh is_cooled mismatch: %s" % var_to_str(heat_after_refresh.get("is_cooled", null)))
	_expect(str(heat_after_refresh.get("cooling_state", "")) == "cooled", "cooling refresh cooling_state mismatch: %s" % var_to_str(heat_after_refresh.get("cooling_state", null)))
	manager.enable_debug_seed = true
	manager._seed_debug_world_objects()

	var seeded: Dictionary = Dictionary(
		manager.world_state_store.get_object_by_id("wall_b1")
	)
	_expect(
		int(seeded.get("scan_level", 0)) == 3,
		"debug seed scan_level mismatch: %s" % var_to_str(seeded)
	)

	var seeded_power: Dictionary = Dictionary(
		manager.world_state_store.get_object_by_id("door_a1")
	)
	_expect(
		str(seeded_power.get("power_network_id", "")) == "power_net_A",
		"debug seed power network mismatch: %s" % var_to_str(seeded_power)
	)
	_expect(manager.world_state_store.validate_consistency().is_empty(), "MissionManager store consistency remains valid")
	bounds_grid.free()
	manager.free()
	manager = null
