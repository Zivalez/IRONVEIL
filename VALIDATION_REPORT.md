# VALIDATION REPORT — 2026-08-16 — Revised Master Prompt

## Automated checks completed in generation environment

- **PASS** — `python3 tools/validate_project.py`
  - required source-of-truth/living files exist;
  - revised `IRONVEIL_MASTER_PROMPT.md` includes §4.5 Security & Scalability;
  - master prompt retains the hard four-player room limit, create-room rate-limit requirement, WSS requirement, checkpoint/resilience requirement, and Phase 3/public release gate;
  - `docs/PHASE2_SECURITY_SCALABILITY.md` contains capacity, anti-abuse, transport, checkpoint and public-release acceptance contracts;
  - all JSON catalogs parse and contain unique IDs;
  - crafting recipes reference valid item IDs;
  - Phase 1 mechanical reference chain remains above saw RPM/torque thresholds;
  - Web export preset exists with threads disabled;
  - Docker builder version contract is present;
  - nginx explicitly maps `.wasm` and `.pck` MIME types;
  - GDScript delimiter/preload-path static checks pass.
- **PASS** — Python helper scripts compile with `py_compile`.
- **PASS** — newly supplied master prompt is copied byte-for-byte into the repository root as `IRONVEIL_MASTER_PROMPT.md`.

## Scope verification

- **PASS** — no Phase 2 lobby/room/rate-limit implementation is falsely claimed in Phase 1.
- **PASS** — Phase 1 Dokploy guidance remains **Application + root Dockerfile + port 80**.
- **PASS** — multi-service/Compose guidance is deferred until the Phase 2 services actually exist.
- **PASS** — public multiplayer security/scalability checklist is recorded as a hard future release gate.

## Not executable in generation environment

The environment used to assemble this repository does not contain a Godot executable or Docker daemon. Therefore the following are explicitly **not** marked as passed:

- GDScript parse/import through the actual Godot engine;
- Godot headless logic test;
- interactive First Playable manual test;
- Windows/Linux export launch;
- Web export execution;
- `docker build` and browser runtime test.

These remain the Phase 1 acceptance gate documented in `PROJECT_STATE.md` and `docs/MANUAL_TEST_PLAN.md`.
