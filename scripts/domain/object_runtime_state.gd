extends RefCounted

# ObjectRuntimeState
# Отделяет runtime поля от config/links.

const DEFAULT_STATE_BY_TYPE := {
	"door": "closed",
	"power_source": "on",
	"terminal": "idle"
}

static func make_initial(definition: Dictionary, data: Dictionary = {}) -> Dictionary:
	var object_type := str(definition.get("object_type", data.get("object_type", "object")))
	return {
		"state": str(data.get("state", DEFAULT_STATE_BY_TYPE.get(object_type, "idle"))),
		"power_state": str(data.get("power_state", "none")),
		"locked": bool(data.get("locked", false)),
		"damaged": bool(data.get("damaged", false)),
		"active": bool(data.get("active", true))
	}

static func merge_into_data(data: Dictionary, runtime_state: Dictionary) -> Dictionary:
	var result := data.duplicate(true)
	result["runtime_state"] = runtime_state.duplicate(true)
	for key in runtime_state.keys():
		result[str(key)] = runtime_state[key]
	return result

static func get_runtime_state(data: Dictionary) -> Dictionary:
	var state: Dictionary = Dictionary(data.get("runtime_state", {})).duplicate(true)
	for key in ["state", "power_state", "locked", "damaged", "active"]:
		if data.has(key) and not state.has(key):
			state[key] = data[key]
	return state
