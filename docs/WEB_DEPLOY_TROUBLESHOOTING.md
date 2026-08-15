# Web Deployment Troubleshooting

## Symptom: Godot splash appears, then canvas stays black

The splash only proves that the HTML/WASM shell started. It does **not** prove that gameplay scripts, autoloads, JSON catalogs, player/camera creation, or the main scene initialized successfully.

## Why the earlier CI revisions produced confusing failures

The production project correctly declares these autoloads in `project.godot`:

- `DataRegistry`
- `TickManager`
- `ChunkManager`
- `SettingsManager`
- `GameState`
- `SaveManager`
- `AudioManager`

The mistake was in the test lifecycle. Earlier Docker revisions invoked `compile_all.gd` and `run_headless_tests.gd` with `godot --script`. That execution path does not reproduce the normal project-scene lifecycle that installs project autoload singletons before gameplay scenes. Production scripts therefore reported `Identifier not found: GameState/TickManager/...` inside CI even though the singleton declarations themselves existed.

The compile gate also relied too heavily on `ResourceLoader.load()` return values, so it could print a misleading PASS while Godot had already emitted script-load errors.

## Current protections

1. `export_presets.cfg` explicitly includes `*.json` in Web, Windows, and Linux exports.
2. Docker removes any stale `.godot` cache and runs Godot `--import` first.
3. CI is launched as a normal scene:

   ```bash
   godot --headless --path . res://scenes/tests/ci_runner.tscn
   ```

4. `ci_runner.tscn` first asserts that every required autoload is present under `/root`.
5. It then loads every runtime `.gd` and both production scenes.
6. It validates every data catalog both from disk and through the live `DataRegistry` autoload.
7. It tests the mechanical solver numerically.
8. It instantiates **`boot.tscn`**, the exact native/Web entry scene, then requires:
   - `main.tscn` attached;
   - player present;
   - active `Camera3D` present;
   - water-wheel graph source registered;
   - mechanical-saw consumer registered.
9. Any failure is accumulated and `SceneTree.quit(1)` is used. PASS is printed only if the failure list is empty.
10. Only after this gate passes does Docker perform the Web export and verify non-empty `index.html`, `index.js`, `index.wasm`, and `index.pck`.
11. nginx revalidates the fixed-name Godot payload files instead of caching them as immutable.

## Expected successful Docker markers

Before Web export, the log must contain:

```text
IRONVEIL CI: normal-scene lifecycle started
IRONVEIL_AUTOLOAD_OK: DataRegistry
IRONVEIL_AUTOLOAD_OK: TickManager
...
IRONVEIL ALL-SCRIPT COMPILE GATE: PASS
IRONVEIL HEADLESS TESTS: PASS
```

Then the Web export runs.

If an autoload is absent, the first failure will explicitly say `Autoload singleton missing at runtime: ...`.

If a script or scene cannot compile/load, the corresponding `IRONVEIL_COMPILE_CHECK` / `IRONVEIL_SCENE_CHECK` entry identifies it.

If compile/load succeeds but startup integration fails, the boot smoke-test assertion identifies the missing invariant.

## After redeploy

Use a hard refresh once (`Ctrl+Shift+R`) or clear site data for the domain. This is especially important if the browser previously received an older fixed-name PCK/WASM payload.

If the Docker gate passes but the browser still fails, open DevTools → Console and copy the **first** Godot error. The on-canvas `IRONVEIL // BOOT SEQUENCE` overlay is also designed to remain visible if gameplay, player, or camera startup fails.
