extends SceneTree

const Store = preload("res://scripts/world/world_state_store.gd")
const Service = preload("res://scripts/world/access_binding_service.gd")
const BindingContract = preload("res://scripts/world/world_binding_store_contract.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func contract(entity_type: String, access: bool) -> Dictionary:
	return {"entity_type":entity_type, "capabilities":{"state":true, "power":false, "health":true, "energy":false, "overheat":false, "control":true, "access":access, "bindings":true, "mount":false, "side":false, "routing":false, "test_override":false}}

func relation(id: String, role: String, source_id: String, target_id: String) -> Dictionary:
	return {"id":id, "role":role, "source_id":source_id, "target_id":target_id, "parameters":{}, "format_version":BindingContract.FORMAT_VERSION}

func run() -> void:
	await process_frame
	var store = Store.new()
	var objects: Array[Dictionary] = [
		{"id":"door", "position":Vector2i(0, 0), "object_group":"door", "object_type":"door", "access_type":"terminal", "state":"closed", "entity_contract":contract("object", true)},
		{"id":"key", "position":Vector2i(0, 1), "object_group":"item", "object_type":"item", "item_class":"key_card", "state":"available", "entity_contract":contract("item", false)},
		{"id":"terminal_a", "position":Vector2i(2, 0), "object_group":"terminal", "object_type":"control_terminal", "state":"active", "is_powered":true, "entity_contract":contract("object", true)},
		{"id":"terminal_b", "position":Vector2i(3, 0), "object_group":"terminal", "object_type":"control_terminal", "state":"active", "is_powered":true, "entity_contract":contract("object", true)}
	]
	check(bool(store.replace_snapshot(objects).get("ok", false)), "fixture load failed")

	check(str(Service.preview_relation(store, BindingContract.ROLE_ACCESS_ITEM, "", "door").get("code", "")) == "missing", "missing code changed")
	check(str(Service.preview_relation(store, BindingContract.ROLE_ACCESS_ITEM, "ghost", "door").get("code", "")) == "source_missing", "source_missing code changed")
	check(str(Service.preview_relation(store, BindingContract.ROLE_ACCESS_ITEM, "key", "ghost").get("code", "")) == "target_missing", "target_missing code changed")
	check(str(Service.preview_relation(store, BindingContract.ROLE_ACCESS_ITEM, "terminal_a", "door").get("code", "")) == "wrong_type", "wrong_type code changed")

	var terminal_link := Service.create_or_replace_relation(store, relation("terminal_link", BindingContract.ROLE_ACCESS_TERMINAL, "terminal_a", "door"))
	check(bool(terminal_link.get("success", false)), "access terminal link failed")
	var capacity := Service.preview_relation(store, BindingContract.ROLE_ACCESS_TERMINAL, "terminal_b", "door")
	check(str(capacity.get("code", "")) == "capacity_exceeded", "capacity code changed")
	var duplicate := Service.create_or_replace_relation(store, relation("terminal_duplicate", BindingContract.ROLE_ACCESS_TERMINAL, "terminal_a", "door"))
	check(str(duplicate.get("code", "")) == "duplicate", "duplicate code changed")

	var control_link := store.create_binding(relation("control_link", BindingContract.ROLE_CONTROL_TERMINAL, "terminal_b", "door"))
	check(bool(control_link.get("success", false)), "control fixture failed")
	var reverse := Service.reverse_index_preview(store, "door")
	check(Array(reverse.get("incoming", [])).size() == 2, "reverse index omitted relation")
	var incoming: Array = Array(reverse.get("incoming", []))
	check(str(Dictionary(incoming[0]).get("id", "")) < str(Dictionary(incoming[1]).get("id", "")), "reverse index order changed")

	var physical := store.create_binding(relation("physical", "power_cable", "key", "door"))
	check(str(physical.get("code", "")) == "physical_relation_forbidden", "physical relation entered binding store")
	check(str(Service.fix_hint_for_code("capacity_exceeded")).length() > 0, "fix hint missing")

	if failures.is_empty():
		print("ACCESS_BINDING_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("ACCESS_BINDING_GATE: FAIL: %s" % failure)
	quit(1)
