#!/usr/bin/env python3
from pathlib import Path
import re, sys
root = Path(__file__).resolve().parents[1]
errors = []
service = (root/'scripts/game/bipob_action_view_model_service.gd').read_text()
interaction = (root/'scripts/world/interaction_system.gd').read_text()
presenter = (root/'scripts/ui/runtime/runtime_interaction_presenter.gd').read_text()
targeting = (root/'scripts/game/bipob_targeting_service.gd').read_text()
checks = [
    ('service owns descriptor generation', 'class_name BipobActionViewModelService' in service and '_canonical_action_descriptor' in service),
    ('no second availability resolver', service.count('InteractionSystemRef.can_apply_action') == 1 and 'can_apply_action' not in presenter),
    ('canonical descriptor fields', all(f'"{k}"' in service for k in ['action_code','label_key','available','reason_code','requirements','target_id','context'])),
    ('legacy aliases retained', all(f'"{k}"' in service for k in ['id','label','enabled','reason'])),
    ('gate exposes machine fields', all(f'"{k}"' in interaction for k in ['success','reason_code','requirements','message','effects'])),
    ('presentation builder exists', 'build_runtime_presentation_snapshot' in service and 'target_object.duplicate(true)' in service),
    ('deterministic signature exists', 'signature' in service and 'var_to_str(unsigned)' in service),
    ('unsupported rows absent by section presence', 'if not sections.has(section_code):' in service),
    ('normal snapshot hides technical ids', 'event_id' in service and 'if debug_enabled' in service),
    ('task test exposes technical status', 'real_values' in service and 'forced_values' in service and 'section_code' in service),
    ('breach reason not parsed from message', 'message.find(' not in service and 'message.to_lower()' not in service and 'reason_code' in (root/'scripts/game/wall/breachable_wall_rules_service.gd').read_text()),
    ('targeting carries presentation snapshot', '"presentation_snapshot": Dictionary' in targeting),
    ('presenter uses canonical fields', 'descriptor.get("available"' in presenter and 'descriptor.get("reason_code"' in presenter),
    ('presenter common path does not read raw migrated state', all(x not in presenter for x in ['target_object.get("state"','target_object.get("power_state"','target_object.get("connected"'])),
    ('presenter uses snapshot signature', 'presentation_snapshot.get("signature"' in presenter),
    ('notification consumed without text classification', 'message.to_lower()' not in service and 'message.contains(' not in service),
]
for name, ok in checks:
    print(('PASS' if ok else 'FAIL') + ': ' + name)
    if not ok:
        errors.append(name)
if errors:
    print('\nRuntime entity presentation gate failed:')
    for e in errors:
        print(' - '+e)
    sys.exit(1)
