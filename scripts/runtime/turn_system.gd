extends RefCounted

# Target class: TurnSystem
# Ходовая система: begin/end turn, reset resources, world tick.

var turn_index: int = 0

func begin_turn(_actor_id: String) -> void:
	pass

func end_turn(actor_id: String) -> Dictionary:
	turn_index += 1
	return {"ok": true, "message": "Turn ended.", "actor_id": actor_id, "turn_index": turn_index}

func tick_world_effects() -> void:
	pass
