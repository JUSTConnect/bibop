extends RefCounted
class_name NormalItemContract

const CODE_VALID := "valid"
const CODE_NOT_NORMAL_ITEM := "not_normal_item"
const CODE_AMOUNT_FORBIDDEN := "amount_forbidden"
const CODE_ITEM_MISSING := "item_missing"
const CODE_ACTION_FAILED := "action_failed"
const CODE_NOT_CONSUMABLE := "not_consumable"
const CODE_CONSUMED := "consumed"

const FORBIDDEN_STACK_FIELDS: Array[String] = [
	"amount",
	"quantity",
	"stack_size",
	"stack_count",
	"item_amount"
]

static func is_details_entry(item: Dictionary) -> bool:
	var currency_id: String = str(item.get("currency_id", "")).strip_edges().to_lower()
	var object_type: String = str(item.get("object_type", item.get("type", ""))).strip_edges().to_lower()
	var item_type: String = str(item.get("item_type", item.get("physical_item_type", ""))).strip_edges().to_lower()
	var category: String = str(item.get("category", "")).strip_edges().to_lower()
	var kind: String = str(item.get("kind", "")).strip_edges().to_lower()
	return currency_id == "details" or object_type == "details_pickup" or item_type in ["parts", "parts_small", "parts_medium", "parts_large"] or (category == "resource" and kind == "parts")

static func is_normal_item(item: Dictionary) -> bool:
	if item.is_empty() or is_details_entry(item):
		return false
	var object_group: String = str(item.get("object_group", item.get("group", ""))).strip_edges().to_lower()
	var entity_contract: Variant = item.get("entity_contract", {})
	var entity_type: String = ""
	if entity_contract is Dictionary:
		entity_type = str(Dictionary(entity_contract).get("entity_type", "")).strip_edges().to_lower()
	var item_form: String = str(item.get("item_form", "")).strip_edges().to_lower()
	return object_group == "item" or entity_type == "item" or item_form in ["physical", "digital"]

static func canonicalize(item: Dictionary) -> Dictionary:
	var result: Dictionary = item.duplicate(true)
	if not is_normal_item(result):
		return result
	for field_name in FORBIDDEN_STACK_FIELDS:
		result.erase(field_name)
	result["stackable"] = false
	return result

static func validate(item: Dictionary) -> Dictionary:
	if not is_normal_item(item):
		return _result(false, CODE_NOT_NORMAL_ITEM, item)
	for field_name in FORBIDDEN_STACK_FIELDS:
		if item.has(field_name):
			return _result(false, CODE_AMOUNT_FORBIDDEN, item, {"field": field_name})
	if bool(item.get("stackable", false)):
		return _result(false, CODE_AMOUNT_FORBIDDEN, item, {"field": "stackable"})
	return _result(true, CODE_VALID, item)

static func apply_consumption(inventory_state: Dictionary, item_id: String, item_data: Dictionary, action_result: Dictionary) -> Dictionary:
	var normalized_id: String = item_id.strip_edges()
	var next_inventory: Dictionary = inventory_state.duplicate(true)
	if normalized_id.is_empty():
		return _consumption_result(false, CODE_ITEM_MISSING, normalized_id, next_inventory, false)
	if not bool(action_result.get("success", false)):
		return _consumption_result(false, CODE_ACTION_FAILED, normalized_id, next_inventory, false)
	if not bool(item_data.get("consumable", false)):
		return _consumption_result(true, CODE_NOT_CONSUMABLE, normalized_id, next_inventory, false)

	var pocket_items: Array = Array(next_inventory.get("pocket_items", [])).duplicate(true)
	pocket_items = pocket_items.filter(func(value: Variant) -> bool: return _item_id(value) != normalized_id)
	next_inventory["pocket_items"] = pocket_items
	if _item_id(next_inventory.get("manipulator_hold", "")) == normalized_id:
		next_inventory["manipulator_hold"] = ""
	var box_storage: Array = Array(next_inventory.get("box_storage", [])).duplicate(true)
	box_storage = box_storage.filter(func(value: Variant) -> bool: return _item_id(value) != normalized_id)
	next_inventory["box_storage"] = box_storage
	var runtime_map: Dictionary = Dictionary(next_inventory.get("world_item_runtime", {})).duplicate(true)
	runtime_map.erase(normalized_id)
	next_inventory["world_item_runtime"] = runtime_map
	var consumed_ids: Array = Array(next_inventory.get("consumed_item_ids", [])).duplicate()
	if not consumed_ids.has(normalized_id):
		consumed_ids.append(normalized_id)
	next_inventory["consumed_item_ids"] = consumed_ids
	return _consumption_result(true, CODE_CONSUMED, normalized_id, next_inventory, true)

static func _item_id(value: Variant) -> String:
	if value is String or value is StringName:
		return str(value).strip_edges()
	if value is Dictionary:
		var item: Dictionary = Dictionary(value)
		return str(item.get("id", item.get("item_id", ""))).strip_edges()
	return ""

static func _result(success: bool, code: String, item: Dictionary, details: Dictionary = {}) -> Dictionary:
	return {
		"ok": success,
		"success": success,
		"code": code,
		"reason_code": code,
		"item_id": _item_id(item),
		"details": details.duplicate(true)
	}

static func _consumption_result(success: bool, code: String, item_id: String, inventory: Dictionary, consumed: bool) -> Dictionary:
	return {
		"ok": success,
		"success": success,
		"code": code,
		"reason_code": code,
		"item_id": item_id,
		"consumed": consumed,
		"inventory": inventory
	}
