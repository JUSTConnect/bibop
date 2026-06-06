extends RefCounted
class_name VisualAssetCatalogRef

# Compatibility proxy for code paths that reference VisualAssetCatalogRef as a global class.
# Long term, large files should preload VisualAssetCatalog directly, but this proxy keeps
# current renderer/runtime references compiling without touching large files.

static func get_asset_path(asset_id: String) -> String:
	return VisualAssetCatalog.get_asset_path(asset_id)

static func has_asset(asset_id: String) -> bool:
	return VisualAssetCatalog.has_asset(asset_id)

static func resolve_floor_asset_id(raw_id: String) -> String:
	return VisualAssetCatalog.resolve_floor_asset_id(raw_id)

static func resolve_wall_asset_id(raw_id: String) -> String:
	return VisualAssetCatalog.resolve_wall_asset_id(raw_id)

static func resolve_object_asset_id(raw_id: String) -> String:
	return VisualAssetCatalog.resolve_object_asset_id(raw_id)

static func get_canonical_object_visual_ids() -> Array[String]:
	return VisualAssetCatalog.get_canonical_object_visual_ids()

static func get_all_asset_paths() -> Dictionary:
	return VisualAssetCatalog.get_all_asset_paths()

static func validate_asset_catalog() -> Array[String]:
	return VisualAssetCatalog.validate_asset_catalog()
