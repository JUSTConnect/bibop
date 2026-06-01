# Final Runtime Contract Audit

## Audit basis and scope

This report audits the current repository code against `docs/bipob_architecture_stabilization_plan.md`. It does **not** use pull-request descriptions as implementation evidence. The historical notes in `docs/bipob_architecture_stabilization_followup_audit.md` were read only to identify previously known risks and were re-checked against the current code.

Status meanings:

- **DONE** — the current static code path implements and validates the contract.
- **PARTIAL** — some contract pieces exist, but the full planned contract is not implemented or not enforced end-to-end.
- **OPEN** — a verified gap remains.
- **NEEDS RUNTIME SMOKE** — the static code path exists, but runtime behavior must still be exercised manually before it can be called complete.

No gameplay rewrite was made during this audit. No validation was weakened. No `project.godot` or `.tscn` file was changed.

## Exact checklist from the stabilization plan

The final verification checklist below is reproduced from section 7.2 of `docs/bipob_architecture_stabilization_plan.md`:

```text
- object registry validation
- constructor prefab validation
- TASK TEST object validation
- door contract validation
- inventory contract validation
- runtime action validation
- mission goal binding validation
- validation read-only/snapshot-restore validation
```

The final readiness checklist below is reproduced from section 7.4 of the plan:

```text
- нет parser errors
- нет endless output errors
- TASK TEST не зависает
- все object/prefab aliases нормализуются
- двери работают через один contract
- key-card работает через keychain
- physical/digital storage separation enforced
- UI отображает backend state, а не placeholder truth
- validation ловит возврат legacy divergence
```

Current static coverage of the section 7.2 checklist:

| Plan checklist item | Status | Current code evidence | Audit note |
| --- | --- | --- | --- |
| object registry validation | DONE | `WorldObjectCatalog.validate_object_registry_contract()`; `MissionManager._build_final_object_registry_section()` | The catalog validates Door aliases and palette exposure. The final report rejects unknown runtime `object_type` and leaked legacy aliases. |
| constructor prefab validation | DONE | `MapConstructorValidationService.validate_constructor_palette_contract()`; `MapConstructorValidationService.get_map_constructor_validation_issues()` | Palette rows are regenerated from the catalog and checked against catalog-creatable objects. Raw `OBJECT_LIBRARY` item rows are rejected if exposed directly. |
| TASK TEST object validation | DONE | `MissionManager._validate_task_test_object_contracts()`; `MissionManager.build_task_test_mission_world_objects_for_validation()` | TASK TEST validation builds a detached snapshot from catalog constructors and validates Door/item fields without mutating active state. Gameplay still needs smoke testing. |
| door contract validation | PARTIAL | `WorldObjectCatalog.validate_archetype_object()`; `MissionManager._validate_current_door_contracts()`; `MissionManager._build_final_door_contract_section()` | Canonical fields, generated labels, state flags, aliases, invalid access types, and `no_key` drift are checked. Explicit runtime semantics for the declared `requires_power_to_open` mode remain incomplete. |
| inventory contract validation | PARTIAL | `MissionManager.validate_runtime_inventory_storage_contract()`; `MissionManager._validate_runtime_inventory_storage_item()` | Storage-class mismatches and duplicate storage are checked. The backend uses singular `manipulator_hold`, `pocket_items`, and `collected_key_ids` rather than the planned slot-named state model. |
| runtime action validation | NEEDS RUNTIME SMOKE | `BipobController.build_runtime_action_view_model()`; `InteractionSystem.can_apply_action()`; `MissionManager._validate_runtime_action_view_model_section()` | Static action truth flows from normalized targets. Pulse clearing and post-action refresh must be exercised manually. |
| mission goal binding validation | DONE | `MissionManager.get_current_mission_objective_view_model()`; `MissionManager._build_final_mission_goal_binding_section()`; `GameUI._get_runtime_mission_objective_text()` | The GOAL panel reads the active mission ViewModel/catalog objective. No TASK TEST placeholder string was found by the required search. |
| validation read-only/snapshot-restore validation | DONE | `MissionManager._build_final_validation_read_only_section()` | The validator snapshots `mission_world_objects` and `runtime_inventory_state`, runs architecture validation, then detects mutation. The required mutation search found no writes in `map_constructor_validation_service.gd`. |

## Summary table

| Plan section | Status | Code evidence | Remaining work |
| --- | --- | --- | --- |
| Door contract | NEEDS RUNTIME SMOKE | `WorldObjectCatalog.ARCHETYPE_REGISTRY["door"]`, `normalize_door_contract()`, `normalize_door_state_fields()`, `generate_display_name()`, `InteractionSystem._normalize_runtime_door_data()`, `MissionManager.update_power_door_state_from_is_powered()` | Smoke mechanical, key-card, digital, terminal, and powered Door variants. Add an explicit fix-only decision and runtime branch for declared `requires_power_to_open`. |
| Key-card contract | NEEDS RUNTIME SMOKE | `WorldObjectCatalog.LEGACY_ITEM_ALIAS_CONFIGS`, `normalize_item_contract()`, `get_item_storage_class()`, `MissionManager.pickup_world_item()`, `add_keycard_to_keychain()`, `set_manipulator_item()`, `set_pocket_item()` | Smoke pickup, key indicator, free-manipulator Door gating, and absence from manipulator/pockets. |
| Inventory storage contract | PARTIAL | `MissionManager.get_inventory_state()`, `validate_runtime_inventory_storage_contract()`, `RuntimeStoragePanel.refresh()` | Backend zones exist, but planned names/shapes are not fully realized: singular `manipulator_hold`, `pocket_items`, `collected_key_ids`, `digital_buffer`, and `digital_storage` are exposed. UI uses fixed/minimum visible cells in places. |
| Map Constructor catalog contract | DONE | `WorldObjectCatalog.get_constructor_palette_rows()`, `MapConstructorValidationService.validate_constructor_palette_contract()`, `MapConstructorValidationService.get_map_constructor_validation_issues()` | Runtime palette visual smoke remains required. |
| Placement normalization | DONE | `MapConstructorService.place_map_constructor_prefab()`, `WorldObjectCatalog.create_world_object()`, `create_archetype_object()`, `MissionManager.add_item_at_cell()` | Smoke placed Door/item behavior and save/load restoration. |
| TASK TEST alignment | NEEDS RUNTIME SMOKE | `MissionManager.build_task_test_mission_world_objects_for_validation()`, `_validate_task_test_object_contracts()`, `_build_final_validation_read_only_section()` | Static creation uses catalog constructors; run the full TASK TEST smoke list. |
| Runtime action contract | NEEDS RUNTIME SMOKE | `BipobController.build_runtime_action_view_model()`, `get_available_world_actions()`, `clear_selected_world_action_if_invalid()`, `RuntimeInteractionPanel.get_target_data()`, `refresh_controls()` | Verify empty-cell behavior and stale action pulse clearing after pickup/action/move/turn. |
| HUD / GOAL binding | PARTIAL | `MissionManager.get_current_mission_objective_view_model()`, `GameUI._get_runtime_mission_objective_view_model()`, `_get_runtime_mission_objective_text()`, `RuntimeStoragePanel.refresh()` | GOAL binding is implemented. Inventory HUD still needs visual/runtime verification, and `GameUI` still contains one Russian-facing `"Ремонт"` label. |
| Validation gate | PARTIAL | `MissionManager.validate_architecture_contracts()`, `build_architecture_stabilization_final_report()`, `WorldObjectCatalog.validate_archetype_object()`, `MapConstructorValidationService.get_map_constructor_validation_issues()` | Broad checks exist. Add focused fix-only coverage for the `requires_power_to_open` decision and strengthen UI checks if the UI storage model is normalized later. |
| Legacy compatibility boundary | PARTIAL | `WorldObjectCatalog.LEGACY_DOOR_ALIAS_CONFIGS`, `LEGACY_ITEM_ALIAS_CONFIGS`, `canonicalize_legacy_object_data()`, `MissionManager._validate_legacy_compatibility_boundary()` | Catalog/runtime Door and item inputs normalize correctly. Legacy names still appear in compatibility, visuals, debug labels, and older command vocabulary; review each remaining occurrence before cleanup. |
| Parser/CI gate | DONE | `.github/workflows/godot-parser-gate.yml` | Workflow is mandatory on `pull_request` and pushes to `main`; local diff/Python checks pass in this audit. The local container does not provide the `godot` executable, so the Godot import/parser commands remain CI/environment verification items. |

## Findings

### F-01 — Canonical Door archetype is implemented

- **Severity:** low
- **Status:** done
- **Evidence:** `WorldObjectCatalog.ARCHETYPE_REGISTRY["door"]` fixes `archetype_id=door`, `object_group=door`, and `object_type=door`. Its schema carries `door_type`, `material`, `access_type`, `door_class`, `power_type`, `control_type`, `power_behavior`, `state`, and `allowed_states`. `normalize_door_contract()` and `normalize_door_state_fields()` canonicalize runtime state. `generate_display_name()` derives the Door label from properties. `LEGACY_DOOR_ALIAS_CONFIGS` retains material/type names only as hidden compatibility mappings.
- **Required follow-up PR:** none for the canonical static shape; runtime smoke remains mandatory.

### F-02 — Declared powered-Door behavior is broader than explicit runtime handling

- **Severity:** high
- **Status:** partial
- **Evidence:** the catalog declares `none`, `opens_when_unpowered`, and `requires_power_to_open` in `WorldObjectCatalog.POWER_BEHAVIORS` and the Door schema. `MissionManager.update_power_door_state_from_is_powered()` contains a clear explicit branch for `opens_when_unpowered` and general unpowered-state handling, while repository search finds no explicit runtime reference to `POWER_BEHAVIOR_REQUIRES_POWER_TO_OPEN` outside its declaration/schema. Current Door validators also explicitly accept only `none` and `opens_when_unpowered` for powered Doors.
- **Required follow-up PR:** add a narrow powered-Door contract PR that decides whether `requires_power_to_open` is supported. If supported, add an explicit runtime branch and validation coverage; if not supported, remove it from the schema/constants. Do not silently widen validation before runtime semantics are defined.

### F-03 — Key Card is canonical and routes to keychain

- **Severity:** low
- **Status:** done
- **Evidence:** `LEGACY_ITEM_ALIAS_CONFIGS` maps `mechanical_key`, `mechanical_keycard`, `keycard`, and `key_card` to canonical `item_class=key_card`. `normalize_item_contract()` writes `storage_route=keychain` and `storage_type=keychain`. `MissionManager.pickup_world_item()` routes key-card items to `add_keycard_to_keychain()` rather than the manipulator. `set_manipulator_item()` and `set_pocket_item()` reject key-card and digital storage classes.
- **Required follow-up PR:** none for static routing; perform runtime smoke.

### F-04 — Digital and physical storage separation exists, but the planned storage model is not fully represented

- **Severity:** medium
- **Status:** partial
- **Evidence:** `MissionManager.get_inventory_state()` exposes `manipulator_hold`, `pocket_items`, `collected_key_ids`, `digital_buffer`, and `digital_storage`. `validate_runtime_inventory_storage_contract()` enforces storage classes across those zones. `RuntimeStoragePanel.refresh()` reads backend state. However, the plan names `manipulator_slots`, `pocket_slots`, and `keychain`; the backend uses a singular physical hold, a pocket array, and `collected_key_ids`. This is a real backend separation, but not the exact planned generalized slot model.
- **Required follow-up PR:** if multi-manipulator inventory is required by the MVP, add a narrowly scoped inventory-state normalization PR. Otherwise, document the singular-manipulator MVP contract and align validation/UI terminology without broad rewrites.

### F-05 — Map Constructor palette is catalog-backed and raw item rows are hidden

- **Severity:** low
- **Status:** done
- **Evidence:** `WorldObjectCatalog.get_constructor_palette_rows()` emits every `ARCHETYPE_REGISTRY` row and skips raw `OBJECT_LIBRARY` rows whose group is `door`, `terminal`, or `item`. `MapConstructorValidationService.validate_constructor_palette_contract()` requires one Door, Floor, External Wall, Wall, Terminal, and Item row. `get_map_constructor_validation_issues()` rejects exposed raw item rows and palette entries that create unknown runtime types.
- **Required follow-up PR:** none statically; perform palette smoke.

### F-06 — Utility items are dedicated archetypes

- **Severity:** low
- **Status:** done
- **Evidence:** `WorldObjectCatalog.UTILITY_ITEM_ARCHETYPE_IDS` lists `power_cable_reel`, `fuse`, `repair_kit`, `reinforcement`, `module_external`, and `module_internal`. Each has an archetype registry entry, and `validate_archetype_object()` checks utility runtime compatibility and special Fuse/Cable fields.
- **Required follow-up PR:** smoke Fuse, Repair Kit, cable reel, reinforcement, and module placement/pickup paths used by the MVP.

### F-07 — Placement normalizes before runtime storage

- **Severity:** low
- **Status:** done
- **Evidence:** `MapConstructorService.place_map_constructor_prefab()` checks placement, creates through `WorldObjectCatalog.create_world_object()`, rejects empty/unknown item construction, normalizes items before `MissionManager.add_item_at_cell()`, and normalizes world objects before insertion. `MissionManager.add_item_at_cell()` normalizes items again before writing `cell_items` and syncing `mission_world_objects`.
- **Required follow-up PR:** none statically; smoke placed objects and save/load.

### F-08 — TASK TEST builds detached canonical validation data

- **Severity:** medium
- **Status:** done
- **Evidence:** `MissionManager.build_task_test_mission_world_objects_for_validation()` creates TASK TEST Doors/items through `WorldObjectCatalog.create_world_object()` and normalizes them before returning detached `objects` and `items_by_cell`. `_validate_task_test_object_contracts()` validates that detached snapshot. `_build_final_validation_read_only_section()` snapshots active world/inventory state around architecture validation and reports mutation.
- **Required follow-up PR:** none for the static build path; run the TASK TEST runtime smoke checklist.

### F-09 — Runtime actions use normalized target truth; pulse lifecycle still needs smoke

- **Severity:** medium
- **Status:** partial
- **Evidence:** `BipobController.build_runtime_action_view_model()` normalizes the target, then calls `get_available_world_actions()` and `InteractionSystem.can_apply_action()`. `RuntimeInteractionPanel.get_target_data()` delegates to `BipobController.get_facing_world_action_target()` rather than owning separate action truth. `clear_selected_world_action_if_invalid()` is called after movement and relevant interactions, while `RuntimeInteractionPanel.refresh_controls()` clears UI pulse when there is no interactable target. Static inspection cannot prove every post-action visual transition.
- **Required follow-up PR:** only if smoke reproduces stale pulse; keep any fix scoped to selection refresh/clearing.

### F-10 — GOAL binds to mission objective data; inventory HUD is not fully proven

- **Severity:** medium
- **Status:** partial
- **Evidence:** `MissionManager.get_current_mission_objective_view_model()` reads catalog goal/hint data. `GameUI._get_runtime_mission_objective_view_model()` delegates to MissionManager and `_get_runtime_mission_objective_text()` renders that ViewModel. The required placeholder search did not find `Use this mission to validate`. `RuntimeStoragePanel.refresh()` reads backend inventory state. Manual visual verification is still required for slot/key/digital presentation.
- **Required follow-up PR:** smoke GOAL and storage HUD. Add only targeted binding fixes if a mismatch is reproduced.

### F-11 — One Russian-facing UI label remains

- **Severity:** medium
- **Status:** open
- **Evidence:** the required Cyrillic search finds one game UI occurrence: `scripts/ui/game_ui.gd` contains `_create_menu_button("Ремонт", ...)`. This violates the English-only game-facing label contract.
- **Required follow-up PR:** replace the label with the correct English UI label in a focused English-only cleanup PR and rerun the Cyrillic search.

### F-12 — Validation is broad but should not be overstated

- **Severity:** medium
- **Status:** partial
- **Evidence:** current validation catches catalog alias drift, legacy Door runtime types, constructor palette divergence, raw item rows, unknown constructor-created runtime types, invalid Door enums, missing Door fields, `no_key` key drift, generated-name drift, storage-class mismatches, active mission objective binding drift, backend manipulator count mismatch, and validation mutation. It does not prove runtime visual behavior. UI widget-count validation is indirect rather than a complete widget-to-backend audit.
- **Required follow-up PR:** after runtime smoke, add only focused regression checks for reproduced issues.

### F-13 — Parser/CI gate is mandatory and complete

- **Severity:** low
- **Status:** done
- **Evidence:** `.github/workflows/godot-parser-gate.yml` runs on `pull_request` and pushes to `main`. It executes `git diff --check`, `python tools/check_gdscript_safety_patterns.py`, `python tools/check_map_constructor_sections.py`, `godot --headless --path . --import`, and `godot --headless --path . --script res://tools/ci/parse_all_gd.gd`.
- **Required follow-up PR:** none.

## Section-by-section contract audit

### A. Door contract — NEEDS RUNTIME SMOKE

Static result:

- Legacy Door ids such as `steel_door`, `reinforced_steel_door`, `titanium_door`, `energy_door`, `mechanical_door`, `digital_door`, and `powered_gate` are compatibility mappings in `LEGACY_DOOR_ALIAS_CONFIGS`; legacy library rows are hidden from constructor placement.
- Canonical Door creation uses `archetype_id=door`, `object_group=door`, and `object_type=door`.
- Door variation lives in the planned fields: `door_type`, `material`, `access_type`, `door_class`, `power_type`, `control_type`, `power_behavior`, `state`, and `allowed_states`.
- `normalize_door_contract()` and `normalize_door_state_fields()` clear `required_key_id` and locked state for `no_key` Doors.
- `generate_display_name()` generates property-derived Door names.
- Runtime action code normalizes Door data and dispatches by Door group/properties rather than treating `steel_door` as canonical gameplay truth.
- Powered Door updates have an explicit `opens_when_unpowered` path. The declared `requires_power_to_open` mode still needs a focused contract decision/fix.

### B. Key-card / item contract — NEEDS RUNTIME SMOKE

Static result:

- `key_card` is canonical.
- `mechanical_key`, `mechanical_keycard`, `keycard`, and `key_card` are compatibility inputs that normalize to canonical Key Card data.
- Key Card routes to keychain and is rejected by manipulator/pocket setters.
- `digital_key`, `access_code`, and `data_file` normalize to digital storage routing; runtime pickup places digital-class items into the active digital buffer.
- Physical items are rejected by `can_place_item_in_digital_buffer()`.
- Dedicated utility archetypes preserve Fuse/Cable/Repair/Reinforcement/Module runtime-compatible fields.

### C. Inventory storage contract — PARTIAL

Static result:

| Planned zone | Current backend representation | Status |
| --- | --- | --- |
| `manipulator_slots` | `runtime_inventory_state["manipulator_hold"]` plus Bipob module-slot APIs | PARTIAL |
| `pocket_slots` | `runtime_inventory_state["pocket_items"]` plus Bipob pocket-slot APIs | PARTIAL |
| `keychain` | `runtime_inventory_state["collected_key_ids"]`, exposed through `get_keychain_ids()` | DONE behavior, PARTIAL naming/model |
| `digital_buffer` | `runtime_inventory_state["digital_buffer"]` | DONE |
| `digital_storage` | `runtime_inventory_state["digital_storage"]` | DONE |

This is more than metadata-only routing: there is a real separated backend and UI read path. It is still marked **PARTIAL** because the exact generalized slot contract is not fully realized.

### D. Map Constructor contract — DONE

Static result:

- Palette rows originate from `ARCHETYPE_REGISTRY` plus allowed non-archetype catalog objects.
- Raw item rows are not directly exposed.
- Door, Floor, External Wall, Wall, Terminal, Item, and utility rows are archetype-backed.
- Placement routes through `WorldObjectCatalog.create_world_object()` and, through that entry point, `create_archetype_object()`.
- Items and objects normalize before entering runtime collections.
- Unknown constructors return empty data and are rejected before insertion; validation also flags unknown constructor-created runtime types.

### E. TASK TEST alignment — NEEDS RUNTIME SMOKE

Static result:

- TASK TEST Door/item specs use canonical `door`/`item`/utility ids and property overrides.
- TASK TEST uses the same catalog constructors and normalization functions used by Map Constructor.
- Detached validation data is built without mutating active mission state.
- Final verification checks validation read-only behavior around active state.

Runtime behavior remains unverified until TASK TEST is launched and exercised manually.

### F. Runtime actions — NEEDS RUNTIME SMOKE

Static result:

- Target normalization precedes action calculation.
- UI delegates target/action truth to BipobController.
- Door detection uses normalized `object_group=door`; item and terminal behavior is property/group driven.
- Selection clearing exists after move and interaction paths, and UI pulse is cleared when no interactable target exists.

Static inspection is insufficient to prove no stale pulse remains after every pickup/action/move/turn sequence.

### G. HUD / GOAL binding — PARTIAL

Static result:

- GOAL reads active mission objective ViewModel/catalog data.
- No hardcoded `Use this mission to validate` placeholder was found.
- Runtime storage HUD reads backend inventory state.
- The exact manipulator/key/digital visual contract still needs smoke testing.
- One Russian-facing label remains in `GameUI` and must be removed in a focused cleanup.

### H. Validation — PARTIAL

| Required validation | Current status | Evidence |
| --- | --- | --- |
| prefab exists in constructor but not in registry/catalog | DONE | `validate_constructor_palette_contract()` creates each prefab; `get_map_constructor_validation_issues()` rejects palette/runtime unknowns. |
| TASK TEST object type missing in registry/catalog | DONE | `_validate_task_test_object_contracts()` checks TASK TEST object types. |
| runtime object has unknown `object_type` | DONE | `_build_final_object_registry_section()` rejects missing/unknown runtime types. |
| legacy `object_type` leaked into runtime | DONE | `_validate_legacy_compatibility_boundary()` and `_build_final_object_registry_section()`. |
| Door missing `door_type` / `material` / `access_type` / `state` | DONE | `_validate_current_door_contracts()` and `validate_archetype_object()`. |
| invalid `access_type` | DONE | `_validate_current_door_contracts()` and constructor validation issues. |
| `no_key` Door still has `required_key_id` | DONE | `validate_archetype_object()`, registry validation, and MissionManager Door validation. |
| Key Card item stored outside keychain | DONE | `validate_runtime_inventory_storage_contract()` checks keychain expected storage class; setters reject key-card in physical storage. |
| physical item in digital buffer/storage | DONE | runtime storage validator and `can_place_item_in_digital_buffer()`. |
| digital item in manipulator/pocket | DONE | runtime storage validator, `set_manipulator_item()`, and `set_pocket_item()`. |
| UI manipulator slot count mismatch | PARTIAL | `_build_final_inventory_contract_section()` compares Bipob runtime manipulator item array length with backend slot count; complete widget-to-backend visual validation is not present. |
| GOAL hardcode / missing mission objective binding | DONE for backend binding; PARTIAL for broad text lint | `_build_final_mission_goal_binding_section()` checks active catalog binding. Required search finds no TASK TEST placeholder but does find one unrelated Russian label. |

No new validation code was added in this audit: the remaining gaps require either a runtime behavior decision (`requires_power_to_open`) or a focused UI/runtime follow-up, not a report-only guard that could misrepresent supported behavior.

### I. Parser/CI gate — DONE

`.github/workflows/godot-parser-gate.yml` exists, triggers on `pull_request` and pushes to `main`, and runs all required commands:

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
godot --headless --path . --import
godot --headless --path . --script res://tools/ci/parse_all_gd.gd
```

## Required search summary

The requested searches were executed against current code. Match counts include compatibility metadata, debug paths, comments/labels, and runtime paths; a non-zero count does not by itself imply a leaked canonical runtime type.

| Search | Result summary |
| --- | --- |
| `rg "steel_door\|reinforced_steel_door\|titanium_door\|energy_door\|mechanical_door\|digital_door\|powered_gate" scripts` | 122 matching lines. Expected compatibility mappings and legacy/debug vocabulary remain. Canonical Door archetype construction is present; remaining occurrences need compatibility-boundary review before cleanup. |
| `rg "mechanical_key\|mechanical_keycard\|keycard" scripts` | 72 matching lines. Expected alias normalization is present. Some visual/debug and older UI vocabulary remains. |
| `rg "keychain\|digital_buffer\|digital_storage\|manipulator\|pocket" scripts` | 803 matching lines. Real separated backend/UI paths exist; this is not metadata-only routing. |
| `rg "storage_route\|storage_type\|item_class" scripts` | 77 matching lines. Catalog normalization, constructor editing metadata, runtime requirements, and TASK TEST overrides are present. |
| `rg "Use this mission to validate\|GOAL\|goal\|objective" scripts` | 214 matching lines. No `Use this mission to validate` placeholder occurrence was found; catalog/ViewModel GOAL binding paths are present. |
| `rg "selected.*pulse\|action.*pulse\|available.*actions\|get_available_actions" scripts` | 39 matching lines. UI pulse helpers, normalized action calculation, and final smoke checklist references are present. |
| `rg "mission_world_objects\\.append\|mission_world_objects\\.erase\|cell_items\\[\|world_objects_by_cell\\[" scripts/game/map_constructor_validation_service.gd` | 0 matching lines. The validation service does not directly mutate active mission collections. |
| `rg "labels_ru\|palette_label_ru\|display_name_ru\|Дверь\|Предохранитель\|Ремонт\|Модуль\|Ключ" scripts/world scripts/game scripts/ui` | 1 matching line: `scripts/ui/game_ui.gd` contains `"Ремонт"`. |

## Remaining risks

1. **Powered Door contract drift:** `requires_power_to_open` is exposed by the archetype schema without a named runtime branch or matching validation acceptance.
2. **Runtime behavior not manually verified:** parser/load checks do not prove interaction, HUD, pulse, save/load, or palette behavior.
3. **Inventory model naming/shape drift:** the backend separation exists but differs from the planned generalized slot-shaped state model.
4. **UI visual contract not fully validated:** backend helpers exist, but exact rendered manipulator/key/digital cells require smoke testing.
5. **English-only UI violation:** one Russian-facing Repair label remains.
6. **Legacy vocabulary remains outside catalog aliases:** occurrences in visuals, debug labels, compatibility helpers, and older commands must be reviewed before deletion; bulk replacement would be unsafe.

## Next fix-only PR list

1. **Powered Door `requires_power_to_open` contract decision**
   - Decide whether the mode is supported.
   - If supported, add explicit runtime behavior, TASK TEST coverage, and focused validation.
   - If unsupported, remove it from schema/constants.
2. **English-only Repair label cleanup**
   - Replace the remaining `"Ремонт"` UI label with the correct English label.
   - Rerun the required Cyrillic search.
3. **Runtime smoke regression fixes only if reproduced**
   - Fix stale action pulse, GOAL display, storage HUD, constructor placement, or save/load issues only when a smoke step fails.
4. **Inventory state naming/model decision**
   - Either formalize the singular-manipulator MVP contract or implement a narrow slot-model normalization if multi-slot physical runtime storage is required now.
5. **Legacy occurrence cleanup review**
   - Classify remaining legacy strings as required compatibility, visual/debug vocabulary, or removable stale gameplay assumptions before editing.

## Runtime smoke checklist

The section 7.3 manual test list is updated to current archetype names and current Map Constructor direction:

- [ ] Start TASK TEST.
- [ ] No endless output errors.
- [ ] GOAL panel shows mission objective.
- [ ] Empty cell before Bipob gives no action pulse.
- [ ] Fuse pickup goes to physical inventory/manipulator route.
- [ ] Fuse can move manipulator ↔ pocket if supported.
- [ ] Key Card pickup goes to keychain and displays as key indicator.
- [ ] Key Card does not occupy manipulator.
- [ ] Mechanical `no_key` Door opens/closes.
- [ ] Key-card Door opens with Key Card and free manipulator.
- [ ] Key-card Door does not open if manipulator is occupied, if this rule is implemented.
- [ ] Digital Door opens through Digital Key / Access Code / Terminal.
- [ ] Powered Door obeys `power_behavior`.
- [ ] Map Constructor palette shows archetype rows, not variants.
- [ ] Placed constructor Door works in runtime.
- [ ] Save/load does not create unknown `object_type`.
- [ ] Physical item cannot enter digital storage.
- [ ] Manipulator UI shows real backend slots.
- [ ] Key strip shows real keychain state.
- [ ] No stale selected pulse after pickup/action/move/turn.

## Final audit conclusion

The current code has implemented the main catalog/archetype foundation, canonical Door and item normalization, constructor palette generation, placement normalization, TASK TEST detached validation, objective ViewModel binding, and mandatory parser/CI gate. Stabilization is **not yet fully complete**: runtime smoke is still required, the inventory model remains partially aligned with the plan, the declared `requires_power_to_open` Door behavior needs a focused decision/fix, and one Russian-facing Repair UI label remains open.
