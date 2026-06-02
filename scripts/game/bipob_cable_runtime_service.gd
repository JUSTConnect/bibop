extends RefCounted
class_name BipobCableRuntimeService

const CableRuntimeStateRef = preload("res://scripts/game/bipob_cable_runtime_state.gd")


## Data-only cable/socket/power runtime helper.
##
## All transition helpers return a cloned BipobCableRuntimeState and leave the
## input state untouched. This skeleton intentionally does not touch gameplay
## controllers, grids, tiles, power systems, inventory, signals, or UI.
static func create_empty_state() -> BipobCableRuntimeState:
	var result: BipobCableRuntimeState = CableRuntimeStateRef.new()
	return result


static func snapshot_legacy_mission7(controller: Variant) -> BipobCableRuntimeState:
	var result: BipobCableRuntimeState = CableRuntimeStateRef.from_legacy_mission7(controller)
	return result


static func can_start_drag(state: BipobCableRuntimeState, hand_occupied: bool = false) -> bool:
	if state == null:
		return false
	if hand_occupied:
		return false
	if state.is_connected():
		return false
	return state.has_cable() and not state.is_dragging()


static func start_drag(state: BipobCableRuntimeState) -> BipobCableRuntimeState:
	var result: BipobCableRuntimeState = _duplicate_state_or_empty(state)
	if can_start_drag(result):
		result.state = CableRuntimeStateRef.STATE_DRAGGING
	return result


static func can_extend_path(state: BipobCableRuntimeState, next_cell: Vector2i) -> bool:
	if state == null:
		return false
	if not state.is_dragging():
		return false
	if not state.can_extend_path():
		return false
	var path_size: int = state.path_cells.size()
	if path_size > 0 and state.path_cells[path_size - 1] == next_cell:
		return false
	return true


static func extend_path(state: BipobCableRuntimeState, next_cell: Vector2i) -> BipobCableRuntimeState:
	var result: BipobCableRuntimeState = _duplicate_state_or_empty(state)
	if can_extend_path(result, next_cell):
		result.add_path_cell(next_cell)
	return result


static func can_connect_to_socket(state: BipobCableRuntimeState, socket_id: String = "", power_filter: String = "") -> bool:
	if state == null:
		return false
	if not state.is_dragging():
		return false
	if state.is_connected():
		return false
	if not socket_id.is_empty() and not state.socket_id.is_empty() and state.socket_id != socket_id:
		return false
	if not power_filter.is_empty() and not state.power_filter.is_empty() and state.power_filter != power_filter:
		return false
	return true


static func connect_to_socket(state: BipobCableRuntimeState, socket_id: String = "", linked_target_id: String = "") -> BipobCableRuntimeState:
	var result: BipobCableRuntimeState = _duplicate_state_or_empty(state)
	if can_connect_to_socket(result, socket_id):
		result.connected = true
		result.state = CableRuntimeStateRef.STATE_CONNECTED
		if not socket_id.is_empty():
			result.socket_id = socket_id
		if not linked_target_id.is_empty():
			result.linked_target_id = linked_target_id
	return result


static func release_cable(state: BipobCableRuntimeState) -> BipobCableRuntimeState:
	var result: BipobCableRuntimeState = _duplicate_state_or_empty(state)
	if not result.is_connected():
		result.state = CableRuntimeStateRef.STATE_RELEASED
	return result


static func clear_path(state: BipobCableRuntimeState) -> BipobCableRuntimeState:
	var result: BipobCableRuntimeState = _duplicate_state_or_empty(state)
	result.clear_path()
	return result


static func get_status_text(state: BipobCableRuntimeState) -> String:
	if state == null or not state.has_cable():
		return "No cable selected."
	if state.is_connected():
		return "Cable connected."
	if state.is_dragging():
		return "Cable dragging."
	if state.state == CableRuntimeStateRef.STATE_RELEASED:
		return "Cable released."
	return "Cable idle."


static func _duplicate_state_or_empty(state: BipobCableRuntimeState) -> BipobCableRuntimeState:
	var result: BipobCableRuntimeState = create_empty_state()
	if state == null:
		return result
	var state_data: Dictionary = state.to_dictionary()
	result.from_dictionary(state_data)
	return result
