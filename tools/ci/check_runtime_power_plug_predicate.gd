extends SceneTree

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const InteractionSystemRef = preload("res://scripts/world/interaction_system.gd")

var _failed: bool = false


func _initialize() -> void:
	_run()
	if _failed:
		quit(1)
		return
	print("OK: runtime power plug predicate checks passed")
	quit(0)


func _run() -> void:
	_expect_accepts({"id":"terminal_a", "object_group":"terminal", "object_type":"terminal", "state":"unpowered", "is_powered":false}, "unpowered terminal should accept runtime power plug")
	_expect_accepts({"id":"door_a", "object_group":"door", "object_type":"powered_door", "state":"unpowered", "power_mode":"external", "is_powered":false}, "external unpowered door should accept runtime power plug")
	_expect_accepts({"id":"firewall_a", "object_group":"security", "object_type":"security_device", "archetype_id":"firewall_node", "state":"unpowered", "is_powered":false}, "unpowered firewall-like device should accept runtime power plug")
	_expect_accepts({"id":"socket_a", "object_type":"power_socket", "state":"active", "is_powered":true}, "existing power socket should accept runtime power plug")
	_expect_rejects({"id":"broken_terminal", "object_group":"terminal", "object_type":"terminal", "state":"broken", "is_powered":false}, "broken terminal should reject runtime power plug")
	_expect_rejects({"id":"damaged_door", "object_group":"door", "object_type":"powered_door", "damaged":true, "power_mode":"external"}, "damaged door should reject runtime power plug")


func _expect_accepts(object_data: Dictionary, message: String) -> void:
	_expect(WorldObjectCatalogRef.object_accepts_runtime_power_plug(object_data), message)
	_expect(InteractionSystemRef._object_supports_external_power_input(object_data), "%s through InteractionSystem delegate" % message)


func _expect_rejects(object_data: Dictionary, message: String) -> void:
	_expect(not WorldObjectCatalogRef.object_accepts_runtime_power_plug(object_data), message)
	_expect(not InteractionSystemRef._object_supports_external_power_input(object_data), "%s through InteractionSystem delegate" % message)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
