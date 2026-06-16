extends RefCounted
class_name LootCaseVisualStateService

const STATE_LOCKED: String = "locked"
const STATE_UNSEARCHED: String = "unsearched"
const STATE_PARTIALLY_LOOTED: String = "partially_looted"
const STATE_EMPTY: String = "empty"
const DEFAULT_VARIANT: String = "class1"

static func _normalized_text(value: Variant) -> String:
	return str(value).strip_edges().to_lower().replace(" ", "_").replace("-", "_")

static func _explicit_bool(object_data: Dictionary, keys: Array[String]) -> Variant:
	for key in keys:
		if object_data.has(key):
			return bool(object_data.get(key, false))
	return null

static func _is_locked(object_data: Dictionary) -> bool:
	var locked_value: Variant = _explicit_bool(object_data, ["locked", "is_locked"])
	if locked_value != null:
		return bool(locked_value)
	var lock_state: String = _normalized_text(object_data.get("lock_state", ""))
	if lock_state in ["locked", "lock", "secured"]:
		return true
	if lock_state in ["unlocked", "unlock", "open", "none"]:
		return false
	var unlocked_value: Variant = _explicit_bool(object_data, ["is_unlocked", "unlocked"])
	if unlocked_value != null:
		return not bool(unlocked_value)
	return false

static func _is_opened_or_searched(object_data: Dictionary) -> bool:
	for key in ["opened", "is_opened", "searched", "is_searched", "has_been_opened", "was_opened", "loot_revealed"]:
		if object_data.has(key) and bool(object_data.get(key, false)):
			return true
	var case_loot_state: String = _normalized_text(object_data.get("case_loot_state", ""))
	return case_loot_state in [STATE_PARTIALLY_LOOTED, STATE_EMPTY, "opened", "searched"]

static func _remaining_loot_count(object_data: Dictionary) -> int:
	for key in ["remaining_loot_count", "loot_count", "items_remaining", "remaining_items"]:
		if object_data.has(key):
			return int(object_data.get(key, 0))
	for key in ["inventory", "loot_items"]:
		if object_data.has(key):
			var value: Variant = object_data.get(key, [])
			if typeof(value) == TYPE_ARRAY:
				return Array(value).size()
			if typeof(value) == TYPE_DICTIONARY:
				return Dictionary(value).size()
	return -1

static func _is_empty(object_data: Dictionary) -> bool:
	for key in ["is_empty", "empty", "loot_empty"]:
		if object_data.has(key) and bool(object_data.get(key, false)):
			return true
	var case_loot_state: String = _normalized_text(object_data.get("case_loot_state", ""))
	if case_loot_state == STATE_EMPTY:
		return true
	var remaining_count: int = _remaining_loot_count(object_data)
	return remaining_count == 0

static func resolve_visual_state(object_data: Dictionary) -> String:
	if _is_locked(object_data):
		return STATE_LOCKED
	if _is_empty(object_data):
		return STATE_EMPTY
	var remaining_count: int = _remaining_loot_count(object_data)
	if _is_opened_or_searched(object_data) and remaining_count != 0:
		return STATE_PARTIALLY_LOOTED
	return STATE_UNSEARCHED

static func resolve_variant(object_data: Dictionary) -> String:
	for key in ["loot_class", "case_class", "loot_tier", "rarity_class", "class", "tier"]:
		var normalized: String = _normalized_text(object_data.get(key, ""))
		match normalized:
			"class1", "class_1", "tier1", "tier_1", "green", "1":
				return "class1"
			"class2", "class_2", "tier2", "tier_2", "blue", "2":
				return "class2"
			"class3", "class_3", "tier3", "tier_3", "purple", "3":
				return "class3"
	return DEFAULT_VARIANT
