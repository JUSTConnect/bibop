extends SceneTree

const Store = preload("res://scripts/world/world_state_store.gd")
const Runtime = preload("res://scripts/world/access_runtime_service.gd")
const BindingContract = preload("res://scripts/world/world_binding_store_contract.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func access_contract(entity_type: String, access: bool) -> Dictionary:
	return {"entity_type":entity_type, "capabilities":{"state":true, "power":false, "health":true, "energy":false, "overheat":false, "control":true, "access":access, "bindings":true, "mount":false, "side":false, "routing":false, "test_override":false}}

func relation(id: String, source_id: String, target_id: String) -> Dictionary:
	return {"id":id, "role":BindingContract.ROLE_ACCESS_ITEM, "source_id":source_id, "target_id":target_id, "parameters":{}, "format_version":BindingContract.FORMAT_VERSION}

func run() -> void:
	await process_frame
	var store = Store.new()
	var target := {"id":"door", "position":Vector2i(0, 0), "object_group":"door", "object_type":"door", "access_type":"key_card", "locked":true, "is_locked":true, "state":"closed", "entity_contract":access_contract("object", true)}
	var key := {"id":"key", "position":Vector2i(0, 1), "object_group":"item", "object_type":"item", "item_class":"key_card", "access_type":"key_card", "state":"available", "consume_on_use":true, "entity_contract":access_contract("item", false)}
	var loaded := store.replace_snapshot([target, key])
	check(bool(loaded.get("ok", false)), "fixture load failed")
	var created := store.create_binding(relation("key_link", "key", "door"))
	check(bool(created.get("success", false)), "binding create failed")

	var before := store.get_object_by_id("door")
	var failed_inventory := {"pocket_items":[], "consumed_item_ids":[]}
	var failed := Runtime.apply_access(store, "door", {}, failed_inventory)
	check(not bool(failed.get("granted", true)), "missing credential granted access")
	check(not bool(failed.get("mutated", true)), "failed access reported mutation")
	check(store.get_object_by_id("door") == before, "failed access changed target")
	check(Dictionary(failed.get("inventory_after", {})) == failed_inventory, "failed access changed inventory")

	var success_inventory := {"pocket_items":["key"], "consumed_item_ids":[]}
	var success := Runtime.apply_access(store, "door", {}, success_inventory)
	check(bool(success.get("granted", false)), "valid credential failed")
	check(bool(success.get("mutated", false)), "successful access did not mutate")
	check(not bool(store.get_object_by_id("door").get("locked", true)), "target remained locked")
	check(Array(success.get("consumed_item_ids", [])).has("key"), "consumed id missing")
	check(not Array(Dictionary(success.get("inventory_after", {})).get("pocket_items", [])).has("key"), "single-use key remained")

	if failures.is_empty():
		print("ACCESS_RUNTIME_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("ACCESS_RUNTIME_GATE: FAIL: %s" % failure)
	quit(1)
