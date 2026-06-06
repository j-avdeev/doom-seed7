# Doom3 Seed7

Doom3 Seed7 is a Seed7-core generated-assets shooter for the browser, with an id Tech 4 compatibility track kept alive through diagnostics. The active GitHub Pages path now launches a Classic DOOM-like generated episode with three maps, generated map metadata, projected surfaces with polygon near-plane clipping, simple monster AI, keys/locked doors, pickups, map exits, procedural monster silhouettes, key/weapon HUD icons, and deterministic smoke checks. The browser runtime renders internally at 640x360 and scales the canvas with pixelated CSS for lower latency. It does not ship commercial Doom, Doom 3, WAD, pk4, texture, sprite, sound, model, or map data.

The Doom 3 GPL source release and dhewm3 are references for behavior, compatibility direction, and data policy:

- https://github.com/id-Software/DOOM-3
- https://github.com/dhewm/dhewm3
- https://dhewm3.org/

## Browser

Build the WebAssembly runtime if needed:

```bash
python build_s7_wasm.py browser
```

Serve the repository over HTTP:

```bash
python -m http.server 8080
```

Open:

```text
http://localhost:8080/index.html
```

`index.html` redirects to:

```text
doom3.html?entry=doom3_seed7_runtime.s7
```

Click `Launch`. With no file input, Pages starts `--engine_mode generated --doom3_start_map e1m1` and mounts the free generated asset pack from `generated/doom3_seed7`. Optional local `.pk4` or `.zip` files are mounted only in browser memory under `/doom3/base` and switch the runtime to `--engine_mode pk4` for compatibility testing.

Generated episode maps:

- `e1m1`: E1M1 Foundry Gate
- `e1m2`: E1M2 Processing Core
- `e1m3`: E1M3 Reactor Exit

## Runtime

Native smoke:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_runtime.s7 --smoke_frames 2
```

Visual smoke:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_runtime.s7 --visual_smoke_frames 2
```

Expected readiness markers:

```text
engine_smoke_ready=TRUE
episode_smoke_ready=TRUE
episode_maps=3
monster_types=3
hud_contract=ammo,health,armor,face,key_icons,weapon_icons
render_resolution=640x360
wall_clip=polygon_near_plane
render_passes=single_sorted
input_polling=continuous
wall_clip_ready=TRUE
visual_smoke_ready=TRUE
```

Supported arguments:

- default: launch E1M1 Foundry Gate in the generated episode
- `--engine_mode generated|pk4`
- `--doom3_data_path <path>`
- `--doom3_start_map e1m1|e1m2|e1m3`
- `--generated_asset_root <path>`
- `--smoke_frames <n>`
- `--visual_smoke_frames <n>`
- `--help`
- `+set fs_basepath <path>`, `+set fs_game <name>`, `+map <map>`

## Controls

- Arrow keys or WASD: move and turn
- Space or left mouse: fire
- R: restart after death
- Esc: quit

## Diagnostics

The active browser path is:

```text
doom3.html -> doom3_seed7_runtime.s7 -> doom3_seed7_engine.s7
```

The earlier simple generated scene is now only a compatibility fallback/debug reference and is not the default launch path. The many `doom3_seed7_*.s7` scanner and subsystem probes remain for Doom 3 data inspection and compatibility work; they are diagnostics, not the Pages user experience.

Checks:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\verify_doom3_seed7_smoke.ps1
powershell -ExecutionPolicy Bypass -File .\tools\verify_doom3_seed7_pages_visual.ps1 -Url http://localhost:8080/doom3.html?entry=doom3_seed7_runtime.s7
```

## Software Framebuffer Demo

This is the smallest browser-runtime milestone: a 320x200 software framebuffer with a moving color pattern. It contains no Doom logic and does not parse WAD or pk4 data.

Native/interpreted smoke:

```bash
node seed7/bin/s7.js -l seed7/lib src/platform/framebuffer_demo.s7 --frame 12 --frames 3
node seed7/bin/s7.js -l seed7/lib src/platform/framebuffer_demo.s7 --frame 12 --ppm framebuffer_demo.ppm
```

Generated Seed7-to-WASM smoke:

```powershell
& 'C:\Program Files\Git\bin\bash.exe' tools/build-wasm.sh
```

From Git Bash or another POSIX-like shell:

```bash
tools/build-wasm.sh
```

The script first builds `src/platform/wasm_probe.s7`, then builds
`src/platform/framebuffer_demo.s7` through Seed7-generated C and Emscripten. The
expected framebuffer proof line is:

```text
framebuffer_demo width=320 height=200 frame=12 checksum=261054247
```

Browser demo:

```bash
python -m http.server 8080
```

Open:

```text
http://localhost:8080/web/index.html
```

The browser wrapper in `web/main.js` first draws with the JavaScript fallback
provider, then switches to the Seed7-generated WASM provider when
`web/wasm/framebuffer_demo.js` loads successfully. The WASM provider exports a
stable C ABI for Canvas rendering:

```text
doom_init(width, height)
doom_tick(frame_number)
doom_framebuffer_ptr()
doom_framebuffer_width()
doom_framebuffer_height()
doom_framebuffer_size()
```

`doom_tick` fills a static 320x200 RGBA framebuffer from Seed7-generated pixel
functions, and `web/main.js` copies those bytes from WASM memory into Canvas
`ImageData`. The frame status includes the WASM checksum; the same checksum is
computed from the displayed Canvas pixels during smoke verification.

What works:

- Interpreted Seed7 framebuffer smoke.
- Minimal Seed7-generated WASM proof callable from JavaScript/Node.
- Seed7-generated WASM framebuffer ABI with pointer, dimensions, size, and
  per-frame rendering.
- Browser Canvas rendering from Seed7-generated WASM memory.
- Browser Canvas fallback with changing pixels when generated WASM is missing.

What still does not:

- `seed7_win.exe` and `s7_direct.exe` were previously unreadable/corrupted in
  this checkout and are not part of the verified path.
- No map loading, Doom rendering, gameplay, pk4 parsing, or commercial asset
  loading is part of this milestone.

See `docs/browser-runtime.md` and `tools/build-wasm.sh` for exact commands,
Emscripten exports, and remaining blockers.

## WAD Directory Parser

Task 3 adds a minimal Doom WAD header and directory parser. It reads `IWAD` or
`PWAD` magic, lump count, directory offset, lump offsets, lump sizes, and lump
names. It also exposes `find_lump_by_name`. It does not load maps, textures,
rendering data, browser uploads, or gameplay.

Generate the synthetic test WAD and parse it:

```bash
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7
node seed7/bin/s7.js -l seed7/lib -l src/wad src/wad/wad_reader.s7 tests/wad_tests/minimal.pwad --find TEST
```

See `docs/wad-format.md` for the parsed fields and expected output.

## WAD Map Loader

Task 4 adds a data-only Doom map lump loader. It finds the first supported map
marker, `E1M1` or `MAP01`, then loads `THINGS`, `LINEDEFS`, `SIDEDEFS`,
`VERTEXES`, and `SECTORS` into Seed7 records. It identifies the first type-1
player start and prints map statistics. It does not render, load textures, or
implement gameplay.

Generate and parse the synthetic map PWAD:

```bash
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7 --map
node seed7/bin/s7.js -l seed7/lib -l src/wad src/wad/map_loader.s7 tests/wad_tests/minimal_map.pwad
```

See `docs/map-structures.md` for loaded record fields and expected output.

## Browser Map And First-Person Renderer

Tasks 6 through 16 add browser map rendering on the existing 320x200 Canvas.
Opening `web/index.html` over HTTP now starts a playable first-person demo from
the generated, non-commercial `web/assets/demo_map.pwad` fixture. Manual WAD
upload remains available under `Advanced / Load WAD`, and the Debug section
keeps the original framebuffer demo and top-down map view available. If an
uploaded WAD includes
`PLAYPAL`, `PNAMES`, `TEXTURE1`, and referenced patch lumps, first-person wall
columns can use basic Doom wall textures. Non-player `THINGS` are drawn as
top-down markers and first-person placeholder billboards. The browser bridge
also supports minimal pistol hitscan combat and simple melee enemy AI for those
placeholder things, plus a HUD, pause, game-over, reset state, a synthetic
level exit, fullscreen support, focus handling, loading/error status, and a
clean default playable browser UX.

Generate the local map fixture:

```bash
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7 --map
```

Generate the synthetic textured map fixture:

```bash
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7 --textured-map
```

Generate the synthetic door interaction fixture:

```bash
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7 --door-map
```

Generate the synthetic thing/sprite placeholder fixture:

```bash
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7 --thing-map
```

Generate the synthetic exit/playable-loop fixture:

```bash
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7 --exit-map
```

Build the current generated WASM framebuffer provider:

```powershell
& 'C:\Program Files\Git\bin\bash.exe' tools/build-wasm.sh
```

From Git Bash or another POSIX-like shell:

```bash
tools/build-wasm.sh
```

Serve the repository locally with PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\serve-web.ps1
```

Serve it from Git Bash:

```bash
tools/serve-web.sh
```

The default port is `8080`. To choose another port:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\serve-web.ps1 -Port 8090
```

```bash
tools/serve-web.sh 8090
```

The raw Python equivalent is:

```bash
python -m http.server 8080 --bind 127.0.0.1
```

Open the local browser demo:

```powershell
Start-Process "http://localhost:8080/web/index.html"
```

Or open this URL manually:

```text
http://localhost:8080/web/index.html
```

### GitHub Pages Deployment

Task 16.1 adds a GitHub Actions deployment workflow for the static playable
demo:

```text
.github/workflows/pages.yml
```

The workflow publishes the committed `web/` directory directly. It does not
rebuild Seed7 or Emscripten in CI. It includes `web/index.html`, `web/main.js`,
`web/styles.css`, `web/assets/demo_map.pwad`, `web/wasm/*.js`,
`web/wasm/*.wasm`, and `web/.nojekyll`.

To enable it:

1. Push the workflow to `main`.
2. In GitHub, open `Settings -> Pages`.
3. Set `Build and deployment` source to `GitHub Actions`.
4. Run `Deploy playable web demo` from the Actions tab, or push a change under
   `web/**` or `.github/workflows/pages.yml` to `main`.

Expected URL:

```text
https://<owner>.github.io/<repository>/
```

If the demo loads but WASM fails, open the collapsed `Debug` panel and browser
devtools Network tab. `framebuffer_demo.js`, `framebuffer_demo.wasm`, and
`assets/demo_map.pwad` should return HTTP 200. The playable first-person WAD
demo still runs if only the generated WASM framebuffer provider fails; the
Framebuffer debug mode falls back to JavaScript.

See `docs/deployment.md` for the full deployment asset list and limitations.

In the page:

1. Confirm the page starts in first-person mode automatically with the bundled
   demo fixture loaded, with no raw mode line, player coordinates, wall-column
   counts, AI counters, WASM status, WAD summary, or lump list visible by
   default.
   The health/ammo/weapon/enemy/status HUD should be drawn inside the Canvas
   pixels, not shown as a DOM panel or CSS overlay.
2. Confirm the compact package status moves from loading to ready/playable.
   Debug and Advanced remain collapsed by default.
3. Click the game area to focus controls. The focus hint should disappear, and
   gameplay keys should not scroll the page.
4. Move with `W`/`S`, strafe with `A`/`D`, turn with arrows or `Q`/`E`, fire
   with left mouse, `Ctrl`, or `F`, and use Pause and Reset.
5. Click `Fullscreen` or press `Alt+Enter`; the game keeps its 16:10 shape,
   the Canvas HUD remains inside the game viewport, and Pause/Reset stay
   visible. Exit fullscreen and continue playing.
6. Open `Advanced / Load WAD`, click `Choose file`, and select
   `tests/wad_tests/minimal_map.pwad` for manual upload regression coverage.
7. Open `Debug` and confirm the WAD details show `PWAD`, `E1M1`, four vertexes,
   four linedefs,
   four sidedefs, one sector, one thing, and player start `128, 64 angle=90`.
8. Use the Debug mode buttons to switch between First-person, Top-down Map, and
   Framebuffer. First-person is the primary play mode. The FPS counter is only
   inside Debug.
9. With `textured_map.pwad`, the Debug WAD details should report `1 of 1
   resolved` wall textures.
10. To test Task 10 interaction, select `tests/wad_tests/door_map.pwad`, face
   the marked door line, and press `Space`. The closed line blocks movement;
   after opening, movement through that line is allowed.
11. To test Task 11 thing rendering, select `tests/wad_tests/thing_map.pwad`.
   The Debug WAD details should show two things and one renderable thing;
   top-down mode should show its marker, and first-person mode should show one
   placeholder billboard.
12. To test Task 12 combat, Task 13 enemy AI, and Task 14 HUD/game state in
   first-person mode, aim at the placeholder and fire with left mouse, `Ctrl`,
   or `F`. The collapsed Debug panel should report renderer details while the
   HUD reports health, ammo, weapon, enemy alive/dead counts, and the latest
   player-facing combat message. The enemy notices or chases the player,
   damages the player at close range with a cooldown, and three hits kill the
   placeholder. A dead enemy disappears in first-person mode, shows as a gray
   cross in top-down mode, and no longer attacks. If the enemy reduces player
   health to zero, game-over blocks movement and firing until Reset restarts
   the current map state.
13. To test Task 15.1 level completion in the default bundled demo, confirm the
    first-person view starts facing a green wall segment labeled `EXIT`, with
    one placeholder enemy off-center. Move forward toward the green `EXIT` wall
    until the in-canvas HUD says `Press Space at EXIT.`, then press `Space`.
    `LEVEL COMPLETE` should appear inside the Canvas game view/HUD,
    movement/firing/enemy AI should stop, and Reset should restart the same map.
14. Open the collapsed `Debug` panel, switch to `Top-down Map`, and confirm the
    exit line is bright green and labeled `EXIT 901`. The Debug WAD details for
    the bundled map should include player start `128, 96 angle=90`, two things,
    one renderable/shootable thing, and `1 synthetic exit special 901`.
15. Temporarily remove or rename `web/assets/demo_map.pwad`, reload, and confirm
    the package status reports the missing/unreadable demo map. Restore the
    fixture afterward.

This is a temporary JavaScript bridge that preserves the Seed7-generated WASM
framebuffer provider. In top-down and first-person modes, `W`/`S` move forward
and backward, `A`/`D` strafe, and `ArrowLeft`/`ArrowRight` or `Q`/`E` turn.
`Space` uses the synthetic Task 10 door line in front of the player or the Task
15 exit line when it is in front of or near the player. Left mouse, `Ctrl`, and
`F` fire the Task 12 pistol hitscan weapon and can alert placeholder enemies.
Pause freezes gameplay, and Reset restores player position, health, ammo, enemy
state, synthetic door state, and level-completion state. Click the Canvas before
using gameplay keys; `Alt+Enter` toggles fullscreen.
One-sided and explicitly blocking linedefs use conservative debug collision.
The first-person renderer is still a ray/segment projection prototype; thing
rendering, combat, and enemy AI are placeholder passes and do not add pickups,
advanced weapon behavior, sound, or full Doom gameplay.

Known limitations:

- The map renderers are browser debug/prototype views, not Doom gameplay.
- Map and first-person rendering use the JavaScript WAD bridge; the WASM path remains the
  framebuffer provider.
- Only the first supported `E1M1` or `MAP01` map marker is loaded.
- Collision is conservative debug collision against one-sided or blocking
  linedefs, not full Doom movement, height, blockmap, or thing collision.
- Texture support is limited to `PLAYPAL`, `PNAMES`, `TEXTURE1`, and vanilla
  patch picture lumps for wall columns. Sprite support is limited to
  placeholder billboards from map `THINGS`. No floor/ceiling flats, Doom sprite
  lump compatibility, pickups, audio, episode progression, or commercial WAD
  assets are included.
- Combat and HUD support are limited to a pistol-style hitscan, player health,
  ammo, game-over, pause, and reset state in the browser bridge.
- Enemy AI support is limited to placeholder idle/chase/attack/dead states,
  approximate line of sight, direct movement, and melee damage with a cooldown.
- Door support is limited to the synthetic browser-side linedef special
  documented in `docs/line-specials.md`; it is not Doom-compatible door logic.
- Exit support is limited to the synthetic browser-side linedef special
  documented in `docs/level-flow.md`; it is not Doom-compatible level
  progression.

See `docs/renderer-debug.md` for top-down details and
`docs/renderer-options.md` for the first-person renderer approach. See
`docs/textures.md` for Task 9 texture support and limitations. See
`docs/line-specials.md` for Task 10 door support and limitations. See
`docs/sprites.md` for Task 11 thing rendering and limitations. See
`docs/combat.md` for Task 12 combat support and limitations. See
`docs/enemy-ai.md` for Task 13 enemy AI support and limitations. See
`docs/ui.md` for Task 14 HUD, pause, game-over, and reset behavior. See
`docs/level-flow.md` for Task 15 exit and level-complete behavior. See
`docs/browser-runtime.md` for Task 16 local packaging and browser-run details.
See `docs/deployment.md` for Task 16.1 GitHub Pages deployment.
