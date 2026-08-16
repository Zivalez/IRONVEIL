# Dokploy redeploy for IRONVEIL 1.2.0

## Important

A `.patch` file stored in the repository does not change the game. Apply the
patch to the source, or overwrite the repository with the complete 1.2.0 source,
then commit the changed source files.

## Apply the patch

From the repository root:

```bash
git apply --check IRONVEIL_1.1.0_TO_1.2.0.patch
git apply IRONVEIL_1.1.0_TO_1.2.0.patch
git add -A
git commit -m "upgrade IRONVEIL to 1.2.0"
git push
```

Do not use `git add IRONVEIL_1.1.0_TO_1.2.0.patch` as the update step. That only
stores the instructions without applying them.

## Dokploy

Use `docker-compose.phase3.yml`. Attach `ironveil.zvlz.dev` to the `client`
service on container port `80`. Keep these production values:

```dotenv
PUBLIC_MODE=true
TRUST_PROXY_HEADERS=true
ALLOWED_ORIGIN=https://ironveil.zvlz.dev
PUBLIC_WS_URL=wss://ironveil.zvlz.dev/room-ws
ROOM_TOKEN_SECRET=replace-with-at-least-32-random-characters
```

Redeploy with a fresh image build. After deployment, `/build-info` must report
build `1.2.0`, and `/api/health` must return JSON with `"ok": true`.

If the browser still shows an older UI after `/build-info` says `1.2.0`, clear
site data once and reload. Build 1.2.0 itself prevents old API URLs from being
used again.
