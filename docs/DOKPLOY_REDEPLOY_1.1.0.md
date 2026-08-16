# Dokploy redeploy verification — IRONVEIL 1.1.0

The repository must be deployed as a **Docker Compose** project, not as a
single Dockerfile application. Use branch `main`, repository root `/`, and
Compose file `docker-compose.phase3.yml`.

Required Dokploy environment values:

```text
PUBLIC_MODE=true
ROOM_TOKEN_SECRET=<one random secret, at least 32 characters>
PUBLIC_WS_URL=wss://ironveil.zvlz.dev/room-ws
ALLOWED_ORIGIN=https://ironveil.zvlz.dev
TRUST_PROXY_HEADERS=true
```

Attach `ironveil.zvlz.dev` to the `client` service on container port `80`.
The public domain must not point directly at `lobby` or `room-server`.

After a push, trigger a new build/redeploy. Restarting the existing container
does not fetch the commit or rebuild the Web export. If the platform offers a
build-cache toggle, clear/disable it for this migration.

Acceptance endpoints:

```text
GET https://ironveil.zvlz.dev/build-info
GET https://ironveil.zvlz.dev/api/health
```

The first endpoint must report build `1.1.0` and input `desktop-touch`. The
second must return an `ok: true` JSON object. If either URL serves the game
HTML/canvas, the running client container still uses an old nginx image.
