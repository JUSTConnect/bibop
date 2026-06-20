extends RefCounted
class_name ScreenRouter

signal transition_completed(from_screen: StringName, to_screen: StringName, transition: StringName)
signal transition_failed(screen_id: StringName, reason: String)

const TRANSITION_REPLACE: StringName = &"replace"
const TRANSITION_PUSH: StringName = &"push"
const TRANSITION_BACK: StringName = &"back"
const TRANSITION_RESET: StringName = &"reset"

const SCREEN_MAIN_MENU: StringName = &"main_menu"
const SCREEN_CENTER: StringName = &"center"
const SCREEN_TASKS: StringName = &"tasks"
const SCREEN_GAMEPLAY: StringName = &"gameplay"
const SCREEN_MISSION_RESULT: StringName = &"mission_result"

var _host: Node
var _registry: Dictionary = {}
var _instances: Dictionary = {}
var _active_screen_id: StringName = &""
var _active_payload: Dictionary = {}
var _back_stack: Array[Dictionary] = []
var _last_error: String = ""


func _init(host: Node) -> void:
	_host = host


func register_screen(
	screen_id: StringName,
	factory: Callable,
	on_enter: Callable = Callable(),
	on_exit: Callable = Callable(),
	on_cleanup: Callable = Callable(),
	cache_instance: bool = true,
	focus_resolver: Callable = Callable()
) -> bool:
	if screen_id == &"" or not factory.is_valid():
		return _fail(screen_id, "invalid_registration")
	_registry[screen_id] = {
		"factory": factory,
		"on_enter": on_enter,
		"on_exit": on_exit,
		"on_cleanup": on_cleanup,
		"cache": cache_instance,
		"focus_resolver": focus_resolver,
	}
	return true


func has_screen(screen_id: StringName) -> bool:
	return _registry.has(screen_id)


func get_active_screen_id() -> StringName:
	return _active_screen_id


func get_active_payload() -> Dictionary:
	return _active_payload.duplicate(true)


func set_active_payload(payload: Dictionary) -> void:
	if _active_screen_id == &"":
		return
	_active_payload = payload.duplicate(true)


func get_back_stack_size() -> int:
	return _back_stack.size()


func get_last_error() -> String:
	return _last_error


func get_screen(screen_id: StringName) -> Control:
	var screen: Control = _instances.get(screen_id, null) as Control
	if screen != null and is_instance_valid(screen):
		return screen
	_instances.erase(screen_id)
	return null


func reset(screen_id: StringName, payload: Dictionary = {}) -> bool:
	if not has_screen(screen_id):
		return _fail(screen_id, "invalid_screen_id")
	var previous_stack: Array[Dictionary] = _back_stack.duplicate(true)
	_back_stack.clear()
	if _open(screen_id, payload, TRANSITION_RESET):
		return true
	_back_stack = previous_stack
	return false


func replace(screen_id: StringName, payload: Dictionary = {}) -> bool:
	return _open(screen_id, payload, TRANSITION_REPLACE)


func push(screen_id: StringName, payload: Dictionary = {}) -> bool:
	return _open(screen_id, payload, TRANSITION_PUSH)


func back() -> bool:
	if _back_stack.is_empty():
		return _fail(&"", "back_stack_empty")
	var target: Dictionary = _back_stack.back()
	var opened: bool = _open(
		StringName(target.get("screen_id", &"")),
		Dictionary(target.get("payload", {})),
		TRANSITION_BACK,
		target.get("focus", null)
	)
	if opened:
		_back_stack.pop_back()
	return opened


func refresh_active(payload: Dictionary = {}) -> bool:
	if _active_screen_id == &"":
		return false
	var merged_payload: Dictionary = _active_payload.duplicate(true)
	merged_payload.merge(payload, true)
	return _open(_active_screen_id, merged_payload, TRANSITION_REPLACE)


func deactivate_active(clear_history: bool = true) -> void:
	_leave_active()
	if clear_history:
		_back_stack.clear()


func forget_screen(screen_id: StringName, cleanup_instance: bool = false) -> void:
	if cleanup_instance:
		_cleanup_instance(screen_id)
	else:
		_instances.erase(screen_id)
	if _active_screen_id == screen_id:
		_active_screen_id = &""
		_active_payload.clear()


func cleanup_all() -> void:
	var ids: Array = _instances.keys()
	for screen_id_variant in ids:
		_cleanup_instance(StringName(screen_id_variant))
	_active_screen_id = &""
	_active_payload.clear()
	_back_stack.clear()


func _open(screen_id: StringName, payload: Dictionary, transition: StringName, preferred_focus: Variant = null) -> bool:
	_last_error = ""
	if not _registry.has(screen_id):
		return _fail(screen_id, "invalid_screen_id")
	var target: Control = _ensure_instance(screen_id)
	if target == null:
		return _fail(screen_id, "factory_failed")

	if screen_id == _active_screen_id:
		_active_payload = payload.duplicate(true)
		target.visible = true
		_call_enter(screen_id, target, _active_payload, true)
		_schedule_focus(screen_id, target, preferred_focus)
		transition_completed.emit(screen_id, screen_id, transition)
		return true

	var from_screen: StringName = _active_screen_id
	if transition == TRANSITION_PUSH and from_screen != &"":
		_back_stack.append({
			"screen_id": from_screen,
			"payload": _active_payload.duplicate(true),
			"focus": _capture_focus(get_screen(from_screen)),
		})

	_leave_active()
	_active_screen_id = screen_id
	_active_payload = payload.duplicate(true)
	target.visible = true
	_call_enter(screen_id, target, _active_payload, false)
	_schedule_focus(screen_id, target, preferred_focus)
	transition_completed.emit(from_screen, screen_id, transition)
	return true


func _ensure_instance(screen_id: StringName) -> Control:
	var existing: Control = get_screen(screen_id)
	if existing != null:
		return existing
	var registration: Dictionary = _registry.get(screen_id, {})
	var factory: Callable = registration.get("factory", Callable())
	if not factory.is_valid():
		return null
	var created_variant: Variant = factory.call()
	var created: Control = created_variant as Control
	if created == null or not is_instance_valid(created):
		return null
	created.visible = false
	if created.get_parent() == null and _host != null and is_instance_valid(_host):
		_host.add_child(created)
	_instances[screen_id] = created
	return created


func _leave_active() -> void:
	if _active_screen_id == &"":
		return
	var leaving_id: StringName = _active_screen_id
	var leaving: Control = get_screen(leaving_id)
	if leaving != null:
		_call_exit(leaving_id, leaving, _active_payload)
		leaving.visible = false
	var registration: Dictionary = _registry.get(leaving_id, {})
	if not bool(registration.get("cache", true)):
		_cleanup_instance(leaving_id)
	_active_screen_id = &""
	_active_payload.clear()


func _cleanup_instance(screen_id: StringName) -> void:
	var screen: Control = get_screen(screen_id)
	_instances.erase(screen_id)
	if screen == null:
		return
	var registration: Dictionary = _registry.get(screen_id, {})
	var cleanup: Callable = registration.get("on_cleanup", Callable())
	if cleanup.is_valid():
		cleanup.call(screen)
	if screen.get_parent() != null:
		screen.get_parent().remove_child(screen)
	screen.queue_free()


func _call_enter(screen_id: StringName, screen: Control, payload: Dictionary, repeated: bool) -> void:
	var callback: Callable = Dictionary(_registry.get(screen_id, {})).get("on_enter", Callable())
	if callback.is_valid():
		callback.call(screen, payload, repeated)


func _call_exit(screen_id: StringName, screen: Control, payload: Dictionary) -> void:
	var callback: Callable = Dictionary(_registry.get(screen_id, {})).get("on_exit", Callable())
	if callback.is_valid():
		callback.call(screen, payload)


func _capture_focus(screen: Control) -> Variant:
	if screen == null or screen.get_viewport() == null:
		return null
	var focused: Control = screen.get_viewport().gui_get_focus_owner()
	if focused == null or not is_instance_valid(focused):
		return null
	if focused == screen or screen.is_ancestor_of(focused):
		return weakref(focused)
	return null


func _schedule_focus(screen_id: StringName, screen: Control, preferred_focus: Variant) -> void:
	if _host == null or not is_instance_valid(_host):
		return
	_host.call_deferred("_screen_router_restore_focus", screen_id, screen, preferred_focus)


func resolve_focus_target(screen_id: StringName, screen: Control, preferred_focus: Variant = null) -> Control:
	if preferred_focus is WeakRef:
		var preferred: Object = preferred_focus.get_ref()
		if preferred is Control and is_instance_valid(preferred) and (preferred == screen or screen.is_ancestor_of(preferred)):
			return preferred as Control
	var registration: Dictionary = _registry.get(screen_id, {})
	var resolver: Callable = registration.get("focus_resolver", Callable())
	if resolver.is_valid():
		var resolved: Control = resolver.call(screen) as Control
		if resolved != null and is_instance_valid(resolved):
			return resolved
	return _find_first_focusable(screen)


func _find_first_focusable(node: Node) -> Control:
	if node is Control:
		var control: Control = node as Control
		if control.visible and control.focus_mode != Control.FOCUS_NONE:
			return control
	for child in node.get_children():
		var found: Control = _find_first_focusable(child)
		if found != null:
			return found
	return null


func _fail(screen_id: StringName, reason: String) -> bool:
	_last_error = reason
	transition_failed.emit(screen_id, reason)
	return false
