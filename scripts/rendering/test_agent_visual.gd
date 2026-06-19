extends RefCounted

static func create(cell: Vector2i, goal: Vector2i, reached_goal: bool) -> Dictionary:
	return {
		"id": "test_agent",
		"marker": "A",
		"label": "Agent",
		"sub_label": "goal" if reached_goal else "to:%d,%d" % [goal.x, goal.y],
		"asset_candidates": [],
		"fill_color": Color(0.95, 0.28, 0.42, 1.0),
		"outline_color": Color(1.0, 0.85, 0.9, 1.0),
		"is_selected": false,
		"agent_cell": cell,
	}
