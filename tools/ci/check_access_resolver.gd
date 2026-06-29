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
	var value: Dictionary = {"id":id, "object_group":"door", "object_type":"door", "access_type":access_type, "locked":true, "is_locked":true}
	if not profile.is_empty():
		value["access_profile_data"] = profile.duplicate(true)
	return value

func item(id: String, access_type: String, consume: bool = false) -> Dictionary:
	return {"id":id, "object_group":"item", "object_type":"item", "item_class":access_type, "access_type":access_type, "credential_state":"valid", "consume_on_use":consume}

func terminal(id: String, powered: bool = true) -> Dictionary:
	return {"id":id, "object_group":"terminal", "object_type":"control_terminal", "operational_state":"active", "is_powered":powered, "power_state":"powered" if powered else "unpowered"}

func binding(id: String, role: String, source_id: String, target_id: String, factor_id: String = "") -> Dictionary:
	var parameters: Dictionary = {}
	if not factor_id.is_empty():
		parameters["factor_id"] = factor_id
	return {"id":id, "role":role, "source_id":source_id, "target_id":target_id, "parameters":parameters, "format_version":BindingContract.FORMAT_VERSION}

func index(values: Array) -> Dictionary:
	var result: Dictionary = {}
	for value in values:
		if value is Dictionary:
			result[str(Dictionary(value).get("id", ""))] = Dictionary(value)
	return result

func _plan(result: Dictionary) -> Array:
	return Array(result.get("consumption_plan", []))

func _run() -> void:
	await process_frame
	print("ACCESS_RESOLVER_GATE: none")
	var open_target := target("open", "none")
	var open_result: Dictionary = Resolver.resolve(open_target, {}, [], index([open_target]))
	check(bool(open_result.get("granted", false)) and str(open_result.get("code", "")) == Resolver.CODE_NO_CHANGE, "none access failed")
	check(_plan(open_result).is_empty() and Dictionary(open_result.get("target_patch", {})).is_empty(), "none access planned mutation")

	print("ACCESS_RESOLVER_GATE: reusable")
	var door := target("door", "key_card")
	var reusable := item("reusable", "key_card")
	var key_binding := binding("key_binding", BindingContract.ROLE_ACCESS_ITEM, "reusable", "door")
	var key_result: Dictionary = Resolver.resolve(door, {"credential_ids":["reusable"]}, [key_binding], index([door, reusable]))
	check(bool(key_result.get("granted", false)), "reusable key rejected")
	var key_plan: Array = _plan(key_result)
	check(key_plan.size() == 1, "reusable key plan missing")
	if key_plan.size() == 1:
		check(not bool(Dictionary(key_plan[0]).get("consume_on_use", true)), "key card consumed by default")
	var kept: Dictionary = Resolver.apply_consumption_plan({"pocket_items":["reusable"]}, key_plan)
	check(Array(Dictionary(kept.get("inventory", {})).get("pocket_items", [])).has("reusable"), "reusable key removed")

	print("ACCESS_RESOLVER_GATE: consumable")
	var single_use := item("single", "key_card", true)
	var single_result: Dictionary = Resolver.resolve(door, {"credential_ids":["single"]}, [binding("single_binding", BindingContract.ROLE_ACCESS_ITEM, "single", "door")], index([door, single_use]))
	var consumed: Dictionary = Resolver.apply_consumption_plan({"pocket_items":["single"]}, _plan(single_result))
	check(not Array(Dictionary(consumed.get("inventory", {})).get("pocket_items", [])).has("single"), "single-use key remained")
	check(Array(consumed.get("consumed_item_ids", [])).has("single"), "consumed id missing")

	print("ACCESS_RESOLVER_GATE: failures")
	var missing: Dictionary = Resolver.resolve(door, {}, [key_binding], index([door, reusable]))
	check(str(missing.get("reason_code", "")) == Resolver.CODE_CREDENTIAL_MISSING, "missing credential code changed")
	var no_binding: Dictionary = Resolver.resolve(door, {"credential_ids":["reusable"]}, [], index([door, reusable]))
	check(str(no_binding.get("reason_code", "")) == Resolver.CODE_BINDING_MISSING, "missing binding code changed")
	for row_value in [
		{"id":"damaged", "field":"damaged", "code":Resolver.CODE_CREDENTIAL_DAMAGED},
		{"id":"encrypted", "field":"encrypted", "code":Resolver.CODE_CREDENTIAL_ENCRYPTED},
		{"id":"invalid", "field":"invalid", "code":Resolver.CODE_CREDENTIAL_INVALID}
	]:
		var row: Dictionary = Dictionary(row_value)
		var row_id: String = str(row.get("id", ""))
		var credential := item(row_id, "key_card")
		credential[str(row.get("field", ""))] = true
		var result: Dictionary = Resolver.resolve(door, {"credential_ids":[row_id]}, [binding("b_%s" % row_id, BindingContract.ROLE_ACCESS_ITEM, row_id, "door")], index([door, credential]))
		check(str(result.get("reason_code", "")) == str(row.get("code", "")), "%s code changed" % row_id)

	print("ACCESS_RESOLVER_GATE: terminal")
	var terminal_target := target("terminal_target", "terminal")
	var console := terminal("console")
	var access_link := binding("access_link", BindingContract.ROLE_ACCESS_TERMINAL, "console", "terminal_target")
	var control_link := binding("control_link", BindingContract.ROLE_CONTROL_TERMINAL, "console", "terminal_target")
	var terminal_result: Dictionary = Resolver.resolve(terminal_target, {"terminal_id":"console"}, [access_link, control_link], index([terminal_target, console]))
	check(bool(terminal_result.get("granted", false)), "access terminal rejected")
	var control_only: Dictionary = Resolver.resolve(terminal_target, {"terminal_id":"console"}, [control_link], index([terminal_target, console]))
	check(str(control_only.get("reason_code", "")) == Resolver.CODE_BINDING_MISSING, "control role satisfied access")
	console["is_powered"] = false
	console["power_state"] = "unpowered"
	var terminal_off: Dictionary = Resolver.resolve(terminal_target, {"terminal_id":"console"}, [access_link], index([terminal_target, console]))
	check(str(terminal_off.get("reason_code", "")) == Resolver.CODE_TERMINAL_UNPOWERED, "terminal power code changed")

	print("ACCESS_RESOLVER_GATE: multi")
	var profile: Dictionary = {"access_type":"multi_factor", "root":{"operator":"all_of", "children":[{"access_type":"key_card", "factor_id":"badge"}, {"group_ref":"remote"}]}, "groups":{"remote":{"operator":"any_of", "children":[{"access_type":"digital_key", "factor_id":"digital"}, {"access_type":"terminal", "factor_id":"console"}]}}}
	var multi := target("multi", "multi_factor", profile)
	var badge := item("badge", "key_card")
	var digital := item("digital", "digital_key")
	var remote := terminal("remote")
	var links: Array[Dictionary] = [binding("badge_link", BindingContract.ROLE_ACCESS_ITEM, "badge", "multi", "badge"), binding("digital_link", BindingContract.ROLE_ACCESS_ITEM, "digital", "multi", "digital"), binding("remote_link", BindingContract.ROLE_ACCESS_TERMINAL, "remote", "multi", "console")]
	var entities := index([multi, badge, digital, remote])
	var multi_ok: Dictionary = Resolver.resolve(multi, {"credential_ids":["badge"], "terminal_id":"remote"}, links, entities)
	check(bool(multi_ok.get("granted", false)) and Array(multi_ok.get("branch_results", [])).size() == 2, "nested multi-factor failed")
	var multi_fail: Dictionary = Resolver.resolve(multi, {"credential_ids":["badge"]}, links, entities)
	check(not bool(multi_fail.get("granted", true)) and not str(multi_fail.get("first_blocking_reason_code", "")).is_empty(), "multi-factor blocker missing")

	print("ACCESS_RESOLVER_GATE: cycle")
	var cycle := target("cycle", "multi_factor", {"access_type":"multi_factor", "root":{"group_ref":"a"}, "groups":{"a":{"group_ref":"b"}, "b":{"group_ref":"a"}}})
	var cycle_validation: Dictionary = Resolver.validate_profile(cycle)
	check(not bool(cycle_validation.get("success", true)) and str(cycle_validation.get("reason_code", "")) == Resolver.CODE_CYCLE, "cycle validation failed")
	var cycle_result: Dictionary = Resolver.resolve(cycle, {}, [], index([cycle]))
	check(str(cycle_result.get("reason_code", "")) == Resolver.CODE_CYCLE, "cycle resolve code changed")

	if failures.is_empty():
		print("ACCESS_RESOLVER_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("ACCESS_RESOLVER_GATE: FAIL: %s" % failure)
	quit(1)
