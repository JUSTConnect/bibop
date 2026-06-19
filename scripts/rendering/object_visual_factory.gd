extends RefCounted

const ObjectVisualCatalogRef = preload("res://scripts/rendering/object_visual_catalog.gd")

const POWER_COLOR := Color(0.20, 0.70, 0.95, 1.0)
const POWER_OFF_COLOR := Color(0.32, 0.38, 0.44, 1.0)
const TERMINAL_COLOR := Color(0.62, 0.42, 0.95, 1.0)
const TERMINAL_OFF_COLOR := Color(0.34, 0.28, 0.42, 1.0)
const DOOR_COLOR := Color(0.95, 0.62, 0.25, 1.0)
const DOOR_OPEN_COLOR := Color(0.28, 0.82, 0.42, 1.0)
const CABLE_COLOR := Color(0.22, 0.86, 0.90, 1.0)
const CABLE_OFF_COLOR := Color(0.24, 0.36, 0.40, 1.0)
const GENERIC_COLOR := Color(0.48, 0.68, 0.58, 1.0)
const SELECTED_OUTLINE := Color(0.30, 0.95, 1.0, 1.0)

static var _visual_catalog: Variant = null

static func create_map_visual(data: Dictionary, definition: Dictionary = {}, is_selected: bool = false) -> Dictionary:
	var object_type: String = str(data.get("object_type", definition.get("object_type", "object")))
	var display_name: String = str(data.get("display_name", data.get("id", "Object")))
	var definition_id: String = str(data.get("definition_id", definition.get("id", "")))
	var visual_id: String = str(data.get("visual_id", definition.get("visual_id", definition_id)))
	var catalog_entry: Dictionary = _get_catalog_entry(visual_id)
	var fill_color: Color = _get_fill_color(data, object_type)
	return {
		"id": str(data.get("id", "")),
		"definition_id": definition_id,
		"visual_id": visual_id,
		"asset_candidates": _make_asset_candidates(visual_id, object_type, catalog_entry),
		"object_type": object_type,
		"display_name": display_name,
		"marker": str(catalog_entry.get("fallback_marker", _get_marker(object_type))),
		"label": _make_short_label(display_name),
		"sub_label": _make_state_label(data, object_type),
		"fill_color": fill_color,
		"outline_color": SELECTED_OUTLINE if is_selected else fill_color,
		"is_selected": is_selected,
		"debug_fallback": true,
	}

static func create_empty_cell_visual(cell: Vector2i) -> Dictionary:
	return {
		"id": "",
		"marker": "+",
		"label": "%d,%d" % [cell.x, cell.y],
		"sub_label": "",
		"asset_candidates": [],
		"fill_color": Color.TRANSPARENT,
		"outline_color": Color.TRANSPARENT,
		"is_selected": false,
		"is_empty": true,
	}

static func create_visual(render_model: Dictionary) -> Node2D:
	var node := Sprite2D.new()
	node.name = str(render_model.get("id", "ObjectVisual"))
	return node

static func _get_catalog_entry(visual_id: String) -> Dictionary:
	if _visual_catalog == null:
		_visual_catalog = ObjectVisualCatalogRef.new()
		_visual_catalog.call("load_from_path")
	return Dictionary(_visual_catalog.call("get_entry", visual_id))

static func _make_asset_candidates(visual_id: String, object_type: String, catalog_entry: Dictionary) -> Array[String]:
	var candidates: Array[String] = []
	var catalog_texture: String = str(catalog_entry.get("texture", ""))
	if not catalog_texture.is_empty():
		candidates.append(catalog_texture)
	if not visual_id.is_empty():
		candidates.append("res://assets/visual/isometric/objects/%s.png" % visual_id)
		candidates.append("res://assets/visual/isometric/%s.png" % visual_id)
		candidates.append("res://assets/visual/isometric/%s/%s.png" % [object_type, visual_id])
	if not object_type.is_empty():
		candidates.append("res://assets/visual/isometric/objects/%s.png" % object_type)
	return candidates

static func _get_marker(object_type: String) -> String:
	match object_type:
		"power_source":
			return "P"
		"terminal":
			return "T"
		"door":
			return "D"
		"power_cable":
			return "C"
		_:
			return "O"

static func _get_fill_color(data: Dictionary, object_type: String) -> Color:
	match object_type:
		"power_source":
			return POWER_OFF_COLOR if str(data.get("state", "on")).to_lower() == "off" else POWER_COLOR
		"terminal":
			return TERMINAL_OFF_COLOR if str(data.get("power_state", "none")).to_lower() == "unpowered" else TERMINAL_COLOR
		"door":
			return DOOR_OPEN_COLOR if str(data.get("state", "closed")).to_lower() == "open" else DOOR_COLOR
		"power_cable":
			return CABLE_OFF_COLOR if str(data.get("power_state", "none")).to_lower() == "unpowered" else CABLE_COLOR
		_:
			return GENERIC_COLOR

static func _make_state_label(data: Dictionary, object_type: String) -> String:
	match object_type:
		"power_source":
			return "power:%s" % str(data.get("state", "on")).to_lower()
		"door":
			return "door:%s" % str(data.get("state", "closed")).to_lower()
		"terminal":
			var links: Dictionary = Dictionary(data.get("links", {}))
			var targets: Array = Array(links.get("controlled_targets", []))
			var power_state: String = str(data.get("power_state", "none")).to_lower()
			return "power:%s targets:%d" % [power_state, targets.size()]
		"power_cable":
			var cable_power: String = str(data.get("power_state", "none")).to_lower()
			var circuit_id: String = str(data.get("circuit_id", ""))
			return "%s %s" % [cable_power, circuit_id]
		_:
			return str(data.get("visual_id", object_type))

static func _make_short_label(text: String) -> String:
	var clean: String = text.strip_edges()
	if clean.length() <= 18:
		return clean
	return clean.substr(0, 15) + "..."
