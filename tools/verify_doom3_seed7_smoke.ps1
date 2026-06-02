param(
  [switch]$Build
)

$ErrorActionPreference = "Stop"

function Assert-ContainsNoString {
  param(
    [string]$Path,
    [string]$Pattern,
    [string]$Message
  )
  $content = Get-Content -LiteralPath $Path -Raw
  if ($content -match $Pattern) {
    throw "$Message`n  File: $Path`n  Pattern: $Pattern"
  }
}

Write-Host "== Doom3 Seed7 verification =="

if ($Build) {
  Write-Host "Building wasm runtime for browser..."
  python build_s7_wasm.py browser
}

if (-not (Test-Path -LiteralPath "doom3_seed7_playloop.s7")) {
  throw "Missing required entrypoint: doom3_seed7_playloop.s7"
}

if (-not (Test-Path -LiteralPath "doom3.html")) {
  throw "Missing Doom3 launcher: doom3.html"
}

Write-Host "Checking legacy prototype references were removed from launch/runtime docs..."
$forbidden = "raycaster|ray caster"
$targets = @(
  "README.md",
  "index.html",
  "doom3.html",
  "tools\\run_doom3_seed7_browser.ps1",
  "tools\\run_doom3_seed7_native.ps1"
)

foreach ($target in $targets) {
  Assert-ContainsNoString -Path $target -Pattern $forbidden -Message "Legacy prototype wording detected"
}

if (-not (Test-Path -LiteralPath "wasm/s7.js") -or -not (Test-Path -LiteralPath "wasm/s7.wasm")) {
  Write-Host "WASM artifacts missing; building before verification..."
  python build_s7_wasm.py browser
}

Write-Host "Running full subsystem smoke harness..."
powershell -ExecutionPolicy Bypass -File .\tools\smoke_doom3_seed7.ps1
if ($LASTEXITCODE -ne 0) {
  throw "Subsystem smoke harness failed with exit code $LASTEXITCODE"
}

Write-Host "Running doom3_seed7_playloop help probe..."
node seed7/bin/s7.js -l seed7/lib doom3_seed7_playloop.s7 --help | Out-Host

Write-Host "Verification complete. Doom3 Seed7 runtime is wired as the active launch target."
