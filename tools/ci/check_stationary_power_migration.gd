extends SceneTree

const Catalog = preload("res://scripts/world/world_object_catalog.gd")
const CanonicalCatalog = preload("res://scripts/world/stationary_power_entity_catalog.gd")
const Resolver = preload("res://scripts/world/power_control_resolver.gd")
const BindingContract = preload("res://scripts/world/world_binding_store_contract.gd")
const ActionService = preload("res://scripts/game/power/stationary_power_action_service.gd")

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
	return {
		"id":binding_id,
		"role":BindingContract.ROLE_PREFERRED_POWER_SOURCE,
		"source_id":consumer_id,
		"target_id":source_id,
		"parameters":{},
		"format_version":BindingContract.FORMAT_VERSION
	}

func _definition_has_any(definition: Dictionary, fields: Array[String]) -> bool:
	for field_name in fields:
		if definition.has(field_name):
			return true
	return false

func _run() -> void:
	await process_frame

	for family_id in CanonicalCatalog.FAMILY_IDS:
		var definition: Dictionary = Catalog.get_constructor_prefab_definition(family_id)
		var report: Dictionary = Catalog.validate_entity_definition_contract(family_id)
		_check(not definition.is_empty(), "canonical definition missing: %s" % family_id)
		_check(bool(report.get("valid", false)), "canonical definition invalid: %s %s" % [family_id, str(report.get("errors", []))])
		_check(not definition.has("legacy_semantic_exceptions"), "#1181 semantic exception remains: %s" % family_id)
		_check(not _definition_has_any(definition, CanonicalCatalog.COMPUTED_POWER_FIELDS), "computed power truth stored in definition: %s" % family_id)

	var cable_definition: Dictionary = Catalog.get_constructor_prefab_definition("power_cable")
	var cable_contract: Dictionary = Dictionary(cable_definition.get("entity_contract", {}))
	_check(not bool(Dictionary(cable_contract.get("capabilities", {})).get("bindings", true)), "stationary cable still uses BindingStore")
	_check(not _definition_has_any(cable_definition, ["durability", "current_health", "max_health", "wall_side", "wall_side_1", "wall_side_2", "power_source_id", "physical_connection_source_id"]), "stationary cable keeps numeric health/manual side/source truth")
	_check(str(cable_definition.get("health_state", "")) == "healthy", "stationary cable lacks discrete health state")

	for alias_id in ["power_source_class_1", "power_source_class_2", "power_source_class_3", "circuit_breaker", "circuit_switch", "light_switch", "fuse_box_installed", "fuse_box_empty", "outlet", "legacy_light_library"]:
		var canonical_id: String = CanonicalCatalog.canonical_id(alias_id)
		_check(Catalog.get_entity_definition_contract(alias_id) == Catalog.get_entity_definition_contract(canonical_id), "alias contract differs from canonical definition: %s" % alias_id)
		_check(not Catalog.create_world_object(alias_id, "alias_%s" % alias_id).is_empty(), "legacy alias no longer loads: %s" % alias_id)

	for source_class in [1, 2, 3]:
		var source_alias: String = "power_source_class_%d" % source_class
		var source_record: Dictionary = Catalog.create_world_object(source_alias, "source_class_%d" % source_class)
		_check(str(source_record.get("object_type", "")) == "power_source", "source class did not normalize to canonical power_source")
		_check(int(source_record.get("power_source_class", 0)) == source_class, "source class value lost for %s" % source_alias)
		_check(not _definition_has_any(source_record, CanonicalCatalog.COMPUTED_POWER_FIELDS), "new source record persists computed power truth")

	var new_cable: Dictionary = Catalog.create_world_object("power_cable", "new_cable")
	var new_socket: Dictionary = Catalog.create_world_object("power_socket", "new_socket")
	var new_fuse: Dictionary = Catalog.create_world_object("fuse_box", "new_fuse")
	var new_switch: Dictionary = Catalog.create_world_object("power_switcher", "new_switch")
	var new_light: Dictionary = Catalog.create_world_object("light", "new_light")
	for record in [new_cable, new_socket, new_fuse, new_switch, new_light]:
		_check(not _definition_has_any(record, CanonicalCatalog.COMPUTED_POWER_FIELDS), "new authoring record persists computed power fields: %s" % str(record.get("id", "")))
	_check(not _definition_has_any(new_light, ["state", "status", "is_on", "light_enabled"]), "new light record keeps state/on double truth")
	_check(str(new_light.get("intent_state", "")) == "on" and str(new_light.get("health_state", "")) == "healthy" and str(new_light.get("thermal_state", "")) == "normal", "new light axes are not separated")
	_check(not _definition_has_any(new_switch, ["state", "switch_state", "is_on"]), "new switch record keeps legacy switch truth")
	_check(not _definition_has_any(new_fuse, ["state", "fuse_present", "fuse_installed"]), "new fuse record keeps legacy fuse truth")

	var lonely_light: Dictionary = _entity("light", "lonely_light", Vector2i(9, 9), {"circuit_id":"isolated"})
	var lonely_power: Dictionary = _power(Resolver.resolve_world([lonely_light]), "lonely_light")
	_check(str(lonely_power.get("power_state", "")) == "unpowered", "zero-source network did not stay unpowered")
	_check(str(lonely_power.get("reason_code", "")) == "power.no_reachable_source", "zero-source reason code changed")

	var source_a: Dictionary = _entity("power_source_class_1", "source_a", Vector2i(0, 0), {"circuit_id":"alpha"})
	var cable_a: Dictionary = _entity("power_cable", "cable_a", Vector2i(1, 0), {"circuit_id":"alpha"})
	var light_a: Dictionary = _entity("light", "light_a", Vector2i(2, 0), {"circuit_id":"alpha"})
	var one_resolution: Dictionary = Resolver.resolve_world([source_a, cable_a, light_a])
	var one_power: Dictionary = _power(one_resolution, "light_a")
	_check(bool(one_power.get("is_powered", false)), "single reachable source did not power light")
	_check(str(one_power.get("resolved_source_id", "")) == "source_a", "single source was not selected deterministically")
	_check(str(one_power.get("resolved_circuit_id", "")) == "alpha", "resolved circuit was not inherited")

	var socket_a: Dictionary = _entity("power_socket", "socket_a", Vector2i(2, 0), {"circuit_id":"alpha"})
	var socket_power: Dictionary = _power(Resolver.resolve_world([source_a, cable_a, socket_a]), "socket_a")
	_check(str(socket_power.get("resolved_source_id", "")) == "source_a" and str(socket_power.get("resolved_circuit_id", "")) == "alpha", "socket did not inherit topology source/circuit")

	var broken_cable: Dictionary = cable_a.duplicate(true)
	broken_cable["health_state"] = "broken"
	broken_cable["operational_state"] = "broken"
	var broken_power: Dictionary = _power(Resolver.resolve_world([source_a, broken_cable, light_a]), "light_a")
	_check(not bool(broken_power.get("is_powered", true)), "broken cable still conducts power")

	var empty_fuse: Dictionary = _entity("fuse_box_empty", "fuse_empty", Vector2i(1, 0), {"circuit_id":"alpha"})
	var empty_fuse_power: Dictionary = _power(Resolver.resolve_world([source_a, empty_fuse, light_a]), "light_a")
	_check(not bool(empty_fuse_power.get("is_powered", true)), "empty fuse box still conducts power")
	var full_fuse: Dictionary = _entity("fuse_box_installed", "fuse_full", Vector2i(1, 0), {"circuit_id":"alpha"})
	var full_fuse_power: Dictionary = _power(Resolver.resolve_world([source_a, full_fuse, light_a]), "light_a")
	_check(bool(full_fuse_power.get("is_powered", false)), "installed fuse did not restore topology")

	var off_switch: Dictionary = _entity("power_switcher", "switch_off", Vector2i(1, 0), {"circuit_id":"alpha", "intent_state":"off"})
	var off_switch_power: Dictionary = _power(Resolver.resolve_world([source_a, off_switch, light_a]), "light_a")
	_check(not bool(off_switch_power.get("is_powered", true)), "off switch still conducts power")
	var on_switch: Dictionary = off_switch.duplicate(true)
	on_switch["intent_state"] = "on"
	var on_switch_power: Dictionary = _power(Resolver.resolve_world([source_a, on_switch, light_a]), "light_a")
	_check(bool(on_switch_power.get("is_powered", false)), "on switch did not restore topology")

	var source_left: Dictionary = _entity("power_source_class_1", "source_left", Vector2i(0, 3), {"circuit_id":"shared"})
	var source_right: Dictionary = _entity("power_source_class_2", "source_right", Vector2i(4, 3), {"circuit_id":"shared"})
	var cable_left: Dictionary = _entity("power_cable", "cable_left", Vector2i(1, 3), {"circuit_id":"shared"})
	var cable_mid: Dictionary = _entity("power_cable", "cable_mid", Vector2i(2, 3), {"circuit_id":"shared"})
	var cable_right: Dictionary = _entity("power_cable", "cable_right", Vector2i(3, 3), {"circuit_id":"shared"})
	var shared_light: Dictionary = _entity("light", "shared_light", Vector2i(2, 4), {"circuit_id":"shared"})
	var shared_objects: Array[Dictionary] = [source_left, source_right, cable_left, cable_mid, cable_right, shared_light]
	var ambiguous: Dictionary = _power(Resolver.resolve_world(shared_objects), "shared_light")
	_check(str(ambiguous.get("power_state", "")) == "ambiguous", "multi-source topology was not marked ambiguous")
	var preferred: Dictionary = _power(Resolver.resolve_world(shared_objects, [_preference("prefer_left", "shared_light", "source_left")]), "shared_light")
	_check(bool(preferred.get("is_powered", false)) and str(preferred.get("resolved_source_id", "")) == "source_left", "preferred source did not resolve multi-source topology")

	var preserved_objects: Array[Dictionary] = [light_a.duplicate(true)]
	var before_axes: Dictionary = preserved_objects[0].duplicate(true)
	Resolver.apply_world_results(preserved_objects)
	for field_name in ["intent_state", "health_state", "thermal_state", "operational_state"]:
		_check(preserved_objects[0].get(field_name) == before_axes.get(field_name), "power recalculation mutated canonical axis %s" % field_name)

	var legacy_record: Dictionary = {"id":"legacy_cable", "object_type":"power_cable", "state":"broken", "broken":true, "durability":0, "power_state":"unpowered", "power_source_id":"old_source", "wall_side":"north"}
	var legacy_before: Dictionary = legacy_record.duplicate(true)
	var adapted: Dictionary = Catalog.adapt_legacy_stationary_power_record(legacy_record)
	_check(legacy_record == legacy_before, "legacy adapter mutated source record")
	_check(str(adapted.get("health_state", "")) == "broken", "legacy cable health was not adapted")
	_check(not _definition_has_any(adapted, CanonicalCatalog.COMPUTED_POWER_FIELDS), "legacy adapter emitted persisted computed power truth")
	_check(not _definition_has_any(adapted, ["durability", "wall_side", "power_source_id"]), "legacy adapter emitted forbidden authoring fields")

	var damaged_cable: Dictionary = _entity("power_cable", "damaged_cable", Vector2i.ZERO, {"health_state":"broken", "operational_state":"broken"})
	var repaired: Dictionary = ActionService.apply_cable_repair(damaged_cable, "repair_action", "bipob_a")
	_check(str(Dictionary(repaired.get("entity", {})).get("health_state", "")) == "healthy", "repair action did not restore cable health")
	_check(str(Dictionary(repaired.get("entity", {})).get("operational_state", "")) == "disconnected", "repair action incorrectly reconnected cable")
	var reconnected: Dictionary = ActionService.apply_cable_reconnect(Dictionary(repaired.get("entity", {})), "reconnect_action", "bipob_a")
	_check(str(Dictionary(reconnected.get("entity", {})).get("operational_state", "")) == "connected", "reconnect action did not restore connection")
	_check(str(Dictionary(repaired.get("action_result", {})).get("action_type", "")) != str(Dictionary(reconnected.get("action_result", {})).get("action_type", "")), "repair and reconnect collapsed into one action")

	var light_action: Dictionary = ActionService.apply_light_player_action(_entity("light", "action_light", Vector2i.ZERO, {"intent_state":"off"}), true, "light_action_1", "bipob_a")
	var notification: Dictionary = Dictionary(light_action.get("notification_event", {}))
	_check(str(Dictionary(light_action.get("action_result", {})).get("action_id", "")) == "light_action_1", "light player action lost structured action result")
	_check(str(notification.get("event_id", "")) == "light_action_1" and bool(notification.get("player_action", false)), "light player action did not emit exactly one correlated notification")
	var autonomous: Dictionary = ActionService.apply_autonomous_power_result(_entity("light", "auto_light", Vector2i.ZERO), {"power_state":"unpowered", "is_powered":false})
	_check(Dictionary(autonomous.get("notification_event", {})).is_empty() and Dictionary(autonomous.get("action_result", {})).is_empty(), "autonomous power change emitted player notification")

	if failures.is_empty():
		print("STATIONARY_POWER_MIGRATION_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("STATIONARY_POWER_MIGRATION_GATE: FAIL: %s" % failure)
	quit(1)
