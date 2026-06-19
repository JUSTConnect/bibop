extends RefCounted

const ProviderRef = preload("res://scripts/interactions/object_action_provider.gd")
const ExecutorRef = preload("res://scripts/interactions/object_action_executor.gd")

static func run() -> Array[String]:
	var errors: Array[String] = []
	var door: Dictionary = {
		"id": "door_1",
		"object_type": "door",
		"state": "closed",
		"locked": true,
		"damaged": false,
	}
	var actions: Array[Dictionary] = ProviderRef.get_actions(door)
	var open_enabled: bool = true
	for action: Dictionary in actions:
		if str(action.get("id", "")) == "open":
			open_enabled = bool(action.get("enabled", true))
	if open_enabled:
		errors.append("Open action must be disabled for locked door")
	var result: Dictionary = ExecutorRef.execute("open", door, [door])
	if bool(result.get("ok", false)):
		errors.append("Executor must enforce locked door rule")
	return errors
