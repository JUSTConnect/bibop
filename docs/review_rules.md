# Review and Codex rules

## Focused PR policy

Keep PRs small, task-focused, and easy to review. Every implementation prompt should include an explicit allowed-files list. Treat that list as a hard boundary: if another file appears necessary, stop and request a scope update instead of editing it opportunistically.

Use the current post-PR19 architecture. Do not fold the next planned refactor, cleanup, or feature into the current PR.

## Allowed-files discipline

- Do not edit `project.godot` unless the task explicitly requests it.
- Do not touch UI files in runtime-only PRs.
- Do not touch runtime files in UI-only PRs.
- Do not edit `scripts/game/map_constructor_service.gd` or `scripts/game/map_constructor_validation_service.gd` unless the task is specifically about those services.
- Do not edit scenes, docs, tools, tests, or schemas unless they are listed as allowed files.
- Do not perform unrelated refactors.
- Do not add save/load schema migrations unless explicitly requested.
- Do not allow PR scope to creep into the next planned PR.

## GDScript safety rules

Avoid patterns that can break parsing, inference, or runtime behavior:

- Never introduce the generated token `PackedString_safe_ui_array`.
- Do not call `_safe_ui_array(...).append(...)`; assign the guarded array to a typed local first, then append.
- Do not use `Dictionary(value)` or `Array(value)` casts without a type guard or the appropriate safe UI helper.
- Do not use C-style ternary syntax (`condition ? a : b`); use GDScript's `a if condition else b` form.
- Avoid ambiguous `:=` declarations when Variant inference can break. Prefer an explicit type when a value comes from dictionaries, dynamic calls, or other Variant-returning APIs.
- For dynamic UI calls, preserve null checks and matching `has_method()` guards.

## Local static checks

Run these lightweight checks for relevant PRs:

```bash
python tools/check_map_constructor_sections.py
python tools/check_gdscript_safety_patterns.py
git diff --check
```

The Python tools do not require Godot. If Godot CLI is installed, run the appropriate project parse or smoke check as an additional validation step. A PR should not make documentation or review tools depend on Godot being installed.

Also confirm the changed-file list matches the prompt:

```bash
git diff --name-only HEAD
```

## Reviewer checklist

- [ ] The diff contains only allowed files.
- [ ] The PR has one focused goal and no unrelated refactor.
- [ ] `project.godot` is unchanged unless explicitly allowed.
- [ ] UI-only and runtime-only boundaries are respected.
- [ ] Map Constructor services are unchanged unless the task targets them.
- [ ] No unplanned save/load migration or return-shape change was introduced.
- [ ] Unsafe GDScript patterns were not added.
- [ ] Local static checks and `git diff --check` were run.
- [ ] Godot CLI checks were run when available and relevant, or their absence is documented.
- [ ] The final PR summary lists changed behavior, preserved behavior, and testing.

## Codex prompt templates

Replace bracketed placeholders before use. Keep the allowed-files list narrow and explicit.

### UI-only PR template

```text
Repository: JUSTConnect/bibop
PR title: [UI-focused title]

Goal:
[Describe the presentation or UI wiring change.]

Allowed files:
- scripts/ui/[specific helper].gd
- [other explicitly required UI files only]

Strict constraints:
- UI-only PR.
- Do not edit runtime systems, Map Constructor services, scenes, tools, schemas, or project.godot.
- No unrelated refactors or scope creep.

Required behavior unchanged:
- Preserve runtime/gameplay behavior and save/load compatibility.
- Keep UI calls behind the MissionManager facade.

Testing:
- Run git diff --check.
- Verify only allowed files changed.
- Run python tools/check_map_constructor_sections.py.
- Run python tools/check_gdscript_safety_patterns.py.
- Run a Godot CLI check if available and relevant.

Final PR summary requirements:
- List UI files changed and the UI result.
- Confirm runtime systems, services, schemas, tools, scenes, and project.godot were not changed.
- List testing performed.
```

### Runtime-only PR template

```text
Repository: JUSTConnect/bibop
PR title: [Runtime-focused title]

Goal:
[Describe the gameplay/runtime bugfix or behavior change.]

Allowed files:
- scripts/[specific runtime file].gd
- [other explicitly required runtime files only]

Strict constraints:
- Runtime-only PR.
- Do not edit UI files, Map Constructor services, scenes, tools, schemas, or project.godot.
- No unrelated refactors or scope creep.

Required behavior unchanged:
- Preserve UI behavior and save/load compatibility.
- Preserve unrelated runtime behavior.

Testing:
- Run git diff --check.
- Verify only allowed files changed.
- Run python tools/check_gdscript_safety_patterns.py.
- Run a Godot CLI check if available and relevant.

Final PR summary requirements:
- List runtime files changed and the fixed behavior.
- Confirm UI files, services, schemas, tools, scenes, and project.godot were not changed.
- List testing performed.
```

### Service-only PR template

```text
Repository: JUSTConnect/bibop
PR title: [Map Constructor service title]

Goal:
[Describe the targeted mutation or validation service change.]

Allowed files:
- scripts/game/map_constructor_[service or validation_service].gd
- scripts/game/mission_manager.gd [only if facade wiring must change]
- [explicitly required callers or tests only]

Strict constraints:
- Service-focused PR.
- Do not edit UI presentation, runtime systems, tools, schemas, scenes, or project.godot unless explicitly listed.
- Preserve the MissionManager facade; do not bypass it from UI helpers.
- No unrelated refactors or scope creep.

Required behavior unchanged:
- Preserve public facade names and return Dictionary shapes unless all callers are explicitly updated.
- Preserve old-map loading without migration.
- Preserve unrelated Map Constructor behavior.

Testing:
- Run git diff --check.
- Verify only allowed files changed.
- Run python tools/check_map_constructor_sections.py.
- Run python tools/check_gdscript_safety_patterns.py.
- Run a Godot CLI check if available and relevant.

Final PR summary requirements:
- State which service responsibility changed and whether facade wiring changed.
- Confirm return-shape and old-map compatibility.
- List testing performed.
```

### Docs/tooling-only PR template

```text
Repository: JUSTConnect/bibop
PR title: [Documentation or tooling title]

Goal:
[Describe the documentation or local-review-tool improvement.]

Allowed files:
- docs/[specific file].md
- tools/[specific script].py [only when tooling changes are requested]

Strict constraints:
- Docs/tooling-only PR.
- Do not edit GDScript, UI, runtime systems, scenes, schemas, or project.godot.
- Do not change runtime or UI behavior.
- No unrelated refactors or scope creep.

Required behavior unchanged:
- Preserve game behavior, UI behavior, and save/load compatibility.
- Keep docs aligned with implemented architecture; do not document speculative work as complete.

Testing:
- Run git diff --check.
- Verify only allowed files changed.
- Run affected Python review tools when applicable.
- No Godot CLI check is required for a documentation-only PR.

Final PR summary requirements:
- List docs/tools changed and what each covers.
- Confirm no GDScript, runtime, UI, schema, scene, or project.godot files changed.
- List testing performed.
```

### Bugfix PR template

```text
Repository: JUSTConnect/bibop
PR title: [Focused bugfix title]

Goal:
[Describe the observed bug, expected behavior, and narrow fix.]

Allowed files:
- [minimum files required for the fix]

Strict constraints:
- Bugfix-only PR.
- Do not broaden the fix into cleanup, architecture work, schema changes, or the next planned PR.
- Do not edit UI/runtime/services/tools/scenes/project.godot outside the allowed list.

Required behavior unchanged:
- Preserve unrelated gameplay, UI behavior, public facade contracts, and old-map loading.
- Keep existing return Dictionary shapes unless caller updates are explicitly in scope.

Testing:
- Run git diff --check.
- Verify only allowed files changed.
- Run python tools/check_gdscript_safety_patterns.py.
- Run python tools/check_map_constructor_sections.py when Map Constructor code is involved.
- Run a focused reproduction or Godot CLI check if available and relevant.

Final PR summary requirements:
- Explain the bug cause and narrow fix.
- List preserved behavior and files intentionally left unchanged.
- List testing performed.
```
