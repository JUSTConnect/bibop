extends RefCounted

# Target class: ConstructorUndoRedoService
# История действий map constructor.

var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []

func push_action(action: Dictionary) -> void:
	undo_stack.append(action)
	redo_stack.clear()

func undo() -> Dictionary:
	return {"ok": false, "message": "Undo is not implemented yet."}

func redo() -> Dictionary:
	return {"ok": false, "message": "Redo is not implemented yet."}
