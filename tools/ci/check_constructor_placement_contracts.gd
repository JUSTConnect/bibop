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
	var firewall := _contract("firewall")
	_expect(bool(firewall.get("supports_floor", false)), "firewall supports floor")
	_expect(not bool(firewall.get("supports_wall", true)), "firewall does not support wall")
	_expect(bool(firewall.get("floor_only", false)), "firewall is floor-only")
	_expect(not bool(firewall.get("wall_only", true)), "firewall is not wall-only")
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
	_expect(str(_contract("power_switcher").get("default_placement_surface", "")) == "floor", "power_switcher defaults floor")

func _check_alias_contracts() -> void:
	for id in ["light_switch", "circuit_breaker"]:
		var c := _contract(id)
		_expect(str(c.get("canonical_prefab_id", "")) == "power_switcher", "%s canonicalizes to power_switcher" % id)
		_expect(str(c.get("requested_prefab_id", "")) == id, "%s preserves requested id" % id)
		_expect(str(c.get("default_placement_surface", "")) == "wall", "%s legacy default is wall" % id)
	for id in ["fuse_box_installed", "fuse_box_empty"]:
		var c := _contract(id)
		_expect(str(c.get("canonical_prefab_id", "")) == "fuse_box", "%s canonicalizes to fuse_box" % id)
		_expect(bool(c.get("supports_floor", false)) and bool(c.get("supports_wall", false)), "%s keeps fuse_box capabilities" % id)
	_expect(str(_contract("concrete_floor").get("canonical_prefab_id", "")) == "floor", "floor aliases canonicalize")
	_expect(str(_contract("breachable_wall").get("canonical_prefab_id", "")) == "wall", "wall aliases canonicalize")

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
		_expect(str(row.get("canonical_prefab_id", "")) == str(c.get("canonical_prefab_id", "")), "%s metadata canonical matches" % id)
		for field in ["supports_floor", "supports_wall", "wall_only", "floor_only", "requires_floor", "requires_wall", "requires_floor_anchor_when_wall_mounted"]:
			_expect(bool(row.get(field, false)) == bool(c.get(field, false)), "%s metadata %s matches" % [id, field])
	manager.queue_free()

func _find_wall_cell(manager: Node) -> Vector2i:
	for y in range(0, 10):
		for x in range(0, 10):
			var cell := Vector2i(x, y)
			if manager._is_valid_grid_cell(cell) and manager._is_map_constructor_wall_cell(cell):
				return cell
	return Vector2i(-1, -1)

func _check_behavioral_placement() -> void:
	var manager := _make_manager()
	var floor_cell := Vector2i(2, 2)
	var wall_cell := _find_wall_cell(manager)
	_expect(bool(manager.can_place_map_constructor_prefab("firewall", floor_cell).get("ok", false)), "firewall places on floor")
	_expect(str(manager.can_place_map_constructor_prefab("firewall", floor_cell, "", "wall").get("reason", "")) == "prefab_does_not_support_wall_placement", "firewall rejects explicit wall")
	_expect(not bool(manager.can_place_map_constructor_prefab("light", floor_cell, "", "object").get("ok", true)), "wall-only prefab rejects floor path")
	if wall_cell != Vector2i(-1, -1):
		_expect(bool(manager.can_place_map_constructor_prefab("light", wall_cell, "", "wall").get("ok", false)), "wall-only prefab passes wall path")
		_expect(bool(manager.can_place_map_constructor_prefab("power_socket", wall_cell, "", "wall").get("ok", false)), "floor+wall prefab passes wall path")
	_expect(bool(manager.can_place_map_constructor_prefab("power_socket", Vector2i(3, 3)).get("ok", false)), "floor+wall prefab passes floor path")
	manager.queue_free()
