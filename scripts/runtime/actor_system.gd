extends RefCounted

# Target class: ActorSystem
# Movement, rotation, energy/actions for actors.

var repository: RefCounted = null

func can_move_actor(_actor_id: String, _direction: String) -> bool:
	return true

func move_actor(actor_id: String, direction: String) -> Dictionary:
	return {"ok": true, "message": "Actor moved.", "changed_ids": [actor_id], "direction": direction}

func turn_actor(actor_id: String, direction: String) -> Dictionary:
	return {"ok": true, "message": "Actor turned.", "changed_ids": [actor_id], "direction": direction}
