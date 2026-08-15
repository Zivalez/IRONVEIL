# SESSION REPORT — 2026-08-16 — Autoload/CI Lifecycle Fix

## 1. Selesai

- Audited the actual `[autoload]` declarations and confirmed all required managers were already configured.
- Removed the `godot --script` compile/test execution path that caused false unresolved singleton identifiers.
- Replaced it with `scenes/tests/ci_runner.tscn`, executed as a normal project scene.
- CI now checks autoload existence first, then all runtime scripts/scenes, JSON + live `DataRegistry`, mechanical solver, and the real `boot.tscn` startup path.
- PASS is emitted only when the shared failure list is empty; failure exits Godot with code 1.
- Updated Dockerfile, Makefile, validation, troubleshooting, and audit documentation.
- Added JSON inclusion to native presets as well as Web.

## 2. Setengah jadi

Phase 1 runtime acceptance still requires a real Dokploy/Godot build and browser playthrough. Phase 2 remains blocked.

## 3. Cara test

```bash
python3 tools/validate_project.py
godot --headless --path . --import
godot --headless --path . res://scenes/tests/ci_runner.tscn
docker build --no-cache -t ironveil:phase1 .
```

Expected CI markers:

```text
IRONVEIL CI: normal-scene lifecycle started
IRONVEIL ALL-SCRIPT COMPILE GATE: PASS
IRONVEIL HEADLESS TESTS: PASS
```

## 4. Keputusan yang kuambil sendiri

`D-013`: all project-aware CI must execute through a normal scene lifecycle. `godot --script` is prohibited for tests that depend on project autoload singleton names.

## 5. Masalah / risiko

- The prior all-script gate was structurally wrong for an autoload-heavy project and could print a misleading PASS.
- Runtime result still cannot be truthfully claimed until Dokploy executes Godot 4.7.1.
- Visuals remain Phase 1 blockout; Modern Pixel Art / Hi-Bit remains the locked final direction.

## 6. Langkah berikutnya

1. Replace repository contents with this audited source.
2. Dokploy rebuild without cache.
3. Confirm all autoload markers + both CI PASS markers before Web export, then play First Playable end-to-end.
