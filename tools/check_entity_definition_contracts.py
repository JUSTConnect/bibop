#!/usr/bin/env python3
from pathlib import Path
root = Path(__file__).resolve().parents[1]
contract = root/'scripts/world/entity_definition_contract.gd'
world = (root/'scripts/world/world_object_catalog.gd').read_text()
prefab = (root/'scripts/game/map_constructor_prefab_catalog.gd').read_text()
mission = (root/'scripts/game/mission_manager.gd').read_text()
service = (root/'scripts/game/map_constructor_service.gd').read_text()
workflow = (root/'.github/workflows/godot-parser-gate.yml').read_text()
text = contract.read_text() if contract.exists() else ''
checks = [
('EntityDefinitionContract exists', contract.exists() and 'class_name EntityDefinitionContract' in text),
('contract owns capability/profile registries', 'CAPABILITY_KEYS' in text and 'PROFILE_REGISTRIES' in text and 'FIELD_SEMANTICS' in text),
('profile registry is descriptor based', '"status_profile":{"none":{' in text and 'static func has_profile' in text and 'static func get_profile_descriptor' in text),
('stable semantic error codes declared', all(code in text for code in ['entity_contract.profile_entity_type_mismatch', 'entity_contract.capability_field_forbidden', 'entity_contract.computed_field_editable', 'entity_contract.legacy_exception_invalid'])),
('temporary migration exceptions list issues', all(issue in text for issue in ['1181', '1182', '1183', '1188', '1189', '1190', '1191', '1192']) and 'legacy_semantic_exceptions' in world),
('WorldObjectCatalog has no inferred contract inventory', 'ENTITY_CONTRACT_TYPE_BY_PREFAB' not in world and 'ENTITY_CONTRACT_EXCLUSIONS' not in world and '_entity_contract_for' not in world),
('WorldObjectCatalog uses explicit entity_contract fields', '"entity_contract"' in world and 'definition["entity_contract"] =' not in world),
('legacy alias dictionaries do not copy contracts', world.split('const ARCHETYPE_REGISTRY', 1)[0].count('entity_contract') == 0),
('MissionManager does not own entity contracts', 'ENTITY_TYPES' not in mission and 'CAPABILITY_KEYS' not in mission and 'PROFILE_REGISTRIES' not in mission),
('MapConstructorPrefabCatalog has no gameplay registries', 'CAPABILITY_KEYS' not in prefab and 'PROFILE_REGISTRIES' not in prefab and 'ENTITY_TYPES' not in prefab and 'FIELD_SEMANTICS' not in prefab),
('direct placement fallback removed', 'display_name": prefab_id.capitalize(), "state": "active"' not in service and 'incomplete_entity_contract' in service),
('WorldObjectCatalog exposes accessors', all(tok in world for tok in ['get_entity_definition_contract(', 'validate_entity_definition_contract(', 'get_entity_definition_contract_for_object(', 'is_entity_definition_palette_eligible('])),
('create_archetype_object validates contract', 'static func create_archetype_object' in world and 'validate_entity_definition_contract(archetype_id)' in world),
('workflow runs Python gate', 'python tools/check_entity_definition_contracts.py' in workflow),
('workflow runs Godot gate', 'check_entity_definition_contracts.gd' in workflow),
]
failed=[n for n,ok in checks if not ok]
for n,ok in checks: print(('OK: ' if ok else 'FAIL: ')+n)
if failed: raise SystemExit(1)
