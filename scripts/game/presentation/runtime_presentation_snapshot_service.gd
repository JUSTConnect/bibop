extends RefCounted
class_name RuntimePresentationSnapshotService

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const EntityStatusEvaluatorRef = preload("res://scripts/world/entity_status_evaluator.gd")
const PowerControlResolverRef = preload("res://scripts/world/power_control_resolver.gd")
const AccessResolverRef = preload("res://scripts/world/access_resolver.gd")
const BindingContractRef = preload("res://scripts/world/world_binding_store_contract.gd")
const RequirementCatalogRef = preload("res://scripts/game/presentation/runtime_requirement_catalog.gd")

const PASSIVE_ACTIONS: Array[String] = ["scan", "diagnose", "diagnostics", "inspect", "properties", "view_properties"]
const STATUS_ORDER: Array[String] = ["intent", "operational", "health", "thermal", "energy", "power", "control", "access"]

static func build(controller: Variant, target_object: Dictionary, target_position: Vector2i, action_view_model: Dictionary, context: Dictionary = {}) -> Dictionary:
	var source: Dictionary = target_object.duplicate(true)
	var debug_enabled: bool = str(context.get("mode", "runtime")).strip_edges().to_lower() in ["task_test", "task_test_context", "debug"] or bool(context.get("debug", false))
	var world_context: Dictionary = _world_context(controller, source, context)
	var entity_id: String = str(source.get("id", ""))
	var resolved: Dictionary = PowerControlResolverRef.resolve_world(_dictionary_array(world_context.get("objects", [])), _dictionary_array(world_context.get("bindings", [])), {"entity_id":entity_id})
	var power_result: Dictionary = Dictionary(Dictionary(resolved.get("power_results", {})).get(entity_id, {}))
	var control_result: Dictionary = Dictionary(Dictionary(resolved.get("control_results", {})).get(entity_id, {}))
	var access_context: Dictionary = Dictionary(context.get("access_context", {})).duplicate(true)
	if context.has("inventory"):
		access_context["inventory"] = Dictionary(context.get("inventory", {})).duplicate(true)
	var access_result: Dictionary = AccessResolverRef.resolve(source, access_context, _dictionary_array(world_context.get("bindings", [])), Dictionary(world_context.get("entities_by_id", {})))
	var status_eval: Dictionary = EntityStatusEvaluatorRef.evaluate(source, context.duplicate(true))
	var control: Dictionary = _control_section(control_result)
	var actions: Array[Dictionary] = _actions(action_view_model, source, control, debug_enabled)
	var requirements: Array = []
	for action in actions:
		requirements.append_array(Array(action.get("requirements", [])))
	var access: Dictionary = _access_section(source, access_result, context, debug_enabled)
	var snapshot: Dictionary = {
		"identity":_identity(source),
		"status":_status_rows(status_eval, debug_enabled),
		"power":_power_section(power_result),
		"control":control,
		"access":access,
		"requirements":RequirementCatalogRef.deduplicate(requirements),
		"bindings":_bindings(source, _dictionary_array(world_context.get("bindings", [])), Dictionary(world_context.get("entities_by_id", {})), control, access, debug_enabled),
		"actions":actions,
		"notification":_notification(Dictionary(context.get("notification", {})), debug_enabled),
		"signature":"",
		"debug":{}
	}
	if debug_enabled:
		snapshot["debug"] = {"target_id":entity_id, "target_position":target_position, "real_values":Dictionary(status_eval.get("real_values", {})).duplicate(true), "forced_values":Dictionary(status_eval.get("forced_values", {})).duplicate(true), "raw_actions":Array(action_view_model.get("actions", [])).duplicate(true), "raw_bindings":Array(world_context.get("bindings", [])).duplicate(true), "power_result":power_result, "control_result":control_result, "access_result":access_result}
	var unsigned: Dictionary = snapshot.duplicate(true)
	unsigned.erase("signature")
	snapshot["signature"] = str(hash(JSON.stringify(_canonical(unsigned))))
	return snapshot

static func _world_context(controller: Variant, source: Dictionary, context: Dictionary) -> Dictionary:
	var objects: Array[Dictionary] = _dictionary_array(context.get("objects", []))
	var bindings: Array[Dictionary] = _dictionary_array(context.get("bindings", []))
	if controller != null and controller.get("mission_manager") != null:
		var manager: Variant = controller.get("mission_manager")
		var store: Variant = manager.get("world_state_store")
		if objects.is_empty() and store != null and store.has_method("get_all_objects"):
			objects = _dictionary_array(store.call("get_all_objects"))
		if bindings.is_empty() and store != null and store.has_method("get_all_bindings"):
			bindings = _dictionary_array(store.call("get_all_bindings"))
	var target_id: String = str(source.get("id", ""))
	var replaced: bool = false
	for index in range(objects.size()):
		if not target_id.is_empty() and str(objects[index].get("id", "")) == target_id:
			objects[index] = source.duplicate(true)
			replaced = true
			break
	if not replaced:
		objects.append(source.duplicate(true))
	var entities_by_id: Dictionary = {}
	for object_data in objects:
		var object_id: String = str(object_data.get("id", ""))
		if not object_id.is_empty():
			entities_by_id[object_id] = object_data.duplicate(true)
	return {"objects":objects, "bindings":bindings, "entities_by_id":entities_by_id}

static func _identity(source: Dictionary) -> Dictionary:
	var contract: Dictionary = WorldObjectCatalogRef.get_entity_definition_contract_for_object(source)
	var result: Dictionary = {"display_name":str(source.get("display_name", source.get("name", contract.get("display_name_template", "Interactable")))).strip_edges(), "type_label":str(contract.get("palette_label", source.get("object_group", source.get("type", "")))).strip_edges(), "object_class":str(source.get("object_group", source.get("object_type", ""))).strip_edges(), "description":str(contract.get("description", source.get("description", ""))).strip_edges()}
	var subtype: String = str(source.get("subtype_label", contract.get("subtype_label", ""))).strip_edges()
	if not subtype.is_empty(): result["subtype_label"] = subtype
	return result

static func _status_rows(status_eval: Dictionary, debug_enabled: bool) -> Array[Dictionary]:
	var sections: Dictionary = Dictionary(status_eval.get("sections", {}))
	var rows: Array[Dictionary] = []
	for code in STATUS_ORDER:
		if not sections.has(code): continue
		var section: Dictionary = Dictionary(sections.get(code, {}))
		var row: Dictionary = {"label":code.capitalize(), "value":str(section.get("value", ""))}
		if debug_enabled:
			row["section_code"] = code
			row["reason_code"] = str(status_eval.get("reason_code", ""))
			row["real_values"] = Dictionary(status_eval.get("real_values", {})).duplicate(true)
			row["forced_values"] = Dictionary(status_eval.get("forced_values", {})).duplicate(true)
		rows.append(row)
	return rows

static func _power_section(result: Dictionary) -> Dictionary:
	return {"mode":str(result.get("power_mode", "none")), "state":str(result.get("power_state", "none")), "powered":bool(result.get("is_powered", true)), "reason_code":str(result.get("reason_code", ""))}

static func _control_section(result: Dictionary) -> Dictionary:
	return {"mode":str(result.get("control_mode", "none")), "available":bool(result.get("available", false)), "local":bool(result.get("local_control_available", false)), "external":bool(result.get("remote_control_available", false)), "controller_id":str(result.get("resolved_controller_id", "")), "reason_code":str(result.get("reason_code", ""))}

static func _access_section(source: Dictionary, result: Dictionary, context: Dictionary, debug_enabled: bool) -> Dictionary:
	var access_type: String = str(result.get("access_type", AccessResolverRef.normalize_access_type(source.get("access_type", source.get("lock_type", "none")))))
	var row: Dictionary = {"access_type":access_type, "granted":bool(result.get("success", false)), "reason_code":str(result.get("reason_code", "")), "show_keypad":access_type == AccessResolverRef.ACCESS_CODE, "access_code_entry":str(context.get("access_code_entry", source.get("access_code_entry", ""))), "max_digits":int(source.get("access_code_digits", 4)), "actions":["access_code_0", "access_code_1", "access_code_2", "access_code_3", "access_code_4", "access_code_5", "access_code_6", "access_code_7", "access_code_8", "access_code_9", "input_password"]}
	if debug_enabled: row["technical"] = result.duplicate(true)
	return row

static func _actions(view_model: Dictionary, source: Dictionary, control: Dictionary, debug_enabled: bool) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var external_control: bool = str(control.get("mode", "none")) == "external"
	var local_hack_allowed: bool = bool(source.get("local_hack_enabled", source.get("allow_local_hack", false)))
	for value in Array(view_model.get("actions", [])):
		if not value is Dictionary: continue
		var action: Dictionary = Dictionary(value)
		var code: String = str(action.get("action_code", action.get("id", ""))).strip_edges().to_lower()
		if external_control and code not in PASSIVE_ACTIONS and not (code == "hack" and local_hack_allowed): continue
		var available: bool = bool(action.get("available", action.get("enabled", false)))
		var row: Dictionary = {"action_code":code, "label_key":str(action.get("label_key", "action.%s.label" % code)), "available":available, "reason_code":str(action.get("reason_code", action.get("reason", ""))), "requirements":RequirementCatalogRef.deduplicate(Array(action.get("requirements", []))), "context":_safe_context(Dictionary(action.get("context", {}))), "id":str(action.get("id", code)), "label":str(action.get("label", code.capitalize())), "enabled":available, "reason":str(action.get("reason", action.get("reason_code", ""))), "priority":int(action.get("priority", 100))}
		if debug_enabled:
			row["target_id"] = str(action.get("target_id", ""))
			row["module_id"] = str(action.get("module_id", ""))
			row["module"] = Dictionary(action.get("module", {})).duplicate(true)
			row["gate"] = Dictionary(action.get("gate", {})).duplicate(true)
		rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("action_code", "")) < str(b.get("action_code", "")))
	return rows

static func _bindings(source: Dictionary, bindings: Array[Dictionary], entities: Dictionary, control: Dictionary, access: Dictionary, debug_enabled: bool) -> Array[Dictionary]:
	var target_id: String = str(source.get("id", ""))
	var rows: Array[Dictionary] = []
	for binding in bindings:
		var role: String = str(binding.get("role", ""))
		var source_id: String = str(binding.get("source_id", ""))
		var bound_target: String = str(binding.get("target_id", ""))
		var row: Dictionary = {}
		if role == BindingContractRef.ROLE_CONTROL_TERMINAL and bound_target == target_id:
			row = {"role":"Controlled by", "source_name":_name(Dictionary(entities.get(source_id, {}))), "state":"Available" if bool(control.get("available", false)) else "Unavailable"}
		elif role == BindingContractRef.ROLE_CONTROL_TERMINAL and source_id == target_id:
			row = {"role":"Controls", "source_name":_name(Dictionary(entities.get(bound_target, {}))), "state":"Bound"}
		elif role == BindingContractRef.ROLE_ACCESS_TERMINAL and bound_target == target_id:
			row = {"role":"Access terminal", "source_name":_name(Dictionary(entities.get(source_id, {}))), "state":"Available" if bool(access.get("granted", false)) else "Required"}
		elif role == BindingContractRef.ROLE_ACCESS_ITEM and bound_target == target_id:
			row = {"role":"Requires", "source_name":_credential_name(Dictionary(entities.get(source_id, {}))), "state":"Available" if bool(access.get("granted", false)) else "Required"}
		elif role == BindingContractRef.ROLE_PREFERRED_POWER_SOURCE and source_id == target_id:
			row = {"role":"Preferred power source", "source_name":_name(Dictionary(entities.get(bound_target, {}))), "state":"Selected"}
		else: continue
		if debug_enabled:
			row["binding_id"] = str(binding.get("id", ""))
			row["source_id"] = source_id
			row["target_id"] = bound_target
			row["parameters"] = Dictionary(binding.get("parameters", {})).duplicate(true)
		rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return "%s|%s" % [a.get("role", ""), a.get("source_name", "")] < "%s|%s" % [b.get("role", ""), b.get("source_name", "")])
	return rows

static func _notification(event: Dictionary, debug_enabled: bool) -> Dictionary:
	if event.is_empty(): return {}
	var row: Dictionary = {"result":str(event.get("result", "")), "message_key":str(event.get("message_key", "")), "fallback":str(event.get("fallback", event.get("message", ""))), "player_action":bool(event.get("player_action", false))}
	if debug_enabled:
		row["event_id"] = str(event.get("event_id", ""))
		row["action_id"] = str(event.get("action_id", ""))
		row["code"] = str(event.get("code", ""))
	return row

static func _safe_context(value: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in ["target_type", "channel", "interaction_mode", "access_type"]:
		if value.has(key): result[key] = value[key]
	return result

static func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for item in Array(value):
			if item is Dictionary: result.append(Dictionary(item).duplicate(true))
	return result

static func _name(entity: Dictionary) -> String:
	return "Missing entity" if entity.is_empty() else str(entity.get("display_name", entity.get("name", entity.get("object_type", entity.get("object_group", "Entity"))))).strip_edges().capitalize()

static func _credential_name(entity: Dictionary) -> String:
	match AccessResolverRef.normalize_access_type(entity.get("access_type", entity.get("item_class", "key_card"))):
		AccessResolverRef.ACCESS_DIGITAL_KEY: return "Digital key"
		AccessResolverRef.ACCESS_CODE: return "Access code"
		_: return "Key card"

static func _canonical(value: Variant) -> Variant:
	if value is Dictionary:
		var keys: Array = Dictionary(value).keys()
		keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
		var result: Dictionary = {}
		for key in keys: result[str(key)] = _canonical(Dictionary(value)[key])
		return result
	if value is Array:
		var array_result: Array = []
		for item in Array(value): array_result.append(_canonical(item))
		return array_result
	if value is Vector2i: return {"x":value.x, "y":value.y}
	if value is Vector2: return {"x":value.x, "y":value.y}
	return value
