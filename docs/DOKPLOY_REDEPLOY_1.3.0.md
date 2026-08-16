# Dokploy redeploy for IRONVEIL 1.3.0

## Copy workflow

Copy every file and folder from `IRONVEIL_SOURCE_COMPLETE_1.3.0` into the root
of the existing Git repository. Replace files with the same name, then run:

```bash
git add -A
git commit -m "upgrade IRONVEIL to 1.3.0"
git push
```

No patch command is required.

## Deploy

Rebuild `docker-compose.phase3.yml` with a fresh image. Keep
`ironveil.zvlz.dev` attached to the `client` service on container port `80`.
The lobby volume must remain attached so existing account and world data can be
migrated rather than discarded.

After the lobby restarts, it repairs owned worlds that were counted by the
limit but missing from the account membership list. Those worlds will become
visible again in the archive.

Verify `https://ironveil.zvlz.dev/build-info` reports build `1.3.0`.
