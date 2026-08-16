# Copy this source to your repository

This folder already contains the complete IRONVEIL 1.2.0 source and every
cumulative update. You do not need to apply a patch.

1. Open `IRONVEIL_SOURCE_COMPLETE_1.2.0`.
2. Copy every file and folder inside it.
3. Paste them into the root of the existing IRONVEIL Git repository.
4. Choose replace or overwrite for files with the same names.
5. Commit and push:

```bash
git add -A
git commit -m "upgrade IRONVEIL to 1.2.0"
git push
```

In Dokploy, rebuild the Compose application with a fresh image. Verify
`https://ironveil.zvlz.dev/build-info` reports build `1.2.0`.
