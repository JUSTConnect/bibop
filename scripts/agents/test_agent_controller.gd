extends RefCounted

const AgentStateRef = preload("res://scripts/agents/test_agent_state.gd")
const PathfinderRef = preload("res://scripts/agents/grid_pathfinder.gd")

var state: RefCounted = AgentStateRef.new()
var allowed_cells: Array[Vector2i] = []
var initialized: bool = false

func setup(start_cell: Vector2i, goal_cell: Vector2i, allowed: Array[Vector2i] = []) -> void:
	state = AgentStateRef.new()
	state.call("setup", start_cell, goal_cell)
	allowed_cells = allowed.duplicate()
	initialized = true

func reset(start_cell: Vector2i, goal_cell: Vector2i) -> void:
	_ensure_state()
	state.call("setup", start_cell, goal_cell)
	initialized = true

func recalculate(repository: RefCounted, columns: int, rows: int) -> Array[Vector2i]:
	if not initialized:
		return []
	var path: Array[Vector2i] = PathfinderRef.find_path(cell(), goal(), repository, columns, rows, allowed_cells)
	state.set("path", path)
	state.set("last_block_reason", "no_path" if path.is_empty() else "")
	return path

func step(repository: RefCounted, columns: int, rows: int) -> Dictionary:
	if not initialized:
		return {"moved": false, "message": "Agent is not initialized."}
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
	if not initialized:
		return {"steps": 0, "reached_goal": false, "cell": Vector2i(-1, -1), "message": "Agent is not initialized."}
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
	if not initialized:
		return Vector2i(-1, -1)
	var value: Variant = state.get("cell")
	return value if value is Vector2i else Vector2i(-1, -1)

func goal() -> Vector2i:
	if not initialized:
		return Vector2i(-1, -1)
	var value: Variant = state.get("goal")
	return value if value is Vector2i else Vector2i(-1, -1)

func reached_goal() -> bool:
	if not initialized:
		return false
	return bool(state.get("reached_goal"))

func _ensure_state() -> void:
	if state == null:
		state = AgentStateRef.new()
