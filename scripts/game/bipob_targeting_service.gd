extends RefCounted
class_name BipobTargetingService

const BreachableWallServiceRef = preload("res://scripts/game/wall/breachable_wall_service.gd")
const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const DEBUG_RUNTIME_ACTION_TARGET_TRACE := false


static func _trace_runtime_action_target(payload: Dictionary) -> void:
	if not DEBUG_RUNTIME_ACTION_TARGET_TRACE:
		return
	print("[RuntimeActionTarget] %s" % JSON.stringify(payload))


static func _debug_platform_target(_message: String, _payload: Dictionary = {}) -> void:
	return

static func get_facing_cell(controller: Variant) -> Vector2i:
	return controller.grid_position + controller.get_direction_vector(controller.direction)


static func get_facing_object(controller: Variant) -> Dictionary:
	if controller.mission_manager == null:
		return {}
	var facing_cell: Vector2i = get_facing_cell(controller)
	var world_object: Dictionary = Dictionary(controller.mission_manager.get_world_object_at_cell(facing_cell))
	return resolve_runtime_action_target_for_cell(controller, facing_cell, world_object)


static func _get_wall_mounted_object_candidate(controller: Variant, target_cell: Vector2i) -> Dictionary:
	if controller == null or controller.mission_manager == null or not controller.mission_manager.has_method("get_wall_mounted_world_object_at_cell"):
		return {}
	return Dictionary(controller.mission_manager.call("get_wall_mounted_world_object_at_cell", target_cell))


static func resolve_runtime_action_target_for_cell(controller: Variant, target_cell: Vector2i, world_object: Dictionary = {}) -> Dictionary:
	if controller == null or controller.mission_manager == null:
		return world_object
	var wall_mounted_candidate: Dictionary = _get_wall_mounted_object_candidate(controller, target_cell)
	if not wall_mounted_candidate.is_empty():
		return wall_mounted_candidate
	var breachable_wall_target: Dictionary = {}
	if controller.mission_manager.has_method("get_breachable_wall_action_target_at_cell"):
		breachable_wall_target = Dictionary(controller.mission_manager.call("get_breachable_wall_action_target_at_cell", target_cell))
	if breachable_wall_target.is_empty():
		return world_object
	if world_object.is_empty():
		return breachable_wall_target
	if BreachableWallServiceRef.is_active_breachable_wall_data(world_object):
		return world_object
	var object_group: String = str(world_object.get("object_group", "")).strip_edges().to_lower()
	var object_type: String = str(world_object.get("object_type", "")).strip_edges().to_lower()
	if object_group == "wall" or object_type == "wall" or object_type == "breachable_wall":
		return breachable_wall_target
	return world_object


static func get_facing_item(controller: Variant) -> Dictionary:
	if controller.mission_manager == null:
		return {}
	var items: Array = controller.mission_manager.get_items_at_cell(get_facing_cell(controller))
	return Dictionary(items[0]) if not items.is_empty() else {}


static func _get_platform_action_target_under_actor(controller: Variant) -> Dictionary:
	if controller == null or controller.mission_manager == null:
		_debug_platform_target("ABORT_NO_CONTROLLER_OR_MANAGER")
		return {}

	var actor_cell: Vector2i = Vector2i(controller.grid_position)

	if controller.mission_manager.has_method("get_platform_for_cell"):
		var platform_variant: Variant = controller.mission_manager.call("get_platform_for_cell", actor_cell)
		if platform_variant is Dictionary:
			var platform_candidate: Dictionary = Dictionary(platform_variant)
			_debug_platform_target("CHECK_GET_PLATFORM_FOR_CELL", {
				"actor_cell": actor_cell,
				"raw": platform_candidate
			})

			if _is_platform_action_target_candidate(platform_candidate):
				var normalized_platform: Dictionary = _normalize_platform_action_target(platform_candidate, actor_cell)
				_debug_platform_target("FOUND_BY_GET_PLATFORM_FOR_CELL", {
					"actor_cell": actor_cell,
					"id": str(normalized_platform.get("id", "")),
					"object_group": str(normalized_platform.get("object_group", "")),
					"object_type": str(normalized_platform.get("object_type", "")),
					"position": normalized_platform.get("position", null),
					"platform_cells": normalized_platform.get("platform_cells", [])
				})
				return normalized_platform

	if controller.mission_manager.has_method("get_world_object_at_cell"):
		var world_object_variant: Variant = controller.mission_manager.call("get_world_object_at_cell", actor_cell)
		if world_object_variant is Dictionary:
			var world_object_candidate: Dictionary = Dictionary(world_object_variant)
			_debug_platform_target("CHECK_WORLD_OBJECT_AT_ACTOR_CELL", {
				"actor_cell": actor_cell,
				"raw": world_object_candidate
			})

			if _is_platform_action_target_candidate(world_object_candidate):
				var normalized_world_object: Dictionary = _normalize_platform_action_target(world_object_candidate, actor_cell)
				_debug_platform_target("FOUND_BY_WORLD_OBJECT_AT_ACTOR_CELL", {
					"actor_cell": actor_cell,
					"id": str(normalized_world_object.get("id", "")),
					"object_group": str(normalized_world_object.get("object_group", "")),
					"object_type": str(normalized_world_object.get("object_type", "")),
					"position": normalized_world_object.get("position", null),
					"platform_cells": normalized_world_object.get("platform_cells", [])
				})
				return normalized_world_object

	var scanned_platform: Dictionary = _find_platform_by_footprint_cell(controller, actor_cell)
	if not scanned_platform.is_empty():
		_debug_platform_target("FOUND_BY_FOOTPRINT_SCAN", {
			"actor_cell": actor_cell,
			"id": str(scanned_platform.get("id", "")),
			"object_group": str(scanned_platform.get("object_group", "")),
			"object_type": str(scanned_platform.get("object_type", "")),
			"position": scanned_platform.get("position", null),
			"platform_cells": scanned_platform.get("platform_cells", [])
		})
		return scanned_platform

	_debug_platform_target("NOT_FOUND", {"actor_cell": actor_cell})
	return {}
	

static func _find_platform_by_footprint_cell(controller: Variant, actor_cell: Vector2i) -> Dictionary:
	if controller == null or controller.mission_manager == null:
		return {}

	if controller.mission_manager.has_method("get_map_constructor_placed_object_rows"):
		var rows: Array = Array(controller.mission_manager.call("get_map_constructor_placed_object_rows"))

		for row_variant in rows:
			if typeof(row_variant) != TYPE_DICTIONARY:
				continue

			var row: Dictionary = Dictionary(row_variant)
			var row_cell: Vector2i = _extract_row_cell(row)
			var object_id: String = str(row.get("id", row.get("entity_id", ""))).strip_edges()
			var candidate: Dictionary = row.duplicate(true)

			if not object_id.is_empty() and controller.mission_manager.has_method("get_map_constructor_entity_by_id"):
				var entity: Dictionary = Dictionary(controller.mission_manager.call("get_map_constructor_entity_by_id", "world_object", object_id))
				if bool(entity.get("ok", false)):
					candidate = Dictionary(entity.get("data", {}))
					candidate["id"] = object_id

					# Preserve actual placement from map row.
					if row_cell.x >= 0 and row_cell.y >= 0:
						candidate["position"] = row_cell
						candidate["platform_cells"] = [row_cell]

			if row_cell.x >= 0 and row_cell.y >= 0 and _is_platform_action_target_candidate(candidate):
				var normalized_candidate: Dictionary = _normalize_platform_action_target(candidate, actor_cell, row_cell)
				if _platform_contains_cell(normalized_candidate, actor_cell):
					return normalized_candidate

			if _is_platform_action_target_candidate(candidate) and _platform_contains_cell(candidate, actor_cell):
				return _normalize_platform_action_target(candidate, actor_cell)

	var world_objects_variant: Variant = controller.mission_manager.get("mission_world_objects")
	if world_objects_variant is Array:
		for object_variant in Array(world_objects_variant):
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue

			var object_data: Dictionary = Dictionary(object_variant)
			if not _is_platform_action_target_candidate(object_data):
				continue

			var placement_cell: Vector2i = _to_platform_cell(
				object_data.get("position", object_data.get("cell", object_data.get("pos", Vector2i(-1, -1)))),
				Vector2i(-1, -1)
			)

			var normalized_object: Dictionary = _normalize_platform_action_target(object_data, actor_cell, placement_cell)

			if _platform_contains_cell(normalized_object, actor_cell):
				return normalized_object

	return {}
	
static func _to_platform_cell(value: Variant, fallback: Vector2i = Vector2i(-1, -1)) -> Vector2i:
	if value is Vector2i:
		return Vector2i(value)

	if value is Vector2:
		return Vector2i(int(value.x), int(value.y))

	if value is Array:
		var values: Array = Array(value)
		if values.size() >= 2:
			return Vector2i(int(values[0]), int(values[1]))

	if value is Dictionary:
		var data: Dictionary = Dictionary(value)
		if data.has("x") and data.has("y"):
			return Vector2i(int(data.get("x", fallback.x)), int(data.get("y", fallback.y)))

	return WorldObjectCatalogRef.to_world_cell(value, fallback)

static func _extract_row_cell(row: Dictionary) -> Vector2i:
	for key in ["cell", "position", "grid_position", "world_cell", "target_position"]:
		if row.has(key):
			var cell: Vector2i = _to_platform_cell(row.get(key), Vector2i(-1, -1))
			if cell.x >= 0 and cell.y >= 0:
				return cell

	var x_value: int = int(row.get("x", row.get("cell_x", -1)))
	var y_value: int = int(row.get("y", row.get("cell_y", -1)))
	if x_value >= 0 and y_value >= 0:
		return Vector2i(x_value, y_value)

	return Vector2i(-1, -1)
				
static func _platform_contains_cell(platform_data: Dictionary, actor_cell: Vector2i) -> bool:
	if platform_data.is_empty():
		return false

	for cell_variant in Array(platform_data.get("platform_cells", [])):
		var platform_cell: Vector2i = _to_platform_cell(cell_variant, Vector2i(-1, -1))
		if platform_cell == actor_cell:
			return true

	for cell_variant in Array(platform_data.get("cells", [])):
		var cell: Vector2i = _to_platform_cell(cell_variant, Vector2i(-1, -1))
		if cell == actor_cell:
			return true

	var position_cell: Vector2i = _to_platform_cell(
		platform_data.get("position", platform_data.get("pos", platform_data.get("cell", Vector2i(-1, -1)))),
		Vector2i(-1, -1)
	)
	if position_cell == actor_cell:
		return true

	var x_value: int = int(platform_data.get("x", platform_data.get("cell_x", -1)))
	var y_value: int = int(platform_data.get("y", platform_data.get("cell_y", -1)))
	if x_value >= 0 and y_value >= 0 and Vector2i(x_value, y_value) == actor_cell:
		return true

	return false
	
static func _is_platform_action_target_candidate(candidate: Dictionary) -> bool:
	if candidate.is_empty():
		return false

	var object_group: String = str(candidate.get("object_group", candidate.get("group", ""))).strip_edges().to_lower()
	var object_type: String = str(candidate.get("object_type", candidate.get("type", ""))).strip_edges().to_lower()
	var archetype_id: String = str(candidate.get("archetype_id", candidate.get("map_constructor_prefab_id", ""))).strip_edges().to_lower()
	var platform_mode: String = str(candidate.get("platform_mode", "")).strip_edges().to_lower()
	var platform_type: String = str(candidate.get("platform_type", "")).strip_edges().to_lower()

	if object_group == "platform":
		return true
	if object_type == "platform":
		return true
	if object_type in ["lifting_platform", "rotating_platform"]:
		return true
	if archetype_id == "platform":
		return true
	if not platform_mode.is_empty():
		return true
	if platform_type in ["lifting", "rotating", "elevator", "rotator"]:
		return true

	return false
	
static func _normalize_platform_action_target(candidate: Dictionary, actor_cell: Vector2i, placement_cell: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	if candidate.is_empty():
		return {}

	var normalized: Dictionary = WorldObjectCatalogRef.normalize_world_object_contract(candidate).duplicate(true)

	# Runtime rule:
	# platform must always enter interaction pipeline as a platform,
	# regardless of legacy object_type/group fields.
	normalized["object_group"] = "platform"
	normalized["object_type"] = "platform"
	normalized["archetype_id"] = "platform"

	# The real installed cell has priority over stale authored platform_cells.
	var resolved_cell: Vector2i = placement_cell
	if resolved_cell.x < 0 or resolved_cell.y < 0:
		resolved_cell = _to_platform_cell(
			normalized.get("position", normalized.get("cell", normalized.get("pos", actor_cell))),
			actor_cell
		)

	if resolved_cell.x < 0 or resolved_cell.y < 0:
		resolved_cell = actor_cell

	normalized["position"] = resolved_cell

	# For a normal one-cell platform, footprint is its installed cell.
	# Old hardcoded platform_cells must not override placement.
	var platform_cells: Array = []
	for cell_variant in Array(normalized.get("platform_cells", [])):
		var cell: Vector2i = _to_platform_cell(cell_variant, Vector2i(-1, -1))
		if cell.x >= 0 and cell.y >= 0 and not platform_cells.has(cell):
			platform_cells.append(cell)

	if not platform_cells.has(resolved_cell):
		platform_cells.insert(0, resolved_cell)

	normalized["platform_cells"] = platform_cells

	return normalized
	
static func build_action_target_context(controller: Variant) -> Dictionary:
	var actor_cell: Vector2i = Vector2i(controller.grid_position)
	var facing_cell: Vector2i = get_facing_cell(controller)

	# 1. Platform rule:
	# Platform interaction is checked from Bipob current cell, not facing cell.
	# Important: selecting platform target must NOT depend on action availability.
	# First select platform-under-Bipob as target, then ViewModel/Controller decides
	# whether activate_platform is available.
	var platform_under_actor: Dictionary = _get_platform_action_target_under_actor(controller)
	if not platform_under_actor.is_empty():
		var platform_view_model: Dictionary = controller.build_runtime_action_view_model(platform_under_actor, actor_cell)
		return {
			"target_position": actor_cell,
			"target_object": platform_under_actor,
			"action_view_model": platform_view_model,
			"actions": Array(platform_view_model.get("actions", [])),
			"available_action_ids": Array(platform_view_model.get("available_action_ids", [])),
			"raw_action_ids": Array(platform_view_model.get("raw_action_ids", [])),
			"target_kind": "platform",
			"interaction_source": "current_cell_platform"
		}

	var raw_world_object: Dictionary = {}
	if controller.mission_manager != null:
		raw_world_object = Dictionary(controller.mission_manager.get_world_object_at_cell(facing_cell))

	var wall_mounted_candidate: Dictionary = _get_wall_mounted_object_candidate(controller, facing_cell)

	var breachable_wall_candidate: Dictionary = {}
	if controller.mission_manager != null and controller.mission_manager.has_method("get_breachable_wall_action_target_at_cell"):
		breachable_wall_candidate = Dictionary(controller.mission_manager.call("get_breachable_wall_action_target_at_cell", facing_cell))

	var target_position: Vector2i = facing_cell
	var target_object: Dictionary = resolve_runtime_action_target_for_cell(controller, target_position, raw_world_object)

	# 2. Platform in front is ignored for normal facing interaction.
	# Platform can be controlled only when Bipob stands on it.
	if _is_platform_action_target_candidate(target_object):
		target_object = {}

	var view_model: Dictionary = controller.build_runtime_action_view_model(target_object, target_position)

	# 3. Item rule:
	# Item can be picked up from facing cell or from Bipob current cell.
	if target_object.is_empty() and controller.mission_manager != null:
		var items: Array = controller.mission_manager.get_items_at_cell(facing_cell)

		if items.is_empty():
			items = controller.mission_manager.get_items_at_cell(actor_cell)
			if not items.is_empty():
				target_position = actor_cell

		if not items.is_empty():
			target_object = Dictionary(items[0])
			view_model = controller.build_runtime_action_view_model(target_object, target_position)

	var resolved_target: Dictionary = Dictionary(view_model.get("target", target_object))

	var direction_text: String = ""
	if controller.has_method("get_direction"):
		direction_text = str(controller.get_direction())

	_trace_runtime_action_target({
		"bipob_cell": str(controller.grid_position),
		"facing_cell": str(facing_cell),
		"target_position": str(target_position),
		"direction": direction_text,
		"raw_object": {
			"id": str(raw_world_object.get("id", "")),
			"object_type": str(raw_world_object.get("object_type", "")),
			"object_group": str(raw_world_object.get("object_group", "")),
			"state": str(raw_world_object.get("state", "")),
			"placement_mode": str(raw_world_object.get("placement_mode", raw_world_object.get("placement", "")))
		},
		"normalized_object": {
			"id": str(resolved_target.get("id", target_object.get("id", ""))),
			"object_type": str(resolved_target.get("object_type", target_object.get("object_type", ""))),
			"object_group": str(resolved_target.get("object_group", target_object.get("object_group", ""))),
			"state": str(resolved_target.get("state", target_object.get("state", ""))),
			"placement_mode": str(resolved_target.get("placement_mode", resolved_target.get("placement", target_object.get("placement_mode", target_object.get("placement", "")))))
		},
		"raw_object_dump": var_to_str(raw_world_object),
		"wall_mounted_candidate": {
			"id": str(wall_mounted_candidate.get("id", "")),
			"object_type": str(wall_mounted_candidate.get("object_type", "")),
			"object_group": str(wall_mounted_candidate.get("object_group", "")),
			"placement_mode": str(wall_mounted_candidate.get("placement_mode", wall_mounted_candidate.get("placement", "")))
		},
		"breachable_wall_candidate": {
			"id": str(breachable_wall_candidate.get("id", "")),
			"object_type": str(breachable_wall_candidate.get("object_type", "")),
			"object_group": str(breachable_wall_candidate.get("object_group", "")),
			"placement_mode": str(breachable_wall_candidate.get("placement_mode", breachable_wall_candidate.get("placement", "")))
		}
	})

	return {
		"target_position": target_position,
		"target_object": target_object,
		"action_view_model": view_model,
		"actions": Array(view_model.get("actions", [])),
		"available_action_ids": Array(view_model.get("available_action_ids", [])),
		"raw_action_ids": Array(view_model.get("raw_action_ids", [])),
		"target_kind": "object" if not target_object.is_empty() else "",
		"interaction_source": "facing_cell"
	}

static func build_connector_target_context(controller: Variant) -> Dictionary:
	return _build_action_context_for_id(build_action_target_context(controller), "connect")


static func build_heavy_claw_target_context(controller: Variant) -> Dictionary:
	var action_target: Dictionary = build_action_target_context(controller)
	var breach_context: Dictionary = _build_action_context_for_id(action_target, "break_breachable_wall")
	return breach_context if not breach_context.is_empty() else _build_action_context_for_id(action_target, "push")


static func build_targeting_snapshot(controller: Variant) -> Dictionary:
	var action_target: Dictionary = build_action_target_context(controller)
	return {
		"bipob_cell": controller.grid_position,
		"facing_cell": get_facing_cell(controller),
		"facing_object": get_facing_object(controller),
		"facing_item": get_facing_item(controller),
		"action_target": action_target,
		"connector_target": _build_action_context_for_id(action_target, "connect"),
		"heavy_claw_target": build_heavy_claw_target_context(controller)
	}


static func _build_action_context_for_id(action_target: Dictionary, action_id: String) -> Dictionary:
	var view_model: Dictionary = Dictionary(action_target.get("action_view_model", {}))
	for descriptor_variant in Array(view_model.get("actions", [])):
		if descriptor_variant is Dictionary and str(Dictionary(descriptor_variant).get("id", "")) == action_id:
			return {
				"target_position": action_target.get("target_position", Vector2i.ZERO),
				"target_object": action_target.get("target_object", {}),
				"action": Dictionary(descriptor_variant)
			}
	return {}
