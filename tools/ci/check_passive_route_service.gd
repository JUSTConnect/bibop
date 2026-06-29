extends SceneTree

const PassiveRouteServiceRef = preload("res://scripts/game/routing/passive_route_service.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _segment(object_id: String, kind: String, cell: Vector2i, side_a: String, side_b: String, mode: String = "inner", mount_side: String = "SW") -> Dictionary:
	return {
		"id": object_id,
		"position": cell,
		"object_group": "cooling",
		"object_type": kind,
		"routing_kind": kind,
		"route_mode": mode,
		"mount_side": mount_side,
		"route_side_1": side_a,
		"route_side_2": side_b
	}

func _issue_codes(preview: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for issue in Array(preview.get("issues", [])):
		var code: String = str(Dictionary(issue).get("code", ""))
		if not result.has(code):
			result.append(code)
	return result

func _run() -> void:
	await process_frame
	var straight_a: Dictionary = _segment("straight_a", "air_duct", Vector2i.ZERO, "NE", "SW")
	var straight_b: Dictionary = _segment("straight_b", "air_duct", Vector2i.ZERO, "SW", "NE")
	var preview_a: Dictionary = PassiveRouteServiceRef.validate_segment(straight_a)
	var preview_b: Dictionary = PassiveRouteServiceRef.validate_segment(straight_b)
	_assert(bool(preview_a.get("success", false)), "straight route rejected")
	_assert(str(preview_a.get("route_shape", "")) == PassiveRouteServiceRef.SHAPE_STRAIGHT, "opposite pair is not straight")
	_assert(Array(preview_a.get("route_pair", [])) == Array(preview_b.get("route_pair", [])), "route pair depends on authoring order")

	var turn: Dictionary = _segment("turn", "water_pipe", Vector2i.ZERO, "NE", "SE")
	var turn_preview: Dictionary = PassiveRouteServiceRef.validate_segment(turn)
	_assert(bool(turn_preview.get("success", false)), "turn route rejected")
	_assert(str(turn_preview.get("route_shape", "")) == PassiveRouteServiceRef.SHAPE_TURN, "adjacent pair is not turn")

	var duplicate: Dictionary = _segment("duplicate", "air_duct", Vector2i.ZERO, "NE", "NE")
	_assert(str(PassiveRouteServiceRef.validate_segment(duplicate).get("code", "")) == PassiveRouteServiceRef.CODE_ROUTE_SIDE_DUPLICATE, "duplicate sides accepted")
	var missing: Dictionary = _segment("missing", "air_duct", Vector2i.ZERO, "NE", "")
	_assert(str(PassiveRouteServiceRef.validate_segment(missing).get("code", "")) in [PassiveRouteServiceRef.CODE_ROUTE_SIDE_INVALID, PassiveRouteServiceRef.CODE_ROUTE_SIDE_MISSING], "missing side accepted")
	var crossing: Dictionary = _segment("crossing", "air_duct", Vector2i.ZERO, "NE", "SE")
	crossing["route_sides"] = ["NE", "SE", "SW", "NW"]
	_assert(str(PassiveRouteServiceRef.validate_segment(crossing).get("code", "")) == PassiveRouteServiceRef.CODE_ROUTE_PAIR_TOO_MANY, "crossing accepted")

	var west: Dictionary = _segment("west", "air_duct", Vector2i(0, 0), "NW", "SE")
	var east: Dictionary = _segment("east", "air_duct", Vector2i(1, 0), "NW", "SE")
	var objects: Array[Dictionary] = [west, east]
	var before: String = var_to_str(objects)
	var topology: Dictionary = PassiveRouteServiceRef.build_topology(objects)
	_assert(var_to_str(objects) == before, "topology mutated input")
	var west_preview: Dictionary = Dictionary(Dictionary(topology.get("previews", {})).get("west", {}))
	var east_preview: Dictionary = Dictionary(Dictionary(topology.get("previews", {})).get("east", {}))
	_assert(Array(west_preview.get("compatible_neighbor_ids", [])).has("east"), "matching physical ports did not connect")
	_assert(str(west_preview.get("component_id", "")) == str(east_preview.get("component_id", "")), "connected segments have different component IDs")
	_assert(not str(west_preview.get("component_id", "")).is_empty(), "component ID missing")

	var reordered: Array[Dictionary] = [east, west]
	var topology_reordered: Dictionary = PassiveRouteServiceRef.build_topology(reordered)
	var reordered_preview: Dictionary = Dictionary(Dictionary(topology_reordered.get("previews", {})).get("west", {}))
	_assert(str(reordered_preview.get("component_id", "")) == str(west_preview.get("component_id", "")), "component ID depends on object order")

	var wrong_kind: Dictionary = _segment("wrong_kind", "water_pipe", Vector2i(1, 0), "NW", "SE")
	var kind_topology: Dictionary = PassiveRouteServiceRef.build_topology([west, wrong_kind])
	_assert(_issue_codes(Dictionary(Dictionary(kind_topology.get("previews", {})).get("west", {}))).has(PassiveRouteServiceRef.CODE_NEIGHBOR_KIND_MISMATCH), "kind mismatch issue missing")
	var wrong_mode: Dictionary = _segment("wrong_mode", "air_duct", Vector2i(1, 0), "NW", "SE", "outer")
	var mode_topology: Dictionary = PassiveRouteServiceRef.build_topology([west, wrong_mode])
	_assert(_issue_codes(Dictionary(Dictionary(mode_topology.get("previews", {})).get("west", {}))).has(PassiveRouteServiceRef.CODE_NEIGHBOR_MODE_MISMATCH), "mode mismatch issue missing")
	var wrong_mount: Dictionary = _segment("wrong_mount", "air_duct", Vector2i(1, 0), "NW", "SE", "inner", "SE")
	var mount_topology: Dictionary = PassiveRouteServiceRef.build_topology([west, wrong_mount])
	_assert(_issue_codes(Dictionary(Dictionary(mount_topology.get("previews", {})).get("west", {}))).has(PassiveRouteServiceRef.CODE_NEIGHBOR_MOUNT_MISMATCH), "mount mismatch issue missing")
	var wrong_port: Dictionary = _segment("wrong_port", "air_duct", Vector2i(1, 0), "NE", "SW")
	var port_topology: Dictionary = PassiveRouteServiceRef.build_topology([west, wrong_port])
	_assert(_issue_codes(Dictionary(Dictionary(port_topology.get("previews", {})).get("west", {}))).has(PassiveRouteServiceRef.CODE_NEIGHBOR_PORT_MISMATCH), "port mismatch issue missing")

	var outer_left: Dictionary = _segment("outer_left", "water_pipe", Vector2i(0, 2), "NW", "SE", "outer", "SW")
	var outer_right_bad: Dictionary = _segment("outer_right_bad", "water_pipe", Vector2i(1, 2), "NE", "SW", "outer", "SW")
	var outer_topology: Dictionary = PassiveRouteServiceRef.build_topology([outer_left, outer_right_bad])
	_assert(not Array(Dictionary(Dictionary(outer_topology.get("previews", {})).get("outer_left", {})).get("compatible_neighbor_ids", [])).has("outer_right_bad"), "outer adjacency connected without opposite ports")

	var legacy: Dictionary = _segment("legacy", "air_duct", Vector2i.ZERO, "NE", "SW")
	legacy["state"] = "active"
	legacy["durability"] = 10
	legacy["cooling_contour_mode"] = "manual"
	legacy["cooling_contour_id"] = "manual_a"
	legacy["cooling_contour_member_ids"] = ["legacy"]
	legacy["connected_device_ids"] = ["x"]
	legacy["test_override_enabled"] = true
	var normalized: Dictionary = PassiveRouteServiceRef.normalize_segment(legacy)
	for field_name in ["state", "durability", "cooling_contour_mode", "cooling_contour_id", "cooling_contour_member_ids", "connected_device_ids", "test_override_enabled"]:
		_assert(not normalized.has(field_name), "forbidden passive field remained: %s" % field_name)
	_assert(str(normalized.get("route_shape", "")) == PassiveRouteServiceRef.SHAPE_STRAIGHT, "normalized geometry missing")
	var render_before: String = var_to_str(normalized)
	var render_snapshot: Dictionary = PassiveRouteServiceRef.get_render_snapshot(normalized, west_preview)
	_assert(var_to_str(normalized) == render_before, "render snapshot mutated route")
	_assert(Array(render_snapshot.get("route_pair", [])).size() == 2, "renderer snapshot lacks normalized route pair")

	await process_frame
	if failures.is_empty():
		print("PASSIVE_ROUTE_SERVICE_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("PASSIVE_ROUTE_SERVICE_GATE: FAIL: %s" % failure)
	quit(1)
