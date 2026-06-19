extends RefCounted

const AgentRef = preload("res://scripts/agents/test_agent_controller.gd")

const FORBIDDEN_SOURCE: Dictionary = {
	"res://scripts/domain/object_data_factory.gd": ["[] if str(link.get"],
	"res://scripts/systems/object_link_system.gd": ["[] if link_type"],
	"res://scripts/presentation/object_links_view_model.gd": ["return [] if link_type"],
	"res://scripts/ui/map_constructor_new/map_canvas_view.gd": ["_cell_from_position(position"],
	"res://scripts/ui/common/common_property_row_builder.gd": [
		"get_item_metadata(option.selected) if option.selected >= 0 else",
	],
	"res://scripts/agents/grid_pathfinder.gd": ["cells_by_key"],
	"res://scripts/agents/test_agent_controller.gd": [
		"func setup(start: Vector2i, goal: Vector2i",
		"func reset(start: Vector2i, goal: Vector2i",
	],
	"res://tests/smoke/test_agent_path.gd": ["for step_index in range"],
}

static func run() -> Array[String]:
	var errors: Array[String] = []
	for path_value: Variant in FORBIDDEN_SOURCE.keys():
		var path: String = str(path_value)
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file == null:
			errors.append("cannot read warning guard source: %s" % path)
			continue
		var source: String = file.get_as_text()
		for pattern_value: Variant in Array(FORBIDDEN_SOURCE[path_value]):
			var pattern: String = str(pattern_value)
			if source.contains(pattern):
				errors.append("warning pattern returned in %s: %s" % [path, pattern])
	var agent: RefCounted = AgentRef.new()
	var early_cell: Variant = agent.call("cell")
	var early_goal: Variant = agent.call("goal")
	var early_reached: bool = bool(agent.call("reached_goal"))
	if not (early_cell is Vector2i) or not (early_goal is Vector2i):
		errors.append("agent must expose safe defaults before setup")
	if early_reached:
		errors.append("uninitialized agent must not report reached goal")
	return errors
