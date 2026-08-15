# Validation Report — Phase 1 Autoload/CI Audit

**Date:** 2026-08-16

## Local source checks

- `python3 tools/validate_project.py`: **PASS**
- Required source-of-truth files and project resources exist: **PASS**
- Required autoload declarations exist in `project.godot`: **PASS**
- Every production runtime GDScript is represented in the scene-based CI compile/load list: **PASS**
- CI uses `res://scenes/tests/ci_runner.tscn`, not `godot --script`: **PASS**
- CI explicitly asserts all seven required autoload singletons at runtime: **PASS**
- Project/autoload/scene `res://` references exist: **PASS**
- JSON catalogs parse and have unique IDs: **PASS**
- Recipe/machine/enemy/biome item references are valid: **PASS**
- Milestone-1 fixed resource supply is sufficient: **PASS**
- Mechanical reference chain remains above the saw minimum torque: **PASS**
- Known high-confidence Godot 4.7 Variant-inference hazards: **none detected**
- Web/Windows/Linux presets explicitly include JSON catalogs: **PASS**
- Web threading remains disabled: **PASS**
- nginx WASM/PCK MIME + non-immutable fixed-payload cache policy: **PASS**
- Docker gate order is import → normal-scene CI → Web export → artifact existence checks: **PASS**

## Root cause fixed

The previous failures were not caused by missing `[autoload]` entries. Those entries already existed. The CI process itself ran tests through `godot --script`, which did not reproduce the normal project-scene lifecycle expected by production scripts that reference autoload singleton identifiers.

That path has been removed from Docker/Makefile. The test gate now runs as a normal Godot scene after project initialization and checks `/root/<AutoloadName>` before compiling/loading gameplay resources.

## Godot/Docker runtime gates configured

A successful Docker build must print:

```text
IRONVEIL CI: normal-scene lifecycle started
IRONVEIL ALL-SCRIPT COMPILE GATE: PASS
IRONVEIL HEADLESS TESTS: PASS
```

The runtime smoke test enters through `boot.tscn`, matching the exported project entry path.

## Pending real-runtime verification

This source-generation environment still has no local Godot executable or Docker daemon. Therefore Dokploy remains the authoritative execution environment for:

- actual Godot 4.7.1 parser/compiler result;
- scene-based CI result with autoload lifecycle;
- Web export result;
- container healthcheck;
- browser rendering and full First Playable gameplay.

Static validation is not represented as runtime completion.
