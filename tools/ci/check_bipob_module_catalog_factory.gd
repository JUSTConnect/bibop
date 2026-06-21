extends SceneTree

const Catalog = preload("res://scripts/bipob/bipob_module_catalog.gd")
const Factory = preload("res://scripts/bipob/bipob_module_factory.gd")

var failures: Array[String] = []

func _init() -> void:
	var validation: Dictionary = Catalog.validate_catalog()
	_expect(bool(validation.get("valid", false)), "catalog validation must succeed: %s" % str(validation.get("errors", [])))
	_expect(int(validation.get("external_count", 0)) > 0, "external catalog must not be empty")
	_expect(int(validation.get("internal_count", 0)) > 0, "internal catalog must not be empty")

	_check_external_alias_compatibility()
	_check_serialized_id_compatibility()
	_check_internal_hydration()
	_check_compatibility_constructors()
	_check_catalog_snapshot_isolation()

	if failures.is_empty():
		print("Bipob module catalog and factory contract OK")
		quit(0)
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_external_alias_compatibility() -> void:
	var canonical: BipobModule = Factory.create_external_module("manipulator_arm_v1")
	var alias: BipobModule = Factory.create_external_module("manipulator_v1")
	_expect(canonical != null and alias != null, "manipulator canonical and legacy ids must hydrate")
	if canonical != null and alias != null:
		_expect(alias.id == "manipulator_arm_v1", "legacy manipulator id must resolve to canonical id")
		_expect(alias.module_id == canonical.module_id, "alias and canonical module_id must match")
		_expect(alias.external_width == canonical.external_width, "alias width must match canonical width")
		_expect(alias.external_height == canonical.external_height, "alias height must match canonical height")
		_expect(alias.allowed_external_sides == canonical.allowed_external_sides, "alias sides must match canonical sides")
		_expect(alias.granted_commands == canonical.granted_commands, "alias commands must match canonical commands")
		_expect(alias.module_version == canonical.module_version, "alias version must match canonical version")

	var interface_alias: BipobModule = Factory.create_external_module("interface_v1")
	var interface_canonical: BipobModule = Factory.create_external_module("external_interface_connector_v1")
	_expect(interface_alias != null and interface_canonical != null, "interface alias and canonical id must hydrate")
	if interface_alias != null and interface_canonical != null:
		_expect(interface_alias.id == "external_interface_connector_v1", "interface_v1 must resolve to canonical connector id")
		_expect(interface_alias.allowed_external_sides == interface_canonical.allowed_external_sides, "interface alias sides must remain compatible")
		_expect(interface_alias.connection_type == interface_canonical.connection_type, "interface alias connection type must remain compatible")

	for alias_id_variant in Catalog.MODULE_ALIASES.keys():
		var alias_id := str(alias_id_variant)
		var canonical_id := Catalog.resolve_module_id(alias_id)
		_expect(canonical_id != alias_id, "alias must resolve to a different canonical id: %s" % alias_id)
		_expect(Catalog.is_external_module_id(canonical_id) or Catalog.is_internal_module_id(canonical_id), "alias target must exist: %s" % alias_id)
		if Catalog.is_external_module_id(canonical_id):
			var hydrated: BipobModule = Factory.create_external_module(alias_id)
			_expect(hydrated != null and hydrated.id == canonical_id, "legacy external id must hydrate through canonical definition: %s" % alias_id)

func _check_serialized_id_compatibility() -> void:
	var serialized_records: Array[Dictionary] = [
		{"id": "legs_v1", "placement_type": "external"},
		{"id": "manipulator_v1", "placement_type": "external"},
		{"id": "interface_v1", "placement_type": "external"},
		{"id": "battery_v3", "placement_type": "internal"},
		{"id": "gpu_v2", "placement_type": "internal"},
	]
	for record in serialized_records:
		var serialized_id := str(record.get("id", ""))
		var placement_type := str(record.get("placement_type", ""))
		var restored: BipobModule = null
		if placement_type == "external":
			restored = Factory.create_external_module(serialized_id)
		else:
			restored = Factory.create_internal_module(serialized_id)
		_expect(restored != null, "serialized module id must restore: %s" % serialized_id)
		if restored == null:
			continue
		var expected_id := Catalog.resolve_module_id(serialized_id) if placement_type == "external" else serialized_id
		_expect(restored.id == expected_id, "restored module must preserve canonical serialized identity: %s" % serialized_id)
		_expect(restored.module_id == expected_id, "restored module_id must match restored identity: %s" % serialized_id)

	_expect(Factory.create_external_module("catalog_missing_external") == null, "unknown external id must fail closed")
	_expect(Factory.create_internal_module("catalog_missing_internal") == null, "unknown internal id must fail closed")

func _check_internal_hydration() -> void:
	var battery: BipobModule = Factory.create_internal_module("battery_v3")
	_expect(battery != null, "battery_v3 must hydrate")
	if battery != null:
		_expect(battery.internal_role == "battery", "battery role must hydrate")
		_expect(battery.module_version == 3, "battery version must hydrate")
		_expect(battery.battery_capacity == 50 and battery.energy_capacity == 50, "battery capacity must hydrate")
		_expect(battery.internal_size == Vector3i(2, 2, 1), "battery size must hydrate")
		_expect(battery.placement_type == "internal", "battery placement must hydrate")

	var gpu: BipobModule = Factory.create_internal_module("gpu_v2")
	_expect(gpu != null, "gpu_v2 must hydrate")
	if gpu != null:
		_expect(gpu.sensor_range_bonus == 5, "gpu range bonus must hydrate")
		_expect(gpu.sensor_visibility_bonus == 30, "gpu visibility bonus must hydrate")
		_expect(gpu.gpu_value == 4, "gpu processing value must hydrate")
		_expect(gpu.internal_size == Vector3i(1, 1, 1), "gpu size must hydrate")

func _check_compatibility_constructors() -> void:
	var debug_battery: BipobModule = Factory.create_debug_found_module()
	_expect(debug_battery != null, "debug found module must hydrate")
	if debug_battery != null:
		_expect(debug_battery.id == "battery_v1" and debug_battery.module_id == "battery_v1", "debug battery must use canonical battery hydration")
		_expect(debug_battery.internal_role == "battery", "debug battery must preserve catalog role")
		_expect(debug_battery.energy_bonus == 10, "debug battery compatibility bonus must remain")

	var debug_cooling: BipobModule = Factory.create_debug_field_component()
	_expect(debug_cooling != null, "debug cooling component must hydrate")
	if debug_cooling != null:
		_expect(debug_cooling.id == "cooling_v1" and debug_cooling.module_id == "cooling_v1", "debug cooling compatibility id must remain")
		_expect(debug_cooling.internal_family == "cooling", "debug cooling must inherit canonical cooling metadata")
		_expect(debug_cooling.cooling_power == 2, "debug cooling must inherit cooler hydration")

	var legacy_gpu: BipobModule = Factory.create_legacy_gpu_v1_module()
	_expect(legacy_gpu != null and legacy_gpu.id == "gpu_v1", "legacy GPU constructor must use canonical gpu_v1 hydration")
	if legacy_gpu != null:
		_expect(legacy_gpu.gpu_value > 0, "legacy GPU must retain canonical processing metadata")
		_expect(legacy_gpu.granted_commands.has("hidden_detection_support"), "legacy GPU compatibility command must remain")

	var legacy_legs: BipobModule = Factory.create_legacy_legs_v1_module()
	_expect(legacy_legs != null and legacy_legs.id == "legs_v1", "legacy legs constructor must use canonical legs_v1 hydration")
	if legacy_legs != null:
		_expect(legacy_legs.placement_type == "external", "legacy legs placement must remain external")
		_expect(legacy_legs.allowed_external_sides.has(Catalog.EXTERNAL_SIDE_BOTTOM), "legacy legs side contract must come from catalog")
		_expect(legacy_legs.granted_commands.has("cross_stepped_floor"), "legacy legs compatibility command must remain")

func _check_catalog_snapshot_isolation() -> void:
	var snapshot: Dictionary = Catalog.get_external_definition("visor_v1")
	snapshot["name"] = "changed"
	_expect(str(Catalog.get_external_definition("visor_v1").get("name", "")) == "Visor V1", "catalog query must return isolated external data")
	var internal_specs: Array[Dictionary] = Catalog.get_internal_module_specs()
	if not internal_specs.is_empty():
		internal_specs[0]["name"] = "changed"
		_expect(str(Catalog.get_internal_module_specs()[0].get("name", "")) != "changed", "catalog query must return isolated internal data")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
