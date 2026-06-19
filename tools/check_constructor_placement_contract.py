#!/usr/bin/env python3
"""Static regression checks for constructor placement contract ownership."""
from pathlib import Path
import re
import sys

catalog = Path("scripts/world/world_object_catalog.gd").read_text()
mission = Path("scripts/game/mission_manager.gd").read_text()
issues = []

def require(condition, message):
    if not condition:
        issues.append(message)

require("static func get_constructor_placement_contract" in catalog, "WorldObjectCatalog is missing get_constructor_placement_contract().")
require("canonical_prefab_id(prefab_id)" in catalog, "Placement contract does not canonicalize aliases first.")
require('"placement_mode"' in catalog and '"mount"' in catalog and '"install_mode"' in catalog, "Placement contract source fields are missing.")
require("_schema_field_values" in catalog and "property_schema" in catalog, "Placement contract does not inspect property schemas.")
require("generic_power_role" in catalog and "cable_link" in catalog, "Placement contract does not preserve cable structural semantics.")

for token in ["MAP_CONSTRUCTOR_" + "WALL_MOUNTED_PREFABS", "wall_only_" + "prefabs", "floor_and_wall_" + "prefabs"]:
    require(token not in mission, f"MissionManager still references duplicated placement list {token}.")

require("get_constructor_placement_contract(normalized_prefab_id)" in mission, "can_place_map_constructor_prefab() does not consume the canonical contract.")
require('"prefab_does_not_support_wall_placement"' in mission, "Explicit wall placement rejection for non-wall prefabs is missing.")
require('row["supports_wall"]' in mission and 'row["supports_floor"]' in mission, "Constructor metadata does not normalize support flags from the contract.")
require('row["requires_wall"] = bool(placement_contract.get("wall_only", false))' in mission, "Constructor metadata requires_wall is not normalized from wall_only.")

firewall = re.search(r'"firewall"\s*:\s*\{(?P<body>.*?)\n\t"item"', catalog, re.S)
require(firewall is not None, "Firewall archetype is missing.")
if firewall:
    body = firewall.group("body")
    require('"placement_mode":"object"' in body, "Firewall is not an object/floor placement archetype.")
    require('"visual_surface":"floor"' in body, "Firewall is not configured as a floor visual.")
    require('"mount":"wall"' not in body and '"placement_mode":"wall_mounted"' not in body, "Firewall archetype is still wall-mounted.")

for prefab in ["light", "light_switcher", "external_air_duct", "external_water_pipe"]:
    pattern = rf'"{prefab}"\s*:\s*\{{(?P<body>.*?)(?:\n\t"[a-z0-9_]+"\s*:\s*\{{|\n\}})'
    match = re.search(pattern, catalog, re.S)
    require(match is not None, f"{prefab} definition is missing.")
    if match:
        body = match.group("body")
        require('"placement_mode":"wall_mounted"' in body or '"mount":"wall"' in body, f"{prefab} is not wall-only by canonical definition.")

for prefab in ["fuse_box", "power_socket", "power_switcher", "power_cable_reel"]:
    match = re.search(rf'"{prefab}"\s*:\s*\{{(?P<body>.*?)(?:\n\t"[a-z0-9_]+"\s*:\s*\{{|\n\}})', catalog, re.S)
    require(match is not None, f"{prefab} definition is missing.")
    if match:
        body = match.group("body")
        require('"field":"mount"' in body and '"floor"' in body and '"wall"' in body, f"{prefab} does not expose floor+wall mount schema.")

require('"power_cable"' in catalog and '"generic_power_role":"cable_link"' in catalog, "power_cable canonical structural cable semantics missing.")
require('"light_switch": "power_switcher"' in catalog, "light_switch alias no longer resolves to canonical power_switcher.")
require('"fuse_box_installed": "fuse_box"' in catalog, "fuse_box alias no longer resolves to canonical fuse_box.")

if issues:
    print("Constructor placement contract checks failed:")
    for issue in issues:
        print(f" - {issue}")
    sys.exit(1)
print("Constructor placement contract checks passed.")
