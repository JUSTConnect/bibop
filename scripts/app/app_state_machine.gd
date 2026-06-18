extends RefCounted

# Target class: AppStateMachine
# Единая точка переключения режимов приложения.

const MODE_BOOT := "boot"
const MODE_MAIN_MENU := "main_menu"
const MODE_MISSION_SELECT := "mission_select"
const MODE_GAMEPLAY := "gameplay"
const MODE_MAP_CONSTRUCTOR := "map_constructor"
const MODE_PAUSE_MENU := "pause_menu"
const MODE_SETTINGS := "settings"
const MODE_DEBUG_TOOLS := "debug_tools"
const MODE_GAME_OVER := "game_over"

var current_mode: String = MODE_BOOT

func can_transition(_from_mode: String, _to_mode: String) -> bool:
	return true

func set_mode(mode: String, _payload: Dictionary = {}) -> bool:
	if not can_transition(current_mode, mode):
		return false
	current_mode = mode
	return true

func get_current_mode() -> String:
	return current_mode
