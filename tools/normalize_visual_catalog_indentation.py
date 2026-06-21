from pathlib import Path

path = Path(__file__).resolve().parents[1] / "scripts/visual/visual_asset_catalog.gd"
text = path.read_text(encoding="utf-8")

markers = [
    ("# Renderer-only presentation metadata for domain surface materials.", "# Visual state families are the primary resolver contract"),
    ("static func get_floor_material_presentation", "static func get_canonical_object_visual_ids"),
]

for start_marker, end_marker in reversed(markers):
    start = text.index(start_marker)
    end = text.index(end_marker, start)
    lines = text[start:end].splitlines(keepends=True)
    converted = []
    for line in lines:
        spaces = len(line) - len(line.lstrip(" "))
        if spaces and spaces % 4 == 0:
            line = "\t" * (spaces // 4) + line[spaces:]
        converted.append(line)
    text = text[:start] + "".join(converted) + text[end:]

path.write_text(text, encoding="utf-8")
print("Visual catalog indentation normalized")
