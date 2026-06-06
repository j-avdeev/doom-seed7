param(
  [int]$Port = 8080
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$url = "http://localhost:$Port/web/index.html"

Write-Host "Serving $repoRoot"
Write-Host "Open $url"
python -m http.server $Port --bind 127.0.0.1 --directory $repoRoot
