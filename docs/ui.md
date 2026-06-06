# UI And Game State

Task 14 adds a minimal browser-side HUD and explicit playable state handling to
the temporary JavaScript WAD bridge. The Seed7-generated WASM framebuffer
provider remains unchanged; the WAD gameplay prototype still runs in
`web/main.js`.

Task 14.2 made `web/index.html` start as a playable browser prototype. On page
load it fetches the generated, non-commercial `web/assets/demo_map.pwad`
fixture, loads it through the same WAD parser path as manual uploads, and starts
in first-person mode.

Task 14.3 changed the default page into a game-first view. The initial page
showed the title, 320x200 game Canvas, attached status bar, and Pause/Reset
buttons. Advanced loading, controls help, renderer mode switches, WAD
summaries, lump lists, WASM status, raw player coordinates, wall-column counts,
and AI counters are hidden inside collapsed panels.

Task 14.4 moved the previous HTML HUD into the game viewport as an overlay.
Task 14.5 supersedes that approach; the overlay is no longer part of the
current default UI.

Task 14.5 removes the visible DOM HUD entirely. The game renderer now reserves
the bottom 40 pixels of the 320x200 Canvas as an in-canvas status bar, draws the
first-person or top-down view in the upper 160 pixels, and paints health, ammo,
weapon, enemies, state, and the short message with Canvas 2D drawing calls.

## HUD

`web/index.html` now exposes a Doom-like in-canvas status strip drawn into the
bottom of the Canvas. It shows:

- player health;
- pistol ammo;
- current weapon;
- alive and dead enemy counts;
- the latest player-facing combat or interaction message.

The older renderer/debug status remains available in the collapsed `Debug`
panel for frame, position, wall-column, thing, WASM, and AI details.

Manual WAD upload remains available in the collapsed `Advanced / Load WAD`
section. Framebuffer and top-down map modes remain available in the collapsed
`Debug` section, alongside WAD summary and lump details.

## Playable State

When a supported `E1M1` or `MAP01` map is loaded, Reset initializes the playable
state:

- player position and angle from the first player start;
- health `100`;
- ammo `24`;
- weapon `pistol`;
- all shootable placeholder enemies alive with 3 health;
- enemy AI returned to `idle`;
- synthetic browser door state returned to `closed`.

Enemy melee damage can reduce player health to zero. At zero health the player
enters game-over state. While game over is active:

- movement input is ignored;
- door use is blocked;
- firing is blocked;
- simulation is frozen;
- the HUD shows `Game over` and a reset message;
- a `GAME OVER` overlay appears on the playfield.

Clicking Reset restarts the current playable state without re-uploading the WAD.

## Pause

The Pause button now freezes both the framebuffer demo and map gameplay. In map
mode, pause stops movement, doors, enemy AI, melee damage, and firing until
Resume is clicked. The playfield shows a `PAUSED` overlay while pause is active.
Reset clears pause and restarts the current map state.

## Controls

Detailed controls are available from the collapsed `Help` panel:

```text
W/S move, A/D strafe, Arrow keys or Q/E turn, Space uses doors,
left mouse/Ctrl/F fires, Pause freezes play, Reset restarts the current map.
```

## Verification

Recommended Task 14 verification:

```bash
node --check web/main.js
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7 --thing-map
node seed7/bin/s7.js -l seed7/lib -l src/wad src/wad/map_loader.s7 tests/wad_tests/thing_map.pwad
```

Serve the browser demo:

```bash
python -m http.server 8080
```

Open:

```text
http://localhost:8080/web/index.html
```

The default page should load `web/assets/demo_map.pwad` automatically and switch
to first-person mode without manual upload. Verify:

- first-person mode is active after page load;
- no raw mode line, player coordinates, wall-column counts, AI counters, WASM
  status, WAD summary, or lump list is visible by default;
- health, ammo, weapon, enemies, and the last combat message are visible inside
  the game viewport;
- movement, firing, enemy melee damage, game over, pause, and reset work;
- `Advanced / Load WAD` still allows manual WAD upload;
- `Debug` still exposes Framebuffer and Top-down Map modes plus WAD details.

For fixture regression coverage, manually upload `tests/wad_tests/thing_map.pwad`
from `Advanced / Load WAD`, switch modes from `Debug`, and
verify:

- in-game HUD strip shows health, ammo, weapon, enemies, and the last combat
  message in the bottom Canvas strip in both first-person and top-down modes;
- no visible DOM element or CSS overlay contains health, ammo, weapon, enemies,
  or the status message;
- renderer/debug text remains available inside the collapsed `Debug` panel;
- the enemy notices, chases, and damages the player;
- player health reaches zero after repeated melee hits;
- game-over state blocks movement and firing;
- Reset restores health, ammo, player position, enemy state, and door state;
- Pause freezes and resumes gameplay.

## Limitations

This milestone does not add level exits, pickups, sound, save/load, advanced
weapons, or real Doom HUD assets. The HUD and state handling are intentionally
minimal and scoped to the Task 12/13 placeholder combat and enemy AI prototype.
