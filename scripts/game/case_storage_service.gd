extends RefCounted
class_name CaseStorageService

# Case/container storage helpers for physical map loot.
# This service is data-only/helper-only: no HUD, no scene mutation, no Map Constructor UI.

const ItemFileTypesRef = preload("res://scripts/game/inventory/item_file_types.gd")
const MissionLoadoutServiceRef = preload("res://scripts/game/mission_loadout_service.gd")

const STORAGE_KIND_CASE: String = "case"
const STORAGE_LOCATION_CASE: String = "case"
const CASE_CONTENT_IDS_KEY: String = "stored_object_ids"

static func can_store_in_case(entry: Dictionary) -> bool:
	# Cases store physical map loot only.
	# Files, digital keys and access codes cannot be stored in cases.
	if ItemFileTypesRef.is_file(entry):
		return false
	if ItemFileTypesRef.is_access_code(entry):
		return false
	if ItemFileTypesRef.is_resource(entry):
		return false
	return ItemFileTypesRef.is_item(entry) or ItemFileTypesRef.is_module(entry)

static func normalize_case_object(case_object: Dictionary) -> Dictionary:
	var result: Dictionary = case_object.duplicate(true)
	result["storage_kind"] = STORAGE_KIND_CASE
	if not result.has(CASE_CONTENT_IDS_KEY) or not (result.get(CASE_CONTENT_IDS_KEY) is Array):
		result[CASE_CONTENT_IDS_KEY] = []
	result[CASE_CONTENT_IDS_KEY] = _normalize_string_array(result.get(CASE_CONTENT_IDS_KEY, []))
	return result

static func anchor_entry_to_case(entry: Dictionary, case_object: Dictionary) -> Dictionary:
	var anchored: Dictionary = entry.duplicate(true)
	var normalized_case: Dictionary = normalize_case_object(case_object)
	anchored["storage_owner_id"] = str(normalized_case.get("id", normalized_case.get("object_id", "")))
	anchored["storage_location"] = STORAGE_LOCATION_CASE
	anchored["is_hidden_on_map"] = true
	if normalized_case.has("cell"):
		anchored["cell"] = normalized_case.get("cell")
	return anchored

static func add_entry_to_case(case_object: Dictionary, entry: Dictionary) -> Dictionary:
	var normalized_case: Dictionary = normalize_case_object(case_object)
	if not can_store_in_case(entry):
		return {"ok": false, "message": "This entry type cannot be stored in a case.", "case_object": normalized_case, "entry": entry.duplicate(true)}
	var entry_id: String = str(entry.get("id", entry.get("object_id", ""))).strip_edges()
	if entry_id.is_empty():
		return {"ok": false, "message": "Stored entry has no id.", "case_object": normalized_case, "entry": entry.duplicate(true)}
	var ids: Array[String] = _normalize_string_array(normalized_case.get(CASE_CONTENT_IDS_KEY, []))
	if not ids.has(entry_id):
		ids.append(entry_id)
	normalized_case[CASE_CONTENT_IDS_KEY] = ids
	return {"ok": true, "message": "Entry stored in case.", "case_object": normalized_case, "entry": anchor_entry_to_case(entry, normalized_case)}

static func remove_entry_from_case(case_object: Dictionary, entry_id: String) -> Dictionary:
	var normalized_case: Dictionary = normalize_case_object(case_object)
	var normalized_id: String = str(entry_id).strip_edges()
	var ids: Array[String] = []
	for id_value in _normalize_string_array(normalized_case.get(CASE_CONTENT_IDS_KEY, [])):
		if id_value != normalized_id:
			ids.append(id_value)
	normalized_case[CASE_CONTENT_IDS_KEY] = ids
	return {"ok": true, "message": "Entry removed from case.", "case_object": normalized_case, "removed_entry_id": normalized_id}

static func get_case_contents(case_object: Dictionary, world_objects_by_id: Dictionary) -> Array[Dictionary]:
	var normalized_case: Dictionary = normalize_case_object(case_object)
	var contents: Array[Dictionary] = []
	for entry_id in _normalize_string_array(normalized_case.get(CASE_CONTENT_IDS_KEY, [])):
		var entry: Dictionary = Dictionary(world_objects_by_id.get(entry_id, {}))
		if not entry.is_empty():
			contents.append(entry.duplicate(true))
	return contents

static func build_case_hud_payload(case_object: Dictionary, world_objects_by_id: Dictionary) -> Dictionary:
	var normalized_case: Dictionary = normalize_case_object(case_object)
	var contents: Array[Dictionary] = get_case_contents(normalized_case, world_objects_by_id)
	var rows: Array[Dictionary] = []
	for entry in contents:
		rows.append({
			"id": str(entry.get("id", entry.get("object_id", ""))),
			"display_name": str(entry.get("display_name", entry.get("name", entry.get("id", "Item")))),
			"category": str(entry.get("category", "")),
			"kind": str(entry.get("kind", "")),
			"can_take": can_store_in_case(entry)
		})
	return {
		"storage_kind": STORAGE_KIND_CASE,
		"case_id": str(normalized_case.get("id", normalized_case.get("object_id", ""))),
		"display_name": str(normalized_case.get("display_name", normalized_case.get("name", "Case"))),
		"contents": rows,
		"has_take_all": true
	}

static func take_one_from_case(
	case_object: Dictionary,
	world_objects_by_id: Dictionary,
	entry_id: String,
	loadout_or_inventory: Dictionary,
	slot_caps: Dictionary
) -> Dictionary:
	var normalized_case: Dictionary = normalize_case_object(case_object)
	var normalized_id: String = str(entry_id).strip_edges()
	var entry: Dictionary = Dictionary(world_objects_by_id.get(normalized_id, {}))
	if entry.is_empty():
		return {"ok": false, "message": "Entry not found in world object map.", "case_object": normalized_case, "loadout": loadout_or_inventory}
	if not _normalize_string_array(normalized_case.get(CASE_CONTENT_IDS_KEY, [])).has(normalized_id):
		return {"ok": false, "message": "Entry is not stored in this case.", "case_object": normalized_case, "loadout": loadout_or_inventory}
	if not can_store_in_case(entry):
		return {"ok": false, "message": "Entry type cannot be taken through case flow.", "case_object": normalized_case, "loadout": loadout_or_inventory}
	var assign_result: Dictionary = MissionLoadoutServiceRef.auto_assign_item(loadout_or_inventory, _clear_case_storage_fields(entry), slot_caps, ItemFileTypesRef.SOURCE_MISSION)
	if not bool(assign_result.get("ok", false)):
		return {"ok": false, "message": str(assign_result.get("message", "No free compatible slot.")), "case_object": normalized_case, "loadout": loadout_or_inventory, "entry": entry}
	var remove_result: Dictionary = remove_entry_from_case(normalized_case, normalized_id)
	return {"ok": true, "message": "Entry taken from case.", "case_object": remove_result.get("case_object", normalized_case), "loadout": assign_result.get("loadout", loadout_or_inventory), "entry": _clear_case_storage_fields(entry)}

static func take_all_from_case(
	case_object: Dictionary,
	world_objects_by_id: Dictionary,
	loadout_or_inventory: Dictionary,
	slot_caps: Dictionary
) -> Dictionary:
	var current_case: Dictionary = normalize_case_object(case_object)
	var current_loadout: Dictionary = loadout_or_inventory.duplicate(true)
	var taken: Array[Dictionary] = []
	var remaining: Array[Dictionary] = []
	for entry in get_case_contents(current_case, world_objects_by_id):
		var result: Dictionary = take_one_from_case(current_case, world_objects_by_id, str(entry.get("id", entry.get("object_id", ""))), current_loadout, slot_caps)
		if bool(result.get("ok", false)):
			current_case = Dictionary(result.get("case_object", current_case))
			current_loadout = Dictionary(result.get("loadout", current_loadout))
			taken.append(Dictionary(result.get("entry", entry)))
		else:
			remaining.append(entry.duplicate(true))
	return {
		"ok": remaining.is_empty(),
		"message": "All entries taken." if remaining.is_empty() else "Some entries remain in case.",
		"case_object": current_case,
		"loadout": current_loadout,
		"taken": taken,
		"remaining": remaining
	}

static func drop_manipulator_entry_into_open_case(case_object: Dictionary, manipulator_entry: Dictionary) -> Dictionary:
	if manipulator_entry.is_empty():
		return {"ok": false, "message": "Manipulator is empty.", "case_object": normalize_case_object(case_object), "entry": {}}
	return add_entry_to_case(case_object, manipulator_entry)

static func can_open_case(has_regular_manipulator: bool) -> bool:
	return has_regular_manipulator

static func can_heavy_claw_open_case() -> bool:
	return false

static func _clear_case_storage_fields(entry: Dictionary) -> Dictionary:
	var result: Dictionary = entry.duplicate(true)
	result.erase("storage_owner_id")
	result.erase("storage_location")
	result.erase("is_hidden_on_map")
	return result

static func _normalize_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in Array(value):
			var text: String = str(item).strip_edges()
			if not text.is_empty() and not result.has(text):
				result.append(text)
	return result
