# IRONVEIL Phase 3 Validation Report

**Candidate:** Phase 3 — three-region MVP implementation  
**Date:** 2026-08-16

## Passed in artifact environment

- `python tools/validate_project.py` — **PASS**
- `python tools/test_lobby_contract.py` — **PASS**
- `python tools/test_public_security_contract.py` — **PASS**
- Python `py_compile` for lobby/validators — **PASS**
- Source manifest generated after cleanup.
- Phase-3 catalogs cross-reference valid items/recipes/machines/crops/NPC barter data.
- Static CI coverage includes all production GDScript files.
- Phase-3 public-mode contract contains strong-secret, HTTPS-origin and WSS fail-closed checks.

## Must still pass on Dokploy/Godot 4.7.1

The artifact environment does not contain a runnable Godot 4.7.1 binary or Docker daemon. Therefore the following are deliberately **not claimed as passed**:

- GDScript engine compile/parse gate;
- `IRONVEIL ALL-SCRIPT COMPILE GATE: PASS`;
- `IRONVEIL HEADLESS TESTS: PASS`;
- Web export/runtime rendering;
- full three-region end-to-end playthrough;
- save/load under browser storage;
- 2–4 client co-op/desync tests;
- public WSS/Traefik long-session behavior;
- force-crash checkpoint restore/resource stress.

Dokploy remains the authoritative runtime acceptance environment for those checks.
