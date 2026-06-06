# Seed7 Browser WebAssembly Feasibility

This note records the current feasibility of compiling Seed7 programs to browser
WebAssembly and the current browser WAD upload bridge. It is scoped to the
software framebuffer, WAD inspection, top-down map-debug, and first-person
prototype milestones with basic Task 9 wall textures and Task 11 placeholder
thing rendering plus Task 12 placeholder combat. It does not add audio, pk4
parsing, enemy AI, enemy attacks, pickups, advanced weapons, or full gameplay.

## Current Result

Task 2.5 connects a real Seed7-generated C to Emscripten to WebAssembly
framebuffer provider to the browser Canvas. The build still includes two small
programs:

- `src/platform/wasm_probe.s7`: prints a fixed proof line.
- `src/platform/framebuffer_demo.s7`: computes the existing 320x200 framebuffer
  checksum path and supplies generated pixel functions used by the WASM bridge.

The generated framebuffer module is relinked through
`src/platform/wasm_framebuffer_bridge.c`. The bridge includes the generated C in
one translation unit, discovers the compiler-assigned Seed7 pixel function
symbols, and exports a small Emscripten ABI:

```text
doom_init(width, height)
doom_tick(frame_number)
doom_framebuffer_ptr()
doom_framebuffer_width()
doom_framebuffer_height()
doom_framebuffer_size()
doom_framebuffer_checksum()
doom_framebuffer_frame()
```

The generated WASM artifacts are written to `web/wasm/`:

- `web/wasm/wasm_probe.js`
- `web/wasm/wasm_probe.wasm`
- `web/wasm/framebuffer_demo.js`
- `web/wasm/framebuffer_demo.wasm`

The browser page renders with the JavaScript fallback immediately, then switches
to the generated WASM provider when the ABI is ready. `web/main.js` calls
`doom_tick(frame)`, reads the framebuffer pointer and size, copies bytes from
`Module.HEAPU8` into Canvas `ImageData`, and displays the WASM checksum in the
frame status. If the generated provider cannot be fetched or its ABI is invalid,
the JavaScript fallback remains active.

Task 5 adds a WAD file picker to `web/index.html`. The selected file is read in
`web/main.js` with `File.arrayBuffer()`. Tasks 6 and 7 extend that same bridge
with a temporary JavaScript top-down map renderer and movable debug player
instead of changing the working framebuffer WASM module. Task 8 adds a
browser-only first-person projection prototype on top of that same parsed
geometry and player state. Task 9 adds optional `PLAYPAL`/`PNAMES`/`TEXTURE1`
wall texture parsing to that JavaScript bridge. Task 11 parses all map things
and renders non-player things as top-down markers and first-person placeholder
billboards. This keeps the Task 2.5
Seed7-generated WASM framebuffer path stable while still exercising the browser
upload flow. The browser bridge mirrors the Task 3 and Task 4 data fields:

- WAD magic: `IWAD` or `PWAD`
- lump count
- directory offset
- lump offsets, sizes, and normalized 8-byte lump names
- first supported map marker: `E1M1` or `MAP01`
- map lump statistics for `THINGS`, `LINEDEFS`, `SIDEDEFS`, `VERTEXES`, and
  `SECTORS`, when the selected WAD contains a complete supported map
- top-down geometry data from `VERTEXES`, `LINEDEFS`, and the type-1 player
  start, rendered into the existing 320x200 Canvas `ImageData`
- first-person wall columns from solid linedef ray intersections, sharing the
  same player `x`, `y`, and `angle`
- optional wall texture data from `PLAYPAL`, `PNAMES`, `TEXTURE1`, and patch
  picture lumps when the uploaded WAD supplies them
- non-player `THINGS` rendered as top-down debug markers and first-person
  placeholder billboards with rough distance ordering
- minimal pistol hitscan combat against alive non-player placeholder things,
  with ammo and hit/miss status text

The upload path does not bundle, fetch, or require copyrighted WAD files. User
files remain in browser memory. The browser bridge remains a debug/prototype
path, not a complete gameplay loop.

## How Seed7 Compiles To C

Seed7 compilation is handled by `seed7/prg/s7c.sd7`.

Observed compiler flow:

1. Parse and analyze the Seed7 source with the configured include paths.
2. Generate a temporary C file named like `tmp_<source>.c`.
3. Compile that temporary C file with the configured C compiler.
4. Link the resulting object with required Seed7 runtime archives from `-b`.
5. Remove temporary C/object files unless debug options keep them.

Relevant options used by the working path:

- `-l <dir>` adds Seed7 include search paths.
- `-b <dir>` points at compiled Seed7 runtime archives.
- `-O2` controls C compiler optimization.
- `-oc3` controls generated C optimization.
- `-g` keeps generated C/object artifacts.

The working script runs `s7c.sd7` through the existing Seed7 WASM interpreter:

```bash
node --stack-size=8192 ../../../seed7/bin/s7.js \
  -l ../../../seed7/lib \
  ../../../seed7/prg/s7c.sd7 \
  -l ../../../seed7/lib \
  -b ../../../seed7/bin \
  -g -O2 -oc3 wasm_probe
```

The source is copied to an extensionless temporary filename first. This avoids
generated artifact names like `tmp_wasm_probe.s7.o` and keeps the relink step
predictable.

## Verified Build Chain

On Windows, run the script through Git Bash:

```powershell
& 'C:\Program Files\Git\bin\bash.exe' tools/build-wasm.sh
```

From a POSIX-like shell:

```bash
tools/build-wasm.sh
```

The script builds the minimal probe first, then builds
`src/platform/framebuffer_demo.s7` by default. To build another Seed7 entry after
the probe:

```bash
tools/build-wasm.sh path/to/entry.s7
```

The probe relink step uses the object generated by Seed7 and the Emscripten
runtime archives already present in `seed7/bin`:

```bash
emcc tmp_<target>.o \
  seed7/bin/s7_data_emc.a \
  seed7/bin/seed7_05_emc.a \
  -sASSERTIONS=0 \
  -sALLOW_MEMORY_GROWTH=1 \
  -sEXIT_RUNTIME=0 \
  -sFORCE_FILESYSTEM=1 \
  -sEXPORTED_FUNCTIONS=_main,_setEnvironmentVar,_setOsProperties \
  -sEXPORTED_RUNTIME_METHODS=ccall,cwrap,UTF8ToString \
  -lnodefs.js \
  --pre-js wasm/pre_js_browser.js \
  -o web/wasm/<target>.js
```

For `framebuffer_demo`, the script relinks through the bridge source instead of
the generated object:

```bash
emcc src/platform/wasm_framebuffer_bridge.c \
  -DSEED7_FRAMEBUFFER_GENERATED_C="<build>/tmp_framebuffer_demo.c" \
  -DSEED7_PIXEL_RED=<generated_red_symbol> \
  -DSEED7_PIXEL_GREEN=<generated_green_symbol> \
  -DSEED7_PIXEL_BLUE=<generated_blue_symbol> \
  seed7/bin/s7_data_emc.a \
  seed7/bin/seed7_05_emc.a \
  -sASSERTIONS=0 \
  -sALLOW_MEMORY_GROWTH=1 \
  -sEXIT_RUNTIME=0 \
  -sFORCE_FILESYSTEM=1 \
  -sEXPORTED_FUNCTIONS=_main,_setEnvironmentVar,_setOsProperties,_doom_init,_doom_tick,_doom_framebuffer_ptr,_doom_framebuffer_width,_doom_framebuffer_height,_doom_framebuffer_size,_doom_framebuffer_checksum,_doom_framebuffer_frame \
  -sEXPORTED_RUNTIME_METHODS=ccall,cwrap,UTF8ToString \
  -lnodefs.js \
  --pre-js wasm/pre_js_browser.js \
  -o web/wasm/framebuffer_demo.js
```

## Browser Run Path

Serve the repository over HTTP:

```bash
python -m http.server 8080
```

Open:

```text
http://localhost:8080/web/index.html
```

`web/main.js` always keeps the JavaScript framebuffer fallback available. It
fetches `web/wasm/framebuffer_demo.js`; when present, that generated Seed7 WASM
module is initialized without running `main`, wrapped with `cwrap`, and used as
the per-frame pixel provider.

The same page now includes a `WAD` file input. Selecting a `.wad` file reads the
file as an `ArrayBuffer`, validates the WAD header and directory, and updates the
page with the parsed WAD type, lump count, directory offset, file size, and the
first 24 lump names with offsets and sizes. If an `E1M1` or `MAP01` marker is
present and the required map lumps are valid, the page also displays vertex,
linedef, sidedef, sector, thing, and player-start statistics, then switches the
Canvas mode to the top-down map view. The mode control can switch back to the
original framebuffer demo or into the first-person prototype.

When the selected map references wall textures and the WAD provides supported
texture lumps, first-person mode resolves those textures and reports the count
in the WAD panel. If texture data is absent or incomplete, the map still loads
and the first-person renderer uses shaded fallback wall columns.

When the selected map includes non-player things, the WAD panel reports
renderable thing count. Top-down mode draws markers for those things, and
first-person mode draws placeholder billboards sorted far-to-near and clipped
against approximate wall-column depth. Doom sprite lump decoding and rotation
selection are not implemented yet.

The expected interpreted and Node-generated checksum proof line remains:

```text
framebuffer_demo width=320 height=200 frame=12 checksum=261054247
```

The expected browser WASM status includes:

```text
Seed7-generated WASM framebuffer active.
Frame 12 (WASM checksum 261054247)
```

## Fixed Blockers

- `cwrap` was not exported in the first generated output. The relink now uses
  `-sEXPORTED_RUNTIME_METHODS=ccall,cwrap,UTF8ToString`.
- Seed7's generated JavaScript also expects `_setEnvironmentVar` and
  `_setOsProperties`; the relink exports them with `_main`.
- A manual relink without NodeFS failed with a Node filesystem `ENOENT` while
  Seed7 setup code mounted/chdir'd runtime paths. The relink now includes
  `-sFORCE_FILESYSTEM=1` and `-lnodefs.js`.
- A relink with `-sEXIT_RUNTIME=1` aborted after startup because runtime support
  functions were called after program exit. The working path uses
  `-sEXIT_RUNTIME=0`.
- Absolute Windows paths passed through Git Bash were converted to `C:/...`
  strings that Seed7 could not open in this context. The script uses relative
  paths from the temporary build directory.
- The generated Seed7 framebuffer functions are `static` C symbols. The bridge
  includes `tmp_framebuffer_demo.c` in the same translation unit, renames the
  generated CLI `main`, and calls the compiler-assigned pixel functions directly.
- Windows clang does not accept Git Bash `/c/...` paths inside C `#include`
  macros. `tools/build-wasm.sh` normalizes the generated-C include path with
  `cygpath -m` when available.

## Unknowns And Blockers

- `cc_conf_emcc.prop` and `emcc_env.ini` are still not present; the script
  bypasses that by setting `PATH` and manually relinking with Emscripten.
- The exported framebuffer is fixed at 320x200 RGBA for this milestone.
- `seed7_win.exe` and `s7_direct.exe` were previously unreadable/corrupted in
  this checkout, so the verified path does not rely on them.
- The full Doom runtime has not been compiled through this path.
- Running Seed7 through Node/WASM still prints
  `warning: unsupported syscall: __syscall_prlimit64`; it did not stop the
  passing build script, but should be tracked before CI depends on this path.

## Verification

Task 2.5 was verified with:

```powershell
& 'C:\Program Files\Git\bin\bash.exe' tools/build-wasm.sh
```

The build emitted the existing probe line and framebuffer checksum:

```text
seed7_wasm_probe ok value=1337
framebuffer_demo width=320 height=200 frame=12 checksum=261054247
```

A direct Node ABI smoke initialized the generated module without `main`, called
`doom_tick(12)`, read `Module.HEAPU8` at `doom_framebuffer_ptr()`, and observed:

```text
abi width=320 height=200 size=256000 checksum=261054247
```

Headless Chrome smoke at `http://localhost:8090/web/index.html` verified:

```text
wasm ok frame=12->21 checksum=261054247 status="Frame 12 (WASM checksum 261054247)" wasmStatus="Seed7-generated WASM framebuffer active."
fallback ok frame=11->20 checksum=169447138 status="Frame 11 (JS fallback)" wasmStatus="Generated WASM provider not built; JS fallback active."
```

Task 5 verification should include:

```powershell
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7
node seed7/bin/s7.js -l seed7/lib -l src/wad src/wad/wad_reader.s7 tests/wad_tests/minimal.pwad --find TEST
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7 --map
node seed7/bin/s7.js -l seed7/lib -l src/wad src/wad/map_loader.s7 tests/wad_tests/minimal_map.pwad
```

Then serve the browser demo, select `tests/wad_tests/minimal.pwad` and
`tests/wad_tests/minimal_map.pwad`, and confirm that the framebuffer keeps
animating while the WAD panel reports parsed WAD metadata. For the map fixture,
the expected browser map marker is `E1M1` and the expected counts are one thing,
four linedefs, four sidedefs, four vertexes, and one sector.

Task 6 verification should additionally confirm that selecting
`tests/wad_tests/minimal_map.pwad` switches the Canvas to `Mode: top-down map
view`, draws the square map outline, draws vertex markers, and draws the
player-start marker with an angle arrow. Switching back to `Framebuffer` should
resume the generated Seed7/WASM framebuffer provider when present, or the
JavaScript fallback when the provider is unavailable. See
`docs/renderer-debug.md` for the debug-renderer behavior.

Task 8 verification should additionally click `First-person`, confirm the Canvas
mode label changes to `Mode: first-person prototype`, confirm flat ceiling/floor
bands and untextured wall columns are visible, confirm movement/turning updates
the player perspective, and confirm `Top-down Map` and `Framebuffer` still work.
See `docs/renderer-options.md` for the prototype renderer approach.

Task 9 verification should additionally generate
`tests/wad_tests/textured_map.pwad`, upload it, confirm the WAD panel reports
one resolved wall texture, and confirm first-person mode reports textured wall
columns while `minimal_map.pwad` still uses fallback wall rendering.

Task 11 verification should additionally generate
`tests/wad_tests/thing_map.pwad`, upload it, confirm the WAD panel reports
`Things 2` and `Renderable things 1`, confirm top-down mode shows one thing
marker, and confirm first-person mode displays one placeholder billboard that
roughly respects distance and wall depth.

Task 12 verification should additionally use `tests/wad_tests/thing_map.pwad`,
switch to first-person mode, fire with left mouse, `Ctrl`, or `F`, and confirm
the status line reports ammo plus `shot=hit` when aiming at the placeholder and
`shot=miss` when aiming away. After three hits, the placeholder should disappear
from first-person mode and remain in top-down mode as a dead gray cross. See
`docs/combat.md` for the current combat behavior and limitations.
