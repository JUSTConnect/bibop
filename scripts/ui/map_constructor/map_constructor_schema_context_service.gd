extends RefCounted
class_name MapConstructorSchemaContextService

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const PassiveRouteServiceRef = preload("res://scripts/game/routing/passive_route_service.gd")

static func definition_for(data: Dictionary) -> Dictionary:
	var definition_id: String = str(data.get("map_constructor_prefab_id", data.get("archetype_id", data.get("object_type", data.get("item_type", ""))))).strip_edges()
	return {} if definition_id.is_empty() else WorldObjectCatalogRef.get_constructor_prefab_definition(definition_id)

static func build(ui: Variant, entity_id: String, data: Dictionary, definition: Dictionary) -> Dictionary:
	var context: Dictionary = {
		"mode":"map_constructor",
		"definition":definition,
		"entities_by_id":{entity_id:data.duplicate(true)},
		"bindings":[],
		"physical_topology":physical_topology(data),
		"issues":[],
		"test_override":test_override(data)
	}
	var manager: Variant = ui.mission_manager_runtime
	if manager == null:
		return context
	var store: Variant = manager.get("world_state_store")
	if store != null:
		var entities: Dictionary = {}
		for value in store.get_all_objects():
			if value is Dictionary:
				var object_data: Dictionary = Dictionary(value)
				var object_id: String = str(object_data.get("id", "")).strip_edges()
				if not object_id.is_empty():
					entities[object_id] = object_data.duplicate(true)
		context["entities_by_id"] = entities
		context["bindings"] = store.get_all_bindings()
	if manager.has_method("get_map_constructor_validation_issues"):
		context["issues"] = manager.call("get_map_constructor_validation_issues")
	return context

static func physical_topology(data: Dictionary) -> Dictionary:
	if PassiveRouteServiceRef.is_passive_route(data):
		return PassiveRouteServiceRef.validate_segment(data)
	var object_type: String = str(data.get("object_type", "")).strip_edges().to_lower()
	if object_type == "power_cable":
		return {"kind":"stationary_power_route", "position":data.get("position"), "mount":data.get("mount", data.get("placement_mode", "floor")), "routing_visibility":data.get("routing_visibility", "external"), "health_state":data.get("health_state", "healthy")}
	if object_type == "power_cable_reel":
		return {"kind":"runtime_reel", "end_1":data.get("end_1", {}), "end_2":data.get("end_2", {}), "path_cells":data.get("path_cells", []), "connection_state":data.get("connection_state", "disconnected")}
	return {}

static func test_override(data: Dictionary) -> Dictionary:
	if not bool(data.get("test_override_enabled", false)):
		return {}
	var forced: Dictionary = {}
	for key in ["forced_intent_state", "forced_operational_state", "forced_health_state", "forced_thermal_state", "forced_power_state"]:
		if data.has(key):
			forced[key] = data[key]
	return {"forced_values":forced}
