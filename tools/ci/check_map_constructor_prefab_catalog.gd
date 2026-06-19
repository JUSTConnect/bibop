extends SceneTree

const Catalog = preload("res://scripts/game/map_constructor_prefab_catalog.gd")
const WorldObjectCatalog = preload("res://scripts/world/world_object_catalog.gd")

var failures: Array[String] = []

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _initialize() -> void:
	var rows: Array[Dictionary] = Catalog.get_catalog_entries()
	var ids: Array[String] = []
	var categories: Array[String] = []
	var labels := {}
	for row in rows:
		var id := str(row.get("id", ""))
		ids.append(id)
		var category := str(row.get("category", ""))
		if not categories.has(category):
			categories.append(category)
		labels[id] = str(row.get("display_name", ""))
		_assert(not Catalog.get_prefab_presentation(id).is_empty(), "missing presentation for visible %s" % id)
		var contract := WorldObjectCatalog.get_constructor_placement_contract(id)
		_assert(not contract.is_empty(), "missing placement contract for %s" % id)
		_assert(str(row.get("canonical_prefab_id", "")) == str(contract.get("canonical_prefab_id", "")), "canonical mismatch for %s" % id)
		_assert(str(row.get("prefab_id", "")) == id, "requested id not preserved for %s" % id)
		_assert(str(row.get("placement_mode", "")) == str(contract.get("default_placement_mode", "")), "placement mode mismatch for %s" % id)
		_assert(str(row.get("default_placement_mode", "")) == str(contract.get("default_placement_mode", "")), "default placement mode mismatch for %s" % id)
		_assert(str(row.get("default_placement_surface", "")) == str(contract.get("default_placement_surface", "")), "default surface mismatch for %s" % id)
		_assert(Array(row.get("placement_surfaces", [])) == Array(contract.get("placement_surfaces", [])), "surfaces mismatch for %s" % id)
		for field in ["supports_floor", "supports_wall", "floor_only", "wall_only", "requires_floor", "requires_wall", "requires_floor_anchor", "requires_floor_anchor_when_wall_mounted", "changes_passability"]:
			_assert(bool(row.get(field, false)) == bool(contract.get(field, false)), "%s mismatch for %s" % [field, id])
		if bool(row.get("configurable", false)):
			_assert(WorldObjectCatalog.get_archetype_property_schema(str(row.get("canonical_prefab_id", id))).size() >= 0, "configurable schema lookup failed for %s" % id)
	var expected_ids: Array[String] = WorldObjectCatalog.CONSTRUCTOR_PALETTE_PREFAB_ORDER.duplicate()
	_assert(ids == expected_ids, "visible prefab sequence changed: %s" % str(ids))
	var expected_categories: Array[String] = categories.duplicate()
	expected_categories.sort()
	_assert(categories == expected_categories, "category sequence changed: %s" % str(categories))
	_assert(labels.get("power_cable_reel", "") == "Cable Reel", "Cable Reel label changed")
	_assert(labels.get("door", "") == "Door", "Door label changed")
	_assert(labels.get("terminal", "") == "Terminal", "Terminal label changed")
	for hidden_alias in ["light_switch", "circuit_breaker", "fuse_box_installed", "fuse_box_empty", "module_internal", "module_external", "concrete_floor", "breachable_wall"]:
		_assert(not ids.has(hidden_alias), "hidden alias exposed: %s" % hidden_alias)
		var alias_meta := Catalog.normalize_presentation_row(Catalog.get_prefab_presentation(hidden_alias))
		var alias_contract := WorldObjectCatalog.get_constructor_placement_contract(hidden_alias)
		_assert(not alias_meta.is_empty(), "alias presentation missing: %s" % hidden_alias)
		_assert(str(alias_meta.get("prefab_id", "")) == hidden_alias, "alias requested id lost: %s" % hidden_alias)
		_assert(str(alias_meta.get("canonical_prefab_id", "")) == str(alias_contract.get("canonical_prefab_id", "")), "alias canonical mismatch: %s" % hidden_alias)
		_assert(str(alias_meta.get("display_name", "")).strip_edges() != "", "alias label missing: %s" % hidden_alias)
	var unknown := Catalog.normalize_presentation_row({"id":"unknown_prefab", "display_name":"Unknown", "supports_floor":true, "placement_mode":"object"})
	_assert(not bool(unknown.get("placement_contract_valid", true)), "unknown contract should fail closed")
	_assert(not bool(unknown.get("supports_floor", true)), "unknown emitted fallback floor support")
	var override_row := Catalog.normalize_presentation_row({"id":"door", "supports_wall":not bool(WorldObjectCatalog.get_constructor_placement_contract("door").get("supports_wall", false))})
	_assert(bool(override_row.get("supports_wall", false)) == bool(WorldObjectCatalog.get_constructor_placement_contract("door").get("supports_wall", false)), "presentation overrode gameplay contract")
	if failures.is_empty():
		print("Map constructor prefab catalog checks passed.")
		quit(0)
	for failure in failures:
		push_error(failure)
	quit(1)
