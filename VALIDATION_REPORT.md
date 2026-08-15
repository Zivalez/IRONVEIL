# Validation Report — Full Phase 1 Audit

**Date:** 2026-08-16

## Local source checks

- `python3 tools/validate_project.py`: **PASS**
- Python helper scripts compile with `py_compile`: **PASS**
- Latest uploaded `IRONVEIL_MASTER_PROMPT.md` SHA-256 matches the repo copy: **PASS**
- All runtime GDScript files are covered by `scripts/tests/compile_all.gd`: **PASS**
- Project/autoload/scene `res://` references exist: **PASS**
- JSON catalogs parse and have unique IDs: **PASS**
- Recipe/machine/enemy/biome item references are valid: **PASS**
- Milestone-1 fixed resource supply is sufficient: **PASS**
- Mechanical reference chain (32 RPM / 120 Nm → 3:1 @ 90% → belt @ 95% → saw @ 92%) remains above saw minimum torque: **PASS**
- Known dangerous `:=` Variant-inference patterns: **none detected**
- Web preset explicitly includes JSON catalogs and disables threads: **PASS**
- nginx WASM/PCK MIME + non-immutable fixed-payload cache policy: **PASS**
- Docker build order includes all-script compile gate before runtime smoke test before Web export: **PASS**

## Godot/Docker runtime gates configured

The next Docker build must print:

```text
IRONVEIL ALL-SCRIPT COMPILE GATE: PASS
IRONVEIL HEADLESS TESTS: PASS
```

The runtime smoke test now starts from `boot.tscn` (the actual project main scene), not directly from `main.tscn`.

## Pending real-runtime verification

This environment has neither the Godot executable nor Docker daemon. Therefore the following remain pending until Dokploy executes the audited repository:

- Godot 4.7.1 all-script compile gate actual result;
- boot/main scene headless smoke test actual result;
- Godot Web export actual result;
- container startup/healthcheck;
- browser rendering and end-to-end First Playable gameplay.

Static validation is intentionally not represented as runtime completion.
