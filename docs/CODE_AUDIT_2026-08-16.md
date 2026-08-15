# IRONVEIL Phase 1 — Full Source / Deployment Audit

**Date:** 2026-08-16  
**Scope:** Phase 1 First Playable source, Godot 4.7.1 Web build path, Docker/nginx deployment contract.

## Why the earlier deployments behaved inconsistently

The first image could be exported and served while gameplay later failed after the Godot splash. The original build pipeline did not have a comprehensive Godot compile/runtime gate before export. Later revisions added a headless test, but that test itself used compile-time `preload()` dependencies. A failure inside a dependency could therefore surface only as `Could not preload ...` at the test-runner boundary, obscuring the actual source file/problem.

The latest Dokploy logs also proved that the previous `MechanicalNetwork` Variant-inference issue and missing `fontconfig` dependency were already fixed: project scanning completed and the next failure moved to the test runner's HUD preload boundary.

## Audit changes

### 1. Godot compile gate

Added `scripts/tests/compile_all.gd`.

It loads every runtime script independently in dependency-first order, then loads both project scenes. `main.gd` is deliberately checked last so a broken dependency is reported before the composition root.

Expected success marker:

```text
IRONVEIL ALL-SCRIPT COMPILE GATE: PASS
```

### 2. Runtime startup smoke test

`scripts/tests/run_headless_tests.gd` no longer uses a large compile-time `preload()` table.

It now:

- validates the mechanical network numerically;
- validates every JSON catalog is present and parseable;
- instantiates **`boot.tscn`**, the same entry scene used by native/Web builds;
- waits for the boot path to attach `main.tscn`;
- requires a player node;
- requires an active `Camera3D`;
- requires the water-wheel source and mechanical-saw consumer to be registered.

Expected success marker:

```text
IRONVEIL HEADLESS TESTS: PASS
```

### 3. GDScript type/Variant audit

Audited boundaries where Godot APIs or dictionaries return `Variant`:

- mechanical graph queue/dictionaries;
- JSON parsing/catalog records;
- save-file parsing and restore;
- journal reconstruction;
- settings dictionary access;
- camera raycast collider;
- enemy drop tables;
- audio `ResourceLoader` result;
- player/enemy input-event narrowing.

High-risk inference is replaced with explicit type conversion, `Variant` checks and casts where appropriate.

The earlier Python-validator claim that `:=` was invalid in function default parameters was removed. That syntax is valid GDScript; grammar correctness is now delegated to the real Godot compile gate rather than guessed by Python regex rules.

### 4. Headless compatibility

`SettingsManager` skips window-only DisplayServer operations when `DisplayServer.get_name() == "headless"`. This keeps the Docker runtime smoke test from depending on a real window/display server.

### 5. Data/economy integrity

Static validation now verifies:

- unique catalog IDs;
- recipe input/output items exist;
- machine input/output items exist;
- enemy drops reference valid items;
- biome resources reference valid items;
- Phase 1 map contains enough Scrap to repair the wheel **and** craft the gear;
- at least one Log and edible berry exist.

### 6. Resource/path integrity

Static validation verifies:

- all required source-of-truth files;
- autoload/project `res://` references;
- `.tscn` external resource paths;
- every runtime `.gd` is represented by the Godot compile gate;
- every `preload("res://...")` path exists.

### 7. Web export/deploy integrity

Verified configuration contract:

- Godot 4.7.1 CI image is pinned;
- Compatibility renderer is configured;
- Web threading is disabled;
- `*.json` is explicitly included in the Web PCK;
- nginx explicitly serves `.wasm` and `.pck` MIME types;
- fixed-name Godot payloads are revalidated instead of cached `immutable`;
- Docker build order is import → compile all → runtime smoke tests → Web export;
- Docker refuses the image if `index.html`, `index.js`, `index.wasm` or `index.pck` is missing/empty.

## Docker build acceptance sequence

A successful Dokploy build should progress through:

```text
Godot --import
↓
IRONVEIL ALL-SCRIPT COMPILE GATE: PASS
↓
IRONVEIL HEADLESS TESTS: PASS
↓
Godot Web export
↓
index.html / index.js / index.wasm / index.pck non-empty
↓
nginx runtime image
```

If it fails **before** the compile marker, the log should now identify the actual script/resource being loaded instead of hiding it behind the old HUD preload boundary.

If compile passes but the runtime marker fails, parsing is no longer the issue; the failure is in startup/gameplay integration and the named smoke-test assertion should identify which invariant is missing.

## What this audit does NOT claim

The source-generation environment does not contain a Godot executable or Docker daemon, so it cannot truthfully claim that the final Godot 4.7.1 Docker build has already run here. `tools/validate_project.py` passes locally, but the next Dokploy build remains the authoritative compiler/runtime verification.

Phase 1 is therefore **not marked complete yet**. It becomes eligible for completion only after the real Web/native acceptance checklist in `PROJECT_STATE.md` is green.
