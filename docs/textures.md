# Doom Palette And Wall Textures

Task 9 adds basic browser-side wall texture support to the temporary
JavaScript WAD bridge and first-person prototype. It leaves the
Seed7-generated WASM framebuffer provider unchanged.

## Supported Format

The browser upload path now recognizes these classic Doom lumps when they are
present in the selected WAD:

- `PLAYPAL`: reads the first 256-color palette and expands indexed pixels to
  RGBA.
- `PNAMES`: reads the patch name table.
- `TEXTURE1`: reads texture names, dimensions, and patch placements.
- patch picture lumps referenced by resolved wall textures.

Patch pictures are decoded as vanilla Doom column/post images. Transparent gaps
inside patches remain transparent while textures are composed, then unresolved
or transparent wall pixels fall back to the existing shaded wall color.

The renderer samples wall textures on the existing ray/segment column renderer:

- one-sided linedefs and explicitly blocking linedefs are still the only wall
  candidates;
- the visible sidedef is chosen from the player side when possible;
- sidedef `middleTexture` is preferred, then `upperTexture`, then
  `lowerTexture`;
- sidedef `xOffset` and `yOffset` are applied;
- texture coordinates wrap across the texture dimensions;
- ceiling and floor remain flat color bands.

## Fallback Behavior

Maps without `PLAYPAL`, `PNAMES`, `TEXTURE1`, or required patch lumps still load.
The first-person mode then uses the Task 8 shaded untextured columns. This keeps
`tests/wad_tests/minimal_map.pwad` working.

The WAD panel reports either the number of resolved wall textures or the fallback
reason after a map loads.

## Test Fixture

The synthetic Task 9 fixture contains no commercial Doom data. Generate it with:

```bash
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7 --textured-map
```

Then select:

```text
tests/wad_tests/textured_map.pwad
```

Expected browser behavior:

- the WAD panel reports `PLAYPAL`, `PNAMES`, `TEXTURE1`, `PATCH1`, and `E1M1`;
- map stats match the square map fixture;
- wall textures report `1 of 1 resolved`;
- first-person mode shows textured wall columns while top-down and framebuffer
  modes remain available.

## Current Limitations

Task 9 intentionally does not implement:

- `TEXTURE2`;
- flat floor or ceiling texture rendering;
- Doom sector height projection, pegging rules, or sidedef upper/lower wall
  selection from sector height differences;
- `COLORMAP` lighting tables, palette swaps, or full Doom distance lighting;
- BSP traversal from `NODES`, `SSECTORS`, or `SEGS`;
- sprites, things, enemies, weapons, combat, doors, interactions, exits, or
  sound.
