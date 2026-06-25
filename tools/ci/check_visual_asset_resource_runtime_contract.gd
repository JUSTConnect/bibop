extends SceneTree

const RuntimeRef = preload("res://scripts/visual/renderer/visual_asset_resource_runtime.gd")
const VisualAssetCatalogRef = preload("res://scripts/visual/visual_asset_catalog.gd")

var failures: Array[String] = []
var runtime = RuntimeRef.new()

func _initialize() -> void:
	_check_path_resolution()
	_check_cached_and_uncached_loads()
	_check_placeholder_and_optional_loads()
	_check_wall_and_breach_resolution()
	_check_cache_invalidation()
	var exit_code: int = 0
	if failures.is_empty():
		print("VisualAssetResourceRuntime contract OK")
	else:
		exit_code = 1
		for failure in failures:
			push_error(failure)
	quit(exit_code)

func _check_path_resolution() -> void:
	var object_path: String = runtime.resolve_object_png_path("power_switcher_off_01")
	_expect(object_path == VisualAssetCatalogRef.get_asset_path("power_switcher_off_01"), "canonical object PNG path changed")
	_expect(runtime.is_object_png_asset_key("power_switcher_off_01"), "canonical object PNG key not recognized")
	_expect(not runtime.is_object_png_asset_key("object_generic"), "SVG placeholder recognized as object PNG")
	var legacy_path: String = "res://assets/visual/isometric/objects/power_switcher_off_01.png"
	var migrated_path: String = runtime.resolve_object_png_path("legacy_unknown", {"path": legacy_path})
	_expect(migrated_path == "res://assets/visual/isometric/objects/power_swicher/power_swicher_off_floor.png", "legacy object path migration changed")
	_expect(runtime.resolve_placeholder_path("object_generic") == VisualAssetCatalogRef.get_asset_path("object_generic"), "placeholder path resolution changed")
	_expect(runtime.is_placeholder_object_texture_asset_key("object_generic"), "object placeholder classification changed")
	_expect(runtime.resolve_gray_test_asset_path("floor_gray_test") == VisualAssetCatalogRef.get_asset_path("floor_gray_test"), "gray test path resolution changed")
	_expect(runtime.resolve_gray_test_asset_path("floor_concrete").is_empty(), "non-test asset resolved as gray test asset")

func _check_cached_and_uncached_loads() -> void:
	var initial_state: Dictionary = runtime.get_cache_debug_state()
	_expect(_cache_size(initial_state, RuntimeRef.CACHE_FLOOR) == 0, "floor cache must start empty")
	var first_floor: Texture2D = runtime.get_floor_texture("floor_concrete")
	_expect(first_floor != null, "uncached floor texture did not load")
	var after_first: Dictionary = runtime.get_cache_debug_state()
	_expect(_cache_size(after_first, RuntimeRef.CACHE_FLOOR) == 1, "floor texture was not cached")
	var second_floor: Texture2D = runtime.get_floor_texture("floor_concrete")
	_expect(second_floor == first_floor, "cached floor texture identity changed")
	_expect(_cache_size(runtime.get_cache_debug_state(), RuntimeRef.CACHE_FLOOR) == 1, "cached floor lookup created duplicate entry")
	var ground_texture: Texture2D = runtime.get_ground_texture("ground_low")
	_expect(ground_texture != null, "ground texture did not load")
	_expect(_cache_size(runtime.get_cache_debug_state(), RuntimeRef.CACHE_GROUND) == 1, "ground texture was not cached")
	var object_texture: Texture2D = runtime.get_object_png_texture("power_switcher_off_01")
	_expect(object_texture != null, "object PNG texture did not load")
	_expect(_cache_size(runtime.get_cache_debug_state(), RuntimeRef.CACHE_OBJECT_PNG) == 1, "object PNG texture was not cached")
	var missing_object: Texture2D = runtime.get_object_png_texture_for_resolved_path("missing_runtime_contract", "res://missing/runtime_contract.png")
	_expect(missing_object == null, "missing object PNG unexpectedly loaded")
	_expect(_cache_size(runtime.get_cache_debug_state(), RuntimeRef.CACHE_OBJECT_PNG) == 2, "missing object PNG was not negatively cached")

func _check_placeholder_and_optional_loads() -> void:
	var placeholder: Texture2D = runtime.get_placeholder_texture("object_generic", true, false)
	_expect(placeholder != null, "placeholder texture did not load")
	_expect(_cache_size(runtime.get_cache_debug_state(), RuntimeRef.CACHE_PLACEHOLDER) == 1, "placeholder texture was not cached")
	_expect(runtime.get_placeholder_texture("object_generic", false, false) == null, "disabled placeholder unexpectedly loaded")
	_expect(runtime.get_placeholder_texture("object_generic", true, true) == null, "skipped placeholder unexpectedly loaded")
	var optional_path: String = VisualAssetCatalogRef.get_asset_path("floor_concrete")
	_expect(runtime.load_optional_texture("floor_concrete", optional_path, false) != null, "optional texture load failed")
	_expect(runtime.load_optional_texture("missing_optional", "res://missing/optional_texture.png", false) == null, "missing optional texture unexpectedly loaded")
	_expect(not runtime.resource_exists("res://missing/optional_texture.png"), "missing optional texture exists probe changed")

func _check_wall_and_breach_resolution() -> void:
	var wall_catalog: Dictionary = {"wall_concrete_mid": "wall_concrete_mid_01.png"}
	var wall_texture: Texture2D = runtime.resolve_wall_texture("wall_concrete_mid", wall_catalog, null, null)
	_expect(wall_texture != null, "wall catalog texture did not load")
	_expect(_cache_size(runtime.get_cache_debug_state(), RuntimeRef.CACHE_WALL) == 1, "wall texture was not cached")
	var breach_texture: Texture2D = runtime.get_breach_overlay_texture("breach_overlay_concrete_sw")
	_expect(breach_texture != null, "breach overlay texture did not load")
	_expect(_cache_size(runtime.get_cache_debug_state(), RuntimeRef.CACHE_BREACH_OVERLAY) == 1, "breach overlay was not cached")
	var image: Image = Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var explicit_texture: Texture2D = ImageTexture.create_from_image(image)
	_expect(runtime.resolve_wall_texture("wall_unknown", {}, explicit_texture, explicit_texture) == explicit_texture, "wall explicit fallback ordering changed")
	_expect(runtime.resolve_wall_texture("wall_gray_unknown", {}, explicit_texture, explicit_texture) == null, "gray wall unexpectedly used explicit fallback")
	var generic_explicit: Texture2D = runtime.resolve_texture("object_generic", {"explicit_texture": explicit_texture, "placeholder_enabled": true})
	_expect(generic_explicit == explicit_texture, "explicit texture precedence changed")

func _check_cache_invalidation() -> void:
	var populated: Dictionary = runtime.get_cache_debug_state()
	_expect(_total_cache_size(populated) > 0, "resource runtime caches were not populated before invalidation")
	runtime.clear_all_caches()
	var cleared: Dictionary = runtime.get_cache_debug_state()
	_expect(_total_cache_size(cleared) == 0, "cache invalidation left resource entries behind")
	for cache_namespace in [
		RuntimeRef.CACHE_FLOOR,
		RuntimeRef.CACHE_GROUND,
		RuntimeRef.CACHE_WALL,
		RuntimeRef.CACHE_BREACH_OVERLAY,
		RuntimeRef.CACHE_OBJECT_PNG,
		RuntimeRef.CACHE_PLACEHOLDER
	]:
		_expect(_cache_size(cleared, cache_namespace) == 0, "%s cache was not cleared" % cache_namespace)

func _cache_size(state: Dictionary, cache_namespace: String) -> int:
	var cache_state_variant: Variant = state.get(cache_namespace, {})
	if not (cache_state_variant is Dictionary):
		return -1
	return int(Dictionary(cache_state_variant).get("size", -1))

func _total_cache_size(state: Dictionary) -> int:
	var total: int = 0
	for cache_namespace_variant in state.keys():
		total += maxi(_cache_size(state, str(cache_namespace_variant)), 0)
	return total

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
