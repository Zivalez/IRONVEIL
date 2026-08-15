# MANUAL TEST PLAN — Phase 1 First Playable

Run these checks before marking Milestone 1 complete.

## A. Boot / UI

1. Start the project outside the editor if testing an export.
2. Confirm the help panel appears.
3. Open Settings with `Esc`.
4. Change VSync, camera zoom, UI scale and audio values.
5. Restart the game and confirm values persist.

## B. Survival + Discovery

1. Spawn at the forest camp.
2. Observe hunger/thirst values changing over time.
3. Walk to the Wild Berries pickup and press `F`.
4. Press `1` to eat berries.
5. Confirm hunger/thirst increase and objective advances.
6. Walk to the abandoned workshop sign and inspect with `F`.
7. Open Journal with `J` and confirm Observation/Hypothesis entries appear.

## C. Mechanical First Playable

1. Collect at least **4 Scrap** total.
2. Interact with the broken water wheel.
3. Confirm 2 Scrap are consumed and the wheel begins rotating.
4. Press `C` to craft one Crude Gear from the remaining 2 Scrap.
5. Interact with the transmission assembly to install it.
6. Confirm its status reports approximately:
   - gearbox output ≈ 96 RPM;
   - torque remains positive after efficiency loss.
7. Collect Logs.
8. Interact with the mechanical saw to load logs into its queue.
9. Wait while the water wheel remains enabled.
10. Confirm the saw processes automatically without repeated craft input.
11. Confirm Planks appear in inventory/output and objective reaches FIRST PLAYABLE COMPLETE.

## D. Predictable Mechanical Failure

1. Save with `F5` while the saw has a queue.
2. Disable or break the upstream chain if using debug controls; alternatively remove connection in a debug session.
3. Confirm saw status changes to unpowered and processing stops.
4. Restore power and confirm processing resumes.
5. Verify no random failure occurs without an explainable simulation reason.

## E. Combat

1. Approach the hostile prototype enemy.
2. Confirm it detects/chases at its intended range.
3. Attack using `Space`.
4. Confirm attacks are range-limited and enemy health decreases.
5. Confirm enemy can damage player and defeated enemy drops a resource.

## F. Save / Load

1. Repair the water wheel.
2. Install the gear.
3. Queue one or more logs.
4. Save using `F5`.
5. Change state: move, collect/consume something, let output change.
6. Load using `F9`.
7. Confirm player position, inventory, survival, objective, journal, wheel/gear graph, saw queue/output and press queue/output are restored consistently.

## G. Native Exports

### Windows

```bash
godot --headless --path . --export-release "Windows Desktop" build/IRONVEIL.exe
```

Launch `build/IRONVEIL.exe` directly and repeat A-C.

### Linux

```bash
godot --headless --path . --export-release "Linux" build/IRONVEIL.x86_64
```

Launch directly and repeat A-C.

## H. Docker / Web

```bash
docker build -t ironveil:phase1 .
docker run --rm -p 8080:80 ironveil:phase1
```

In a browser:

1. Open `http://localhost:8080`.
2. Confirm no WASM/PCK MIME loading errors in DevTools.
3. Complete A-C again.
4. Confirm settings persistence works in Web storage.
5. Check camera/UI at common desktop resolutions.

## Pass Rule

**Do not begin Phase 2 until all checks above pass or every failure is resolved and re-tested.**
