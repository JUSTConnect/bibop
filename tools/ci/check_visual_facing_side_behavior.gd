extends SceneTree

const DescriptorService = preload("res://scripts/visual/canonical_visual_descriptor_service.gd")
const VisualStateAssetService = preload("res://scripts/visual/visual_state_asset_service.gd")
const ObjectRenderer = preload("res://scripts/visual/renderer/object_renderer.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_fail("%s: expected=%s actual=%s" % [message, str(expected), str(actual)])


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail(message)


func _cooling_object(side: String) -> Dictionary:
	return {
		"object_type": "air_cooling",
		"visual_family": "air_cooling",
		"visual_state_policy": "powered_three_state",
		"visual_surface": "floor",
		"mount": "floor",
		"facing_side": side,
		"is_powered": true,
		"is_on": true,
	}


func _assert_direction(side: String, expected_descriptor_side: String, expected_asset: String, expected_mirror: bool, expected_source: String) -> void:
	var object_data: Dictionary = _cooling_object(side)
	var descriptor: Dictionary = DescriptorService.build_descriptor(object_data)
	var state_descriptor: Dictionary = VisualStateAssetService.resolve_visual_asset_descriptor(object_data)
	var renderer_asset: String = ObjectRenderer.get_asset_key_for_object_data(object_data, "generic_object")
	_assert_true(DescriptorService.is_valid_descriptor(descriptor), "descriptor is valid for %s" % side)
	_assert_equal(descriptor.get(DescriptorService.FIELD_FACING_SIDE, ""), expected_descriptor_side, "descriptor normalizes facing side for %s" % side)
	_assert_equal(descriptor.get(DescriptorService.FIELD_VISUAL_VARIANT, ""), expected_source, "descriptor stores source variant for %s" % side)
	_assert_equal(state_descriptor.get("visual_asset_id", ""), expected_asset, "state descriptor asset for %s" % side)
	_assert_equal(bool(state_descriptor.get("mirror_h", false)), expected_mirror, "state descriptor mirror for %s" % side)
	_assert_equal(renderer_asset, expected_asset, "ObjectRenderer asset for %s" % side)


func _init() -> void:
	_assert_direction("SW", "sw", "air_cooling_on_floor_sw_01", false, "sw")
	_assert_direction("SE", "se", "air_cooling_on_floor_sw_01", true, "sw")
	_assert_direction("NE", "ne", "air_cooling_on_floor_ne_01", false, "ne")
	_assert_direction("NW", "nw", "air_cooling_on_floor_ne_01", true, "ne")
	print("VISUAL_FACING_SIDE_BEHAVIOR: OK")
	quit(0)
