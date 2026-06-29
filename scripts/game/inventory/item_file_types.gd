extends RefCounted
class_name ItemFileTypes

# Shared type/status constants for physical items, files, keys, modules and currency migration.
# Data-only foundation. Do not put inventory UI or mission mutation here.

const CATEGORY_ITEM: String = "item"
const CATEGORY_FILE: String = "file"
const CATEGORY_MODULE: String = "module"
const CATEGORY_RESOURCE: String = "resource" # Legacy serialization category only.
const CATEGORY_ACCESS_CODE: String = "access_code"
const CATEGORY_CURRENCY_PICKUP: String = "currency_pickup"

const ITEM_KIND_PHYSICAL_ITEM: String = "physical_item"
const ITEM_KIND_REPAIR_TOOL: String = "repair_tool"
const ITEM_KIND_FUSE: String = "fuse"
const ITEM_KIND_REINFORCEMENT: String = "reinforcement"
const ITEM_KIND_PHYSICAL_KEY: String = "physical_key"
const ITEM_KIND_MODULE_LOOT: String = "module_loot"

const FILE_KIND_DIGITAL_KEY: String = "digital_key"
const FILE_KIND_INFORMATION_DATA: String = "information_data"

const CURRENCY_KIND_DETAILS: String = "details"
const RESOURCE_KIND_PARTS: String = "parts" # Legacy migration alias only.

const FILE_STATUS_OPEN: String = "open"
const FILE_STATUS_ENCRYPTED: String = "encrypted"
const FILE_STATUS_DAMAGED: String = "damaged"

const MODULE_SCOPE_INTERNAL: String = "internal"
const MODULE_SCOPE_EXTERNAL: String = "external"

const SLOT_KIND_POCKET: String = "pocket"
const SLOT_KIND_MANIPULATOR: String = "manipulator"
const SLOT_KIND_KEYHOLDER: String = "keyholder"
const SLOT_KIND_BUFFER: String = "buffer"
const SLOT_KIND_FILE_STORAGE: String = "file_storage"
const SLOT_KIND_CENTER_STORAGE: String = "center_storage"
const SLOT_KIND_MODULE_STORAGE: String = "module_storage"

const SOURCE_CENTER: String = "center"
const SOURCE_MISSION: String = "mission"
const SOURCE_CASE: String = "case"
const SOURCE_TERMINAL: String = "terminal"
const SOURCE_PROGRAMMER: String = "programmer"

static func is_file(entry: Dictionary) -> bool:
	return str(entry.get("category", "")) == CATEGORY_FILE

static func is_item(entry: Dictionary) -> bool:
	return str(entry.get("category", "")) == CATEGORY_ITEM

static func is_module(entry: Dictionary) -> bool:
	return str(entry.get("category", "")) == CATEGORY_MODULE

static func is_resource(entry: Dictionary) -> bool:
	return str(entry.get("category", "")) == CATEGORY_RESOURCE

static func is_currency_pickup(entry: Dictionary) -> bool:
	return str(entry.get("category", "")) == CATEGORY_CURRENCY_PICKUP or str(entry.get("currency_id", "")) == CURRENCY_KIND_DETAILS

static func is_access_code(entry: Dictionary) -> bool:
	return str(entry.get("category", "")) == CATEGORY_ACCESS_CODE

static func is_digital_key_file(entry: Dictionary) -> bool:
	return is_file(entry) and str(entry.get("kind", "")) == FILE_KIND_DIGITAL_KEY

static func is_information_data_file(entry: Dictionary) -> bool:
	return is_file(entry) and str(entry.get("kind", "")) == FILE_KIND_INFORMATION_DATA

static func is_open_file(entry: Dictionary) -> bool:
	return is_file(entry) and str(entry.get("status", "")) == FILE_STATUS_OPEN

static func needs_programmer_processing(entry: Dictionary) -> bool:
	if not is_file(entry):
		return false
	var status: String = str(entry.get("status", ""))
	return status == FILE_STATUS_ENCRYPTED or status == FILE_STATUS_DAMAGED

static func is_physical_key(entry: Dictionary) -> bool:
	return is_item(entry) and str(entry.get("kind", "")) == ITEM_KIND_PHYSICAL_KEY

static func is_repair_tool(entry: Dictionary) -> bool:
	return is_item(entry) and str(entry.get("kind", "")) == ITEM_KIND_REPAIR_TOOL

static func can_center_assign_to_pocket_or_manipulator(entry: Dictionary) -> bool:
	return is_item(entry) and not is_physical_key(entry) and not is_currency_pickup(entry)

static func can_mission_loot_assign_to_pocket_or_manipulator(entry: Dictionary) -> bool:
	return (is_item(entry) or is_module(entry)) and not is_currency_pickup(entry)

static func can_assign_to_keyholder(entry: Dictionary) -> bool:
	return is_physical_key(entry)

static func can_assign_to_buffer_or_file_storage(entry: Dictionary) -> bool:
	return is_open_file(entry)

static func can_show_in_box_file_loadout(entry: Dictionary) -> bool:
	return is_open_file(entry)

static func can_show_in_programmer(entry: Dictionary) -> bool:
	return needs_programmer_processing(entry)

static func normalize_file_status(status: String) -> String:
	var normalized: String = str(status).strip_edges().to_lower()
	if normalized in [FILE_STATUS_OPEN, FILE_STATUS_ENCRYPTED, FILE_STATUS_DAMAGED]:
		return normalized
	return FILE_STATUS_OPEN
