extends SceneTree

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const PassiveRouteServiceRef = preload("res://scripts/game/routing/passive_route_service.gd")
const CoolingContourFacadeRef = preload("res://scripts/game/cooling/cooling_routing_contour_service.gd")
const WallRoutingValidationServiceRef = preload("res://scripts/game/routing/wall_routing_validation_service.gd")
const RouteRendererRef = preload("res://scripts/visual/renderer/route_renderer.gd")

class FakeRouteWorld:
	extends Node
	var mission_world_objects: Array[Dictionary] = []

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _segment(object_id: String, kind: String, cell: Vector2i, side_a: String, side_b: String) -> Dictionary:
	return {
		"id": object_id,
		"position": cell,
		"object_group": "cooling",
		"object_type": kind,
		"routing_kind": kind,
		"route_mode": "outer",
		"mount_side": "SW",
		"route_side_1": side_a,
		"route_side_2": side_b
	}

func _codes(issues: Array[Dictionary]) -> Array[String]:
	var result: Array[String] = []
	for issue in issues:
		var code: String = str(issue.get("code", ""))
		if not result.has(code):
			result.append(code)
	return result

func _run() -> void:
	await process_frame
	var legacy: Dictionary = {
		"id": "legacy_duct",
		"position": Vector2i(2, 2),
		"map_constructor_prefab_id": "external_air_duct",
		"object_type": "external_air_duct",
		"state": "active",
		"durability": 12,
		"test_override_enabled": true,
		"generic_airflow_role": "airflow_path_cell",
		"cooling_contour_mode": "manual",
		"cooling_contour_id": "manual_route",
		"cooling_contour_member_ids": ["legacy_duct"],
		"wall_side_1": "NW",
		"wall_side_2": "SE",
		"wall_side": "SW"
	}
	var normalized: Dictionary = WorldObjectCatalogRef.normalize_world_object_contract(legacy)
	_assert(str(normalized.get("object_type", "")) == PassiveRouteServiceRef.KIND_AIR_DUCT, "catalog did not canonicalize air duct subtype")
	_assert(str(normalized.get("mount_side", "")) == "SW", "catalog lost mount side")
	_assert(str(normalized.get("route_side_1", "")) == "NW" and str(normalized.get("route_side_2", "")) == "SE", "catalog lost route pair")
	for field_name in ["state", "durability", "test_override_enabled", "generic_airflow_role", "cooling_contour_mode", "cooling_contour_id", "cooling_contour_member_ids", "wall_side_1", "wall_side_2"]:
		_assert(not normalized.has(field_name), "catalog retained forbidden field: %s" % field_name)

	var definition: Dictionary = WorldObjectCatalogRef.get_archetype_definition("external_air_duct")
	var entity_contract: Dictionary = Dictionary(definition.get("entity_contract", {}))
	var capabilities: Dictionary = Dictionary(entity_contract.get("capabilities", {}))
	_assert(str(entity_contract.get("entity_subtype", "")) == PassiveRouteServiceRef.KIND_AIR_DUCT, "air duct entity subtype is not canonical")
	_assert(not bool(capabilities.get("state", true)), "passive route exposes state capability")
	_assert(not bool(capabilities.get("power", true)), "passive route exposes power capability")
	_assert(not bool(capabilities.get("health", true)), "passive route exposes health capability")
	_assert(not bool(capabilities.get("test_override", true)), "passive route exposes test override")
	var schema_fields: Array[String] = []
	for field in WorldObjectCatalogRef.get_archetype_property_schema("external_air_duct"):
		schema_fields.append(str(field.get("field", "")))
	_assert(schema_fields == ["mount_side", "route_side_1", "route_side_2"], "passive route authoring schema contains extra fields")

	var west: Dictionary = _segment("west", "air_duct", Vector2i(0, 0), "NW", "SE")
	var east: Dictionary = _segment("east", "air_duct", Vector2i(1, 0), "NW", "SE")
	var fake_world = FakeRouteWorld.new()
	root.add_child(fake_world)
	var connected_routes: Array[Dictionary] = [west, east]
	fake_world.mission_world_objects = connected_routes
	var world_before: String = var_to_str(fake_world.mission_world_objects)
	var west_issues: Array[Dictionary] = WallRoutingValidationServiceRef.collect_issue_rows(west, Vector2i(0, 0), fake_world)
	_assert(var_to_str(fake_world.mission_world_objects) == world_before, "constructor validation mutated world routes")
	_assert(not _codes(west_issues).has(PassiveRouteServiceRef.CODE_NEIGHBOR_PORT_MISMATCH), "matching neighbor ports were rejected")

	var disconnected: Dictionary = _segment("disconnected", "water_pipe", Vector2i(5, 5), "NE", "SW")
	var disconnected_routes: Array[Dictionary] = [disconnected]
	fake_world.mission_world_objects = disconnected_routes
	var disconnected_issues: Array[Dictionary] = WallRoutingValidationServiceRef.collect_issue_rows(disconnected, Vector2i(5, 5), fake_world)
	_assert(_codes(disconnected_issues).has(PassiveRouteServiceRef.CODE_DISCONNECTED_PORT), "machine-readable disconnected-port issue missing")

	var objects_by_id: Dictionary = {"west": west, "east": east}
	var contours: Dictionary = CoolingContourFacadeRef.build_contours(objects_by_id)
	var contour_id: String = CoolingContourFacadeRef.get_object_contour_id(west, "west", contours)
	_assert(not contour_id.is_empty(), "computed compatibility contour ID missing")
	var contour_data: Dictionary = Dictionary(Dictionary(contours.get("air_duct", {})).get(contour_id, {}))
	_assert(Array(contour_data.get("members", [])).has("east"), "computed contour omitted connected member")
	_assert(bool(contour_data.get("computed", false)), "compatibility contour is not marked computed")

	var render_before: String = var_to_str(normalized)
	var render_snapshot: Dictionary = PassiveRouteServiceRef.get_render_snapshot(normalized)
	_assert(var_to_str(normalized) == render_before, "render snapshot mutated passive route")
	_assert(Array(render_snapshot.get("route_pair", [])).size() == 2, "render snapshot lacks normalized pair")
	_assert(RouteRendererRef.get_route_family(normalized) == RouteRendererRef.FAMILY_AIR_DUCT, "renderer did not recognize canonical air duct")

	fake_world.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASSIVE_ROUTE_INTEGRATION_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("PASSIVE_ROUTE_INTEGRATION_GATE: FAIL: %s" % failure)
	quit(1)
