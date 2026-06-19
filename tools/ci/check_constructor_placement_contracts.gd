extends SceneTree

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const MissionManagerRef = preload("res://scripts/game/mission_manager.gd")
const GridManagerRef = preload("res://scripts/field/grid_manager.gd")

var _failed := false

func _initialize() -> void:
	_run()
	if _failed:
		quit(1)
		return
	print("OK: Constructor placement contract checks passed")
	quit(0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failed = true

func _contract(id: String) -> Dictionary:
	return WorldObjectCatalogRef.get_constructor_placement_contract(id)

func _run() -> void:
	_check_canonical_contracts()
	_check_alias_contracts()
	_check_missing_contracts()
	_check_metadata_contracts()
	_check_behavioral_placement()

func _check_canonical_contracts() -> void:
	var module_item := _contract("module_item")
	_expect(not module_item.is_empty(), "module_item contract exists")
	_expect(str(module_item.get("default_placement_mode", "")) == "item", "module_item placement mode is item")
	_expect(str(module_item.get("default_placement_surface", "")) == "floor", "module_item defaults to floor")
	_expect(Array(module_item.get("placement_surfaces", [])) == ["floor"], "module_item is floor-only")
	_expect(bool(module_item.get("supports_floor", false)), "module_item supports floor")
	_expect(not bool(module_item.get("supports_wall", true)), "module_item rejects wall")
	_expect(not bool(module_item.get("requires_floor_anchor_when_wall_mounted", true)), "module_item has no wall anchor requirement")
	for id in ["module_internal", "module_external"]:
		var c := _contract(id)
		_expect(str(c.get("canonical_prefab_id", "")) == "module_item", "%s canonicalizes to module_item" % id)
		_expect(str(c.get("default_placement_mode", "")) == "item", "%s inherits item mode" % id)
		_expect(Array(c.get("placement_surfaces", [])) == ["floor"], "%s inherits floor-only surfaces" % id)
		_expect(str(c.get("default_placement_surface", "")) == "floor", "%s defaults to floor" % id)
	var firewall := _contract("firewall")
	_expect(bool(firewall.get("supports_floor", false)), "firewall supports floor")
	_expect(not bool(firewall.get("supports_wall", true)), "firewall does not support wall")
	_expect(bool(firewall.get("floor_only", false)), "firewall is floor-only")
	_expect(str(firewall.get("default_placement_surface", "")) == "floor", "firewall defaults to floor")
	for id in ["light", "external_air_duct"]:
		var c := _contract(id)
		_expect(not bool(c.get("supports_floor", true)), "%s does not support floor" % id)
		_expect(bool(c.get("supports_wall", false)), "%s supports wall" % id)
		_expect(bool(c.get("wall_only", false)), "%s is wall-only" % id)
	for id in ["fuse_box", "power_socket", "power_switcher", "power_cable"]:
		var c := _contract(id)
		_expect(bool(c.get("supports_floor", false)), "%s supports floor" % id)
		_expect(bool(c.get("supports_wall", false)), "%s supports wall" % id)
	_expect(bool(_contract("power_socket").get("supports_floor", false)), "supports_floor is independent")
	_expect(not bool(_contract("power_socket").get("requires_floor", true)), "requires_floor remains floor-only, not floor support")
	_expect(bool(_contract("power_socket").get("requires_floor_anchor_when_wall_mounted", false)), "wall anchor remains distinct")

func _check_alias_contracts() -> void:
	for id in ["light_switch", "circuit_breaker"]:
		var c := _contract(id)
		_expect(str(c.get("canonical_prefab_id", "")) == "power_switcher", "%s canonicalizes to power_switcher" % id)
		_expect(str(c.get("default_placement_surface", "")) == "wall", "%s legacy default is wall" % id)
	for id in ["fuse_box_installed", "fuse_box_empty"]:
		var c := _contract(id)
		_expect(str(c.get("canonical_prefab_id", "")) == "fuse_box", "%s canonicalizes to fuse_box" % id)
		_expect(bool(c.get("supports_floor", false)) and bool(c.get("supports_wall", false)), "%s keeps fuse_box capabilities" % id)
		_expect(str(c.get("default_placement_surface", "")) == "floor", "%s keeps floor default" % id)
	_expect(str(_contract("concrete_floor").get("canonical_prefab_id", "")) == "floor", "floor aliases canonicalize")
	_expect(str(_contract("concrete_floor").get("default_placement_surface", "")) == "floor", "floor aliases default floor")
	_expect(str(_contract("breachable_wall").get("canonical_prefab_id", "")) == "wall", "wall aliases canonicalize")
	_expect(str(_contract("breachable_wall").get("default_placement_surface", "")) == "floor", "structural wall aliases keep floor-cell placement")

func _make_manager() -> Node:
	var manager: Node = MissionManagerRef.new()
	var grid_manager: Node = GridManagerRef.new()
	root.add_child(grid_manager)
	root.add_child(manager)
	manager.grid_manager = grid_manager
	manager.setup_task_test_sandbox_world()
	return manager

func _check_missing_contracts() -> void:
	_expect(_contract("__missing_prefab__").is_empty(), "missing prefab returns empty contract")
	var manager := _make_manager()
	var result: Dictionary = manager.can_place_map_constructor_prefab("__missing_prefab__", Vector2i(1, 1))
	_expect(not bool(result.get("ok", true)), "missing prefab cannot be placed")
	_expect(str(result.get("reason", "")) == "missing_placement_contract", "missing prefab fails closed")
	manager.queue_free()

func _check_metadata_contracts() -> void:
	var manager := _make_manager()
	var rows: Dictionary = manager.get_map_constructor_prefab_palette_rows({})
	for row_variant in Array(rows.get("items", rows.get("rows", []))):
		var row: Dictionary = Dictionary(row_variant)
		var id := str(row.get("id", row.get("prefab_id", "")))
		if id.is_empty():
			continue
		var c := _contract(id)
		_expect(not c.is_empty(), "%s palette contract exists" % id)
		_expect(bool(row.get("placement_contract_valid", false)), "%s metadata contract valid" % id)
		_expect(str(row.get("canonical_prefab_id", "")) == str(c.get("canonical_prefab_id", "")), "%s metadata canonical matches" % id)
		_expect(str(row.get("placement_mode", "")) == str(c.get("default_placement_mode", "")), "%s metadata placement_mode matches" % id)
		_expect(str(row.get("default_placement_surface", "")) == str(c.get("default_placement_surface", "")), "%s metadata default surface matches" % id)
		_expect(Array(row.get("placement_surfaces", [])) == Array(c.get("placement_surfaces", [])), "%s metadata surfaces match" % id)
		for field in ["supports_floor", "supports_wall", "wall_only", "floor_only", "requires_floor", "requires_wall", "requires_floor_anchor_when_wall_mounted", "requires_floor_anchor"]:
			_expect(bool(row.get(field, false)) == bool(c.get(field, false)), "%s metadata %s matches" % [id, field])
	manager.queue_free()

func _prepare_fixture(manager: Node) -> Dictionary:
	var floor_cell := Vector2i(2, 2)
	var floor_cell_b := Vector2i(3, 3)
	var wall_cell := Vector2i(0, 2)
	var anchor_cell := Vector2i(1, 2)
	manager.world_objects_by_cell.clear()
	manager.wall_mounted_objects_by_cell.clear()
	manager.mission_world_objects.clear()
	manager.cell_items.clear()
	manager.grid_manager.set_tile(floor_cell, GridManagerRef.TILE_FLOOR)
	manager.grid_manager.set_tile(floor_cell_b, GridManagerRef.TILE_FLOOR)
	manager.grid_manager.set_tile(anchor_cell, GridManagerRef.TILE_FLOOR)
	manager.grid_manager.set_tile(wall_cell, GridManagerRef.TILE_WALL)
	_expect(manager._is_valid_grid_cell(floor_cell), "fixture floor cell is valid")
	_expect(manager._is_valid_grid_cell(wall_cell), "fixture wall cell is valid")
	_expect(not manager._is_map_constructor_wall_cell(floor_cell), "fixture floor cell is floor")
	_expect(not manager._is_map_constructor_wall_cell(anchor_cell), "fixture anchor cell is floor")
	_expect(manager._is_map_constructor_wall_cell(wall_cell), "fixture wall cell is wall")
	return {"floor": floor_cell, "floor_b": floor_cell_b, "wall": wall_cell, "anchor": anchor_cell}

func _check_behavioral_placement() -> void:
	var manager := _make_manager()
	var fixture := _prepare_fixture(manager)
	var floor_cell: Vector2i = fixture["floor"]
	var floor_cell_b: Vector2i = fixture["floor_b"]
	var wall_cell: Vector2i = fixture["wall"]
	var anchor_cell: Vector2i = fixture["anchor"]
	_expect(bool(manager.can_place_map_constructor_prefab("firewall", floor_cell).get("ok", false)), "firewall places on floor")
	_expect(str(manager.can_place_map_constructor_prefab("firewall", floor_cell, "", "wall").get("reason", "")) == "prefab_does_not_support_wall_placement", "firewall rejects explicit wall")
	_expect(not bool(manager.can_place_map_constructor_prefab("light", floor_cell, "", "object").get("ok", true)), "wall-only prefab rejects floor path")
	_expect(bool(manager.can_place_map_constructor_prefab("light", wall_cell, "", "wall").get("ok", false)), "wall-only prefab passes wall path")
	_expect(bool(manager.can_place_map_constructor_prefab("power_socket", wall_cell, "", "wall").get("ok", false)), "floor+wall prefab passes wall path")
	_expect(bool(manager.can_place_map_constructor_prefab("power_socket", floor_cell_b).get("ok", false)), "floor+wall prefab passes floor path by default")
	for id in ["light_switch", "circuit_breaker"]:
		var result: Dictionary = manager.can_place_map_constructor_prefab(id, wall_cell)
		_expect(bool(result.get("ok", false)), "%s uses wall default without override" % id)
		_expect(str(result.get("placement_mode", "")) == "wall_mounted", "%s default path is wall-mounted" % id)
		_expect(str(manager.can_place_map_constructor_prefab(id, floor_cell).get("reason", "")) == "wall_mount_requires_wall_cell", "%s does not silently floor-place" % id)
	for id in ["module_item", "module_internal", "module_external"]:
		var result: Dictionary = manager.can_place_map_constructor_prefab(id, anchor_cell)
		_expect(bool(result.get("ok", false)), "%s succeeds through item floor path" % id)
		_expect(str(result.get("placement_mode", "")) == "item", "%s placement mode is item" % id)
	_expect(bool(manager.can_place_map_constructor_prefab("fuse_box_installed", floor_cell_b).get("ok", false)), "fuse_box_installed floor default places on floor")
	_expect(bool(manager.can_place_map_constructor_prefab("fuse_box_empty", wall_cell, "", "wall").get("ok", false)), "fuse_box_empty explicit wall places on wall")
	_expect(bool(manager.can_place_map_constructor_prefab("concrete_floor", floor_cell_b).get("ok", false)), "legacy floor alias follows floor behavior")
	_expect(bool(manager.can_place_map_constructor_prefab("breachable_wall", floor_cell_b).get("ok", false)), "legacy wall alias follows structural wall behavior")
	manager.queue_free()
