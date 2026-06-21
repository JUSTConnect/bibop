#!/usr/bin/env python3
from __future__ import annotations

import re
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


def function_body(source: str, name: str) -> str:
    match = re.search(rf"(?m)^static func {re.escape(name)}\s*\(", source)
    if match is None:
        errors.append(f"factory missing function: {name}")
        return ""
    following = re.search(r"(?m)^static func [A-Za-z0-9_]+\s*\(", source[match.end():])
    end = match.end() + following.start() if following is not None else len(source)
    return source[match.start():end]


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
    ("BipobModuleRef.new()", "BipobController constructs BipobModule directly"),
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
    "static func create_debug_found_module",
    "static func create_debug_field_component",
    "static func create_legacy_gpu_v1_module",
    "static func create_legacy_legs_v1_module",
)
for token in required_factory_tokens:
    if token not in factory:
        errors.append(f"factory missing contract: {token}")

if re.search(r"\bBipobModule(?:Ref)?\.new\s*\(", catalog):
    errors.append("catalog must not construct runtime module instances")

constructor_count = len(re.findall(r"\bBipobModuleRef\.new\s*\(", factory))
if constructor_count != 2:
    errors.append(
        "factory must construct BipobModule only in canonical external/internal hydration paths; "
        f"found {constructor_count} direct constructors"
    )

compatibility_paths = {
    "create_debug_found_module": 'create_internal_module("battery_v1")',
    "create_debug_field_component": 'create_internal_module("cooler_v1")',
    "create_legacy_gpu_v1_module": 'create_internal_module("gpu_v1")',
    "create_legacy_legs_v1_module": 'create_external_module("legs_v1")',
}
for function_name, required_call in compatibility_paths.items():
    body = function_body(factory, function_name)
    if required_call not in body:
        errors.append(f"{function_name} must delegate through {required_call}")
    if re.search(r"\bBipobModuleRef\.new\s*\(", body):
        errors.append(f"{function_name} bypasses canonical module hydration")

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
