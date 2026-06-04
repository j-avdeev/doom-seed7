# Doom3 Seed7

Doom3 Seed7 is a Seed7-core id Tech 4 compatibility track for the browser. The active GitHub Pages path now launches an engine shell with generated replacement assets, projected surfaces, lighting/fog-style shading, weapon/HUD composition, and deterministic visual smoke checks. It does not ship commercial Doom 3 textures, sounds, models, maps, or pk4 contents.

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

Click `Launch`. With no file input, Pages starts `--engine_mode generated` and mounts the free generated asset pack from `generated/doom3_seed7`. Optional local `.pk4` or `.zip` files are mounted only in browser memory under `/doom3/base` and switch the runtime to `--engine_mode pk4` for compatibility testing.

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
visual_smoke_ready=TRUE
```

Supported arguments:

- default: launch the generated replacement asset engine scene
- `--engine_mode generated|pk4`
- `--doom3_data_path <path>`
- `--doom3_start_map <map>`
- `--generated_asset_root <path>`
- `--smoke_frames <n>`
- `--visual_smoke_frames <n>`
- `--help`
- `+set fs_basepath <path>`, `+set fs_game <name>`, `+map <map>`

## Controls

- Arrow keys: move and turn
- Space or left mouse: fire
- Esc: quit

## Diagnostics

The active browser path is:

```text
doom3.html -> doom3_seed7_runtime.s7 -> doom3_seed7_engine.s7
```

The earlier simple generated game remains as a separate debug/demo file, but it is not the default launch path. The many `doom3_seed7_*.s7` scanner and subsystem probes remain for Doom 3 data inspection and compatibility work.

Checks:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\verify_doom3_seed7_smoke.ps1
powershell -ExecutionPolicy Bypass -File .\tools\verify_doom3_seed7_pages_visual.ps1 -Url http://localhost:8080/doom3.html?entry=doom3_seed7_runtime.s7
```
