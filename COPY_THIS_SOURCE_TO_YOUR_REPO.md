# Copy this source to your repository

This folder contains the complete IRONVEIL 1.3.0 source and all cumulative
updates. No patch command is required.

1. Copy every item inside this folder.
2. Paste into the root of the existing IRONVEIL Git repository.
3. Replace files with the same names.
4. Run:

```bash
git add -A
git commit -m "upgrade IRONVEIL to 1.3.0"
git push
```

Rebuild the Compose application in Dokploy without deleting the lobby volume.
The existing volume contains account and world data that build 1.3.0 repairs
during startup.
