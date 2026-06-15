extends RefCounted
class_name VisualAssetRenderContractService

const CONTRACT_OBJECT_SPRITE := "object_sprite"
const CONTRACT_WALL_AUTHORED_CANVAS := "wall_authored_canvas"
const CONTRACT_FLOOR_AUTHORED_CANVAS := "floor_authored_canvas"

static func get_texture_basename(texture_path: String) -> String:
	return str(texture_path).strip_edges().get_file().get_basename().to_lower()

static func is_wall_authored_canvas(texture_path: String) -> bool:
	return get_texture_basename(texture_path).ends_with("_wall")

static func is_floor_authored_canvas(texture_path: String) -> bool:
	return get_texture_basename(texture_path).ends_with("_floor")

static func is_pulsar_overlay(texture_path: String) -> bool:
	return get_texture_basename(texture_path).contains("pulsar_overlay")

static func get_render_contract(texture_path: String) -> String:
	if is_wall_authored_canvas(texture_path):
		return CONTRACT_WALL_AUTHORED_CANVAS
	if is_floor_authored_canvas(texture_path):
		return CONTRACT_FLOOR_AUTHORED_CANVAS
	return CONTRACT_OBJECT_SPRITE
