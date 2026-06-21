extends SceneTree

const SurfaceCatalog = preload("res://scripts/world/surface_material_catalog.gd")
const HeightCatalog = preload("res://scripts/world/wall_height_catalog.gd")
const VisualCatalog = preload("res://scripts/visual/visual_asset_catalog.gd")
const MissionManagerScript = preload("res://scripts/game/mission_manager.gd")
const PresetService = preload("res://scripts/game/map_constructor_preset_service.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_domain_catalogs()
	_check_height_catalogs()
	_check_visual_separation()
	_check_legacy_snapshot_round_trip()
	if failures.is_empty():
		print("Surface material and height catalog contract OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_domain_catalogs() -> void:
	_expect(SurfaceCatalog.validate_catalog().is_empty(), "surface catalog validation must pass")
	_expect(SurfaceCatalog.normalize_wall_material_id("default_metal") == "concrete", "default_metal alias must resolve")
	_expect(SurfaceCatalog.normalize_wall_material_id("power_room") == "reinforced_steel", "power_room alias must resolve")
	_expect(SurfaceCatalog.normalize_wall_material_id("outer_wall") == "outerwall", "outer_wall alias must resolve")
	_expect(SurfaceCatalog.normalize_floor_material_id("titanium_default", "") == "titan", "titanium floor alias must resolve")
	_expect(SurfaceCatalog.normalize_floor_material_id("power_floor", "") == "steel", "power floor alias must resolve")
	_expect(not SurfaceCatalog.is_known_wall_material_id("missing_wall_material"), "unknown wall material must fail closed")
	_expect(not SurfaceCatalog.is_known_floor_material_id("missing_floor_material"), "unknown floor material must fail closed")
	for material_id in ["breachable_concrete", "breachable_brick"]:
		_expect(SurfaceCatalog.is_breachable_wall_material(material_id), "%s must remain breachable" % material_id)
		_expect(SurfaceCatalog.get_allowed_wall_heights(material_id) == ["mid", "halfmid", "tall"], "%s breach heights must remain stable" % material_id)

func _check_height_catalogs() -> void:
	_expect(HeightCatalog.validate_catalog().is_empty(), "height catalog validation must pass")
	_expect(HeightCatalog.normalize_wall_height("highest") == "tall", "highest wall alias must resolve")
	_expect(HeightCatalog.normalize_wall_height("half-medium") == "halfmid", "half-medium wall alias must resolve")
	_expect(HeightCatalog.normalize_wall_height("half_low") == "halflow", "half-low wall alias must resolve")
	_expect(HeightCatalog.normalize_floor_height("groundlow") == "step_1", "groundlow floor alias must resolve")
	_expect(HeightCatalog.normalize_floor_height("ground_halflow") == "step_2", "ground halflow alias must resolve")
	_expect(not HeightCatalog.is_known_wall_height("missing_height"), "unknown wall height must fail closed")

func _check_visual_separation() -> void:
	var wall_domain := SurfaceCatalog.get_wall_material("breachable_concrete")
	_expect(not wall_domain.has("texture_asset_id"), "domain material must not contain texture id")
	_expect(not wall_domain.has("fallback_color"), "domain material must not contain fallback color")
	var decorated := VisualCatalog.decorate_surface_material_catalog(SurfaceCatalog.get_wall_catalog(), "wall")
	var decorated_breachable: Dictionary = {}
	for row_variant in Array(decorated.get("materials", [])):
		var row := Dictionary(row_variant)
		if str(row.get("id", "")) == "breachable_concrete":
			decorated_breachable = row
			break
	_expect(str(decorated_breachable.get("texture_asset_id", "")) == "wall_concrete", "visual owner must decorate surface rows")
	_expect(VisualCatalog.resolve_legacy_mission_asset_id("Fuse_box", "object") == "fuse_box_out_01", "legacy object alias must resolve")
	_expect(VisualCatalog.resolve_legacy_mission_asset_id("power_floor", "floor") == "floor_steel", "legacy floor asset must resolve")
	_expect(VisualCatalog.resolve_wall_asset_key_for_material_and_height("breachable_brick", "tall") == "wall_brick_tall", "wall material/height asset must resolve")
	_expect(VisualCatalog.resolve_wall_asset_key_for_material_and_height("grate", "low") == "wall_grate_mid", "grate low height must normalize to mid")

func _check_legacy_snapshot_round_trip() -> void:
	var manager := MissionManagerScript.new()
	var snapshot := {
		"_map_constructor_wall_material_overrides": {
			"1,1|north": {"cell": Vector2i(1, 1), "side": "north", "material_id": "default_metal", "wall_visual_height": "highest"}
		},
		"_map_constructor_floor_material_overrides": {
			"2,2": {"cell": Vector2i(2, 2), "material_id": "titanium_default", "ground_height": "ground_halflow"}
		}
	}
	var result := PresetService.apply_snapshot_to_owner(manager, snapshot)
	_expect(bool(result.get("ok", false)), "preset snapshot apply must succeed")
	var wall_row := Dictionary(Dictionary(manager.get("_map_constructor_wall_material_overrides")).get("1,1|north", {}))
	_expect(str(wall_row.get("material_id", "")) == "concrete", "legacy wall material must restore canonically")
	_expect(str(wall_row.get("wall_height", "")) == "tall", "legacy wall height must restore canonically")
	_expect(not wall_row.has("wall_visual_height"), "legacy wall height key must be removed")
	var floor_row := Dictionary(Dictionary(manager.get("_map_constructor_floor_material_overrides")).get("2,2", {}))
	_expect(str(floor_row.get("material_id", "")) == "titan", "legacy floor material must restore canonically")
	_expect(str(floor_row.get("floor_height", "")) == "step_2", "legacy floor height must restore canonically")
	manager.free()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
