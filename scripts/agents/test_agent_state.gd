extends RefCounted

var cell: Vector2i = Vector2i.ZERO
var goal: Vector2i = Vector2i.ZERO
var path: Array[Vector2i] = []
var reached_goal: bool = false
var last_block_reason: String = ""

func setup(start_cell: Vector2i, goal_cell: Vector2i) -> void:
	cell = start_cell
	goal = goal_cell
	path.clear()
	reached_goal = cell == goal
	last_block_reason = ""

func make_snapshot() -> Dictionary:
	return {
		"cell": {"x": cell.x, "y": cell.y},
		"goal": {"x": goal.x, "y": goal.y},
		"reached_goal": reached_goal,
	}
