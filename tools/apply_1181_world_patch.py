#!/usr/bin/env python3
from pathlib import Path
import re

path = Path("scripts/world/world_object_catalog.gd")
text = path.read_text(encoding="utf-8")

preload = 'const StationaryPowerEntityCatalogRef = preload("res://scripts/world/stationary_power_entity_catalog.gd")'
if preload not in text:
    anchor = 'const PassiveRouteServiceRef = preload("res://scripts/game/routing/passive_route_service.gd")'
    text = text.replace(anchor, anchor + "\n" + preload, 1)

if "StationaryPowerEntityCatalogRef.is_alias(normalized_value)" not in text:
    text = text.replace(
        "return PREFAB_ALIASES.has(normalized_value)",
        "return StationaryPowerEntityCatalogRef.is_alias(normalized_value) or PREFAB_ALIASES.has(normalized_value)",
        1,
    )

canonical_anchor = "static func canonical_prefab_id(prefab_id: String) -> String:\n\tvar normalized_type: String = prefab_id.strip_edges().to_lower()\n"
canonical_block_start = text.find("static func canonical_prefab_id")
canonical_block_end = text.find("\nstatic func ", canonical_block_start + 1)
if "StationaryPowerEntityCatalogRef.is_alias(normalized_type)" not in text[canonical_block_start:canonical_block_end]:
    text = text.replace(
        canonical_anchor,
        canonical_anchor + "\tif StationaryPowerEntityCatalogRef.is_alias(normalized_type):\n\t\treturn StationaryPowerEntityCatalogRef.canonical_id(normalized_type)\n",
        1,
    )

defaults_start = text.find("static func get_prefab_alias_defaults(")
defaults_end = text.find("\nstatic func ", defaults_start + 1)
defaults_block = text[defaults_start:defaults_end]
if "StationaryPowerEntityCatalogRef.alias_defaults" not in defaults_block:
    line_match = re.search(r"\n\tvar normalized[^\n]*\n", defaults_block)
    if line_match is None:
        raise SystemExit("normalized alias-default line not found")
    variable_match = re.search(r"var (normalized\w*):", line_match.group(0))
    variable_name = variable_match.group(1) if variable_match else "normalized_prefab_id"
    addition = (
        f"\tvar stationary_defaults: Dictionary = StationaryPowerEntityCatalogRef.alias_defaults({variable_name})\n"
        "\tif not stationary_defaults.is_empty():\n"
        "\t\treturn stationary_defaults\n"
    )
    insert_at = defaults_start + line_match.end()
    text = text[:insert_at] + addition + text[insert_at:]

constructor_anchor = "static func _get_constructor_prefab_definition(canonical_id: String) -> Dictionary:\n"
constructor_start = text.find(constructor_anchor)
constructor_end = text.find("\nstatic func ", constructor_start + 1)
if "StationaryPowerEntityCatalogRef.definition(canonical_id)" not in text[constructor_start:constructor_end]:
    addition = (
        "\tvar stationary_definition: Dictionary = StationaryPowerEntityCatalogRef.definition(canonical_id)\n"
        "\tif not stationary_definition.is_empty():\n"
        "\t\treturn stationary_definition\n"
    )
    text = text.replace(constructor_anchor, constructor_anchor + addition, 1)

archetype_start = text.find("static func get_archetype_definition(")
archetype_end = text.find("\nstatic func ", archetype_start + 1)
if "StationaryPowerEntityCatalogRef.definition" not in text[archetype_start:archetype_end]:
    replacement = """static func get_archetype_definition(archetype_id: String) -> Dictionary:
	var canonical_id: String = canonical_prefab_id(_normalized_contract_token(archetype_id))
	var stationary_definition: Dictionary = StationaryPowerEntityCatalogRef.definition(canonical_id)
	if not stationary_definition.is_empty():
		return stationary_definition
	var definition: Variant = ARCHETYPE_REGISTRY.get(canonical_id, {})
	return definition.duplicate(true) if definition is Dictionary else {}
"""
    text = text[:archetype_start] + replacement + text[archetype_end + 1:]

id_start = text.find("static func get_archetype_id_for_object(")
id_end = text.find("\nstatic func ", id_start + 1)
id_block = text[id_start:id_end]
if "canonical_explicit_id" not in id_block:
    needle = '\tvar explicit_id: String = _normalized_contract_token(object_data.get("archetype_id", ""))\n'
    addition = needle + "\tvar canonical_explicit_id: String = canonical_prefab_id(explicit_id)\n\tif StationaryPowerEntityCatalogRef.is_family(canonical_explicit_id):\n\t\treturn canonical_explicit_id\n"
    text = text[:id_start] + id_block.replace(needle, addition, 1) + text[id_end:]

create_start = text.find("static func create_world_object(")
create_end = text.find("\nstatic func ", create_start + 1)
create_block = text[create_start:create_end]
if "var stationary_id:" not in create_block:
    needle = "\tvar normalized_type: String = _normalized_contract_token(object_type)\n"
    addition = (
        needle
        + "\tvar stationary_id: String = StationaryPowerEntityCatalogRef.canonical_id(normalized_type)\n"
        + "\tif StationaryPowerEntityCatalogRef.is_family(stationary_id):\n"
        + "\t\tvar stationary_object: Dictionary = create_archetype_object(stationary_id, id_override, get_prefab_alias_defaults(normalized_type))\n"
        + "\t\treturn mark_legacy_source(stationary_object, normalized_type) if StationaryPowerEntityCatalogRef.is_alias(normalized_type) else stationary_object\n"
    )
    text = text[:create_start] + create_block.replace(needle, addition, 1) + text[create_end:]

create_arch_start = text.find("static func create_archetype_object(")
create_arch_end = text.find("\nstatic func ", create_arch_start + 1)
create_arch_block = text[create_arch_start:create_arch_end]
if "StationaryPowerEntityCatalogRef.normalize_new_record" not in create_arch_block:
    old_return = "\treturn normalize_door_state_fields(normalize_world_object_contract(normalize_archetype_object(data)))"
    new_return = "\tvar normalized: Dictionary = normalize_door_state_fields(normalize_world_object_contract(normalize_archetype_object(data)))\n\treturn StationaryPowerEntityCatalogRef.normalize_new_record(normalized, archetype_id)"
    create_arch_block = create_arch_block.replace(old_return, new_return, 1)
    text = text[:create_arch_start] + create_arch_block + text[create_arch_end:]

if "static func adapt_legacy_stationary_power_record(" not in text:
    anchor = "static func normalize_world_object_contract(object_data: Dictionary) -> Dictionary:"
    facade = "static func adapt_legacy_stationary_power_record(object_data: Dictionary) -> Dictionary:\n\treturn StationaryPowerEntityCatalogRef.adapt_legacy_read_only(object_data)\n\n\n"
    text = text.replace(anchor, facade + anchor, 1)

text = re.sub(r'\n\t\t"legacy_semantic_exceptions":\[[^\n]*"migration_issue":1181[^\n]*\],', "", text)

required = [
    preload,
    "adapt_legacy_stationary_power_record",
    "normalize_new_record(normalized, archetype_id)",
    "var stationary_id:",
    "StationaryPowerEntityCatalogRef.definition(canonical_id)",
]
missing = [token for token in required if token not in text]
if missing:
    raise SystemExit("world catalog patch incomplete: " + ", ".join(missing))

path.write_text(text, encoding="utf-8")
print("WORLD_CATALOG_1181_PATCH: OK")
