extends SceneTree

const MissionManagerRef = preload("res://scripts/game/mission_manager.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _inventory_has_id(inventory: Dictionary, item_id: String) -> bool:
	if str(inventory.get("manipulator_hold", "")) == item_id:
		return true
	for value in Array(inventory.get("pocket_items", [])):
		if str(value) == item_id:
			return true
	return Dictionary(inventory.get("world_item_runtime", {})).has(item_id)

func _run() -> void:
	await process_frame
	var manager = MissionManagerRef.new()
	root.add_child(manager)
	manager.runtime_inventory_state["pocket_capacity"] = 3
	manager.runtime_inventory_state["pocket_items"] = []

	var pickup: Dictionary = {
		"id":"details_pickup_test",
		"position":Vector2i(1, 1),
		"object_group":"item",
		"object_type":"details_pickup",
		"currency_id":"details",
		"item_type":"details",
		"item_form":"currency_pickup",
		"storage_type":"none",
		"amount":12,
		"can_pickup":true
	}
	_assert(bool(manager.world_state_store.replace_snapshot([pickup]).get("ok", false)), "Details world failed to load")
	var pickup_result: Dictionary = manager.pickup_world_item("details_pickup_test")
	_assert(bool(pickup_result.get("success", false)), "Details pickup failed")
	_assert(manager.get_details_balance() == 12, "Details pickup did not increase central balance")
	_assert(str(pickup_result.get("storage", "")) == "details_balance", "Details pickup used inventory storage")
	_assert(not _inventory_has_id(manager.get_inventory_state(), "details_pickup_test"), "Details pickup entered inventory")
	_assert(manager.world_state_store.get_object_by_id("details_pickup_test").is_empty(), "collected Details remained in world")
	var duplicate_reward: Dictionary = manager.receive_details_reward("mission_reward:test", 5, "mission")
	_assert(bool(duplicate_reward.get("success", false)), "mission Details reward failed")
	_assert(manager.get_details_balance() == 17, "mission Details reward did not use central balance")
	manager.receive_details_reward("mission_reward:test", 5, "mission")
	_assert(manager.get_details_balance() == 17, "duplicate mission reward changed balance")

	var routed: Dictionary = manager.route_runtime_item({"id":"repair_kit_test", "object_group":"item", "item_type":"repair_kit", "item_form":"physical", "amount":9, "consumable":true})
	_assert(bool(routed.get("success", false)), "normal item route failed")
	var runtime_item: Dictionary = Dictionary(Dictionary(manager.get_inventory_state().get("world_item_runtime", {})).get("repair_kit_test", {})).get("item_data", {})
	_assert(not runtime_item.has("amount"), "normal item retained amount")
	var before_failed_use: Dictionary = manager.get_inventory_state()
	var failed_use: Dictionary = manager.use_inventory_item_on_world_object("repair_kit_test", "missing_target")
	_assert(not bool(failed_use.get("success", true)), "missing-target use succeeded")
	_assert(_inventory_has_id(manager.get_inventory_state(), "repair_kit_test"), "failed use consumed item")
	_assert(var_to_str(before_failed_use) == var_to_str(manager.get_inventory_state()), "failed use mutated inventory")

	var fuse_route: Dictionary = manager.route_runtime_item({"id":"fuse_test", "object_group":"item", "item_type":"fuse", "item_form":"physical", "consumable":true})
	_assert(bool(fuse_route.get("success", false)), "fuse route failed")
	var world_objects: Array[Dictionary] = manager.world_state_store.get_all_objects()
	world_objects.append({"id":"fuse_box_test", "position":Vector2i(2, 1), "object_group":"power", "object_type":"fuse_box_empty", "state":"empty", "power_network_id":""})
	_assert(bool(manager.world_state_store.replace_snapshot(world_objects).get("ok", false)), "fuse target load failed")
	var successful_use: Dictionary = manager.use_inventory_item_on_world_object("fuse_test", "fuse_box_test")
	_assert(bool(successful_use.get("success", false)), "successful consumable action failed")
	_assert(not _inventory_has_id(manager.get_inventory_state(), "fuse_test"), "successful consumable remained in inventory")
	_assert(Array(manager.get_inventory_state().get("consumed_item_ids", [])).has("fuse_test"), "consumed item ID not recorded")

	manager.runtime_inventory_state = {
		"pocket_items":["legacy_parts"],
		"manipulator_hold":"",
		"box_storage":[],
		"item_amounts":{"legacy_parts":8},
		"world_item_runtime":{"legacy_parts":{"in_inventory":true, "item_data":{"id":"legacy_parts", "item_type":"parts"}}},
		"consumed_item_ids":[]
	}
	var migration: Dictionary = manager.migrate_legacy_parts_state({"parts":4}, "legacy:test")
	_assert(bool(migration.get("success", false)), "MissionManager legacy migration failed")
	_assert(manager.get_details_balance() == 29, "legacy migration sum lost")
	_assert(not manager.get_inventory_state().has("item_amounts"), "legacy item_amounts exposed after migration")
	_assert(not _inventory_has_id(manager.get_inventory_state(), "legacy_parts"), "legacy parts remained in inventory")
	manager.migrate_legacy_parts_state({"parts":4}, "legacy:test")
	_assert(manager.get_details_balance() == 29, "duplicate migration changed balance")

	var snapshot: Dictionary = manager.get_world_state_serializable_snapshot()
	_assert(snapshot.has("details_currency"), "Details snapshot missing from persistence")
	var restored = MissionManagerRef.new()
	root.add_child(restored)
	_assert(bool(restored.replace_world_state_serialized_snapshot(snapshot).get("ok", false)), "Details persistence restore failed")
	_assert(restored.get_details_balance() == 29, "restored Details balance mismatch")

	manager.queue_free()
	restored.queue_free()
	await process_frame
	if failures.is_empty():
		print("NORMAL_ITEMS_DETAILS_MISSION_MANAGER_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("NORMAL_ITEMS_DETAILS_MISSION_MANAGER_GATE: FAIL: %s" % failure)
	quit(1)
