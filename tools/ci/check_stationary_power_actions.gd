extends SceneTree

const Catalog = preload("res://scripts/world/world_object_catalog.gd")
const ActionService = preload("res://scripts/game/power/stationary_power_action_service.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _entity(prefab_id: String, entity_id: String, overrides: Dictionary = {}) -> Dictionary:
	var value: Dictionary = Catalog.create_world_object(prefab_id, entity_id)
	for key in overrides.keys():
		value[key] = overrides[key]
	return value

func _run() -> void:
	await process_frame
	var damaged_cable: Dictionary = _entity("power_cable", "damaged_cable", {"health_state":"broken", "operational_state":"broken"})
	var repaired: Dictionary = ActionService.apply_cable_repair(damaged_cable, "repair_action", "bipob_a")
	_check(str(Dictionary(repaired.get("entity", {})).get("health_state", "")) == "healthy", "repair did not restore health")
	_check(str(Dictionary(repaired.get("entity", {})).get("operational_state", "")) == "disconnected", "repair incorrectly reconnected cable")
	var reconnected: Dictionary = ActionService.apply_cable_reconnect(Dictionary(repaired.get("entity", {})), "reconnect_action", "bipob_a")
	_check(str(Dictionary(reconnected.get("entity", {})).get("operational_state", "")) == "connected", "reconnect did not restore connection")
	_check(str(Dictionary(repaired.get("action_result", {})).get("action_type", "")) != str(Dictionary(reconnected.get("action_result", {})).get("action_type", "")), "repair and reconnect collapsed into one action")
	var blocked_reconnect: Dictionary = ActionService.apply_cable_reconnect(damaged_cable, "blocked_reconnect", "bipob_a")
	_check(str(Dictionary(blocked_reconnect.get("action_result", {})).get("result", "")) == "blocked", "broken cable reconnect was not blocked")

	var light: Dictionary = _entity("light", "action_light", {"intent_state":"off"})
	var light_before: Dictionary = light.duplicate(true)
	var light_action: Dictionary = ActionService.apply_light_player_action(light, true, "light_action_1", "bipob_a")
	var action_result: Dictionary = Dictionary(light_action.get("action_result", {}))
	var notification: Dictionary = Dictionary(light_action.get("notification_event", {}))
	_check(light == light_before, "light action mutated input")
	_check(str(Dictionary(light_action.get("entity", {})).get("intent_state", "")) == "on", "light action did not update intent")
	_check(str(action_result.get("action_id", "")) == "light_action_1", "light action lost correlation id")
	_check(str(action_result.get("result", "")) == "success", "light action result is not success")
	_check(str(notification.get("event_id", "")) == "light_action_1" and bool(notification.get("player_action", false)), "light action did not emit one correlated player notification")

	var autonomous: Dictionary = ActionService.apply_autonomous_power_result(_entity("light", "auto_light"), {"power_state":"unpowered", "is_powered":false, "resolved_source_id":""})
	_check(Dictionary(autonomous.get("notification_event", {})).is_empty(), "autonomous power change emitted player notification")
	_check(Dictionary(autonomous.get("action_result", {})).is_empty(), "autonomous power change emitted player action result")
	_check(str(Dictionary(autonomous.get("entity", {})).get("power_state", "")) == "unpowered", "autonomous power result was not applied")

	if failures.is_empty():
		print("STATIONARY_POWER_ACTIONS_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("STATIONARY_POWER_ACTIONS_GATE: FAIL: %s" % failure)
	quit(1)
