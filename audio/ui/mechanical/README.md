# UI SFX — mechanical pack

IRONVEIL maps its interface semantic cues through `scripts/core/audio_manager.gd` to the
**mechanical** pack from `romainsimon/uisfx`.

Expected Ogg assets in this directory:

- `hover.ogg`
- `press.ogg`
- `complete.ogg`
- `error.ogg`
- `toggle-on.ogg`
- `toggle-off.ogg`
- `open.ogg`
- `close.ogg`

Upstream audio is CC0 1.0. The source repository is:
`https://github.com/romainsimon/uisfx`

The game intentionally treats these as UI/interface SFX only. World audio (gear grinding,
motor hum, steam, impact, ambience) is a separate content track, matching the master prompt.
