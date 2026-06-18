extends RefCounted

# Target class: Result
# Единый формат результата mutation.

var ok: bool = true
var message: String = ""
var changed_ids: Array[String] = []
var warnings: Array[String] = []
var events: Array = []

static func success(text: String = "") -> Dictionary:
	return {"ok": true, "message": text, "changed_ids": [], "warnings": [], "events": []}

static func failure(text: String) -> Dictionary:
	return {"ok": false, "message": text, "changed_ids": [], "warnings": [], "events": []}
