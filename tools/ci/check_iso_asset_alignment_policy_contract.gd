extends SceneTree

const PolicyRef = preload("res://scripts/visual/renderer/iso_asset_alignment_policy.gd")
const VisualAssetCatalogRef = preload("res://scripts/visual/visual_asset_catalog.gd")
const IsoProjectionServiceRef = preload("res://scripts/visual/renderer/iso_projection_service.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_alignment_rules()
	_check_cooling_layout()
	_check_outer_utility_layout()
	_check_duplicate_safety_and_catalog_ownership()
	var exit_code: int = 0
	if failures.is_empty():
		print("IsoAssetAlignmentPolicy contract OK")
	else:
		exit_code = 1
		for failure in failures:
			push_error(failure)
	quit(exit_code)

func _check_alignment_rules() -> void:
	_expect_rule("floor_default", "center", 1.0, Vector2.ZERO, IsoProjectionServiceRef.STANDARD_TILE_SIZE, "floor")
	_expect_rule("wall_default", "wall_cell_base", 1.0, Vector2(0, -32), Vector2(128, 120), "wall")
	_expect_rule("object_key", "bottom_center", 0.55, Vector2(0, -6), Vector2(96, 96), "object")
	_expect_rule("object_terminal", "wall_mount_center", 0.8, Vector2(0, -18), Vector2(96, 96), "object")
	_expect_rule("object_socket", "wall_mount_center", 0.8, Vector2(0, -18), Vector2(96, 96), "object")
	_expect(not PolicyRef.has_alignment_rule("unknown_asset"), "unknown asset unexpectedly has a rule")
	_expect(PolicyRef.get_alignment_rule("unknown_asset").is_empty(), "unknown rule must be empty")
	_expect(PolicyRef.get_expected_size("unknown_asset", Vector2(7, 9)) == Vector2(7, 9), "unknown expected-size fallback changed")
	_expect(PolicyRef.get_anchor("unknown_asset", "fallback_anchor") == "fallback_anchor", "unknown anchor fallback changed")
	_expect(is_equal_approx(PolicyRef.get_scale("unknown_asset", 1.25), 1.25), "unknown scale fallback changed")
	_expect(PolicyRef.get_offset("unknown_asset", Vector2(3, 4)) == Vector2(3, 4), "unknown offset fallback changed")
	_expect(PolicyRef.get_layer_hint("unknown_asset", "fallback_layer") == "fallback_layer", "unknown layer fallback changed")
	var normalized_floor: Dictionary = PolicyRef.normalize_runtime_rule("floor_default", PolicyRef.get_alignment_rule("floor_default"), Vector2(144, 80), Vector2(72, 40), IsoProjectionServiceRef.CLASSIC_TILE_SIZE)
	_expect(PolicyRef.get_rule_expected_size(normalized_floor, Vector2.ZERO) == Vector2(144, 80), "runtime floor expected-size normalization changed")
	var normalized_wall: Dictionary = PolicyRef.normalize_runtime_rule("wall_default", PolicyRef.get_alignment_rule("wall_default"), Vector2(144, 80), Vector2(72, 40), IsoProjectionServiceRef.CLASSIC_TILE_SIZE)
	_expect(PolicyRef.get_rule_offset(normalized_wall, Vector2.ZERO) == Vector2(0, -40), "runtime wall offset normalization changed")
	_expect(PolicyRef.get_anchor_offset("wall_cell_base", Vector2(96, 120)) == Vector2(48, 120), "wall base anchor offset changed")

func _check_cooling_layout() -> void:
	_expect(PolicyRef.get_cooling_wall_face_region("sw") == Rect2(0.0, 0.0, 0.5, 1.0), "SW cooling face region changed")
	_expect(PolicyRef.get_cooling_wall_face_region("se") == Rect2(0.5, 0.0, 0.5, 1.0), "SE cooling face region changed")
	_expect(PolicyRef.get_cooling_wall_face_region("unknown") == Rect2(0.0, 0.0, 1.0, 1.0), "unknown cooling face fallback changed")
	_expect(PolicyRef.get_cooling_wall_canvas_region("sw", Vector2(512, 256)) == Rect2(0, 0, 256, 256), "SW cooling canvas formula changed")
	_expect(PolicyRef.get_cooling_wall_canvas_region("se", Vector2(512, 256)) == Rect2(256, 0, 256, 256), "SE cooling canvas formula changed")
	_expect(is_equal_approx(PolicyRef.OUTER_UTILITY_WIDTH_SCALE, 5.0), "outer utility width scale changed")
	_expect(is_equal_approx(PolicyRef.OUTER_UTILITY_HEIGHT_SCALE, 2.0), "outer utility height scale changed")
	_expect(is_equal_approx(PolicyRef.OUTER_UTILITY_VERTICAL_OFFSET_SCALE, 2.0), "outer utility vertical offset changed")

func _check_outer_utility_layout() -> void:
	var segment: Dictionary = {"mid": Vector2(10, 20), "normal": Vector2(0, -1), "start_edge": Vector2(0, 20), "end_edge": Vector2(20, 20)}
	var water: Dictionary = PolicyRef.build_outer_utility_layout({"segment": segment, "kind": "water_pipe", "base_width": 4.0})
	_expect(Vector2(water.get("center", Vector2.ZERO)) == Vector2(10, 18), "water utility center changed")
	_expect(Vector2(water.get("start", Vector2.ZERO)) == Vector2(0, 20), "water utility start changed")
	_expect(Vector2(water.get("end", Vector2.ZERO)) == Vector2(20, 20), "water utility end changed")
	_expect(is_equal_approx(float(water.get("base_width", 0.0)), 20.0), "water base width changed")
	_expect(is_equal_approx(float(water.get("primary_width", 0.0)), 20.0), "water primary width changed")
	_expect(is_equal_approx(float(water.get("secondary_width", 0.0)), 12.4), "water secondary width changed")
	var duct: Dictionary = PolicyRef.build_outer_utility_layout({"segment": segment, "kind": "air_duct", "base_width": 4.0})
	_expect(is_equal_approx(float(duct.get("primary_width", 0.0)), 40.0), "duct primary width changed")
	_expect(is_equal_approx(float(duct.get("secondary_width", 0.0)), 31.0), "duct secondary width changed")
	var malformed: Dictionary = PolicyRef.build_outer_utility_layout({"segment": "invalid", "base_width": "invalid"})
	_expect(Vector2(malformed.get("center", Vector2.INF)) == Vector2(0, -2), "malformed utility context fallback changed")
	_expect(is_equal_approx(float(malformed.get("base_width", 0.0)), 20.0), "malformed utility width fallback changed")

func _check_duplicate_safety_and_catalog_ownership() -> void:
	var rule: Dictionary = PolicyRef.get_alignment_rule("object_key")
	rule["scale"] = 99.0
	_expect(is_equal_approx(PolicyRef.get_scale("object_key", 0.0), 0.55), "alignment rule getter exposes mutable policy data")
	var rule_ids: Array[String] = PolicyRef.get_alignment_rule_ids()
	rule_ids.clear()
	_expect(not PolicyRef.get_alignment_rule_ids().is_empty(), "alignment rule id getter exposes mutable policy data")
	var visual_ids: Array[String] = VisualAssetCatalogRef.get_canonical_object_visual_ids()
	_expect("power_source_01" in visual_ids, "canonical visual ids lost power_source_01")
	_expect("terminal_01" in visual_ids, "canonical visual ids lost terminal_01")
	_expect("radiator_floor_01" in visual_ids, "canonical visual ids lost radiator_floor_01")
	visual_ids.clear()
	_expect(not VisualAssetCatalogRef.get_canonical_object_visual_ids().is_empty(), "canonical visual id getter exposes mutable catalog data")

func _expect_rule(asset_key: String, anchor: String, scale_value: float, offset: Vector2, expected_size: Vector2, layer_hint: String) -> void:
	var rule: Dictionary = PolicyRef.get_alignment_rule(asset_key)
	_expect(not rule.is_empty(), "%s rule missing" % asset_key)
	_expect(PolicyRef.get_rule_anchor(rule, "") == anchor, "%s anchor changed" % asset_key)
	_expect(is_equal_approx(PolicyRef.get_rule_scale(rule, 0.0), scale_value), "%s scale changed" % asset_key)
	_expect(PolicyRef.get_rule_offset(rule, Vector2.INF) == offset, "%s offset changed" % asset_key)
	_expect(PolicyRef.get_rule_expected_size(rule, Vector2.ZERO) == expected_size, "%s expected size changed" % asset_key)
	_expect(str(rule.get("layer_hint", "")) == layer_hint, "%s layer hint changed" % asset_key)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
