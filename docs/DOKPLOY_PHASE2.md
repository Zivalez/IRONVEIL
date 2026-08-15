# DOKPLOY — Phase 2 Private Co-op Deployment

Phase 2 introduces three services. Keep the existing single Web client deploy intact until the multi-service stack has passed private testing.

## Recommended private-test endpoints

Use three subdomains (names are examples):

```text
game.example.com   → client/nginx port 80
lobby.example.com  → lobby port 8080
room.example.com   → room-server port 9081 (WebSocket/WSS)
```

## Required environment

```text
ROOM_TOKEN_SECRET=<strong random secret, same for lobby + room server>
MAX_ACTIVE_ROOMS=<small value appropriate for private test, e.g. 4>
CREATE_ROOM_LIMIT_PER_MINUTE=6
PASSWORD_ATTEMPTS_PER_MINUTE=5
PUBLIC_WS_URL=wss://room.example.com
ALLOWED_ORIGIN=https://game.example.com
```

Do not use the development secret for Internet-facing testing.

## Deployment options

### Option A — Dokploy Compose

Use `docker-compose.phase2.yml`, configure environment values above, then attach domains/routes to the corresponding services.

### Option B — three Dokploy Applications

- client → root `Dockerfile`, port 80;
- lobby → `services/lobby/Dockerfile`, port 8080;
- room server → `Dockerfile.room`, port 9081.

This is operationally equivalent for the current Phase 2 architecture and can be easier if domain/WebSocket routing is clearer as separate Applications.

## Client configuration

Open the game:

```text
Esc → Network
```

Set Lobby API URL to:

```text
https://lobby.example.com
```

Press `N` to open the room terminal. The lobby returns `PUBLIC_WS_URL` in the signed join flow, so clients then connect to `wss://room.example.com`.

## First private test

1. One browser creates a public room.
2. Second browser lists and joins it.
3. Confirm both remote players move.
4. Repair Ashwick bridge on one client and confirm the shared flag appears on the other.
5. Repeat with 3 and 4 clients.
6. Attempt a fifth client; it must be rejected.
7. Create a private room, copy the room ID, and join from another browser using the invite-code field.
8. Keep the connection open through normal play to detect proxy timeout issues.

## Do not open public rooms yet

The current candidate still needs full gameplay authority migration and forced-crash/checkpoint verification. `docs/PHASE2_SECURITY_SCALABILITY.md` is the release gate.
