extends RefCounted
class_name BipobCableRuntimeState

const STATE_IDLE: String = "idle"
const STATE_DRAGGING: String = "dragging"
const STATE_CONNECTED: String = "connected"
const STATE_RELEASED: String = "released"

const ROLE_CABLE_REEL: String = "cable_reel"
const ROLE_CABLE_ENDPOINT: String = "cable_endpoint"
const ROLE_CABLE_SOCKET: String = "cable_socket"
const ROLE_POWERED_TARGET: String = "powered_target"

const LEGACY_MISSION7_CABLE_ID: String = "cable_a"

var cable_id: String = ""
var reel_id: String = ""
var socket_id: String = ""
var linked_target_id: String = ""
var power_event_id: String = ""
var power_filter: String = ""
var state: String = STATE_IDLE
var connected: bool = false
var max_length: int = 0
var path_cells: Array[Vector2i] = []
var reel_position: Vector2i = Vector2i.ZERO
var socket_position: Vector2i = Vector2i.ZERO
var target_position: Vector2i = Vector2i.ZERO


func reset() -> void:
	cable_id = ""
	reel_id = ""
	socket_id = ""
	linked_target_id = ""
	power_event_id = ""
	power_filter = ""
	state = STATE_IDLE
	connected = false
	max_length = 0
	path_cells.clear()
	reel_position = Vector2i.ZERO
	socket_position = Vector2i.ZERO
	target_position = Vector2i.ZERO


func is_dragging() -> bool:
	return state == STATE_DRAGGING


func is_connected() -> bool:
	return connected or state == STATE_CONNECTED


func has_cable() -> bool:
	return not cable_id.is_empty()


func can_extend_path() -> bool:
	return max_length <= 0 or path_cells.size() < max_length


func add_path_cell(cell: Vector2i) -> void:
	if not can_extend_path():
		return
	path_cells.append(cell)


func clear_path() -> void:
	path_cells.clear()


func get_path_length() -> int:
	return path_cells.size()


func to_dictionary() -> Dictionary:
	return {
		"cable_id": cable_id,
		"reel_id": reel_id,
		"socket_id": socket_id,
		"linked_target_id": linked_target_id,
		"power_event_id": power_event_id,
		"power_filter": power_filter,
		"state": state,
		"connected": connected,
		"max_length": max_length,
		"path_cells": path_cells.duplicate(),
		"reel_position": reel_position,
		"socket_position": socket_position,
		"target_position": target_position,
	}


func from_dictionary(data: Dictionary) -> void:
	cable_id = String(data.get("cable_id", ""))
	reel_id = String(data.get("reel_id", ""))
	socket_id = String(data.get("socket_id", ""))
	linked_target_id = String(data.get("linked_target_id", ""))
	power_event_id = String(data.get("power_event_id", ""))
	power_filter = String(data.get("power_filter", ""))
	state = String(data.get("state", STATE_IDLE))
	connected = bool(data.get("connected", false))
	max_length = int(data.get("max_length", 0))
	path_cells = _variant_to_vector2i_array(data.get("path_cells", []))
	reel_position = _variant_to_vector2i(data.get("reel_position", Vector2i.ZERO), Vector2i.ZERO)
	socket_position = _variant_to_vector2i(data.get("socket_position", Vector2i.ZERO), Vector2i.ZERO)
	target_position = _variant_to_vector2i(data.get("target_position", Vector2i.ZERO), Vector2i.ZERO)


static func from_legacy_mission7(controller: Variant) -> BipobCableRuntimeState:
	var result: BipobCableRuntimeState = BipobCableRuntimeState.new()
	result.cable_id = LEGACY_MISSION7_CABLE_ID
	result.reel_position = _variant_to_vector2i(_read_variant_field(controller, "mission7_cable_reel_position", Vector2i.ZERO), Vector2i.ZERO)
	result.socket_position = _variant_to_vector2i(_read_variant_field(controller, "mission7_socket_position", Vector2i.ZERO), Vector2i.ZERO)
	result.target_position = _variant_to_vector2i(_read_variant_field(controller, "mission7_powered_gate_position", Vector2i.ZERO), Vector2i.ZERO)
	result.connected = bool(_read_variant_field(controller, "mission7_cable_connected", false))
	result.max_length = int(_read_variant_field(controller, "mission7_cable_max_length", 0))
	result.path_cells = _variant_to_vector2i_array(_read_variant_field(controller, "mission7_cable_path", []))
	var is_dragging: bool = bool(_read_variant_field(controller, "mission7_is_dragging_cable", false))
	if result.connected:
		result.state = STATE_CONNECTED
	elif is_dragging:
		result.state = STATE_DRAGGING
	else:
		result.state = STATE_IDLE
	return result


static func _read_variant_field(source: Variant, field_name: String, fallback: Variant) -> Variant:
	if source == null:
		return fallback
	if source is Dictionary:
		var source_dictionary: Dictionary = Dictionary(source)
		return source_dictionary.get(field_name, fallback)
	if source is Object:
		var source_object: Object = source as Object
		if source_object == null:
			return fallback
		var property_value: Variant = source_object.get(field_name)
		if property_value == null:
			return fallback
		return property_value
	return fallback


static func _variant_to_vector2i(value: Variant, fallback: Vector2i) -> Vector2i:
	if value is Vector2i:
		return Vector2i(value)
	if value is Vector2:
		return Vector2i(value)
	if value is Array:
		var value_array: Array = Array(value)
		if value_array.size() >= 2:
			return Vector2i(int(value_array[0]), int(value_array[1]))
	if value is Dictionary:
		var value_dictionary: Dictionary = Dictionary(value)
		return Vector2i(int(value_dictionary.get("x", fallback.x)), int(value_dictionary.get("y", fallback.y)))
	return fallback


static func _variant_to_vector2i_array(value: Variant) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not (value is Array):
		return result
	var source_array: Array = Array(value)
	for cell_variant in source_array:
		var cell: Vector2i = _variant_to_vector2i(cell_variant, Vector2i.ZERO)
		result.append(cell)
	return result
