extends RefCounted

static func use_door(door_data: Dictionary, force_terminal: bool = false) -> Dictionary:
	var door_id := str(door_data.get("id", ""))
	if bool(door_data.get("damaged", false)):
		return {"ok": false, "message": "Door is damaged.", "patches": []}
	if bool(door_data.get("locked", false)) and not force_terminal:
		return {"ok": false, "message": "Door is locked.", "patches": []}
	if bool(door_data.get("power_required", false)) and str(door_data.get("power_state", "none")) == "unpowered":
		return {"ok": false, "message": "Door has no power.", "patches": []}
	var next_state := "closed" if str(door_data.get("state", "closed")).to_lower() == "open" else "open"
	return {"ok": true, "message": "Door %s." % next_state, "patches": [{"instance_id": door_id, "patch": {"state": next_state}}]}
