extends SceneTree

const Catalog = preload("res://scripts/world/world_object_catalog.gd")
const Resolver = preload("res://scripts/world/power_control_resolver.gd")
const BindingContract = preload("res://scripts/world/world_binding_store_contract.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _entity(prefab_id: String, entity_id: String, cell: Vector2i, overrides: Dictionary = {}) -> Dictionary:
	var value: Dictionary = Catalog.create_world_object(prefab_id, entity_id)
	value["position"] = cell
	for key in overrides.keys():
		value[key] = overrides[key]
	return value

func _power(resolution: Dictionary, entity_id: String) -> Dictionary:
	return Dictionary(Dictionary(resolution.get("power_results", {})).get(entity_id, {}))

func _preference(binding_id: String, consumer_id: String, source_id: String) -> Dictionary:
	return {"id":binding_id, "role":BindingContract.ROLE_PREFERRED_POWER_SOURCE, "source_id":consumer_id, "target_id":source_id, "parameters":{}, "format_version":BindingContract.FORMAT_VERSION}

func _run() -> void:
	await process_frame
	var lonely_light: Dictionary = _entity("light", "lonely_light", Vector2i(9, 9), {"circuit_id":"isolated"})
	var lonely_power: Dictionary = _power(Resolver.resolve_world([lonely_light]), "lonely_light")
	_check(str(lonely_power.get("power_state", "")) == "unpowered", "zero-source network did not stay unpowered")
	_check(str(lonely_power.get("reason_code", "")) == "power.no_reachable_source", "zero-source reason code changed")

	var source_a: Dictionary = _entity("power_source_class_1", "source_a", Vector2i(0, 0), {"circuit_id":"alpha"})
	var cable_a: Dictionary = _entity("power_cable", "cable_a", Vector2i(1, 0), {"circuit_id":"alpha"})
	var light_a: Dictionary = _entity("light", "light_a", Vector2i(2, 0), {"circuit_id":"alpha"})
	var one_power: Dictionary = _power(Resolver.resolve_world([source_a, cable_a, light_a]), "light_a")
	_check(bool(one_power.get("is_powered", false)), "single source did not power light")
	_check(str(one_power.get("resolved_source_id", "")) == "source_a", "single source selection changed")
	_check(str(one_power.get("resolved_circuit_id", "")) == "alpha", "resolved circuit inheritance changed")

	var socket_a: Dictionary = _entity("power_socket", "socket_a", Vector2i(2, 0), {"circuit_id":"alpha"})
	var socket_power: Dictionary = _power(Resolver.resolve_world([source_a, cable_a, socket_a]), "socket_a")
	_check(str(socket_power.get("resolved_source_id", "")) == "source_a" and str(socket_power.get("resolved_circuit_id", "")) == "alpha", "socket did not inherit topology source/circuit")

	var broken_cable: Dictionary = cable_a.duplicate(true)
	broken_cable["health_state"] = "broken"
	broken_cable["operational_state"] = "broken"
	_check(not bool(_power(Resolver.resolve_world([source_a, broken_cable, light_a]), "light_a").get("is_powered", true)), "broken cable still conducts")

	var empty_fuse: Dictionary = _entity("fuse_box_empty", "fuse_empty", Vector2i(1, 0), {"circuit_id":"alpha"})
	_check(not bool(_power(Resolver.resolve_world([source_a, empty_fuse, light_a]), "light_a").get("is_powered", true)), "empty fuse box still conducts")
	var full_fuse: Dictionary = _entity("fuse_box_installed", "fuse_full", Vector2i(1, 0), {"circuit_id":"alpha"})
	_check(bool(_power(Resolver.resolve_world([source_a, full_fuse, light_a]), "light_a").get("is_powered", false)), "installed fuse did not restore topology")

	var off_switch: Dictionary = _entity("power_switcher", "switch_off", Vector2i(1, 0), {"circuit_id":"alpha", "intent_state":"off"})
	_check(not bool(_power(Resolver.resolve_world([source_a, off_switch, light_a]), "light_a").get("is_powered", true)), "off switch still conducts")
	var on_switch: Dictionary = off_switch.duplicate(true)
	on_switch["intent_state"] = "on"
	_check(bool(_power(Resolver.resolve_world([source_a, on_switch, light_a]), "light_a").get("is_powered", false)), "on switch did not restore topology")

	var source_left: Dictionary = _entity("power_source_class_1", "source_left", Vector2i(0, 3), {"circuit_id":"shared"})
	var source_right: Dictionary = _entity("power_source_class_2", "source_right", Vector2i(4, 3), {"circuit_id":"shared"})
	var cable_left: Dictionary = _entity("power_cable", "cable_left", Vector2i(1, 3), {"circuit_id":"shared"})
	var cable_mid: Dictionary = _entity("power_cable", "cable_mid", Vector2i(2, 3), {"circuit_id":"shared"})
	var cable_right: Dictionary = _entity("power_cable", "cable_right", Vector2i(3, 3), {"circuit_id":"shared"})
	var shared_light: Dictionary = _entity("light", "shared_light", Vector2i(2, 4), {"circuit_id":"shared"})
	var objects: Array[Dictionary] = [source_left, source_right, cable_left, cable_mid, cable_right, shared_light]
	_check(str(_power(Resolver.resolve_world(objects), "shared_light").get("power_state", "")) == "ambiguous", "multi-source topology was not ambiguous")
	var preferred: Dictionary = _power(Resolver.resolve_world(objects, [_preference("prefer_left", "shared_light", "source_left")]), "shared_light")
	_check(bool(preferred.get("is_powered", false)) and str(preferred.get("resolved_source_id", "")) == "source_left", "preferred source did not resolve multi-source topology")

	var preserved: Array[Dictionary] = [light_a.duplicate(true)]
	var before: Dictionary = preserved[0].duplicate(true)
	Resolver.apply_world_results(preserved)
	for field_name in ["intent_state", "health_state", "thermal_state", "operational_state"]:
		_check(preserved[0].get(field_name) == before.get(field_name), "recalculation mutated canonical axis: %s" % field_name)

	if failures.is_empty():
		print("STATIONARY_POWER_TOPOLOGY_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("STATIONARY_POWER_TOPOLOGY_GATE: FAIL: %s" % failure)
	quit(1)
