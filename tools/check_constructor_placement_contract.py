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
require("_schema_field_values" in catalog and "property_schema" in catalog, "Placement contract does not retain schema compatibility support.")
require('"placement_surfaces"' in catalog and '"default_placement_surface"' in catalog, "Explicit placement surface fields are missing from catalog definitions.")

for token in ["MAP_CONSTRUCTOR_" + "WALL_MOUNTED_PREFABS", "wall_only_" + "prefabs", "floor_and_wall_" + "prefabs"]:
    require(token not in mission, f"MissionManager still references duplicated placement list {token}.")

require("get_constructor_placement_contract(normalized_prefab_id)" in mission, "can_place_map_constructor_prefab() does not consume the canonical contract.")
require('"prefab_does_not_support_wall_placement"' in mission, "Explicit wall placement rejection for non-wall prefabs is missing.")
require('row["supports_wall"]' in mission and 'row["supports_floor"]' in mission, "Constructor metadata does not normalize support flags from the contract.")
require('row["requires_wall"] = bool(placement_contract.get("requires_wall", false))' in mission, "Constructor metadata requires_wall is not normalized from contract requires_wall.")

firewall = re.search(r'"firewall"\s*:\s*\{(?P<body>.*?)\n\t"item"', catalog, re.S)
require(firewall is not None, "Firewall archetype is missing.")
if firewall:
    body = firewall.group("body")
    require('"placement_mode":"object"' in body, "Firewall is not an object/floor placement archetype.")
    require('"placement_surfaces":["floor"]' in body, "Firewall lacks explicit floor-only placement surfaces.")
    require('"mount":"wall"' not in body and '"placement_mode":"wall_mounted"' not in body, "Firewall archetype is still wall-mounted.")

for prefab in ["light", "light_switcher", "external_air_duct", "external_water_pipe"]:
    pattern = rf'"{prefab}"\s*:\s*\{{(?P<body>.*?)(?:\n\t"[a-z0-9_]+"\s*:\s*\{{|\n\}})'
    match = re.search(pattern, catalog, re.S)
    require(match is not None, f"{prefab} definition is missing.")
    if match:
        body = match.group("body")
        require('"placement_surfaces":["wall"]' in body, f"{prefab} is not explicit wall-only by canonical definition.")

for prefab in ["fuse_box", "power_socket", "power_switcher", "power_cable_reel"]:
    match = re.search(rf'"{prefab}"\s*:\s*\{{(?P<body>.*?)(?:\n\t"[a-z0-9_]+"\s*:\s*\{{|\n\}})', catalog, re.S)
    require(match is not None, f"{prefab} definition is missing.")
    if match:
        body = match.group("body")
        require('"placement_surfaces":["floor", "wall"]' in body, f"{prefab} does not explicitly support floor+wall placement.")

require('"power_cable"' in catalog and '"placement_surfaces":["floor", "wall"]' in catalog, "power_cable explicit floor+wall placement semantics missing.")
require('"light_switch": "power_switcher"' in catalog, "light_switch alias no longer resolves to canonical power_switcher.")
require('"fuse_box_installed": "fuse_box"' in catalog, "fuse_box alias no longer resolves to canonical fuse_box.")

resolver_match = re.search(r"static func get_constructor_placement_contract\(prefab_id: String\).*?\nstatic func is_legacy_prefab_alias", catalog, re.S)
require(resolver_match is not None, "Placement resolver body not found.")
if resolver_match:
    resolver_body = resolver_match.group(0)
    require("visual_surface" not in resolver_body, "Placement resolver must not infer from visual_surface.")
    require("generic_power_role" not in resolver_body and "cable_link" not in resolver_body, "Placement resolver must not infer wall support from generic_power_role/cable_link.")
require('"missing_placement_contract"' in mission, "MissionManager missing fail-closed missing_placement_contract handling.")
require(Path("tools/ci/check_constructor_placement_contracts.gd").exists(), "Executable GDScript placement contract test is missing.")
require('placement_contract.get("supports_floor", true)' not in mission, "MissionManager still has permissive supports_floor fallback.")


if issues:
    print("Constructor placement contract checks failed:")
    for issue in issues:
        print(f" - {issue}")
    sys.exit(1)
print("Constructor placement contract checks passed.")
