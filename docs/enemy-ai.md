# Basic Enemy AI

Task 13 adds minimal browser-side AI for shootable placeholder things in the
temporary JavaScript WAD bridge. It keeps the Seed7-generated WASM framebuffer
provider unchanged and does not implement Doom monster definitions, projectiles,
pickups, keys, sound, real sprite decoding, full actor logic, or pathfinding.

## State Machine

Every non-player shootable thing now has one of these debug states:

- `idle`: initialized state after WAD load or Reset.
- `chase`: the enemy has noticed the player and moves toward the player's
  current position.
- `attack`: the enemy is close enough for a melee hit.
- `dead`: the enemy has zero health and no longer moves or attacks.

Player start things remain non-shootable and do not receive AI state.

## Notice And Visibility

An idle enemy notices the player when the player is within a fixed detection
range and an approximate line-of-sight test is clear. The same visibility test
uses the existing solid linedef rules, so one-sided walls, explicitly blocking
linedefs, and closed synthetic doors block sight. Open synthetic doors do not.

Firing the pistol also alerts alive enemies within a larger shot-alert range
when the same approximate visibility test is clear. Hits on a living enemy force
that enemy into `chase` unless the shot kills it.

## Movement

Chasing enemies move directly toward the player's current position. Movement
uses the existing conservative solid-line collision helper with an enemy radius,
so walls and closed doors block movement as much as practical for this
prototype. If a direct step is blocked, the enemy tries the X and Y components
separately for simple sliding.

There is no blockmap, thing collision, sector height handling, route planning,
last-known-position search, or full Doom pathfinding.

## Melee Damage

When an alive enemy is close to the player and still has approximate line of
sight, it enters `attack` and applies a simple melee hit:

- damage: 5 health
- range: 30 map units
- cooldown: 1 second

The cooldown prevents damage every frame. Player health is clamped at zero, but
Task 13 does not add player death, restart flow, HUD faces, armor, or game-state
transitions.

## Rendering And HUD

The top-down debug view colors alive enemies by state:

- idle: blue
- chase: amber
- attack: red
- dead: gray cross

First-person billboard rendering still uses the same depth-sorted placeholder
pass as Task 11. Alive enemies remain visible as billboards; dead enemies are
not drawn in first-person mode.

The Canvas status line includes the existing combat HUD plus enemy state counts
and the last AI event, for example:

```text
ai idle=0 chase=1 attack=0 dead=0 last=detected 1
```

## Fixture

Task 13 reuses the synthetic Task 11/12 fixture:

```bash
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7 --thing-map
```

Then upload:

```text
tests/wad_tests/thing_map.pwad
```

Expected browser behavior:

- the WAD panel reports `Things 2`, `Renderable things 1`,
  `Shootable things 1`, and basic enemy AI support;
- the placeholder enemy starts idle, then notices the player in the square room;
- the top-down marker changes from idle blue to chase amber and attack red when
  close;
- player health decreases by 5 per melee hit at most once per second;
- firing with left mouse, `Ctrl`, or `F` still spends ammo and damages the
  enemy;
- after three pistol hits, the enemy is dead, no longer appears in first-person
  mode, remains a gray cross in top-down mode, and no longer attacks.

## Verification

Recommended Task 13 verification:

```bash
node --check web/main.js
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7 --thing-map
node seed7/bin/s7.js -l seed7/lib -l src/wad src/wad/map_loader.s7 tests/wad_tests/thing_map.pwad
```

Serve the browser demo:

```bash
python -m http.server 8080
```

Open:

```text
http://localhost:8080/web/index.html
```

Upload `tests/wad_tests/thing_map.pwad`, switch between top-down and
first-person mode, wait for the enemy to chase and attack, and confirm that
player health decreases. Then shoot the enemy three times and confirm that it
dies and stops attacking.

Existing Task 3-12 checks should still pass: WAD parsing, map loading,
top-down rendering, movement collision, first-person wall rendering, optional
wall textures, door interaction, placeholder thing rendering, and pistol
hitscan combat.

## Limitations

This AI is intentionally synthetic and debug-oriented. It does not implement
Doom thing definitions, skill flags, monster sounds, pain states, animation
frames, missile attacks, hitscan enemies, corpse blocking, infighting, target
switching, sector-height rules, pathfinding, or real Doom actor state tables.
