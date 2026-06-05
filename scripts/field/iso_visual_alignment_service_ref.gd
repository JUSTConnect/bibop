extends RefCounted
class_name IsoVisualAlignmentServiceRef

const IsoVisualAlignmentServiceBaseRef = preload("res://scripts/field/iso_visual_alignment_service.gd")

static func clamp_visible_bounds(visible_bounds: Rect2, texture_size: Vector2) -> Rect2:
	return IsoVisualAlignmentServiceBaseRef.clamp_visible_bounds(visible_bounds, texture_size)

static func get_ground_destination_rect(cell_iso_center: Vector2, tile_size: Vector2, texture_size: Vector2, placement: Dictionary) -> Rect2:
	return IsoVisualAlignmentServiceBaseRef.get_ground_destination_rect(cell_iso_center, tile_size, texture_size, placement)

static func get_floor_destination_rect(cell_iso_center: Vector2, tile_size: Vector2, placement: Dictionary, surface_y_offset: float = 0.0) -> Rect2:
	return IsoVisualAlignmentServiceBaseRef.get_floor_destination_rect(cell_iso_center, tile_size, placement, surface_y_offset)

static func get_ground_top_surface_y_offset(tile_size: Vector2, texture_size: Vector2, placement: Dictionary) -> float:
	return IsoVisualAlignmentServiceBaseRef.get_ground_top_surface_y_offset(tile_size, texture_size, placement)
