extends SceneTree

const CableRuntimeStateRef = preload("res://scripts/game/bipob_cable_runtime_state.gd")
const CableRuntimeServiceRef = preload("res://scripts/game/bipob_cable_runtime_service.gd")

var _failed: bool = false


func _initialize() -> void:
	_run()
	if _failed:
		quit(1)
		return
	print("OK: BipobCableRuntimeService checks passed")
	quit(0)


func _run() -> void:
	_check_empty_state()
	_check_dictionary_roundtrip()
	_check_start_drag()
	_check_extend_path()
	_check_connect()
	_check_release()
	_check_clear_path()
	_check_legacy_snapshot()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failed = true


func _check_empty_state() -> void:
	var empty_state: BipobCableRuntimeState = CableRuntimeServiceRef.create_empty_state()
	_expect(empty_state != null, "create_empty_state() should return a state.")
	if empty_state == null:
		return
	_expect(not empty_state.has_cable(), "Empty state should not have a cable.")
	_expect(CableRuntimeServiceRef.get_status_text(empty_state) == "No cable selected.", "Empty state status text should describe no selected cable.")


func _check_dictionary_roundtrip() -> void:
	var source_state: BipobCableRuntimeState = CableRuntimeStateRef.new()
	source_state.cable_id = "cable_test"
	source_state.socket_id = "socket_test"
	source_state.linked_target_id = "gate_test"
	source_state.power_filter = "standard"
	source_state.max_length = 3
	source_state.path_cells = _make_path(Vector2i(1, 1), Vector2i(2, 1))

	var serialized_state: Dictionary = source_state.to_dictionary()
	var roundtrip_state: BipobCableRuntimeState = CableRuntimeStateRef.new()
	roundtrip_state.from_dictionary(serialized_state)

	_expect(roundtrip_state.cable_id == "cable_test", "Roundtrip should preserve cable_id.")
	_expect(roundtrip_state.socket_id == "socket_test", "Roundtrip should preserve socket_id.")
	_expect(roundtrip_state.linked_target_id == "gate_test", "Roundtrip should preserve linked_target_id.")
	_expect(roundtrip_state.power_filter == "standard", "Roundtrip should preserve power_filter.")
	_expect(roundtrip_state.max_length == 3, "Roundtrip should preserve max_length.")
	_expect(roundtrip_state.path_cells.size() == 2, "Roundtrip should preserve path length.")
	_expect(roundtrip_state.path_cells[0] == Vector2i(1, 1), "Roundtrip should preserve first path cell.")
	_expect(roundtrip_state.path_cells[1] == Vector2i(2, 1), "Roundtrip should preserve second path cell.")


func _check_start_drag() -> void:
	var source_state: BipobCableRuntimeState = CableRuntimeStateRef.new()
	source_state.cable_id = "cable_test"

	_expect(CableRuntimeServiceRef.can_start_drag(source_state, false), "can_start_drag() should allow a cable with a free hand.")
	_expect(not CableRuntimeServiceRef.can_start_drag(source_state, true), "can_start_drag() should reject an occupied hand.")

	var dragging_state: BipobCableRuntimeState = CableRuntimeServiceRef.start_drag(source_state)
	_expect(dragging_state != source_state, "start_drag() should return a cloned state.")
	_expect(dragging_state.state == CableRuntimeStateRef.STATE_DRAGGING, "start_drag() clone should enter dragging state.")
	_expect(source_state.state == CableRuntimeStateRef.STATE_IDLE, "start_drag() should not mutate the input state.")


func _check_extend_path() -> void:
	var source_state: BipobCableRuntimeState = CableRuntimeStateRef.new()
	source_state.cable_id = "cable_test"
	source_state.state = CableRuntimeStateRef.STATE_DRAGGING
	source_state.max_length = 2

	var one_cell_state: BipobCableRuntimeState = CableRuntimeServiceRef.extend_path(source_state, Vector2i(1, 1))
	_expect(one_cell_state != source_state, "extend_path() should return a cloned state.")
	_expect(one_cell_state.path_cells.size() == 1, "extend_path() should add the first path cell.")
	_expect(one_cell_state.path_cells[0] == Vector2i(1, 1), "extend_path() should add the requested first path cell.")
	_expect(source_state.path_cells.is_empty(), "extend_path() should not mutate the input state.")

	var duplicate_state: BipobCableRuntimeState = CableRuntimeServiceRef.extend_path(one_cell_state, Vector2i(1, 1))
	_expect(duplicate_state.path_cells.size() == 1, "extend_path() should not duplicate the same last cell.")

	var maxed_state: BipobCableRuntimeState = CableRuntimeServiceRef.extend_path(duplicate_state, Vector2i(2, 1))
	_expect(maxed_state.path_cells.size() == 2, "extend_path() should add cells until max_length is reached.")
	var overflow_state: BipobCableRuntimeState = CableRuntimeServiceRef.extend_path(maxed_state, Vector2i(3, 1))
	_expect(overflow_state.path_cells.size() == 2, "extend_path() should not add cells past max_length.")


func _check_connect() -> void:
	var source_state: BipobCableRuntimeState = CableRuntimeStateRef.new()
	source_state.cable_id = "cable_test"
	source_state.socket_id = "socket_test"
	source_state.state = CableRuntimeStateRef.STATE_DRAGGING

	_expect(CableRuntimeServiceRef.can_connect_to_socket(source_state, "socket_test", ""), "can_connect_to_socket() should allow compatible dragging state.")
	var connected_state: BipobCableRuntimeState = CableRuntimeServiceRef.connect_to_socket(source_state, "socket_test", "gate_test")
	_expect(connected_state != source_state, "connect_to_socket() should return a cloned state.")
	_expect(connected_state.state == CableRuntimeStateRef.STATE_CONNECTED, "connect_to_socket() clone should enter connected state.")
	_expect(connected_state.connected, "connect_to_socket() clone should mark connected true.")
	_expect(connected_state.socket_id == "socket_test", "connect_to_socket() should apply socket_id.")
	_expect(connected_state.linked_target_id == "gate_test", "connect_to_socket() should apply linked_target_id.")
	_expect(source_state.state == CableRuntimeStateRef.STATE_DRAGGING, "connect_to_socket() should not mutate input state.")
	_expect(not source_state.connected, "connect_to_socket() should not mark input state connected.")
	_expect(source_state.linked_target_id.is_empty(), "connect_to_socket() should not apply linked target to input state.")


func _check_release() -> void:
	var dragging_state: BipobCableRuntimeState = CableRuntimeStateRef.new()
	dragging_state.cable_id = "cable_test"
	dragging_state.state = CableRuntimeStateRef.STATE_DRAGGING

	var released_state: BipobCableRuntimeState = CableRuntimeServiceRef.release_cable(dragging_state)
	_expect(released_state.state == CableRuntimeStateRef.STATE_RELEASED, "release_cable() should release a dragging cable.")
	_expect(dragging_state.state == CableRuntimeStateRef.STATE_DRAGGING, "release_cable() should not mutate the dragging input state.")

	var connected_state: BipobCableRuntimeState = CableRuntimeStateRef.new()
	connected_state.cable_id = "cable_test"
	connected_state.state = CableRuntimeStateRef.STATE_CONNECTED
	connected_state.connected = true

	var still_connected_state: BipobCableRuntimeState = CableRuntimeServiceRef.release_cable(connected_state)
	_expect(still_connected_state.state == CableRuntimeStateRef.STATE_CONNECTED, "release_cable() should keep connected state connected.")
	_expect(still_connected_state.connected, "release_cable() should keep connected flag true.")


func _check_clear_path() -> void:
	var source_state: BipobCableRuntimeState = CableRuntimeStateRef.new()
	source_state.cable_id = "cable_test"
	source_state.path_cells = _make_path(Vector2i(1, 1), Vector2i(2, 1))

	var cleared_state: BipobCableRuntimeState = CableRuntimeServiceRef.clear_path(source_state)
	_expect(cleared_state != source_state, "clear_path() should return a cloned state.")
	_expect(cleared_state.path_cells.is_empty(), "clear_path() clone should have an empty path.")
	_expect(source_state.path_cells.size() == 2, "clear_path() should not mutate input path cells.")


func _check_legacy_snapshot() -> void:
	var legacy_path_cells: Array[Vector2i] = _make_path(Vector2i(2, 2), Vector2i(3, 2))
	var legacy_source: Dictionary = {
		"mission7_cable_reel_position": Vector2i(2, 2),
		"mission7_socket_position": Vector2i(3, 2),
		"mission7_powered_gate_position": Vector2i(4, 2),
		"mission7_cable_connected": false,
		"mission7_cable_max_length": 5,
		"mission7_cable_path": legacy_path_cells,
		"mission7_is_dragging_cable": true,
	}

	var snapshot_state: BipobCableRuntimeState = CableRuntimeServiceRef.snapshot_legacy_mission7(legacy_source)
	_expect(snapshot_state.cable_id == "cable_a", "snapshot_legacy_mission7() should use the legacy cable id.")
	_expect(snapshot_state.state == CableRuntimeStateRef.STATE_DRAGGING, "snapshot_legacy_mission7() should report dragging state.")
	_expect(snapshot_state.path_cells.size() == 2, "snapshot_legacy_mission7() should copy path cells.")
	_expect(snapshot_state.reel_position == Vector2i(2, 2), "snapshot_legacy_mission7() should copy reel position.")
	_expect(snapshot_state.socket_position == Vector2i(3, 2), "snapshot_legacy_mission7() should copy socket position.")
	_expect(snapshot_state.target_position == Vector2i(4, 2), "snapshot_legacy_mission7() should copy target position.")
	_expect(snapshot_state.max_length == 5, "snapshot_legacy_mission7() should copy max length.")
	var legacy_path: Array = Array(legacy_source.get("mission7_cable_path", []))
	_expect(legacy_path.size() == 2, "snapshot_legacy_mission7() should not mutate legacy dictionary path.")


func _make_path(first_cell: Vector2i, second_cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.append(first_cell)
	result.append(second_cell)
	return result
