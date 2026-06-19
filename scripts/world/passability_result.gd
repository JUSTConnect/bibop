extends RefCounted

var passable: bool = true
var reason: String = ""
var blocker_id: String = ""

static func allow() -> RefCounted:
	return new()

static func block(reason_text: String, object_id: String = "") -> RefCounted:
	var result: RefCounted = new()
	result.set("passable", false)
	result.set("reason", reason_text)
	result.set("blocker_id", object_id)
	return result
