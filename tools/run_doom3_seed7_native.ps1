param(
  [Parameter(Mandatory = $true)]
  [string]$DataPath,

  [string]$Seed7Js = "seed7/bin/s7.js",
  [string]$Seed7Lib = "seed7/lib",
  [string]$Entry = "doom3_seed7_runtime.s7",
  [string]$StartMap = "game/mars_city1",
  [switch]$Build,
  [switch]$Help
)

$ErrorActionPreference = "Stop"

if ($Help) {
  Write-Host "Usage:"
  Write-Host "  .\run_doom3_seed7_native.ps1 -DataPath C:\\Path\\To\\Doom3"
  Write-Host ""
  Write-Host "Optional:"
  Write-Host "  -Seed7Js         Path to Seed7 JS runtime"
  Write-Host "  -Seed7Lib        Seed7 lib path"
  Write-Host "  -Entry           Doom3 Seed7 entrypoint (default: doom3_seed7_runtime.s7)"
  Write-Host "  -StartMap        Starting map token (default: game/mars_city1)"
  Write-Host "  -Build           Rebuild wasm runtime before launch"
  Write-Host ""
  exit 0
}

if (-not (Test-Path -LiteralPath $Seed7Js)) {
  throw "Seed7 runtime not found: $Seed7Js"
}

if (-not (Test-Path -LiteralPath $Seed7Lib)) {
  throw "Seed7 library path not found: $Seed7Lib"
}

if (-not (Test-Path -LiteralPath $DataPath)) {
  throw "DOOM data path not found: $DataPath"
}

if (-not (Test-Path -LiteralPath $Entry)) {
  throw "Seed7 entrypoint not found: $Entry"
}

if ($Build) {
  Write-Host "Rebuilding browser Seed7 runtime (wasm) before launch..."
  python build_s7_wasm.py browser
}

if (-not (Test-Path -LiteralPath "wasm/s7.js") -or -not (Test-Path -LiteralPath "wasm/s7.wasm")) {
  throw "WASM runtime artifacts missing; run python build_s7_wasm.py browser and retry."
}

Write-Host "Launching Doom3 Seed7 native run:"
Write-Host "  Seed7 Runtime: $Seed7Js"
Write-Host "  Data path   : $DataPath"
Write-Host "  Entry       : $Entry"
Write-Host "  Start map   : $StartMap"
Write-Host ""

& node $Seed7Js -l $Seed7Lib $Entry --doom3_data_path $DataPath --doom3_start_map $StartMap