# PHASE 2 NETWORK ARCHITECTURE — DESIGN ONLY

> This document records the seam prepared by Phase 1. It is **not** evidence that Phase 2 has been implemented.
>
> Security/scalability requirements are defined in `docs/PHASE2_SECURITY_SCALABILITY.md` and `IRONVEIL_MASTER_PROMPT.md` §4.5.

## Components

1. Web/native client using `WebSocketMultiplayerPeer` for Web-compatible transport.
2. Headless Godot authoritative room server.
3. Lightweight lobby service for create/list/join room operations and server-side password validation.

## Authority

Room server owns:

- simulation tick;
- inventory/survival mutation;
- mechanical network;
- enemies/NPC simulation;
- authoritative item/machine world state;
- room membership and the hard four-player limit.

Client owns only presentation and local input intent.

## Replication Interest

Reuse `ChunkManager`:

```text
FULL          → frequent entity/state replication
SIMPLIFIED    → lower-rate summaries
STATISTICAL   → no high-frequency entity broadcast
```

Exact rates should be profiled during Phase 2, not guessed now.

## Room Contract

The lobby/room layer must enforce server-side:

- maximum **4 players per room**;
- deployment-configurable active-room capacity;
- public/private visibility;
- optional password validation;
- sanitized/bounded room and player names.

If server capacity is exhausted, room creation is rejected cleanly instead of spawning another process.

## Room Password Rule

Password is a gameplay access gate:

- validated only server-side;
- never returned in public room listing;
- never logged in plaintext;
- no client-side-only validation;
- no unnecessary identity/auth subsystem added solely for room passwords;
- wrong attempts become rate-limited/locked out before public release.

## Web Transport

Development may connect directly to a local WebSocket endpoint. Public deployment from an HTTPS page must use **WSS** and Dokploy/Traefik must preserve WebSocket upgrade semantics and a timeout appropriate for persistent game connections.

## Process Resilience

Each authoritative room process/container must eventually have:

- explicit CPU/RAM limits;
- automatic restart behavior;
- periodic authoritative-state checkpoints;
- lifecycle/error/disconnect logging.

A restart without checkpoint recovery is not sufficient for public readiness.

## Deployment Evolution

### Current Phase 1

Use Dokploy **Application** → root `Dockerfile` → Godot Web export → nginx port 80.

### Phase 2+

The game becomes a multi-service deployment (client + room server + lobby). Compose or separate Dokploy Applications may be used when those services actually exist. Do not add a fake multi-service deployment to Phase 1.

## Implementation Gate

Begin actual multiplayer implementation only after every Phase 1 runtime item in `PROJECT_STATE.md` is verified.

Before public rooms are enabled, additionally pass every item in `docs/PHASE2_SECURITY_SCALABILITY.md`'s Public Multiplayer Release Checklist.
