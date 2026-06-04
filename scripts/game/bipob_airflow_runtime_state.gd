extends RefCounted
class_name BipobAirflowRuntimeState

const ROLE_FAN: String = "fan"
const ROLE_AIRFLOW_SOURCE: String = "airflow_source"
const ROLE_AIRFLOW_PATH_CELL: String = "airflow_path_cell"
const ROLE_AIRFLOW_BLOCKER: String = "airflow_blocker"
const ROLE_COOLING_TARGET: String = "cooling_target"
const ROLE_HEAT_SENSITIVE_TERMINAL: String = "heat_sensitive_terminal"
const ROLE_ROTATING_PLATFORM: String = "rotating_platform"

var airflow_network_id: String = ""
var fan_object_id: String = ""
var fan_enabled: bool = false
var fan_direction: String = "right"
var fan_speed: int = 0
var airflow_range: int = 0
var airflow_cells: Array[Vector2i] = []
var blocked_cells: Array[Vector2i] = []
var cooled_target_ids: Array[String] = []
var is_cooled: bool = false
var cooling_required: bool = false
var cooling_received: int = 0
var cooling_state: String = "uncooled"


func reset() -> void:
	airflow_network_id = ""
	fan_object_id = ""
	fan_enabled = false
	fan_direction = "right"
	fan_speed = 0
	airflow_range = 0
	airflow_cells.clear()
	blocked_cells.clear()
	cooled_target_ids.clear()
	is_cooled = false
	cooling_required = false
	cooling_received = 0
	cooling_state = "uncooled"


func to_dictionary() -> Dictionary:
	return {
		"airflow_network_id": airflow_network_id,
		"fan_object_id": fan_object_id,
		"fan_enabled": fan_enabled,
		"fan_direction": fan_direction,
		"fan_speed": fan_speed,
		"airflow_range": airflow_range,
		"airflow_cells": airflow_cells.duplicate(),
		"blocked_cells": blocked_cells.duplicate(),
		"cooled_target_ids": cooled_target_ids.duplicate(),
		"is_cooled": is_cooled,
		"cooling_required": cooling_required,
		"cooling_received": cooling_received,
		"cooling_state": cooling_state,
	}


func from_dictionary(data: Dictionary) -> void:
	airflow_network_id = str(data.get("airflow_network_id", ""))
	fan_object_id = str(data.get("fan_object_id", ""))
	fan_enabled = bool(data.get("fan_enabled", false))
	fan_direction = str(data.get("fan_direction", "right"))
	fan_speed = int(data.get("fan_speed", 0))
	airflow_range = int(data.get("airflow_range", 0))
	airflow_cells = _variant_to_vector2i_array(data.get("airflow_cells", []))
	blocked_cells = _variant_to_vector2i_array(data.get("blocked_cells", []))
	cooled_target_ids = _variant_to_string_array(data.get("cooled_target_ids", []))
	is_cooled = bool(data.get("is_cooled", false))
	cooling_required = bool(data.get("cooling_required", false))
	cooling_received = int(data.get("cooling_received", 0))
	cooling_state = str(data.get("cooling_state", "uncooled"))


static func _variant_to_vector2i_array(value: Variant) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if value is Array:
		for item in Array(value):
			result.append(_variant_to_vector2i(item))
	return result


static func _variant_to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in Array(value):
			result.append(str(item))
	return result


static func _variant_to_vector2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(value)
	if value is Array and Array(value).size() >= 2:
		var array_value: Array = Array(value)
		return Vector2i(int(array_value[0]), int(array_value[1]))
	if value is Dictionary:
		var dictionary_value: Dictionary = Dictionary(value)
		return Vector2i(int(dictionary_value.get("x", 0)), int(dictionary_value.get("y", 0)))
	return Vector2i.ZERO
