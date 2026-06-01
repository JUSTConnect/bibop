#!/usr/bin/env python3
"""Check the Map Constructor validation string-safety regression contract."""

from pathlib import Path
import sys


SERVICE_PATH = Path("scripts/game/map_constructor_validation_service.gd")
CATALOG_PATH = Path("scripts/world/world_object_catalog.gd")


def fail(message: str) -> int:
    print(f"FAIL: {message}")
    return 1


def require(source: str, fragment: str, description: str) -> str | None:
    if fragment not in source:
        return f"missing {description}: {fragment}"
    return None


def main() -> int:
    service_source = SERVICE_PATH.read_text(encoding="utf-8")
    catalog_source = CATALOG_PATH.read_text(encoding="utf-8")
    issues: list[str] = []

    if "String(" in service_source:
        issues.append("validation service still contains unsafe String(value) constructor calls")

    service_requirements = [
        ('func _safe_string(value: Variant, fallback: String = "") -> String:', "local safe string helper"),
        ("return str(value).strip_edges()", "safe str(value) conversion"),
        ("func get_map_constructor_validation_issues() -> Array[Dictionary]:", "validation issue entrypoint"),
        ('"obj_invalid_access_type_%s"', "non-canonical access_type validation issue"),
        ('"obj_invalid_door_type_%s"', "legacy/non-canonical door_type validation issue"),
        ("WorldObjectCatalogRef.ACCESS_TYPE_KEY_CARD", "canonical key_card link validation"),
        ("WorldObjectCatalogRef.ACCESS_TYPE_DIGITAL_KEY", "canonical digital_key link validation"),
        ("WorldObjectCatalogRef.ACCESS_TYPE_ACCESS_CODE", "canonical access_code link validation"),
        ("WorldObjectCatalogRef.ACCESS_TYPE_TERMINAL", "canonical terminal link validation"),
    ]
    catalog_requirements = [
        ('const ACCESS_TYPE_KEY_CARD := "key_card"', "key_card catalog access type"),
        ('const ACCESS_TYPE_DIGITAL_KEY := "digital_key"', "digital_key catalog access type"),
        ('const ACCESS_TYPE_ACCESS_CODE := "access_code"', "access_code catalog access type"),
        ('"digital", "digital_key":', "digital_key normalization branch"),
        ('"password", "code", "access_code":', "access_code normalization branch"),
    ]
    for fragment, description in service_requirements:
        issue = require(service_source, fragment, description)
        if issue is not None:
            issues.append(issue)
    for fragment, description in catalog_requirements:
        issue = require(catalog_source, fragment, description)
        if issue is not None:
            issues.append(issue)

    if issues:
        for issue in issues:
            print(f"FAIL: {issue}")
        return 1
    print("OK: Map Constructor validation uses safe string conversion and canonical digital access tokens.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
