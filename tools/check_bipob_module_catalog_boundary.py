#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTROLLER = ROOT / "scripts/bipob/bipob_controller.gd"
CATALOG = ROOT / "scripts/bipob/bipob_module_catalog.gd"
FACTORY = ROOT / "scripts/bipob/bipob_module_factory.gd"

errors: list[str] = []


def read(path: Path) -> str:
    if not path.exists():
        errors.append(f"missing required file: {path.relative_to(ROOT)}")
        return ""
    return path.read_text(encoding="utf-8")


controller = read(CONTROLLER)
catalog = read(CATALOG)
factory = read(FACTORY)

for token in (
    'preload("res://scripts/bipob/bipob_module_catalog.gd")',
    'preload("res://scripts/bipob/bipob_module_factory.gd")',
):
    if token not in controller:
        errors.append(f"BipobController missing dependency: {token}")

for forbidden, message in (
    ("const EXTERNAL_MODULE_CATALOG", "external catalog returned to BipobController"),
    ("var internal_specs: Array[Dictionary]", "internal module specs returned to BipobController"),
    ("BipobModule.new()", "BipobController constructs BipobModule directly"),
):
    if forbidden in controller:
        errors.append(message)

required_catalog_tokens = (
    "class_name BipobModuleCatalog",
    "const EXTERNAL_MODULES: Dictionary",
    "const INTERNAL_MODULE_SPECS: Array[Dictionary]",
    "const MODULE_ALIASES: Dictionary",
    "static func resolve_module_id",
    "static func validate_catalog",
)
for token in required_catalog_tokens:
    if token not in catalog:
        errors.append(f"catalog missing contract: {token}")

required_factory_tokens = (
    "class_name BipobModuleFactory",
    "static func create_external_module",
    "static func create_internal_module",
    "static func create_overlay_module",
    "BipobModuleRef.new()",
)
for token in required_factory_tokens:
    if token not in factory:
        errors.append(f"factory missing contract: {token}")

if re.search(r"\bBipobModule(?:Ref)?\.new\s*\(", catalog):
    errors.append("catalog must not construct runtime module instances")

for path in sorted((ROOT / "scripts/bipob").glob("*.gd")):
    if path == FACTORY:
        continue
    source = path.read_text(encoding="utf-8")
    if re.search(r"\bBipobModule(?:Ref)?\.new\s*\(", source):
        errors.append(f"direct BipobModule construction outside factory: {path.relative_to(ROOT)}")

if errors:
    print("Bipob module catalog boundary audit FAILED:")
    for error in errors:
        print(f" - {error}")
    raise SystemExit(1)

print("Bipob module catalog boundary audit OK")
