extends RefCounted
class_name WorldStateStore

signal changed(change: Dictionary)

const CableTopologyServiceRef = preload("res://scripts/game/cable_topology_service.gd")
const PlatformOccupancyServiceRef = preload("res://scripts/game/platform/platform_occupancy_service.gd")
const LAYER_SURFACE := "surface"
const LAYER_PLATFORM := "platform"
const LAYER_OCCUPANT := "occupant"
const LAYER_PRIMARY := "primary"
const LAYER_ROUTE := "route"
const LAYER_WALL := "wall"
const LAYER_ITEM := "item"
const LAYER_VISUAL := "visual"
const STRUCTURAL_FIELDS := {"id": true, "position": true, "object_group": true, "object_type": true, "placement_mode": true, "placement": true, "mount": true, "wall_side": true, "mount_side": true, "surface": true, "is_wall_mounted": true, "on_platform": true, "platform_id": true, "platform_cell": true, "platform_height_level": true, "surface_level": true}

var _objects_by_id: Dictionary = {}
var _object_order: Array[String] = []
var _primary_object_id_by_cell: Dictionary = {}
var _surface_ids_by_cell: Dictionary = {}
var _platform_ids_by_cell: Dictionary = {}
var _occupant_ids_by_cell: Dictionary = {}
var _route_ids_by_cell: Dictionary = {}
var _item_ids_by_cell: Dictionary = {}
var _wall_mount_ids_by_cell: Dictionary = {}
var _wall_mount_ids_by_cell_and_side: Dictionary = {}
var _visual_ids_by_cell: Dictionary = {}

func clear() -> void:
	_commit_state({}, [], _empty_indexes())
	changed.emit({"action": "clear", "warnings": []})

func replace_snapshot(objects: Array[Dictionary]) -> Dictionary:
	var built := _build_state_from_objects(objects)
	if not bool(built.get("ok", false)):
		return built
	_commit_state(Dictionary(built.get("objects_by_id", {})), Array(built.get("object_order", [])), Dictionary(built.get("indexes", {})))
	changed.emit({"action": "replace_snapshot", "warnings": [], "count": _object_order.size()})
	return _ok({"object_count": _object_order.size()})

func add_object(object_data: Dictionary) -> Dictionary:
	var object_id := _object_id(object_data)
	if object_id.is_empty(): return _fail("empty_object_id")
	if _objects_by_id.has(object_id): return _fail("duplicate_object_id")
	var placement := validate_structural_placement(object_data, _cell(object_data))
	if not bool(placement.get("ok", false)): return placement
	var objects := _duplicate_objects_by_id(_objects_by_id)
	var order: Array[String] = _object_order.duplicate()
	objects[object_id] = Dictionary(placement.get("object", object_data)).duplicate(true)
	order.append(object_id)
	var built := _build_state_from_maps(objects, order)
	if not bool(built.get("ok", false)): return built
	_commit_state(Dictionary(built.get("objects_by_id", objects)), Array(built.get("object_order", order)), Dictionary(built.get("indexes", {})))
	var canonical_object: Dictionary = get_object_by_id(object_id)
	changed.emit({"action": "add", "object_id": object_id, "current_cell": _cell(canonical_object), "layer": _layer(canonical_object), "warnings": []})
	return _ok({"object": canonical_object})

func upsert_object(object_data: Dictionary) -> Dictionary:
	return _upsert_object_internal(object_data, "upsert")

func _upsert_object_internal(object_data: Dictionary, action: String = "") -> Dictionary:
	var object_id := _object_id(object_data)
	if object_id.is_empty(): return _fail("empty_object_id")
	var replacing := object_id if _objects_by_id.has(object_id) else ""
	var placement := validate_structural_placement(object_data, _cell(object_data), replacing)
	if not bool(placement.get("ok", false)): return placement
	var objects := _duplicate_objects_by_id(_objects_by_id)
	var order: Array[String] = _object_order.duplicate()
	objects[object_id] = Dictionary(placement.get("object", object_data)).duplicate(true)
	if not order.has(object_id): order.append(object_id)
	var built := _build_state_from_maps(objects, order)
	if not bool(built.get("ok", false)): return built
	_commit_state(Dictionary(built.get("objects_by_id", objects)), Array(built.get("object_order", order)), Dictionary(built.get("indexes", {})))
	var canonical_object: Dictionary = get_object_by_id(object_id)
	if not action.is_empty():
		changed.emit({"action": action, "object_id": object_id, "current_cell": _cell(canonical_object), "layer": _layer(canonical_object), "warnings": []})
	return _ok({"object": canonical_object})

func update_object_state(object_id: String, patch: Dictionary) -> Dictionary:
	if not _objects_by_id.has(object_id): return _fail("missing_object_id")
	if _patch_has_id_change(object_id, patch): return _fail("object_id_is_immutable")
	for key in patch.keys():
		if STRUCTURAL_FIELDS.has(str(key)): return _fail("structural_field_patch")
	var object_data: Dictionary = Dictionary(_objects_by_id[object_id]).duplicate(true)
	for key in patch.keys(): object_data[key] = patch[key]
	_objects_by_id[object_id] = object_data
	changed.emit({"action": "update_state", "object_id": object_id, "warnings": []})
	return _ok({"object": object_data.duplicate(true)})

func update_object_structure(object_id: String, structural_patch: Dictionary) -> Dictionary:
	if not _objects_by_id.has(object_id): return _fail("missing_object_id")
	if _patch_has_id_change(object_id, structural_patch): return _fail("object_id_is_immutable")
	var object_data: Dictionary = Dictionary(_objects_by_id[object_id]).duplicate(true)
	for key in structural_patch.keys(): object_data[key] = structural_patch[key]
	var result := _upsert_object_internal(object_data, "")
	if bool(result.get("ok", false)):
		changed.emit({"action": "update_structure", "object_id": object_id, "warnings": []})
	return result

func move_object(object_id: String, destination: Vector2i, structural_patch: Dictionary = {}) -> Dictionary:
	if not _objects_by_id.has(object_id): return _fail("missing_object_id")
	if _patch_has_id_change(object_id, structural_patch): return _fail("object_id_is_immutable")
	var object_data: Dictionary = Dictionary(_objects_by_id[object_id]).duplicate(true)
	var previous_cell := _cell(object_data)
	object_data["position"] = destination
	for key in structural_patch.keys(): object_data[key] = structural_patch[key]
	var placement := validate_structural_placement(object_data, destination, object_id)
	if not bool(placement.get("ok", false)): return placement
	var result := _upsert_object_internal(object_data, "")
	if bool(result.get("ok", false)):
		changed.emit({"action": "move", "object_id": object_id, "previous_cell": previous_cell, "current_cell": destination, "layer": _layer(object_data), "warnings": []})
	return result

func remove_object_by_id(object_id: String) -> Dictionary:
	if not _objects_by_id.has(object_id): return _fail("missing_object_id")
	var removed: Dictionary = Dictionary(_objects_by_id[object_id]).duplicate(true)
	var objects := _duplicate_objects_by_id(_objects_by_id)
	var order: Array[String] = _object_order.duplicate()
	objects.erase(object_id)
	order.erase(object_id)
	var built := _build_state_from_maps(objects, order)
	if not bool(built.get("ok", false)): return built
	_commit_state(objects, order, Dictionary(built.get("indexes", {})))
	changed.emit({"action": "remove", "object_id": object_id, "previous_cell": _cell(removed), "warnings": []})
	return _ok({"removed": removed})

func remove_object_at_cell(cell: Vector2i) -> Dictionary:
	var object_data := get_primary_object_at_cell(cell)
	if object_data.is_empty(): return _fail("missing_object_at_cell")
	return remove_object_by_id(_object_id(object_data))

func add_item(cell: Vector2i, item_data: Dictionary) -> Dictionary:
	var stored := item_data.duplicate(true)
	stored["position"] = cell
	stored["object_group"] = "item"
	if str(stored.get("object_type", "")).strip_edges().is_empty(): stored["object_type"] = "item"
	return add_object(stored)

func remove_first_item_at_cell(cell: Vector2i) -> Dictionary:
	var ids: Array = Array(_item_ids_by_cell.get(cell, []))
	if ids.is_empty(): return _fail("missing_item_at_cell")
	return remove_object_by_id(str(ids[0]))

func validate_structural_placement(object_data: Dictionary, destination: Vector2i, replacing_object_id: String = "") -> Dictionary:
	var structural := _validate_structural_object(object_data)
	if not bool(structural.get("ok", false)): return structural
	var object_id := _object_id(object_data)
	var actual_cell: Vector2i = Vector2i(structural.get("cell", destination))
	if actual_cell != destination: return _fail("position_destination_mismatch")
	var layer := _layer(object_data)
	var conflicts: Array[String] = []
	if layer == LAYER_PRIMARY:
		var current := str(_primary_object_id_by_cell.get(destination, ""))
		if not current.is_empty() and current != replacing_object_id: conflicts.append(current)
	elif layer == LAYER_WALL:
		var side := _wall_side(object_data)
		for id in Array(_wall_side_bucket(_wall_mount_ids_by_cell_and_side, destination, side)):
			if str(id) != replacing_object_id: conflicts.append(str(id))
	if not conflicts.is_empty(): return _fail("%s_cell_occupied" % layer, [], conflicts)
	return _ok({"layer": layer, "conflicting_object_ids": [], "object": Dictionary(structural.get("object", object_data)).duplicate(true)})

func apply_non_structural_snapshot(mutated_objects: Array[Dictionary], action: String = "batch_update_state") -> Dictionary:
	var seen: Dictionary = {}
	var changed_ids: Array[String] = []
	if mutated_objects.size() != _object_order.size():
		return _fail("object_order_changed")
	for index in range(mutated_objects.size()):
		var object_data: Dictionary = Dictionary(mutated_objects[index])
		var object_id := _object_id(object_data)
		if object_id.is_empty(): return _fail("missing_object_id")
		if seen.has(object_id): return _fail("duplicate_object_id", [], [object_id])
		seen[object_id] = true
		if index >= _object_order.size() or _object_order[index] != object_id:
			return _fail("object_order_changed", [], [object_id])
		if not _objects_by_id.has(object_id): return _fail("unexpected_object_id", [], [object_id])
		var canonical: Dictionary = _objects_by_id[object_id]
		var structural_check := _validate_non_structural_snapshot_object(canonical, object_data)
		if not bool(structural_check.get("ok", false)): return structural_check
		if var_to_str(canonical) != var_to_str(object_data): changed_ids.append(object_id)
	for object_id in _object_order:
		if not seen.has(object_id): return _fail("missing_object_id", [], [object_id])
	var next_objects := _duplicate_objects_by_id(_objects_by_id)
	for object_data in mutated_objects:
		var object_id := _object_id(object_data)
		next_objects[object_id] = Dictionary(object_data).duplicate(true)
	_objects_by_id = next_objects
	changed.emit({"action": action, "changed_object_ids": changed_ids.duplicate(), "warnings": []})
	return _ok({"changed_object_ids": changed_ids})

func _validate_non_structural_snapshot_object(canonical: Dictionary, candidate: Dictionary) -> Dictionary:
	var object_id := _object_id(canonical)
	if _object_id(candidate) != object_id:
		return {"ok": false, "reason": "object_id_is_immutable", "object_id": object_id, "warnings": []}
	if _layer(candidate) != _layer(canonical):
		return {"ok": false, "reason": "structural_layer_changed", "object_id": object_id, "warnings": []}
	for field in STRUCTURAL_FIELDS.keys():
		var key := str(field)
		if var_to_str(canonical.get(key, null)) != var_to_str(candidate.get(key, null)):
			return {"ok": false, "reason": "structural_field_changed", "object_id": object_id, "field": key, "warnings": []}
	return _ok()

func has_object(object_id: String) -> bool: return _objects_by_id.has(object_id)
func get_object_by_id(object_id: String) -> Dictionary: return Dictionary(_objects_by_id.get(object_id, {})).duplicate(true)
func get_primary_object_at_cell(cell: Vector2i) -> Dictionary:
	var id := str(_primary_object_id_by_cell.get(cell, ""))
	return get_object_by_id(id) if not id.is_empty() else {}
func get_floor_object_at_cell(cell: Vector2i) -> Dictionary: return get_primary_object_at_cell(cell)
func get_items_at_cell(cell: Vector2i) -> Array[Dictionary]: return _objects_for_ids(Array(_item_ids_by_cell.get(cell, [])))
func get_wall_mounted_objects_at_cell(cell: Vector2i) -> Array[Dictionary]: return _objects_for_ids(Array(_wall_mount_ids_by_cell.get(cell, [])))
func get_wall_mounted_objects_at_cell_side(cell: Vector2i, side: String) -> Array[Dictionary]: return _objects_for_ids(Array(_wall_side_bucket(_wall_mount_ids_by_cell_and_side, cell, side)))
func get_renderable_objects_at_cell(cell: Vector2i) -> Array[Dictionary]:
	var ids: Array = []
	for index in [_visual_ids_by_cell, _surface_ids_by_cell, _platform_ids_by_cell, _route_ids_by_cell, _primary_object_id_by_cell, _occupant_ids_by_cell, _wall_mount_ids_by_cell, _item_ids_by_cell]:
		if index == _primary_object_id_by_cell:
			var primary_id := str(index.get(cell, ""))
			if not primary_id.is_empty(): ids.append(primary_id)
		else:
			ids.append_array(Array(index.get(cell, [])))
	return _objects_for_ids(ids)
func get_all_objects() -> Array[Dictionary]: return _objects_for_ids(_object_order)
func get_object_count() -> int: return _object_order.size()
func get_floor_lookup_snapshot() -> Dictionary:
	var result := {}
	for cell in _primary_object_id_by_cell.keys():
		result[cell] = get_object_by_id(str(_primary_object_id_by_cell[cell]))
	return result
func get_cell_items_snapshot() -> Dictionary:
	var result := {}
	for cell in _item_ids_by_cell.keys():
		result[cell] = get_items_at_cell(cell)
	return result
func get_wall_mount_lookup_snapshot() -> Dictionary:
	var result := {}
	for cell in _wall_mount_ids_by_cell.keys():
		result[cell] = get_wall_mounted_objects_at_cell(cell)
	return result

func validate_consistency() -> Array[String]:
	var warnings: Array[String] = []
	var order_seen := {}
	for object_id in _object_order:
		if str(object_id).strip_edges().is_empty(): warnings.append("empty_ordered_id")
		if order_seen.has(object_id): warnings.append("duplicate_ordered_id:%s" % object_id)
		order_seen[object_id] = true
		if not _objects_by_id.has(object_id): warnings.append("ordered_id_missing_object:%s" % object_id)
	for key in _objects_by_id.keys():
		var object_id := str(key)
		var object_data: Dictionary = _objects_by_id[key]
		var field_id := _object_id(object_data)
		if object_id != field_id: warnings.append("object_id_key_mismatch:%s:%s" % [object_id, field_id])
		if not order_seen.has(object_id): warnings.append("object_missing_order:%s" % object_id)
		_validate_object_index_membership(object_id, object_data, warnings)
	_validate_index_ids(_primary_object_id_by_cell, warnings, false, LAYER_PRIMARY)
	for pair in [[_surface_ids_by_cell, LAYER_SURFACE], [_platform_ids_by_cell, LAYER_PLATFORM], [_occupant_ids_by_cell, LAYER_OCCUPANT], [_route_ids_by_cell, LAYER_ROUTE], [_item_ids_by_cell, LAYER_ITEM], [_wall_mount_ids_by_cell, LAYER_WALL], [_visual_ids_by_cell, LAYER_VISUAL]]:
		_validate_index_ids(pair[0], warnings, true, pair[1])
	for cell in _wall_mount_ids_by_cell_and_side.keys():
		var by_side: Dictionary = Dictionary(_wall_mount_ids_by_cell_and_side[cell])
		for side in by_side.keys():
			var seen := {}
			for id in Array(by_side[side]):
				var text_id := str(id)
				if seen.has(text_id): warnings.append("duplicate_wall_side_index_id:%s" % text_id)
				seen[text_id] = true
				var object_data: Dictionary = _objects_by_id.get(text_id, {})
				if object_data.is_empty(): warnings.append("stale_index_id:%s" % text_id)
				elif _cell(object_data) != cell or _wall_side(object_data) != str(side): warnings.append("wall_wrong_side_index:%s" % text_id)
	return warnings

func get_diagnostic_snapshot() -> Dictionary:
	return {"object_ids": _object_order.duplicate(), "primary": _primary_object_id_by_cell.duplicate(true), "surface": _surface_ids_by_cell.duplicate(true), "platform": _platform_ids_by_cell.duplicate(true), "occupant": _occupant_ids_by_cell.duplicate(true), "route": _route_ids_by_cell.duplicate(true), "items": _item_ids_by_cell.duplicate(true), "wall": _wall_mount_ids_by_cell.duplicate(true), "wall_by_side": _wall_mount_ids_by_cell_and_side.duplicate(true), "visual": _visual_ids_by_cell.duplicate(true)}

func _build_state_from_objects(objects: Array[Dictionary]) -> Dictionary:
	var by_id := {}
	var order: Array[String] = []
	for object_data in objects:
		var object_id := _object_id(object_data)
		if object_id.is_empty(): return _fail("empty_object_id")
		if by_id.has(object_id): return _fail("duplicate_object_id")
		by_id[object_id] = object_data.duplicate(true)
		order.append(object_id)
	return _build_state_from_maps(by_id, order)

func _build_state_from_maps(objects: Dictionary, order: Array[String]) -> Dictionary:
	var indexes := _empty_indexes()
	var seen_order := {}
	for object_id in order:
		if seen_order.has(object_id): return _fail("duplicate_ordered_id")
		seen_order[object_id] = true
		if not objects.has(object_id): return _fail("ordered_id_missing_object")
	for object_id in objects.keys():
		if not seen_order.has(str(object_id)): return _fail("object_missing_order")
		var object_data: Dictionary = objects[object_id]
		if str(object_id) != _object_id(object_data): return _fail("object_id_key_mismatch")
		var structural := _validate_structural_object(object_data)
		if not bool(structural.get("ok", false)): return structural
		object_data = Dictionary(structural.get("object", object_data)).duplicate(true)
		objects[object_id] = object_data
		var conflict := _validate_against_indexes(object_data, indexes, str(object_id))
		if not bool(conflict.get("ok", false)): return conflict
		_index_into(indexes, str(object_id), object_data)
	return _ok({"indexes": indexes, "objects_by_id": objects, "object_order": order})

func _empty_indexes() -> Dictionary:
	return {"primary": {}, "surface": {}, "platform": {}, "occupant": {}, "route": {}, "item": {}, "wall": {}, "wall_side": {}, "visual": {}}
func _commit_state(objects: Dictionary, order: Array, indexes: Dictionary) -> void:
	_objects_by_id = objects
	_object_order = []
	for id in order: _object_order.append(str(id))
	_primary_object_id_by_cell = Dictionary(indexes.get("primary", {}))
	_surface_ids_by_cell = Dictionary(indexes.get("surface", {}))
	_platform_ids_by_cell = Dictionary(indexes.get("platform", {}))
	_occupant_ids_by_cell = Dictionary(indexes.get("occupant", {}))
	_route_ids_by_cell = Dictionary(indexes.get("route", {}))
	_item_ids_by_cell = Dictionary(indexes.get("item", {}))
	_wall_mount_ids_by_cell = Dictionary(indexes.get("wall", {}))
	_wall_mount_ids_by_cell_and_side = Dictionary(indexes.get("wall_side", {}))
	_visual_ids_by_cell = Dictionary(indexes.get("visual", {}))
func _validate_against_indexes(object_data: Dictionary, indexes: Dictionary, replacing_object_id: String = "") -> Dictionary:
	var layer := _layer(object_data)
	var cell := _cell(object_data)
	var conflicts: Array[String] = []
	if layer == LAYER_PRIMARY:
		var existing := str(Dictionary(indexes.get("primary", {})).get(cell, ""))
		if not existing.is_empty() and existing != replacing_object_id:
			conflicts.append(existing)
	elif layer == LAYER_WALL:
		for id in Array(_wall_side_bucket(Dictionary(indexes.get("wall_side", {})), cell, _wall_side(object_data))):
			if str(id) != replacing_object_id: conflicts.append(str(id))
	if conflicts.is_empty(): return _ok({"conflicting_object_ids": []})
	return _fail("%s_cell_occupied" % layer, [], conflicts)
func _index_into(indexes: Dictionary, object_id: String, object_data: Dictionary) -> void:
	var layer := _layer(object_data)
	var cell := _cell(object_data)
	match layer:
		LAYER_PRIMARY:
			var primary: Dictionary = indexes["primary"]
			primary[cell] = object_id
			indexes["primary"] = primary
		LAYER_SURFACE:
			var surface: Dictionary = indexes["surface"]
			_append_index(surface, cell, object_id)
			indexes["surface"] = surface
		LAYER_PLATFORM:
			var platform: Dictionary = indexes["platform"]
			_append_index(platform, cell, object_id)
			indexes["platform"] = platform
		LAYER_OCCUPANT:
			var occupant: Dictionary = indexes["occupant"]
			_append_index(occupant, cell, object_id)
			indexes["occupant"] = occupant
		LAYER_ROUTE:
			var route: Dictionary = indexes["route"]
			_append_index(route, cell, object_id)
			indexes["route"] = route
		LAYER_ITEM:
			var item: Dictionary = indexes["item"]
			_append_index(item, cell, object_id)
			indexes["item"] = item
		LAYER_WALL:
			var wall: Dictionary = indexes["wall"]
			_append_index(wall, cell, object_id)
			indexes["wall"] = wall
			var wall_side: Dictionary = indexes["wall_side"]
			_append_wall_side_index(wall_side, cell, _wall_side(object_data), object_id)
			indexes["wall_side"] = wall_side
		LAYER_VISUAL:
			var visual: Dictionary = indexes["visual"]
			_append_index(visual, cell, object_id)
			indexes["visual"] = visual
func _append_index(index: Dictionary, cell: Vector2i, object_id: String) -> void:
	var ids: Array = Array(index.get(cell, []))
	if not ids.has(object_id):
		ids.append(object_id)
	index[cell] = ids
func _append_wall_side_index(index: Dictionary, cell: Vector2i, side: String, object_id: String) -> void:
	var by_side: Dictionary = Dictionary(index.get(cell, {}))
	var ids: Array = Array(by_side.get(side, []))
	if not ids.has(object_id):
		ids.append(object_id)
	by_side[side] = ids
	index[cell] = by_side
func _wall_side_bucket(index: Dictionary, cell: Vector2i, side: String) -> Array:
	return Array(Dictionary(index.get(cell, {})).get(_normalize_side(side), []))
func _objects_for_ids(ids: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in ids:
		if _objects_by_id.has(str(id)): result.append(Dictionary(_objects_by_id[str(id)]).duplicate(true))
	return result
func _duplicate_objects_by_id(source: Dictionary) -> Dictionary:
	var result := {}
	for id in source.keys():
		result[str(id)] = Dictionary(source[id]).duplicate(true)
	return result
func _validate_object_index_membership(object_id: String, object_data: Dictionary, warnings: Array[String]) -> void:
	var layer := _layer(object_data)
	var cell := _cell(object_data)
	var in_expected := false
	match layer:
		LAYER_PRIMARY: in_expected = str(_primary_object_id_by_cell.get(cell, "")) == object_id
		LAYER_SURFACE: in_expected = Array(_surface_ids_by_cell.get(cell, [])).has(object_id)
		LAYER_PLATFORM: in_expected = Array(_platform_ids_by_cell.get(cell, [])).has(object_id)
		LAYER_OCCUPANT: in_expected = Array(_occupant_ids_by_cell.get(cell, [])).has(object_id)
		LAYER_ROUTE: in_expected = Array(_route_ids_by_cell.get(cell, [])).has(object_id)
		LAYER_ITEM: in_expected = Array(_item_ids_by_cell.get(cell, [])).has(object_id)
		LAYER_WALL: in_expected = Array(_wall_mount_ids_by_cell.get(cell, [])).has(object_id) and Array(_wall_side_bucket(_wall_mount_ids_by_cell_and_side, cell, _wall_side(object_data))).has(object_id)
		LAYER_VISUAL: in_expected = Array(_visual_ids_by_cell.get(cell, [])).has(object_id)
	if not in_expected: warnings.append("object_missing_expected_index:%s:%s" % [object_id, layer])
	if layer != LAYER_ROUTE and _id_in_multi(_route_ids_by_cell, object_id): warnings.append("wrong_layer_route:%s" % object_id)
	if layer != LAYER_PRIMARY and _primary_object_id_by_cell.values().has(object_id): warnings.append("wrong_layer_primary:%s" % object_id)
func _validate_index_ids(index: Dictionary, warnings: Array[String], multi: bool, expected_layer: String) -> void:
	for cell in index.keys():
		var ids: Array = Array(index[cell]) if multi else [str(index[cell])]
		var seen := {}
		for id in ids:
			var object_id := str(id)
			if seen.has(object_id): warnings.append("duplicate_index_id:%s" % object_id)
			seen[object_id] = true
			var object_data: Dictionary = _objects_by_id.get(object_id, {})
			if object_data.is_empty(): warnings.append("stale_index_id:%s" % object_id)
			elif _cell(object_data) != cell: warnings.append("index_cell_mismatch:%s" % object_id)
			elif _layer(object_data) != expected_layer: warnings.append("wrong_index_layer:%s:%s" % [object_id, expected_layer])
func _id_in_multi(index: Dictionary, object_id: String) -> bool:
	for ids in index.values():
		if Array(ids).has(object_id): return true
	return false
func _layer(object_data: Dictionary) -> String:
	var group := str(object_data.get("object_group", object_data.get("group", ""))).strip_edges().to_lower()
	var object_type := str(object_data.get("object_type", object_data.get("type", object_data.get("item_type", "")))).strip_edges().to_lower()
	if group == "item": return LAYER_ITEM
	if _is_wall_mounted(object_data): return LAYER_WALL
	if CableTopologyServiceRef.is_cable_object(object_data): return LAYER_ROUTE
	if PlatformOccupancyServiceRef.is_platform_data(object_data): return LAYER_PLATFORM
	if PlatformOccupancyServiceRef.is_platform_placeable_object(object_data) and (bool(object_data.get("on_platform", false)) or not str(object_data.get("platform_id", "")).is_empty()): return LAYER_OCCUPANT
	if _is_visual_only_floor_ground_object(object_data): return LAYER_VISUAL
	if group in ["surface"] or bool(object_data.get("is_surface_provider", false)): return LAYER_SURFACE
	return LAYER_PRIMARY
func _is_wall_mounted(object_data: Dictionary) -> bool:
	var placement := str(object_data.get("placement_mode", object_data.get("placement", ""))).strip_edges().to_lower()
	var mount := str(object_data.get("mount", "")).strip_edges().to_lower()
	return placement == "wall_mounted" or mount in ["wall", "wall_mounted"] or bool(object_data.get("is_wall_mounted", false))
func _is_visual_only_floor_ground_object(object_data: Dictionary) -> bool:
	var group := str(object_data.get("object_group", "")).strip_edges().to_lower()
	var object_type := str(object_data.get("object_type", "")).strip_edges().to_lower()
	var category := str(object_data.get("category", object_data.get("object_category", ""))).strip_edges().to_lower()
	var texture := str(object_data.get("texture_asset_id", object_data.get("visual_texture_asset_id", object_data.get("visual_asset_id", object_data.get("asset_id", ""))))).strip_edges().to_lower()
	var height := str(object_data.get("floor_height_level", object_data.get("floor_visual_height", object_data.get("ground_height", object_data.get("height_level", ""))))).strip_edges().to_lower()
	var groups: Array[String] = ["floor", "ground", "floor_visual", "visual_floor", "floor_height", "raised_ground"]
	return group in groups or category in groups or object_type in ["stepped_floor", "raised_ground", "ground_low", "ground_halflow", "ground_low_01", "ground_halflow_01", "floor_stepped", "step_1", "step_2"] or object_type.begins_with("floor_") or object_type.begins_with("ground_") or texture in ["ground_low_01", "ground_low_01.png", "ground_low", "ground_halflow_01", "ground_halflow_01.png", "ground_halflow", "floor_stepped"] or height in ["step_1", "step_2", "ground_low", "ground_halflow", "low", "halflow"]
func _validate_structural_object(object_data: Dictionary) -> Dictionary:
	var object_id := _object_id(object_data)
	if object_id.is_empty(): return _fail("empty_object_id")
	if object_data.has("id") and str(object_data.get("id", "")).strip_edges() != object_id: return _fail("empty_object_id")
	var parsed := _parse_cell(object_data)
	if not bool(parsed.get("ok", false)): return parsed
	var cell: Vector2i = Vector2i(parsed.get("cell", Vector2i(-1, -1)))
	if cell.x < 0 or cell.y < 0: return _fail("negative_position")
	var canonical: Dictionary = object_data.duplicate(true)
	canonical["position"] = cell
	if _is_wall_mounted(object_data):
		var side_check := _validate_wall_side(object_data)
		if not bool(side_check.get("ok", false)): return side_check
		canonical["wall_side"] = str(side_check.get("wall_side", ""))
		if canonical.has("mount_side"):
			canonical["mount_side"] = str(side_check.get("wall_side", ""))
	return _ok({"cell": cell, "object": canonical})

func _parse_cell(object_data: Dictionary) -> Dictionary:
	if not object_data.has("position"):
		return _fail("missing_position")
	var raw: Variant = object_data.get("position")
	if raw is Vector2i:
		return _ok({"cell": raw})
	if raw is Vector2:
		return _ok({"cell": Vector2i(int(raw.x), int(raw.y))})
	if raw is Array and raw.size() >= 2 and (raw[0] is int or raw[0] is float) and (raw[1] is int or raw[1] is float):
		return _ok({"cell": Vector2i(int(raw[0]), int(raw[1]))})
	return _fail("malformed_position")

func _validate_wall_side(object_data: Dictionary) -> Dictionary:
	var raw_side := ""
	if object_data.has("wall_side"):
		raw_side = str(object_data.get("wall_side", ""))
	elif object_data.has("mount_side"):
		raw_side = str(object_data.get("mount_side", ""))
	else:
		return _fail("missing_wall_side")
	var side := _normalize_side(raw_side)
	if side.is_empty(): return _fail("missing_wall_side")
	if not (side in ["nw", "ne", "sw", "se"]): return _fail("invalid_wall_side")
	return _ok({"wall_side": side})

func _cell(object_data: Dictionary) -> Vector2i:
	var parsed := _parse_cell(object_data)
	return Vector2i(parsed.get("cell", Vector2i(-1, -1))) if bool(parsed.get("ok", false)) else Vector2i(-1, -1)
func _wall_side(object_data: Dictionary) -> String: return _normalize_side(str(object_data.get("wall_side", object_data.get("mount_side", ""))))
func _normalize_side(side: String) -> String:
	var text := side.strip_edges().to_lower()
	match text:
		"north": return "nw"
		"east": return "ne"
		"south": return "se"
		"west": return "sw"
	return text
func _object_id(object_data: Dictionary) -> String: return str(object_data.get("id", "")).strip_edges()
func _patch_has_id_change(object_id: String, patch: Dictionary) -> bool: return patch.has("id") and str(patch.get("id", "")).strip_edges() != object_id
func _ok(extra: Dictionary = {}) -> Dictionary:
	var result := {"ok": true, "warnings": [], "conflicting_object_ids": []}
	for key in extra.keys():
		result[key] = extra[key]
	return result
func _fail(reason: String, warnings: Array[String] = [], conflicts: Array[String] = []) -> Dictionary: return {"ok": false, "reason": reason, "warnings": warnings, "conflicting_object_ids": conflicts}
