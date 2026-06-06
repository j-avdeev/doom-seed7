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

Tasks 6 through 8 add browser map rendering on the existing 320x200 Canvas.
Select `tests/wad_tests/minimal_map.pwad` in `web/index.html` to render the
loaded `E1M1` vertexes, linedefs, and movable player state. The Canvas mode
control switches between the original framebuffer demo, the first-person
prototype, and the top-down debug map view.

Generate the local map fixture:

```bash
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7 --map
```

Build the current generated WASM framebuffer provider:

```powershell
& 'C:\Program Files\Git\bin\bash.exe' tools/build-wasm.sh
```

From Git Bash or another POSIX-like shell:

```bash
tools/build-wasm.sh
```

Serve the repository locally:

```bash
python -m http.server 8080
```

Open the local browser demo:

```powershell
Start-Process "http://localhost:8080/web/index.html"
```

Or open this URL manually:

```text
http://localhost:8080/web/index.html
```

In the page:

1. Click `Choose file`.
2. Select `tests/wad_tests/minimal_map.pwad`.
3. Confirm the WAD panel shows `PWAD`, `E1M1`, four vertexes, four linedefs,
   four sidedefs, one sector, one thing, and player start `128, 64 angle=90`.
4. The page switches to `Mode: top-down map view` automatically. If needed,
   click `Top-down Map`.
5. Click `First-person` to render flat ceiling/floor bands and untextured wall
   columns from the player perspective.
6. Click `Framebuffer` to return to the generated WASM framebuffer demo.

This is a temporary JavaScript bridge that preserves the Seed7-generated WASM
framebuffer provider. In top-down and first-person modes, `W`/`S` move forward
and backward, `A`/`D` strafe, and `ArrowLeft`/`ArrowRight` or `Q`/`E` turn.
One-sided and explicitly blocking linedefs use conservative debug collision.
The first-person renderer is an untextured ray/segment projection prototype; it
does not add textures, sprites, enemies, weapons, combat, sound, or gameplay.

Known limitations:

- The map renderers are browser debug/prototype views, not Doom gameplay.
- Map and first-person rendering use the JavaScript WAD bridge; the WASM path remains the
  framebuffer provider.
- Only the first supported `E1M1` or `MAP01` map marker is loaded.
- Collision is conservative debug collision against one-sided or blocking
  linedefs, not full Doom movement, height, blockmap, or thing collision.
- No textures, sprites, enemies, weapons, combat, audio, exits, or commercial
  WAD assets are included.

See `docs/renderer-debug.md` for top-down details and
`docs/renderer-options.md` for the first-person renderer approach.
