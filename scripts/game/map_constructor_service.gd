extends RefCounted
class_name MapConstructorService

const DEBUG_WALL_MOUNTED_PLACEMENT_TRACE := false

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const PowerSystemRef = preload("res://scripts/world/power_system.gd")
const CableTopologyServiceRef = preload("res://scripts/game/cable_topology_service.gd")
const WallMountedPlacementRulesServiceRef = preload("res://scripts/game/wall/wall_mounted_placement_rules_service.gd")

const CIRCUIT_ID_FIELDS = ["circuit_id", "power_circuit_id", "network_id", "power_network_id", "chain_id", "link_group", "cable_group", "connected_circuit"]

var manager: Variant

func _init(owner: Node) -> void:
	manager = owner

func _parse_wall_entity_cell(entity_id: String, fallback_cell: Vector2i = Vector2i(-1, -1)) -> Vector2i:
	var parts: PackedStringArray = entity_id.strip_edges().split("_")
	if parts.size() >= 3 and parts[0] == "wall":
		return Vector2i(int(parts[1]), int(parts[2]))
	return fallback_cell

func _remove_world_object_record_by_id(entity_id: String) -> bool:
	var removed: bool = false
	for index in range(manager.mission_world_objects.size() - 1, -1, -1):
		var existing: Dictionary = manager._safe_dictionary(manager.mission_world_objects[index])
		if str(existing.get("id", "")) == entity_id:
			manager.mission_world_objects.remove_at(index)
			removed = true
	for cell_variant in manager.world_objects_by_cell.keys().duplicate():
		var lookup_data: Dictionary = manager._safe_dictionary(manager.world_objects_by_cell.get(cell_variant, {}))
		if str(lookup_data.get("id", "")) == entity_id:
			manager.world_objects_by_cell.erase(cell_variant)
	return removed

func _set_wall_tile_for_constructor(cell: Vector2i, tile_type: int) -> void:
	if manager.grid_manager != null and manager.grid_manager.has_method("set_tile"):
		manager.grid_manager.call("set_tile", cell, tile_type)

func _trace_wall_mounted_placement(event_name: String, payload: Dictionary) -> void:
	if not DEBUG_WALL_MOUNTED_PLACEMENT_TRACE:
		return
	print("[WallMountedPlacementService:%s] %s" % [event_name, JSON.stringify(payload)])

func place_map_constructor_prefab(prefab_id: String, cell: Vector2i, preferred_wall_side: String = "", rotation_degrees: int = 0, placement_mode_override: String = "") -> Dictionary:
	if not manager._is_task_test_constructor_context():
		return {"ok": false, "message": "Operation is available only in TASK TEST constructor mode."}
	var check: Dictionary = manager.can_place_map_constructor_prefab(prefab_id, cell, preferred_wall_side, placement_mode_override)
	if not bool(check.get("ok", false)):
		return check
	_trace_wall_mounted_placement("place_start", {"clicked_cell": cell, "selected_cell": cell, "placement_mode_override": placement_mode_override, "prefab_id": prefab_id, "is_wall_cell": manager._is_map_constructor_wall_cell(cell), "direct_wall_cell_mount": bool(check.get("direct_wall_cell_mount", false)), "wall_side": preferred_wall_side})
	var result: Dictionary = {"ok": true, "message": "Placed %s." % prefab_id, "object_id": "", "warnings": []}
	var previous_tile_type: int = GridManager.TILE_FLOOR
	if manager.grid_manager != null and manager.grid_manager.has_method("get_tile"):
		previous_tile_type = int(manager.grid_manager.call("get_tile", cell))
	if prefab_id == "stepped_floor":
		manager.grid_manager.call("set_tile", cell, GridManager.TILE_STEPPED_FLOOR)
		manager._record_map_constructor_change("place", {"entity_kind":"tile", "object_type":"stepped_floor", "cell":cell, "summary":"Placed stepped_floor at %s" % manager._format_map_constructor_cell(cell), "undo_hint":"Use constructor cleanup/reset tools if needed."})
		return result
	if manager.is_map_constructor_item_prefab(prefab_id):
		var item_object_id: String = "mapedit_%s_%d" % [prefab_id, manager._map_constructor_runtime_object_seq]
		manager._map_constructor_runtime_object_seq += 1
		var item_data: Dictionary = WorldObjectCatalogRef.create_world_object(prefab_id, item_object_id)
		if item_data.is_empty():
			return {"ok": false, "message": "Unknown item archetype.", "object_id": "", "warnings": []}
		item_data["position"] = cell
		item_data["created_by_map_constructor"] = true
		item_data["map_constructor_rotation_degrees"] = posmod(rotation_degrees, 360)
		item_data = WorldObjectCatalogRef.normalize_item_contract(WorldObjectCatalogRef.normalize_archetype_object(WorldObjectCatalogRef.normalize_world_object_contract(item_data)))
		if CableTopologyServiceRef.is_cable_object(item_data):
			var cable_validation: Dictionary = CableTopologyServiceRef.validate_placement(cell, manager.mission_world_objects, item_data)
			if not bool(cable_validation.get("ok", false)):
				return {"ok": false, "reason": "invalid_cable_junction", "message": str(cable_validation.get("message", CableTopologyServiceRef.ERROR_MESSAGE_JUNCTION_REQUIRES_SWITCH)), "object_id": "", "warnings": [], "cable_topology": cable_validation}
		manager.add_item_at_cell(cell, item_data)
		PowerSystemRef.recalculate_network(manager.mission_world_objects, "")
		manager.refresh_world_cooling_received()
		result["object_id"] = item_object_id
		result["is_item"] = true
		manager._record_map_constructor_change("place", {"entity_kind":"item", "entity_id":item_object_id, "object_type":str(item_data.get("item_type", "item")), "cell":cell, "summary":"Placed %s at %s" % [str(item_data.get("display_name", "Item")), manager._format_map_constructor_cell(cell)], "undo_hint":"Can undo by deleting item."})
		return result
	var canonical_prefab_id: String = WorldObjectCatalogRef.canonical_object_type(prefab_id)
	var constructor_prefab_defaults: Dictionary = WorldObjectCatalogRef.get_prefab_alias_defaults(prefab_id)
	var constructor_preview: Dictionary = WorldObjectCatalogRef.create_world_object(prefab_id, "constructor_preview")
	var requested_door_type: String = str(constructor_preview.get("door_type", constructor_prefab_defaults.get("door_type", "")))
	var requested_object_group: String = str(constructor_preview.get("object_group", ""))
	var requested_material: String = str(constructor_preview.get("material", ""))
	var placed_tile_type: int = previous_tile_type
	if str(constructor_preview.get("replaces_tile_with", "")) == "floor":
		placed_tile_type = GridManager.TILE_FLOOR
		manager.grid_manager.call("set_tile", cell, placed_tile_type)
	elif requested_object_group == "wall":
		placed_tile_type = GridManager.TILE_WALL
		manager.grid_manager.call("set_tile", cell, placed_tile_type)
	elif requested_door_type == WorldObjectCatalogRef.DOOR_TYPE_POWERED:
		placed_tile_type = GridManager.TILE_POWERED_GATE
		manager.grid_manager.call("set_tile", cell, placed_tile_type)
	elif requested_object_group == "door" and requested_material == WorldObjectCatalogRef.DOOR_MATERIAL_ENERGY:
		placed_tile_type = GridManager.TILE_DIGITAL_DOOR
		manager.grid_manager.call("set_tile", cell, placed_tile_type)
	elif requested_object_group == "door":
		placed_tile_type = GridManager.TILE_DOOR
		manager.grid_manager.call("set_tile", cell, placed_tile_type)
	var object_id: String = "mapedit_%s_%d" % [prefab_id, manager._map_constructor_runtime_object_seq]
	manager._map_constructor_runtime_object_seq += 1
	var object_data: Dictionary = WorldObjectCatalogRef.create_world_object(prefab_id, object_id)
	if object_data.is_empty():
		object_data = {"id": object_id, "object_type": canonical_prefab_id, "display_name": prefab_id.capitalize(), "state": "active"}
	object_data["position"] = cell
	object_data["created_by_map_constructor"] = true
	object_data["map_constructor_prefab_id"] = prefab_id
	object_data["map_constructor_tile_type"] = placed_tile_type
	object_data["map_constructor_previous_tile_type"] = previous_tile_type
	object_data["map_constructor_rotation_degrees"] = posmod(rotation_degrees, 360)
	var prefab_meta_result: Dictionary = manager.get_map_constructor_prefab_metadata(prefab_id)
	if bool(prefab_meta_result.get("ok", false)):
		var prefab_meta: Dictionary = manager._safe_dictionary(prefab_meta_result.get("prefab", {}))
		var prefab_defaults: Dictionary = manager._safe_dictionary(prefab_meta.get("default_state", {}))
		for default_key in prefab_defaults.keys():
			object_data[str(default_key)] = prefab_defaults[default_key]
	object_data = WorldObjectCatalogRef.apply_prefab_alias_defaults(canonical_prefab_id, prefab_id, object_data)
	object_data = WorldObjectCatalogRef.normalize_world_object_contract(object_data)
	object_data = WorldObjectCatalogRef.normalize_door_state_fields(object_data)
	if str(check.get("placement_mode", "")) == "wall_mounted":
		if bool(check.get("direct_wall_cell_mount", false)):
			var direct_anchor_floor_cell: Vector2i = manager._deserialize_cell_variant(check.get("anchor_floor_cell", Vector2i(-1, -1)))
			var direct_wall_side: String = str(check.get("wall_side", "south"))
			object_data = WallMountedPlacementRulesServiceRef.normalize_direct_wall_cell_mount_object(object_data, direct_wall_side, cell, direct_anchor_floor_cell)
			object_data["placement_mode"] = "wall_mounted"
			object_data["is_wall_mounted"] = true
			object_data["attached_wall_cell"] = manager._serialize_cell_key(cell)
			object_data["anchor_floor_cell"] = manager._serialize_cell_key(direct_anchor_floor_cell) if manager._is_valid_grid_cell(direct_anchor_floor_cell) else "-1,-1"
			object_data["position"] = cell
			object_data["wall_side"] = direct_wall_side
			object_data["interaction_side"] = direct_wall_side
			object_data["blocks_movement"] = false
			object_data["changes_passability"] = false
			object_data["does_not_block_movement"] = true
		else:
			var attachment: Dictionary = manager._resolve_wall_mounted_attachment(cell, preferred_wall_side)
			if not bool(attachment.get("ok", false)):
				return {"ok": false, "reason": str(attachment.get("reason", "no_adjacent_wall")), "message": str(attachment.get("message", "Blocked: no adjacent wall.")), "object_id": "", "warnings": []}
			var attached_wall_cell: Vector2i = Vector2i(attachment.get("attached_wall_cell", Vector2i(-1, -1)))
			if manager.has_method("is_breachable_wall_cell") and bool(manager.call("is_breachable_wall_cell", attached_wall_cell)):
				return {"ok": false, "reason": "breachable_wall_blocks_wall_mount", "message": "Cannot mount on a Breachable Wall.", "object_id": "", "warnings": []}
			if not manager._is_wall_or_boundary_cell(attached_wall_cell):
				return {"ok": false, "reason": "invalid_wall_attachment", "message": "Blocked: attached wall cell is not wall/boundary.", "object_id": "", "warnings": []}
			object_data["placement_mode"] = "wall_mounted"
			object_data["anchor_floor_cell"] = manager._serialize_cell_key(cell)
			object_data["attached_wall_cell"] = manager._serialize_cell_key(attached_wall_cell)
			object_data["wall_side"] = str(attachment.get("wall_side", "north"))
			object_data["interaction_side"] = object_data["wall_side"]
		object_data["is_wall_mounted"] = true
		object_data["mount"] = "wall"
		object_data["install_mode"] = "wall"
		object_data["blocks_movement"] = false
		object_data["changes_passability"] = false
		object_data["does_not_block_movement"] = true
	if CableTopologyServiceRef.is_cable_object(object_data):
		if _normalize_cable_install_mode(object_data.get("cable_install_mode", object_data.get("install_mode", "floor"))) == "wall" and not manager._is_map_constructor_wall_cell(cell):
			return {"ok": false, "reason": "wall_cable_requires_wall", "message": "Wall cable requires a wall in this cell.", "object_id": "", "warnings": []}
		if _normalize_cable_install_mode(object_data.get("cable_install_mode", object_data.get("install_mode", "floor"))) == "wall" and manager.has_method("is_breachable_wall_cell") and bool(manager.call("is_breachable_wall_cell", cell)):
			return {"ok": false, "reason": "breachable_wall_blocks_cable", "message": "Cannot route cables on a Breachable Wall.", "object_id": "", "warnings": []}
		var cable_validation: Dictionary = CableTopologyServiceRef.validate_placement(cell, manager.mission_world_objects, object_data)
		if not bool(cable_validation.get("ok", false)):
			return {"ok": false, "reason": "invalid_cable_junction", "message": str(cable_validation.get("message", CableTopologyServiceRef.ERROR_MESSAGE_JUNCTION_REQUIRES_SWITCH)), "object_id": "", "warnings": [], "cable_topology": cable_validation}
	object_data = manager._normalize_map_constructor_active_object_fields(object_data)
	object_data = WorldObjectCatalogRef.normalize_world_object_contract(object_data)
	object_data = WorldObjectCatalogRef.normalize_door_state_fields(object_data)
	_trace_wall_mounted_placement("place_final", {"prefab_id": prefab_id, "direct_wall_cell_mount": bool(check.get("direct_wall_cell_mount", false)), "final_object_position": object_data.get("position", cell), "attached_wall_cell": object_data.get("attached_wall_cell", ""), "wall_side": str(object_data.get("wall_side", "")), "interaction_side": str(object_data.get("interaction_side", "")), "placement_mode": str(object_data.get("placement_mode", "")), "is_wall_mounted": bool(object_data.get("is_wall_mounted", false))})
	manager.set_world_object_at_cell(cell, object_data)
	PowerSystemRef.recalculate_network(manager.mission_world_objects, str(object_data.get("power_network_id", "")))
	manager.refresh_world_cooling_received()
	result["object_id"] = object_id
	manager._record_map_constructor_change("place", {"entity_kind":"world_object", "entity_id":object_id, "object_type":canonical_prefab_id, "cell":cell, "summary":"Placed %s at %s" % [prefab_id, manager._format_map_constructor_cell(cell)], "undo_hint":"Can undo by deleting object."})
	return result

func _remove_map_constructor_entity_by_id(entity_kind: String, entity_id: String) -> Dictionary:
	if entity_kind == "item":
		for cell_variant in manager.cell_items.keys():
			var cell: Vector2i = Vector2i(cell_variant)
			var items: Array[Dictionary] = manager.get_items_at_cell(cell)
			for index in range(items.size() - 1, -1, -1):
				var item_data: Dictionary = items[index]
				if str(item_data.get("id", "")) != entity_id:
					continue
				if not bool(item_data.get("created_by_map_constructor", false)):
					return {"ok": false, "message": "Cannot remove non-constructor item.", "object_id": entity_id, "warnings": []}
				items.remove_at(index)
				manager.cell_items[cell] = items
				manager.mission_world_objects.erase(item_data)
				PowerSystemRef.recalculate_network(manager.mission_world_objects, "")
				manager.refresh_world_cooling_received()
				manager._record_map_constructor_change("delete", {"entity_kind":"item", "entity_id":entity_id, "object_type":str(item_data.get("item_type", item_data.get("object_type", "item"))), "cell":cell, "summary":"Deleted item %s" % entity_id, "undo_hint":"Cannot directly undo; use cleanup/autofix/patch undo systems when applicable."})
				return {"ok": true, "message": "Removed item.", "object_id": entity_id, "warnings": []}
		return {"ok": false, "message": "Nothing to remove.", "object_id": "", "warnings": []}
	if entity_kind == "wall":
		var wall_cell: Vector2i = _parse_wall_entity_cell(entity_id)
		if wall_cell.x < 0 or wall_cell.y < 0 or not manager._is_map_constructor_wall_cell(wall_cell):
			return {"ok": false, "message": "Wall not found.", "object_id": entity_id, "warnings": []}
		_set_wall_tile_for_constructor(wall_cell, GridManager.TILE_FLOOR)
		manager._record_map_constructor_change("delete", {"entity_kind":"wall", "entity_id":entity_id, "object_type":"wall", "cell":wall_cell, "summary":"Deleted wall at %s" % manager._format_map_constructor_cell(wall_cell), "undo_hint":"Place a wall again if needed."})
		return {"ok": true, "message": "Removed wall.", "object_id": entity_id, "cell": wall_cell, "warnings": []}
	var object_data: Dictionary = manager.get_world_object_by_id(entity_id)
	if object_data.is_empty():
		return {"ok": false, "message": "Nothing to remove.", "object_id": "", "warnings": []}
	if not bool(object_data.get("created_by_map_constructor", false)):
		return {"ok": false, "message": "Cannot remove non-constructor object.", "object_id": entity_id, "warnings": []}
	var object_cell: Vector2i = Vector2i(object_data.get("position", Vector2i(-1, -1)))
	var removed_network_id: String = str(object_data.get("power_network_id", ""))
	if manager.grid_manager != null and manager.grid_manager.has_method("set_tile") and not CableTopologyServiceRef.is_cable_object(object_data):
		var restore_tile_type: int = GridManager.TILE_FLOOR
		if object_data.has("map_constructor_previous_tile_type"):
			restore_tile_type = int(object_data.get("map_constructor_previous_tile_type", GridManager.TILE_FLOOR))
		manager.grid_manager.call("set_tile", object_cell, restore_tile_type)
	_remove_world_object_record_by_id(entity_id)
	PowerSystemRef.recalculate_network(manager.mission_world_objects, removed_network_id)
	manager.refresh_world_cooling_received()
	manager._record_map_constructor_change("delete", {"entity_kind":"world_object", "entity_id":entity_id, "object_type":str(object_data.get("object_type", "")), "cell":object_cell, "summary":"Deleted %s %s" % [str(object_data.get("object_type", "object")), entity_id], "undo_hint":"Cannot directly undo; use cleanup/autofix/patch undo systems when applicable."})
	return {"ok": true, "message": "Removed object.", "object_id": entity_id, "warnings": []}

func _clone_map_constructor_entity_data(source_data: Dictionary, target_cell: Vector2i, preferred_wall_side: String, assign_new_id: bool) -> Dictionary:
	var clone_data: Dictionary = source_data.duplicate(true)
	if assign_new_id:
		var prefab_id: String = str(clone_data.get("map_constructor_prefab_id", clone_data.get("object_type", "object")))
		clone_data["id"] = "mapedit_%s_%d" % [prefab_id, manager._map_constructor_runtime_object_seq]
		manager._map_constructor_runtime_object_seq += 1
		if str(clone_data.get("object_type", "")).strip_edges().to_lower().begins_with("power_source"):
			clone_data["power_network_id"] = "%s_net" % str(clone_data.get("id", "power_source"))
	clone_data.erase("position")
	clone_data.erase("anchor_floor_cell")
	clone_data.erase("attached_wall_cell")
	clone_data.erase("wall_side")
	clone_data.erase("map_constructor_previous_tile_type")
	clone_data["position"] = target_cell
	if str(clone_data.get("placement_mode", "")) == "wall_mounted":
		var resolved_side: String = preferred_wall_side.strip_edges()
		if resolved_side.is_empty():
			resolved_side = str(source_data.get("wall_side", ""))
		var attachment: Dictionary = manager._resolve_wall_mounted_attachment(target_cell, resolved_side)
		if not bool(attachment.get("ok", false)):
			return {"ok": false, "message": str(attachment.get("message", "Blocked: no adjacent wall."))}
		clone_data["placement_mode"] = "wall_mounted"
		clone_data["anchor_floor_cell"] = manager._serialize_cell_key(target_cell)
		clone_data["attached_wall_cell"] = manager._serialize_cell_key(Vector2i(attachment.get("attached_wall_cell", Vector2i(-1, -1))))
		clone_data["wall_side"] = str(attachment.get("wall_side", "north"))
	return {"ok": true, "data": clone_data}

func move_map_constructor_entity_to_cell(entity_kind: String, entity_id: String, target_cell: Vector2i, preferred_wall_side: String = "") -> Dictionary:
	if not manager._is_task_test_constructor_context():
		return {"ok": false, "message": "Operation is available only in TASK TEST constructor mode."}
	if entity_kind == "wall":
		var source_wall_cell: Vector2i = _parse_wall_entity_cell(entity_id)
		if source_wall_cell.x < 0 or source_wall_cell.y < 0 or not manager._is_map_constructor_wall_cell(source_wall_cell):
			return {"ok": false, "message": "Move failed: wall not found."}
		var wall_place_check: Dictionary = manager.can_place_map_constructor_prefab("wall", target_cell, preferred_wall_side)
		if not bool(wall_place_check.get("ok", false)):
			return {"ok": false, "message": str(wall_place_check.get("message", "Move failed."))}
		_set_wall_tile_for_constructor(source_wall_cell, GridManager.TILE_FLOOR)
		_set_wall_tile_for_constructor(target_cell, GridManager.TILE_WALL)
		var moved_wall_id: String = "wall_%d_%d" % [target_cell.x, target_cell.y]
		manager._record_map_constructor_change("move", {"entity_kind":"wall", "entity_id":moved_wall_id, "object_type":"wall", "cell":target_cell, "summary":"Moved wall from %s to %s" % [manager._format_map_constructor_cell(source_wall_cell), manager._format_map_constructor_cell(target_cell)], "details":{"from_cell":source_wall_cell, "to_cell":target_cell}, "undo_hint":"Move back manually."})
		return {"ok": true, "message": "Moved wall.", "object_id": moved_wall_id, "entity_id": moved_wall_id, "cell": target_cell}
	var entity: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
	if not bool(entity.get("ok", false)):
		return {"ok": false, "message": "Move failed: entity not found."}
	var data: Dictionary = manager._safe_dictionary(entity.get("data", {}))
	var source_cell: Vector2i = Vector2i(entity.get("cell", Vector2i(-1, -1)))
	var prefab_id: String = str(data.get("map_constructor_prefab_id", data.get("object_type", "")))
	var place_check: Dictionary = manager.can_place_map_constructor_prefab(prefab_id, target_cell, preferred_wall_side)
	if not bool(place_check.get("ok", false)):
		return {"ok": false, "message": str(place_check.get("message", "Move failed."))}
	var clone_result: Dictionary = _clone_map_constructor_entity_data(data, target_cell, preferred_wall_side, false)
	if not bool(clone_result.get("ok", false)):
		return {"ok": false, "message": str(clone_result.get("message", "Move failed."))}
	var cloned_data: Dictionary = manager._safe_dictionary(clone_result.get("data", {}))
	var remove_result: Dictionary = _remove_map_constructor_entity_by_id(str(entity.get("entity_kind", entity_kind)), entity_id)
	if not bool(remove_result.get("ok", false)):
		return {"ok": false, "message": str(remove_result.get("message", "Move failed."))}
	if entity_kind == "item" or str(entity.get("entity_kind", entity_kind)) == "item":
		manager.add_item_at_cell(target_cell, cloned_data)
		PowerSystemRef.recalculate_network(manager.mission_world_objects, "")
		manager.refresh_world_cooling_received()
		manager._record_map_constructor_change("move", {"entity_kind":"item", "entity_id":str(cloned_data.get("id", "")), "object_type":str(cloned_data.get("item_type", cloned_data.get("object_type", "item"))), "cell":target_cell, "summary":"Moved object %s from %s to %s" % [str(cloned_data.get("id", "")), manager._format_map_constructor_cell(source_cell), manager._format_map_constructor_cell(target_cell)], "details":{"from_cell":source_cell, "to_cell":target_cell}, "undo_hint":"Move back manually."})
		return {"ok": true, "message": "Moved object.", "object_id": str(cloned_data.get("id", ""))}
	var previous_tile_type: int = GridManager.TILE_FLOOR
	if manager.grid_manager != null and manager.grid_manager.has_method("get_tile"):
		previous_tile_type = int(manager.grid_manager.call("get_tile", target_cell))
	cloned_data["map_constructor_previous_tile_type"] = previous_tile_type
	if manager.grid_manager != null and manager.grid_manager.has_method("set_tile"):
		manager.grid_manager.call("set_tile", target_cell, int(cloned_data.get("map_constructor_tile_type", previous_tile_type)))
	manager.set_world_object_at_cell(target_cell, cloned_data)
	PowerSystemRef.recalculate_network(manager.mission_world_objects, str(cloned_data.get("power_network_id", "")))
	manager.refresh_world_cooling_received()
	manager._record_map_constructor_change("move", {"entity_kind":"world_object", "entity_id":str(cloned_data.get("id", "")), "object_type":str(cloned_data.get("object_type", "")), "cell":target_cell, "summary":"Moved object %s from %s to %s" % [str(cloned_data.get("id", "")), manager._format_map_constructor_cell(source_cell), manager._format_map_constructor_cell(target_cell)], "details":{"from_cell":source_cell, "to_cell":target_cell}, "undo_hint":"Move back manually."})
	return {"ok": true, "message": "Moved object.", "object_id": str(cloned_data.get("id", ""))}

func duplicate_map_constructor_entity_to_cell(entity_kind: String, entity_id: String, target_cell: Vector2i, preferred_wall_side: String = "") -> Dictionary:
	if not manager._is_task_test_constructor_context():
		return {"ok": false, "message": "Operation is available only in TASK TEST constructor mode."}
	if entity_kind == "wall":
		var source_wall_cell: Vector2i = _parse_wall_entity_cell(entity_id)
		if source_wall_cell.x < 0 or source_wall_cell.y < 0 or not manager._is_map_constructor_wall_cell(source_wall_cell):
			return {"ok": false, "message": "Duplicate failed: wall not found."}
		var wall_place_check: Dictionary = manager.can_place_map_constructor_prefab("wall", target_cell, preferred_wall_side)
		if not bool(wall_place_check.get("ok", false)):
			return {"ok": false, "message": str(wall_place_check.get("message", "Duplicate failed."))}
		_set_wall_tile_for_constructor(target_cell, GridManager.TILE_WALL)
		var duplicated_wall_id: String = "wall_%d_%d" % [target_cell.x, target_cell.y]
		manager._record_map_constructor_change("duplicate", {"entity_kind":"wall", "entity_id":duplicated_wall_id, "object_type":"wall", "cell":target_cell, "summary":"Duplicated wall %s to %s" % [entity_id, manager._format_map_constructor_cell(target_cell)], "details":{"source_entity_id":entity_id}, "undo_hint":"Can undo by deleting duplicate."})
		return {"ok": true, "message": "Duplicated wall.", "object_id": duplicated_wall_id, "entity_id": duplicated_wall_id, "cell": target_cell}
	var entity: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
	if not bool(entity.get("ok", false)):
		return {"ok": false, "message": "Duplicate failed: entity not found."}
	var data: Dictionary = manager._safe_dictionary(entity.get("data", {}))
	var prefab_id: String = str(data.get("map_constructor_prefab_id", data.get("object_type", "")))
	var place_check: Dictionary = manager.can_place_map_constructor_prefab(prefab_id, target_cell, preferred_wall_side)
	if not bool(place_check.get("ok", false)):
		return {"ok": false, "message": str(place_check.get("message", "Duplicate failed."))}
	var clone_result: Dictionary = _clone_map_constructor_entity_data(data, target_cell, preferred_wall_side, true)
	if not bool(clone_result.get("ok", false)):
		return {"ok": false, "message": str(clone_result.get("message", "Duplicate failed."))}
	var cloned_data: Dictionary = manager._safe_dictionary(clone_result.get("data", {}))
	if entity_kind == "item" or str(entity.get("entity_kind", entity_kind)) == "item":
		manager.add_item_at_cell(target_cell, cloned_data)
		PowerSystemRef.recalculate_network(manager.mission_world_objects, "")
		manager.refresh_world_cooling_received()
		manager._record_map_constructor_change("duplicate", {"entity_kind":"item", "entity_id":str(cloned_data.get("id", "")), "object_type":str(cloned_data.get("item_type", cloned_data.get("object_type", "item"))), "cell":target_cell, "summary":"Duplicated object %s to %s" % [entity_id, manager._format_map_constructor_cell(target_cell)], "details":{"source_entity_id":entity_id}, "undo_hint":"Can undo by deleting duplicate."})
		return {"ok": true, "message": "Duplicated object.", "object_id": str(cloned_data.get("id", ""))}
	var previous_tile_type: int = GridManager.TILE_FLOOR
	if manager.grid_manager != null and manager.grid_manager.has_method("get_tile"):
		previous_tile_type = int(manager.grid_manager.call("get_tile", target_cell))
	cloned_data["map_constructor_previous_tile_type"] = previous_tile_type
	if manager.grid_manager != null and manager.grid_manager.has_method("set_tile"):
		manager.grid_manager.call("set_tile", target_cell, int(cloned_data.get("map_constructor_tile_type", previous_tile_type)))
	manager.set_world_object_at_cell(target_cell, cloned_data)
	PowerSystemRef.recalculate_network(manager.mission_world_objects, str(cloned_data.get("power_network_id", "")))
	manager.refresh_world_cooling_received()
	manager._record_map_constructor_change("duplicate", {"entity_kind":"world_object", "entity_id":str(cloned_data.get("id", "")), "object_type":str(cloned_data.get("object_type", "")), "cell":target_cell, "summary":"Duplicated object %s to %s" % [entity_id, manager._format_map_constructor_cell(target_cell)], "details":{"source_entity_id":entity_id}, "undo_hint":"Can undo by deleting duplicate."})
	return {"ok": true, "message": "Duplicated object.", "object_id": str(cloned_data.get("id", ""))}

func remove_map_constructor_object_at_cell(cell: Vector2i) -> Dictionary:
	if not manager._is_task_test_constructor_context():
		return {"ok": false, "message": "Operation is available only in TASK TEST constructor mode."}
	var entity: Dictionary = manager.get_map_constructor_editable_entity_at_cell(cell)
	if not bool(entity.get("ok", false)):
		return {"ok": false, "message": "Nothing to remove.", "object_id": "", "warnings": []}
	return _remove_map_constructor_entity_by_id(str(entity.get("entity_kind", "")), str(entity.get("id", "")))



func _get_map_constructor_entity_inspection_tab_id(entity_kind: String, data: Dictionary) -> String:
	if entity_kind == "item":
		return "items"
	var object_type: String = str(data.get("object_type", data.get("item_type", ""))).to_lower().strip_edges()
	var object_group: String = str(data.get("object_group", data.get("group", ""))).to_lower().strip_edges()
	var category: String = str(data.get("category", "")).to_lower().strip_edges()
	var prefab_id: String = str(data.get("map_constructor_prefab_id", "")).to_lower().strip_edges()
	var joined: String = "%s %s %s %s" % [object_type, object_group, category, prefab_id]
	if object_group == "threat" or joined.contains("enemy") or joined.contains("bipob") or joined.contains("bipop"):
		return "enemies"
	if object_type == "power_cable" or object_type == "power_cable_reel" or object_group == "cable" or joined.contains("power_cable"):
		return "cables"
	if object_type == "light" or object_group == "lighting" or joined.contains(" lighting"):
		return "lighting"
	if object_group == "wall" or object_type == "wall":
		return "walls"
	return "objects"


func _append_map_constructor_cell_inspection_entity(tabs_by_id: Dictionary, tab_id: String, entity_kind: String, entity_id: String, cell: Vector2i, data: Dictionary) -> void:
	if not tabs_by_id.has(tab_id):
		return
	var tab: Dictionary = Dictionary(tabs_by_id.get(tab_id, {}))
	var entities: Array = Array(tab.get("entities", []))
	entities.append({"entity_kind": entity_kind, "id": entity_id, "cell": cell, "data": data.duplicate(true)})
	tab["entities"] = entities
	tabs_by_id[tab_id] = tab


func get_map_constructor_cell_inspection_model(cell: Vector2i, preferred_entity_kind: String = "", preferred_entity_id: String = "") -> Dictionary:
	var tab_order: Array[Dictionary] = [
		{"id":"objects", "title":"Objects", "entities": []},
		{"id":"enemies", "title":"Enemies", "entities": []},
		{"id":"items", "title":"Items", "entities": []},
		{"id":"cables", "title":"Cables", "entities": []},
		{"id":"lighting", "title":"Lighting", "entities": []},
		{"id":"walls", "title":"Walls", "entities": []},
		{"id":"floor", "title":"Floor", "entities": []}
	]
	var tabs_by_id: Dictionary = {}
	for tab in tab_order:
		tabs_by_id[str(tab.get("id", ""))] = Dictionary(tab).duplicate(true)
	var tile_type: int = -1
	var tile_name: String = ""
	var in_bounds: bool = true
	if manager.grid_manager != null and manager.grid_manager.has_method("is_in_bounds"):
		in_bounds = bool(manager.grid_manager.call("is_in_bounds", cell))
	if manager.grid_manager != null and manager.grid_manager.has_method("get_tile") and in_bounds:
		tile_type = int(manager.grid_manager.call("get_tile", cell))
		if manager.grid_manager.has_method("get_tile_name"):
			tile_name = str(manager.grid_manager.call("get_tile_name", tile_type))
	var floor_data: Dictionary = {"id":"floor_%d_%d" % [cell.x, cell.y], "display_name":"Floor", "object_type":"floor", "position":cell, "tile_type":tile_type, "tile_name":tile_name, "in_bounds":in_bounds}
	_append_map_constructor_cell_inspection_entity(tabs_by_id, "floor", "floor", str(floor_data.get("id", "")), cell, floor_data)
	if in_bounds and manager.grid_manager != null and tile_type == GridManager.TILE_WALL:
		var wall_data: Dictionary = {"id":"wall_%d_%d" % [cell.x, cell.y], "display_name":"Wall", "object_type":"wall", "object_group":"wall", "position":cell, "tile_type":tile_type, "tile_name":tile_name, "has_actual_wall_layer":true}
		_append_map_constructor_cell_inspection_entity(tabs_by_id, "walls", "wall", str(wall_data.get("id", "")), cell, wall_data)
	for object_variant in manager.mission_world_objects:
		var object_data: Dictionary = manager._safe_dictionary(object_variant)
		if object_data.is_empty():
			continue
		var object_cell: Vector2i = manager._get_world_object_cell_from_data(object_data)
		var matches_cell: bool = object_cell == cell
		if not matches_cell and str(object_data.get("placement_mode", "")) == "wall_mounted":
			matches_cell = manager._deserialize_cell_variant(object_data.get("anchor_floor_cell", Vector2i(-1, -1))) == cell or manager._deserialize_cell_variant(object_data.get("attached_wall_cell", Vector2i(-1, -1))) == cell
		if not matches_cell:
			continue
		var object_id: String = str(object_data.get("id", ""))
		_append_map_constructor_cell_inspection_entity(tabs_by_id, _get_map_constructor_entity_inspection_tab_id("world_object", object_data), "world_object", object_id, object_cell if object_cell.x >= 0 and object_cell.y >= 0 else cell, manager._normalize_map_constructor_active_object_fields(object_data))
	for cell_variant in manager.cell_items.keys():
		var item_cell: Vector2i = Vector2i(cell_variant)
		if item_cell != cell:
			continue
		for item_variant in manager.get_items_at_cell(item_cell):
			var item_data: Dictionary = manager._safe_dictionary(item_variant)
			_append_map_constructor_cell_inspection_entity(tabs_by_id, "items", "item", str(item_data.get("id", "")), item_cell, item_data)
	if manager.active_bipob_ref != null and is_instance_valid(manager.active_bipob_ref) and manager.active_bipob_ref.has_method("get_grid_position"):
		var bipob_cell: Vector2i = Vector2i(manager.active_bipob_ref.call("get_grid_position"))
		if bipob_cell == cell:
			_append_map_constructor_cell_inspection_entity(tabs_by_id, "enemies", "bipob", "active_bipob", cell, {"id":"active_bipob", "display_name":"Active Bipob", "object_type":"bipob", "position":cell})
	var present_tabs: Array[Dictionary] = []
	for tab in tab_order:
		var tab_id: String = str(tab.get("id", ""))
		var resolved_tab: Dictionary = Dictionary(tabs_by_id.get(tab_id, tab))
		if tab_id == "floor" or not Array(resolved_tab.get("entities", [])).is_empty():
			present_tabs.append(resolved_tab)
	var preferred_tab: String = "floor"
	if not preferred_entity_id.is_empty():
		var preferred_entity: Dictionary = get_map_constructor_entity_by_id(preferred_entity_kind, preferred_entity_id)
		if bool(preferred_entity.get("ok", false)):
			preferred_tab = _get_map_constructor_entity_inspection_tab_id(str(preferred_entity.get("entity_kind", preferred_entity_kind)), manager._safe_dictionary(preferred_entity.get("data", {})))
	return {"ok": true, "cell": cell, "tabs": present_tabs, "preferred_tab": preferred_tab}

func get_map_constructor_entity_by_id(entity_kind: String, entity_id: String) -> Dictionary:
	if entity_kind.is_empty():
		var world_entity: Dictionary = get_map_constructor_entity_by_id("world_object", entity_id)
		if bool(world_entity.get("ok", false)):
			return world_entity
		return get_map_constructor_entity_by_id("item", entity_id)
	if entity_kind == "world_object":
		var object_data: Dictionary = manager.get_world_object_by_id(entity_id)
		if object_data.is_empty():
			return {"ok": false, "reason": "not_found", "entity_kind": entity_kind, "id": entity_id}
		return {"ok": true, "entity_kind": entity_kind, "id": entity_id, "cell": Vector2i(object_data.get("position", Vector2i(-1, -1))), "data": manager._normalize_map_constructor_active_object_fields(object_data)}
	if entity_kind == "item":
		for cell_variant in manager.cell_items.keys():
			var cell: Vector2i = Vector2i(cell_variant)
			var items: Array[Dictionary] = manager.get_items_at_cell(cell)
			for item_data in items:
				if str(item_data.get("id", "")) == entity_id:
					return {"ok": true, "entity_kind": entity_kind, "id": entity_id, "cell": cell, "data": item_data}
		return {"ok": false, "reason": "not_found", "entity_kind": entity_kind, "id": entity_id}
	if entity_kind == "wall":
		var wall_cell: Vector2i = _parse_wall_entity_cell(entity_id)
		if wall_cell.x >= 0 and wall_cell.y >= 0 and manager._is_map_constructor_wall_cell(wall_cell):
			return {"ok": true, "entity_kind": entity_kind, "id": entity_id, "cell": wall_cell, "data": {"id":entity_id, "object_type":"wall", "object_group":"wall", "position":wall_cell}}
		return {"ok": false, "reason": "not_found", "entity_kind": entity_kind, "id": entity_id}
	return {"ok": false, "reason": "unsupported_entity_kind", "entity_kind": entity_kind, "id": entity_id}

func _sync_terminal_door_link(entity_id: String, data: Dictionary, field_name: String, old_value: Variant, new_value: Variant) -> void:
	if field_name not in ["target_door_id", "linked_terminal_id", "required_terminal_id", "control_terminal_id"]:
		return
	var old_id: String = str(old_value).strip_edges()
	var new_id: String = str(new_value).strip_edges()
	var group: String = str(data.get("object_group", "")).strip_edges().to_lower()
	if group == "terminal" and field_name == "target_door_id":
		for door_id in [old_id, new_id]:
			if door_id.is_empty():
				continue
			var door: Dictionary = manager.get_world_object_by_id(door_id)
			if door.is_empty():
				continue
			if door_id == new_id:
				door["linked_terminal_id"] = entity_id
			elif str(door.get("linked_terminal_id", "")) == entity_id:
				door["linked_terminal_id"] = ""
			manager.update_world_object_by_id(door_id, door)
	elif group == "door" and field_name in ["linked_terminal_id", "required_terminal_id", "control_terminal_id"]:
		for terminal_id in [old_id, new_id]:
			if terminal_id.is_empty():
				continue
			var terminal: Dictionary = manager.get_world_object_by_id(terminal_id)
			if terminal.is_empty():
				continue
			if terminal_id == new_id:
				terminal["target_door_id"] = entity_id
				var linked_ids: Array = manager._safe_array(terminal.get("linked_door_ids", []))
				if not linked_ids.has(entity_id):
					linked_ids.append(entity_id)
				terminal["linked_door_ids"] = linked_ids
			else:
				if str(terminal.get("target_door_id", "")) == entity_id:
					terminal["target_door_id"] = ""
				var linked_ids: Array = manager._safe_array(terminal.get("linked_door_ids", []))
				linked_ids.erase(entity_id)
				terminal["linked_door_ids"] = linked_ids
			manager.update_world_object_by_id(terminal_id, terminal)


func get_normalized_map_constructor_circuit_id(data: Dictionary) -> String:
	for field_name in CIRCUIT_ID_FIELDS:
		var circuit_id: String = str(data.get(field_name, "")).strip_edges()
		if not circuit_id.is_empty():
			return circuit_id
	return ""

func _get_map_constructor_entity_circuit_id(entity_kind: String, entity_id: String) -> String:
	var entity: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
	if not bool(entity.get("ok", false)):
		return ""
	return get_normalized_map_constructor_circuit_id(manager._safe_dictionary(entity.get("data", {})))

func _get_circuit_display_name(circuit_id: String) -> String:
	var normalized_id: String = circuit_id.strip_edges()
	if normalized_id.is_empty():
		return ""
	for object_variant in manager.mission_world_objects:
		var object_data: Dictionary = manager._safe_dictionary(object_variant)
		if get_normalized_map_constructor_circuit_id(object_data) == normalized_id:
			var object_circuit_name: String = str(object_data.get("circuit_name", "")).strip_edges()
			if not object_circuit_name.is_empty():
				return object_circuit_name
	for cell_variant in manager.cell_items.keys():
		for item_variant in manager.get_items_at_cell(Vector2i(cell_variant)):
			var item_data: Dictionary = manager._safe_dictionary(item_variant)
			if get_normalized_map_constructor_circuit_id(item_data) == normalized_id:
				var item_circuit_name: String = str(item_data.get("circuit_name", "")).strip_edges()
				if not item_circuit_name.is_empty():
					return item_circuit_name
	return ""

func _make_map_constructor_circuit_option(circuit_id: String) -> Dictionary:
	var normalized_id: String = circuit_id.strip_edges()
	var display_name: String = _get_circuit_display_name(normalized_id)
	if normalized_id == "main" and display_name.is_empty():
		display_name = "Main"
	var label: String = normalized_id
	if not display_name.is_empty():
		label = "%s — %s" % [normalized_id, display_name]
	return {"id": normalized_id, "label": label, "name": display_name}

func get_map_constructor_circuit_options() -> Array[Dictionary]:
	var ids: Dictionary = {"main": true}
	for object_variant in manager.mission_world_objects:
		var object_data: Dictionary = manager._safe_dictionary(object_variant)
		var circuit_id: String = get_normalized_map_constructor_circuit_id(object_data)
		if not circuit_id.is_empty():
			ids[circuit_id] = true
	for cell_variant in manager.cell_items.keys():
		for item_variant in manager.get_items_at_cell(Vector2i(cell_variant)):
			var item_data: Dictionary = manager._safe_dictionary(item_variant)
			var item_circuit_id: String = get_normalized_map_constructor_circuit_id(item_data)
			if not item_circuit_id.is_empty():
				ids[item_circuit_id] = true
	var out: Array[Dictionary] = []
	for id_variant in ids.keys():
		out.append(_make_map_constructor_circuit_option(str(id_variant)))
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("id", "")) < str(b.get("id", ""))
	)
	return out

func get_map_constructor_same_circuit_entities(entity_kind: String, entity_id: String) -> Array[Dictionary]:
	var circuit_id: String = _get_map_constructor_entity_circuit_id(entity_kind, entity_id)
	var out: Array[Dictionary] = []
	if circuit_id.is_empty():
		return out
	for object_variant in manager.mission_world_objects:
		var object_data: Dictionary = manager._safe_dictionary(object_variant)
		var object_id: String = str(object_data.get("id", "")).strip_edges()
		if object_id.is_empty() or object_id == entity_id:
			continue
		if get_normalized_map_constructor_circuit_id(object_data) != circuit_id:
			continue
		out.append({"entity_kind":"world_object", "id":object_id, "label":str(object_data.get("display_name", object_id)), "cell":Vector2i(object_data.get("position", Vector2i(-1, -1))), "object_type":str(object_data.get("object_type", "")), "circuit_id":circuit_id})
	for cell_variant in manager.cell_items.keys():
		var cell: Vector2i = Vector2i(cell_variant)
		for item_variant in manager.get_items_at_cell(cell):
			var item_data: Dictionary = manager._safe_dictionary(item_variant)
			var item_id: String = str(item_data.get("id", "")).strip_edges()
			if item_id.is_empty() or item_id == entity_id:
				continue
			if get_normalized_map_constructor_circuit_id(item_data) != circuit_id:
				continue
			out.append({"entity_kind":"item", "id":item_id, "label":str(item_data.get("display_name", item_id)), "cell":cell, "object_type":str(item_data.get("item_type", item_data.get("object_type", ""))), "circuit_id":circuit_id})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ac: Vector2i = Vector2i(a.get("cell", Vector2i.ZERO))
		var bc: Vector2i = Vector2i(b.get("cell", Vector2i.ZERO))
		return "%04d|%04d|%s" % [ac.y, ac.x, str(a.get("id", ""))] < "%04d|%04d|%s" % [bc.y, bc.x, str(b.get("id", ""))]
	)
	return out

func get_map_constructor_circuit_summary(entity_kind: String, entity_id: String) -> Dictionary:
	var entity: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
	if not bool(entity.get("ok", false)):
		return {"ok": false, "message": "Entity not found.", "circuit_id": "", "circuit_name": "", "options": [], "linked_entities": []}
	var data: Dictionary = manager._safe_dictionary(entity.get("data", {}))
	var circuit_id: String = get_normalized_map_constructor_circuit_id(data)
	var circuit_name: String = str(data.get("circuit_name", "")).strip_edges()
	if circuit_name.is_empty():
		circuit_name = _get_circuit_display_name(circuit_id)
	return {"ok": true, "circuit_id": circuit_id, "circuit_name": circuit_name, "options": get_map_constructor_circuit_options(), "linked_entities": get_map_constructor_same_circuit_entities(entity_kind, entity_id)}

func _build_map_constructor_circuit_updates(data: Dictionary, circuit_id: String, circuit_name: String = "", include_name: bool = false) -> Dictionary:
	var updates: Dictionary = {"circuit_id": circuit_id}
	var object_type: String = str(data.get("object_type", data.get("item_type", ""))).strip_edges().to_lower()
	var object_group: String = str(data.get("object_group", data.get("group", ""))).strip_edges().to_lower()
	if data.has("power_network_id") or object_group == "power" or object_type.contains("power") or object_type.contains("cable") or object_type.contains("socket") or object_type.contains("outlet"):
		updates["power_network_id"] = circuit_id
	for field_name in ["power_circuit_id", "network_id", "power_network_id", "chain_id", "link_group", "cable_group", "connected_circuit"]:
		if data.has(field_name):
			updates[field_name] = circuit_id
	if include_name:
		updates["circuit_name"] = circuit_name
	return updates

func assign_map_constructor_entity_to_circuit(entity_kind: String, entity_id: String, circuit_id: String, circuit_name: String = "") -> Dictionary:
	if not manager._is_task_test_constructor_context():
		return {"ok": false, "message": "Operation is available only in TASK TEST constructor mode."}
	var normalized_id: String = circuit_id.strip_edges()
	if normalized_id.is_empty():
		return {"ok": false, "message": "Circuit id is required."}
	var entity: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
	if not bool(entity.get("ok", false)):
		return {"ok": false, "message": "Entity not found."}
	var data: Dictionary = manager._safe_dictionary(entity.get("data", {}))
	var updates: Dictionary = _build_map_constructor_circuit_updates(data, normalized_id, circuit_name.strip_edges(), not circuit_name.strip_edges().is_empty())
	var result: Dictionary = manager.update_map_constructor_entity_properties(str(entity.get("entity_kind", entity_kind)), entity_id, updates)
	if bool(result.get("ok", false)):
		result["message"] = "Assigned circuit %s." % normalized_id
		result["circuit_id"] = normalized_id
	return result

func create_map_constructor_circuit(entity_kind: String, entity_id: String, requested_id: String = "", circuit_name: String = "") -> Dictionary:
	var circuit_id: String = requested_id.strip_edges()
	if circuit_id.is_empty():
		circuit_id = "mapedit_circuit_%d" % manager._map_constructor_runtime_object_seq
		manager._map_constructor_runtime_object_seq += 1
	return assign_map_constructor_entity_to_circuit(entity_kind, entity_id, circuit_id, circuit_name)

func rename_map_constructor_circuit(entity_kind: String, entity_id: String, circuit_name: String) -> Dictionary:
	if not manager._is_task_test_constructor_context():
		return {"ok": false, "message": "Operation is available only in TASK TEST constructor mode."}
	var circuit_id: String = _get_map_constructor_entity_circuit_id(entity_kind, entity_id)
	if circuit_id.is_empty():
		return {"ok": false, "message": "No circuit assigned."}
	var normalized_name: String = circuit_name.strip_edges()
	var updated_count: int = 0
	for object_variant in manager.mission_world_objects:
		var object_data: Dictionary = manager._safe_dictionary(object_variant)
		var object_id: String = str(object_data.get("id", "")).strip_edges()
		if object_id.is_empty() or get_normalized_map_constructor_circuit_id(object_data) != circuit_id:
			continue
		var result: Dictionary = manager.update_map_constructor_entity_properties("world_object", object_id, {"circuit_name": normalized_name})
		if bool(result.get("ok", false)):
			updated_count += 1
	for cell_variant in manager.cell_items.keys():
		for item_variant in manager.get_items_at_cell(Vector2i(cell_variant)):
			var item_data: Dictionary = manager._safe_dictionary(item_variant)
			var item_id: String = str(item_data.get("id", "")).strip_edges()
			if item_id.is_empty() or get_normalized_map_constructor_circuit_id(item_data) != circuit_id:
				continue
			var item_result: Dictionary = manager.update_map_constructor_entity_properties("item", item_id, {"circuit_name": normalized_name})
			if bool(item_result.get("ok", false)):
				updated_count += 1
	return {"ok": true, "message": "Renamed circuit %s." % circuit_id, "circuit_id": circuit_id, "circuit_name": normalized_name, "updated_count": updated_count}

func delete_map_constructor_circuit(circuit_id: String) -> Dictionary:
	if not manager._is_task_test_constructor_context():
		return {"ok": false, "message": "Operation is available only in TASK TEST constructor mode."}
	var normalized_id: String = circuit_id.strip_edges()
	if normalized_id.is_empty():
		return {"ok": false, "message": "Circuit id is required."}
	if normalized_id == "main":
		return {"ok": false, "message": "Main circuit cannot be deleted."}
	var updated_count: int = 0
	for object_variant in manager.mission_world_objects:
		var object_data: Dictionary = manager._safe_dictionary(object_variant)
		var object_id: String = str(object_data.get("id", "")).strip_edges()
		if object_id.is_empty() or get_normalized_map_constructor_circuit_id(object_data) != normalized_id:
			continue
		var result: Dictionary = manager.update_map_constructor_entity_properties("world_object", object_id, _build_map_constructor_circuit_updates(object_data, "main", "Main", true))
		if bool(result.get("ok", false)):
			updated_count += 1
	for cell_variant in manager.cell_items.keys():
		for item_variant in manager.get_items_at_cell(Vector2i(cell_variant)):
			var item_data: Dictionary = manager._safe_dictionary(item_variant)
			var item_id: String = str(item_data.get("id", "")).strip_edges()
			if item_id.is_empty() or get_normalized_map_constructor_circuit_id(item_data) != normalized_id:
				continue
			var item_result: Dictionary = manager.update_map_constructor_entity_properties("item", item_id, _build_map_constructor_circuit_updates(item_data, "main", "Main", true))
			if bool(item_result.get("ok", false)):
				updated_count += 1
	return {"ok": true, "message": "Deleted circuit %s." % normalized_id, "circuit_id": normalized_id, "updated_count": updated_count}

func _normalize_cable_install_mode(value: Variant) -> String:
	var raw_mode: String = str(value).strip_edges().to_lower()
	match raw_mode:
		"hidden", "concealed", "embedded":
			return "hidden"
		"wall", "wall_cable", "wall_surface":
			return "wall"
		_:
			return "floor"

func _normalize_cable_health_state(value: Variant) -> String:
	var raw_state: String = str(value).strip_edges().to_lower()
	match raw_state:
		"damaged", "broken", "cut":
			return raw_state
		_:
			return "normal"

func _is_cable_property_field(field_name: String) -> bool:
	return field_name in ["mount", "cable_install_mode", "install_mode", "placement_mode", "route_surface", "hidden_installation", "is_hidden", "cable_health_state", "health_state", "state", "damaged", "broken"]

func _is_cable_entity_data(data: Dictionary) -> bool:
	var object_type: String = str(data.get("object_type", data.get("item_type", ""))).strip_edges().to_lower()
	return object_type.contains("cable") or object_type.contains("wire")

func _cable_wall_install_missing_wall_cells(data: Dictionary) -> Array[Vector2i]:
	var missing_cells: Array[Vector2i] = []
	var cells_to_check: Array[Vector2i] = []
	cells_to_check.append(manager._deserialize_cell_variant(data.get("position", Vector2i(-1, -1))))
	for path_cell_variant in manager._safe_array(data.get("cable_path_cells", [])):
		var path_cell: Vector2i = manager._deserialize_cell_variant(path_cell_variant)
		if path_cell.x >= 0 and path_cell.y >= 0 and not cells_to_check.has(path_cell):
			cells_to_check.append(path_cell)
	for cell in cells_to_check:
		if cell.x >= 0 and cell.y >= 0 and not manager._is_map_constructor_wall_cell(cell):
			missing_cells.append(cell)
	return missing_cells

func _apply_cable_property_aliases(data: Dictionary, field_name: String, value: Variant) -> Dictionary:
	if not _is_cable_entity_data(data) or not _is_cable_property_field(field_name):
		return data
	if field_name in ["mount", "cable_install_mode", "install_mode", "placement_mode", "route_surface", "hidden_installation", "is_hidden"]:
		var install_mode: String = "hidden" if (field_name in ["hidden_installation", "is_hidden"] and bool(value)) else _normalize_cable_install_mode(value)
		if field_name == "route_surface" and str(value).strip_edges().to_lower() == "floor" and bool(data.get("is_hidden", false)):
			install_mode = "hidden"
		data["mount"] = "wall" if install_mode == "wall" else "floor"
		data["cable_install_mode"] = install_mode
		data["install_mode"] = install_mode
		data["route_surface"] = "wall" if install_mode == "wall" else "floor"
		data["hidden_installation"] = install_mode == "hidden"
		data["is_hidden"] = install_mode == "hidden"
	if field_name in ["cable_health_state", "health_state", "state", "damaged", "broken"]:
		var health_state: String = "normal"
		if field_name == "damaged" and bool(value):
			health_state = "damaged"
		elif field_name == "broken" and bool(value):
			health_state = "broken"
		else:
			health_state = _normalize_cable_health_state(value)
		data["cable_health_state"] = health_state
		data["health_state"] = health_state
		data["cut"] = health_state == "cut"
		data["broken"] = health_state == "broken"
		data["damaged"] = health_state in ["damaged", "broken", "cut"]
		if str(data.get("object_type", "")).strip_edges().to_lower() == "power_cable":
			data["state"] = "ok" if health_state == "normal" else health_state
	return data


func apply_map_constructor_property_update(entity_kind: String, entity_id: String, field_name: String, raw_value: Variant) -> Dictionary:
	if not manager._is_task_test_constructor_context():
		return {"ok": false, "message": "Operation is available only in TASK TEST constructor mode."}
	var result: Dictionary = {"ok": false, "message": "Update failed.", "entity_id": entity_id, "field": field_name, "value": raw_value}
	var schema: Dictionary = manager._get_map_constructor_editable_field_schema()
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
	var data: Dictionary = manager._safe_dictionary(entity_info.get("data", {}))
	if not data.has(field_name):
		var default_value: Variant = manager.get_default_map_constructor_field_value(field_name, resolved_kind, data)
		if default_value == null:
			result["message"] = "Field is unavailable for this entity."
			return result
		data[field_name] = default_value
	var converted: Dictionary = manager._convert_map_constructor_field_value(field_name, raw_value, str(schema[field_name]))
	if not bool(converted.get("ok", false)):
		result["message"] = str(converted.get("message", "Invalid value."))
		return result
	var new_value: Variant = converted.get("value")
	if _is_cable_entity_data(data) and field_name in ["mount", "cable_install_mode", "install_mode", "placement_mode", "route_surface"] and _normalize_cable_install_mode(new_value) == "wall":
		if not _cable_wall_install_missing_wall_cells(data).is_empty():
			result["message"] = "Wall cable requires a wall in this cell."
			return result
		var cable_cell: Vector2i = manager._deserialize_cell_variant(data.get("position", data.get("cell", Vector2i(-1, -1))))
		if manager.has_method("is_breachable_wall_cell") and bool(manager.call("is_breachable_wall_cell", cable_cell)):
			result["message"] = "Cannot route cables on a Breachable Wall."
			return result
	var old_value: Variant = data.get(field_name)
	var old_network_id: String = str(data.get("power_network_id", ""))
	data[field_name] = new_value
	data = _apply_cable_property_aliases(data, field_name, new_value)
	if resolved_kind == "world_object" and field_name == "access_type" and WorldObjectCatalogRef.normalize_access_type(new_value) == WorldObjectCatalogRef.ACCESS_TYPE_KEY_CARD and str(data.get("state", "closed")) not in ["damaged", "broken", "destroyed", "jammed"]:
		data["state"] = "locked"
		data["is_locked"] = true
		data["is_closed"] = true
		data["is_open"] = false
		data["blocks_movement"] = true
	if resolved_kind == "world_object" and field_name == "door_class" and int(new_value) == 1:
		data["required_manipulator_level"] = 1
	if field_name == "status" and str(data.get("archetype_id", "")) == "terminal":
		data["state"] = new_value
	if resolved_kind == "world_object":
		data = WorldObjectCatalogRef.normalize_door_state_fields(WorldObjectCatalogRef.normalize_world_object_contract(data))
		data = manager._normalize_map_constructor_active_object_fields(data)
		manager.update_world_object_by_id(entity_id, data)
	elif resolved_kind == "item":
		data = WorldObjectCatalogRef.normalize_item_contract(WorldObjectCatalogRef.normalize_archetype_object(WorldObjectCatalogRef.normalize_world_object_contract(data)))
		var found_item: bool = false
		for cell_variant in manager.cell_items.keys():
			var cell: Vector2i = Vector2i(cell_variant)
			var items: Array[Dictionary] = manager.get_items_at_cell(cell)
			for index in range(items.size()):
				var item_data: Dictionary = items[index]
				if str(item_data.get("id", "")) != entity_id:
					continue
				items[index] = data
				manager.cell_items[cell] = items
				manager._sync_world_item_record(data)
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
	var needs_power_refresh: bool = field_name in CIRCUIT_ID_FIELDS or field_name in ["is_powered", "requires_external_power", "power_mode", "power_source_id", "current_heat", "working_heat", "overheat_threshold"]
	if needs_power_refresh:
		PowerSystemRef.recalculate_network(manager.mission_world_objects, old_network_id)
		PowerSystemRef.recalculate_network(manager.mission_world_objects, str(data.get("power_network_id", "")))
	manager.refresh_world_cooling_received()
	if resolved_kind == "world_object":
		_sync_terminal_door_link(entity_id, data, field_name, old_value, new_value)
	if resolved_kind == "world_object" and field_name in ["power_source_id", "control_terminal_id", "access_terminal_id"]:
		var linked_id: String = str(new_value).strip_edges()
		if not linked_id.is_empty():
			var linked_object: Dictionary = manager.get_world_object_by_id(linked_id)
			if not linked_object.is_empty():
				var backlink_field: String = "powered_device_ids" if field_name == "power_source_id" else "controlled_device_ids"
				if field_name == "access_terminal_id":
					backlink_field = "stored_access_target_ids"
				var backlink_ids: Array = manager._safe_array(linked_object.get(backlink_field, []))
				if not backlink_ids.has(entity_id):
					backlink_ids.append(entity_id)
				linked_object[backlink_field] = backlink_ids
				manager.update_world_object_by_id(linked_id, linked_object)
	if field_name == "linked_door_id" and resolved_kind == "item":
		var door_id: String = str(new_value).strip_edges()
		if not door_id.is_empty():
			var linked_door: Dictionary = manager.get_world_object_by_id(door_id)
			if not linked_door.is_empty():
				linked_door["required_key_id"] = entity_id
				manager.update_world_object_by_id(door_id, linked_door)
	elif field_name == "required_key_id" and resolved_kind == "world_object":
		var key_id: String = str(new_value).strip_edges()
		if not key_id.is_empty():
			var linked_key: Dictionary = manager.get_cell_item_by_id(key_id)
			if not linked_key.is_empty():
				linked_key["linked_door_id"] = entity_id
				manager._sync_world_item_record(linked_key)
				for cell_variant in manager.cell_items.keys():
					var cell: Vector2i = Vector2i(cell_variant)
					var items: Array[Dictionary] = manager.get_items_at_cell(cell)
					for item_index in range(items.size()):
						if str(items[item_index].get("id", "")) == key_id:
							items[item_index] = linked_key
							manager.cell_items[cell] = items
							break
	result["ok"] = true
	result["value"] = new_value
	result["message"] = "Updated %s." % field_name
	manager._record_map_constructor_change("property_update", {"entity_kind":resolved_kind, "entity_id":entity_id, "object_type":str(data.get("object_type", data.get("item_type", ""))), "cell":Vector2i(entity_info.get("cell", Vector2i(-1, -1))), "summary":"Updated %s on %s" % [field_name, entity_id], "details":{"field":field_name, "old":old_value, "new":new_value}, "undo_hint":"Can undo by setting previous value manually."})
	return result
