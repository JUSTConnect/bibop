extends RefCounted

signal mode_changed(mode: String)

const EDIT := "edit"
const PLAY := "play"

var mode: String = EDIT

func enter_edit() -> void:
	_set_mode(EDIT)

func enter_play() -> void:
	_set_mode(PLAY)

func is_edit() -> bool:
	return mode == EDIT

func is_play() -> bool:
	return mode == PLAY

func _set_mode(next_mode: String) -> void:
	if next_mode == mode or not next_mode in [EDIT, PLAY]:
		return
	mode = next_mode
	mode_changed.emit(mode)
