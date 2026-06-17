extends RefCounted
class_name VisualAssetRenderContractService

const CONTRACT_OBJECT_SPRITE := "object_sprite"
const CONTRACT_WALL_AUTHORED_CANVAS := "wall_authored_canvas"
const CONTRACT_FLOOR_AUTHORED_CANVAS := "floor_authored_canvas"

static func get_texture_basename(texture_path: String) -> String:
	return str(texture_path).strip_edges().get_file().get_basename().to_lower()

static func _has_authored_canvas_token(basename: String, token: String) -> bool:
	return basename.ends_with("_" + token) or basename.contains("_" + token + "_")

static func is_wall_authored_canvas(texture_path: String) -> bool:
	return _has_authored_canvas_token(get_texture_basename(texture_path), "wall")

static func is_floor_authored_canvas(texture_path: String) -> bool:
	return _has_authored_canvas_token(get_texture_basename(texture_path), "floor")

static func is_pulsar_overlay(texture_path: String) -> bool:
	return get_texture_basename(texture_path).contains("pulsar_overlay")

static func get_render_contract(texture_path: String) -> String:
	if is_wall_authored_canvas(texture_path):
		return CONTRACT_WALL_AUTHORED_CANVAS
	if is_floor_authored_canvas(texture_path):
		return CONTRACT_FLOOR_AUTHORED_CANVAS
	return CONTRACT_OBJECT_SPRITE
