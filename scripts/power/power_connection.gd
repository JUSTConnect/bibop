extends RefCounted

var from_id: String = ""
var to_id: String = ""

static func make(source_id: String, target_id: String) -> RefCounted:
	var connection: RefCounted = new()
	connection.set("from_id", source_id)
	connection.set("to_id", target_id)
	return connection
