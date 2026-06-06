# Level Flow

Task 15 adds a minimal playable loop to the browser-side JavaScript WAD bridge.
It does not add Doom episode progression, intermission screens, save/load,
pickups, keys, sound, or advanced line-special compatibility.

## Supported Exit

```text
901  synthetic use exit
```

The prototype treats linedef special `901` as a synthetic non-commercial exit
for fixture maps. Press `Space` while facing the line, or while standing within
the existing use distance of that exit line, to complete the level. The line
remains a normal wall for collision and rendering; it only changes the browser
game state when used.

In first-person mode, special `901` renders as a bright green wall segment and
the Canvas draws an `EXIT` marker over it when visible. The in-canvas HUD shows
`Find green EXIT wall; press Space.` until the player is close enough, then
switches to `Press Space at EXIT.` In top-down debug mode, special `901` is
drawn as a bright green line labeled `EXIT 901`.

The default bundled demo map is generated from:

```text
tests/wad_tests/exit_map_pwad.hex
```

Generate it locally with:

```bash
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7 --exit-map
```

The same fixture can be written to the browser asset path with:

```bash
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7 --exit-map web/assets/demo_map.pwad
```

## Level States

The browser bridge now uses these playable states:

- `playing`: player movement, firing, doors, and enemy AI are active.
- `paused`: movement, firing, doors, and enemy AI are frozen until resumed.
- `player_dead`: movement, use, firing, doors, and enemy AI are frozen until
  Reset.
- `level_complete`: movement, use, firing, doors, and enemy AI are frozen until
  Reset.

When `level_complete` is active, the renderer draws `LEVEL COMPLETE` inside the
Canvas playfield and the in-canvas HUD shows the level-complete state. Reset
restarts the current map from the player start, closes synthetic doors, restores
enemy health/AI, restores player health/ammo, and clears completion.

## Verification

Recommended Task 15 checks:

```bash
node --check web/main.js
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7 --exit-map
node seed7/bin/s7.js -l seed7/lib -l src/wad src/wad/map_loader.s7 tests/wad_tests/exit_map.pwad
```

Serve the repo and open the browser demo:

```bash
python -m http.server 8080
```

Open:

```text
http://localhost:8080/web/index.html
```

Expected behavior:

- the default demo loads automatically in first-person mode;
- the default fixture includes a player start at `128,96 angle=90`, one
  off-center placeholder enemy at `80,144`, and one north-wall linedef with
  synthetic exit special `901`;
- combat and enemy AI still work before completion;
- move forward toward the green `EXIT` wall and press `Space` when the HUD says
  `Press Space at EXIT.`;
- `LEVEL COMPLETE` appears inside the Canvas game view/HUD;
- movement, firing, door/use interaction, and enemy AI stop after completion;
- Reset restarts the same map and allows replay;
- manual WAD upload remains in `Advanced / Load WAD`;
- framebuffer and top-down modes remain in collapsed `Debug`.
