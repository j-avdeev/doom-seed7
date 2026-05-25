# Seed7 DOOM-lite (Option B: Raycaster)

A minimal **DOOM-lite / original Doom 3–inspired sci-fi room raycaster** written entirely in **Seed7**, suitable for compilation to **WebAssembly** so it can run in the browser.

## Why Option B?

Translating a full C DOOM engine (Dwasm, wasm-doom, 72k–137k+ lines) to Seed7 is not feasible. This project instead implements a **custom raycaster** from scratch in Seed7:

- **Result:** A working 3D-style game in Seed7 that can be built with `s7c -c emcc` for the browser.
- **Scope:** Minimal clone / tech demo (flat ceiling/floor, orthogonal walls, no sprites), not the full classic DOOM engine.

## What’s Included

- **`raycaster.s7`** – Main program:
  - Original compact 24×24 sci-fi room: entrance corridor, main chamber, side server bays, central console, and sealed far door.
  - 640×400 viewport, dark industrial palette, distance shading, crosshair, weapon silhouette, and compact HUD bars.
  - Arrow keys: hold to move (forward/back) and rotate (left/right). ESC to quit.
  - Uses Seed7 `draw.s7i` (screen, rect, clear, flushGraphic) and `keybd.s7i` (GRAPH_KEYBOARD, getc, inputReady, buttonPressed).

## Build and Run

### Prerequisites

- **Seed7** installed (interpreter `s7`, compiler `s7c`).
- For WebAssembly: **Emscripten** (`emcc`) and your existing Seed7+WASM setup (e.g. `build_s7_wasm.py` in this repo).

### Native (desktop)

1. Build the Seed7 runtime with graphics (e.g. X11 or Windows draw lib).
2. Compile and run:
   ```bash
   s7c -l draw raycaster.s7
   ./raycaster
   ```
   Or run interpreted:
   ```bash
   s7 raycaster.s7
   ```
   (Exact command may depend on your Seed7 install and how `draw`/`keybd` are linked.)

### WebAssembly (browser)

This repo includes a **browser runner** so you can open the raycaster in a page.

1. **Build the Seed7 interpreter for WASM** (one-time; requires Emscripten and a working Seed7 Emscripten setup, including levelup/generated headers):
   ```bash
   python build_s7_wasm.py
   ```
   If the build fails (e.g. missing `gmp.h` or type headers), fix your Seed7/Emscripten environment (see Seed7 docs). The script uses `-DBIGINT_LIBRARY=1` so GMP is not required once the rest of the build is configured.

2. **Build the browser variant** (uses `wasm/pre_js_browser.js` so the page can inject `raycaster.s7` into the virtual FS):
   ```bash
   python build_s7_wasm.py browser
   ```
   This produces `wasm/s7.js` and `wasm/s7.wasm`.

3. **Serve the project and open the page** (from the project root):
   ```bash
   python -m http.server 8080
   ```
   Then open: **http://localhost:8080/index.html**

   The page will fetch `raycaster.s7` and `wasm/s7.js`, inject the script into the WASM FS, and run it. Use **arrow keys** to move/rotate and **ESC** to quit.

## Controls

| Key     | Action        |
|--------|---------------|
| Up     | Move forward  |
| Down   | Move backward |
| Left   | Rotate left   |
| Right  | Rotate right  |
| ESC    | Quit          |

## Technical Notes

- **Resolution:** 640×400 (change `SCREEN_WIDTH` / `SCREEN_HEIGHT` in `raycaster.s7` if needed).
- **Map:** Defined in `WORLD_MAP`; `0` = empty, `1`–`5` = dark metal, tech panels, server panels, trim, and amber/red door or console blocks.
- **Algorithm:** Same idea as [Lode’s raycaster](https://lodev.org/cgtutor/raycasting.html): camera plane, ray direction per column, DDA step, perpendicular wall distance, vertical stripe height, then draw with `rect(..., 1, height, col)`.
- **Visual style:** Original Doom 3–inspired sci-fi room only: dark lighting and a first-person HUD, not a Doom 3 room, engine, or asset port.

## License

Seed7 runtime and libraries are under their respective licenses (e.g. LGPL). This raycaster is provided as a minimal demo for the Option B plan.
