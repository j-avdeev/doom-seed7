# Renderer Debug View

Task 7 extends the browser-only top-down map viewer with a movable debug player.
It is still a debug renderer, not a first-person renderer and not gameplay.

## Current Scope

The browser can load a user-selected WAD file, find the first supported `E1M1`
or `MAP01` marker, and render the map on the existing 320x200 Canvas. The view
draws:

- `VERTEXES` as small cyan points.
- `LINEDEFS` as software framebuffer lines.
- one-sided linedefs in light gray.
- two-sided linedefs in muted green.
- non-player `THINGS` as colored ring markers with angle ticks.
- alive Task 13 placeholder enemies color-coded by AI state.
- dead placeholder things as gray crosses.
- the current player position as a yellow marker with a direction arrow.

The renderer computes bounds from the loaded map vertexes and the player start,
then scales and centers that world rectangle into the Canvas with fixed padding.
Doom map coordinates keep their native orientation: positive X points right and
positive Y points upward in the debug view.

Player state is initialized from the first type-1 `THINGS` player start. The
view updates that state every animation frame while top-down mode is active and
shows the current `x`, `y`, and `angle` in the Canvas status line.

Controls in top-down mode:

- `W` / `S`: move forward and backward.
- `A` / `D`: strafe left and right.
- `ArrowLeft` / `ArrowRight`: turn.
- `Q` / `E`: alternate turn keys.

Collision is intentionally conservative. One-sided linedefs and linedefs with
the Doom blocking flag are treated as solid. Movement that crosses one of those
segments, or moves the debug player radius farther into one, is rejected. This
prevents obvious wall walking for the debug view, but it is not full Doom
collision, blockmap, height, or thing collision.

## Browser Bridge

This milestone intentionally leaves the working Seed7-generated WASM framebuffer
provider unchanged. The top-down view extends the existing Task 5 JavaScript WAD
bridge in `web/main.js`, because that bridge already parses uploaded WAD bytes
without disturbing the framebuffer ABI.

The renderer still uses the same Canvas and `ImageData` surface as the
framebuffer demo. It writes pixels directly into the 320x200 RGBA buffer, then
presents them with `putImageData`. No WebGL, BSP traversal, pickups, audio,
advanced weapons, or full Doom gameplay were added.

## Modes

`web/index.html` now exposes a Canvas mode control:

- `Framebuffer`: the original JavaScript fallback or Seed7-generated WASM
  framebuffer animation.
- `Top-down Map`: the uploaded map debug view.

The map button is disabled until a complete `E1M1` or `MAP01` map is loaded. A
successful map upload automatically switches to the top-down view. The
framebuffer button switches back to the existing framebuffer demo.

## Verification

Generate and load the synthetic map fixture:

```bash
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7 --map
python -m http.server 8080
```

Open:

```text
http://localhost:8080/web/index.html
```

Select:

```text
tests/wad_tests/minimal_map.pwad
```

Expected browser result:

- WAD stats still show `PWAD` metadata.
- Map stats show `E1M1`, four vertexes, four linedefs, four sidedefs, one
  sector, one thing, and a player start.
- The Canvas mode label changes to `Mode: top-down map view`.
- The Canvas shows a simple square map outline, vertex dots, and the player
  direction arrow.
- Pressing `W`, `S`, `A`, or `D` moves the yellow player marker.
- Pressing `ArrowLeft`, `ArrowRight`, `Q`, or `E` turns the direction arrow.
- The status line updates with player `x`, `y`, and `angle`.
- The square map boundary blocks obvious attempts to walk through the walls.
- Switching back to `Framebuffer` resumes the Seed7-generated WASM framebuffer
  provider when it is available, or the JavaScript fallback when it is not.

Task 11 additionally draws non-player thing markers in this same top-down debug
view. Task 12 uses this same view to show dead placeholder things as gray
crosses. Task 13 color-codes alive placeholder enemies by AI state. It still
does not add pickups, sound, or full Doom gameplay.
