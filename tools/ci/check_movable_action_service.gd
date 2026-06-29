extends SceneTree

const MovableService = preload("res://scripts/game/movable/movable_action_service.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _actor(actor_type: String, manipulator_level: int, heavy_claw_level: int, power_class: String = "", occupied: bool = false, actor_count: int = 1) -> Dictionary:
	return {
		"actor_type": actor_type,
		"actor_count": actor_count,
		"power_class": actor_type if power_class.is_empty() else power_class,
		"manipulator_level": manipulator_level,
		"manipulator_active": manipulator_level > 0,
		"manipulator_occupied": occupied,
		"heavy_claw_level": heavy_claw_level,
		"heavy_claw_active": heavy_claw_level > 0,
		"actor_position": Vector2i(0, 0),
		"facing_direction": Vector2i(1, 0)
	}

func _crate(weight_class: String) -> Dictionary:
	return {
		"id": "crate_%s" % weight_class,
		"position": Vector2i(1, 0),
		"object_group": "physical_object",
		"object_type": "crate",
		"weight_class": weight_class,
		"entity_contract": {"entity_type": "movable"}
	}

func _destination(to_cell: Vector2i = Vector2i(2, 0), passable: bool = true, occupied: bool = false, in_bounds: bool = true, surface_allowed: bool = true) -> Dictionary:
	return {
		"validate_destination": true,
		"validate_target_relation": true,
		"from_cell": Vector2i(1, 0),
		"to_cell": to_cell,
		"in_bounds": in_bounds,
		"destination_passable": passable,
		"destination_occupied": occupied,
		"surface_move_allowed": surface_allowed
	}

func _code(result: Dictionary) -> String:
	return str(result.get("code", result.get("reason_code", "")))

func _run() -> void:
	await process_frame
	var normal_crate: Dictionary = _crate(MovableService.WEIGHT_NORMAL)
	var scout: Dictionary = _actor("scout", 1, 0)
	var normal_preview: Dictionary = MovableService.preview_action(scout, normal_crate, "push", _destination())
	_assert(bool(normal_preview.get("success", false)), "normal crate rejected valid scout: %s" % str(normal_preview))
	_assert(str(Dictionary(normal_preview.get("movement_requirement", {})).get("required_manipulator", "")) == MovableService.MANIPULATOR_ARM, "normal crate did not require regular manipulator")

	var occupied_scout: Dictionary = _actor("scout", 1, 0, "scout", true)
	_assert(_code(MovableService.preview_action(occupied_scout, normal_crate, "push", _destination())) == MovableService.CODE_MANIPULATOR_OCCUPIED, "normal crate ignored occupied manipulator")
	var no_arm_scout: Dictionary = _actor("scout", 0, 0)
	_assert(_code(MovableService.preview_action(no_arm_scout, normal_crate, "push", _destination())) == MovableService.CODE_MANIPULATOR_REQUIRED, "normal crate ignored missing manipulator")

	var heavy_crate: Dictionary = _crate(MovableService.WEIGHT_HEAVY)
	_assert(_code(MovableService.preview_action(scout, heavy_crate, "push", _destination())) == MovableService.CODE_ACTOR_TYPE_INCOMPATIBLE, "heavy crate accepted scout")
	var engineer_without_claw: Dictionary = _actor("engineer", 1, 0)
	_assert(_code(MovableService.preview_action(engineer_without_claw, heavy_crate, "push", _destination())) == MovableService.CODE_HEAVY_CLAW_REQUIRED, "heavy crate accepted engineer without Heavy Claw")
	var engineer_with_claw: Dictionary = _actor("engineer", 1, 1, "engineer", true)
	var heavy_preview: Dictionary = MovableService.preview_action(engineer_with_claw, heavy_crate, "push", _destination())
	_assert(bool(heavy_preview.get("success", false)), "valid engineer Heavy Claw rejected: %s" % str(heavy_preview))
	_assert(str(Dictionary(heavy_preview.get("movement_requirement", {})).get("movement_mode", "")) == MovableService.MOVEMENT_DRAG, "heavy crate movement mode is not drag")
	_assert(bool(heavy_preview.get("success", false)), "held regular-manipulator item blocked Heavy Claw")

	var juggernaut: Dictionary = _actor("Juggernaut", 0, 1, "Juggernaut", true)
	var juggernaut_preview: Dictionary = MovableService.preview_action(juggernaut, heavy_crate, "push", _destination())
	_assert(bool(juggernaut_preview.get("success", false)), "Juggernaut alias did not normalize to heavy")
	_assert(str(Dictionary(juggernaut_preview.get("details", {})).get("actor_type", "")) == MovableService.ACTOR_HEAVY, "Juggernaut canonical actor type is not heavy")

	var combined_actors: Dictionary = _actor("scout", 1, 1, "heavy", false, 2)
	_assert(_code(MovableService.preview_action(combined_actors, heavy_crate, "push", _destination())) == MovableService.CODE_ACTOR_COUNT_INVALID, "multiple actors combined strength")

	var barrel: Dictionary = {
		"id": "barrel",
		"position": Vector2i(1, 0),
		"object_type": "barrel",
		"entity_contract": {"entity_type": "movable"},
		"weight_class": "heavy",
		"movement_requirement": {
			"profile_id": "barrel_push",
			"required_actor_types": ["scout", "engineer", "heavy"],
			"required_manipulator": "manipulator_arm",
			"required_manipulator_level": 1,
			"required_power_class": "scout",
			"movement_mode": "push"
		}
	}
	var normalized_barrel: Dictionary = MovableService.normalize_movable_contract(barrel)
	_assert(not normalized_barrel.has("weight_class"), "non-crate movable retained weight_class")
	_assert(normalized_barrel.has("movement_requirement"), "non-crate movable lost requirement profile")

	var invalid_crate: Dictionary = _crate("block")
	_assert(_code(MovableService.preview_action(engineer_with_claw, invalid_crate, "push", _destination())) == MovableService.CODE_INVALID_WEIGHT_CLASS, "invalid crate weight class accepted")

	var blocked_before_actor: String = var_to_str(engineer_with_claw)
	var blocked_before_object: String = var_to_str(heavy_crate)
	var blocked_preview: Dictionary = MovableService.preview_action(engineer_with_claw, heavy_crate, "push", _destination(Vector2i(2, 0), false))
	_assert(_code(blocked_preview) == MovableService.CODE_DESTINATION_BLOCKED, "blocked destination code mismatch")
	_assert(var_to_str(engineer_with_claw) == blocked_before_actor, "failed preview mutated actor")
	_assert(var_to_str(heavy_crate) == blocked_before_object, "failed preview mutated object")
	_assert(_code(MovableService.preview_action(engineer_with_claw, heavy_crate, "push", _destination(Vector2i(2, 0), true, true))) == MovableService.CODE_DESTINATION_OCCUPIED, "occupied destination code mismatch")
	_assert(_code(MovableService.preview_action(engineer_with_claw, heavy_crate, "push", _destination(Vector2i(2, 0), true, false, false))) == MovableService.CODE_DESTINATION_OUT_OF_BOUNDS, "out-of-bounds destination code mismatch")
	_assert(_code(MovableService.preview_action(engineer_with_claw, heavy_crate, "push", _destination(Vector2i(2, 0), true, false, true, false))) == MovableService.CODE_SURFACE_LEVEL_MISMATCH, "surface mismatch code mismatch")

	var not_in_front_actor: Dictionary = _actor("engineer", 1, 1)
	not_in_front_actor["facing_direction"] = Vector2i(0, 1)
	_assert(_code(MovableService.preview_action(not_in_front_actor, heavy_crate, "push")) == MovableService.CODE_TARGET_NOT_IN_FRONT, "front-facing rule not enforced")

	await process_frame
	if failures.is_empty():
		print("MOVABLE_ACTION_SERVICE_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("MOVABLE_ACTION_SERVICE_GATE: FAIL: %s" % failure)
	quit(1)
