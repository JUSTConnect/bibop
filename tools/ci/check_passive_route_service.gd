extends SceneTree

const RouteService = preload("res://scripts/game/cooling/passive_route_service.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _segment(object_id: String, kind: String, cell: Vector2i, sides: Array[String], mount_side: String = "inner") -> Dictionary:
	return {
		"id": object_id,
		"position": cell,
		"object_group": "cooling",
		"object_type": "external_air_duct" if kind == "air_duct" else "external_water_pipe",
		"routing_kind": kind,
		"mount_side": mount_side,
		"route_sides": sides.duplicate()
	}

func _code(result: Dictionary) -> String:
	return str(result.get("code", result.get("reason_code", "")))

func _has_issue(issues: Array, code: String) -> bool:
	for issue_value in issues:
		if issue_value is Dictionary and _code(Dictionary(issue_value)) == code:
			return true
	return false

func _run() -> void:
	await process_frame
	var straight: Dictionary = _segment("straight", "air_duct", Vector2i.ZERO, ["NW", "SE"])
	var straight_validation: Dictionary = RouteService.validate_segment(straight)
	_assert(bool(straight_validation.get("success", false)), "straight pair rejected")
	_assert(str(Dictionary(straight_validation.get("details", {})).get("route_shape", "")) == RouteService.SHAPE_STRAIGHT, "straight shape mismatch")

	var turn: Dictionary = _segment("turn", "air_duct", Vector2i.ZERO, ["NE", "SE"])
	var turn_validation: Dictionary = RouteService.validate_segment(turn)
	_assert(bool(turn_validation.get("success", false)), "turn pair rejected")
	_assert(str(Dictionary(turn_validation.get("details", {})).get("route_shape", "")) == RouteService.SHAPE_TURN, "turn shape mismatch")
	var reverse_turn: Dictionary = _segment("turn", "air_duct", Vector2i.ZERO, ["SE", "NE"])
	_assert(Array(Dictionary(RouteService.validate_segment(reverse_turn).get("details", {})).get("normalized_route_pair", [])) == Array(Dictionary(turn_validation.get("details", {})).get("normalized_route_pair", [])), "route pair order changed normalization")

	var duplicate: Dictionary = _segment("duplicate", "air_duct", Vector2i.ZERO, ["NE", "NE"])
	_assert(_code(RouteService.validate_segment(duplicate)) == RouteService.CODE_ROUTE_SIDE_DUPLICATE, "duplicate pair accepted")
	var missing: Dictionary = _segment("missing", "air_duct", Vector2i.ZERO, [])
	_assert(_code(RouteService.validate_segment(missing)) == RouteService.CODE_ROUTE_PAIR_MISSING, "missing pair code mismatch")
	var three_way: Dictionary = _segment("three", "air_duct", Vector2i.ZERO, ["NE", "SE", "SW"])
	_assert(_code(RouteService.validate_segment(three_way)) == RouteService.CODE_ROUTE_PAIR_COUNT_INVALID, "T-junction accepted")
	var four_way: Dictionary = _segment("four", "air_duct", Vector2i.ZERO, ["NE", "SE", "SW", "NW"])
	_assert(_code(RouteService.validate_segment(four_way)) == RouteService.CODE_ROUTE_PAIR_COUNT_INVALID, "cross accepted")
	var invalid_mount: Dictionary = _segment("bad_mount", "air_duct", Vector2i.ZERO, ["NE", "SW"], "middle")
	_assert(_code(RouteService.validate_segment(invalid_mount)) == RouteService.CODE_INVALID_MOUNT_SIDE, "invalid mount accepted")

	var objects: Dictionary = {
		"a": _segment("a", "air_duct", Vector2i(0, 0), ["NW", "SE"]),
		"b": _segment("b", "air_duct", Vector2i(1, 0), ["NW", "SE"]),
		"c": _segment("c", "air_duct", Vector2i(2, 0), ["NW", "SW"])
	}
	var topology: Dictionary = RouteService.build_topology(objects)
	_assert(Array(Dictionary(topology.get("neighbors", {})).get("a", [])).has("b"), "compatible neighbor a-b missing")
	_assert(Array(Dictionary(topology.get("neighbors", {})).get("b", [])).has("a"), "compatible neighbor b-a missing")
	_assert(Array(Dictionary(topology.get("neighbors", {})).get("b", [])).has("c"), "compatible neighbor b-c missing")
	var component_a: String = str(Dictionary(topology.get("component_by_object_id", {})).get("a", ""))
	_assert(not component_a.is_empty(), "computed component id missing")
	_assert(component_a == str(Dictionary(topology.get("component_by_object_id", {})).get("c", "")), "connected route split into components")
	var topology_again: Dictionary = RouteService.build_topology(objects)
	_assert(var_to_str(topology.get("components", [])) == var_to_str(topology_again.get("components", [])), "component calculation is not deterministic")

	var wrong_kind_objects: Dictionary = {
		"air": _segment("air", "air_duct", Vector2i(0, 1), ["NW", "SE"]),
		"water": _segment("water", "water_pipe", Vector2i(1, 1), ["NW", "SE"])
	}
	var wrong_kind_topology: Dictionary = RouteService.build_topology(wrong_kind_objects)
	_assert(_has_issue(Array(Dictionary(wrong_kind_topology.get("diagnostics", {})).get("air", [])), RouteService.CODE_NEIGHBOR_KIND_INCOMPATIBLE), "kind mismatch issue missing")

	var wrong_mount_objects: Dictionary = {
		"inner": _segment("inner", "air_duct", Vector2i(0, 2), ["NW", "SE"], "inner"),
		"outer": _segment("outer", "air_duct", Vector2i(1, 2), ["NW", "SE"], "outer")
	}
	var wrong_mount_topology: Dictionary = RouteService.build_topology(wrong_mount_objects)
	_assert(_has_issue(Array(Dictionary(wrong_mount_topology.get("diagnostics", {})).get("inner", [])), RouteService.CODE_NEIGHBOR_MOUNT_INCOMPATIBLE), "mount mismatch issue missing")

	var port_mismatch_objects: Dictionary = {
		"left": _segment("left", "air_duct", Vector2i(0, 3), ["NW", "SE"]),
		"right": _segment("right", "air_duct", Vector2i(1, 3), ["NE", "SE"])
	}
	var port_mismatch_topology: Dictionary = RouteService.build_topology(port_mismatch_objects)
	_assert(_has_issue(Array(Dictionary(port_mismatch_topology.get("diagnostics", {})).get("left", [])), RouteService.CODE_NEIGHBOR_PORT_MISMATCH), "port mismatch issue missing")

	var disconnected_objects: Dictionary = {"solo": _segment("solo", "water_pipe", Vector2i(4, 4), ["NE", "SW"], "outer")}
	var disconnected_preview: Dictionary = RouteService.preview_segment("solo", disconnected_objects["solo"], disconnected_objects)
	_assert(_has_issue(Array(disconnected_preview.get("issues", [])), RouteService.CODE_DISCONNECTED), "disconnected issue missing")
	_assert(str(disconnected_preview.get("mount_side", "")) == "outer", "outer mount side changed")

	var legacy: Dictionary = {
		"id":"legacy",
		"position":Vector2i.ZERO,
		"object_type":"external_air_duct",
		"route_mode":"outer",
		"wall_routing_mode":"outer",
		"wall_side_1":"SW",
		"wall_side_2":"NE",
		"state":"active",
		"durability":12,
		"cooling_contour_mode":"manual",
		"cooling_contour_id":"legacy_manual",
		"cooling_contour_member_ids":["legacy"],
		"connected_device_ids":["x"],
		"runtime_test_override":true
	}
	var canonical: Dictionary = RouteService.canonicalize_segment(legacy)
	_assert(str(canonical.get("mount_side", "")) == "outer", "legacy route mode not migrated")
	_assert(Array(canonical.get("route_sides", [])) == ["NE", "SW"], "legacy sides not normalized")
	for forbidden in RouteService.FORBIDDEN_STORED_FIELDS:
		_assert(not canonical.has(forbidden), "forbidden passive field remained: %s" % forbidden)
	_assert(not canonical.has("route_mode") and not canonical.has("wall_side_1"), "legacy route aliases remained")
	_assert(str(canonical.get("route_shape", "")) == RouteService.SHAPE_STRAIGHT, "legacy route shape mismatch")

	var before_objects: String = var_to_str(objects)
	RouteService.preview_segment("a", objects["a"], objects)
	_assert(var_to_str(objects) == before_objects, "preview mutated authoring input")

	await process_frame
	if failures.is_empty():
		print("PASSIVE_ROUTE_SERVICE_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("PASSIVE_ROUTE_SERVICE_GATE: FAIL: %s" % failure)
	quit(1)
