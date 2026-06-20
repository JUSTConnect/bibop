extends SceneTree

func _init() -> void:
	var ok := true
	ok = _check_project_autoloads() and ok
	ok = _check_preview_controls() and ok
	ok = _check_explicit_lifecycle_api() and ok
	ok = _check_notification_one_shot_source() and ok
	if ok:
		print("check_event_driven_runtime_hud: OK")
		quit(0)
	else:
		push_error("check_event_driven_runtime_hud: FAILED")
		quit(1)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""

func _expect(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return condition

func _check_project_autoloads() -> bool:
	var project := _read("res://project.godot")
	return _expect(not project.contains("RuntimeHudRepair"), "RuntimeHudRepair autoload absent") and _expect(not project.contains("MapConstructorInspectorStructure="), "MapConstructorInspectorStructure autoload absent")

func _check_preview_controls() -> bool:
	var game := _read("res://scripts/ui/game_ui.gd")
	return _expect(game.contains("func request_refresh() -> void:\n\t\tqueue_redraw()"), "preview controls expose explicit redraw invalidation") and _expect(not game.contains("func _process(_delta: float) -> void:\n\t\tqueue_redraw()"), "preview controls do not redraw from idle _process")

func _check_explicit_lifecycle_api() -> bool:
	var game := _read("res://scripts/ui/game_ui.gd")
	var bridge := _read("res://scripts/ui/runtime/runtime_action_panel_bridge.gd")
	var inspector := _read("res://scripts/ui/map_constructor/map_constructor_inspector_structure_layer.gd")
	return _expect(game.contains("func _initialize_runtime_hud"), "gameplay entry builds HUD explicitly") and _expect(game.contains("func _teardown_runtime_hud"), "gameplay exit tears HUD down explicitly") and _expect(game.contains("func request_runtime_hud_refresh"), "state changes use explicit HUD invalidation") and _expect(not bridge.contains("RuntimeNotificationsRef.process_runtime_notification_timer(ui, delta)"), "bridge frame path does not own notification correctness") and _expect(inspector.contains("static func apply_structure"), "inspector structure has event API") and _expect(not inspector.contains("func _process"), "inspector structure has no idle repair loop")

func _check_notification_one_shot_source() -> bool:
	var game := _read("res://scripts/ui/game_ui.gd")
	return _expect(game.contains("runtime_notification_timeout.one_shot = true"), "notification timeout is one-shot") and _expect(game.contains("_restart_runtime_notification_timeout"), "notification show restarts timeout explicitly")
