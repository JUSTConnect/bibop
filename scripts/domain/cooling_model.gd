extends RefCounted

# Target class: CoolingModel
# Чистая модель cooling/contour/routing.

static func build_cooling_state(data: Dictionary) -> Dictionary:
	return {
		"cooling_state": str(data.get("cooling_state", "none")),
		"contour_id": str(data.get("cooling_contour_id", "")),
		"routing_mode": str(data.get("routing_mode", data.get("wall_routing_mode", "outer"))),
		"capacity": int(data.get("cooling_capacity", 0)),
	}
