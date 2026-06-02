# BIPOB — TASK TEST / Map Constructor runtime contract audit

**Version:** 2026-06-02  
**Scope:** documentation-only audit  
**Active product surface:** `TASK TEST` sandbox + Map Constructor runtime editor  
**Repository:** `JUSTConnect/bibop`  
**Engine:** Godot 4.x / GDScript

---

## 0. Executive summary

The current development focus is not story/career mission content. The active development and testing surface is:

```text
TASK TEST
→ Map Constructor
→ WorldObjectCatalog
→ canonical object/item contracts
→ Bipob targeting/action services
→ runtime HUD
→ validation/readiness reports
```

Normal missions should be treated as legacy compatibility only during this phase. They are useful for finding older tile-driven branches that can still pollute the runtime flow, but they are not the target for new work.

The repository already contains meaningful extraction work:

- `MapConstructorService` owns a focused constructor mutation slice.
- `MapConstructorValidationService` and helper services own a large read-only validation/readiness slice.
- `BipobTargetingService`, `BipobActionViewModelService`, `BipobCapabilityService`, and execution helpers have already reduced part of `BipobController`.
- `scripts/ui/map_constructor/*` and `scripts/ui/runtime/*` have already moved UI presentation slices out of `game_ui.gd`.

The remaining risk is not lack of services. The risk is that TASK TEST runtime behavior still crosses broad compatibility facades and legacy branches:

- `MissionManager` remains both runtime owner and Map Constructor compatibility facade.
- `GameUI` remains a large stateful coordinator for constructor state, refresh sequencing, overlay/picker state, and some mutation callbacks.
- `BipobController` still contains legacy tile/device branches and legacy scan/hack/open-door behavior near the modern world-object action path.
- Constructor mutations still call broad power/cooling refresh hooks in several places; these must stay scoped and must not become global per-move/per-action recalculation.

The correct next step is to preserve the already-created seams and run a narrow, TASK TEST-first cleanup sequence. Do not start broad rewrites.

---

## 1. Non-goals

This audit intentionally does not plan work on story/career missions.

Do not use the next PRs to:

- add or edit normal mission content;
- create new story mission flows;
- rebalance mission objectives;
- migrate every old mission branch at once;
- add enemies/combat;
- rewrite `MissionManager` broadly;
- redesign the whole UI;
- change save/preset/patch formats unless a later PR explicitly scopes that;
- change `project.godot`;
- create `Test Build` folders/files;
- add Russian game-facing labels;
- add global power/cooling recalculation after every movement/action/turn.

Legacy mission-specific code may be audited or quarantined only when it protects TASK TEST / Map Constructor runtime behavior.

---

## 2. Current architecture map

### 2.1 Runtime truth and constructor truth

`MissionManager` currently owns the authoritative runtime collections used by TASK TEST:

```text
mission_world_objects
world_objects_by_cell
cell_items
runtime_inventory_state
constructor_start_marker
constructor_exit_marker
constructor_map_width / constructor_map_height
```

This is acceptable for now. The next step should not move these collections blindly. Instead, future services should wrap narrow responsibilities while leaving `MissionManager` as a compatibility facade until callers are migrated safely.

### 2.2 Catalog and contract layer

`WorldObjectCatalog` is the canonical source for object semantics:

```text
Door types/materials/access/power/control
Item classes/storage routes
Wall/floor archetypes and aliases
Terminal classes/types/statuses
Utility item archetypes
Legacy alias normalization
Constructor palette rows
Archetype property schemas
```

Important current direction:

- constructor palette should expose canonical archetypes, not legacy variants;
- legacy aliases are compatibility-only and must not become new user-facing prefab IDs;
- placed objects/items should normalize through catalog helpers before entering runtime collections.

### 2.3 Map Constructor mutation layer

`MapConstructorService` already owns important mutation operations:

```text
place prefab
remove entity
move entity
duplicate entity
get entity by id
clone constructor entity data
single-property update application
part of terminal/door link synchronization during property updates
```

It correctly guards operations behind TASK TEST constructor context. This guard should remain central. Any new constructor mutation service must keep the same guard and must return explicit mutation results.

### 2.4 Map Constructor validation/readiness layer

Current validation is already split across several read-only helpers:

```text
MapConstructorValidationService
MapConstructorPowerLinkValidationRules
MapConstructorReadinessValidationService
MapConstructorValidationAdapter
MapConstructorLinkReadModelService
```

This is a good direction. Do not move validation decisions back into `GameUI` or display helpers. UI should render result dictionaries; services should decide severity, dependency meaning, link consistency, and readiness status.

### 2.5 Bipob action runtime layer

The modern action path should be treated as the preferred TASK TEST path:

```text
BipobTargetingService
→ BipobActionViewModelService
→ InteractionSystem.can_apply_action
→ narrow execution helper or MissionManager action API
→ UI refresh / HUD refresh
```

The targeting service already resolves facing/current-cell item fallback and builds action/connector/heavy-claw contexts. The action view-model service normalizes target contracts before creating descriptors and gating them through `InteractionSystem`.

Legacy tile interactions must not be allowed to become the source of truth for constructor-placed objects.

### 2.6 UI layer

The extracted UI helpers are real and useful, but `GameUI` remains a broad coordinator.

Safe UI responsibilities:

```text
screen boot
panel construction/root mounting
selected entity UI state
picker/overlay UI state
callback routing
hint routing
post-mutation refresh sequencing
requesting targeted field/renderer refresh
```

Unsafe UI responsibilities that should not grow:

```text
semantic link validity
persisted field alias policy
Door/Terminal/Power/Item normalization
validation severity decisions
autofix/cleanup planning
save/load readiness policy
power/cooling recalculation policy
```

---

## 3. TASK TEST object/system audit table

| System | Current contract status | Main risk | Next action |
| --- | --- | --- | --- |
| Floor / wall archetypes | Mostly catalog-backed and constructor-facing | Visual and gameplay can drift if tile replacement and object contract are mixed casually | Keep visual cleanup separate from gameplay contracts |
| Door | Strong canonical contract exists for type/material/access/control/power/state | UI/link aliases and legacy tile doors can reintroduce duplicated truth | Smoke all Door variants in TASK TEST; then audit remaining legacy door branches |
| Terminal | Canonical terminal archetype exists, validation catches palette variants | Specialized terminal link reads/mutations still pass through broad facade paths | Extract only link mutation/read boundaries after audit, not behavior rewrite |
| Power source | Runtime collections support source-owned networks and power state | Constructor placement/update can trigger broad recalculation if future PRs are careless | Add a scoped recalculation audit around constructor mutation result types |
| Power cable / socket / cable reel | Utility archetypes and cable visuals exist; runtime flow is complex | Old Mission 7 cable branch may confuse modern constructor cable path | Quarantine legacy Mission 7 tile flow; keep modern cable world-object path separate |
| Circuit switch | Action labels and ids exist for Circuit 1/2/3 | UI can regress into generic Switch-only control | Add TASK TEST smoke for three explicit circuit actions |
| Fuse / fuse box | Item storage and utility object contracts exist | Physical item route vs manipulator hold can drift | Smoke pickup, insert, remove, failed insert without held fuse |
| Cooling devices | Scoped helpers exist in project architecture | Future UI/constructor mutations may trigger global cooling/power refresh | Keep preview read-only; apply only after explicit constructor/power/cooling events |
| Platform | Platform controls exist in runtime design, some legacy Mission 8 code remains | Legacy platform/fan tile flow can pollute modern action model | Audit Mission 8 branches as legacy quarantine only |
| Heavy objects | Heavy Claw execution helper exists | Availability and push/pull target truth must stay in action view-model path | Smoke crate/barrel push in TASK TEST and validate stale selection clearing |
| Hidden/X-Ray objects | Scan/X-Ray flags exist in project architecture | Basic scan vs X-Ray reveal can regress if hidden state is UI-owned | Add targeted TASK TEST smoke for hidden/revealed/discovered state |
| Inventory/items | Storage class separation exists, but backend is still MVP-shaped | UI may show slot truth that does not match backend truth | Document MVP storage shape or normalize later; do not fake multi-slot behavior |
| Extraction/start markers | Constructor markers exist | Goal/extraction can become mission-content-driven instead of constructor-driven | Audit TASK TEST start/exit marker validation and runtime spawn/extract binding |

---

## 4. Verified strengths

### 4.1 The constructor context guard exists

Constructor operations in `MapConstructorService` check the TASK TEST constructor context before mutating runtime data. This is the correct protection boundary.

Future services must keep this rule:

```text
No constructor mutation outside TASK TEST constructor context.
```

### 4.2 Constructor placement normalizes objects/items

Placement currently routes through `WorldObjectCatalog.create_world_object()` and additional normalization helpers before writing to runtime collections. This is the correct direction.

Future PRs should not add object dictionaries directly in UI or tests.

### 4.3 Validation is already meaningful and read-oriented

The validation layer checks constructor palette shape, required archetypes, exposed legacy aliases, archetype schemas, and some runtime object contracts. The readiness layer also exists as a separate boundary.

Future PRs should add validation to services, not UI display adapters.

### 4.4 Bipob targeting/action services already form a useful seam

The modern action path is visible and should be protected. `BipobController` should continue moving toward a thin façade, but only through narrow PRs that preserve behavior and side-effect order.

---

## 5. Remaining risks

### R-01 — `MissionManager` is still too broad

`MissionManager` owns runtime state, constructor state, validation forwarding, persistence, presets, cleanup/autofix, property schema/preset logic, link routing, visual refresh hooks, and power/cooling refresh orchestration.

This is acceptable as a temporary compatibility facade, but it is the main future extraction target.

Do not split it by moving random chunks. Split it by stable TASK TEST boundaries:

```text
task_test_setup_service.gd
runtime_object_lookup_service.gd
runtime_inventory_service.gd
map_constructor_link_mutation_service.gd
map_constructor_cleanup_autofix_service.gd
map_constructor_persistence_service.gd
map_constructor_recalculation_policy_service.gd
```

### R-02 — `GameUI` can still become semantic owner again

Even after UI helper extraction, `GameUI` still holds a lot of constructor state and coordinates mutation refreshes. This is fine, but new semantic decisions must not be added there.

A good next docs/code audit should list every direct `mission_manager_runtime` call from:

```text
scripts/ui/game_ui.gd
scripts/ui/map_constructor/*.gd
scripts/ui/runtime/*.gd
```

Then classify each call as:

```text
render-read
callback-route
mutation-facade
semantic-decision-risk
legacy-compatibility
```

### R-03 — Legacy tile flow can bypass constructor world-object contracts

`BipobController` still contains legacy device/tile concepts and mission-specific branches. They may be harmless for old content, but they are dangerous if they intercept a TASK TEST object that should go through world-object targeting/action services.

The goal is not to rewrite old mission behavior. The goal is to quarantine it.

### R-04 — Power/cooling recalculation policy is not explicit enough

Constructor placement/removal/move currently calls recalculation/refresh hooks. That is expected after explicit constructor mutations. The risk is future PRs adding broad recalculation to movement, UI refresh, validation, scan, or every action.

The project needs an explicit rule:

```text
Validation/readiness: read-only or snapshot/restore.
UI refresh: no power/cooling mutation.
Movement/turn/action view-model: no global recalculation.
Constructor mutation: targeted recalculation only when the mutation changes a relevant network/object.
Explicit power/cooling gameplay action: scoped apply only.
```

### R-05 — Storage UI can overpromise backend capability

Runtime inventory has separated zones, but the backend is still MVP-shaped. Before adding richer storage UI, decide whether current MVP is:

```text
single manipulator hold + pocket array + key ids + digital buffer/storage
```

or whether the next iteration must normalize to named slot structures. Do not let UI display fake slot behavior that backend does not enforce.

---

## 6. Recommended next PR sequence

### PR-TT-01 — TASK TEST runtime contract matrix audit

**Type:** docs-only  
**Goal:** Create a complete object/system matrix for TASK TEST constructor-created gameplay.

Target files:

```text
docs/bipob_task_test_runtime_contract_matrix.md
```

Audit every constructor-facing object/system:

```text
Door
Terminal
Power Source
Power Cable
Socket
Cable Reel
Circuit Switch
Fuse Box
Light/Light Switch
Cooling device
Platform
Crate/Barrel/Heavy object
Hidden/X-Ray object
Physical item
Key Card
Digital Key
Access Code
Extraction/start marker
```

For each row answer:

```text
catalog-backed?
constructor-placeable?
normalized on placement/update?
blocks_movement truth?
Action/Connect/Heavy Claw availability source?
execution path?
HUD source?
validation coverage?
manual smoke required?
legacy tile risk?
```

Acceptance:

```text
- No code changes.
- Normal missions are explicitly out of scope.
- The output lists exact follow-up PRs by object/system.
```

### PR-TT-02 — UI-to-runtime call boundary audit

**Type:** docs-only or tiny helper-only refactor  
**Goal:** Stop new semantic logic from accumulating in `GameUI` and UI helpers.

Target files:

```text
scripts/ui/game_ui.gd
scripts/ui/map_constructor/*.gd
scripts/ui/runtime/*.gd
docs/bipob_game_ui_constructor_runtime_boundary_audit.md
```

Deliverable:

```text
A table of all direct mission_manager_runtime calls.
Classification:
- render-read
- callback-route
- mutation-facade
- semantic-decision-risk
- legacy-compatibility
```

Follow-up candidates:

```text
map_constructor_ui_runtime_facade.gd
map_constructor_selection_state.gd
map_constructor_refresh_coordinator.gd
```

Do not move broad UI state yet.

### PR-TT-03 — Constructor recalculation policy audit

**Type:** docs-only first  
**Goal:** Make power/cooling refresh policy explicit for constructor mutations.

Target files:

```text
scripts/game/map_constructor_service.gd
scripts/game/map_constructor_property_update_service.gd
scripts/game/mission_manager.gd
scripts/world/power_system.gd
docs/bipob_constructor_recalculation_policy_audit.md
```

Classify mutations:

```text
no recalculation needed
targeted object refresh needed
targeted power network recalculation needed
cooling refresh needed
full runtime rebuild required only by explicit reset/load
```

Acceptance:

```text
- No new global recalculation.
- Validation remains read-only.
- UI refresh cannot trigger gameplay mutation.
```

### PR-TT-04 — Legacy tile interaction quarantine audit

**Type:** docs-only first, then narrow code PRs  
**Goal:** Protect TASK TEST world-object action flow from legacy tile/device branches.

Target files:

```text
scripts/bipob/bipob_controller.gd
scripts/game/bipob_*_service.gd
docs/bipob_controller_legacy_tile_interaction_boundary_audit.md
```

Classification:

```text
still needed for legacy compatibility
reachable in TASK TEST
unreachable in TASK TEST
must be moved behind legacy service
can be deleted later only after proof
```

Follow-up code PR order:

```text
1. extract read-only legacy digital tile blockers
2. quarantine Mission 8 platform/fan tile router
3. quarantine Mission 7 cable/socket tile router
4. audit fallback TILE_COMPONENT/TILE_KEY/TILE_DOOR branches
5. audit scan/hack/open_door/open_digital_door legacy paths
```

### PR-TT-05 — TASK TEST setup/default capability boundary

**Type:** narrow code PR  
**Goal:** Ensure TASK TEST starts with the expected editor/smoke capabilities without manual module setup.

Expected TASK TEST default capabilities:

```text
Manipulator V1+
Connector V1+
Heavy Claw
```

Target candidate:

```text
scripts/game/task_test_setup_service.gd
```

Rules:

```text
- TASK TEST only.
- Do not change normal mission setup.
- Do not fake capabilities in UI.
- Capability truth must be visible to BipobCapabilityService / action view-model path.
```

### PR-TT-06 — MissionManager extraction boundary audit

**Type:** docs-only first  
**Goal:** Decide exact MissionManager split order after TASK TEST/UI/recalculation audits.

Candidate services:

```text
task_test_setup_service.gd
runtime_object_lookup_service.gd
runtime_inventory_service.gd
map_constructor_link_mutation_service.gd
map_constructor_cleanup_autofix_service.gd
map_constructor_persistence_service.gd
map_constructor_recalculation_policy_service.gd
```

Acceptance:

```text
- No broad MissionManager rewrite.
- Each future service has a narrow API and a compatibility forwarding method.
- Existing public methods remain stable until callers migrate.
```

---

## 7. Manual TASK TEST smoke checklist

Run this inside Godot, in TASK TEST constructor mode, using only Map Constructor-created or edited objects.

### 7.1 Constructor basics

```text
[ ] Open TASK TEST.
[ ] Enter Map Constructor.
[ ] Place floor, wall, external wall.
[ ] Place and delete a world object.
[ ] Place and delete an item.
[ ] Move an object.
[ ] Duplicate an object.
[ ] Select object and confirm inspector shows backend data.
[ ] Switch tabs without losing selected entity.
[ ] Confirm validation overlay updates after mutation.
```

### 7.2 Door contracts

```text
[ ] Place mechanical Door.
[ ] Configure key-card access.
[ ] Confirm closed Door blocks movement.
[ ] Pick up Key Card into keychain, not manipulator.
[ ] Open/close Door through Action.
[ ] Place digital Door.
[ ] Confirm Digital Key requires Connect path, not physical manipulator action.
[ ] Place access-code Door.
[ ] Confirm code entry is real UI or honestly reports not implemented.
[ ] Place powered Door.
[ ] Confirm power loss/restoration changes availability according to power_behavior.
[ ] Confirm linked Terminal can unlock/control only linked Door.
```

### 7.3 Terminal contracts

```text
[ ] Place Terminal.
[ ] Confirm Terminal blocks movement by object contract.
[ ] Confirm Scan/Action/Connect target the same Terminal shown in HUD.
[ ] Link Terminal to Door.
[ ] Confirm Terminal actions affect only linked target.
[ ] Unpower Terminal.
[ ] Confirm hack/execute are blocked while unpowered.
[ ] Damage/break Terminal.
[ ] Confirm actions are blocked with readable reason.
```

### 7.4 Power/cable contracts

```text
[ ] Place Power Source.
[ ] Confirm it has stable source-owned network id.
[ ] Place consumer on main_power_net and source-owned net.
[ ] Place visible Power Cable path.
[ ] Confirm warning disappears only when physical path exists.
[ ] Cut/disconnect cable.
[ ] Confirm affected consumer loses power through scoped update.
[ ] Repair cable.
[ ] Confirm repair does not auto-reconnect unless explicit reconnect action is used.
[ ] Confirm hidden cable has no visible stripe but still validates correctly when intended.
```

### 7.5 Switch/fuse/circuit contracts

```text
[ ] Place Circuit Switch.
[ ] Confirm runtime UI shows Circuit 1, Circuit 2, Circuit 3.
[ ] Trigger each circuit action.
[ ] Place Fuse Box.
[ ] Try Insert Fuse without held fuse; confirm no mutation.
[ ] Pick up Fuse.
[ ] Insert Fuse successfully.
[ ] Remove Fuse successfully.
```

### 7.6 Heavy Claw contracts

```text
[ ] Place Crate/Barrel/Box with movable_by_heavy_claw=true.
[ ] Face object.
[ ] Confirm Heavy Claw button enables only for valid target.
[ ] Push object.
[ ] Confirm collision, blocking, and target cell update correctly.
[ ] Move/turn away.
[ ] Confirm stale Heavy Claw pulse clears.
```

### 7.7 Inventory/storage contracts

```text
[ ] Place physical item.
[ ] Pick up item.
[ ] Confirm it routes to pocket/manipulator according to backend rules.
[ ] Place Key Card.
[ ] Pick up Key Card.
[ ] Confirm it goes to keychain/collected_key_ids and is not held physically.
[ ] Place Digital Key.
[ ] Pick up Digital Key.
[ ] Confirm it routes to digital buffer/storage.
[ ] Confirm UI displays backend state only.
```

### 7.8 Scan/X-Ray/hidden contracts

```text
[ ] Place hidden object.
[ ] Basic scan should not reveal it unless contract says so.
[ ] X-Ray should reveal only objects with correct flags.
[ ] Revealed/discovered state persists in runtime.
[ ] HUD and validation agree on revealed state.
```

### 7.9 Start/extraction markers

```text
[ ] Move TASK TEST start marker.
[ ] Restart/load TASK TEST and confirm Bipob starts at marker.
[ ] Move extraction marker.
[ ] Confirm extraction/goal reads constructor marker, not hardcoded story mission content.
```

---

## 8. Acceptance checklist for all next PRs

```text
[ ] PR scope says TASK TEST / Map Constructor runtime when applicable.
[ ] Normal mission content is untouched.
[ ] No project.godot changes.
[ ] No Test Build files/folders.
[ ] No mission resource writes from validation/tools.
[ ] No new combat/enemy behavior.
[ ] Validation is read-only or snapshot/restore.
[ ] UI does not decide semantic validity.
[ ] UI refresh does not mutate gameplay state.
[ ] No broad global power/cooling recalculation is added.
[ ] Runtime labels remain English.
[ ] Existing public methods remain stable unless migration is explicitly scoped.
[ ] GDScript safety checks remain green.
[ ] Godot parser gate remains green.
[ ] Manual TASK TEST smoke steps relevant to the PR are listed.
```

---

## 9. Codex prompt for the next immediate audit PR

```text
BIPOB PR-TT-01 — TASK TEST runtime contract matrix audit

Goal:
Create a documentation-only audit for TASK TEST / Map Constructor runtime contracts. Treat TASK TEST as the active sandbox/editor/runtime product surface. Do not plan story mission work.

Scope:
- scripts/world/world_object_catalog.gd
- scripts/game/mission_manager.gd
- scripts/game/map_constructor_service.gd
- scripts/game/map_constructor_validation_service.gd
- scripts/game/map_constructor_property_update_service.gd
- scripts/game/map_constructor_link_read_model_service.gd
- scripts/game/map_constructor_power_link_validation_rules.gd
- scripts/game/map_constructor_readiness_validation_service.gd
- scripts/bipob/bipob_controller.gd
- scripts/game/bipob_*_service.gd
- scripts/ui/game_ui.gd
- scripts/ui/map_constructor/*
- scripts/ui/runtime/*

Rules:
- Documentation-only.
- Do not modify gameplay code.
- Do not add or edit normal mission content.
- Normal missions are legacy compatibility only.
- Do not change project.godot.
- Do not create Test Build files/folders.
- Do not add Russian game-facing labels.
- Validation must remain read-only or snapshot/restore.

Deliverable:
Create docs/bipob_task_test_runtime_contract_matrix.md with a table for each constructor-facing object/system:
- catalog-backed?
- constructor-placeable?
- normalized on placement/update?
- movement blocking truth?
- action/Connect/Heavy Claw availability source?
- execution path?
- HUD source?
- validation coverage?
- manual smoke requirement?
- legacy tile risk?

Acceptance:
- The document prioritizes exact next PRs.
- The document explicitly excludes story/career mission work.
- The document identifies any legacy tile branches that can interfere with TASK TEST runtime contracts.
```

---

## 10. Final recommendation

The next iteration should be:

```text
1. PR-TT-01 — TASK TEST runtime contract matrix audit
2. PR-TT-02 — UI-to-runtime call boundary audit
3. PR-TT-03 — constructor recalculation policy audit
4. PR-TT-04 — legacy tile interaction quarantine audit
5. PR-TT-05 — TASK TEST default capability setup service
6. PR-TT-06 — MissionManager extraction boundary audit
```

This order keeps the project aligned with the current real workflow: build and test mechanics in TASK TEST through Map Constructor, stabilize canonical contracts, then reduce `GameUI`, `BipobController`, and `MissionManager` without breaking the sandbox.
