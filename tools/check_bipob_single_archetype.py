#!/usr/bin/env python3
from pathlib import Path
import re

catalog = Path("scripts/world/world_object_catalog.gd").read_text()
validation = Path("scripts/game/map_constructor_validation_service.gd").read_text()
failures = []

def require(condition, message):
    if not condition:
        failures.append(message)

require('"bipob": {' in catalog and '"palette_label":"Bipob"' in catalog, "canonical bipob archetype missing")
for field in ["bipob_type", "bipob_status", "bipob_alignment", "chassis_type", "visor_type", "loadout_profile"]:
    require(f'"field":"{field}"' in catalog, f"bipob schema field missing: {field}")
require('const LEGACY_BIPOB_ALIAS_CONFIGS' in catalog, "legacy bipob alias table missing")
for alias in ["disabled_bipop_scout", "disabled_bipop_engineer", "disabled_bipop_juggernaut", "bipob_infected", "hostile_bipob", "bipob_heavy"]:
    require(f'"{alias}"' in catalog, f"legacy alias missing: {alias}")
require('LEGACY_BIPOB_ALIAS_CONFIGS.has(normalized_value)' in catalog, "legacy alias detector does not include bipob aliases")
require('normalize_bipob_config_fields' in catalog, "bipob normalization helper missing")
require('data["bipob_alignment"] = "hostile"' in catalog, "infected does not force hostile alignment")
require('data["map_constructor_prefab_id"] = "bipob"' in catalog, "normalization does not canonicalize map_constructor_prefab_id")
require('constructor_palette_requires_exactly_one_bipob' in validation, "palette validation does not require one bipob")
require('constructor_palette_bipob_entries_must_be_exactly_bipob' in validation, "palette validation does not enforce single bipob row")
require('bipob_archetype_missing_property_' in validation, "validation does not check bipob property schema")
if failures:
    for failure in failures:
        print(f"FAIL: {failure}")
    raise SystemExit(1)
print("OK: Bipob single archetype catalog checks passed")
