# SuperKore OpenKore plugin: `pilotLive`

Logs:

1. `Your Coordinates` / `พิกัดของคุณคือ` whenever the character cell changes so Pilot Live can move the marker while walking. OpenKore only prints coords on map enter by default.
2. `PilotStatus: HP … SP … Base … Job … Zeny …` whenever HP/SP/levels/zeny change (throttled to ~1s) so Pilot Live meta can show vitals.
3. `PilotAI: idle|moving|attacking [target]` whenever AI state/target changes (throttled to ~1s) so Live meta/marker reflect idle / moving / attacking.

Pilot Log tab filters PilotStatus / PilotAI / coord spam out; Live reads the raw log.

## Install

Pilot UI installs this automatically on bot start (`ensurePilotLivePlugin`). Manual install:

1. Copy this folder to `<openkore>/plugins/pilotLive/`
2. In `control/sys.txt`, append `pilotLive` to `loadPlugins_list`
