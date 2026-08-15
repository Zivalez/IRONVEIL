# Web Deployment Troubleshooting

## Symptom: Godot splash appears, then canvas stays black

The splash proves that the HTML shell is reachable and the Web boot sequence has started. It does not prove that the gameplay scene initialized successfully.

### Protections in this revision

1. `export_presets.cfg` includes `*.json` so the data-driven catalogs are present in Web exports.
2. Docker runs Godot `--import` before export.
3. Docker runs `scripts/tests/run_headless_tests.gd`; parser/test failure stops the image build.
4. `scenes/boot.tscn` is the project entry scene. It loads the gameplay scene dynamically and keeps a visible diagnostic overlay if the gameplay scene, player, or camera fails to initialize.
5. nginx revalidates `index.js`, `index.wasm`, and `index.pck` instead of caching those fixed filenames as immutable.

## After redeploy

Use a hard refresh once (`Ctrl+Shift+R`) or clear site data for the domain. This is especially important after deploying a build created before the cache-policy fix.

If startup still fails, the page should now show an `IRONVEIL // BOOT SEQUENCE` failure message rather than an empty black canvas. Open browser DevTools → Console and copy the **first** Godot error; later errors are often secondary symptoms.
