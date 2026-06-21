extends SceneTree

const Projection = preload("res://scripts/visual/renderer/iso_projection_service.gd")
const DrawEntry = preload("res://scripts/visual/renderer/iso_draw_entry_contract.gd")
const RendererScript = preload("res://scripts/field/room_visual_renderer.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_projection_modes()
	_check_projection_round_trip()
	_check_draw_entry_contract()
	_check_renderer_delegation()
	if failures.is_empty():
		print("Renderer projection and draw-entry contract OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_projection_modes() -> void:
	_expect(Projection.normalize_mode(Projection.PROJECTION_PREVIEW_181) == Projection.PROJECTION_STANDARD, "preview alias must normalize to standard")
	_expect(Projection.normalize_mode("missing") == Projection.PROJECTION_STANDARD, "unknown projection must fail to standard")
	_expect(Projection.get_tile_size(Projection.PROJECTION_STANDARD, 1.0, 1.0) == Vector2(128.0, 71.0), "standard tile size changed")
	_expect(Projection.get_tile_size(Projection.PROJECTION_CLASSIC, 1.0, 1.0) == Vector2(128.0, 64.0), "classic tile size changed")
	_expect(Projection.get_tile_size(Projection.PROJECTION_CUSTOM, -3.0, 0.0) == Vector2(1.0, 1.0), "custom tile size must clamp")
	var flat_half: Vector2 = Projection.get_tile_half_size(Vector2(128.0, 71.0), 0.0)
	_expect(flat_half == Vector2(64.0, 35.5), "standard half tile changed")
	var pitched_half: Vector2 = Projection.get_tile_half_size(Vector2(128.0, 71.0), 4.0)
	_expect(is_equal_approx(pitched_half.x, 64.0) and pitched_half.y > flat_half.y, "pitch correction must preserve width and raise vertical half-size")

func _check_projection_round_trip() -> void:
	var origin := Vector2(17.0, -9.0)
	var half := Vector2(64.0, 35.5)
	for cell in [Vector2i.ZERO, Vector2i(1, 1), Vector2i(4, 2), Vector2i(2, 5)]:
		var screen := Projection.grid_to_iso(cell, origin, half)
		_expect(Projection.iso_to_grid(screen, origin, half) == cell, "grid/iso round-trip failed for %s" % cell)
	var diamond := Projection.get_diamond_points(Vector2i(2, 1), origin, half)
	_expect(diamond.size() == 4, "diamond must have four points")
	var inset := Projection.get_inset_diamond_points(Vector2i(2, 1), 6.0, origin, half)
	_expect(inset.size() == 4, "inset diamond must have four points")
	for index in range(4):
		_expect(inset[index].distance_to(Projection.grid_to_iso(Vector2i(2, 1), origin, half)) < diamond[index].distance_to(Projection.grid_to_iso(Vector2i(2, 1), origin, half)), "inset point must move toward center")

func _check_draw_entry_contract() -> void:
	var base_depth := Projection.get_depth_key(Vector2i(1, 1), Vector2.ZERO, Vector2(64.0, 35.5))
	var floor_entry := DrawEntry.make_entry(Vector2i(1, 1), "floor", "floor", base_depth, DrawEntry.SUB_ORDER_FLOOR, {"tile_type": 0})
	var item_entry := DrawEntry.make_entry(Vector2i(1, 1), "item", "object", base_depth, DrawEntry.SUB_ORDER_ITEM, {})
	var wall_entry := DrawEntry.make_entry(Vector2i(1, 1), "wall", "wall_body", base_depth, DrawEntry.SUB_ORDER_WALL_BODY, {}, DrawEntry.LAYER_BIAS_WALL)
	_expect(DrawEntry.validate_entry(floor_entry).is_empty(), "valid floor entry rejected")
	_expect(not DrawEntry.validate_entry({}).is_empty(), "empty entry must be rejected")
	_expect(DrawEntry.less(floor_entry, item_entry, 0.0, 0.0), "floor must sort before item at equal depth")
	_expect(DrawEntry.less(item_entry, wall_entry, 0.0, 0.0), "item must sort before wall body at equal depth")
	var tie_a := DrawEntry.make_entry(Vector2i(2, 0), "floor", "floor", base_depth, 0.0, {})
	var tie_b := DrawEntry.make_entry(Vector2i(1, 1), "floor", "floor", base_depth, 0.0, {})
	_expect(DrawEntry.less(tie_a, tie_b, 0.0, 0.0), "equal-depth cell tie-break changed")
	var deeper := DrawEntry.make_entry(Vector2i(2, 1), "floor", "floor", base_depth + 35.5, 0.0, {})
	_expect(DrawEntry.less(wall_entry, deeper, 0.0, 0.0), "depth must dominate sub-order")

func _check_renderer_delegation() -> void:
	var renderer := RendererScript.new()
	renderer.iso_projection_mode = Projection.PROJECTION_PREVIEW_181
	renderer.iso_origin = Vector2(11.0, 7.0)
	renderer.iso_floor_projection_pitch_correction_degrees = 0.0
	_expect(renderer.get_iso_projection_mode() == Projection.PROJECTION_STANDARD, "renderer projection mode delegation changed")
	_expect(renderer.get_iso_tile_size() == Projection.STANDARD_TILE_SIZE, "renderer tile-size delegation changed")
	var cell := Vector2i(3, 2)
	var expected := Projection.grid_to_iso(cell, renderer.iso_origin, Projection.get_tile_half_size(Projection.STANDARD_TILE_SIZE, 0.0))
	_expect(renderer.grid_to_iso(cell) == expected, "renderer grid projection delegation changed")
	_expect(renderer.iso_to_grid(expected) == cell, "renderer inverse projection delegation changed")
	renderer.free()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
