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
