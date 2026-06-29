extends RefCounted
class_name BindingStore

var _bindings: Dictionary = {}

func add_binding(source_id: String, target_id: String, binding_type: String = "logical") -> Dictionary:
	var source_key: String = source_id.strip_edges()
	var target_key: String = target_id.strip_edges()
	var type_key: String = binding_type.strip_edges()
	if source_key.is_empty() or target_key.is_empty() or type_key.is_empty():
		return {"ok":false, "error":"invalid_binding"}
	var rows: Array = Array(_bindings.get(source_key, [])).duplicate(true)
	for row in rows:
		var binding: Dictionary = Dictionary(row)
		if str(binding.get("target_id", "")) == target_key and str(binding.get("binding_type", "")) == type_key:
			return {"ok":true, "binding":binding.duplicate(true), "created":false}
	var record: Dictionary = {"source_id":source_key, "target_id":target_key, "binding_type":type_key}
	rows.append(record)
	_bindings[source_key] = rows
	return {"ok":true, "binding":record.duplicate(true), "created":true}

func remove_binding(source_id: String, target_id: String, binding_type: String = "logical") -> bool:
	var source_key: String = source_id.strip_edges()
	if not _bindings.has(source_key):
		return false
	var next_rows: Array = []
	var removed: bool = false
	for row in Array(_bindings.get(source_key, [])):
		var binding: Dictionary = Dictionary(row)
		if str(binding.get("target_id", "")) == target_id and str(binding.get("binding_type", "")) == binding_type:
			removed = true
		else:
			next_rows.append(binding)
	if next_rows.is_empty():
		_bindings.erase(source_key)
	else:
		_bindings[source_key] = next_rows
	return removed

func get_bindings_for_source(source_id: String) -> Array:
	return Array(_bindings.get(source_id.strip_edges(), [])).duplicate(true)

func replace_snapshot(snapshot: Dictionary) -> void:
	_bindings.clear()
	for source_id in snapshot.keys():
		var rows: Array = []
		for row in Array(snapshot[source_id]):
			rows.append(Dictionary(row).duplicate(true))
		_bindings[str(source_id)] = rows

func get_snapshot() -> Dictionary:
	return _bindings.duplicate(true)
