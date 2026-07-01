#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
contract_path = root / "scripts/world/world_binding_store_contract.gd"
contract = contract_path.read_text() if contract_path.exists() else ""

checks = [
    ("BindingStore contract exists", contract_path.exists() and "class_name WorldBindingStoreContract" in contract),
    ("legacy door fields are listed", all(token in contract for token in ["linked_door_id", "linked_door_ids", "target_door_id"])),
    ("door migration helper exists", "_append_legacy_door_links" in contract),
    ("terminal door links migrate as control_terminal", "ROLE_CONTROL_TERMINAL" in contract and "linked_door_ids" in contract),
    ("item door links migrate as access_item", "ROLE_ACCESS_ITEM" in contract and "target_door_id" in contract),
]

failed = [name for name, ok in checks if not ok]
for name, ok in checks:
    print(("OK: " if ok else "FAIL: ") + name)
if failed:
    raise SystemExit(1)
