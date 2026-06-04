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
const ROLE_POWER_SOURCE: String = "power_source"
const ROLE_SOCKET_INPUT: String = "socket_input"
const ROLE_SOCKET_OUTPUT: String = "socket_output"
const ROLE_CABLE_LINK: String = "cable_link"
const ROLE_CABLE_SEGMENT: String = "cable_segment"
const ROLE_POWER_SINK: String = "power_sink"
const ROLE_POWERED_DEVICE: String = "powered_device"


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
var power_network_id: String = ""
var connection_id: String = ""
var source_object_id: String = ""
var sink_object_id: String = ""
var endpoint_a_id: String = ""
var endpoint_b_id: String = ""
var runtime_is_connected: bool = false
var is_powered: bool = false
var power_state: String = "unpowered"
var power_required: bool = false
var power_received: int = 0


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
	power_network_id = ""
	connection_id = ""
	source_object_id = ""
	sink_object_id = ""
	endpoint_a_id = ""
	endpoint_b_id = ""
	runtime_is_connected = false
	is_powered = false
	power_state = "unpowered"
	power_required = false
	power_received = 0


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
		"power_network_id": power_network_id,
		"connection_id": connection_id,
		"source_object_id": source_object_id,
		"sink_object_id": sink_object_id,
		"endpoint_a_id": endpoint_a_id,
		"endpoint_b_id": endpoint_b_id,
		"is_connected": runtime_is_connected,
		"is_powered": is_powered,
		"power_state": power_state,
		"power_required": power_required,
		"power_received": power_received,
	}


func from_dictionary(data: Dictionary) -> void:
	cable_id = str(data.get("cable_id", ""))
	reel_id = str(data.get("reel_id", ""))
	socket_id = str(data.get("socket_id", ""))
	linked_target_id = str(data.get("linked_target_id", ""))
	power_event_id = str(data.get("power_event_id", ""))
	power_filter = str(data.get("power_filter", ""))
	state = str(data.get("state", STATE_IDLE))
	connected = bool(data.get("connected", false))
	max_length = int(data.get("max_length", 0))
	path_cells = _variant_to_vector2i_array(data.get("path_cells", []))
	reel_position = _variant_to_vector2i(data.get("reel_position", Vector2i.ZERO), Vector2i.ZERO)
	socket_position = _variant_to_vector2i(data.get("socket_position", Vector2i.ZERO), Vector2i.ZERO)
	target_position = _variant_to_vector2i(data.get("target_position", Vector2i.ZERO), Vector2i.ZERO)
	power_network_id = str(data.get("power_network_id", ""))
	connection_id = str(data.get("connection_id", ""))
	source_object_id = str(data.get("source_object_id", ""))
	sink_object_id = str(data.get("sink_object_id", ""))
	endpoint_a_id = str(data.get("endpoint_a_id", ""))
	endpoint_b_id = str(data.get("endpoint_b_id", ""))
	runtime_is_connected = bool(data.get("is_connected", false))
	is_powered = bool(data.get("is_powered", false))
	power_state = str(data.get("power_state", "unpowered"))
	power_required = bool(data.get("power_required", false))
	power_received = int(data.get("power_received", 0))


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
