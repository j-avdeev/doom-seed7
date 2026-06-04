# Doom3 Seed7

Doom3 Seed7 is a playable browser/native Seed7 runtime that targets a dark sci-fi horror first-person feel while staying clean-room and asset-safe. The active GitHub Pages path launches a generated-art WebAssembly game by default; no commercial Doom 3 textures, sounds, models, maps, or pk4 contents are bundled.

The Doom 3 GPL source release and dhewm3 are reference material for behavior, compatibility direction, and asset policy:

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

Click `Launch`. Optional local `.pk4` or `.zip` files can be selected before launch; they are mounted only in browser memory under `/doom3/base`. The v1 game does not require them.

## Runtime

Native smoke test:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_runtime.s7 --smoke_frames 2
```

Expected readiness marker:

```text
game_smoke_ready=TRUE
```

Help:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_runtime.s7 --help
```

Runtime entrypoint:

```text
doom3_seed7_runtime.s7
```

Supported arguments:

- default: open the interactive graphical game
- `--help`: print controls and options
- `--smoke_frames <n>`: render deterministic headless frames and print hashes for CI
- `--doom3_data_path <path>`: accepted for compatibility
- `--doom3_start_map <map>`: accepted for compatibility
- `+set fs_basepath <path>`, `+set fs_game <name>`, `+map <map>`: accepted Doom-style aliases

## Controls

- Arrow keys: move and turn
- Space: fire
- Esc or `q`: quit

The playable runtime uses generated wall, floor, pickup, monster, weapon, muzzle flash, fog, and HUD presentation in Seed7 through `draw.s7i` and `keybd.s7i`.

## Diagnostics

The many `doom3_seed7_*.s7` scanner and subsystem probes remain in the repository for Doom 3 data inspection and compatibility work, but they are no longer the active Pages launch path. The browser game path is only:

```text
doom3.html -> doom3_seed7_runtime.s7 -> doom3_seed7_game.s7
```

For probe-oriented checks, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\smoke_doom3_seed7.ps1
```

For the active playable runtime verification, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\verify_doom3_seed7_smoke.ps1
```
