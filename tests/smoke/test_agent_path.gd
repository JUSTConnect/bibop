extends RefCounted

const RepositoryRef = preload("res://scripts/world/world_object_repository.gd")
const AgentRef = preload("res://scripts/agents/test_agent_controller.gd")

static func run() -> Array[String]:
	var errors: Array[String] = []
	var repository: RefCounted = RepositoryRef.new()
	repository.call("add_object", {
		"id": "door_1",
		"object_type": "door",
		"state": "closed",
		"placement": {"cell_x": 3, "cell_y": 2},
	})
	var corridor: Array[Vector2i] = []
	for x in range(6):
		corridor.append(Vector2i(x, 2))
	var agent: RefCounted = AgentRef.new()
	agent.call("setup", Vector2i(0, 2), Vector2i(5, 2), corridor)
	var blocked: Dictionary = Dictionary(agent.call("step", repository, 6, 5))
	if bool(blocked.get("moved", false)):
		errors.append("Agent must not move through closed corridor door")
	repository.call("apply_patch", "door_1", {"state": "open"})
	for step_index in range(5):
		agent.call("step", repository, 6, 5)
	if not bool(agent.call("reached_goal")):
		errors.append("Agent must reach goal after door opens")
	return errors
