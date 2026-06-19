extends RefCounted

var from_id: String = ""
var to_id: String = ""

static func make(source_id: String, target_id: String) -> RefCounted:
	var connection := new()
	connection.from_id = source_id
	connection.to_id = target_id
	return connection
