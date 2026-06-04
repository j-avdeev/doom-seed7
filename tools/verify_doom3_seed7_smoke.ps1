param(
  [switch]$Build
)

$ErrorActionPreference = "Stop"

function Assert-Exists {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Missing required file: $Path"
  }
}

function Assert-FileContains {
  param(
    [string]$Path,
    [string]$Needle,
    [string]$Label
  )
  $content = Get-Content -LiteralPath $Path -Raw
  if (-not $content.Contains($Needle)) {
    throw "$Label missing expected text.`n  File: $Path`n  Needle: $Needle"
  }
}

function Assert-FileNotMatches {
  param(
    [string]$Path,
    [string]$Pattern,
    [string]$Label
  )
  $content = Get-Content -LiteralPath $Path -Raw
  if ($content -match $Pattern) {
    throw "$Label contains forbidden pattern.`n  File: $Path`n  Pattern: $Pattern"
  }
}

function Assert-TextContains {
  param(
    [string]$Text,
    [string]$Needle,
    [string]$Label
  )
  if (-not $Text.Contains($Needle)) {
    throw "$Label missing expected text.`n  Needle: $Needle`n  Output:`n$Text"
  }
}

Write-Host "== Doom3 Seed7 generated episode verification =="

$activeFiles = @(
  "README.md",
  "index.html",
  "doom3.html",
  "doom3_seed7_runtime.s7",
  "doom3_seed7_engine.s7",
  ".github\workflows\deploy-pages.yml",
  "wasm\pre_js_browser.js",
  "wasm\s7.js",
  "tools\run_doom3_seed7_browser.ps1",
  "tools\run_doom3_seed7_native.ps1"
)

$generatedFiles = @(
  "generated\doom3_seed7\manifest.txt",
  "generated\doom3_seed7\materials\seed7_tech4.mtr",
  "generated\doom3_seed7\maps\seed7\mars_city1.map",
  "generated\doom3_seed7\maps\seed7\e1m1.map",
  "generated\doom3_seed7\maps\seed7\e1m2.map",
  "generated\doom3_seed7\maps\seed7\e1m3.map",
  "generated\doom3_seed7\models\monsters\generated_imp.md5mesh",
  "generated\doom3_seed7\guis\hud_seed7.gui"
)

foreach ($file in $activeFiles + $generatedFiles) {
  Assert-Exists -Path $file
}

if ($Build) {
  Write-Host "Building wasm runtime for browser..."
  python build_s7_wasm.py browser
}

if (-not (Test-Path -LiteralPath "wasm\s7.js") -or -not (Test-Path -LiteralPath "wasm\s7.wasm")) {
  Write-Host "WASM artifacts missing; building before verification..."
  python build_s7_wasm.py browser
}

$forbiddenTerms = @("ray" + "caster", "run" + "caster", "ray " + "caster")
$forbiddenPattern = ($forbiddenTerms | ForEach-Object { [regex]::Escape($_) }) -join "|"

Write-Host "Checking active files for removed prototype wording..."
foreach ($file in $activeFiles) {
  Assert-FileNotMatches -Path $file -Pattern $forbiddenPattern -Label "Active launch/runtime file"
}

Write-Host "Checking browser launcher wiring..."
Assert-FileContains -Path "doom3.html" -Needle "Doom3 Seed7 Generated Episode" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "doom3_seed7_runtime.s7" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "doom3_seed7_engine.s7" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "generated/doom3_seed7/manifest.txt" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "generated/doom3_seed7/maps/seed7/e1m1.map" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "generated/doom3_seed7/maps/seed7/e1m2.map" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "generated/doom3_seed7/maps/seed7/e1m3.map" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "wasm/s7.js" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "'--engine_mode', engineMode" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "'--generated_asset_root', '/' + GENERATED_ASSET_ROOT" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "seed7UseDocumentCanvas: true" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "image-rendering: pixelated;" -Label "browser canvas scaling"
Assert-FileContains -Path "doom3.html" -Needle "canvas.style.imageRendering = 'pixelated';" -Label "browser canvas scaling"
Assert-FileContains -Path "doom3.html" -Needle "accept=`".pk4,.zip`"" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle '/\.s7$/i' -Label "browser launcher runtime extension check"
Assert-FileNotMatches -Path "doom3.html" -Pattern ([regex]::Escape('/\\.s7$/i')) -Label "browser launcher stale escaped runtime extension check"
$syntheticFixtureNeedle = "Synthetic " + "fixture"
Assert-FileNotMatches -Path "doom3.html" -Pattern ([regex]::Escape($syntheticFixtureNeedle)) -Label "browser launcher"

Write-Host "Checking browser canvas popup guard..."
Assert-FileContains -Path "wasm\pre_js_browser.js" -Needle "Module.seed7UseDocumentCanvas" -Label "wasm pre-js"
Assert-FileContains -Path "wasm\s7.js" -Needle "Module.seed7UseDocumentCanvas" -Label "wasm runtime"

Write-Host "Checking Pages artifact contents..."
Assert-FileContains -Path ".github\workflows\deploy-pages.yml" -Needle "cp doom3_seed7_runtime.s7 doom3_seed7_engine.s7 _site/" -Label "Pages deploy"
Assert-FileContains -Path ".github\workflows\deploy-pages.yml" -Needle "cp -R generated _site/generated" -Label "Pages deploy"
Assert-FileNotMatches -Path ".github\workflows\deploy-pages.yml" -Pattern "cp doom3_seed7\*\.s7" -Label "Pages deploy"
Assert-FileNotMatches -Path ".github\workflows\deploy-pages.yml" -Pattern "\bfixtures\b" -Label "Pages deploy"

Write-Host "Checking generated replacement asset pack..."
Assert-FileContains -Path "generated\doom3_seed7\manifest.txt" -Needle "doom3_seed7_generated_assets=1" -Label "generated assets"
Assert-FileContains -Path "generated\doom3_seed7\manifest.txt" -Needle "episode_maps=3" -Label "generated assets"
Assert-FileContains -Path "generated\doom3_seed7\manifest.txt" -Needle "maps=e1m1,e1m2,e1m3" -Label "generated assets"
Assert-FileContains -Path "generated\doom3_seed7\manifest.txt" -Needle "monster_types=rust_trooper,ember_crawler,iron_brute" -Label "generated assets"
Assert-FileContains -Path "generated\doom3_seed7\manifest.txt" -Needle "doors=3" -Label "generated assets"
Assert-FileContains -Path "generated\doom3_seed7\manifest.txt" -Needle "keys=red,blue,yellow" -Label "generated assets"
Assert-FileContains -Path "generated\doom3_seed7\manifest.txt" -Needle "hud_contract=ammo,health,armor,face,key_icons,weapon_icons" -Label "generated assets"
Assert-FileContains -Path "generated\doom3_seed7\materials\seed7_tech4.mtr" -Needle "textures/seed7/emissive_cyan" -Label "generated assets"
Assert-FileContains -Path "generated\doom3_seed7\maps\seed7\mars_city1.map" -Needle '"classname" "info_player_start"' -Label "generated assets"
Assert-FileContains -Path "generated\doom3_seed7\maps\seed7\mars_city1.map" -Needle '"episode_alias" "e1m1"' -Label "generated assets"
Assert-FileContains -Path "generated\doom3_seed7\maps\seed7\e1m1.map" -Needle '"name" "E1M1 Foundry Gate"' -Label "generated assets"
Assert-FileContains -Path "generated\doom3_seed7\maps\seed7\e1m1.map" -Needle '"locked_door" "red_key_gate"' -Label "generated assets"
Assert-FileContains -Path "generated\doom3_seed7\maps\seed7\e1m2.map" -Needle '"name" "E1M2 Processing Core"' -Label "generated assets"
Assert-FileContains -Path "generated\doom3_seed7\maps\seed7\e1m2.map" -Needle '"locked_door" "blue_key_gate"' -Label "generated assets"
Assert-FileContains -Path "generated\doom3_seed7\maps\seed7\e1m3.map" -Needle '"name" "E1M3 Reactor Exit"' -Label "generated assets"
Assert-FileContains -Path "generated\doom3_seed7\maps\seed7\e1m3.map" -Needle '"locked_door" "yellow_key_gate"' -Label "generated assets"
Assert-FileContains -Path "generated\doom3_seed7\models\monsters\generated_imp.md5mesh" -Needle "MD5Version 10" -Label "generated assets"
Assert-FileContains -Path "generated\doom3_seed7\guis\hud_seed7.gui" -Needle "windowDef Desktop" -Label "generated assets"
Assert-FileContains -Path "generated\doom3_seed7\guis\hud_seed7.gui" -Needle "windowDef Face" -Label "generated assets"
Assert-FileContains -Path "generated\doom3_seed7\guis\hud_seed7.gui" -Needle "windowDef KeyIcons" -Label "generated assets"
Assert-FileContains -Path "generated\doom3_seed7\guis\hud_seed7.gui" -Needle "windowDef WeaponIcons" -Label "generated assets"

Write-Host "Checking generated multi-room scene and HUD contracts..."
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle 'surf("side_lab_floor"' -Label "engine generated scene"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "appendEpisodeRoom(surfaces, `"e1m2_processing_core`"" -Label "engine generated scene"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "appendEpisodeRoom(surfaces, `"e1m3_reactor_ring`"" -Label "engine generated scene"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle 'actor("rust_trooper"' -Label "engine generated scene"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle 'actor("ember_crawler"' -Label "engine generated scene"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle 'actor("iron_brute"' -Label "engine generated scene"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "drawNumber3" -Label "engine generated HUD"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "drawStatusFace" -Label "engine generated HUD"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "drawKeyCardIcon" -Label "engine generated HUD key icons"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "drawWeaponSlotIcon" -Label "engine generated HUD weapon icons"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "HUD_GLASSES" -Label "engine generated HUD face"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "HUD_HAIR" -Label "engine generated HUD face"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "state.redKey" -Label "engine generated HUD key slots"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "const integer: SCREEN_WIDTH  is 640;" -Label "performance viewport"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "const integer: SCREEN_HEIGHT is 360;" -Label "performance viewport"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "const float:   FOCAL_LENGTH  is 260.0;" -Label "performance viewport"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "renderContext" -Label "per-frame render context"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "clipEdgeToNear" -Label "near-plane wall clipping"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "clipPolygonNear" -Label "near-plane wall clipping"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "surfaceOrderDepth" -Label "far-to-near wall ordering"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "drawn := length(surfaces) times FALSE;" -Label "single sorted render pass"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "orderDepths := length(surfaces) times 0.0;" -Label "single sorted render pass"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "cachedSurfaces := generatedSurfacesFor(state.mapIndex);" -Label "cached map surfaces"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "renderEngineFrame(stats, state, cachedSurfaces);" -Label "cached map surfaces"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "frameWaitMicros := 16000 - toMicroSeconds(frameElapsed);" -Label "target frame wait"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "glowShift" -Label "procedural monster detail"
Assert-FileNotMatches -Path "doom3_seed7_engine.s7" -Pattern "projectPointClamped" -Label "stale clamped wall projection"
Assert-FileNotMatches -Path "doom3_seed7_engine.s7" -Pattern "for pass range 42" -Label "old multi-pass renderer"
Assert-FileNotMatches -Path "doom3_seed7_engine.s7" -Pattern "state\.ammo \* 2" -Label "right-side HUD ammo duplicate"
Assert-FileNotMatches -Path "doom3_seed7_engine.s7" -Pattern "ammoWidth := clampInt\(state\.ammo" -Label "right-side HUD ammo duplicate"
Assert-FileNotMatches -Path "doom3_seed7_engine.s7" -Pattern "drawDigit\(858|drawDigit\(900|drawDigit\(922" -Label "old right-side HUD digit slots"

Write-Host "Checking interactive control mapping..."
$engineSource = Get-Content -LiteralPath "doom3_seed7_engine.s7" -Raw
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "const float:   MOVE_SPEED    is 0.115;" -Label "player movement tuning"
if ($engineSource -notmatch "KEY_RIGHT[\s\S]{0,240}rotatePlayer\(state, ROT_SPEED\)") {
  throw "Right arrow must rotate with positive engine yaw."
}
if ($engineSource -notmatch "KEY_LEFT[\s\S]{0,240}rotatePlayer\(state, -ROT_SPEED\)") {
  throw "Left arrow must rotate with negative engine yaw."
}
if ($engineSource -notmatch "updateInput\(state\)[\s\S]{0,320}renderEngineFrame\(stats, state, cachedSurfaces\)") {
  throw "Main loop must poll input before rendering the cached-surface frame."
}
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "buttonPressed(KEYBOARD, 'w')" -Label "continuous WASD controls"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "buttonPressed(KEYBOARD, 'a')" -Label "continuous WASD controls"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "buttonPressed(KEYBOARD, 's')" -Label "continuous WASD controls"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "buttonPressed(KEYBOARD, 'd')" -Label "continuous WASD controls"
Assert-FileNotMatches -Path "doom3_seed7_engine.s7" -Pattern "state\.lastKey = (KEY_UP|KEY_DOWN|KEY_LEFT|KEY_RIGHT|'w'|'a'|'s'|'d'|'W'|'A'|'S'|'D')" -Label "old lastKey-gated movement"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "damage := 7;" -Label "monster damage tuning"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "damage := 5;" -Label "monster damage tuning"
Assert-FileContains -Path "doom3_seed7_engine.s7" -Needle "damage := 3;" -Label "monster damage tuning"
Assert-FileNotMatches -Path "doom3_seed7_engine.s7" -Pattern "damage := 13|damage := 9|damage := 6" -Label "monster damage tuning"

Write-Host "Running engine native smoke..."
$smokeOutput = cmd /c "node seed7/bin/s7.js -l seed7/lib doom3_seed7_runtime.s7 --smoke_frames 2 2>&1"
$smokeText = $smokeOutput | Out-String
if ($LASTEXITCODE -ne 0) {
  throw "Engine smoke failed with exit code $LASTEXITCODE.`n$smokeText"
}
Assert-TextContains -Text $smokeText -Needle "smoke_frame_1" -Label "engine smoke"
Assert-TextContains -Text $smokeText -Needle "smoke_frame_2" -Label "engine smoke"
Assert-TextContains -Text $smokeText -Needle "smoke_hashes=" -Label "engine smoke"
Assert-TextContains -Text $smokeText -Needle "engine_smoke_ready=TRUE" -Label "engine smoke"
Assert-TextContains -Text $smokeText -Needle "episode_maps=3" -Label "engine smoke"
Assert-TextContains -Text $smokeText -Needle "monster_types=3" -Label "engine smoke"
Assert-TextContains -Text $smokeText -Needle "keys=3" -Label "engine smoke"
Assert-TextContains -Text $smokeText -Needle "doors=3" -Label "engine smoke"
Assert-TextContains -Text $smokeText -Needle "episode_smoke_ready=TRUE" -Label "engine smoke"
Assert-TextContains -Text $smokeText -Needle "scripted_path=pickup_key>open_door>kill_monster>exit" -Label "engine smoke"
Assert-TextContains -Text $smokeText -Needle "scripted_kills=1" -Label "engine smoke"
Assert-TextContains -Text $smokeText -Needle "scripted_transition_map=e1m2" -Label "engine smoke"
Assert-TextContains -Text $smokeText -Needle "monster_sprite_detail=procedural_silhouettes" -Label "engine smoke"
Assert-TextContains -Text $smokeText -Needle "hud_contract=ammo,health,armor,face,key_icons,weapon_icons" -Label "engine smoke"
Assert-TextContains -Text $smokeText -Needle "render_resolution=640x360" -Label "engine smoke"
Assert-TextContains -Text $smokeText -Needle "wall_clip=polygon_near_plane" -Label "engine smoke"
Assert-TextContains -Text $smokeText -Needle "render_passes=single_sorted" -Label "engine smoke"
Assert-TextContains -Text $smokeText -Needle "input_polling=continuous" -Label "engine smoke"
Assert-TextContains -Text $smokeText -Needle "wall_clip_ready=TRUE" -Label "engine smoke"
Assert-TextContains -Text $smokeText -Needle "flat_columns=FALSE" -Label "engine smoke"
Write-Host $smokeText

Write-Host "Running engine visual smoke..."
$visualOutput = cmd /c "node seed7/bin/s7.js -l seed7/lib doom3_seed7_runtime.s7 --visual_smoke_frames 2 2>&1"
$visualText = $visualOutput | Out-String
if ($LASTEXITCODE -ne 0) {
  throw "Visual smoke failed with exit code $LASTEXITCODE.`n$visualText"
}
Assert-TextContains -Text $visualText -Needle "visual_smoke_ready=TRUE" -Label "visual smoke"
Assert-TextContains -Text $visualText -Needle "visual_smoke_renderer=projected_surfaces" -Label "visual smoke"
Assert-TextContains -Text $visualText -Needle "visual_smoke_canvas=main_document_expected" -Label "visual smoke"
Assert-TextContains -Text $visualText -Needle "visual_smoke_episode=classic_generated" -Label "visual smoke"
Assert-TextContains -Text $visualText -Needle "visual_smoke_hud=key_icons_weapon_icons" -Label "visual smoke"
Assert-TextContains -Text $visualText -Needle "visual_smoke_resolution=640x360" -Label "visual smoke"
Assert-TextContains -Text $visualText -Needle "visual_smoke_wall_clip=polygon_near_plane" -Label "visual smoke"
Assert-TextContains -Text $visualText -Needle "visual_smoke_render_passes=single_sorted" -Label "visual smoke"
Assert-TextContains -Text $visualText -Needle "visual_smoke_input_polling=continuous" -Label "visual smoke"

Write-Host "Running runtime help..."
$helpOutput = cmd /c "node seed7/bin/s7.js -l seed7/lib doom3_seed7_runtime.s7 --help 2>&1"
$helpText = $helpOutput | Out-String
if ($LASTEXITCODE -ne 0) {
  throw "Runtime help failed with exit code $LASTEXITCODE.`n$helpText"
}
Assert-TextContains -Text $helpText -Needle "--engine_mode generated" -Label "runtime help"
Assert-TextContains -Text $helpText -Needle "--visual_smoke_frames" -Label "runtime help"
Assert-TextContains -Text $helpText -Needle "--doom3_start_map e1m1|e1m2|e1m3" -Label "runtime help"
Assert-TextContains -Text $helpText -Needle "replacement assets" -Label "runtime help"

Write-Host "Verification complete. Active path is the Seed7 generated episode."
