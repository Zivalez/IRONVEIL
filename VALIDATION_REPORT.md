# VALIDATION REPORT — Phase 2 Candidate

**Date:** 2026-08-16

## Passed in this environment

```text
python tools/validate_project.py
→ IRONVEIL STATIC VALIDATION: PASS

python tools/test_lobby_contract.py
→ IRONVEIL LOBBY CONTRACT: PASS

python -m py_compile services/lobby/lobby.py
→ PASS
```

The lobby contract test starts the actual lobby HTTP server on an ephemeral local port and verifies:

- health endpoint;
- public room create/list;
- room/player sanitization;
- password not exposed in listing;
- incorrect password rejection;
- incorrect-password rate lockout;
- correct password join ticket;
- four-player reservation cap and fifth join rejection;
- private room omitted from listing but joinable by invite room ID;
- active-room capacity rejection.

The static validator checks data cross-references, critical resource economy, master-prompt security terms, Web export/Docker contract, runtime-script CI coverage, autoload order, resource paths, known Godot 4.7 Variant-inference hazards and Phase 2 world/network/visual contracts.

## Not executable in this environment

The environment does not currently provide a runnable Godot 4.7.1 binary or Docker daemon. Therefore these remain **unverified**, not silently marked PASS:

- Godot import/compile of every GDScript;
- `scenes/tests/ci_runner.tscn` runtime gate;
- Web export artifact creation;
- client Docker image build;
- room-server Docker image build;
- browser rendering/input;
- 2–4 player WebSocket synchronization;
- WSS through Dokploy/Traefik;
- forced crash/checkpoint recovery.

The Dockerfiles are structured to make the real Godot CI gate run before export/server startup so the next Dokploy build is the authoritative engine-level validation.
