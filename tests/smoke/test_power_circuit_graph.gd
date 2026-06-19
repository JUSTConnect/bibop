extends RefCounted

const PowerGraphRef = preload("res://scripts/power/power_graph.gd")
const PowerSolverRef = preload("res://scripts/power/power_network_solver.gd")

static func run() -> Array[String]:
	var errors: Array[String] = []
	var objects: Array[Dictionary] = [
		_make("source", "power_source", 0, 0, "on", "source"),
		_make("cable", "power_cable", 1, 0, "connected", "none"),
		_make("terminal", "terminal", 2, 0, "idle", "external"),
	]
	var graph: Dictionary = PowerGraphRef.build(objects)
	var solved: Dictionary = PowerSolverRef.solve(graph)
	var powered: Dictionary = Dictionary(solved.get("powered_by_id", {}))
	if not bool(powered.get("terminal", false)):
		errors.append("connected terminal must be powered")
	objects[0]["state"] = "off"
	graph = PowerGraphRef.build(objects)
	solved = PowerSolverRef.solve(graph)
	powered = Dictionary(solved.get("powered_by_id", {}))
	if bool(powered.get("terminal", true)):
		errors.append("terminal must lose power when source is off")
	return errors

static func _make(id: String, kind: String, x: int, y: int, state: String, power_mode: String) -> Dictionary:
	return {
		"id": id,
		"instance_id": id,
		"object_type": kind,
		"state": state,
		"power_mode": power_mode,
		"placement": {"cell_x": x, "cell_y": y},
	}
