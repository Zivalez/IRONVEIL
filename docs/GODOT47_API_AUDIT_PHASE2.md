# Godot 4.7 API Audit — Phase 2

**Date:** 2026-08-16

## Trigger

Dokploy's Godot 4.7.1 compile gate reported:

```text
res://scripts/ui/hud.gd:598
Cannot find member "upper" in base "String"
Function "upper()" not found in base String
```

## Fix

```gdscript
# invalid
boss_name_label.text = name.upper()

# Godot 4.7
boss_name_label.text = name.to_upper()
```

## Repository-wide audit

All `scripts/**/*.gd` files were scanned for common foreign-language String APIs that are easy to accidentally write in GDScript:

- `.upper()` → use `.to_upper()`
- `.lower()` → use `.to_lower()`
- `.startswith()` → use `.begins_with()`
- `.endswith()` → use `.ends_with()`
- `.strip()` → use `.strip_edges()`
- `.splitlines()` → use `.split("\n")` or another explicit delimiter strategy

No remaining occurrences were found after the fix.

`String.lstrip(chars)` and `String.rstrip(chars)` are valid Godot 4.7 methods and are intentionally **not** rejected by the validator.

## CI hardening

`tools/validate_project.py` now has a high-confidence preflight guard for the invalid calls above. This is supplemental only: the normal-scene Godot CI runner in `scenes/tests/ci_runner.tscn` remains the authoritative GDScript compile/runtime gate during Docker build.

## Local checks performed

```text
python3 tools/validate_project.py
→ IRONVEIL STATIC VALIDATION: PASS

python3 tools/test_lobby_contract.py
→ IRONVEIL LOBBY CONTRACT: PASS

python3 -m py_compile services/lobby/lobby.py tools/validate_project.py tools/test_lobby_contract.py
→ PASS
```

Godot 4.7.1 and Docker are not executable in this source-generation environment, so the next Dokploy build remains the engine-level acceptance test.
