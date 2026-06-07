extends RefCounted
class_name ThreatAlertService

# Pure helper functions for threat alert broadcast rules.
# This service does not move enemies, mutate missions, or run combat logic.

const ThreatCatalogRef = preload("res://scripts/game/threats/threat_catalog.gd")
const ThreatDetectionTypesRef = preload("res://scripts/game/threats/threat_detection_types.gd")
const ThreatTypesRef = preload("res://scripts/game/threats/threat_types.gd")

const BUG_ALERT_RADIUS_DEFAULT: int = 5
const BUG_RANGED_ALERT_RADIUS_DEFAULT: int = 7
const VAGUS_ALERT_RADIUS_DEFAULT: int = 20

static func get_alert_radius(threat_id: String, override_definition: Dictionary = {}) -> int:
	var definition: Dictionary = _resolve_definition(threat_id, override_definition)
	if definition.has("alert_radius"):
		return int(definition.get("alert_radius", 0))
	var kind: String = str(definition.get("kind", ""))
	if kind == ThreatTypesRef.KIND_VAGUS:
		return VAGUS_ALERT_RADIUS_DEFAULT
	if kind == ThreatTypesRef.KIND_BUG:
		var model_tier: int = int(definition.get("model_tier", 0))
		return BUG_RANGED_ALERT_RADIUS_DEFAULT if model_tier >= 4 else BUG_ALERT_RADIUS_DEFAULT
	return ThreatDetectionTypesRef.DEFAULT_ALERT_RADIUS

static func can_broadcast_alert(threat_id: String, override_definition: Dictionary = {}) -> bool:
	var definition: Dictionary = _resolve_definition(threat_id, override_definition)
	if ThreatTypesRef.has_capability(definition, ThreatTypesRef.CAPABILITY_NO_ALERT_BROADCAST):
		return false
	if str(definition.get("kind", "")) == ThreatTypesRef.KIND_TURRET:
		return false
	return get_alert_radius(threat_id, definition) > 0

static func can_receive_alert(threat_id: String, override_definition: Dictionary = {}) -> bool:
	var definition: Dictionary = _resolve_definition(threat_id, override_definition)
	if str(definition.get("kind", "")) == ThreatTypesRef.KIND_TURRET:
		return false
	return true

static func is_cell_in_alert_area(source_cell: Vector2i, target_cell: Vector2i, alert_radius: int) -> bool:
	if alert_radius < 0:
		return false
	return source_cell.distance_to(target_cell) <= float(alert_radius)

static func get_alerted_threat_ids(
	source_threat_id: String,
	source_cell: Vector2i,
	candidate_threats: Array[Dictionary],
	override_definition: Dictionary = {}
) -> Array[String]:
	var alerted_ids: Array[String] = []
	if not can_broadcast_alert(source_threat_id, override_definition):
		return alerted_ids
	var alert_radius: int = get_alert_radius(source_threat_id, override_definition)
	for candidate in candidate_threats:
		var candidate_id: String = str(candidate.get("id", candidate.get("threat_id", "")))
		if candidate_id.is_empty():
			continue
		if not can_receive_alert(str(candidate.get("threat_id", candidate_id)), Dictionary(candidate.get("definition", {}))):
			continue
		var candidate_cell: Vector2i = _read_cell(candidate.get("cell", Vector2i(-9999, -9999)))
		if candidate_cell == source_cell:
			continue
		if is_cell_in_alert_area(source_cell, candidate_cell, alert_radius):
			alerted_ids.append(candidate_id)
	return alerted_ids

static func build_alert_event(
	source_threat_id: String,
	source_cell: Vector2i,
	target_cell: Vector2i,
	candidate_threats: Array[Dictionary],
	override_definition: Dictionary = {}
) -> Dictionary:
	var alerted_ids: Array[String] = get_alerted_threat_ids(source_threat_id, source_cell, candidate_threats, override_definition)
	return {
		"mode": ThreatDetectionTypesRef.DETECTION_MODE_ALERT,
		"source_threat_id": source_threat_id,
		"source_cell": source_cell,
		"target_cell": target_cell,
		"alert_radius": get_alert_radius(source_threat_id, override_definition),
		"alerted_threat_ids": alerted_ids,
		"last_known_position": target_cell,
		"can_broadcast": can_broadcast_alert(source_threat_id, override_definition)
	}

static func mark_alert_state(threat_state: Dictionary, last_known_position: Vector2i) -> Dictionary:
	var next_state: Dictionary = threat_state.duplicate(true)
	next_state["detection_state"] = ThreatDetectionTypesRef.DETECTION_STATE_ALERTED
	next_state["last_known_position"] = last_known_position
	return next_state

static func _resolve_definition(threat_id: String, override_definition: Dictionary = {}) -> Dictionary:
	if not override_definition.is_empty():
		return override_definition.duplicate(true)
	return ThreatCatalogRef.get_threat_definition(threat_id)

static func _read_cell(value: Variant) -> Vector2i:
	if value is Vector2i:
		return Vector2i(value)
	if value is Vector2:
		var vector_value: Vector2 = Vector2(value)
		return Vector2i(int(vector_value.x), int(vector_value.y))
	if value is Dictionary:
		var data: Dictionary = Dictionary(value)
		return Vector2i(int(data.get("x", 0)), int(data.get("y", 0)))
	return Vector2i(-9999, -9999)
