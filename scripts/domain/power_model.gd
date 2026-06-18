extends RefCounted

# Target class: PowerModel
# Чистые power calculations без UI и renderer.

static func build_power_state(data: Dictionary) -> Dictionary:
	return {
		"power_state": "powered" if bool(data.get("is_powered", false)) else "unpowered",
		"power_mode": str(data.get("power_mode", data.get("power_type", "none"))),
		"source_id": str(data.get("power_source_id", "")),
		"circuit_id": str(data.get("power_network_id", data.get("power_circuit_id", "main"))),
	}
