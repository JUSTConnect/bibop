extends RefCounted

const ObjectActionRef = preload("res://scripts/interactions/object_action.gd")

static func get_actions(data: Dictionary) -> Array[Dictionary]:
	match str(data.get("object_type", "")):
		"power_source":
			return _power_source_actions(data)
		"door":
			return _door_actions(data)
		"terminal":
			return _terminal_actions(data)
		_:
			return [ObjectActionRef.make("inspect", "Inspect")]

static func _power_source_actions(data: Dictionary) -> Array[Dictionary]:
	var is_on: bool = str(data.get("state", "on")).to_lower() == "on"
	return [
		ObjectActionRef.make("turn_off", "Turn off", is_on, "Already off"),
		ObjectActionRef.make("turn_on", "Turn on", not is_on, "Already on"),
		ObjectActionRef.make("inspect", "Inspect"),
	]

static func _door_actions(data: Dictionary) -> Array[Dictionary]:
	var is_open: bool = str(data.get("state", "closed")).to_lower() == "open"
	var locked: bool = bool(data.get("locked", false))
	var damaged: bool = bool(data.get("damaged", false))
	var usable: bool = not damaged and not locked
	return [
		ObjectActionRef.make("open", "Open", usable and not is_open, "Door cannot open"),
		ObjectActionRef.make("close", "Close", not damaged and is_open, "Door cannot close"),
		ObjectActionRef.make("unlock", "Unlock", locked, "Already unlocked"),
		ObjectActionRef.make("lock", "Lock", not locked and not is_open, "Close door first"),
		ObjectActionRef.make("inspect", "Inspect"),
	]

static func _terminal_actions(data: Dictionary) -> Array[Dictionary]:
	var powered: bool = str(data.get("power_state", "none")).to_lower() != "unpowered"
	var targets: Array = Array(Dictionary(data.get("links", {})).get("controlled_targets", []))
	var active: bool = powered and not targets.is_empty()
	return [
		ObjectActionRef.make("activate", "Activate", active, "Terminal is unpowered or unlinked"),
		ObjectActionRef.make("inspect_links", "Inspect links"),
	]
