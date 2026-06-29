extends "res://scripts/game/mission_manager.gd"

var test_width: int = 8
var test_height: int = 8
var blocked_cells: Dictionary = {}

func set_test_cell_blocked(cell: Vector2i, blocked: bool) -> void:
	if blocked:
		blocked_cells[cell] = true
	else:
		blocked_cells.erase(cell)

func get_runtime_cell_state(cell: Vector2i) -> Dictionary:
	var in_bounds: bool = cell.x >= 0 and cell.y >= 0 and cell.x < test_width and cell.y < test_height
	return {
		"in_bounds": in_bounds,
		"is_passable": in_bounds and not blocked_cells.has(cell),
		"cell": cell
	}
