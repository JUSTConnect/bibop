extends SceneTree

const DetailsServiceRef = preload("res://scripts/game/inventory/details_currency_service.gd")
const NormalItemContractRef = preload("res://scripts/game/inventory/normal_item_contract.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _run() -> void:
	await process_frame
	var details = DetailsServiceRef.new()
	_assert(details.get_balance() == 0, "new Details balance is not zero")
	var received: Dictionary = details.receive(10, "reward:mission:1", "mission_reward")
	_assert(bool(received.get("success", false)), "valid Details reward failed")
	_assert(str(received.get("code", "")) == DetailsServiceRef.CODE_RECEIVED, "received code missing")
	_assert(details.get_balance() == 10, "Details balance not increased")
	_assert(not Dictionary(received.get("notification_event", {})).is_empty(), "player reward notification missing")
	var duplicate: Dictionary = details.receive(10, "reward:mission:1", "mission_reward")
	_assert(str(duplicate.get("code", "")) == DetailsServiceRef.CODE_DUPLICATE_REWARD, "duplicate reward was not detected")
	_assert(details.get_balance() == 10, "duplicate reward changed balance")
	_assert(Dictionary(duplicate.get("notification_event", {})).is_empty(), "duplicate reward emitted notification")
	var insufficient: Dictionary = details.spend(11, "purchase:1", "shop")
	_assert(str(insufficient.get("code", "")) == DetailsServiceRef.CODE_INSUFFICIENT, "insufficient code missing")
	_assert(details.get_balance() == 10, "insufficient spend changed balance")
	var spent: Dictionary = details.spend(4, "purchase:1", "shop")
	_assert(str(spent.get("code", "")) == DetailsServiceRef.CODE_SPENT, "spent code missing")
	_assert(details.get_balance() == 6, "spend did not reduce balance")
	var duplicate_spend: Dictionary = details.spend(4, "purchase:1", "shop")
	_assert(str(duplicate_spend.get("code", "")) == DetailsServiceRef.CODE_DUPLICATE_TRANSACTION, "duplicate spend not detected")
	_assert(details.get_balance() == 6, "duplicate spend changed balance")

	var normal_item: Dictionary = {"id":"fuse_1", "object_group":"item", "item_type":"fuse", "item_form":"physical", "consumable":true}
	_assert(bool(NormalItemContractRef.validate(normal_item).get("success", false)), "valid normal item rejected")
	var stacked_item: Dictionary = normal_item.duplicate(true)
	stacked_item["amount"] = 3
	_assert(str(NormalItemContractRef.validate(stacked_item).get("code", "")) == NormalItemContractRef.CODE_AMOUNT_FORBIDDEN, "normal item amount accepted")
	var canonical_item: Dictionary = NormalItemContractRef.canonicalize(stacked_item)
	_assert(not canonical_item.has("amount"), "normal item amount not removed")
	_assert(not bool(canonical_item.get("stackable", true)), "normal item remained stackable")
	var details_pickup: Dictionary = DetailsServiceRef.make_details_pickup({"id":"parts_medium", "amount":10, "position":Vector2i(2, 2)})
	_assert(not NormalItemContractRef.is_normal_item(details_pickup), "Details pickup classified as normal item")
	_assert(int(details_pickup.get("amount", 0)) == 10, "Details pickup lost amount")
	_assert(str(details_pickup.get("storage_type", "")) == "none", "Details pickup received inventory storage")

	var inventory: Dictionary = {
		"pocket_items":["fuse_1"],
		"manipulator_hold":"",
		"box_storage":[],
		"world_item_runtime":{"fuse_1":{"in_inventory":true, "item_data":normal_item}},
		"consumed_item_ids":[]
	}
	var failed_consumption: Dictionary = NormalItemContractRef.apply_consumption(inventory, "fuse_1", normal_item, {"success":false})
	_assert(not bool(failed_consumption.get("consumed", true)), "failed action consumed item")
	_assert(Array(Dictionary(failed_consumption.get("inventory", {})).get("pocket_items", [])).has("fuse_1"), "failed action removed item")
	var successful_consumption: Dictionary = NormalItemContractRef.apply_consumption(inventory, "fuse_1", normal_item, {"success":true})
	_assert(bool(successful_consumption.get("consumed", false)), "successful consumable action did not consume")
	_assert(not Array(Dictionary(successful_consumption.get("inventory", {})).get("pocket_items", [])).has("fuse_1"), "consumed item remained in pocket")
	_assert(Array(Dictionary(successful_consumption.get("inventory", {})).get("consumed_item_ids", [])).has("fuse_1"), "consumed item ID not recorded")

	var legacy_inventory: Dictionary = {
		"pocket_items":["parts_stack", "repair_kit_1"],
		"manipulator_hold":{"id":"parts_small", "item_type":"parts_small", "amount":5},
		"box_storage":[{"id":"parts_large", "category":"resource", "kind":"parts", "amount":20}],
		"item_amounts":{"parts_stack":10},
		"world_item_runtime":{
			"parts_stack":{"in_inventory":true, "item_data":{"id":"parts_stack", "item_type":"parts", "amount":1}},
			"repair_kit_1":{"in_inventory":true, "item_data":{"id":"repair_kit_1", "item_type":"repair_kit"}}
		},
		"consumed_item_ids":[]
	}
	var migration_service = DetailsServiceRef.new()
	var migration: Dictionary = migration_service.migrate_legacy_parts(legacy_inventory, {"parts":7, "items":[]}, "migration:test")
	_assert(bool(migration.get("success", false)), "legacy parts migration failed")
	_assert(int(migration.get("migrated_amount", 0)) == 42, "legacy parts sum was not preserved")
	_assert(migration_service.get_balance() == 42, "migrated Details balance mismatch")
	var migrated_inventory: Dictionary = Dictionary(migration.get("inventory_state", {}))
	_assert(not migrated_inventory.has("item_amounts"), "legacy item_amounts remained")
	_assert(Array(migrated_inventory.get("pocket_items", [])).size() == 1, "legacy parts remained in pocket")
	_assert(str(migrated_inventory.get("manipulator_hold", "")) == "", "legacy parts remained in manipulator")
	_assert(Array(migrated_inventory.get("box_storage", [])).is_empty(), "legacy parts remained in box storage")
	_assert(not Dictionary(migration.get("center_storage", {})).has("parts"), "legacy center parts remained")
	var migration_again: Dictionary = migration_service.migrate_legacy_parts(legacy_inventory, {"parts":7, "items":[]}, "migration:test")
	_assert(str(Dictionary(migration_again.get("currency_result", {})).get("code", "")) == DetailsServiceRef.CODE_DUPLICATE_REWARD, "migration was not idempotent")
	_assert(migration_service.get_balance() == 42, "duplicate migration changed balance")

	var world: Array[Dictionary] = DetailsServiceRef.migrate_world_pickups([
		{"id":"world_parts", "object_group":"item", "item_type":"parts", "amount":5, "position":Vector2i(1, 1)},
		{"id":"world_fuse", "object_group":"item", "item_type":"fuse", "amount":9, "position":Vector2i(2, 1)}
	])
	_assert(str(world[0].get("object_type", "")) == "details_pickup", "world parts not migrated to Details pickup")
	_assert(int(world[0].get("amount", 0)) == 5, "world Details pickup amount lost")
	_assert(world[1].has("amount"), "world migration unexpectedly normalized unrelated item")

	var snapshot: Dictionary = migration_service.get_snapshot()
	var restored = DetailsServiceRef.new()
	_assert(bool(restored.replace_snapshot(snapshot).get("success", false)), "Details snapshot restore failed")
	_assert(restored.get_balance() == 42, "Details snapshot balance mismatch")
	_assert(restored.has_processed_reward("migration:test"), "processed reward IDs not restored")

	await process_frame
	if failures.is_empty():
		print("NORMAL_ITEMS_DETAILS_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("NORMAL_ITEMS_DETAILS_GATE: FAIL: %s" % failure)
	quit(1)
