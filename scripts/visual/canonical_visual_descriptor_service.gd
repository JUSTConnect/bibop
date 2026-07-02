extends RefCounted
class_name CanonicalVisualDescriptorService

const VisualAssetCatalogRef = preload("res://scripts/visual/visual_asset_catalog.gd")
const VisualStateAssetServiceRef = preload("res://scripts/visual/visual_state_asset_service.gd")

const FIELD_VISUAL_FAMILY: String = "visual_family"
const FIELD_VISUAL_SURFACE: String = "visual_surface"
const FIELD_VISUAL_STATE_POLICY: String = "visual_state_policy"
const FIELD_VISUAL_VARIANT: String = "visual_variant"
const FIELD_VISUAL_ASSET_ID: String = "visual_asset_id"
const FIELD_RENDER_CONTRACT: String = "render_contract"
const FIELD_MOUNT: String = "mount"
const FIELD_FACING_SIDE: String = "facing_side"

const SURFACE_FLOOR: String = "floor"
const SURFACE_WALL: String = "wall"
const MOUNT_FLOOR: String = "floor"
const MOUNT_WALL: String = "wall"
const RENDER_CONTRACT_OBJECT: String = "object"

const DESCRIPTOR_FIELDS: Array[String] = [
	FIELD_VISUAL_FAMILY,
	FIELD_VISUAL_SURFACE,
	FIELD_VISUAL_STATE_POLICY,
	FIELD_VISUAL_VARIANT,
	FIELD_VISUAL_ASSET_ID,
	FIELD_RENDER_CONTRACT,
	FIELD_MOUNT,
	FIELD_FACING_SIDE,
]


static func _normalized_text(value: Variant) -> String:
	return str(value).strip_edges().to_lower().replace(" ", "_").replace("-", "_")


static func _first_text(source: Dictionary, keys: Array[String], fallback: String = "") -> String:
	for key in keys:
		var normalized: String = _normalized_text(source.get(key, ""))
		if not normalized.is_empty():
			return normalized
	return fallback


static func normalize_surface(value: Variant) -> String:
	var normalized: String = _normalized_text(value)
	if normalized in [SURFACE_WALL, "wall_mounted"]:
		return SURFACE_WALL
	if normalized in [SURFACE_FLOOR, "ground", "cell"]:
		return SURFACE_FLOOR
	return ""


static func normalize_mount(value: Variant) -> String:
	var normalized: String = _normalized_text(value)
	if normalized in [MOUNT_WALL, "wall_mounted"]:
		return MOUNT_WALL
	if normalized in [MOUNT_FLOOR, "ground", "cell"]:
		return MOUNT_FLOOR
	return ""


static func normalize_facing_side(value: Variant) -> String:
	var normalized: String = _normalized_text(value)
	match normalized:
		"ne", "north_east", "up_right", "right_up":
			return "ne"
		"nw", "north_west", "up_left", "left_up":
			return "nw"
		"se", "south_east", "down_right", "right_down":
			return "se"
		"sw", "south_west", "down_left", "left_down":
			return "sw"
		"north", "east", "south", "west":
			return normalized
		_:
			return ""


static func resolve_visual_state_policy(object_data: Dictionary) -> String:
	var explicit_policy: String = _first_text(object_data, [FIELD_VISUAL_STATE_POLICY, "state_policy"])
	if not explicit_policy.is_empty():
		return explicit_policy
	var family: String = VisualStateAssetServiceRef.get_visual_family(object_data)
	var config: Dictionary = VisualStateAssetServiceRef.get_visual_state_family_config(family)
	return _normalized_text(config.get(FIELD_VISUAL_STATE_POLICY, "static"))


static func resolve_mount(object_data: Dictionary, visual_surface: String) -> String:
	var explicit_mount: String = normalize_mount(_first_text(object_data, [FIELD_MOUNT, "install_mode", "placement_mode", "placement", "cable_install_mode"]))
	if not explicit_mount.is_empty():
		return explicit_mount
	return MOUNT_WALL if visual_surface == SURFACE_WALL else MOUNT_FLOOR


static func resolve_facing_side(object_data: Dictionary) -> String:
	for key in [FIELD_FACING_SIDE, "facing_dir", "direction", "visual_variant", "variant"]:
		var side: String = normalize_facing_side(object_data.get(key, ""))
		if not side.is_empty():
			return side
	return ""


static func normalize_descriptor(descriptor: Dictionary) -> Dictionary:
	var normalized: Dictionary = {}
	for field in DESCRIPTOR_FIELDS:
		normalized[field] = _normalized_text(descriptor.get(field, ""))
	normalized[FIELD_VISUAL_SURFACE] = normalize_surface(normalized.get(FIELD_VISUAL_SURFACE, ""))
	normalized[FIELD_MOUNT] = normalize_mount(normalized.get(FIELD_MOUNT, ""))
	normalized[FIELD_FACING_SIDE] = normalize_facing_side(normalized.get(FIELD_FACING_SIDE, ""))
	if str(normalized.get(FIELD_RENDER_CONTRACT, "")).is_empty():
		normalized[FIELD_RENDER_CONTRACT] = RENDER_CONTRACT_OBJECT
	return normalized


static func build_descriptor(object_data: Dictionary, fallback_render_contract: String = RENDER_CONTRACT_OBJECT) -> Dictionary:
	var family: String = VisualStateAssetServiceRef.get_visual_family(object_data)
	var surface: String = VisualStateAssetServiceRef.get_visual_surface(object_data)
	var visual_variant: String = VisualStateAssetServiceRef.resolve_visual_variant(object_data)
	var visual_asset_id: String = VisualStateAssetServiceRef.resolve_visual_asset_id(object_data)
	if visual_asset_id.is_empty():
		visual_asset_id = VisualAssetCatalogRef.resolve_object_asset_id("object_generic")
	var descriptor: Dictionary = {
		FIELD_VISUAL_FAMILY: family,
		FIELD_VISUAL_SURFACE: surface,
		FIELD_VISUAL_STATE_POLICY: resolve_visual_state_policy(object_data),
		FIELD_VISUAL_VARIANT: visual_variant,
		FIELD_VISUAL_ASSET_ID: visual_asset_id,
		FIELD_RENDER_CONTRACT: _first_text(object_data, [FIELD_RENDER_CONTRACT, "descriptor_mode"], fallback_render_contract),
		FIELD_MOUNT: resolve_mount(object_data, surface),
		FIELD_FACING_SIDE: resolve_facing_side(object_data),
	}
	return normalize_descriptor(descriptor)


static func validate_descriptor(descriptor: Dictionary) -> Array[String]:
	var issues: Array[String] = []
	for field in DESCRIPTOR_FIELDS:
		if not descriptor.has(field):
			issues.append("missing_%s" % field)
	var visual_asset_id: String = str(descriptor.get(FIELD_VISUAL_ASSET_ID, "")).strip_edges()
	if visual_asset_id.is_empty():
		issues.append("missing_visual_asset_id")
	if str(descriptor.get(FIELD_VISUAL_SURFACE, "")) not in [SURFACE_FLOOR, SURFACE_WALL]:
		issues.append("invalid_visual_surface")
	if str(descriptor.get(FIELD_MOUNT, "")) not in [MOUNT_FLOOR, MOUNT_WALL]:
		issues.append("invalid_mount")
	if str(descriptor.get(FIELD_RENDER_CONTRACT, "")).strip_edges().is_empty():
		issues.append("missing_render_contract")
	return issues


static func is_valid_descriptor(descriptor: Dictionary) -> bool:
	return validate_descriptor(descriptor).is_empty()
