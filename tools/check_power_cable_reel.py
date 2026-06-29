#!/usr/bin/env python3
from pathlib import Path
root=Path(__file__).resolve().parents[1]
text=(root/'scripts/world/world_object_catalog.gd').read_text()
errors=[]
block=text
for token in ['"entity_type":"item"','"entity_subtype":"power_cable_reel"','"max_cable_length":5','"end_1_state"','"end_2_state"','"cable_install_mode"']:
 if token not in block: errors.append(f'power_cable_reel missing {token}')
mission=(root/'scripts/game/mission_manager.gd').read_text()
for token in ['_normalize_power_cable_reel_state','validate_power_cable_reel_normalization']:
 if token not in mission: errors.append(f'MissionManager missing {token}')
if errors:
 print('Power cable reel gate failed:')
 for e in errors: print('-',e)
 raise SystemExit(1)
print('OK: power cable reel contract holds')
