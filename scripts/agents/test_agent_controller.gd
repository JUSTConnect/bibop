extends RefCounted

const AgentStateRef = preload("res://scripts/agents/test_agent_state.gd")
const PathfinderRef = preload("res://scripts/agents/grid_pathfinder.gd")

var state: RefCounted = AgentStateRef.new()
var allowed_cells: Array[Vector2i] = []

func setup(start_cell: Vector2i, goal_cell: Vector2i, allowed: Array[Vector2i] = []) -> void:
	state = AgentStateRef.new()
	state.call("setup", start_cell, goal_cell)
	allowed_cells = allowed.duplicate()

func reset(start_cell: Vector2i, goal_cell: Vector2i) -> void:
	_ensure_state()
	state.call("setup", start_cell, goal_cell)

func recalculate(repository: RefCounted, columns: int, rows: int) -> Array[Vector2i]:
	_ensure_state()
	var path: Array[Vector2i] = PathfinderRef.find_path(cell(), goal(), repository, columns, rows, allowed_cells)
	state.set("path", path)
	state.set("last_block_reason", "no_path" if path.is_empty() else "")
	return path

func step(repository: RefCounted, columns: int, rows: int) -> Dictionary:
	_ensure_state()
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
	_ensure_state()
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
	_ensure_state()
	var value: Variant = state.get("cell")
	return value if value is Vector2i else Vector2i.ZERO

func goal() -> Vector2i:
	_ensure_state()
	var value: Variant = state.get("goal")
	return value if value is Vector2i else Vector2i.ZERO

func reached_goal() -> bool:
	_ensure_state()
	return bool(state.get("reached_goal"))

func _ensure_state() -> void:
	if state == null:
		state = AgentStateRef.new()
