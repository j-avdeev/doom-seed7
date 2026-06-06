# Doom Map Structures

Task 4 loads one Doom map from an already parsed WAD directory. It is a data
loader only: no BSP traversal, rendering, texture loading, browser upload,
enemies, weapons, or gameplay are implemented.

## Supported Map Markers

The loader searches the WAD directory in order and loads the first supported map
marker:

```text
E1M1
MAP01
```

Map data lumps are searched only after the selected marker and before another
supported marker. This keeps map loading independent of any same-named global
lumps elsewhere in the WAD.

## Loaded Lumps

The Task 4 loader reads these classic Doom map lumps into Seed7 records:

```text
THINGS    10 bytes per record
LINEDEFS  14 bytes per record
SIDEDEFS  30 bytes per record
VERTEXES   4 bytes per record
SECTORS   26 bytes per record
```

The corresponding Seed7 records live in `src/wad/map_types.s7`:

```text
mapThing
mapLinedef
mapSidedef
mapVertex
mapSector
doomMap
```

The loader uses arrays and explicit integer indexes instead of pointer-style
structures. WAD indexes remain the original Doom zero-based values where the
format uses indexes, such as vertex and sidedef references.

## Player Start

The player start is the first `THINGS` record with type `1`. The loader reports
the player start position and angle and treats a missing player start as a load
failure for this milestone.

## Synthetic Fixture

No copyrighted WAD data is required. The repository includes a fake map fixture:

```text
tests/wad_tests/minimal_map_pwad.hex
```

Generate it:

```bash
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7 --map
```

Load the fake map:

```bash
node seed7/bin/s7.js -l seed7/lib -l src/wad src/wad/map_loader.s7 tests/wad_tests/minimal_map.pwad
```

Expected key output:

```text
map_name=E1M1
vertex_count=4
linedef_count=4
sidedef_count=4
sector_count=1
thing_count=1
player_start_x=128
player_start_y=64
player_start_angle=90
```

The fake map is one square sector with four vertices, four one-sided linedefs,
four sidedefs, one sector, and one type-1 player start.
