# Web Deployment Troubleshooting

## Symptom: Godot splash appears, then canvas stays black

The splash proves that the HTML shell is reachable and the Web boot sequence has started. It does not prove that the gameplay scene initialized successfully.

### Protections in this revision

1. `export_presets.cfg` includes `*.json` so the data-driven catalogs are present in Web exports.
2. Docker runs Godot `--import` before export.
3. Docker runs `scripts/tests/compile_all.gd` first. Every runtime script is loaded independently, dependency-first, so the failing script is no longer hidden behind another script's `preload()`.
4. Docker then runs `scripts/tests/run_headless_tests.gd`, which tests the mechanical solver and instantiates `main.tscn` in headless mode; parser/runtime smoke-test failure stops the image build.
5. `scenes/boot.tscn` is the project entry scene. It loads the gameplay scene dynamically and keeps a visible diagnostic overlay if the gameplay scene, player, or camera fails to initialize.
6. nginx revalidates `index.js`, `index.wasm`, and `index.pck` instead of caching those fixed filenames as immutable.

## After redeploy

Use a hard refresh once (`Ctrl+Shift+R`) or clear site data for the domain. This is especially important after deploying a build created before the cache-policy fix.

If startup still fails, the page should now show an `IRONVEIL // BOOT SEQUENCE` failure message rather than an empty black canvas. Open browser DevTools → Console and copy the **first** Godot error; later errors are often secondary symptoms.


## Expected successful Docker markers

Before Web export, the log should contain both:

```text
IRONVEIL ALL-SCRIPT COMPILE GATE: PASS
IRONVEIL HEADLESS TESTS: PASS
```

If the first marker is absent, fix the first `IRONVEIL_COMPILE_CHECK` resource that Godot reports as invalid. If the compile marker passes but the runtime marker fails, the parser is no longer the problem; use the named smoke-test failure to diagnose startup/game-state integration.
