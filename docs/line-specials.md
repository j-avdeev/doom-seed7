# Line Specials And Door Interaction

Task 10 adds one browser-side synthetic line special for local interaction
testing. It is not full Doom line-special compatibility and it does not add
sprites, enemies, weapons, combat, sound, or sector-height animation.

## Supported Special

```text
900  synthetic use door
901  synthetic use exit
```

The browser JavaScript map bridge treats linedef special `900` as a simple
use-activated door. The line should also carry the blocking flag in the test
fixture.

Task 15 adds linedef special `901` as a simple use-activated level exit. Press
`Space` while facing the line, or while standing within the debug use distance
of the line, to set the current level state to `level_complete`.

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

Generate the synthetic exit map with:

```bash
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7 --exit-map
```

Then upload:

```text
tests/wad_tests/exit_map.pwad
```

Expected browser behavior:

- the WAD panel reports `Line specials 1 synthetic door special 900`;
- the closed door blocks movement;
- pressing `Space` near the door changes it to opening/open;
- the opened door no longer blocks movement;
- top-down mode colors the door line differently by state;
- first-person mode stops rendering that door line after it opens.

Expected exit behavior:

- the WAD panel reports `1 synthetic exit special 901`;
- first-person mode shows the exit as a green wall labeled `EXIT`;
- top-down mode shows the exit as a green line labeled `EXIT 901`;
- pressing `Space` near the exit line completes the level;
- movement, firing, door/use interaction, and enemy AI stop;
- `LEVEL COMPLETE` is drawn inside the Canvas game view/HUD;
- Reset restarts the current map.

## Limitations

These milestones intentionally do not implement Doom door or exit types, sector
height motion, keyed doors, switches, repeatable trigger variants, tags across
multiple sectors, monster activation, sound, closing behavior, intermission
screens, or episode progression.
