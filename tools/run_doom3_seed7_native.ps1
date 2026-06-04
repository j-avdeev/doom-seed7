param(
  [string]$DataPath = "",
  [string]$Seed7Js = "seed7/bin/s7.js",
  [string]$Seed7Lib = "seed7/lib",
  [string]$Entry = "doom3_seed7_runtime.s7",
  [string]$StartMap = "game/mars_city1",
  [string]$EngineMode = "generated",
  [int]$SmokeFrames = 0,
  [int]$VisualSmokeFrames = 0,
  [switch]$Build,
  [switch]$Help
)

$ErrorActionPreference = "Stop"

if ($Help) {
  Write-Host "Usage:"
  Write-Host "  .\run_doom3_seed7_native.ps1"
  Write-Host "  .\run_doom3_seed7_native.ps1 -SmokeFrames 2"
  Write-Host "  .\run_doom3_seed7_native.ps1 -VisualSmokeFrames 2"
  Write-Host "  .\run_doom3_seed7_native.ps1 -DataPath C:\Path\To\Doom3"
  Write-Host ""
  Write-Host "Optional:"
  Write-Host "  -DataPath        Optional Doom 3 install path for local pk4 compatibility"
  Write-Host "  -Seed7Js         Path to Seed7 JS runtime"
  Write-Host "  -Seed7Lib        Seed7 lib path"
  Write-Host "  -Entry           Doom3 Seed7 entrypoint (default: doom3_seed7_runtime.s7)"
  Write-Host "  -StartMap        Starting map token (default: game/mars_city1)"
  Write-Host "  -EngineMode      generated or pk4 (default: generated)"
  Write-Host "  -SmokeFrames     Render deterministic headless smoke frames, then exit"
  Write-Host "  -VisualSmokeFrames Render deterministic visual smoke metrics, then exit"
  Write-Host "  -Build           Rebuild browser wasm runtime before launch"
  Write-Host ""
  exit 0
}

if (-not (Test-Path -LiteralPath $Seed7Js)) {
  throw "Seed7 runtime not found: $Seed7Js"
}

if (-not (Test-Path -LiteralPath $Seed7Lib)) {
  throw "Seed7 library path not found: $Seed7Lib"
}

if ($DataPath -and -not (Test-Path -LiteralPath $DataPath)) {
  throw "Doom 3 data path not found: $DataPath"
}

if (-not (Test-Path -LiteralPath $Entry)) {
  throw "Seed7 entrypoint not found: $Entry"
}

if ($EngineMode -ne "generated" -and $EngineMode -ne "pk4") {
  throw "EngineMode must be 'generated' or 'pk4'."
}

if ($Build) {
  Write-Host "Rebuilding browser Seed7 runtime (wasm) before launch..."
  python build_s7_wasm.py browser
}

$runtimeArgs = @("-l", $Seed7Lib, $Entry)

if ($SmokeFrames -gt 0) {
  $runtimeArgs += @("--smoke_frames", [string]$SmokeFrames)
} elseif ($VisualSmokeFrames -gt 0) {
  $runtimeArgs += @("--visual_smoke_frames", [string]$VisualSmokeFrames)
} else {
  $runtimeArgs += @("--engine_mode", $EngineMode)
  if ($DataPath) {
    $runtimeArgs += @("--doom3_data_path", $DataPath)
  }
  if ($StartMap) {
    $runtimeArgs += @("--doom3_start_map", $StartMap)
  }
}

Write-Host "Launching Doom3 Seed7 native runtime:"
Write-Host "  Seed7 runtime: $Seed7Js"
Write-Host "  Entry        : $Entry"
if ($SmokeFrames -gt 0) {
  Write-Host "  Smoke frames : $SmokeFrames"
} elseif ($VisualSmokeFrames -gt 0) {
  Write-Host "  Visual smoke : $VisualSmokeFrames"
} else {
  Write-Host "  Engine mode  : $EngineMode"
  Write-Host "  Data path    : $(if ($DataPath) { $DataPath } else { '(generated assets)' })"
  Write-Host "  Start map    : $StartMap"
}
Write-Host ""

& node $Seed7Js @runtimeArgs
