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

function Assert-FileMatches {
  param(
    [string]$Path,
    [string]$Pattern,
    [string]$Label
  )
  $content = Get-Content -LiteralPath $Path -Raw
  if (-not ($content -match $Pattern)) {
    throw "$Label missing expected pattern.`n  File: $Path`n  Pattern: $Pattern"
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

Write-Host "== Doom3 Seed7 playable runtime verification =="

$activeFiles = @(
  "README.md",
  "index.html",
  "doom3.html",
  "doom3_seed7_runtime.s7",
  "doom3_seed7_game.s7",
  ".github\workflows\deploy-pages.yml",
  "tools\run_doom3_seed7_browser.ps1",
  "tools\run_doom3_seed7_native.ps1"
)

foreach ($file in $activeFiles) {
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
Assert-FileContains -Path "doom3.html" -Needle "Doom3 Seed7 Playable" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "doom3_seed7_runtime.s7" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "doom3_seed7_game.s7" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "wasm/s7.js" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "'--doom3_data_path', '/doom3'" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "'--doom3_start_map', startMap" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "accept=`".pk4,.zip`"" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle '/\.s7$/i' -Label "browser launcher runtime extension check"
Assert-FileNotMatches -Path "doom3.html" -Pattern ([regex]::Escape('/\\.s7$/i')) -Label "browser launcher stale escaped runtime extension check"
$syntheticFixtureNeedle = "Synthetic " + "fixture"
Assert-FileNotMatches -Path "doom3.html" -Pattern ([regex]::Escape($syntheticFixtureNeedle)) -Label "browser launcher"

Write-Host "Checking Pages artifact contents..."
Assert-FileContains -Path ".github\workflows\deploy-pages.yml" -Needle "cp doom3_seed7_runtime.s7 doom3_seed7_game.s7 _site/" -Label "Pages deploy"
Assert-FileNotMatches -Path ".github\workflows\deploy-pages.yml" -Pattern "cp doom3_seed7\*\.s7" -Label "Pages deploy"
Assert-FileNotMatches -Path ".github\workflows\deploy-pages.yml" -Pattern "\bfixtures\b" -Label "Pages deploy"

Write-Host "Running playable native smoke..."
$smokeOutput = cmd /c "node seed7/bin/s7.js -l seed7/lib doom3_seed7_runtime.s7 --smoke_frames 2 2>&1"
$smokeText = $smokeOutput | Out-String
if ($LASTEXITCODE -ne 0) {
  throw "Playable smoke failed with exit code $LASTEXITCODE.`n$smokeText"
}
Assert-TextContains -Text $smokeText -Needle "smoke_frame_1" -Label "playable smoke"
Assert-TextContains -Text $smokeText -Needle "smoke_frame_2" -Label "playable smoke"
Assert-TextContains -Text $smokeText -Needle "smoke_hashes=" -Label "playable smoke"
Assert-TextContains -Text $smokeText -Needle "game_smoke_ready=TRUE" -Label "playable smoke"
Write-Host $smokeText

Write-Host "Running runtime help..."
$helpOutput = cmd /c "node seed7/bin/s7.js -l seed7/lib doom3_seed7_runtime.s7 --help 2>&1"
$helpText = $helpOutput | Out-String
if ($LASTEXITCODE -ne 0) {
  throw "Runtime help failed with exit code $LASTEXITCODE.`n$helpText"
}
Assert-TextContains -Text $helpText -Needle "--smoke_frames" -Label "runtime help"
Assert-TextContains -Text $helpText -Needle "generated Doom 3 style assets" -Label "runtime help"

Write-Host "Verification complete. Active GitHub Pages path is the playable Doom3 Seed7 runtime."
