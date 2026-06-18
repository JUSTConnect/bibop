extends Node

# Target class: SaveLoadService
# Единый сервис сохранений. Не должен знать про UI layout.

func load_profile(_profile_id: String = "default") -> Dictionary:
	return {}

func save_profile(_profile_id: String, _data: Dictionary) -> bool:
	return true

func load_mission_save(_slot_id: String) -> Dictionary:
	return {}

func save_mission(_slot_id: String, _snapshot: Dictionary) -> bool:
	return true
