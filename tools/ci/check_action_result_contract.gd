extends SceneTree

const Contract = preload("res://scripts/game/actions/action_result_contract.gd")
const CommandService = preload("res://scripts/game/actions/player_action_command_service.gd")
const Aggregator = preload("res://scripts/game/actions/action_result_aggregator.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func run() -> void:
	await process_frame
	var commands = CommandService.new("test")
	var command_a: Dictionary = commands.begin_command("bipob", "door_a", "door.open")
	var command_b: Dictionary = commands.begin_command("bipob", "door_a", "door.open")
	check(not str(command_a.get("action_id", "")).is_empty(), "command action_id missing")
	check(command_a.get("action_id") == command_a.get("correlation_id"), "command correlation differs from action id")
	check(command_a.get("action_id") != command_b.get("action_id"), "two commands reused action id")

	var nested: Dictionary = CommandService.propagate(command_a, {"step":"access"})
	check(nested.get("action_id") == command_a.get("action_id"), "nested command changed action id")
	check(nested.get("correlation_id") == command_a.get("action_id"), "nested correlation changed")

	var access_step: Dictionary = commands.make_step(command_a, "access.granted", Contract.RESULT_SUCCESS, "access.granted", "Access granted.")
	var item_step: Dictionary = commands.make_step(command_a, "item.consumed", Contract.RESULT_SUCCESS, "item.consumed", "Credential consumed.")
	var mutation_step: Dictionary = commands.make_step(command_a, "door.open.no_change", Contract.RESULT_NO_CHANGE, "door.open.no_change", "Door is already open.")
	for step in [access_step, item_step, mutation_step]:
		check(step.get("action_id") == command_a.get("action_id"), "step lost correlation")

	var aggregator = Aggregator.new()
	var aggregation: Dictionary = aggregator.aggregate(command_a, [access_step, item_step, mutation_step])
	check(bool(aggregation.get("success", false)), "aggregation failed")
	check(not bool(aggregation.get("duplicate", true)), "first aggregation marked duplicate")
	var final_result: Dictionary = Dictionary(aggregation.get("action_result", {}))
	check(str(final_result.get("result", "")) == Contract.RESULT_SUCCESS, "success composition selected wrong outcome")
	check(int(Dictionary(final_result.get("details", {})).get("step_count", 0)) == 3, "step count missing")
	var event: Dictionary = Dictionary(aggregation.get("notification_event", {}))
	check(event.get("event_id") == command_a.get("action_id"), "event id differs from command id")

	var duplicate: Dictionary = aggregator.aggregate(command_a, [access_step])
	check(bool(duplicate.get("duplicate", false)), "duplicate delivery was not ignored")
	check(Dictionary(duplicate.get("notification_event", {})).is_empty(), "duplicate produced event")

	var blocked_command: Dictionary = commands.begin_command("bipob", "door_b", "door.open")
	var blocked_step: Dictionary = commands.make_step(blocked_command, "access.credential_missing", Contract.RESULT_BLOCKED, "access.credential_missing", "Credential required.")
	var earlier_success: Dictionary = commands.make_step(blocked_command, "power.ready", Contract.RESULT_SUCCESS, "power.ready", "Power ready.")
	var blocked_aggregation: Dictionary = aggregator.aggregate(blocked_command, [earlier_success, blocked_step])
	check(str(Dictionary(blocked_aggregation.get("action_result", {})).get("result", "")) == Contract.RESULT_BLOCKED, "blocked outcome priority changed")

	var mismatch_command: Dictionary = commands.begin_command("bipob", "door_c", "door.open")
	var mismatch: Dictionary = aggregator.aggregate(mismatch_command, [access_step])
	check(str(mismatch.get("code", "")) == "action_aggregation.correlation_mismatch", "correlation mismatch accepted")

	var empty_command: Dictionary = commands.begin_command("bipob", "door_d", "door.open")
	var empty_result: Dictionary = aggregator.aggregate(empty_command, [])
	check(str(Dictionary(empty_result.get("action_result", {})).get("result", "")) == Contract.RESULT_NO_CHANGE, "empty aggregation did not produce no_change")

	if failures.is_empty():
		print("ACTION_RESULT_CONTRACT_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("ACTION_RESULT_CONTRACT_GATE: FAIL: %s" % failure)
	quit(1)
