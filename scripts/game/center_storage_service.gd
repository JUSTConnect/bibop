extends RefCounted
class_name CenterStorageService

# Center virtual storage helpers for items, files and modules.
# Details currency is owned by DetailsCurrencyService and never by this storage.

const ItemFileTypesRef = preload("res://scripts/game/inventory/item_file_types.gd")
const DetailsCurrencyServiceRef = preload("res://scripts/game/inventory/details_currency_service.gd")

const STORAGE_ITEMS: String = "items"
const STORAGE_FILES: String = "files"
const STORAGE_INTERNAL_MODULES: String = "internal_modules"
const STORAGE_EXTERNAL_MODULES: String = "external_modules"
const STORAGE_PARTS: String = "parts" # Legacy read-only migration key.

static func create_empty_storage() -> Dictionary:
	return {
		STORAGE_ITEMS: [],
		STORAGE_FILES: [],
		STORAGE_INTERNAL_MODULES: [],
		STORAGE_EXTERNAL_MODULES: []
	}

static func normalize_storage(storage: Dictionary) -> Dictionary:
	var result: Dictionary = create_empty_storage()
	for key in result.keys():
		if storage.has(key):
			result[key] = _normalize_array_of_dictionaries(storage.get(key, []))
	return result

static func extract_legacy_details_amount(storage: Dictionary) -> int:
	var amount: int = maxi(0, int(storage.get(STORAGE_PARTS, 0)))
	for entry in _normalize_array_of_dictionaries(storage.get(STORAGE_ITEMS, [])):
		if DetailsCurrencyServiceRef.is_details_entry(entry, str(entry.get("id", ""))):
			amount += DetailsCurrencyServiceRef.get_entry_amount(entry)
	return amount

static func migrate_legacy_details(storage: Dictionary) -> Dictionary:
	var result: Dictionary = normalize_storage(storage)
	var filtered_items: Array[Dictionary] = []
	for entry in Array(result.get(STORAGE_ITEMS, [])):
		var entry_dict: Dictionary = Dictionary(entry)
		if not DetailsCurrencyServiceRef.is_details_entry(entry_dict, str(entry_dict.get("id", ""))):
			filtered_items.append(entry_dict.duplicate(true))
	result[STORAGE_ITEMS] = filtered_items
	return {
		"storage": result,
		"details_amount": extract_legacy_details_amount(storage)
	}

static func add_entry(storage: Dictionary, entry: Dictionary) -> Dictionary:
	var result: Dictionary = normalize_storage(storage)
	var target_key: String = _get_storage_key_for_entry(entry)
	if target_key.is_empty():
		return result
	var entries: Array[Dictionary] = Array(result.get(target_key, []))
	entries.append(entry.duplicate(true))
	result[target_key] = entries
	return result

static func add_entries(storage: Dictionary, entries: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = normalize_storage(storage)
	for entry in entries:
		result = add_entry(result, entry)
	return result

static func remove_entry_by_id(storage: Dictionary, entry_id: String) -> Dictionary:
	var result: Dictionary = normalize_storage(storage)
	var normalized_id: String = str(entry_id).strip_edges()
	if normalized_id.is_empty():
		return result
	for key in [STORAGE_ITEMS, STORAGE_FILES, STORAGE_INTERNAL_MODULES, STORAGE_EXTERNAL_MODULES]:
		var filtered: Array[Dictionary] = []
		for entry in Array(result.get(key, [])):
			if str(Dictionary(entry).get("id", "")) != normalized_id:
				filtered.append(Dictionary(entry))
		result[key] = filtered
	return result

static func find_entry_by_id(storage: Dictionary, entry_id: String) -> Dictionary:
	var normalized: Dictionary = normalize_storage(storage)
	var normalized_id: String = str(entry_id).strip_edges()
	for key in [STORAGE_ITEMS, STORAGE_FILES, STORAGE_INTERNAL_MODULES, STORAGE_EXTERNAL_MODULES]:
		for entry in Array(normalized.get(key, [])):
			var entry_dict: Dictionary = Dictionary(entry)
			if str(entry_dict.get("id", "")) == normalized_id:
				return entry_dict.duplicate(true)
	return {}

static func get_box_loadout_items(storage: Dictionary) -> Array[Dictionary]:
	var normalized: Dictionary = normalize_storage(storage)
	var result: Array[Dictionary] = []
	for entry in Array(normalized.get(STORAGE_ITEMS, [])):
		var entry_dict: Dictionary = Dictionary(entry)
		if ItemFileTypesRef.can_center_assign_to_pocket_or_manipulator(entry_dict) or ItemFileTypesRef.can_assign_to_keyholder(entry_dict):
			result.append(entry_dict.duplicate(true))
	return result

static func get_box_loadout_files(storage: Dictionary) -> Array[Dictionary]:
	var normalized: Dictionary = normalize_storage(storage)
	var result: Array[Dictionary] = []
	for entry in Array(normalized.get(STORAGE_FILES, [])):
		var entry_dict: Dictionary = Dictionary(entry)
		if ItemFileTypesRef.can_show_in_box_file_loadout(entry_dict):
			result.append(entry_dict.duplicate(true))
	return result

static func get_programmer_files(storage: Dictionary) -> Array[Dictionary]:
	var normalized: Dictionary = normalize_storage(storage)
	var result: Array[Dictionary] = []
	for entry in Array(normalized.get(STORAGE_FILES, [])):
		var entry_dict: Dictionary = Dictionary(entry)
		if ItemFileTypesRef.can_show_in_programmer(entry_dict):
			result.append(entry_dict.duplicate(true))
	return result

static func collect_mission_return(storage: Dictionary, carried_entries: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = normalize_storage(storage)
	for entry in carried_entries:
		if DetailsCurrencyServiceRef.is_details_entry(entry, str(entry.get("id", ""))):
			continue
		result = add_entry(result, _mark_returned_from_mission(entry))
	return result

static func complete_center_programmer_file(storage: Dictionary, processed_file: Dictionary, take_to_storage: bool) -> Dictionary:
	var result: Dictionary = normalize_storage(storage)
	if not take_to_storage:
		return result
	var file_entry: Dictionary = processed_file.duplicate(true)
	file_entry["category"] = ItemFileTypesRef.CATEGORY_FILE
	file_entry["status"] = ItemFileTypesRef.FILE_STATUS_OPEN
	return add_entry(remove_entry_by_id(result, str(file_entry.get("id", ""))), file_entry)

static func consume_repair_tool(entries: Array[Dictionary], repair_tool_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var consumed: bool = false
	for entry in entries:
		var entry_dict: Dictionary = Dictionary(entry)
		if not consumed and str(entry_dict.get("id", "")) == str(repair_tool_id) and ItemFileTypesRef.is_repair_tool(entry_dict):
			consumed = true
			continue
		result.append(entry_dict.duplicate(true))
	return result

static func _get_storage_key_for_entry(entry: Dictionary) -> String:
	if DetailsCurrencyServiceRef.is_details_entry(entry, str(entry.get("id", ""))):
		return ""
	if ItemFileTypesRef.is_resource(entry):
		return ""
	if ItemFileTypesRef.is_file(entry):
		return STORAGE_FILES
	if ItemFileTypesRef.is_module(entry):
		var scope: String = str(entry.get("module_scope", entry.get("scope", ""))).strip_edges().to_lower()
		return STORAGE_EXTERNAL_MODULES if scope == ItemFileTypesRef.MODULE_SCOPE_EXTERNAL else STORAGE_INTERNAL_MODULES
	if ItemFileTypesRef.is_item(entry):
		return STORAGE_ITEMS
	return ""

static func _normalize_array_of_dictionaries(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for entry in Array(value):
			if entry is Dictionary:
				result.append(Dictionary(entry).duplicate(true))
	return result

static func _mark_returned_from_mission(entry: Dictionary) -> Dictionary:
	var result: Dictionary = entry.duplicate(true)
	result["last_source"] = ItemFileTypesRef.SOURCE_MISSION
	result["stored_at"] = ItemFileTypesRef.SLOT_KIND_CENTER_STORAGE
	return result
