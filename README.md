# Doom Seed7

This repository now tracks the Doom 3 Seed7 development line:

- The legacy standalone prototype entry has been removed; Doom3 flow is now only through `doom3.html` and `doom3_seed7*.s7` entrypoints.

- `doom3_seed7.s7`: the Doom 3/id Tech 4 foundation and scanner entrypoint.
- `doom3_seed7_inventory.s7`: a focused gameplay subsystem probe for pickup/inventory readiness.
- `doom3_seed7_combat.s7`: a focused gameplay subsystem probe for selected-map `.cm` collision-backed weapon/ammo/monster combat readiness.
- `doom3_seed7_ai.s7`: a focused gameplay subsystem probe for monster definition inheritance, script/animation/sound binding, and deterministic AI state readiness.
- `doom3_seed7_objective.s7`: a focused gameplay subsystem probe for objective text, trigger target links, door activation, clear conditions, next-map spawn readiness, and next-map `.proc`/`.cm` companion readiness.
- `doom3_seed7_level.s7`: a focused level-flow subsystem probe for map cataloging, next-map `.proc`/`.cm` asset resolution, transition state, and spawn readiness after a map change.
- `doom3_seed7_model.s7`: a focused asset subsystem probe for model asset, `modelDef`, entity model binding, and first-pass `.md5mesh` / `.md5anim` metadata readiness.
- `doom3_seed7_pose.s7`: a focused skeletal-animation probe for first-pass `.md5mesh` / `.md5anim` pose sampling, weight skinning, skinned bounds, selected-map animated entity binding, material texture resolution, renderer draw-call handoff readiness, and first camera/light/visibility metadata for animated actors.
- `doom3_seed7_weapon.s7`: a focused gameplay subsystem probe for Doom 3-style weapon definitions, ammo bindings, projectile definitions, fire sounds, first-person `model_view` binding, projectile count/spread firing plan metadata, and selected-map `.cm` collision-backed firing readiness.
- `doom3_seed7_projectile.s7`: a focused gameplay subsystem probe for projectile definition/model binding, weapon projectile count/spread launch planning, spawned projectile travel, impact damage, splash radius metadata, and cleanup readiness.
- `doom3_seed7_fx.s7`: a focused effects subsystem probe for projectile `fx_*` spawnargs, `.fx` declarations, particle assets, sound/decal/light references, and deterministic impact-effect readiness.
- `doom3_seed7_cinematic.s7`: a focused cinematic/video subsystem probe for RoQ-style video asset discovery, GUI/background video references, worldspawn cinematic references, header fallback handling, and deterministic playback-plan readiness.
- `doom3_seed7_gui.s7`: a focused UI subsystem probe for `.gui` assets, HUD/window declarations, entity/map GUI bindings, and runtime GUI-surface readiness.
- `doom3_seed7_sound.s7`: a focused audio subsystem probe for sound shader declarations, sample readiness, entity sound bindings, and runtime sound-event readiness.
- `doom3_seed7_audio.s7`: a focused audio metadata probe for `.wav` / `.ogg` sample headers, PCM/channel/rate/duration buckets, and mixer-readiness planning.
- `doom3_seed7_aas.s7`: a focused AI navigation subsystem probe for selected-map `.aas` companion discovery, area/reachability graph parsing, and deterministic player-to-monster path readiness.
- `doom3_seed7_script.s7`: a focused gameplay subsystem probe for script object/function binding plus first-pass executable script-event readiness.
- `doom3_seed7_scheduler.s7`: a focused gameplay subsystem probe for wait-delayed script scheduling, queued event dispatch, target activation, objective-complete readiness, next-map `.proc`/`.cm` companion readiness, and a first frame-clear gate that combines delayed script completion with door activation, monster defeat, and loadable next-map data.
- `doom3_seed7_trace.s7`: a focused world subsystem probe for coarse brush/entity trace readiness plus selected-map `.cm` version, collision-model name, geometry companion readiness, first collision polygon material/contents/plane handoff, first compiled plane point/segment hit tests with hit fraction, compiled segment-trace blocking/nonblocking classification, and compiled collision blocking/nonblocking classification.
- `doom3_seed7_vfs.s7`: a focused virtual-filesystem probe for pk4 mount order and selected-map override readiness.
- `doom3_seed7_platform.s7`: a focused platform subsystem probe for config files, console cvars, key/action binds, deterministic input translation, timing, and save/config path plumbing.
- `doom3_seed7_console.s7`: a focused console command-buffer probe for quoted command parsing, semicolon splitting, `exec`, aliases, `wait`, `map` / `devmap`, cvars, binds, and unsupported-command reporting.
- `doom3_seed7_lang.s7`: a focused localization subsystem probe for `strings/*.lang` tables, `#str_*` references in GUI/map/decl text, resolved text, and placeholder fallback readiness.
- `doom3_seed7_pda.s7`: a focused PDA subsystem probe for `.pda` email/audio/video entries, localized PDA labels, referenced audio/video/GUI assets, and placeholder-free runtime entry readiness.
- `doom3_seed7_access.s7`: a focused security/access probe for PDA-granted door authorization, selected-map door/trigger resolution, and first locked-to-unlocked runtime access readiness.
- `doom3_seed7_armor.s7`: a focused armor/damage probe for selected-map `.cm` collision-backed PDA suit armor state, monster melee damage definitions, armor absorption, health damage, and HUD armor readiness.
- `doom3_seed7_survival.s7`: a focused survival-loop probe that combines PDA armor, `g_skill` / `--doom3_skill` difficulty scaling, weapon/projectile damage, inherited monster health/damage, selected-map pickups, ammo use, armor absorption, HUD survival state, clear/death terminal-state readiness, next-map `.proc`/`.cm` transition readiness, post-terminal load-next/restart-current planning, and save/restore snapshot verification.
- `doom3_seed7_campaign.s7`: a focused campaign-flow probe that connects selected-map loading, next-map `.proc`/`.cm` transition readiness, clear-to-next-map autosave, death-to-current-map checkpoint restart, and restore verification.
- `doom3_seed7_playloop.s7`: a focused playable-loop probe that connects session load, config input binds, selected and next-map `.proc`/`.cm` companion readiness, gameplay ticks, render submission, presentation-frame handoff, audio events, HUD state, next-map loading, post-transition frame readiness, pause/menu resume, quicksave restore, and restart-current checkpoint restore.
- `doom3_seed7_math.s7`: a focused core-math subsystem probe for vectors, planes, bounds, yaw basis, segment-plane hits, and frustum-style visibility tests.
- `doom3_seed7_parser.s7`: a focused Doom text lexer/parser probe for comments, quoted strings, braces, parentheses, selected-map entity key/value parsing, declaration names, script functions, and GUI `windowDef` names.
- `doom3_seed7_decl.s7`: a focused declaration-registry probe for material, entityDef, skin, sound, and model decl cataloging with pk4 mount-order override semantics.
- `doom3_seed7_resource.s7`: a focused resource-manager probe for asset catalogs, decl/map reference resolution, and placeholder fallback reporting for missing resources.
- `doom3_seed7_texture.s7`: a focused texture subsystem probe for `.tga` / `.dds` image header metadata, upload-planning format buckets, and mip-level readiness.
- `doom3_seed7_material.s7`: a focused material-compatibility probe for `.mtr` stage classification, image directives, render flags, animated transforms, pk4 override counts, and unsupported shader fallback reporting.
- `doom3_seed7_lighting.s7`: a focused renderer-lighting probe for selected-map light entities, material shadow flags, lit brush/patch surfaces, shadow-caster suppression, and first shadow-volume fallback planning.
- `doom3_seed7_session.s7`: a focused session-flow probe for loading, running, pause/menu, main-menu GUI action discovery, restart, save/restore snapshot, and next-map `.proc`/`.cm` transition readiness.
- `doom3_seed7_save.s7`: a focused savegame subsystem probe for save-slot metadata, selected-map state serialization, checksum verification, restore-state validation, and next-map `.proc`/`.cm` transition readiness.
- `doom3_seed7_physics.s7`: a focused player-physics subsystem probe for selected-map spawn state, `.cm` collision companion data, floor contact, gravity, slide response, step-up response, and clipped movement readiness.
- `doom3_seed7_interaction.s7`: a focused player-interaction subsystem probe for `_use` input binding, selected-map `.cm` collision-backed focus traces, trigger target resolution, door activation, world/HUD GUI references, and GUI action readiness.
- `doom3_seed7_spawn.s7`: a focused entity-spawn subsystem probe for merging selected-map spawnargs with inherited `entityDef` defaults, selected-map `.cm` collision-backed runtime component creation, and model/sound/GUI/target resolution.
- `doom3_seed7_mover.s7`: a focused mover-door subsystem probe for trigger and script activation, door sound resolution, selected-map `.cm` collision-backed closed/open state transitions, collision-state changes, and idempotent activation readiness.
- `doom3_seed7_render.s7`: a focused renderer-front-end probe for material-bound brush and patch surfaces, selected-map `.proc` version/model identity, render-surface, draw-call, area-portal, first visibility-scope handoff, and portal-flood visibility summary, common material image directives, animated material-stage sampling, renderable entity model/animation/skin binding, first MD5 animated actor draw-call handoff, light contribution, depth rejection, and a deterministic ASCII framebuffer.
- `doom3_seed7_submit.s7`: a focused frame-to-render submission probe that binds a selected-map monster through inherited `entityDef` model/animation/skin/spawnclass/health data, binds a weapon `model_view`, and emits first animated actor plus view-relative weapon renderer submissions.
- `doom3_seed7_view.s7`: a focused renderView/camera probe for selected-map player camera extraction, FOV/aspect projection setup, viewport/scissor metadata, `.proc` portal-area visibility handoff, and first-person weapon-view projection planning.
- `doom3_seed7_compiledmap.s7`: a focused map-data probe for selected-map `.proc` render-geometry and `.cm` collision-model companion readiness, including first compiled segment-trace hit/skip classification.
- `doom3_seed7_frame.s7`: a focused gameplay subsystem probe for one integrated map/game-frame update, runtime model/animation/skin/spawnclass binding, HUD/GUI binding, collision-gated player movement, weapon/projectile definition-driven combat, coarse frame hitscan/world-trace gating, script-event dispatch, frame sound-event dispatch, next-map `.proc`/`.cm` transition preparation, plus a small persistent multi-tick loop.

The Doom 3 port track is based on the GPL source-port plan, but it does not bundle commercial Doom 3 assets. You must point it at a legal Doom 3 installation that contains `base/*.pk4`.

## Doom 3 Port Foundation

`doom3_seed7.s7` is Stage 1 of the true port. It starts as a command-line/runtime asset scanner rather than a playable renderer.

Implemented:

- command-line config for `doom3_data_path`, `doom3_base_path`, `doom3_start_map`, and `doom3_render_mode`
- Doom-style aliases: `+set fs_basepath`, `+set fs_game`, and `+map`
- minimal console-variable registry for runtime config plus arbitrary `--set` / `+set` values
- save/config path options for later persistence wiring, logged but not written in Stage 1
- base directory detection
- `.pk4` discovery under `base/`
- pk4 mounting through Seed7's zip filesystem
- pk4 mount-order handling for selected-map metadata, where later archives can override earlier archives
- recursive metadata scan for `.decl`, `.mtr`, `.def`, `.map`, `.script`, image, and sound paths
- top-level selected-map compiled companion checks for matching `.proc` and `.cm` paths before later renderer/collision probes depend on them
- first content parser pass for text assets:
  - image references in materials/defs/scripts/maps
  - sound references in defs/scripts/maps
  - `entityDef` declarations
  - named `entityDef` declarations for map-class compatibility checks
  - simple `entityDef` spawnargs such as `health`, `model`, `snd_*`, `inherit`, `mins`, and `maxs` for runtime entity initialization planning
  - material declaration names from `.mtr` files
  - material texture references and matching image assets for renderer texture fallback planning
  - first material-to-texture bindings from `.mtr` declarations for render-surface texture selection
  - renderer-impacting material flags such as `noshadows`, `twosided`, `translucent`, and `blend`
  - sound references and matching sound assets for audio fallback planning
  - model assets for selected map `model` key fallback planning
  - map entity `"classname"` entries
  - map classname category buckets for lights, `func_static`, doors, triggers, monsters, items, pickups, and player starts
  - script `void` functions
  - script-related spawnarg references such as `scriptobject` and `call` in defs/maps
- material block/stage markers
- separate script-scheduler probe coverage for map `call` resolution, immediate script events, `wait`-queued delayed events, door target activation, objective completion, fixed-tick dispatch timing, next-map `.proc`/`.cm` readiness, and frame-clear gating after delayed script completion plus simulated combat resolution
- selected map lookup from `+map` / `doom3_start_map`, normalized to `maps/<name>.map`
- first map entity extraction for `worldspawn` and `info_player_start` origin/angle
- public scanner reporting for the selected map's expected compiled `.proc` / `.cm` sibling asset paths and whether both were mounted
- selected map entity-key summary for `classname`, `name`, `origin`, `model`, `snd_*`, `health`, `target`, `mins`, and `maxs`
- typed selected-map entity records with parsed origin, yaw, health, and sound values for Stage 2 world initialization
- entity bounds metadata detection from map/entityDef `mins` and `maxs` so later collision can move from radius fallback to real spawn bounds
- runtime entity spawn records derived from selected-map entities, with kind, active, solid, trigger, origin, yaw, and initial health state
- runtime entity health overrides from map `health` spawnargs or parsed `entityDef` `health` spawnargs, including custom monster health reporting
- runtime entity model fallback from parsed `entityDef` `model` spawnargs when a map entity has no direct `model` key
- runtime model readiness matching entityDef/map-provided model references against mounted model assets
- runtime entity sound fallback from map or parsed `entityDef` `snd_*` spawnargs
- runtime sound readiness matching entity sound references against mounted sound assets
- bounded `entityDef` inheritance resolution so runtime health, model, and sound values can come from parent definitions
- map-level runtime override counts for per-instance health and sound spawnargs
- script spawnarg reference counts so the future game-frame layer can identify entities that need script binding
- runtime entity kind summary for player spawns, lights, statics, doors, triggers, monsters, and pickups
- health item, ammo, and weapon pickup class recognition through `item_*`, `ammo_*`, and `weapon_*` runtime entities
- unsupported selected-map entity reporting so future compatibility gaps are visible instead of silent
- runtime solid-entity collision checks for the first movement probe and fixed-step player simulation
- trigger-activated runtime door state, where activated doors are reported and no longer block the simulated player path
- selected target-link readiness summary matching map `target` keys against named entities
- spawn-relevant selected map count for player starts, lights, statics, doors, triggers, monsters, items, ammo, and weapons
- selected spawn classname compatibility summary against parsed `entityDef` declarations and engine built-ins
- selected map material reference summary with declared/missing material counts for renderer fallback planning
- selected brush/patch surface material summaries so Stage 2 can separate render-ready surfaces from placeholder surfaces
- typed selected brush plane records with normal, distance, and material name for first collision/render geometry loading
- coarse selected brush bounds derived from axis-aligned `brushDef3` planes for first collision broadphase and debug rendering
- runtime render-surface records derived from complete brush bounds for the first static renderer frontend
- renderer material readiness counts showing declared materials versus fallback-material surfaces
- first render-surface texture binding and asset-availability check for the static renderer path
- material compatibility flag counts for shadow, two-sided, translucent, and blend-stage planning
- renderer-front-end animated material readiness for `.mtr` stage counts, blend stages, `scroll` / `rotate` transforms, time-expression detection, and deterministic sampled UV/rotation state
- deterministic renderer fallback colors for surfaces whose full material pipeline is not translated yet
- first camera-facing render queue from runtime render surfaces using player position and yaw
- nearest queued render-surface metadata, including material, fallback color, and squared distance
- first dynamic-light influence pass for queued render surfaces using parsed light origins, radius vectors, and light colors
- lit render-queue counts plus nearest-surface light count/color metadata for the first renderer lighting contract
- player spawn collision readiness against coarse brush bounds, including blocking-bound count and clear/blocked status
- player spawn collision readiness against runtime solid entities such as doors, statics, and monsters
- first forward movement probe from player spawn yaw with coarse brush and runtime entity collision clear/blocked status
- first-frame movement acceptance result that either advances to the probe point or keeps the player at spawn when blocked
- short fixed-step player movement simulation that advances until a coarse brush or runtime solid-entity collision stops it
- coarse top-down debug render metrics centered on the simulated player, including view bounds, player grid cell, and visible brush bounds
- ASCII top-down debug frame rows using `P` for player, `#` for coarse brush cells, and `.` for empty cells
- light overlay in the ASCII debug frame using `L` for parsed light entities with visible origins
- gameplay entity overlay in the ASCII debug frame from runtime spawn records using `S` statics, `D` doors, `T` triggers, `M` monsters, and `I` items/pickups
- first trigger interaction simulation that reports touched triggers and resolved target entities after the player movement simulation
- activated-door debug state derived from touched trigger targets, using `O` for doors activated by the simulated player path
- selected map origin bounds from parsed entity `origin` vectors for first world/camera extents
- selected brush plane-line counts for first collision/render geometry readiness checks
- selected light entity readiness summary for `origin`, `light_radius`, and `_color` values
- material texture readiness summary matching `.mtr` texture references against image assets inside mounted pk4 archives
- sound readiness summary matching text sound references against sound assets inside mounted pk4 archives
- selected model readiness summary matching map `model` references against model assets inside mounted pk4 archives
- first spawn-relevant entity summary for Stage 2 world/entity initialization
- numeric player spawn state from `info_player_start`:
  - `player_spawn_x`
  - `player_spawn_y`
  - `player_spawn_z`
  - `player_spawn_yaw`
- static map primitive counters for `brushDef3` and `patchDef2` / `patchDef3`
- separate compiled-map probe coverage for selected-map `.proc` and `.cm` companion assets, including first-pass companion version checks, render/collision model-pair matching, render surface/vertex/index counters, `.proc` area/portal header, first portal records, first visibility-scope summary, portal-flood visibility summary, `.proc` material and texture binding validation against mounted `.mtr` declarations and image assets, first compiled-surface and draw-call renderer handoff summaries, and `.cm` vertex/edge/polygon/brush counters plus first collision payload, polygon material/contents/plane, material declaration, material-aware blocking/nonblocking classification, and compiled segment-trace hit/skip handoff records
- separate platform probe coverage for Doom-style `.cfg` files, `set` / `seta` cvars, `bind` key/action records, an ordered startup command buffer where config commands run before command-line `+set` / `+bind` / `+map` overrides, fixed-frame timing values, deterministic input-frame translation, and save/config path reporting
- separate console command-buffer probe coverage for quoted arguments, semicolon-separated commands, config `exec`, command-line startup commands, aliases, `wait`, `map` / `devmap`, cvars, binds, and visible unsupported-command reporting
- separate localization probe coverage for `strings/*.lang` parsing, selected language filtering, `#str_*` GUI/map/decl reference discovery, resolved/missing string counts, and placeholder fallback reporting
- separate PDA probe coverage for `.pda` cataloging, email/audio/video entry discovery, localized PDA labels, referenced GUI/audio/video asset resolution, and placeholder-free runtime entry readiness
- separate security/access probe coverage for PDA-granted door authorization, selected-map door and trigger-target resolution, and locked-to-unlocked runtime access readiness
- separate armor/damage probe coverage for PDA-provided suit armor state, selected-map monster/player readiness, melee damage definition parsing, armor absorption, health damage, and HUD armor state
- separate survival-loop probe coverage for armor-aware combat over multiple ticks, including `g_skill` difficulty scaling, ammo consumption, inherited monster health/damage, projectile damage, HUD health/armor state, clear/death terminal readiness, next-map `.proc`/`.cm` transition readiness, post-terminal load-next/restart-current planning, and save/restore snapshot verification
- separate campaign-flow probe coverage for selected-map load state, next-map `.proc`/`.cm` transition readiness, clear-to-next-map autosave metadata, next-map spawn readiness, death-to-current-map checkpoint metadata, and restore verification for both terminal paths
- separate playable-loop probe coverage for config input actions, selected-map and next-map `.proc`/`.cm` companion readiness, selected-map gameplay ticks, render-frame submission, presentation-frame pass/hash readiness, audio-event emission, HUD state, clear condition, load-next readiness, carried player state, post-transition frame readiness, pause/menu resume, quicksave restore, and restart-current checkpoint restore in one end-to-end runtime path
- separate core-math probe coverage for vector subtraction/dot/length, yaw-derived forward/right basis vectors, plane distance and segment-hit fraction, expanded bounds intersection, and a deterministic frustum-style visibility test
- separate lexer/parser probe coverage for Doom text tokenization, line/block comment skipping, quoted string preservation, brace/paren accounting, selected-map entity key/value parsing, declaration headers, script functions, and GUI windows
- separate declaration-registry probe coverage for material, `entityDef`, skin, sound shader, and model decl names, inherited entityDef counts, material-stage hints, skin remaps, sound sample references, unique decl keys, and later-pk4 override detection
- separate resource-manager probe coverage for image/sound/model/GUI/script asset catalogs, material texture refs, model/animation refs, sound refs, GUI refs, skin refs, resolved/missing counts, and placeholder fallback totals
- separate audio metadata probe coverage for mounted `.wav` / `.ogg` sample headers, PCM versus non-PCM buckets, channel counts, sample rates, durations, and invalid-header fallback reporting
- separate AAS/navigation probe coverage for selected-map `.aas` companion discovery, agent settings, area/reachability graph parsing, nearest-area binding for player/monster origins, deterministic path readiness, and a first monster path-following runtime step with attack/damage result
- AI probe integration with selected-map `.aas` navigation data, including monster-area to player-area path resolution and a first path-following movement step before melee-state readiness is reported
- separate texture metadata probe coverage for mounted `.tga` / `.dds` image headers, width/height/bpp/FourCC/mip counts, compressed versus uncompressed upload buckets, and invalid-header fallback reporting
- separate material-compatibility probe coverage for `.mtr` raw/unique/override declaration counts, stage blends, stage image directives, material flags, animated transforms, renderer-ready/fallback classification, and unsupported shader feature logging
- separate lighting/shadow-readiness probe coverage for selected-map light origins/radius/color, material shadow flags, lit brush/patch surfaces, shadow-casting suppression, and first fallback shadow-volume planning
- separate skeletal pose/skinning probe coverage for first MD5 mesh/animation pair compatibility, deterministic frame interpolation, weighted vertex output, triangle handoff, skinned bounds, selected-map animated entity model/anim/skin binding, material texture resolution, world-space animated bounds, first animated draw-call handoff, and camera/depth/light/occlusion metadata for that animated draw-call
- separate session-flow probe coverage for selected-map loading, config binds, pause/menu action readiness, main-menu GUI start/resume/restart/quit action discovery, GUI reference resolution, restart readiness, save/restore snapshot readiness, and next-map `.proc`/`.cm` transition readiness with selected-map pk4 override semantics
- separate savegame probe coverage for selected-map save-slot manifests, serialized autosave and restart-checkpoint state, checksum verification, restored health/ammo/objective/screen values, restart-current metadata, and next-map `.proc`/`.cm` transition metadata
- separate player-physics probe coverage for selected-map spawn extraction, `.cm` identity/classification, floor-contact derivation, fixed-tick gravity, blocked/accepted movement counts, slide response, step-up response, clipped velocity, and first collision-plane handoff
- separate player-interaction probe coverage for `_use` bind readiness, selected-map `.cm` collision-backed trigger and door links, target resolution, first focus/use trace, activated-door result, world/HUD GUI reference resolution, and GUI action readiness
- separate entity-spawn probe coverage for inherited `entityDef` template data, selected-map spawn records, selected-map `.cm` collision-backed typed runtime component counts, map-level health/sound overrides, and model/sound/GUI/target resolution
- separate mover-door probe coverage for selected-map door entities, trigger targets, script-trigger calls, open-sound resolution, selected-map `.cm` collision-backed closed/open state transitions, solid/open collision toggles, and idempotent activation when script and trigger paths hit the same door
- separate projectile runtime probe coverage for weapon-to-projectile resolution, projectile count/spread launch planning, projectile model binding, deterministic projectile travel by speed over fixed ticks, impact damage application, splash damage/radius metadata, and projectile removal
- separate FX/particle probe coverage for projectile impact `fx_*` spawnargs, `.fx` declaration lookup, particle asset resolution, sound/decal/light effect references, and deterministic impact-effect event planning
- separate cinematic/video probe coverage for mounted video asset discovery, GUI and map cinematic references, RoQ header fallback, and deterministic runtime playback planning
- separate renderView/camera probe coverage for player-spawn view state, FOV/aspect projection, viewport/scissor metadata, portal visibility scope, and first-person weapon-view depth-hack planning
- clear errors when Doom 3 assets are missing
- `*.pk4` ignored by git so commercial data is not committed accidentally

Run:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

Or with Doom-style arguments:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7.s7 +set fs_basepath "C:\Path\To\Doom 3" +map game/mars_city1
```

Native one-command run (play-loop entrypoint):

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\run_doom3_seed7_native.ps1 -DataPath "C:\Path\To\Doom 3" -Build
```

Browser launcher:

```bash
python -m http.server 8080
```

Open:

```text
http://localhost:8080/doom3.html
```

The browser launcher is Doom 3-only in this branch. It can run immediately with the generated synthetic fixture at `fixtures/base/pak000.pk4`, or it can mount optional legal local `.pk4` files under `/doom3/base`. It runs `doom3_seed7_runtime.s7` through `wasm/s7.js`.
If you need older probe outputs from the command line, run the dedicated `doom3_seed7_*.s7` scripts directly.

Smoke test the true port entrypoint:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\smoke_doom3_seed7.ps1
```

The smoke script creates a temporary synthetic `base/pak000.pk4` fixture with original placeholder data, then asserts parser, material, entity, trigger/door, render-queue, runtime readiness, inventory subsystem, combat subsystem, AI subsystem, AAS/navigation subsystem, objective subsystem, level-flow subsystem, model subsystem, pose/skinning subsystem, weapon subsystem, projectile subsystem, FX/particle subsystem, cinematic/video subsystem, GUI subsystem, sound subsystem, audio metadata subsystem, script subsystem, scheduler subsystem, trace subsystem, text lexer/parser subsystem, console command-buffer subsystem, localization/string-table subsystem, PDA/email/audio-log subsystem, security/access subsystem, armor/damage subsystem, armor-aware survival-loop subsystem with default and Nightmare `g_skill` scaling plus clear/death transition, next-map `.proc`/`.cm` readiness, and post-terminal action snapshot restore verification, campaign-flow subsystem with clear/load-next and death/restart-current restore verification, playable-loop subsystem with selected `.proc`/`.cm` companion readiness plus input/game/render/presentation/audio/HUD/transition, post-transition frame readiness, pause/menu resume, quicksave restore, and restart-current checkpoint restore, resource-manager subsystem, texture metadata subsystem, material-compatibility subsystem, lighting/shadow-readiness subsystem, session-flow/menu-action subsystem, save/restore subsystem, player-physics subsystem, player-interaction subsystem, entity-spawn subsystem, mover-door subsystem, renderer-front-end subsystem, renderView/camera subsystem, and game-frame subsystem markers, including frame-level next-map `.proc`/`.cm` transition readiness. It also creates a separate two-pk4 fixture to verify that later mounted archives can override selected map metadata, session loading state, and material declarations from earlier archives. It does not need or include commercial Doom 3 assets.

The inventory probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_inventory.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans the selected map for `item_*`, `ammo_*`, and `weapon_*` entities, parses player spawn position/yaw, verifies the selected map's compiled `.cm` collision companion, and only then simulates a short collision-backed pickup path to report which pickup classes would be collected.

The combat probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_combat.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans the selected map for player starts, monsters, ammo, and weapons, verifies the selected map has a compiled `.cm` collision companion with collision models/polygons, resolves simple `entityDef` monster health including inherited definitions, then simulates one collision-world-gated hitscan weapon attack and one in-range monster retaliation pass. It reports ammo use, hit count, monster health before/after, and player health before/after.

The AI probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_ai.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans mounted pk4 archives for monster `entityDef` declarations, resolves inherited monster health, animation, sight sound, `scriptobject`, melee range, and melee damage, matches those references against mounted `.md5anim`, sound, and script object assets, then checks the selected map's player start, first monster spawn, and companion `.aas` navigation asset. It emits AAS area/reachability readiness, a monster-area to player-area path, a first path-following movement step, and a deterministic `idle>alert>melee` state transition summary with attack count and player health after damage. This is not a full Doom 3 AI scheduler yet, but it establishes the state/binding/pathing contract needed before real enemy thinking and scripted combat events move into the frame loop.

The AAS probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_aas.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans mounted pk4 archives for the selected map's companion `.aas` navigation asset, parses a small area/reachability subset, binds player and monster origins to nearest navigation areas, and reports whether deterministic paths are available. It also simulates one monster navigation-frame step toward the player and applies the first attack/damage result from that moved position. This is not the final Doom 3 pathfinder yet, but it establishes the data contract needed before enemy movement leaves direct-distance checks behind.

The objective probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_objective.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans the selected map for objective text, next-map metadata, named entities, trigger target links, doors, monsters, and player starts, resolves the declared next map, verifies that next map has a player start plus `.proc` and `.cm` companions, then simulates the first trigger-to-door progression step and reports whether a clear/next-map condition is ready. This is not the final campaign manager yet, but it establishes the contract needed before mission objectives, map exits, and loading transitions can become part of the playable loop.

The level-flow probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_level.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It catalogs map assets from mounted pk4 archives, loads the selected map, resolves its worldspawn `nextmap` value to a real `maps/*.map` asset, checks that the transition target exists, verifies that the next map has a player start, and requires the next map's `.proc` render companion plus `.cm` collision companion before reporting the transition ready. It also emits a deterministic transition path and carried-state summary. This is still a readiness probe rather than a full loading screen/campaign manager, but it proves the data contract needed for real map changes.

The model probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_model.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans mounted pk4 archives for model assets, parses simple `model` declarations from `.def` / `.decl` text, resolves `entityDef` `model` spawnargs either directly to mesh assets or through `modelDef` names, resolves first-pass `entityDef` animation spawnargs to mounted `.md5anim` assets, parses `.skin` declarations, and resolves `entityDef` `skin` spawnargs against mounted skin declarations/assets. It performs first-pass `.md5mesh` / `.md5anim` metadata extraction. Mesh metadata covers version, joint count, mesh block count, shader references, verts, tris, and weights; animation metadata covers version, frame count, joint count, frame rate, animated component count, hierarchy blocks, bounds, and base frames. It also performs deterministic animation frame sampling, next-frame selection, blend-percent calculation, verifies that the first mesh/animation joint counts are compatible, and reports first-pass skin material remap readiness. This is not full skinning or animation playback yet, but it establishes the model-loader contract needed before animated actors and weapon view models can become real.

The skeletal pose probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_pose.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It parses the first compatible MD5 mesh/animation pair far enough to sample a deterministic animation frame, apply root translation interpolation, skin weighted mesh vertices, preserve the first triangle index handoff, and compute skinned bounds. It also reads the selected map and inherited `entityDef` data to bind the first monster entity to its model, animation, skin, material texture, world-space skinned bounds, a first animated draw-call summary, camera/depth metadata, first-light influence, and a simple world-occlusion decision slot. This is still a first-pass CPU skinning contract rather than a full renderer path, but it moves animated actors from metadata toward drawable geometry with visibility data.

The weapon probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_weapon.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans mounted pk4 archives for `weapon_*` and `projectile_*` `entityDef` declarations, recognizes weapon ammo type, ammo-per-shot, clip size, projectile count, spread, projectile binding, fire sound, first-person `model_view`, projectile damage, and projectile speed, then matches the selected map's weapon pickup, ammo pickup, and monster presence against those definitions. It also verifies the selected map has a compiled `.cm` collision companion before reporting the deterministic one-shot firing summary with ammo before/after, projectile damage, projectile count, and spread. The `model_view` value is resolved against mounted MD5 mesh assets so later renderer submission can distinguish pickup/world models from the first-person weapon path. This is not the final weapon runtime yet, but it establishes the collision-backed definition-level contract needed before proper Doom 3 weapon scripts, projectile spawning, first-person weapon rendering, and hitscan/projectile combat can be integrated into the frame loop.

The projectile probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_projectile.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It resolves a weapon's `def_projectile` binding, reads weapon `num_projectiles` / `spread`, reads projectile `damage`, `splash_damage`, `splash_radius`, `speed`, and `model` spawnargs, verifies the projectile model against mounted model assets, and requires the selected map's compiled `.cm` collision companion before reporting impact readiness. With that collision data present, it builds a deterministic launch plan, spawns a projectile from the selected map's player start toward the first monster, advances it by speed over fixed 16 ms ticks, applies direct damage on impact, emits a first splash radius/target summary, and removes the projectile. This is still a probe, but it moves combat from definition-only checks toward collision-backed projectile entity lifetime and future multi-projectile/spread/splash behavior.

The GUI probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_gui.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans mounted pk4 archives for `.gui` files, counts first-pass `windowDef`, `rect`, `visible`, `matcolor`, and `onAction` declarations, then resolves `entityDef` and selected-map `gui` spawnargs against mounted GUI assets. It reports deterministic runtime GUI-surface and HUD-binding readiness. This is not a full Doom 3 GUI VM yet, but it establishes the data contract needed before HUDs, menus, in-world monitors, and script-driven GUI events can be integrated into the playable frame path.

The sound probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_sound.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans mounted pk4 archives for `.sndshd` / sound declaration text, resolves sound shader sample references against mounted `.wav` / `.ogg` assets, resolves `entityDef` and selected-map `snd_*` spawnargs either as direct samples or shader names, and emits a deterministic runtime sound-event summary for map entities that would play sounds. This is not a real mixer or spatial audio backend yet, but it establishes the audio binding contract needed before doors, monsters, weapons, and scripted events can trigger Doom 3-compatible sounds.

The audio metadata probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_audio.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans mounted sound samples, parses first-pass WAV headers, recognizes OGG containers, and reports PCM/non-PCM, mono/stereo, sample-rate, bits-per-sample, and duration buckets. This is not a mixer yet, but it establishes the sample metadata contract needed before real Doom 3 positional audio playback.

The script probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_script.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans mounted pk4 archives for `.script` functions and objects, then resolves `entityDef` `scriptobject` values and selected-map `call` spawnargs against those declarations. It also recognizes a small executable script-event subset in function bodies, currently including `sys.*` print-style calls, trigger/activate-style events, `wait`, and objective-complete markers, then verifies that selected-map `call` hooks resolve to an executable event path. This is not a full Doom 3 script VM yet, but it establishes the first event-dispatch contract needed before scripted doors, objectives, waits, and map logic can run inside the frame loop.

The script scheduler probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_scheduler.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It resolves selected-map `call` spawnargs to script functions, executes a small event subset, queues objective events after `wait(...)`, advances a deterministic 16 ms scheduler tick, dispatches due events, and reports target effects such as door activation and objective completion. It also resolves the selected map's `nextmap`, verifies the next map has a player start plus `.proc` and `.cm` companions, then runs a first frame-clear gate that requires the delayed objective, the activated door, a deterministic monster-defeat pass, and loadable next-map data before reporting the map as clear. This is still a focused scheduler contract rather than a full Doom 3 script VM.

The trace probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_trace.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It parses the selected map for coarse `brushDef3` bounds, scans `.mtr` material declarations for first-pass collision content flags such as `nonsolid`, scans `.def` `entityDef` declarations for inherited `mins` / `maxs` collision bounds, classifies solid, trigger, and hostile runtime entities, binds entityDef bounds onto spawned trace entities, parses the selected `.cm` companion version and first `collisionModel` name, extracts a first `.cm` polygon material/contents/plane record, checks that the polygon material is declared, classifies whether compiled polygons are blocking or nonblocking, evaluates the first compiled plane against deterministic point and segment tests, reports the first segment hit fraction, then runs a deterministic compiled segment trace across all parsed `.cm` polygon planes so blocking planes produce a nearest hit fraction and nonblocking planes are counted as skipped. It also runs deterministic movement, wall-blocking, hitscan, and trigger-target traces. Movement traces expand entity bounds by a small player hull, while hitscan traces test the actual hostile bounds without that expansion. The smoke fixture includes both a solid brush material and a declared `nonsolid` brush material, and the trace probe reports that the nonsolid brush and compiled nonsolid polygon are parsed but excluded from blocking. This is a coarse Stage 2 collision contract, not the final id Tech 4 collision model.

The VFS probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_vfs.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans sorted mounted pk4 archives, records first and last mounts, applies later-archive override semantics for the selected map, and reports the archive that supplied the final selected map plus its player start. The smoke fixture includes a `pak001.pk4` override for `maps/game/mars_city1.map`, proving that selected-map metadata comes from the later archive rather than the base `pak000.pk4`.

The platform probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_platform.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans mounted pk4 archives for `.cfg` files, recognizes `set` / `seta` cvars and `bind` key/action records, accepts command-line `+set`, `+bind`, and `+map` startup commands, and reports an ordered command buffer where config defaults are applied before command-line overrides. It also reports save/config paths, derives fixed-frame timing values, and translates a deterministic input frame into Doom-style actions such as `_forward`, `_attack`, `_use`, and `togglemenu`. This is not the final native/browser input backend yet, but it establishes the platform and startup-command contract needed before the playable frame loop can consume real keyboard and mouse state consistently.

The core-math probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_math.s7
```

It validates a shared math contract for later renderer and collision code: vector subtraction/dot/length, yaw-derived forward/right basis vectors, movement along a basis vector, id-Tech-style plane distance `dot(normal, point) + distance`, deterministic segment-plane hit fraction, point-in-bounds, expanded bounds intersection, and a simple frustum-style forward/side visibility test. This is intentionally asset-independent so math regressions can be caught before loading maps.

The lexer/parser probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_parser.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It tokenizes Doom-style text files with quoted strings, braces, parentheses, `//` comments, and `/* ... */` comments, then builds first-pass parser summaries for selected-map entity key/value pairs, `entityDef` declaration headers, material declarations, script functions, and GUI `windowDef` names. This is not a complete idLexer/idParser replacement yet, but it starts consolidating the text parsing contract that the real port needs before map, decl, script, GUI, and material loading can stop relying on scattered string scans.

The declaration-registry probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_decl.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans mounted pk4 archives for declaration text, registers material, `entityDef`, skin, sound shader, and model decls as typed keys, records inherited entityDefs plus first-pass material stage, skin remap, and sound sample metadata, and applies later-pk4 override semantics when the same typed decl key appears again. This is the future resource-manager contract that lets real Doom 3 content override base declarations without hardcoding individual subsystems.

The resource-manager probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_resource.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It catalogs mounted image, sound, model, GUI, and script assets, resolves references from materials, `entityDef` declarations, sound shaders, skins, and the selected map, and reports missing references as placeholder resources. The smoke override fixture deliberately adds a later-pk4 material that references missing images so the probe proves missing resources degrade into counted placeholders instead of hard failure.

The texture metadata probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_texture.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans mounted image assets, parses first-pass TGA and DDS headers, reports width, height, bits-per-pixel, DDS FourCC, mip-level counts, and separates compressed from uncompressed texture upload buckets. This is not renderer upload yet, but it establishes the metadata contract needed before real Doom 3 material images can become GPU textures.

The material-compatibility probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_material.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans mounted `.mtr` files, counts raw/unique/overridden material declarations, classifies stage blocks, blend modes, image directives, material flags, and animated transforms, then reports renderer-ready versus fallback materials. Unsupported GPU-program, conditional, cubemap, and deform features are logged as compatibility gaps so real Doom 3 materials can degrade visibly instead of failing silently.

The lighting/shadow probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_lighting.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans mounted `.mtr` files and the selected `.map`, records Doom-style light entity origin/radius/color data, classifies brush/patch surfaces against first-pass material shadow flags, and emits a deterministic shadow-volume fallback plan. This is not the final id Tech 4 stencil-shadow renderer yet, but it proves the data handoff needed before dynamic lights and shadow casters move into the renderer frame path.

The session-flow probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_session.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It validates the outer game-session contract around the selected map: pk4 map cataloging, selected-map override semantics, config binds for pause/attack/use, main-menu GUI discovery, start/resume/restart/quit action detection, GUI reference resolution, loading-to-running state, pause/resume, restart readiness, save/restore snapshot readiness, and next-map transition readiness. This is not a full interactive menu system yet, but it establishes the session manager and frontend-action contract needed before the integrated frame loop becomes a playable campaign flow.

The campaign-flow probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_campaign.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It catalogs mounted map assets, loads the selected map summary, resolves the `worldspawn` `nextmap`, verifies the next map has a player start, then emits both terminal campaign paths: clear writes an autosave-style snapshot and loads the next map with carried health/ammo, while death restores a checkpoint-style snapshot and restarts the current map at its player start. This is still a campaign-flow contract rather than the final Doom 3 session manager, but it ties the level, survival, and save probes together around the two transitions a playable campaign loop needs first.

The playable-loop probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_playloop.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It validates one deterministic end-to-end runtime path over mounted data: session load, config input actions, selected-map `.proc`/`.cm` companion readiness, next-map `.proc`/`.cm` transition readiness, selected-map gameplay ticks, trigger/use/attack intent, render-frame submission, first-person weapon and animated actor handoff, presentation-frame pass/hash handoff, audio-event emission, HUD state, clear screen state, next-map loading, carried health/ammo state, a post-transition presentation frame, pause/menu resume, quicksave restore on the loaded map, and restart-current checkpoint restore back to the current map/player start. This is still a contract probe, but it is the first single entrypoint that expects input, compiled-map companions, gameplay, renderer, presentation, audio, HUD, frontend session control, save/restore, and campaign transition readiness to agree across both load-next and restart-current flows.

The savegame probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_save.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It catalogs mounted map assets, reads the selected map and its `nextmap`, verifies the next map's `.proc` render companion and `.cm` collision companion before marking the transition save-ready, builds deterministic autosave/quicksave/checkpoint slot metadata, serializes a first selected-map terminal state with map, save path, player start, health, ammo, objective, screen, next-map, and compiled-transition fields, computes a checksum, and verifies restored map/health/ammo/objective/screen values from that snapshot. It also emits a restart-current checkpoint snapshot with player-start, health, ammo, post-action, and post-map fields so death/restart flow has a persistent contract. This is not a final binary Doom 3 save format yet, but it establishes the save/restore data contract needed before persistent campaign play can leave in-memory frame state.

The player-physics probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_physics.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans the selected map for player-spawn state, resolves the companion `.cm` collision model, classifies blocking versus nonblocking collision polygons, derives floor contact from the spawn height, then emits a deterministic fixed-tick movement contract with accepted and blocked moves, slide response, step-up response, gravity ticks, clipped velocity, and the first collision-plane handoff. This is not the final id Tech 4 `idPhysics_Player` translation yet, but it establishes the player-movement contract needed before real map walking moves into the integrated frame path.

The player-interaction probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_interaction.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans mounted config binds for `_use`, resolves selected-map trigger, door, target, and GUI references, verifies the selected map has a compiled `.cm` collision companion with collision models/polygons, counts GUI `onAction` declarations, then emits a deterministic use-focus trace from the player spawn through the first trigger to its target door. The same probe reports world/HUD GUI reference resolution and GUI event readiness. This is not the final interactive Doom 3 GUI VM or idPlayer use-code path yet, but it establishes the collision-backed focus/use/activate contract needed before doors, monitors, and scripted objects become part of the integrated frame loop.

The entity-spawn probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_spawn.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans selected-map entities, verifies the selected map has a compiled `.cm` collision companion with collision models/polygons, resolves inherited `entityDef` templates, model/sound/GUI assets, and target links, then builds a typed runtime-spawn summary for transforms, health, models, sounds, targets, GUI bindings, collision, think/spawnclass behavior, pickups, and lights. This is not the final idGameLocal spawn system yet, but it moves map loading from loose parser counts toward collision-backed runtime component creation.

The mover-door probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_mover.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans the selected map for `func_door` / `mover_door` entities and trigger targets, verifies the selected map has a compiled `.cm` collision companion with collision models/polygons, scans scripts for `$door.trigger(...)` calls, resolves door-open sounds against mounted sound samples, then emits a deterministic closed-to-open mover state with timing, collision-state toggles, and idempotent activation when physical triggers and scripts target the same door. This is not the final idMover translation yet, but it establishes the collision-backed door-runtime contract needed before scripted map progression moves fully into the integrated frame path.

The compiled-map probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_compiledmap.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans mounted pk4 archives for `maps/*.proc` and `maps/*.cm` files next to the selected `.map`, scans mounted `.mtr` material declarations plus image assets, then reports first-pass companion versions, render/collision model-pair matching, render surface/portal counters, `.proc` vertex/index declaration totals, the first `.proc` surface record, parsed `.proc` area/portal header counts, the first portal point/area tuple, the first portal-derived visibility-scope summary, a portal-flood visibility summary across connected areas, `.proc` material references with declared/missing counts, `.proc` texture bindings resolved against mounted images, a first compiled-surface summary containing material, texture, vertex count, and index count, a first compiled draw-call summary containing material, texture, triangle count, and portal-area scope, `.cm` vertex/edge/polygon/brush counters, a first `.cm` collision payload handoff record, a first `.cm` polygon material/contents/plane handoff record, first-pass material-declared plus material-aware blocking/nonblocking classification for compiled collision polygons, and a deterministic compiled segment trace that reports the nearest blocking hit fraction while counting raw nonblocking and material-`nonsolid` planes as skipped. This is not a full `.proc` renderer or `.cm` collision loader yet, but it establishes the data contract needed for real retail Doom 3 map loading where compiled map companions matter.

The renderer-front-end probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_render.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans mounted pk4 archives for `.mtr` material texture bindings, common image directives such as `qer_editorimage`, `diffusemap`, `bumpmap`, and `specularmap`, animated material-stage hints, `.skin` material remap declarations, selected-map `brushDef3` / `patchDef2` / `patchDef3` surfaces, selected-map `.proc` version/model identity, render-surface, draw-call, area-portal metadata, a first visibility-scope summary, and a portal-flood visibility summary, Doom 3 `light` entities with `origin`, `light_radius`, and `_color`, renderable map entities such as pickups, triggers, doors, statics, and monsters, simple `entityDef` model/anim/skin references, and first-pass `.md5mesh` / `.md5anim` metadata. It resolves surface and compiled-surface textures against image assets, derives a first compiled draw-call summary with triangle count and portal-area scope, derives a first camera-area/visible-area scope from the `.proc` portal tuple, floods connected portal areas from that camera area, samples first-pass `scroll` and `rotate` material transforms at a deterministic time, resolves renderable entity model and animation spawnargs through direct or inherited `entityDef` data against mounted MD5 assets, resolves inherited skin spawnargs against mounted `.skin` declarations, reports the first renderer-facing material remap for a skinned entity, emits a first animated actor draw-call summary from the bound MD5 mesh/animation/material/texture, computes a first light contribution for visible brush and patch surfaces, renders a tiny deterministic ASCII framebuffer using a per-column depth buffer, then tests renderable entities against that buffer. The synthetic smoke map includes overlapping near/far surfaces, an animated material stage, a material that resolves through `diffusemap` rather than a stage `map`, a selected-map `.proc` identity and surface with vertex/index counts and material-to-texture resolution, a chained `.proc` area/portal tuple for future visibility traversal, a skinned animated monster, and entities in front of/behind world geometry so the probe verifies material-stage animation metadata, directive-based texture fallback, compiled render identity, surface, draw-call, portal, first visibility-scope handoff, portal-flood visibility readiness, MD5 animated actor handoff, depth writes, rejected occluded columns, visible/occluded entities, visible/occluded model-bound entities, and renderer skin-remap readiness. This is a renderer contract for the future browser/native frame path, not a full id Tech 4 renderer yet.

The frame-to-render submission probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_submit.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans mounted MD5 mesh/animation assets, inherited `entityDef` model/anim/skin/spawnclass/health values, weapon `model_view` spawnargs, and the selected map's first monster and weapon entities. It emits a deterministic frame-to-render actor submission containing mesh, animation, shader, sampled animation frame, blend percent, vertex count, and triangle count, plus a view-relative weapon drawcall tagged for the first-person weapon path. This keeps the large integrated frame probe under the current Seed7 WASM stack ceiling while still proving the gameplay-to-renderer animated actor and weapon-view contracts.

The renderView/camera probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_view.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It extracts the selected map's first player start as the camera origin/yaw, computes a deterministic FOV/aspect projection and viewport/scissor handoff, reads the selected `.proc` portal-area header for visibility scope, and resolves first-person weapon `model_view` data into a weapon-view projection plan. This is not the final renderer backend yet, but it gives the future Doom 3 frame path a concrete renderView contract instead of only drawing from ad hoc camera globals.

The game-frame probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_frame.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It builds a small selected-map runtime entity set, resolves inherited monster health, model, animation, skin, spawnclass, and sound spawnargs from `entityDef` declarations, parses first-pass weapon/projectile definitions, parses first-pass `.gui` assets, parses first-pass script-event functions, then simulates one deterministic gameplay update covering HUD/GUI binding, collision-gated player movement, pickup collection, map `call` script dispatch, trigger-to-door activation, weapon fire, monster damage, and monster retaliation. The frame runtime catalogs mounted model assets, parses simple `model` declarations, resolves `entityDef` `model` spawnargs either directly or through `modelDef` mesh bindings, verifies `anim` spawnargs against mounted `.md5anim` assets, resolves inherited `skin` spawnargs against mounted `.skin` declarations, validates inherited behavior `spawnclass` values against the supported runtime subset, and samples the resolved animation at 75 ms to produce current frame, next frame, and blend percent before the entity participates in the frame path. It also catalogs mounted `.gui` assets, counts basic `windowDef` / `rect` / `visible` / `matcolor` / `onAction` structure, resolves entityDef and worldspawn GUI references, and binds the world HUD GUI to the frame HUD values. The frame movement path now advances only through accepted steps and stops at parsed `brushDef3` bounds or solid runtime entities before evaluating further pickups/triggers past the collision point. Weapon runtime values now come from mounted Doom-style defs: active weapon class, `ammoRequired`, `clipSize`, `def_projectile`, fire sound, and projectile `damage` are resolved before combat. Weapon damage is gated by a coarse frame hitscan trace through parsed brush bounds, so the frame loop only damages the nearest visible monster when selected-map geometry leaves line of sight open. The same frame dispatches resolved sound events for door open, weapon fire, and monster response against mounted sound samples. The frame path treats scripted and physical door activation idempotently, so a script-triggered door is not double-counted when the player also touches the trigger. It also runs a short persistent loop that consumes pickups once, keeps the door open, spends ammo across repeated shots using the resolved ammo-per-shot value, kills the monster using resolved projectile damage, records remaining player health, and reports a clear condition. After clear, it resolves the current map's `worldspawn` `nextmap` against the mounted map catalog, verifies the next map has a player start, verifies the next map's `.proc` render companion and `.cm` collision companion are mounted, records transition readiness, and persists the transition fields in the save snapshot. The same loop derives HUD-facing health/ammo bars, enemies remaining, objective completion, and final screen state, then serializes the terminal state to an in-memory save snapshot and verifies restore consistency. This is the first integrated gameplay-loop/model-binding/animation-sampling/skin-binding/spawnclass-binding/HUD-GUI/movement-collision/weapon-definition/world-trace/script-dispatch/sound-dispatch/transition/save-state contract, not a full campaign loop yet.

The projectile runtime probe resolves projectile splash damage and radius from mounted projectile defs and reports deterministic splash metadata for the first simulated impact; this remains outside the large integrated frame probe to stay below the current Seed7 WASM stack ceiling.

The FX/particle probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_fx.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans projectile `fx_impact` spawnargs, `.fx` declarations, mounted `.prt` particle assets, sound samples, decal materials, and light metadata, then emits a deterministic impact-effect event plan. This is not the final idDeclFX or particle renderer yet, but it creates the resource/runtime contract needed before projectile impacts, scripted effects, decals, and transient lights move into the frame path.

The cinematic/video probe can also be run directly:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7_cinematic.s7 --doom3_data_path "C:\Path\To\Doom 3"
```

It scans mounted video assets, GUI background video references, and selected-map cinematic spawnargs, checks a tiny RoQ header readiness contract, and emits a deterministic playback plan. This is a compatibility contract for future menu videos, monitors, and scripted cinematics; it does not bundle or decode commercial Doom 3 videos.

Optional environment variables:

- `DOOM3_SEED7_FIXTURE`: runs the smoke script against a local test fixture path.
- `DOOM3_DATA_PATH`: runs the smoke script against a legal Doom 3 install path.

Expected success output includes mounted pk4 archives, metadata counts, first discovered map/material/def/script paths, parser counts for entity definitions, named entity definitions, entityDef health/model/sound/inherit/bounds spawnargs, material declarations, material texture binding/readiness, texture header metadata readiness for TGA/DDS dimensions, format buckets, FourCC, and mip counts, audio sample metadata readiness for WAV/OGG headers, PCM/channel/rate/duration buckets, material compatibility flags, material raw/unique/override registry readiness, material renderer-ready/fallback classification, unsupported material feature reporting, common material image-directive readiness, animated material-stage readiness, deterministic material transform sampling, session loading/running/pause/restart/save/transition readiness, platform config/cvar/bind/input/timing readiness, core vector/plane/bounds/frustum math readiness, declaration registry and later-pk4 override readiness, resource-manager asset resolution and placeholder fallback readiness, sound readiness, selected model readiness, runtime model readiness, runtime sound readiness, AI monster definition readiness, AI script/animation/sound/spawnclass binding readiness, deterministic AI state transition readiness, objective text/next-map readiness, trigger target progression readiness, clear-condition readiness, level-flow map cataloging, next-map `.proc`/`.cm` asset resolution, transition-path readiness, carried-state readiness, weapon definition readiness, projectile definition readiness, projectile model binding readiness, deterministic projectile travel/impact/removal readiness, weapon ammo/projectile/fire-sound binding readiness, deterministic weapon firing readiness, GUI asset/window readiness, GUI binding readiness, runtime HUD/GUI-surface readiness, sound shader/sample readiness, sound binding readiness, deterministic runtime sound-event readiness, compiled `.proc` / `.cm` selected-map readiness with `.proc` identity and geometry counters, `.proc` area-portal metadata, first visibility-scope summary, portal-flood visibility summary, `.proc` material/texture image readiness, first compiled-surface and draw-call renderer handoff, `.cm` version/name/payload counters, first `.cm` polygon material/contents handoff, compiled collision polygon material declaration/material-aware blocking readiness, compiled collision blocking/nonblocking polygon counts, first compiled plane point and segment hit tests with hit fraction, compiled-map and trace-probe segment-trace nearest blocking hit and nonblocking-skip counts, and material declaration matching, map entities, map classname categories, selected-map entity key summaries including bounds, typed entity-record readiness, inherited and map-level runtime spawnarg readiness, script function and script spawnarg readiness, executable script-event readiness, map-call event dispatch readiness, frame-loop model/animation/skin/spawnclass binding readiness, frame-loop animation playback sampling readiness, frame-loop HUD/GUI binding readiness, frame-loop collision-gated movement readiness, frame-loop weapon/projectile definition readiness, frame-loop script dispatch readiness, frame-loop sound-event dispatch readiness, frame-loop hitscan/world-trace readiness, frame-loop next-map transition readiness, idempotent scripted/triggered door activation, runtime spawn records, runtime entity kind counts, runtime custom health counts, health/ammo/weapon pickup recognition, pickup path collection counts, combat weapon/ammo/monster readiness, combat entityDef health inheritance, combat hit and monster-health delta, monster attack range/damage readiness, model asset/modelDef/skin resolution readiness, first-pass `.md5mesh` / `.md5anim` metadata readiness, script object/function binding readiness, coarse world-trace readiness with inherited entityDef bounds, material-backed solid brush collision, movement hull expansion, and exact hostile hitscan bounds, renderer-front-end brush/patch depth-buffer/framebuffer readiness with occluded-column, entity-depth rejection, model-bound entity readiness, and skin-remap readiness, integrated game-frame readiness, persistent multi-tick gameplay-loop readiness, HUD/objective/screen-state readiness, save/restore snapshot readiness, map-level sound overrides, runtime solid-entity collision counts, unsupported selected entity counts, target-link readiness, trigger target resolution, activated runtime door readiness, spawn-ready entity counts, spawn classname declaration compatibility, selected-map material declaration compatibility, brush/patch surface material readiness, typed brush-plane readiness, coarse brush-bounds readiness, runtime render-surface readiness, renderer material/fallback/texture readiness, camera-facing render queue readiness, nearest render-surface metadata, first render-light influence readiness, lit render queue counts, player spawn collision readiness, first movement-probe readiness, first movement-acceptance readiness, fixed-step player simulation readiness, first trigger interaction readiness, activated door readiness, top-down debug render readiness, ASCII debug frame rows, light overlay readiness, gameplay entity overlay readiness, selected entity-origin bounds, brush plane-line counts, selected light readiness, script functions, image references, sound references, brush/patch primitive counts, selected-map status, and parsed player spawn numbers. Expected failure output explains that `base/*.pk4` was not found.

The startup log also reports save/config paths, the registered cvar count, the first cvar, core `fs_basepath` / `fs_game` values, and any first custom cvar supplied with `--set` or `+set`.

## Doom 3 Port Roadmap

1. Stage 1: platform/config layer and user-owned pk4 asset pipeline.
2. Stage 2: core id Tech 4 runtime translation, map loading, collision, and first static renderer.
3. Stage 3: playable compatibility pass with entities, scripts subset, HUD/menu flow, graceful fallbacks, and release packaging.

## Doom3 Probe Launcher

### Browser

This repository includes the browser launcher in `index.html` and the wasm runtime in `wasm/`.

```bash
python -m http.server 8080
```

Open:

```text
http://localhost:8080/index.html
```

For a one-command run/check flow, use:

```bash
powershell -ExecutionPolicy Bypass -File .\tools\run_doom3_seed7_browser.ps1 -Port 8080
```

Add `-Build` if you want the helper to rebuild `wasm/s7.js` first:

```bash
powershell -ExecutionPolicy Bypass -File .\tools\run_doom3_seed7_browser.ps1 -Port 8080 -Build
```

Quick verification (build + smoke + no-legacy check):

```bash
powershell -ExecutionPolicy Bypass -File .\tools\verify_doom3_seed7_smoke.ps1 -Build
```

By default, `index.html` opens `doom3.html`, which starts with `doom3_seed7_runtime.s7` through `wasm/s7.js`. With no files selected, the launcher automatically uses the generated synthetic fixture.

If you ever see `Error: Failed to fetch` for the runtime entry, it is usually a stale
legacy URL/browser cache issue. Open `http://localhost:8080/doom3.html` directly, hard-refresh with `Ctrl+Shift+R`
(or clear cache), and make sure `entry=doom3_seed7_runtime.s7` is the active launch entry. If you still see a stale launcher page, open `/doom3.html` with a fresh query:

```text
http://localhost:8080/doom3.html?entry=doom3_seed7_runtime.s7
```
If you still see a cached legacy interface, clear cache and reopen
`/doom3.html` with the current entry; stale browser versions can persist briefly.

Native instructions for the current port entrypoint are:

### Rebuild WebAssembly Runtime

If you need to rebuild the Seed7 wasm runtime:

```bash
python build_s7_wasm.py
python build_s7_wasm.py browser
```

The browser build writes `wasm/s7.js` and `wasm/s7.wasm`.

### Native Seed7

If your local Seed7 installation supports the graphics library:

```bash
node seed7/bin/s7.js -l seed7/lib doom3_seed7.s7 --doom3_data_path /path/to/doom3
```

Exact native commands depend on the local Seed7 installation and graphics backend.

## Controls

| Key | Action |
| --- | --- |
| Up | Move forward |
| Down | Move backward |
| Left | Rotate left |
| Right | Rotate right |
| Space / left mouse | Fire |
| ESC | Quit |

## Technical Notes







