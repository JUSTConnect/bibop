extends SceneTree

const Catalog = preload("res://scripts/bipob/bipob_module_catalog.gd")
const Factory = preload("res://scripts/bipob/bipob_module_factory.gd")

var failures: Array[String] = []

func _init() -> void:
	var validation: Dictionary = Catalog.validate_catalog()
	_expect(bool(validation.get("valid", false)), "catalog validation must succeed")
	_expect(int(validation.get("external_count", 0)) > 0, "external catalog must not be empty")
	_expect(int(validation.get("internal_count", 0)) > 0, "internal catalog must not be empty")

	var canonical: BipobModule = Factory.create_external_module("manipulator_arm_v1")
	var alias: BipobModule = Factory.create_external_module("manipulator_v1")
	_expect(canonical != null and alias != null, "manipulator ids must hydrate")
	if canonical != null and alias != null:
		_expect(alias.id == canonical.id, "legacy alias must resolve to canonical id")
		_expect(alias.external_width == canonical.external_width, "alias width must match")
		_expect(alias.external_height == canonical.external_height, "alias height must match")
		_expect(alias.allowed_external_sides == canonical.allowed_external_sides, "alias sides must match")

	var interface_alias: BipobModule = Factory.create_external_module("interface_v1")
	_expect(interface_alias != null and interface_alias.id == "external_interface_connector_v1", "interface alias must remain supported")
	_expect(Factory.create_external_module("catalog_missing_external") == null, "unknown external id must fail closed")

	var battery: BipobModule = Factory.create_internal_module("battery_v3")
	_expect(battery != null, "battery_v3 must hydrate")
	if battery != null:
		_expect(battery.internal_role == "battery", "battery role must hydrate")
		_expect(battery.module_version == 3, "battery version must hydrate")
		_expect(battery.battery_capacity == 50, "battery capacity must hydrate")
		_expect(battery.internal_size == Vector3i(2, 2, 1), "battery size must hydrate")

	var gpu: BipobModule = Factory.create_internal_module("gpu_v2")
	_expect(gpu != null, "gpu_v2 must hydrate")
	if gpu != null:
		_expect(gpu.sensor_range_bonus == 5, "gpu range bonus must hydrate")
		_expect(gpu.sensor_visibility_bonus == 30, "gpu visibility bonus must hydrate")

	_expect(Factory.create_internal_module("catalog_missing_internal") == null, "unknown internal id must fail closed")

	var snapshot: Dictionary = Catalog.get_external_definition("visor_v1")
	snapshot["name"] = "changed"
	_expect(str(Catalog.get_external_definition("visor_v1").get("name", "")) == "Visor V1", "catalog query must return isolated data")

	if failures.is_empty():
		print("Bipob module catalog and factory contract OK")
		quit(0)
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
