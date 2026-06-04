param(
  [string]$Port = "8080",
  [switch]$Build,
  [switch]$NoOpen
)

$ErrorActionPreference = "Stop"

$url = "http://localhost:${Port}/doom3.html"
$runtimeUrl = "http://localhost:${Port}/doom3_seed7_runtime.s7"

if ($Build) {
  Write-Host "Building Seed7 wasm browser runtime..."
  python build_s7_wasm.py browser
}

if (-not (Test-Path "doom3_seed7_runtime.s7")) {
  throw "doom3_seed7_runtime.s7 is missing; rebuild from a complete repository checkout."
}

if (-not (Test-Path "wasm/s7.js") -or -not (Test-Path "wasm/s7.wasm")) {
  Write-Host "WASM runtime artifacts missing; running build automatically..."
  python build_s7_wasm.py browser
}

Write-Host "Starting local static server for Doom3 Seed7 playable launcher..."
$server = Start-Process -FilePath python -ArgumentList @("-m", "http.server", $Port) -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 1

try {
  Write-Host "Verifying launcher artifacts..."
  Invoke-WebRequest -Uri "$url" -UseBasicParsing | Out-Null
  Invoke-WebRequest -Uri $runtimeUrl -UseBasicParsing | Out-Null
  Write-Host "Server running at $url"
  Write-Host "Runtime reachable at $runtimeUrl"
  Write-Host ""
  Write-Host "Playable browser smoke path:"
  Write-Host "  1) Open $url"
  Write-Host "  2) Optionally select local Doom 3 *.pk4/.zip files"
  Write-Host "  3) Click 'Launch'"
  Write-Host "  4) Confirm the game canvas appears with wall geometry, weapon, and HUD."
  Write-Host ""
  Write-Host "For command-line sanity checks, use:"
  Write-Host "  powershell -ExecutionPolicy Bypass -File .\\tools\\verify_doom3_seed7_smoke.ps1"
  Write-Host "  node seed7/bin/s7.js -l seed7/lib doom3_seed7_runtime.s7 --smoke_frames 2"
  Write-Host ""
  if (-not $NoOpen) {
    Start-Process $url | Out-Null
  } else {
    Write-Host "NoOpen set; server left running for manual open."
  }
  Write-Host "Press Ctrl+C in this shell to stop the server when you're done."
  while ($true) {
    Start-Sleep -Seconds 1
  }
}
finally {
  if ($server -and -not $server.HasExited) {
    Stop-Process -Id $server.Id -Force
  }
}
