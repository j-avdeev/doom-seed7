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

Write-Host "== Doom3 Seed7 engine-shell verification =="

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
Assert-FileContains -Path "doom3.html" -Needle "Doom3 Seed7 Engine Shell" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "doom3_seed7_runtime.s7" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "doom3_seed7_engine.s7" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "generated/doom3_seed7/manifest.txt" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "wasm/s7.js" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "'--engine_mode', engineMode" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "'--generated_asset_root', '/' + GENERATED_ASSET_ROOT" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "seed7UseDocumentCanvas: true" -Label "browser launcher"
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
Assert-FileContains -Path "generated\doom3_seed7\materials\seed7_tech4.mtr" -Needle "textures/seed7/emissive_cyan" -Label "generated assets"
Assert-FileContains -Path "generated\doom3_seed7\maps\seed7\mars_city1.map" -Needle '"classname" "info_player_start"' -Label "generated assets"
Assert-FileContains -Path "generated\doom3_seed7\models\monsters\generated_imp.md5mesh" -Needle "MD5Version 10" -Label "generated assets"
Assert-FileContains -Path "generated\doom3_seed7\guis\hud_seed7.gui" -Needle "windowDef Desktop" -Label "generated assets"

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

Write-Host "Running runtime help..."
$helpOutput = cmd /c "node seed7/bin/s7.js -l seed7/lib doom3_seed7_runtime.s7 --help 2>&1"
$helpText = $helpOutput | Out-String
if ($LASTEXITCODE -ne 0) {
  throw "Runtime help failed with exit code $LASTEXITCODE.`n$helpText"
}
Assert-TextContains -Text $helpText -Needle "--engine_mode generated" -Label "runtime help"
Assert-TextContains -Text $helpText -Needle "--visual_smoke_frames" -Label "runtime help"
Assert-TextContains -Text $helpText -Needle "generated replacement assets" -Label "runtime help"

Write-Host "Verification complete. Active path is the Seed7 engine shell with generated replacement assets."
