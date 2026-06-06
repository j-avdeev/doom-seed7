# Sprites And Things

Task 11 adds browser-side THINGS rendering to the temporary JavaScript WAD
bridge. It keeps the Seed7-generated WASM framebuffer provider unchanged and
does not add combat, weapons, enemy AI, pickups, health, damage, sound, or full
Doom sprite compatibility.

## Parsed Data

The browser upload path now parses every 10-byte `THINGS` record:

- `x`
- `y`
- `angle`
- `thingType`
- `flags`

The first type-1 thing still initializes the debug player start. Player starts
with types `1`, `2`, `3`, `4`, and `11` are excluded from object rendering so
the player spawn does not appear as an enemy or pickup marker.

## Top-Down Rendering

Top-down mode draws each non-player thing as a colored ring with a short angle
line. This is a debug marker only. It uses the same map scaling, player state,
and conservative linedef collision as the previous milestones.

## First-Person Rendering

First-person mode projects non-player things as simple billboard placeholders:

- things are transformed into the player's view space;
- things behind the player or outside the horizontal viewport are skipped;
- projected size shrinks with distance;
- billboards are sorted far-to-near;
- each wall column records an approximate depth, and billboard pixels behind
  nearer walls are skipped.

This gives rough object depth ordering without implementing BSP traversal,
sector heights, sprite clipping rules, or Doom's full rotation/frame naming
scheme.

## Fixture

The synthetic Task 11 fixture contains no commercial Doom data:

```bash
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7 --thing-map
```

Then upload:

```text
tests/wad_tests/thing_map.pwad
```

Expected browser behavior:

- the WAD panel reports `Things 2`;
- the WAD panel reports `Renderable things 1`;
- top-down mode shows one non-player thing marker in the square room;
- first-person mode starts with one placeholder billboard visible in front of
  the player;
- moving or turning changes the billboard projection;
- walls still occlude the placeholder at least per-column.

## Current Limitations

Task 11 intentionally uses placeholder billboards. It does not decode or select
Doom sprite lumps such as `TROOA1`, does not implement rotations, mirrored
frames, animation states, thing flags by skill level, thing collision, pickup
logic, monster logic, weapons, damage, or sound.

Maps with commercial sprite lumps remain user-provided only. The repository does
not bundle copyrighted WAD, sprite, texture, sound, model, or map data.
