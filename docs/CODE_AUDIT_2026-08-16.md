# IRONVEIL Phase 1 — Full Source / Deployment Audit

**Date:** 2026-08-16  
**Scope:** Phase 1 First Playable, Godot 4.7.1 autoload lifecycle, script compilation, boot path, Web export, Docker/nginx deployment.

## Confirmed root cause of the repeated Docker failures

The project already had valid `[autoload]` entries for `DataRegistry`, `TickManager`, `ChunkManager`, `SettingsManager`, `GameState`, `SaveManager`, and `AudioManager`.

The failing component was the **CI execution model** introduced after the original black-screen deployment. The Dockerfile ran test scripts with `godot --script`. Production gameplay scripts rely on Godot project autoload singleton names, which are designed around the normal project/scene lifecycle. The custom `--script` runner therefore created a lifecycle mismatch and emitted unresolved identifiers such as `TickManager` and `GameState`.

The old compile gate also had a correctness flaw: it could reach its PASS branch even after Godot had already emitted script dependency errors, so the PASS marker was not trustworthy.

## Final CI architecture

### 1. Import cleanly

Docker deletes `.godot`, then runs:

```text
godot --headless --path /app --import
```

### 2. Run tests as a normal project scene

Docker then runs:

```text
godot --headless --path /app res://scenes/tests/ci_runner.tscn
```

This is intentionally **not** `--script`.

### 3. Assert autoloads first

Before any compile/test PASS can occur, `ci_runner.gd` requires the following live nodes:

```text
/root/DataRegistry
/root/TickManager
/root/ChunkManager
/root/SettingsManager
/root/GameState
/root/SaveManager
/root/AudioManager
```

If any is missing, CI records a failure and exits non-zero.

### 4. Compile/load every production runtime script

The runner loads every runtime `.gd` and both production scenes. A null/non-script result is a failure. The PASS marker is printed only while the shared failure list is still empty.

### 5. Validate live data registry

All seven JSON files must exist and parse as arrays, and the already-initialized `DataRegistry` autoload must expose non-empty dictionaries for each catalog.

### 6. Validate mechanical solver

The deterministic chain remains:

```text
Water wheel 32 RPM / 120 Nm
→ 3:1 gearbox @ 90%
→ belt @ 95%
→ saw @ 92%
```

The gear must resolve to 96 RPM / 36 Nm, the saw must be powered above its minimum torque, and disabling the source must depower it.

### 7. Reproduce the real boot path

CI instantiates `boot.tscn`, not a test-only fake main. It waits for deferred startup and then requires:

- `Main` attached;
- a player in the `players` group;
- an active `Camera3D`;
- water-wheel mechanical node registered;
- mechanical-saw consumer registered.

### 8. Export only after CI passes

Only then does Docker run Web export and require non-empty:

```text
index.html
index.js
index.wasm
index.pck
```

## Additional code/deploy hardening retained

- Godot 4.7 Variant-return boundaries use explicit types/casts where high-risk.
- `SettingsManager` skips window-only calls under the headless display server.
- `boot.gd` loads `main.tscn` as a strongly typed `PackedScene` and keeps a visible diagnostic overlay on startup failure.
- All export presets include `*.json` runtime catalogs.
- Web uses Compatibility renderer with threads disabled.
- nginx explicitly maps WASM/PCK MIME types.
- Fixed-name Web payloads are revalidated rather than cached `immutable`.
- Phase 1 remains an **Application + root Dockerfile** deployment; Compose remains a Phase 2 consideration when room/lobby services exist.

## What this audit does not claim

The current execution environment cannot run Godot or Docker locally, so the final claim remains deliberately narrow: the source/CI lifecycle mismatch has been fixed and static validation passes. The next Dokploy build is the authoritative Godot runtime check.
