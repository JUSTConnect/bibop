extends RefCounted

const AgentStateRef = preload("res://scripts/agents/test_agent_state.gd")
const PathfinderRef = preload("res://scripts/agents/grid_pathfinder.gd")

var state: RefCounted = null
var allowed_cells: Array[Vector2i] = []

func setup(start: Vector2i, goal: Vector2i, allowed: Array[Vector2i] = []) -> void:
	state = AgentStateRef.new()
	state.call("setup", start, goal)
	allowed_cells = allowed.duplicate()

func reset(start: Vector2i, goal: Vector2i) -> void:
	state.call("setup", start, goal)

func recalculate(repository: RefCounted, columns: int, rows: int) -> Array[Vector2i]:
	var path: Array[Vector2i] = PathfinderRef.find_path(cell(), goal(), repository, columns, rows, allowed_cells)
	state.set("path", path)
	state.set("last_block_reason", "no_path" if path.is_empty() else "")
	return path

func step(repository: RefCounted, columns: int, rows: int) -> Dictionary:
	if cell() == goal():
		state.set("reached_goal", true)
		return {"moved": false, "message": "Agent already reached goal."}
	var path: Array[Vector2i] = recalculate(repository, columns, rows)
	if path.size() < 2:
		return {"moved": false, "message": "Agent path is blocked."}
	state.set("cell", path[1])
	state.set("reached_goal", path[1] == goal())
	return {
		"moved": true,
		"message": "Agent reached goal." if path[1] == goal() else "Agent moved to %s." % str(path[1]),
	}

func run_until_stop(repository: RefCounted, columns: int, rows: int, max_steps: int = 64) -> Dictionary:
	var steps: int = 0
	var last_result: Dictionary = {"moved": false, "message": "No movement."}
	while steps < max_steps and not reached_goal():
		last_result = step(repository, columns, rows)
		if not bool(last_result.get("moved", false)):
			break
		steps += 1
	return {
		"steps": steps,
		"reached_goal": reached_goal(),
		"cell": cell(),
		"message": str(last_result.get("message", "Agent stopped.")),
	}

func cell() -> Vector2i:
	var value: Variant = state.get("cell")
	return value if value is Vector2i else Vector2i.ZERO

func goal() -> Vector2i:
	var value: Variant = state.get("goal")
	return value if value is Vector2i else Vector2i.ZERO

func reached_goal() -> bool:
	return bool(state.get("reached_goal"))
