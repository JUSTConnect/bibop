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

static func get_platform_surface_y_offset(platform_data: Dictionary, level_height_pixels: float = 32.0) -> float:
	return IsoVisualAlignmentServiceBaseRef.get_platform_surface_y_offset(platform_data, level_height_pixels)

static func get_object_surface_y_offset(surface_context: Dictionary) -> float:
	return IsoVisualAlignmentServiceBaseRef.get_object_surface_y_offset(surface_context)

static func apply_surface_y_offset_to_center(cell_center: Vector2, surface_context: Dictionary) -> Vector2:
	return IsoVisualAlignmentServiceBaseRef.apply_surface_y_offset_to_center(cell_center, surface_context)

static func build_surface_context(surface_level: int = 0, ground_surface_y_offset: float = 0.0, platform_surface_y_offset: float = 0.0, wall_mounted: bool = false) -> Dictionary:
	return IsoVisualAlignmentServiceBaseRef.build_surface_context(surface_level, ground_surface_y_offset, platform_surface_y_offset, wall_mounted)

static func get_surface_layer_bias(surface_context: Dictionary) -> float:
	return IsoVisualAlignmentServiceBaseRef.get_surface_layer_bias(surface_context)
