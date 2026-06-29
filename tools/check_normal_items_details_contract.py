#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
service = (root / "scripts/game/inventory/details_currency_service.gd").read_text()
normal = (root / "scripts/game/inventory/normal_item_contract.gd").read_text()
mission = (root / "scripts/game/mission_manager.gd").read_text()
catalog = (root / "scripts/world/world_object_catalog.gd").read_text()
center = (root / "scripts/game/center_storage_service.gd").read_text()
workflow = (root / ".github/workflows/normal-items-details-contract-gate.yml").read_text()

codes = [
    "received",
    "spent",
    "duplicate_reward",
    "duplicate_transaction",
    "invalid_amount",
    "insufficient",
    "migrated",
]
api_methods = [
    "get_details_balance(",
    "get_details_currency_snapshot(",
    "replace_details_currency_snapshot(",
    "receive_details_reward(",
    "spend_details(",
    "migrate_legacy_parts_state(",
]
checks = [
    ("Details service", "class_name DetailsCurrencyService" in service),
    ("normal item contract", "class_name NormalItemContract" in normal),
    ("single Details owner", "var details_currency_service = DetailsCurrencyServiceRef.new()" in mission and "var _balance: int" in service),
    ("stable codes", all(f'"{code}"' in service for code in codes)),
    ("idempotent IDs", "processed_reward_ids" in service and "processed_transaction_ids" in service),
    ("MissionManager API", all(method in mission for method in api_methods)),
    ("currency serialized separately", 'snapshot["details_currency"]' in mission and 'snapshot.erase("item_amounts")' in mission),
    ("no canonical item_amounts", '"item_amounts": {}' not in mission),
    ("pickup bypasses inventory", '"storage": "details_balance"' in mission),
    ("normal items canonicalized", "NormalItemContractRef.canonicalize" in mission),
    ("consume after success", "NormalItemContractRef.apply_consumption" in mission),
    ("amount forbidden on normal item", "FORBIDDEN_STACK_FIELDS" in normal and "CODE_AMOUNT_FORBIDDEN" in normal),
    ("separate Details contract", '"entity_subtype":"details_pickup"' in catalog and '"currency_id":"details"' in catalog),
    ("normal item excludes parts", '"values":["fuse", "reinforcement", "repair_kit"]' in catalog),
    ("Details has no slot", '"storage_type":"none"' in catalog and '"object_type":"details_pickup"' in catalog),
    ("legacy aliases", all(f'"{name}": "details_pickup"' in catalog for name in ["parts", "parts_small", "parts_medium", "parts_large"])),
    ("center has no canonical parts", "STORAGE_PARTS: 0" not in center and "extract_legacy_details_amount" in center),
    ("static gate wired", "python tools/check_normal_items_details_contract.py" in workflow),
    ("behavior gate wired", "check_normal_items_details.gd" in workflow),
    ("integration gate wired", "check_normal_items_details_mission_manager.gd" in workflow),
]

failed = [name for name, ok in checks if not ok]
for name, ok in checks:
    print(("OK: " if ok else "FAIL: ") + name)
if failed:
    raise SystemExit(1)
