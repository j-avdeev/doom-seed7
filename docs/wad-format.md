# Doom WAD Format

Task 3 implements only the WAD header and lump directory. It does not load maps,
textures, rendering data, or gameplay state.

## Header

A Doom WAD starts with a 12-byte little-endian header:

```text
bytes 0..3   magic: "IWAD" or "PWAD"
bytes 4..7   signed 32-bit lump count
bytes 8..11  signed 32-bit directory offset from the start of the file
```

The Seed7 parser stores these fields in `wadHeader`.

## Directory Entries

The directory contains one 16-byte entry per lump:

```text
bytes 0..3   signed 32-bit lump data offset
bytes 4..7   signed 32-bit lump data size
bytes 8..15  lump name, maximum 8 ASCII bytes, null padded
```

The parser stores entries as `wadLump` records and keeps them in order in
`wadDirectory.lumps`. Lump names are normalized to uppercase and trimmed at the
first null byte.

## Lookup

`find_lump_by_name(wad, name)` returns the one-based index of the first matching
lump name, or `0` if no lump exists. The lookup normalizes the requested name to
uppercase and limits it to the Doom 8-byte lump-name width.

## Synthetic Fixture

No copyrighted IWAD or PWAD is required. The repository includes a synthetic hex
fixture:

```text
tests/wad_tests/minimal_pwad.hex
```

Generate a binary test WAD:

```bash
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7
```

Parse it and test lookup:

```bash
node seed7/bin/s7.js -l seed7/lib -l src/wad src/wad/wad_reader.s7 tests/wad_tests/minimal.pwad --find TEST
```

Expected key output:

```text
wad_type=PWAD
lump_count=3
directory_offset=16
  1 name=TEST offset=12 size=4
  2 name=EMPTY offset=0 size=0
  3 name=END offset=0 size=0
find_lump_by_name name=TEST index=1 offset=12 size=4
```
