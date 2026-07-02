extends SceneTree

const DescriptorService = preload("res://scripts/visual/canonical_visual_descriptor_service.gd")
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


func _init() -> void:
	var explicit_object: Dictionary = {
		"object_type": "crate",
		"visual_asset_id": "normal_crate_floor_01",
		"visual_surface": "floor",
		"visual_state_policy": "static",
		"mount": "floor",
		"facing_side": "NE",
	}
	var descriptor: Dictionary = DescriptorService.build_descriptor(explicit_object)
	_assert_true(DescriptorService.is_valid_descriptor(descriptor), "explicit visual descriptor should be valid")
	_assert_equal(descriptor.get(DescriptorService.FIELD_VISUAL_ASSET_ID, ""), "normal_crate_floor_01", "descriptor keeps explicit visual asset")
	_assert_equal(descriptor.get(DescriptorService.FIELD_VISUAL_SURFACE, ""), "floor", "descriptor normalizes visual surface")
	_assert_equal(descriptor.get(DescriptorService.FIELD_MOUNT, ""), "floor", "descriptor normalizes mount")
	_assert_equal(descriptor.get(DescriptorService.FIELD_FACING_SIDE, ""), "ne", "descriptor normalizes facing side")

	var renderer_asset: String = ObjectRenderer.get_asset_key_for_object_data(explicit_object, "generic_object")
	_assert_equal(renderer_asset, descriptor.get(DescriptorService.FIELD_VISUAL_ASSET_ID, ""), "ObjectRenderer uses canonical descriptor asset")

	var legacy_object: Dictionary = {"object_type": "terminal"}
	_assert_equal(ObjectRenderer.get_canonical_visual_asset_key(legacy_object), "", "legacy object without descriptor stays off descriptor path")
	_assert_equal(ObjectRenderer.get_asset_key_for_object_data(legacy_object, "generic_object"), "terminal_01", "legacy fallback rendering remains unchanged")

	print("CANONICAL_VISUAL_DESCRIPTOR_BEHAVIOR: OK")
	quit(0)
