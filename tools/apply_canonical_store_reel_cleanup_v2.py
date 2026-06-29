#!/usr/bin/env python3
from pathlib import Path

source_path = Path("tools/apply_canonical_store_reel_cleanup.py")
source = source_path.read_text()
source = source.replace(
    'migrate_pattern = r"\\nfunc migrate_legacy_bindings\\(\\) -> Dictionary:\\n.*?\\nfunc _duplicate_objects_by_id"',
    'migrate_pattern = r"\\nfunc migrate_legacy_bindings\\(source_format_version: int\\) -> Dictionary:\\n.*?\\nfunc validate_consistency"',
)
source = source.replace(
    're.subn(migrate_pattern, "\\nfunc _duplicate_objects_by_id", store, count=1, flags=re.S)',
    're.subn(migrate_pattern, "\\nfunc validate_consistency", store, count=1, flags=re.S)',
)
exec(compile(source, str(source_path), "exec"))
