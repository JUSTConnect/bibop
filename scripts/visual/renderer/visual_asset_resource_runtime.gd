extends RefCounted
class_name VisualAssetResourceRuntime

const VisualAssetCatalogRef = preload("res://scripts/visual/visual_asset_catalog.gd")

const CACHE_FLOOR: String = "floor"
const CACHE_GROUND: String = "ground"
const CACHE_WALL: String = "wall"
const CACHE_BREACH_OVERLAY: String = "breach_overlay"
const CACHE_OBJECT_PNG: String = "object_png"
const CACHE_PLACEHOLDER: String = "placeholder"

const OBJECT_PNG_DIRECTORY_MARKERS: Array[String] = [
	"/objects/",
	"/moovable/",
	"/light/",
	"/items/",
	"/cooling system/"
]

var _texture_caches: Dictionary = {
	CACHE_FLOOR: {},
	CACHE_GROUND: {},
	CACHE_WALL: {},
	CACHE_BREACH_OVERLAY: {},
	CACHE_OBJECT_PNG: {},
	CACHE_PLACEHOLDER: {}
}

func resolve_gray_test_asset_path(asset_key: String) -> String:
	var path: String = VisualAssetCatalogRef.get_asset_path(asset_key)
	return path if path.find("/test/") >= 0 else ""

func resolve_object_png_path(asset_key: String, descriptor: Dictionary = {}) -> String:
	var normalized_asset_key: String = str(asset_key).strip_edges().to_lower()
	if normalized_asset_key.is_empty() and descriptor.is_empty():
		return ""
	var descriptor_visual_id: String = str(
		descriptor.get(
			"visual_id",
			descriptor.get("visual_asset_id", descriptor.get("asset_id", normalized_asset_key))
		)
	).strip_edges()
	var descriptor_path: String = str(descriptor.get("path", descriptor.get("texture_path", ""))).strip_edges()
	var catalog_path: String = VisualAssetCatalogRef.resolve_visual_texture_path(descriptor_visual_id, descriptor_path)
	if not catalog_path.ends_with(".png"):
		return ""
	for marker in OBJECT_PNG_DIRECTORY_MARKERS:
		if catalog_path.find(marker) >= 0:
			return catalog_path
	return ""

func is_object_png_asset_key(asset_key: String) -> bool:
	return not resolve_object_png_path(asset_key).is_empty()

func resolve_placeholder_path(asset_key: String) -> String:
	var normalized_asset_key: String = str(asset_key).strip_edges().to_lower()
	if normalized_asset_key.is_empty():
		return ""
	var catalog_path: String = VisualAssetCatalogRef.get_asset_path(normalized_asset_key)
	return catalog_path if catalog_path.find("/placeholders/") >= 0 else ""

func is_placeholder_object_texture_path(texture_path: String) -> bool:
	var normalized_path: String = texture_path.strip_edges().to_lower()
	return normalized_path.begins_with("res://assets/visual/isometric/placeholders/iso_object_") and normalized_path.ends_with(".svg")

func is_placeholder_object_texture_asset_key(asset_key: String) -> bool:
	return is_placeholder_object_texture_path(resolve_placeholder_path(asset_key))

func get_floor_texture(asset_key: String) -> Texture2D:
	return _load_catalog_texture(CACHE_FLOOR, asset_key)

func get_ground_texture(asset_key: String) -> Texture2D:
	return _load_catalog_texture(CACHE_GROUND, asset_key)

func get_breach_overlay_texture(asset_key: String) -> Texture2D:
	return _load_catalog_texture(CACHE_BREACH_OVERLAY, asset_key)

func get_object_png_texture_for_resolved_path(asset_key: String, texture_path: String) -> Texture2D:
	var normalized_asset_key: String = asset_key.strip_edges().to_lower()
	var normalized_texture_path: String = texture_path.strip_edges()
	if normalized_texture_path.is_empty():
		return null
	var cache_key: String = "%s|%s" % [normalized_asset_key, normalized_texture_path]
	var cache: Dictionary = _get_cache(CACHE_OBJECT_PNG)
	if cache.has(cache_key):
		return _as_texture(cache.get(cache_key))
	if not ResourceLoader.exists(normalized_texture_path, "Texture2D"):
		push_warning("[IsoObjectPNG] missing object PNG for visual_id=%s path=%s" % [normalized_asset_key, normalized_texture_path])
		cache[cache_key] = null
		return null
	var loaded_resource: Resource = ResourceLoader.load(normalized_texture_path)
	if loaded_resource is Texture2D:
		var loaded_texture: Texture2D = loaded_resource as Texture2D
		cache[cache_key] = loaded_texture
		return loaded_texture
	push_warning("[IsoObjectPNG] failed to load object PNG as Texture2D for visual_id=%s path=%s" % [normalized_asset_key, normalized_texture_path])
	cache[cache_key] = null
	return null

func get_object_png_texture(asset_key: String, descriptor: Dictionary = {}) -> Texture2D:
	var normalized_asset_key: String = asset_key.strip_edges().to_lower()
	return get_object_png_texture_for_resolved_path(
		normalized_asset_key,
		resolve_object_png_path(normalized_asset_key, descriptor)
	)

func get_placeholder_texture(asset_key: String, enabled: bool, skip_placeholder: bool) -> Texture2D:
	if not enabled or skip_placeholder:
		return null
	var normalized_asset_key: String = str(asset_key).strip_edges().to_lower()
	if normalized_asset_key.is_empty():
		return null
	var placeholder_path: String = resolve_placeholder_path(normalized_asset_key)
	if placeholder_path.is_empty():
		return null
	var cache: Dictionary = _get_cache(CACHE_PLACEHOLDER)
	if cache.has(normalized_asset_key):
		return _as_texture(cache.get(normalized_asset_key))
	var loaded_resource: Resource = ResourceLoader.load(placeholder_path)
	if loaded_resource is Texture2D:
		var loaded_texture: Texture2D = loaded_resource as Texture2D
		cache[normalized_asset_key] = loaded_texture
		return loaded_texture
	cache[normalized_asset_key] = null
	return null

func resolve_wall_texture(
	asset_key: String,
	catalog: Dictionary,
	explicit_texture: Texture2D,
	fallback_explicit_texture: Texture2D,
	fallback_asset_key: String = "wall_concrete_mid"
) -> Texture2D:
	var normalized_key: String = asset_key.strip_edges().to_lower()
	if normalized_key.is_empty():
		return null
	var cache: Dictionary = _get_cache(CACHE_WALL)
	if catalog.has(normalized_key):
		if cache.has(normalized_key):
			return _as_texture(cache.get(normalized_key))
		var texture_path: String = VisualAssetCatalogRef.get_asset_path(normalized_key)
		if texture_path.is_empty():
			cache[normalized_key] = null
			return null
		if ResourceLoader.exists(texture_path):
			var loaded_resource: Resource = ResourceLoader.load(texture_path)
			if loaded_resource is Texture2D:
				var loaded_texture: Texture2D = loaded_resource as Texture2D
				cache[normalized_key] = loaded_texture
				return loaded_texture
		cache[normalized_key] = null
	if normalized_key.begins_with("wall_gray_"):
		return null
	if explicit_texture != null:
		return explicit_texture
	var normalized_fallback: String = fallback_asset_key.strip_edges().to_lower()
	if not normalized_fallback.is_empty() and normalized_key != normalized_fallback:
		return resolve_wall_texture(
			normalized_fallback,
			catalog,
			fallback_explicit_texture,
			fallback_explicit_texture,
			normalized_fallback
		)
	return null

func resolve_texture(asset_key: String, context: Dictionary) -> Texture2D:
	var normalized_asset_key: String = asset_key.strip_edges().to_lower()
	if normalized_asset_key.is_empty():
		return null
	if normalized_asset_key.begins_with("wall_"):
		return resolve_wall_texture(
			normalized_asset_key,
			_as_dictionary(context.get("wall_catalog", {})),
			_as_texture(context.get("wall_explicit_texture")),
			_as_texture(context.get("wall_fallback_explicit_texture")),
			str(context.get("wall_fallback_asset_key", "wall_concrete_mid"))
		)
	if is_object_png_asset_key(normalized_asset_key):
		return get_object_png_texture(normalized_asset_key)
	var explicit_texture: Texture2D = _as_texture(context.get("explicit_texture"))
	if explicit_texture != null:
		return explicit_texture
	return get_placeholder_texture(
		normalized_asset_key,
		bool(context.get("placeholder_enabled", false)),
		bool(context.get("skip_placeholder", false))
	)

func load_optional_texture(asset_id: String, texture_path: String, warn_on_failure: bool = true) -> Texture2D:
	var normalized_asset_id: String = asset_id.strip_edges()
	var normalized_texture_path: String = texture_path.strip_edges()
	if normalized_texture_path.is_empty():
		return null
	var loaded_resource: Resource = ResourceLoader.load(normalized_texture_path)
	if loaded_resource is Texture2D:
		return loaded_resource as Texture2D
	if warn_on_failure:
		push_warning("[VisualAsset] failed to load texture_path for %s: %s" % [normalized_asset_id, normalized_texture_path])
	return null

func resource_exists(texture_path: String, type_hint: String = "") -> bool:
	var normalized_path: String = texture_path.strip_edges()
	if normalized_path.is_empty():
		return false
	if type_hint.strip_edges().is_empty():
		return ResourceLoader.exists(normalized_path)
	return ResourceLoader.exists(normalized_path, type_hint)

func validate_gray_test_assets(asset_keys: Array[String], enabled: bool) -> Dictionary:
	var assets: Dictionary = {}
	var missing: Array[String] = []
	var invalid: Array[String] = []
	for asset_key in asset_keys:
		var path: String = resolve_gray_test_asset_path(asset_key)
		var exists: bool = resource_exists(path)
		var loads_as_texture: bool = false
		if exists:
			loads_as_texture = load_optional_texture(asset_key, path, false) != null
		assets[asset_key] = {"path": path, "exists": exists, "loads_as_texture": loads_as_texture}
		if not exists:
			missing.append(asset_key)
		elif not loads_as_texture:
			invalid.append(asset_key)
	return {
		"ok": missing.is_empty() and invalid.is_empty(),
		"enabled": enabled,
		"assets": assets,
		"missing": missing,
		"invalid": invalid,
		"fallback": "magenta_black_missing_asset_debug_checker"
	}

func build_texture_debug_state(texture_keys: Array[String], context: Dictionary) -> Dictionary:
	var explicit_textures: Dictionary = _as_dictionary(context.get("explicit_textures", {}))
	var placeholder_enabled: bool = bool(context.get("placeholder_enabled", false))
	var gray_test_enabled: bool = bool(context.get("gray_test_enabled", false))
	var floor_test_asset_key: String = str(context.get("floor_test_asset_key", "floor_gray_test"))
	var wall_catalog: Dictionary = _as_dictionary(context.get("wall_catalog", {}))
	var ground_catalog: Dictionary = _as_dictionary(context.get("ground_catalog", {}))
	var debug_state: Dictionary = {}
	for texture_key in texture_keys:
		var explicit_texture: Texture2D = _as_texture(explicit_textures.get(texture_key))
		var has_explicit_texture: bool = explicit_texture != null
		var placeholder_path: String = resolve_placeholder_path(texture_key)
		var placeholder_available: bool = false
		var wall_catalog_path: String = ""
		var wall_catalog_available: bool = false
		var ground_catalog_path: String = ""
		var ground_catalog_available: bool = false
		var gray_test_placeholder_object_skipped: bool = gray_test_enabled and not has_explicit_texture and is_placeholder_object_texture_asset_key(texture_key)
		if texture_key == floor_test_asset_key:
			wall_catalog_path = resolve_gray_test_asset_path(texture_key)
			wall_catalog_available = resource_exists(wall_catalog_path)
		elif texture_key.begins_with("wall_"):
			if wall_catalog.has(texture_key):
				wall_catalog_path = resolve_gray_test_asset_path(texture_key) if texture_key.begins_with("wall_gray_") else VisualAssetCatalogRef.get_asset_path(texture_key)
				wall_catalog_available = resource_exists(wall_catalog_path)
		elif texture_key.begins_with("ground_"):
			if ground_catalog.has(texture_key):
				ground_catalog_path = VisualAssetCatalogRef.get_asset_path(texture_key)
				ground_catalog_available = resource_exists(ground_catalog_path)
		elif placeholder_enabled and not placeholder_path.is_empty() and not gray_test_placeholder_object_skipped:
			placeholder_available = resource_exists(placeholder_path)
		var object_png_path: String = resolve_object_png_path(texture_key)
		var object_png_available: bool = resource_exists(object_png_path, "Texture2D")
		var active_texture_source: String = "none"
		if object_png_available:
			active_texture_source = "object_png"
		elif wall_catalog_available:
			active_texture_source = "wall_catalog"
		elif ground_catalog_available:
			active_texture_source = "ground_catalog"
		elif has_explicit_texture:
			active_texture_source = "explicit"
		elif gray_test_placeholder_object_skipped:
			active_texture_source = "gray_test_placeholder_object_skipped"
		elif placeholder_enabled and placeholder_available:
			active_texture_source = "placeholder"
		debug_state[texture_key] = {
			"has_explicit_texture": has_explicit_texture,
			"placeholder_path": placeholder_path,
			"placeholder_available": placeholder_available,
			"gray_test_placeholder_object_skipped": gray_test_placeholder_object_skipped,
			"object_png_path": object_png_path,
			"object_png_available": object_png_available,
			"wall_catalog_path": wall_catalog_path,
			"wall_catalog_available": wall_catalog_available,
			"ground_catalog_path": ground_catalog_path,
			"ground_catalog_available": ground_catalog_available,
			"active_texture_source": active_texture_source
		}
	return debug_state

func validate_object_png_assets(visual_ids: Array[String]) -> Dictionary:
	var missing_paths: Array[Dictionary] = []
	var invalid_textures: Array[Dictionary] = []
	var svg_conflicts: Array[Dictionary] = []
	var assets: Dictionary = {}
	for visual_id in visual_ids:
		var expected_path: String = resolve_object_png_path(visual_id)
		var exists: bool = resource_exists(expected_path)
		var loads_as_texture: bool = resource_exists(expected_path, "Texture2D")
		assets[visual_id] = {
			"path": expected_path,
			"exists": exists,
			"loads_as_texture": loads_as_texture,
			"resolver": "object_png"
		}
		if expected_path.is_empty() or not exists:
			missing_paths.append({"visual_id": visual_id, "expected_path": expected_path})
		elif not loads_as_texture:
			invalid_textures.append({"visual_id": visual_id, "expected_path": expected_path})
		var placeholder_path: String = resolve_placeholder_path(visual_id)
		if not placeholder_path.is_empty() and is_placeholder_object_texture_path(placeholder_path):
			svg_conflicts.append({"visual_id": visual_id, "png_path": expected_path, "svg_path": placeholder_path})
	return {
		"ok": missing_paths.is_empty() and invalid_textures.is_empty() and svg_conflicts.is_empty(),
		"asset_count": visual_ids.size(),
		"assets": assets,
		"missing_paths": missing_paths,
		"invalid_textures": invalid_textures,
		"svg_conflicts": svg_conflicts,
		"fallback": "magenta_black_missing_asset_debug_checker"
	}

func clear_all_caches() -> void:
	for cache_namespace_variant in _texture_caches.keys():
		var cache_namespace: String = str(cache_namespace_variant)
		var cache: Dictionary = _get_cache(cache_namespace)
		cache.clear()

func get_cache_debug_state() -> Dictionary:
	var result: Dictionary = {}
	for cache_namespace_variant in _texture_caches.keys():
		var cache_namespace: String = str(cache_namespace_variant)
		var cache: Dictionary = _get_cache(cache_namespace)
		result[cache_namespace] = {
			"size": cache.size(),
			"keys": cache.keys().duplicate()
		}
	return result

func _load_catalog_texture(cache_namespace: String, asset_key: String) -> Texture2D:
	var normalized_asset_key: String = str(asset_key).strip_edges().to_lower()
	if normalized_asset_key.is_empty():
		return null
	var cache: Dictionary = _get_cache(cache_namespace)
	if cache.has(normalized_asset_key):
		return _as_texture(cache.get(normalized_asset_key))
	var texture_path: String = VisualAssetCatalogRef.get_asset_path(normalized_asset_key)
	if texture_path.is_empty():
		cache[normalized_asset_key] = null
		return null
	if ResourceLoader.exists(texture_path):
		var loaded_resource: Resource = ResourceLoader.load(texture_path)
		if loaded_resource is Texture2D:
			var loaded_texture: Texture2D = loaded_resource as Texture2D
			cache[normalized_asset_key] = loaded_texture
			return loaded_texture
	cache[normalized_asset_key] = null
	return null

func _get_cache(cache_namespace: String) -> Dictionary:
	var normalized_namespace: String = cache_namespace.strip_edges().to_lower()
	if not _texture_caches.has(normalized_namespace):
		_texture_caches[normalized_namespace] = {}
	var cache: Dictionary = _texture_caches[normalized_namespace]
	return cache

func _as_dictionary(value: Variant) -> Dictionary:
	return Dictionary(value) if value is Dictionary else {}

func _as_texture(value: Variant) -> Texture2D:
	return value as Texture2D if value is Texture2D else null
