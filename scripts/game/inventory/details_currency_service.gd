extends RefCounted
class_name DetailsCurrencyService

const FORMAT_VERSION: int = 1
const CURRENCY_ID := "details"
const DISPLAY_NAME_EN := "Details"
const DISPLAY_NAME_RU := "Детали"

const CODE_VALID := "valid"
const CODE_RECEIVED := "received"
const CODE_SPENT := "spent"
const CODE_DUPLICATE_REWARD := "duplicate_reward"
const CODE_DUPLICATE_TRANSACTION := "duplicate_transaction"
const CODE_INVALID_AMOUNT := "invalid_amount"
const CODE_INSUFFICIENT := "insufficient"
const CODE_INVALID_SNAPSHOT := "invalid_snapshot"
const CODE_MIGRATED := "migrated"

const LEGACY_PART_TYPES: Array[String] = ["parts", "parts_small", "parts_medium", "parts_large"]
const LEGACY_PART_AMOUNTS: Dictionary = {
	"parts": 1,
	"parts_small": 5,
	"parts_medium": 10,
	"parts_large": 20
}

var _balance: int = 0
var _processed_reward_ids: Dictionary = {}
var _processed_transaction_ids: Dictionary = {}

func get_balance() -> int:
	return _balance

func has_processed_reward(reward_id: String) -> bool:
	return _processed_reward_ids.has(reward_id.strip_edges())

func has_processed_transaction(transaction_id: String) -> bool:
	return _processed_transaction_ids.has(transaction_id.strip_edges())

func get_snapshot() -> Dictionary:
	var reward_ids: Array = _processed_reward_ids.keys()
	reward_ids.sort()
	var transaction_ids: Array = _processed_transaction_ids.keys()
	transaction_ids.sort()
	return {
		"format_version": FORMAT_VERSION,
		"currency_id": CURRENCY_ID,
		"balance": _balance,
		"processed_reward_ids": reward_ids,
		"processed_transaction_ids": transaction_ids
	}

func replace_snapshot(snapshot: Dictionary) -> Dictionary:
	if int(snapshot.get("format_version", FORMAT_VERSION)) > FORMAT_VERSION:
		return _result(false, CODE_INVALID_SNAPSHOT, 0, "", "", {"reason": "unsupported_format_version"})
	var next_balance: int = int(snapshot.get("balance", 0))
	if next_balance < 0:
		return _result(false, CODE_INVALID_SNAPSHOT, 0, "", "", {"reason": "negative_balance"})
	var next_rewards: Dictionary = {}
	for value in Array(snapshot.get("processed_reward_ids", [])):
		var reward_id: String = str(value).strip_edges()
		if not reward_id.is_empty():
			next_rewards[reward_id] = true
	var next_transactions: Dictionary = {}
	for value in Array(snapshot.get("processed_transaction_ids", [])):
		var transaction_id: String = str(value).strip_edges()
		if not transaction_id.is_empty():
			next_transactions[transaction_id] = true
	_balance = next_balance
	_processed_reward_ids = next_rewards
	_processed_transaction_ids = next_transactions
	return _result(true, CODE_VALID, 0, "", "", {"balance": _balance})

func preview_receive(amount: int, reward_id: String, source: String = "") -> Dictionary:
	var normalized_reward_id: String = reward_id.strip_edges()
	if amount <= 0:
		return _result(false, CODE_INVALID_AMOUNT, amount, normalized_reward_id, source)
	if not normalized_reward_id.is_empty() and _processed_reward_ids.has(normalized_reward_id):
		return _result(true, CODE_DUPLICATE_REWARD, amount, normalized_reward_id, source, {"balance_after": _balance})
	return _result(true, CODE_RECEIVED, amount, normalized_reward_id, source, {"balance_after": _balance + amount})

func receive(amount: int, reward_id: String, source: String = "") -> Dictionary:
	var preview: Dictionary = preview_receive(amount, reward_id, source)
	if not bool(preview.get("success", false)):
		return preview
	if str(preview.get("code", "")) == CODE_DUPLICATE_REWARD:
		return preview
	var balance_before: int = _balance
	_balance += amount
	var normalized_reward_id: String = reward_id.strip_edges()
	if not normalized_reward_id.is_empty():
		_processed_reward_ids[normalized_reward_id] = true
	return _result(true, CODE_RECEIVED, amount, normalized_reward_id, source, {
		"balance_before": balance_before,
		"balance_after": _balance
	}, _build_notification_event("details_received", normalized_reward_id, amount))

func preview_spend(amount: int, transaction_id: String = "", source: String = "") -> Dictionary:
	var normalized_transaction_id: String = transaction_id.strip_edges()
	if amount <= 0:
		return _result(false, CODE_INVALID_AMOUNT, amount, normalized_transaction_id, source)
	if not normalized_transaction_id.is_empty() and _processed_transaction_ids.has(normalized_transaction_id):
		return _result(true, CODE_DUPLICATE_TRANSACTION, amount, normalized_transaction_id, source, {"balance_after": _balance})
	if _balance < amount:
		return _result(false, CODE_INSUFFICIENT, amount, normalized_transaction_id, source, {
			"balance_before": _balance,
			"balance_after": _balance,
			"missing": amount - _balance
		})
	return _result(true, CODE_SPENT, amount, normalized_transaction_id, source, {"balance_after": _balance - amount})

func spend(amount: int, transaction_id: String = "", source: String = "") -> Dictionary:
	var preview: Dictionary = preview_spend(amount, transaction_id, source)
	if not bool(preview.get("success", false)):
		return preview
	if str(preview.get("code", "")) == CODE_DUPLICATE_TRANSACTION:
		return preview
	var balance_before: int = _balance
	_balance -= amount
	var normalized_transaction_id: String = transaction_id.strip_edges()
	if not normalized_transaction_id.is_empty():
		_processed_transaction_ids[normalized_transaction_id] = true
	return _result(true, CODE_SPENT, amount, normalized_transaction_id, source, {
		"balance_before": balance_before,
		"balance_after": _balance
	}, _build_notification_event("details_spent", normalized_transaction_id, amount))

func migrate_legacy_parts(inventory_state: Dictionary, center_storage: Dictionary = {}, migration_id: String = "legacy_parts_v1") -> Dictionary:
	var next_inventory: Dictionary = inventory_state.duplicate(true)
	var next_center_storage: Dictionary = center_storage.duplicate(true)
	var runtime_map: Dictionary = Dictionary(next_inventory.get("world_item_runtime", {})).duplicate(true)
	var item_amounts: Dictionary = Dictionary(next_inventory.get("item_amounts", {})).duplicate(true)
	var migrated_ids: Dictionary = {}
	var migrated_amount: int = 0

	for field_name in ["pocket_items", "box_storage"]:
		var filtered: Array = []
		for value in Array(next_inventory.get(field_name, [])):
			var item_id: String = _item_id(value)
			var item_data: Dictionary = _item_data_for_id(value, item_id, runtime_map)
			if is_details_entry(item_data, item_id):
				if not migrated_ids.has(item_id):
					migrated_amount += _legacy_inventory_amount(item_data, item_id, item_amounts)
					migrated_ids[item_id] = true
				continue
			filtered.append(value)
		next_inventory[field_name] = filtered

	var held_id: String = _item_id(next_inventory.get("manipulator_hold", ""))
	var held_data: Dictionary = _item_data_for_id(next_inventory.get("manipulator_hold", ""), held_id, runtime_map)
	if is_details_entry(held_data, held_id):
		if not migrated_ids.has(held_id):
			migrated_amount += _legacy_inventory_amount(held_data, held_id, item_amounts)
			migrated_ids[held_id] = true
		next_inventory["manipulator_hold"] = ""

	for runtime_id_value in runtime_map.keys():
		var runtime_id: String = str(runtime_id_value)
		var runtime_row: Dictionary = Dictionary(runtime_map[runtime_id])
		var runtime_data: Dictionary = Dictionary(runtime_row.get("item_data", runtime_row))
		if not is_details_entry(runtime_data, runtime_id):
			continue
		if bool(runtime_row.get("in_inventory", false)) and not migrated_ids.has(runtime_id):
			migrated_amount += _legacy_inventory_amount(runtime_data, runtime_id, item_amounts)
			migrated_ids[runtime_id] = true
		runtime_map.erase(runtime_id)
		item_amounts.erase(runtime_id)

	for migrated_id_value in migrated_ids.keys():
		item_amounts.erase(str(migrated_id_value))
	next_inventory["world_item_runtime"] = runtime_map
	next_inventory.erase("item_amounts")

	migrated_amount += maxi(0, int(next_center_storage.get("parts", 0)))
	next_center_storage.erase("parts")
	var center_items: Array = []
	for value in Array(next_center_storage.get("items", [])):
		if value is Dictionary and is_details_entry(Dictionary(value), _item_id(value)):
			migrated_amount += get_entry_amount(Dictionary(value))
			continue
		center_items.append(value)
	next_center_storage["items"] = center_items

	var receipt: Dictionary = receive(migrated_amount, migration_id, "legacy_parts_migration") if migrated_amount > 0 else _result(true, CODE_MIGRATED, 0, migration_id, "legacy_parts_migration", {"balance_after": _balance})
	return {
		"ok": bool(receipt.get("success", false)),
		"success": bool(receipt.get("success", false)),
		"code": CODE_MIGRATED if bool(receipt.get("success", false)) else str(receipt.get("code", CODE_INVALID_SNAPSHOT)),
		"reason_code": CODE_MIGRATED if bool(receipt.get("success", false)) else str(receipt.get("reason_code", CODE_INVALID_SNAPSHOT)),
		"migrated_amount": migrated_amount,
		"migrated_item_ids": migrated_ids.keys(),
		"inventory_state": next_inventory,
		"center_storage": next_center_storage,
		"currency_result": receipt,
		"balance": _balance
	}

static func migrate_world_pickups(objects: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for object_data in objects:
		if is_details_entry(object_data, _item_id(object_data)):
			result.append(make_details_pickup(object_data))
		else:
			result.append(object_data.duplicate(true))
	return result

static func make_details_pickup(source: Dictionary) -> Dictionary:
	var result: Dictionary = source.duplicate(true)
	var amount: int = get_entry_amount(result)
	result["object_group"] = "item"
	result["group"] = "item"
	result["object_type"] = "details_pickup"
	result["item_type"] = "details"
	result["currency_id"] = CURRENCY_ID
	result["display_name"] = DISPLAY_NAME_RU
	result["item_form"] = "currency_pickup"
	result["storage_type"] = "none"
	result["storage_route"] = "none"
	result["can_pickup"] = true
	result["amount"] = amount
	result["stackable"] = false
	for field_name in ["physical_item_type", "item_class", "consumable", "fits_targets"]:
		result.erase(field_name)
	return result

static func is_details_entry(entry: Dictionary, fallback_id: String = "") -> bool:
	var currency_id: String = str(entry.get("currency_id", "")).strip_edges().to_lower()
	var object_type: String = str(entry.get("object_type", entry.get("type", ""))).strip_edges().to_lower()
	var item_type: String = str(entry.get("item_type", entry.get("physical_item_type", fallback_id))).strip_edges().to_lower()
	var category: String = str(entry.get("category", "")).strip_edges().to_lower()
	var kind: String = str(entry.get("kind", "")).strip_edges().to_lower()
	var entry_id: String = str(entry.get("id", fallback_id)).strip_edges().to_lower()
	return currency_id == CURRENCY_ID or object_type == "details_pickup" or item_type in LEGACY_PART_TYPES or entry_id in LEGACY_PART_TYPES or (category == "resource" and kind == "parts")

static func get_entry_amount(entry: Dictionary) -> int:
	var explicit_amount: int = int(entry.get("amount", 0))
	if explicit_amount > 0:
		return explicit_amount
	for field_name in ["item_type", "physical_item_type", "id"]:
		var token: String = str(entry.get(field_name, "")).strip_edges().to_lower()
		if LEGACY_PART_AMOUNTS.has(token):
			return int(LEGACY_PART_AMOUNTS[token])
	return 1

static func _legacy_inventory_amount(item_data: Dictionary, item_id: String, item_amounts: Dictionary) -> int:
	if item_amounts.has(item_id):
		return maxi(0, int(item_amounts[item_id]))
	return get_entry_amount(item_data)

static func _item_data_for_id(value: Variant, item_id: String, runtime_map: Dictionary) -> Dictionary:
	if value is Dictionary:
		return Dictionary(value)
	var runtime_row: Dictionary = Dictionary(runtime_map.get(item_id, {}))
	return Dictionary(runtime_row.get("item_data", runtime_row))

static func _item_id(value: Variant) -> String:
	if value is String or value is StringName:
		return str(value).strip_edges()
	if value is Dictionary:
		var item: Dictionary = Dictionary(value)
		return str(item.get("id", item.get("item_id", ""))).strip_edges()
	return ""

func _result(success: bool, code: String, amount: int, operation_id: String, source: String, details: Dictionary = {}, notification_event: Dictionary = {}) -> Dictionary:
	return {
		"ok": success,
		"success": success,
		"code": code,
		"reason_code": code,
		"currency_id": CURRENCY_ID,
		"amount": amount,
		"operation_id": operation_id,
		"source": source,
		"balance": _balance,
		"details": details.duplicate(true),
		"notification_event": notification_event.duplicate(true)
	}

static func _build_notification_event(event_type: String, operation_id: String, amount: int) -> Dictionary:
	return {
		"event_id": operation_id if not operation_id.is_empty() else "%s:%d" % [event_type, amount],
		"event_type": event_type,
		"currency_id": CURRENCY_ID,
		"amount": amount
	}
