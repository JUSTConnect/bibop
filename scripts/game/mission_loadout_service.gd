extends RefCounted
class_name MissionLoadoutService

# Mission loadout helpers for assigning Center items/files into Bipob carry slots.
# This service does not build UI and does not mutate runtime scenes.

const ItemFileTypesRef = preload("res://scripts/game/inventory/item_file_types.gd")

const LOADOUT_MANIPULATOR_ITEMS: String = "manipulator_items"
const LOADOUT_POCKET_ITEMS: String = "pocket_items"
const LOADOUT_KEYHOLDER_ITEMS: String = "keyholder_items"
const LOADOUT_BUFFER_FILES: String = "buffer_files"
const LOADOUT_STORAGE_FILES: String = "storage_files"

static func create_empty_loadout() -> Dictionary:
	return {
		LOADOUT_MANIPULATOR_ITEMS: [],
		LOADOUT_POCKET_ITEMS: [],
		LOADOUT_KEYHOLDER_ITEMS: [],
		LOADOUT_BUFFER_FILES: [],
		LOADOUT_STORAGE_FILES: []
	}

static func normalize_loadout(loadout: Dictionary) -> Dictionary:
	var result: Dictionary = create_empty_loadout()
	for key in result.keys():
		if loadout.has(key):
			result[key] = _normalize_array_of_dictionaries(loadout.get(key, []))
	return result

static func get_slot_count(slot_caps: Dictionary, slot_kind: String) -> int:
	return max(0, int(slot_caps.get(slot_kind, 0)))

static func can_assign_entry_to_slot(entry: Dictionary, slot_kind: String, source_context: String = ItemFileTypesRef.SOURCE_CENTER) -> bool:
	match slot_kind:
		ItemFileTypesRef.SLOT_KIND_POCKET, ItemFileTypesRef.SLOT_KIND_MANIPULATOR:
			if source_context == ItemFileTypesRef.SOURCE_CENTER:
				return ItemFileTypesRef.can_center_assign_to_pocket_or_manipulator(entry)
			return ItemFileTypesRef.can_mission_loot_assign_to_pocket_or_manipulator(entry)
		ItemFileTypesRef.SLOT_KIND_KEYHOLDER:
			return ItemFileTypesRef.can_assign_to_keyholder(entry)
		ItemFileTypesRef.SLOT_KIND_BUFFER, ItemFileTypesRef.SLOT_KIND_FILE_STORAGE:
			return ItemFileTypesRef.can_assign_to_buffer_or_file_storage(entry)
		_:
			return false

static func assign_entry(loadout: Dictionary, entry: Dictionary, slot_kind: String, slot_index: int, slot_caps: Dictionary, source_context: String = ItemFileTypesRef.SOURCE_CENTER) -> Dictionary:
	var normalized: Dictionary = normalize_loadout(loadout)
	if not can_assign_entry_to_slot(entry, slot_kind, source_context):
		return {"ok": false, "message": "Entry cannot be assigned to this slot.", "loadout": normalized}
	var key: String = _loadout_key_for_slot(slot_kind)
	if key.is_empty():
		return {"ok": false, "message": "Unknown slot kind.", "loadout": normalized}
	var capacity: int = get_slot_count(slot_caps, slot_kind)
	if slot_index < 0 or slot_index >= capacity:
		return {"ok": false, "message": "Slot index is outside capacity.", "loadout": normalized}
	var slots: Array[Dictionary] = _ensure_slot_array(Array(normalized.get(key, [])), capacity)
	if not Dictionary(slots[slot_index]).is_empty():
		return {"ok": false, "message": "Slot is already occupied.", "loadout": normalized}
	var next_entry: Dictionary = entry.duplicate(true)
	next_entry["assigned_slot_kind"] = slot_kind
	next_entry["assigned_slot_index"] = slot_index
	slots[slot_index] = next_entry
	normalized[key] = slots
	return {"ok": true, "message": "Entry assigned.", "loadout": normalized}

static func remove_entry_from_slot(loadout: Dictionary, slot_kind: String, slot_index: int, slot_caps: Dictionary) -> Dictionary:
	var normalized: Dictionary = normalize_loadout(loadout)
	var key: String = _loadout_key_for_slot(slot_kind)
	if key.is_empty():
		return {"ok": false, "message": "Unknown slot kind.", "loadout": normalized, "removed_entry": {}}
	var capacity: int = get_slot_count(slot_caps, slot_kind)
	var slots: Array[Dictionary] = _ensure_slot_array(Array(normalized.get(key, [])), capacity)
	if slot_index < 0 or slot_index >= slots.size():
		return {"ok": false, "message": "Slot index is outside capacity.", "loadout": normalized, "removed_entry": {}}
	var removed_entry: Dictionary = Dictionary(slots[slot_index]).duplicate(true)
	slots[slot_index] = {}
	normalized[key] = slots
	return {"ok": true, "message": "Entry removed.", "loadout": normalized, "removed_entry": removed_entry}

static func get_first_free_slot(loadout: Dictionary, slot_kind: String, slot_caps: Dictionary) -> int:
	var normalized: Dictionary = normalize_loadout(loadout)
	var key: String = _loadout_key_for_slot(slot_kind)
	if key.is_empty():
		return -1
	var capacity: int = get_slot_count(slot_caps, slot_kind)
	var slots: Array[Dictionary] = _ensure_slot_array(Array(normalized.get(key, [])), capacity)
	for index in range(slots.size()):
		if Dictionary(slots[index]).is_empty():
			return index
	return -1

static func auto_assign_item(loadout: Dictionary, entry: Dictionary, slot_caps: Dictionary, source_context: String = ItemFileTypesRef.SOURCE_CENTER) -> Dictionary:
	var normalized: Dictionary = normalize_loadout(loadout)
	if ItemFileTypesRef.can_assign_to_keyholder(entry):
		return _auto_assign_to_slot_order(normalized, entry, [ItemFileTypesRef.SLOT_KIND_KEYHOLDER], slot_caps, source_context)
	return _auto_assign_to_slot_order(normalized, entry, [ItemFileTypesRef.SLOT_KIND_POCKET, ItemFileTypesRef.SLOT_KIND_MANIPULATOR], slot_caps, source_context)

static func auto_assign_file(loadout: Dictionary, entry: Dictionary, slot_caps: Dictionary) -> Dictionary:
	return _auto_assign_to_slot_order(normalize_loadout(loadout), entry, [ItemFileTypesRef.SLOT_KIND_BUFFER, ItemFileTypesRef.SLOT_KIND_FILE_STORAGE], slot_caps, ItemFileTypesRef.SOURCE_CENTER)

static func get_visible_slot_descriptors(loadout: Dictionary, slot_caps: Dictionary, mode: String) -> Array[Dictionary]:
	var normalized: Dictionary = normalize_loadout(loadout)
	var result: Array[Dictionary] = []
	var slot_order: Array[String] = []
	if mode == "files":
		slot_order = [ItemFileTypesRef.SLOT_KIND_BUFFER, ItemFileTypesRef.SLOT_KIND_FILE_STORAGE]
	else:
		slot_order = [ItemFileTypesRef.SLOT_KIND_MANIPULATOR, ItemFileTypesRef.SLOT_KIND_POCKET, ItemFileTypesRef.SLOT_KIND_KEYHOLDER]
	for slot_kind in slot_order:
		var capacity: int = get_slot_count(slot_caps, slot_kind)
		if capacity <= 0:
			continue
		var key: String = _loadout_key_for_slot(slot_kind)
		var slots: Array[Dictionary] = _ensure_slot_array(Array(normalized.get(key, [])), capacity)
		for index in range(capacity):
			result.append({
				"slot_kind": slot_kind,
				"slot_index": index,
				"entry": Dictionary(slots[index]).duplicate(true),
				"is_empty": Dictionary(slots[index]).is_empty()
			})
	return result

static func validate_loadout(loadout: Dictionary, slot_caps: Dictionary, source_context: String = ItemFileTypesRef.SOURCE_CENTER) -> Array[String]:
	var warnings: Array[String] = []
	var normalized: Dictionary = normalize_loadout(loadout)
	for slot_kind in [ItemFileTypesRef.SLOT_KIND_MANIPULATOR, ItemFileTypesRef.SLOT_KIND_POCKET, ItemFileTypesRef.SLOT_KIND_KEYHOLDER, ItemFileTypesRef.SLOT_KIND_BUFFER, ItemFileTypesRef.SLOT_KIND_FILE_STORAGE]:
		var key: String = _loadout_key_for_slot(slot_kind)
		var capacity: int = get_slot_count(slot_caps, slot_kind)
		var slots: Array[Dictionary] = Array(normalized.get(key, []))
		if slots.size() > capacity:
			warnings.append("slot_over_capacity:%s" % slot_kind)
		for index in range(min(slots.size(), capacity)):
			var entry: Dictionary = Dictionary(slots[index])
			if entry.is_empty():
				continue
			if not can_assign_entry_to_slot(entry, slot_kind, source_context):
				warnings.append("invalid_entry_for_slot:%s:%s" % [slot_kind, str(entry.get("id", index))])
	return warnings

static func _auto_assign_to_slot_order(loadout: Dictionary, entry: Dictionary, slot_order: Array[String], slot_caps: Dictionary, source_context: String) -> Dictionary:
	var current: Dictionary = normalize_loadout(loadout)
	for slot_kind in slot_order:
		var free_index: int = get_first_free_slot(current, slot_kind, slot_caps)
		if free_index < 0:
			continue
		var result: Dictionary = assign_entry(current, entry, slot_kind, free_index, slot_caps, source_context)
		if bool(result.get("ok", false)):
			return result
	return {"ok": false, "message": "No free compatible slot.", "loadout": current}

static func _loadout_key_for_slot(slot_kind: String) -> String:
	match slot_kind:
		ItemFileTypesRef.SLOT_KIND_MANIPULATOR:
			return LOADOUT_MANIPULATOR_ITEMS
		ItemFileTypesRef.SLOT_KIND_POCKET:
			return LOADOUT_POCKET_ITEMS
		ItemFileTypesRef.SLOT_KIND_KEYHOLDER:
			return LOADOUT_KEYHOLDER_ITEMS
		ItemFileTypesRef.SLOT_KIND_BUFFER:
			return LOADOUT_BUFFER_FILES
		ItemFileTypesRef.SLOT_KIND_FILE_STORAGE:
			return LOADOUT_STORAGE_FILES
		_:
			return ""

static func _ensure_slot_array(source: Array, capacity: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(capacity):
		if index < source.size() and source[index] is Dictionary:
			result.append(Dictionary(source[index]).duplicate(true))
		else:
			result.append({})
	return result

static func _normalize_array_of_dictionaries(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for entry in Array(value):
			if entry is Dictionary:
				result.append(Dictionary(entry).duplicate(true))
	return result
