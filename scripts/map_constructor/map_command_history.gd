extends RefCounted

signal changed(can_undo: bool, can_redo: bool)

var undo_stack: Array[RefCounted] = []
var redo_stack: Array[RefCounted] = []

func execute(command: RefCounted) -> bool:
	if not bool(command.call("execute")):
		return false
	undo_stack.append(command)
	redo_stack.clear()
	_emit_changed()
	return true

func undo() -> bool:
	if undo_stack.is_empty():
		return false
	var command: RefCounted = undo_stack.pop_back()
	command.call("undo")
	redo_stack.append(command)
	_emit_changed()
	return true

func redo() -> bool:
	if redo_stack.is_empty():
		return false
	var command: RefCounted = redo_stack.pop_back()
	if not bool(command.call("execute")):
		return false
	undo_stack.append(command)
	_emit_changed()
	return true

func clear() -> void:
	undo_stack.clear()
	redo_stack.clear()
	_emit_changed()

func can_undo() -> bool:
	return not undo_stack.is_empty()

func can_redo() -> bool:
	return not redo_stack.is_empty()

func undo_label() -> String:
	if undo_stack.is_empty():
		return ""
	return str(undo_stack.back().get("label"))

func redo_label() -> String:
	if redo_stack.is_empty():
		return ""
	return str(redo_stack.back().get("label"))

func _emit_changed() -> void:
	changed.emit(can_undo(), can_redo())
