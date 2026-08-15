# Validation Report — Web Black-Screen Fix

Date: 2026-08-16

## Static checks

- `tools/validate_project.py`: **PASS**
- Web preset contains `include_filter="*.json"`: **PASS**
- Project entry scene is `res://scenes/boot.tscn`: **PASS**
- nginx no longer immutable-caches fixed-name `index.pck/index.wasm`: **PASS**
- Docker build contract runs Godot `--import` and `scripts/tests/run_headless_tests.gd` before Web export: **PASS**
- Phase 1 runtime scripts are preloaded by the Godot headless test so parser failures are intended to fail the Dokploy build: **configured**

## Still requires the real deployment runtime

This environment does not have a Godot executable or Docker daemon, so the corrected image must be rebuilt by Dokploy. The live deployment previously reached the Godot splash but then showed a black canvas. After this revision is deployed, the boot scene should either enter gameplay or show an explicit on-canvas startup failure.
