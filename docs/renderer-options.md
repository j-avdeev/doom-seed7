# Renderer Options

Task 8 adds a browser-only first-person renderer prototype on top of the
existing Task 5-7 JavaScript WAD bridge. Task 9 extends that prototype with
basic Doom palette and wall texture support. It keeps the Seed7-generated WASM
framebuffer provider unchanged and does not add sprites, enemies, weapons,
combat, sound, doors, interactions, or a Doom BSP renderer.

## Current Prototype

The browser page has three Canvas modes:

- `Framebuffer`: the original generated-WASM framebuffer demo, or the JavaScript
  fallback when the WASM provider is unavailable.
- `First-person`: the Task 8 ray/segment prototype, with Task 9 wall textures
  when the uploaded WAD supplies supported texture lumps.
- `Top-down Map`: the Task 6-7 debug map renderer.

Uploading `tests/wad_tests/minimal_map.pwad` still parses the WAD directory and
the first supported `E1M1` or `MAP01` map. A successful upload still switches to
the top-down debug view so Task 7 verification remains stable. The
`First-person` button is enabled after the map loads and uses the same map
geometry and player state as the top-down mode.

## Rendering Approach

The prototype casts one ray for each of the 320 Canvas columns across a fixed
66-degree field of view. Each ray is intersected against solid map linedefs from
the uploaded map:

- one-sided linedefs are rendered as walls;
- linedefs with the Doom blocking flag are rendered as walls;
- two-sided non-blocking linedefs are ignored for now.

For each column, the nearest ray/segment intersection is chosen, distance is
corrected by the ray angle offset to reduce fisheye distortion, and a vertical
wall column is projected using a fixed prototype wall height. If the hit
sidedef names a wall texture resolved from `PLAYPAL`, `PNAMES`, `TEXTURE1`, and
patch picture lumps, the column samples that texture with distance shading.
Otherwise, it falls back to the Task 8 shaded untextured column. The upper half
of the framebuffer is a flat ceiling color and the lower half is a flat floor
color.

This is intentionally a stepping-stone renderer. It does not use Doom sectors
for floor or ceiling heights, does not traverse `NODES`/`SSECTORS`/`SEGS`, and
does not sample flats, sprites, or things. See `docs/textures.md` for the
supported texture subset.

## Player State

The first-person and top-down modes share the existing debug player state:

- `x`, `y`, and `angle` are initialized from the first type-1 player start.
- `W` / `S` move forward and backward.
- `A` / `D` strafe left and right.
- `ArrowLeft` / `ArrowRight` and `Q` / `E` turn.
- Collision still uses the Task 7 conservative segment test against solid
  linedefs.

Switching between first-person and top-down modes keeps the current player
position and angle. `Reset` restores the uploaded map's player start.

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

- WAD and map statistics match the Task 4 fixture.
- The page initially switches to `Mode: top-down map view`.
- Clicking `First-person` changes the label to
  `Mode: first-person prototype`.
- The Canvas shows flat ceiling and floor bands with wall columns. The
  synthetic `minimal_map.pwad` uses untextured fallback columns.
- Movement and turning update the first-person view and the status line.
- Clicking `Top-down Map` returns to the debug map view with the same player
  state.
- Clicking `Framebuffer` returns to the generated-WASM framebuffer demo when it
  is available, or to the JavaScript fallback otherwise.

For Task 9 texture verification, generate and select
`tests/wad_tests/textured_map.pwad`; first-person mode should report textured
wall columns and the WAD panel should report one resolved wall texture.
