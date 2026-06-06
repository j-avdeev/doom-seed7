# Renderer Debug View

Task 6 adds a browser-only top-down map viewer for loaded Doom map geometry. It
is a debug renderer, not a first-person renderer and not gameplay.

## Current Scope

The browser can load a user-selected WAD file, find the first supported `E1M1`
or `MAP01` marker, and render the map on the existing 320x200 Canvas. The view
draws:

- `VERTEXES` as small cyan points.
- `LINEDEFS` as software framebuffer lines.
- one-sided linedefs in light gray.
- two-sided linedefs in muted green.
- the type-1 player start as a yellow marker with a direction arrow.

The renderer computes bounds from the loaded map vertexes and the player start,
then scales and centers that world rectangle into the Canvas with fixed padding.
Doom map coordinates keep their native orientation: positive X points right and
positive Y points upward in the debug view.

## Browser Bridge

This milestone intentionally leaves the working Seed7-generated WASM framebuffer
provider unchanged. The top-down view extends the existing Task 5 JavaScript WAD
bridge in `web/main.js`, because that bridge already parses uploaded WAD bytes
without disturbing the framebuffer ABI.

The renderer still uses the same Canvas and `ImageData` surface as the
framebuffer demo. It writes pixels directly into the 320x200 RGBA buffer, then
presents them with `putImageData`. No WebGL, textures, BSP traversal, player
movement, enemies, weapons, audio, or gameplay were added.

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
- The Canvas shows a simple square map outline, vertex dots, and a player-start
  direction arrow.
- Switching back to `Framebuffer` resumes the Seed7-generated WASM framebuffer
  provider when it is available, or the JavaScript fallback when it is not.

Task 7 is still not started by this renderer. Movement, collision, first-person
projection, textures, enemies, combat, and gameplay remain future milestones.
