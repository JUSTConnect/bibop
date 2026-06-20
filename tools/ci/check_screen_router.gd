extends SceneTree

const ScreenRouterRef = preload("res://scripts/ui/navigation/screen_router.gd")

class RouterHost:
	extends Control
	var router: ScreenRouter

	func _screen_router_restore_focus(screen_id: StringName, screen: Control, preferred_focus: Variant = null) -> void:
		if router == null or router.get_active_screen_id() != screen_id:
			return
		var target: Control = router.resolve_focus_target(screen_id, screen, preferred_focus)
		if target != null:
			target.grab_focus()


var host: RouterHost
var router: ScreenRouter
var factory_counts: Dictionary = {}
var enter_counts: Dictionary = {}
var cleanup_counts: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return condition


func _make_screen(screen_id: StringName) -> Control:
	factory_counts[screen_id] = int(factory_counts.get(screen_id, 0)) + 1
	var root := Control.new()
	root.name = String(screen_id)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var button := Button.new()
	button.name = "FocusButton"
	button.text = String(screen_id)
	button.focus_mode = Control.FOCUS_ALL
	root.add_child(button)
	return root


func _on_enter(_screen: Control, _payload: Dictionary, _repeated: bool, screen_id: StringName) -> void:
	enter_counts[screen_id] = int(enter_counts.get(screen_id, 0)) + 1


func _on_cleanup(_screen: Control, screen_id: StringName) -> void:
	cleanup_counts[screen_id] = int(cleanup_counts.get(screen_id, 0)) + 1


func _register(screen_id: StringName, cache: bool = true) -> void:
	router.register_screen(
		screen_id,
		Callable(self, "_make_screen").bind(screen_id),
		Callable(self, "_on_enter").bind(screen_id),
		Callable(),
		Callable(self, "_on_cleanup").bind(screen_id),
		cache
	)


func _run() -> void:
	host = RouterHost.new()
	root.add_child(host)
	router = ScreenRouterRef.new(host)
	host.router = router
	_register(&"a", true)
	_register(&"b", false)
	_register(&"c", true)

	var ok := _expect(router.reset(&"a", {"value": 1}), "reset(A) must succeed")
	await process_frame
	var a_root: Control = router.get_screen(&"a")
	ok = _expect(router.get_active_screen_id() == &"a" and a_root != null and a_root.visible, "A must be active and visible") and ok
	ok = _expect(int(factory_counts.get(&"a", 0)) == 1, "A factory must run once") and ok

	var a_button: Button = a_root.get_node("FocusButton") as Button
	a_button.grab_focus()
	await process_frame
	ok = _expect(router.replace(&"a", {"value": 2}), "repeated open(A) must succeed") and ok
	await process_frame
	ok = _expect(router.get_screen(&"a") == a_root, "repeated open must reuse cached instance") and ok
	ok = _expect(int(factory_counts.get(&"a", 0)) == 1 and int(enter_counts.get(&"a", 0)) == 2, "repeated open must not duplicate root") and ok

	ok = _expect(router.push(&"b"), "push(B) must succeed") and ok
	await process_frame
	var b_root: Control = router.get_screen(&"b")
	ok = _expect(router.get_back_stack_size() == 1, "push must create one back-stack entry") and ok
	ok = _expect(not a_root.visible and b_root != null and b_root.visible, "push must hide A and show B") and ok

	ok = _expect(router.back(), "back() must return to A") and ok
	await process_frame
	ok = _expect(router.get_active_screen_id() == &"a" and a_root.visible, "back must restore A") and ok
	ok = _expect(router.get_screen(&"b") == null, "transient B must be removed from router instances") and ok
	ok = _expect(int(cleanup_counts.get(&"b", 0)) == 1, "transient B cleanup must run once") and ok
	ok = _expect(host.get_viewport().gui_get_focus_owner() == a_button, "back must restore previous focus") and ok

	ok = _expect(router.replace(&"c"), "replace(C) must succeed") and ok
	await process_frame
	ok = _expect(router.get_active_screen_id() == &"c" and router.get_back_stack_size() == 0, "replace must not add history") and ok
	var previous_active := router.get_active_screen_id()
	ok = _expect(not router.replace(&"missing"), "invalid screen ID must fail") and ok
	ok = _expect(router.get_active_screen_id() == previous_active and router.get_last_error() == "invalid_screen_id", "invalid transition must preserve active screen") and ok

	router.cleanup_all()
	await process_frame
	ok = _expect(router.get_active_screen_id() == &"" and router.get_screen(&"a") == null and router.get_screen(&"c") == null, "cleanup_all must clear instances and active ID") and ok

	if ok:
		print("check_screen_router: OK")
		quit(0)
	else:
		push_error("check_screen_router: FAILED")
		quit(1)
