extends SceneTree

const Resolver = preload("res://scripts/world/access_resolver.gd")
const BindingContract = preload("res://scripts/world/world_binding_store_contract.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func target(id: String, access_type: String, profile: Dictionary = {}) -> Dictionary:
	var value := {"id":id, "object_group":"door", "object_type":"door", "access_type":access_type, "locked":true, "is_locked":true}
	if not profile.is_empty():
		value["access_profile_data"] = profile
	return value

func item(id: String, access_type: String, consume: bool = false) -> Dictionary:
	return {"id":id, "object_group":"item", "object_type":"item", "item_class":access_type, "access_type":access_type, "credential_state":"valid", "consume_on_use":consume}

func terminal(id: String, powered: bool = true) -> Dictionary:
	return {"id":id, "object_group":"terminal", "object_type":"control_terminal", "operational_state":"active", "is_powered":powered, "power_state":"powered" if powered else "unpowered"}

func binding(id: String, role: String, source_id: String, target_id: String, factor_id: String = "") -> Dictionary:
	var parameters := {}
	if not factor_id.is_empty():
		parameters["factor_id"] = factor_id
	return {"id":id, "role":role, "source_id":source_id, "target_id":target_id, "parameters":parameters, "format_version":BindingContract.FORMAT_VERSION}

func index(values: Array) -> Dictionary:
	var result := {}
	for value in values:
		result[str(value.get("id", ""))] = value
	return result

func _run() -> void:
	await process_frame

	var open_target := target("open", "none")
	var open_result := Resolver.resolve(open_target, {}, [], index([open_target]))
	check(open_result.granted and open_result.code == Resolver.CODE_NOT_REQUIRED, "none access failed")

	var door := target("door", "key_card")
	var reusable := item("reusable", "key_card")
	var key_binding := binding("key_binding", BindingContract.ROLE_ACCESS_ITEM, "reusable", "door")
	var key_result := Resolver.resolve(door, {"credential_ids":["reusable"]}, [key_binding], index([door, reusable]))
	check(key_result.granted, "reusable key rejected")
	check(not bool(key_result.consumption_plan[0].consume_on_use), "key card consumed by default")
	var kept := Resolver.apply_consumption_plan({"pocket_items":["reusable"]}, key_result.consumption_plan)
	check(kept.inventory.pocket_items.has("reusable"), "reusable key removed")

	var single_use := item("single", "key_card", true)
	var single_result := Resolver.resolve(door, {"credential_ids":["single"]}, [binding("single_binding", BindingContract.ROLE_ACCESS_ITEM, "single", "door")], index([door, single_use]))
	var consumed := Resolver.apply_consumption_plan({"pocket_items":["single"]}, single_result.consumption_plan)
	check(not consumed.inventory.pocket_items.has("single"), "single-use key remained")
	check(consumed.consumed_item_ids.has("single"), "consumed id missing")

	var missing := Resolver.resolve(door, {}, [key_binding], index([door, reusable]))
	check(missing.reason_code == Resolver.CODE_CREDENTIAL_MISSING, "missing credential code changed")
	var no_binding := Resolver.resolve(door, {"credential_ids":["reusable"]}, [], index([door, reusable]))
	check(no_binding.reason_code == Resolver.CODE_BINDING_MISSING, "missing binding code changed")

	for row in [
		{"id":"damaged", "field":"damaged", "code":Resolver.CODE_CREDENTIAL_DAMAGED},
		{"id":"encrypted", "field":"encrypted", "code":Resolver.CODE_CREDENTIAL_ENCRYPTED},
		{"id":"invalid", "field":"invalid", "code":Resolver.CODE_CREDENTIAL_INVALID}
	]:
		var credential := item(row.id, "key_card")
		credential[row.field] = true
		var result := Resolver.resolve(door, {"credential_ids":[row.id]}, [binding("b_" + row.id, BindingContract.ROLE_ACCESS_ITEM, row.id, "door")], index([door, credential]))
		check(result.reason_code == row.code, row.id + " code changed")

	var terminal_target := target("terminal_target", "terminal")
	var console := terminal("console")
	var access_link := binding("access_link", BindingContract.ROLE_ACCESS_TERMINAL, "console", "terminal_target")
	var control_link := binding("control_link", BindingContract.ROLE_CONTROL_TERMINAL, "console", "terminal_target")
	var terminal_result := Resolver.resolve(terminal_target, {"terminal_id":"console"}, [access_link, control_link], index([terminal_target, console]))
	check(terminal_result.granted, "access terminal rejected")
	var control_only := Resolver.resolve(terminal_target, {"terminal_id":"console"}, [control_link], index([terminal_target, console]))
	check(control_only.reason_code == Resolver.CODE_BINDING_MISSING, "control role satisfied access")
	console["is_powered"] = false
	console["power_state"] = "unpowered"
	var terminal_off := Resolver.resolve(terminal_target, {"terminal_id":"console"}, [access_link], index([terminal_target, console]))
	check(terminal_off.reason_code == Resolver.CODE_TERMINAL_UNPOWERED, "terminal power code changed")

	var profile := {
		"access_type":"multi_factor",
		"root":{"operator":"all_of", "children":[{"access_type":"key_card", "factor_id":"badge"}, {"group_ref":"remote"}]},
		"groups":{"remote":{"operator":"any_of", "children":[{"access_type":"digital_key", "factor_id":"digital"}, {"access_type":"terminal", "factor_id":"console"}]}}
	}
	var multi := target("multi", "multi_factor", profile)
	var badge := item("badge", "key_card")
	var digital := item("digital", "digital_key")
	var remote := terminal("remote")
	var links := [
		binding("badge_link", BindingContract.ROLE_ACCESS_ITEM, "badge", "multi", "badge"),
		binding("digital_link", BindingContract.ROLE_ACCESS_ITEM, "digital", "multi", "digital"),
		binding("remote_link", BindingContract.ROLE_ACCESS_TERMINAL, "remote", "multi", "console")
	]
	var entities := index([multi, badge, digital, remote])
	var multi_ok := Resolver.resolve(multi, {"credential_ids":["badge"], "terminal_id":"remote"}, links, entities)
	check(multi_ok.granted and multi_ok.branch_results.size() == 2, "nested multi-factor failed")
	var multi_fail := Resolver.resolve(multi, {"credential_ids":["badge"]}, links, entities)
	check(not multi_fail.granted and not multi_fail.first_blocking_reason_code.is_empty(), "multi-factor blocker missing")

	var cycle := target("cycle", "multi_factor", {"access_type":"multi_factor", "root":{"group_ref":"a"}, "groups":{"a":{"group_ref":"b"}, "b":{"group_ref":"a"}}})
	var cycle_validation := Resolver.validate_profile(cycle)
	check(not cycle_validation.success and cycle_validation.reason_code == Resolver.CODE_CYCLE, "cycle validation failed")
	var cycle_result := Resolver.resolve(cycle, {}, [], index([cycle]))
	check(cycle_result.reason_code == Resolver.CODE_CYCLE, "cycle resolve code changed")

	if failures.is_empty():
		print("ACCESS_RESOLVER_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("ACCESS_RESOLVER_GATE: FAIL: %s" % failure)
	quit(1)
