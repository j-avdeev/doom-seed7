# Basic Combat

Task 12 adds minimal browser-side combat to the temporary JavaScript WAD bridge.
It keeps the Seed7-generated WASM framebuffer provider unchanged and does not
add enemy AI, enemy attacks, pickups, sound, advanced Doom weapon behavior, or
real Doom sprite decoding.

## Player State

When a supported map is loaded, the debug player state now includes:

- `health`: starts at `100`, but nothing can damage the player yet.
- `currentWeapon`: always `pistol`.
- `ammo`: starts at `24`.

`Reset` restores player position, health, ammo, door state, and thing health.

## Shootable Things

Every non-player map thing is initialized as a shootable placeholder with 3
health. Player start things with types `1`, `2`, `3`, `4`, and `11` are not
shootable.

When a shootable thing reaches zero health, it is marked dead. Dead things:

- disappear from the first-person placeholder billboard pass;
- remain visible in top-down mode as a gray cross for debugging;
- no longer receive hitscan damage.

## Firing

The browser demo supports these fire inputs in top-down and first-person modes:

- left mouse click on the Canvas;
- `Ctrl`;
- `F`.

`Space` remains the Task 10 door interaction key.

The pistol is a simple hitscan weapon:

- one ammo is spent per shot;
- no spread, cooldown, recoil, animation, sound, or Doom weapon state is
  implemented;
- the shot follows the player's current view direction;
- the closest alive shootable thing within a small fixed aim radius is selected;
- blocking walls and closed synthetic doors stop the shot.

The Canvas status line acts as the current HUD. It reports player health,
weapon, ammo, visible thing count, alive shootable thing count, and the last
shot result such as `shot=miss`, `shot=hit thing#2 hp=2`, or
`shot=kill thing#2`.

## Fixture

Task 12 reuses the Task 11 synthetic thing fixture:

```bash
node seed7/bin/s7.js -l seed7/lib tests/wad_tests/make_minimal_wad.s7 --thing-map
```

Then upload:

```text
tests/wad_tests/thing_map.pwad
```

Expected browser behavior:

- the WAD panel reports `Things 2`, `Renderable things 1`, and
  `Shootable things 1`;
- first-person mode starts with one placeholder thing visible;
- firing at the placeholder reports a hit and decrements ammo;
- after three hits, the placeholder is killed and disappears in first-person
  mode;
- top-down mode shows the killed thing as a gray cross;
- firing away from the thing reports a miss.

## Current Limitations

Combat is intentionally synthetic and debug-oriented. It does not implement Doom
thing definitions, actor states, monster behavior, thing collision, blockmap
queries, skill flags, damage randomness, weapon bob, muzzle flash, ammo pickups,
enemy attacks, player death, sound, or sprite lump rendering.

The current implementation is suitable only for proving that visible
placeholder things can be aimed at, damaged, and killed from the browser
first-person view.
