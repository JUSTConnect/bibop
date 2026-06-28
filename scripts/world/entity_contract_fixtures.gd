extends RefCounted

const FIXTURES: Dictionary = {
	"status_none": {
		"profile_field": "status_profile",
		"profile_id": "none",
		"valid_sample": {"entity_type": "object", "capabilities": {"state": false}},
		"invalid_mutations": [{"path": "capabilities.state", "value": true, "expected_code": "entity_contract.profile_capability_required"}],
		"allowed_fields": {"stored": [], "editable": [], "computed": []}
	}
}
