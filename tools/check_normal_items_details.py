#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
service_path = root / "scripts/game/inventory/details_currency_service.gd"
normal_path = root / "scripts/game/inventory/normal_item_contract.gd"
mission_path = root / "scripts/game/mission_manager.gd"
catalog_path = root / "scripts/world/world_object_catalog.gd"
center_path = root / "scripts/game/center_storage_service.gd"
workflow_path = root / ".github/workflows/godot-parser-gate.yml"

service = service_path.read_text() if service_path.exists() else ""
normal = normal_path.read_text() if normal_path.exists() else ""
mission = mission_path.read_text() if mission_path.exists() else ""
catalog = catalog_path.read_text() if catalog_path.exists() else ""
center = center_path.read_text() if center_path.exists() else ""
workflow = workflow_path.read_text() if workflow_path.exists() else ""

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
    ("Details service exists", service_path.exists() and "class_name DetailsCurrencyService" in service),
    ("normal item contract exists", normal_path.exists() and "class_name NormalItemContract" in normal),
    ("one stateful Details owner", "var details_currency_service = DetailsCurrencyServiceRef.new()" in mission and "var _balance: int" in service),
    ("stable currency codes declared", all(f'"{code}"' in service for code in codes)),
    ("reward and transaction IDs persisted", "processed_reward_ids" in service and "processed_transaction_ids" in service),
    ("MissionManager exposes currency API", all(method in mission for method in api_methods)),
    ("Details serialized outside inventory", 'snapshot["details_currency"]' in mission and 'snapshot.erase("item_amounts")' in mission),
    ("legacy item_amounts is not canonical", '"item_amounts": {}' not in mission),
    ("Details pickup bypasses inventory", '"storage": "details_balance"' in mission and 'DetailsCurrencyServiceRef.is_details_entry' in mission),
    ("normal items canonicalized", "NormalItemContractRef.canonicalize" in mission),
    ("consumption follows successful action", "NormalItemContractRef.apply_consumption" in mission),
    ("normal item amount forbidden", 'FORBIDDEN_STACK_FIELDS' in normal and 'CODE_AMOUNT_FORBIDDEN' in normal),
    ("catalog has separate Details contract", '"entity_subtype":"details_pickup"' in catalog and '"currency_id":"details"' in catalog),
    ("normal physical item excludes parts", '"values":["fuse", "reinforcement", "repair_kit"]' in catalog),
    ("Details has no inventory storage", '"storage_type":"none"' in catalog and '"object_type":"details_pickup"' in catalog),
    ("legacy aliases migrate to Details", all(f'"{name}": "details_pickup"' in catalog for name in ["parts", "parts_small", "parts_medium", "parts_large"])),
    ("center storage has no canonical parts balance", 'STORAGE_PARTS: 0' not in center and "extract_legacy_details_amount" in center),
    ("static gate wired", "python tools/check_normal_items_details.py" in workflow),
    ("behavior gate wired", "check_normal_items_details.gd" in workflow),
    ("MissionManager gate wired", "check_normal_items_details_mission_manager.gd" in workflow),
]

failed = [name for name, ok in checks if not ok]
for name, ok in checks:
    print(("OK: " if ok else "FAIL: ") + name)
if failed:
    raise SystemExit(1)
