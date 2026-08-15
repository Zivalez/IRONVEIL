# Dokploy — IRONVEIL production

## `ironveil.zvlz.dev` (recommended single-domain layout)

Deploy `docker-compose.phase3.yml`, then attach the public HTTPS domain
`ironveil.zvlz.dev` to the **client** service on container port `80`. Do not
publish separate public domains for the lobby or room server: the bundled
nginx forwards `/api/*` to `lobby:8080` and `/room-ws` to
`room-server:9081` inside the Compose network.

Copy `.env.phase3.example` to `.env.phase3` (or enter the same values in
Dokploy) and replace `ROOM_TOKEN_SECRET` with one cryptographically random
secret of at least 32 characters. The same value is injected into lobby and
room-server by Compose.

Required production values:

```text
PUBLIC_MODE=true
ROOM_TOKEN_SECRET=<random 32+ character secret>
PUBLIC_WS_URL=wss://ironveil.zvlz.dev/room-ws
ALLOWED_ORIGIN=https://ironveil.zvlz.dev
TRUST_PROXY_HEADERS=true
```

After deployment, `https://ironveil.zvlz.dev/api/health` must return HTTP 200.
Account requests use `https://ironveil.zvlz.dev/api/auth/register`; they never
use the visitor's `127.0.0.1`.

## Local/private test

```bash
cp .env.phase3.example .env.phase3
docker compose --env-file .env.phase3 -f docker-compose.phase3.yml up --build
```

Defaults:

- client: `http://127.0.0.1:8080`
- lobby: `http://127.0.0.1:8081`
- room server: `ws://127.0.0.1:9081`

## Public deployment on another domain

Set all of the following before enabling public co-op:

```text
PUBLIC_MODE=true
ROOM_TOKEN_SECRET=<long random 32+ char secret>
PUBLIC_WS_URL=wss://<room-domain>
ALLOWED_ORIGIN=https://<game-domain>
TRUST_PROXY_HEADERS=true
MAX_ACTIVE_ROOMS=<profiled capacity>
```

`PUBLIC_MODE=true` deliberately makes the lobby fail startup if the join endpoint is not `wss://`, if the allowed origin is wildcard/non-HTTPS, or if the room-token secret is weak. The room server also rejects weak secrets in public mode.

Dokploy/Traefik must terminate TLS for the room domain, preserve WebSocket Upgrade/Connection headers and use a long-lived timeout appropriate for game sessions. Internal room traffic may remain plain WS behind the trusted reverse proxy; the browser-facing endpoint must be WSS.

## Resource isolation / resilience

`docker-compose.phase3.yml` keeps explicit CPU/RAM ceilings and `restart: unless-stopped`. Room shared state is checkpointed periodically by the headless Godot server. Force-crash/restart restore is an acceptance test, not assumed merely because the files exist.

## Do not open public co-op until

- fifth client is rejected server-side;
- create/join abuse limits are verified through the public proxy;
- WSS remains connected for a long play session;
- forced room-server crash restarts and restores a valid checkpoint;
- 2–4 clients complete the MVP route without major shared-state divergence;
- server authority debt listed in `PROJECT_STATE.md` is resolved or explicitly scoped out of the public test.
