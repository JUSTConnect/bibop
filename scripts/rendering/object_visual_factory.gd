extends RefCounted

# ObjectVisualFactory
# Создаёт visual descriptors для map canvas.
# Позже здесь же будет выбор PNG/animated visual_id, сейчас — системные placeholder visuals.

const POWER_COLOR := Color(0.20, 0.70, 0.95, 1.0)
const TERMINAL_COLOR := Color(0.62, 0.42, 0.95, 1.0)
const DOOR_COLOR := Color(0.95, 0.62, 0.25, 1.0)
const GENERIC_COLOR := Color(0.48, 0.68, 0.58, 1.0)
const SELECTED_OUTLINE := Color(0.30, 0.95, 1.0, 1.0)

static func create_map_visual(data: Dictionary, definition: Dictionary = {}, is_selected: bool = false) -> Dictionary:
	var object_type: String = str(data.get("object_type", definition.get("object_type", "object")))
	var display_name: String = str(data.get("display_name", data.get("id", "Object")))
	var definition_id: String = str(data.get("definition_id", definition.get("id", "")))
	return {
		"id": str(data.get("id", "")),
		"definition_id": definition_id,
		"object_type": object_type,
		"display_name": display_name,
		"marker": _get_marker(object_type),
		"label": _make_short_label(display_name),
		"sub_label": object_type,
		"fill_color": _get_fill_color(object_type),
		"outline_color": SELECTED_OUTLINE if is_selected else _get_fill_color(object_type),
		"is_selected": is_selected,
	}


static func create_empty_cell_visual(cell: Vector2i) -> Dictionary:
	return {
		"id": "",
		"marker": "+",
		"label": "%d,%d" % [cell.x, cell.y],
		"sub_label": "",
		"fill_color": Color.TRANSPARENT,
		"outline_color": Color.TRANSPARENT,
		"is_selected": false,
		"is_empty": true,
	}


static func create_visual(render_model: Dictionary) -> Node2D:
	var node := Sprite2D.new()
	node.name = str(render_model.get("id", "ObjectVisual"))
	return node


static func _get_marker(object_type: String) -> String:
	match object_type:
		"power_source":
			return "P"
		"terminal":
			return "T"
		"door":
			return "D"
		_:
			return "O"


static func _get_fill_color(object_type: String) -> Color:
	match object_type:
		"power_source":
			return POWER_COLOR
		"terminal":
			return TERMINAL_COLOR
		"door":
			return DOOR_COLOR
		_:
			return GENERIC_COLOR


static func _make_short_label(text: String) -> String:
	var clean := text.strip_edges()
	if clean.length() <= 18:
		return clean
	return clean.substr(0, 15) + "..."
