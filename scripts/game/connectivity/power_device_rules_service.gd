extends RefCounted
class_name PowerDeviceRulesService

# Power/device rule helpers for physical cable and powered device logic.
# Foundation only: no renderer drawing, no scene mutation, no HUD, no MissionManager integration.

const DEVICE_POWER_SOURCE: String = "power_source"
const DEVICE_POWER_SOCKET: String = "power_socket"
const DEVICE_FUSE_BOX: String = "fuse_box"
const DEVICE_POWER_SWITCHER: String = "power_switcher"
const DEVICE_CHAIN_SWITCHER: String = "chain_switcher"
const DEVICE_LIGHT_SWITCH: String = "light_switch"
const DEVICE_LIGHT: String = "light"
const DEVICE_POWERED_OBJECT: String = "powered_object"

const POWER_STATE_ON: String = "on"
const POWER_STATE_OFF: String = "off"
const POWER_STATE_DISCONNECTED: String = "disconnected"
const POWER_STATE_UNKNOWN: String = "unknown"

const CIRCUIT_STATE_CLOSED: String = "closed"
const CIRCUIT_STATE_OPEN: String = "open"
const CIRCUIT_STATE_BROKEN: String = "broken"

const CABLE_STATE_INTACT: String = "intact"
const CABLE_STATE_CUT: String = "cut"
const CABLE_STATE_REPAIRED: String = "repaired"

const MAX_CHAIN_SWITCHER_OUTPUTS: int = 3

static func normalize_device_kind(kind: String) -> String:
	var normalized: String = str(kind).strip_edges().to_lower()
	if normalized in [
		DEVICE_POWER_SOURCE,
		DEVICE_POWER_SOCKET,
		DEVICE_FUSE_BOX,
		DEVICE_POWER_SWITCHER,
		DEVICE_CHAIN_SWITCHER,
		DEVICE_LIGHT_SWITCH,
		DEVICE_LIGHT,
		DEVICE_POWERED_OBJECT
	]:
		return normalized
	return DEVICE_POWERED_OBJECT

static func is_cable_intact(cable_entry: Dictionary) -> bool:
	var state: String = str(cable_entry.get("state", CABLE_STATE_INTACT)).strip_edges().to_lower()
	return state == CABLE_STATE_INTACT or state == CABLE_STATE_REPAIRED

static func can_cable_connect(device_a: Dictionary, device_b: Dictionary) -> bool:
	return _has_cable_port(device_a) and _has_cable_port(device_b)

static func get_cable_endpoint_payload(device_a: Dictionary, device_b: Dictionary, cable_cells: Array[Vector2i]) -> Dictionary:
	return {
		"from_id": str(device_a.get("id", device_a.get("object_id", ""))),
		"to_id": str(device_b.get("id", device_b.get("object_id", ""))),
		"from_kind": normalize_device_kind(str(device_a.get("device_kind", device_a.get("kind", "")))),
		"to_kind": normalize_device_kind(str(device_b.get("device_kind", device_b.get("kind", "")))),
		"cells": cable_cells.duplicate(),
		"is_physical": true,
		"can_be_cut": true,
		"can_be_repaired": true
	}

static func evaluate_fuse_box(device: Dictionary) -> Dictionary:
	var has_fuse: bool = bool(device.get("has_fuse", device.get("fuse_inserted", false)))
	var circuit_state: String = CIRCUIT_STATE_CLOSED if has_fuse else CIRCUIT_STATE_OPEN
	return {
		"device_kind": DEVICE_FUSE_BOX,
		"has_fuse": has_fuse,
		"circuit_state": circuit_state,
		"allows_power": has_fuse,
		"message": "Fuse inserted: circuit closed." if has_fuse else "Fuse missing: circuit open."
	}

static func evaluate_power_switcher(device: Dictionary) -> Dictionary:
	var is_on: bool = bool(device.get("is_on", device.get("enabled", false)))
	return {
		"device_kind": DEVICE_POWER_SWITCHER,
		"is_on": is_on,
		"circuit_state": CIRCUIT_STATE_CLOSED if is_on else CIRCUIT_STATE_OPEN,
		"allows_power": is_on,
		"message": "Power switcher is on." if is_on else "Power switcher is off."
	}

static func evaluate_chain_switcher(device: Dictionary) -> Dictionary:
	var selected_output: int = clampi(int(device.get("selected_output", 0)), 0, MAX_CHAIN_SWITCHER_OUTPUTS - 1)
	var output_count: int = clampi(int(device.get("output_count", MAX_CHAIN_SWITCHER_OUTPUTS)), 0, MAX_CHAIN_SWITCHER_OUTPUTS)
	var is_on: bool = bool(device.get("is_on", true))
	return {
		"device_kind": DEVICE_CHAIN_SWITCHER,
		"is_on": is_on,
		"selected_output": selected_output,
		"output_count": output_count,
		"allows_power": is_on and output_count > 0,
		"active_output": selected_output if is_on and output_count > 0 else -1,
		"message": "Chain switcher output %s active." % selected_output if is_on and output_count > 0 else "Chain switcher is off."
	}

static func evaluate_light_switch(device: Dictionary) -> Dictionary:
	var is_on: bool = bool(device.get("is_on", device.get("enabled", false)))
	var linked_light_ids: Array[String] = _normalize_string_array(device.get("linked_light_ids", []))
	return {
		"device_kind": DEVICE_LIGHT_SWITCH,
		"is_on": is_on,
		"allows_power": true,
		"requires_direct_cable": false,
		"linked_light_ids": linked_light_ids,
		"message": "Light switch is on." if is_on else "Light switch is off."
	}

static func evaluate_socket(device: Dictionary) -> Dictionary:
	return {
		"device_kind": DEVICE_POWER_SOCKET,
		"allows_power": true,
		"is_endpoint": true,
		"requires_cable_reel": true,
		"message": "Socket can bridge power to a connected object through cable."
	}

static func evaluate_device_gate(device: Dictionary) -> Dictionary:
	var kind: String = normalize_device_kind(str(device.get("device_kind", device.get("kind", ""))))
	match kind:
		DEVICE_FUSE_BOX:
			return evaluate_fuse_box(device)
		DEVICE_POWER_SWITCHER:
			return evaluate_power_switcher(device)
		DEVICE_CHAIN_SWITCHER:
			return evaluate_chain_switcher(device)
		DEVICE_LIGHT_SWITCH:
			return evaluate_light_switch(device)
		DEVICE_POWER_SOCKET:
			return evaluate_socket(device)
		DEVICE_POWER_SOURCE:
			return {"device_kind": DEVICE_POWER_SOURCE, "allows_power": true, "is_source": true, "message": "Power source active."}
		_:
			return {"device_kind": kind, "allows_power": bool(device.get("allows_power", true)), "message": "Generic powered device."}

static func evaluate_physical_power_path(devices_in_path: Array[Dictionary], cables_in_path: Array[Dictionary]) -> Dictionary:
	for cable in cables_in_path:
		if not is_cable_intact(cable):
			return {"ok": false, "power_state": POWER_STATE_DISCONNECTED, "message": "Cable path is cut or broken.", "blocked_by": str(cable.get("id", "cable"))}
	for device in devices_in_path:
		var gate: Dictionary = evaluate_device_gate(device)
		if not bool(gate.get("allows_power", false)):
			return {"ok": false, "power_state": POWER_STATE_OFF, "message": str(gate.get("message", "Circuit is open.")), "blocked_by": str(device.get("id", device.get("object_id", "device")))}
	return {"ok": true, "power_state": POWER_STATE_ON, "message": "Physical power path is closed."}

static func toggle_power_switcher(device: Dictionary) -> Dictionary:
	var next_device: Dictionary = device.duplicate(true)
	next_device["is_on"] = not bool(device.get("is_on", device.get("enabled", false)))
	return {"ok": true, "device": next_device, "evaluation": evaluate_power_switcher(next_device)}

static func insert_fuse(device: Dictionary, fuse_item_id: String) -> Dictionary:
	var next_device: Dictionary = device.duplicate(true)
	next_device["has_fuse"] = true
	next_device["fuse_item_id"] = str(fuse_item_id)
	return {"ok": true, "device": next_device, "evaluation": evaluate_fuse_box(next_device)}

static func remove_fuse(device: Dictionary) -> Dictionary:
	var next_device: Dictionary = device.duplicate(true)
	var removed_fuse_id: String = str(next_device.get("fuse_item_id", ""))
	next_device["has_fuse"] = false
	next_device.erase("fuse_item_id")
	return {"ok": true, "device": next_device, "removed_fuse_id": removed_fuse_id, "evaluation": evaluate_fuse_box(next_device)}

static func switch_chain_output(device: Dictionary, output_index: int) -> Dictionary:
	var next_device: Dictionary = device.duplicate(true)
	var output_count: int = clampi(int(next_device.get("output_count", MAX_CHAIN_SWITCHER_OUTPUTS)), 0, MAX_CHAIN_SWITCHER_OUTPUTS)
	if output_count <= 0:
		return {"ok": false, "message": "No chain outputs configured.", "device": next_device}
	var selected_output: int = clampi(output_index, 0, output_count - 1)
	next_device["selected_output"] = selected_output
	return {"ok": true, "device": next_device, "evaluation": evaluate_chain_switcher(next_device)}

static func toggle_light_switch(device: Dictionary) -> Dictionary:
	var next_device: Dictionary = device.duplicate(true)
	next_device["is_on"] = not bool(device.get("is_on", device.get("enabled", false)))
	return {"ok": true, "device": next_device, "evaluation": evaluate_light_switch(next_device)}

static func build_linked_lights_update(light_switch: Dictionary) -> Dictionary:
	var evaluation: Dictionary = evaluate_light_switch(light_switch)
	return {
		"linked_light_ids": evaluation.get("linked_light_ids", []),
		"light_state": POWER_STATE_ON if bool(evaluation.get("is_on", false)) else POWER_STATE_OFF,
		"requires_direct_cable": false
	}

static func _has_cable_port(device: Dictionary) -> bool:
	if device.has("has_cable_port"):
		return bool(device.get("has_cable_port", false))
	var kind: String = normalize_device_kind(str(device.get("device_kind", device.get("kind", ""))))
	return kind in [DEVICE_POWER_SOURCE, DEVICE_POWER_SOCKET, DEVICE_FUSE_BOX, DEVICE_POWER_SWITCHER, DEVICE_CHAIN_SWITCHER, DEVICE_POWERED_OBJECT]

static func _normalize_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in Array(value):
			var text: String = str(item).strip_edges()
			if not text.is_empty() and not result.has(text):
				result.append(text)
	return result
