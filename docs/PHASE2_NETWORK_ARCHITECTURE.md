# PHASE 2 NETWORK ARCHITECTURE

**Status:** implementation candidate; runtime/desync acceptance pending.

## Components

1. **Godot Web/native client** — presentation, local input, lobby UI and WebSocket client.
2. **Godot headless room server** — authenticated room membership, room limits, movement validation/replication, shared progression state and checkpoints.
3. **Python lobby service** — create/list/join API, public/private visibility, password validation, rate limits and HMAC join-ticket issuance.

## Current authority boundary

Implemented server-owned boundaries:

- membership and room routing;
- max 4 players/room;
- active room capacity;
- authentication ticket validation;
- server-clamped player position updates;
- room roster;
- shared bridge/Mara/gate/thermal/boss progression flags;
- room shared-state checkpoint.

Still requiring authority migration before Phase 2 acceptance:

- player inventory and survival;
- machine queues/output and full mechanical simulation;
- general enemy AI/combat damage;
- resource pickup ownership;
- authoritative live lobby presence.

Therefore this source must **not** be described as fully server-authoritative yet.

## Authentication

```text
Client → Lobby POST create/join
       ← short-lived HMAC join ticket + room id + websocket URL
Client → Room WebSocket
       → SceneMultiplayer auth payload(ticket)
Room server verifies HMAC + expiry + room capacity
       → complete_auth / reject
```

Lobby and room server share `ROOM_TOKEN_SECRET`; the secret is never sent to clients.

## Room modes

- **Public:** listed by `GET /rooms`.
- **Private:** absent from public listing; another player joins by room ID/invite code.
- Optional password is checked by lobby server only.

## Web transport

Local development can use `ws://`. Public HTTPS deployment requires:

```text
https://game.example
https://lobby.example
wss://room.example
```

Dokploy/Traefik must proxy WebSocket upgrades and preserve long-lived connections.

## Replication

Phase 2 movement updates use unreliable ordered channel 1. Shared progression uses reliable channel 2; roster uses reliable channel 3.

`ChunkManager` remains the intended foundation for future interest management:

```text
FULL          → high-frequency relevant entities
SIMPLIFIED    → lower-frequency summaries
STATISTICAL   → no high-frequency entity stream
```

## Persistence

Room server writes a checkpoint approximately every 30 seconds. Current checkpoint scope is room shared flags. As authority migration proceeds, the checkpoint must expand to every authoritative state required to reconstruct the active room.

## Acceptance tests

- 2 clients join and move without major jitter/desync.
- 4 clients join; fifth is rejected.
- private room joins by invite code.
- bridge/gate/thermal/boss progression reaches all connected peers.
- late join receives already-set shared flags.
- disconnect removes remote presentation.
- WSS connection survives normal idle/play duration through Dokploy.
- forced crash restarts server and restores valid checkpoint.
