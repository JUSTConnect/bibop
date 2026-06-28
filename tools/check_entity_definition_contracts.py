#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
contract = root / 'scripts/world/entity_definition_contract.gd'
fixtures = root / 'scripts/world/entity_contract_fixtures.gd'
world = (root / 'scripts/world/world_object_catalog.gd').read_text()
prefab = (root / 'scripts/game/map_constructor_prefab_catalog.gd').read_text()
mission = (root / 'scripts/game/mission_manager.gd').read_text()
service = (root / 'scripts/game/map_constructor_service.gd').read_text()
workflow = (root / '.github/workflows/godot-parser-gate.yml').read_text()
text = contract.read_text() if contract.exists() else ''
fixture_text = fixtures.read_text() if fixtures.exists() else ''
combined = text + fixture_text
checks = [
('EntityDefinitionContract exists', contract.exists() and 'class_name EntityDefinitionContract' in text),
('fixture registry exists', fixtures.exists() and 'const SPECS: Dictionary' in fixture_text),
('contract owns capability/profile registries', all(v in combined for v in ['CAPABILITY_KEYS', 'PROFILE_REGISTRIES', 'FIELD_SEMANTICS'])),
('profile registry is descriptor based', '"status_profile":{"none":{' in fixture_text and 'static func has_profile' in fixture_text and 'static func get_profile_descriptor' in fixture_text),
('fixtures are machine readable', all(v in fixture_text for v in ['valid_sample', 'invalid_mutations', 'expected_code', 'allowed_fields'])),
('stable semantic error codes declared', all(v in combined for v in ['entity_contract.profile_entity_type_mismatch', 'entity_contract.capability_field_forbidden', 'entity_contract.computed_field_editable', 'entity_contract.legacy_exception_invalid'])),
('rich diagnostics declared', all(v in text for v in ['severity', 'message_key', 'fallback', 'fix_hint'])),
('temporary migration issues declared', all(v in combined for v in ['1181', '1182', '1183', '1188', '1189', '1190', '1191', '1192']) and 'legacy_semantic_exceptions' in world),
('WorldObjectCatalog has no inferred contract inventory', 'ENTITY_CONTRACT_TYPE_BY_PREFAB' not in world and 'ENTITY_CONTRACT_EXCLUSIONS' not in world and '_entity_contract_for' not in world),
('WorldObjectCatalog uses explicit entity_contract fields', '"entity_contract"' in world and 'definition["entity_contract"] =' not in world),
('legacy alias dictionaries do not copy contracts', world.split('const ARCHETYPE_REGISTRY', 1)[0].count('entity_contract') == 0),
('MissionManager does not own entity contracts', all(v not in mission for v in ['ENTITY_TYPES', 'CAPABILITY_KEYS', 'PROFILE_REGISTRIES'])),
('MapConstructorPrefabCatalog has no gameplay registries', all(v not in prefab for v in ['CAPABILITY_KEYS', 'PROFILE_REGISTRIES', 'ENTITY_TYPES', 'FIELD_SEMANTICS'])),
('direct placement fallback removed', 'display_name": prefab_id.capitalize(), "state": "active"' not in service and 'incomplete_entity_contract' in service),
('WorldObjectCatalog exposes accessors', all(v in world for v in ['get_entity_definition_contract(', 'validate_entity_definition_contract(', 'get_entity_definition_contract_for_object(', 'is_entity_definition_palette_eligible('])),
('create_archetype_object validates contract', 'static func create_archetype_object' in world and 'validate_entity_definition_contract(archetype_id)' in world),
('workflow runs Python gate', 'python tools/check_entity_definition_contracts.py' in workflow),
('workflow runs Godot gate', 'check_entity_definition_contracts.gd' in workflow),
]
failed = [name for name, ok in checks if not ok]
for name, ok in checks:
    print(('OK: ' if ok else 'FAIL: ') + name)
if failed:
    raise SystemExit(1)
