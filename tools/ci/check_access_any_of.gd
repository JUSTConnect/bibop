extends SceneTree

const Resolver = preload("res://scripts/world/access_resolver.gd")
const BindingContract = preload("res://scripts/world/world_binding_store_contract.gd")

func _init() -> void:
	call_deferred("run")

func run() -> void:
	await process_frame
	var target := {
		"id":"choice",
		"object_group":"door",
		"object_type":"door",
		"access_type":"multi_factor",
		"access_profile_data":{
			"access_type":"multi_factor",
			"root":{"operator":"any_of", "children":[
				{"access_type":"key_card", "factor_id":"first"},
				{"access_type":"key_card", "factor_id":"second"}
			]}
		}
	}
	var first := {"id":"first", "object_group":"item", "object_type":"item", "item_class":"key_card", "access_type":"key_card", "consume_on_use":true}
	var second := {"id":"second", "object_group":"item", "object_type":"item", "item_class":"key_card", "access_type":"key_card", "consume_on_use":true}
	var bindings: Array[Dictionary] = [
		{"id":"a_first", "role":BindingContract.ROLE_ACCESS_ITEM, "source_id":"first", "target_id":"choice", "parameters":{"factor_id":"first"}, "format_version":BindingContract.FORMAT_VERSION},
		{"id":"b_second", "role":BindingContract.ROLE_ACCESS_ITEM, "source_id":"second", "target_id":"choice", "parameters":{"factor_id":"second"}, "format_version":BindingContract.FORMAT_VERSION}
	]
	var entities := {"choice":target, "first":first, "second":second}
	var result := Resolver.resolve(target, {"credential_ids":["first", "second"]}, bindings, entities)
	if not bool(result.get("granted", false)):
		printerr("ACCESS_ANY_OF_GATE: FAIL: alternatives rejected")
		quit(1)
		return
	var plan: Array = Array(result.get("consumption_plan", []))
	if plan.size() != 1 or str(Dictionary(plan[0]).get("item_id", "")) != "first":
		printerr("ACCESS_ANY_OF_GATE: FAIL: any_of selected multiple alternatives")
		quit(1)
		return
	print("ACCESS_ANY_OF_GATE: OK")
	quit(0)
