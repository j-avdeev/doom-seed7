# Line Specials And Door Interaction

Task 10 adds one browser-side synthetic line special for local interaction
testing. It is not full Doom line-special compatibility and it does not add
sprites, enemies, weapons, combat, sound, or sector-height animation.

## Supported Special

```text
900  synthetic use door
```

The browser JavaScript map bridge treats linedef special `900` as a simple
use-activated door. The line should also carry the blocking flag in the test
fixture.

Door states:

- `closed`: the line blocks movement and renders as a wall.
- `opening`: the line still blocks briefly while the debug state advances.
- `open`: the line no longer blocks movement and first-person rays ignore it.

Press `Space` while facing the special line within the debug use distance to
open it.

## Test Fixture

Generate the synthetic door map with:

```bash
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7 --door-map
```

Then upload:

```text
tests/wad_tests/door_map.pwad
```

Expected browser behavior:

- the WAD panel reports `Line specials 1 synthetic door special 900`;
- the closed door blocks movement;
- pressing `Space` near the door changes it to opening/open;
- the opened door no longer blocks movement;
- top-down mode colors the door line differently by state;
- first-person mode stops rendering that door line after it opens.

## Limitations

This milestone intentionally does not implement Doom door types, sector height
motion, keyed doors, switches, repeatable trigger variants, tags across multiple
sectors, monster activation, sound, or closing behavior.
