# PHASE 2/3 SECURITY & SCALABILITY CONTRACT

> Source of truth: `IRONVEIL_MASTER_PROMPT.md` §4.5, §6 and §10.  
> **Current status:** Phase 2 safety envelope is implemented in source and lobby contract-tested where possible. Public multiplayer remains blocked until WSS, stress, multi-client, restart and checkpoint-recovery tests pass on the real deployment.

## Implementation matrix

| Control | Source status | Runtime status |
|---|---|---|
| Max 4 players/room | Implemented in lobby + room server | Lobby contract PASS; Godot room runtime pending |
| Configurable active-room cap | Implemented | Lobby contract PASS; room-server runtime pending |
| CPU/RAM ceilings | Present in Phase 2 Compose | Needs VPS profiling/stress validation |
| Create-room rate limit | Implemented in lobby | Contract path covered; production tuning pending |
| Wrong-password limit | Implemented in lobby | Contract PASS |
| Server-side password validation | Implemented, PBKDF2 hash persisted | Contract PASS |
| Room/player name sanitization | Implemented in lobby | Contract PASS |
| Short-lived signed join tickets | HMAC-SHA256 implemented | Godot authentication handshake runtime pending |
| Public WSS | Configuration path documented | **Not yet verified** |
| Restart policy | `unless-stopped` in Compose | Forced restart test pending |
| Periodic checkpoint | Room server every ~30s | Force-crash recovery pending |
| Structured logs | Lobby + room events | Operational review pending |
| Full gameplay server authority | Partial only | **Not complete** |

## Capacity contract

### Players per room

Hard maximum: **4 players**. This is enforced in both the lobby reservation layer and the Godot room server; UI is not the enforcement boundary.

### Active rooms

Deployment-configurable:

```text
MAX_ACTIVE_ROOMS=<profiled capacity>
```

When capacity is reached the lobby rejects creation with a clear `server_capacity_reached` response rather than overcommitting the VPS.

### Resource ceilings

`docker-compose.phase2.yml` currently supplies initial testing limits:

```text
lobby       128 MB / 0.25 CPU
room-server 768 MB / 1.0 CPU
```

These are test ceilings, not production sizing. Profile the actual factory/multiplayer simulation before choosing final values.

## Anti-abuse contract

### Create-room endpoint

Per-source-IP rate limit is enabled and configurable through:

```text
CREATE_ROOM_LIMIT_PER_MINUTE
```

### Password attempts

Wrong password attempts are limited per IP + room. Default Phase 2 configuration follows the master prompt baseline:

```text
PASSWORD_ATTEMPTS_PER_MINUTE=5
```

Room passwords are truncated to a bounded input length, hashed with PBKDF2 for persistence, validated server-side, and never returned in room listings or structured logs.

### Public text fields

Lobby sanitizes and bounds room names and player names. Client-side display-name truncation exists for UX, but server-side sanitation is authoritative for lobby-visible strings.

## Join-ticket boundary

Lobby and room server share a strong deployment secret:

```text
ROOM_TOKEN_SECRET=<long random value>
```

Lobby issues a short-lived HMAC-SHA256 ticket containing room ID, sanitized player name, expiration and nonce. Room server verifies signature and expiration before calling SceneMultiplayer authentication completion.

Compose intentionally refuses to start without `ROOM_TOKEN_SECRET` rather than silently using the development fallback.

## Transport contract

Local development:

```text
http://client
http://lobby
ws://room
```

Public deployment:

```text
HTTPS Web client
      │
      ├── HTTPS → lobby
      │
      └── WSS ──→ Dokploy/Traefik ──→ Godot room server
```

The public `PUBLIC_WS_URL` must be `wss://...`. The reverse proxy must preserve WebSocket upgrade semantics and use timeouts appropriate for persistent game connections.

A successful initial handshake is insufficient: test an actual gameplay connection for long enough to expose idle/read timeout problems.

## Resilience contract

### Restart

Lobby and room server use `restart: unless-stopped` in the Phase 2 Compose file.

### Checkpoints

Room server writes `room_server_checkpoint.json` approximately every 30 seconds and restores it on boot. Current checkpoint scope covers shared room flags. It must expand alongside authority migration so all authoritative inventory/factory/combat/world state needed to reconstruct a room survives a crash.

Required validation before public release:

```text
create room
→ alter authoritative state
→ wait for checkpoint
→ force-kill room server
→ verify automatic restart
→ reconnect
→ verify state restored
```

### Logging

Structured logs currently cover room/lobby startup, room creation, password failures/lockout, auth rejection, joins/disconnects and checkpoint outcomes. Do not log plaintext room passwords or the shared HMAC secret.

## Authority warning

The master prompt requires server-authoritative simulation. The current Phase 2 candidate is **not yet fully authoritative**:

- room membership/authentication: server-owned;
- movement: server-clamped and rebroadcast;
- shared vertical-slice flags: server-routed;
- inventory/survival/machine queues/general enemy simulation: authority migration still pending; Furnace Saint health/window is authoritative on the room server.

Do not expose public co-op or make anti-cheat claims until the co-op-sensitive gameplay state is actually owned/validated by the room server.

## Horizontal scaling boundary

Multiple room-server hosts/load balancing are outside Phase 1–2 scope. Current APIs should remain routable later, but no distributed orchestrator is required yet.

## Public Multiplayer Release Checklist

- [x] Max 4 player rule exists in lobby and room-server source.
- [x] Active-room cap is configurable in source/deployment.
- [x] CPU/memory limits exist in Compose.
- [x] Create-room limiter exists.
- [x] Password-attempt limiter exists and contract test passes.
- [x] Room/player names are sanitized/bounded server-side.
- [x] Plaintext room passwords are not exposed by public listing/log contract.
- [ ] Full co-op-sensitive simulation is server-authoritative.
- [ ] Public clients use HTTPS lobby + WSS room endpoint.
- [ ] Traefik/Dokploy WebSocket upgrade + long-lived timeout verified.
- [ ] Fifth connected Godot client is rejected in real room-server test.
- [ ] Resource ceilings verified under deliberate stress.
- [ ] Room server automatic restart verified.
- [ ] Periodic checkpoint observed in real room runtime.
- [ ] Forced-crash recovery restores authoritative state.
- [ ] Operational logs are reviewed and sufficient for incident debugging.

Until every required public-release item passes, co-op is private/limited testing only.
