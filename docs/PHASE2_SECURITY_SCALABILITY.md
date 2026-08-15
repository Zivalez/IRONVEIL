# PHASE 2/3 SECURITY & SCALABILITY CONTRACT — DESIGN GATE

> Source of truth: `IRONVEIL_MASTER_PROMPT.md` §4.5, §6 and §10.
>
> This document is an implementation contract for later phases. It is **not evidence that public multiplayer security is already implemented in Phase 1**.

## Why this exists

Server-authoritative gameplay protects authoritative game state from client-side tampering, but it does not by itself protect the VPS from room spam, password brute force, runaway room processes, connection abuse, or progress loss after a room-server crash.

The multiplayer stack must therefore add explicit capacity, abuse, transport, and resilience controls before public rooms are enabled.

## Phase ownership

### Phase 1 — current repository

Prepare architectural seams only:

- simulation state is independent from rendering/input;
- `ChunkManager` can become multiplayer interest management;
- persistence already exists for the prototype simulation state;
- no lobby endpoint, room process, rate limiter, WSS endpoint, or public multiplayer UI is claimed as implemented.

### Phase 2 — vertical slice multiplayer

Implement the basic multiplayer safety envelope together with the room server:

- server-enforced `MAX_PLAYERS_PER_ROOM = 4`;
- configurable maximum number of active rooms;
- CPU and memory limits for each room-server container/process;
- room/player name sanitization and length bounds;
- server-side room-password validation;
- restart policy for room server;
- periodic room checkpoint/persistence;
- structured lifecycle/error/disconnect logging;
- Web client connects through WebSocket-compatible transport;
- production deployment path prepared for WSS through Dokploy/Traefik.

For friend-only/internal testing, rate-limit values may still be tuned during Phase 2, but bypassing the server-enforced player/room/resource limits is not acceptable.

### Phase 3 — public limited deployment gate

Before public co-op rooms are enabled, all of the following must be operational and tested:

- create-room rate limiting;
- wrong-password attempt rate limiting/temporary lockout;
- WSS only for the public HTTPS origin;
- reverse proxy verified to preserve WebSocket upgrade and long-lived connections;
- room capacity rejection returns a clear "server full" response;
- resource limits verified under a deliberately stressed room;
- automatic restart verified;
- checkpoint recovery verified after a forced room-server crash;
- logging is sufficient to identify room creation/closure, server errors, and abnormal disconnects.

## Capacity contract

### Players per room

Hard maximum: **4 players**.

This value must be enforced in authoritative server code. UI may display the limit, but UI is not an enforcement boundary.

### Active room capacity

The lobby service must expose a deployment-configurable room cap, for example:

```text
MAX_ACTIVE_ROOMS=<deployment-specific value>
```

The repository must not hardcode an arbitrary production room count because the correct value depends on VPS CPU/RAM and profiling of the actual simulation.

When the limit is reached:

```text
create_room → reject
reason      → server_capacity_reached
```

Never create rooms until the VPS becomes unstable.

### Room process resources

Every room-server deployment must have explicit CPU and memory ceilings in Docker/Dokploy. Exact values are chosen from profiling, not guessed in Phase 1.

Resource limits protect other rooms from a runaway simulation or infinite loop; they do not replace profiling and optimization.

## Anti-abuse contract

### Create-room endpoint

Rate limit per source IP. The exact Phase 3 production value is tunable/configurable, but the limiter itself is mandatory before public room creation.

Expected behavior:

```text
within allowance  → create request evaluated normally
limit exceeded    → HTTP 429 / equivalent application error
```

### Password attempts

Room passwords remain a lightweight gameplay access gate, but attempts must be limited server-side.

Baseline from the master prompt:

```text
maximum wrong attempts ≈ 5 / room / minute / IP
```

Treat the number as configuration, while preserving the actual protection. Never return the room password in a listing or error.

### Public text fields

At minimum sanitize and bound:

- room name;
- player display name.

Validation rules must be shared by server-side lobby logic. The client may pre-validate for UX, but the server re-validates every request.

## Transport contract

### Public deployment

```text
HTTPS Web client
      │
      ▼
     WSS
      │
      ▼
Dokploy / Traefik
      │ WebSocket upgrade + long-lived timeout
      ▼
Godot authoritative room server
```

A page served over HTTPS must not depend on `ws://` in production. Public configuration must generate/use `wss://` endpoints.

Reverse-proxy validation must include a connection kept open long enough to catch idle/read timeout problems, not only a successful initial handshake.

## Resilience contract

### Restart policy

Room server uses Docker/Dokploy restart behavior such as `on-failure` or `unless-stopped` as appropriate for the final room-process model.

### Checkpoints

A room process periodically persists authoritative room state. At minimum the future checkpoint must cover the state required to reconstruct the active world/base/factory for that room.

A crash-recovery test is mandatory before public deployment:

```text
create room
→ alter persistent world state
→ checkpoint
→ force-kill room server
→ restart/recover
→ verify state is restored
```

### Logging

At minimum record structured events for:

- room created;
- room closed;
- room capacity rejection;
- join/disconnect;
- repeated password failures / lockout;
- checkpoint success/failure;
- server/runtime error;
- abnormal disconnect.

Do not log plaintext room passwords.

## Dokploy topology

### Phase 1

Use a Dokploy **Application** with the root `Dockerfile`. It builds the Godot Web client and serves it through nginx on port 80.

### Phase 2+

The deployment becomes multi-service: Web client, authoritative room server(s), and lobby service. At that point use either Dokploy Compose or separately managed Dokploy applications if operationally cleaner, but keep service isolation and resource limits explicit.

Do not introduce a Phase 2 Compose stack into the Phase 1 branch merely to look production-ready. The running services must exist before their deployment manifest becomes authoritative.

## Horizontal scaling boundary

Horizontal scaling across multiple room-server hosts/load-balanced capacity is explicitly outside Phase 1-2 scope. The lobby design must avoid assumptions that make later multi-host routing impossible, but no distributed orchestrator is required yet.

## Public Multiplayer Release Checklist

- [ ] Max 4 players is enforced on the server.
- [ ] Active-room cap is configurable and enforced.
- [ ] Room CPU/memory limits are configured.
- [ ] Create-room rate limiting is enabled.
- [ ] Password-attempt rate limiting/lockout is enabled.
- [ ] Room/player names are sanitized and length-limited server-side.
- [ ] Public clients use WSS.
- [ ] Traefik/Dokploy WebSocket upgrade + timeout behavior is verified.
- [ ] Room server restart behavior is verified.
- [ ] Periodic checkpoints are enabled.
- [ ] Forced-crash recovery restores a checkpoint.
- [ ] Lifecycle/error/disconnect logs are available.
- [ ] Plaintext room passwords are never exposed/logged.

Until every public-release item above passes, co-op may be used only in the limited testing scope allowed by the roadmap; it must not be described as production-public-ready.
