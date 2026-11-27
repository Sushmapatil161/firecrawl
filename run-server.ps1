# Starts the Firecrawl v2 API on http://localhost:3002 (no DB, no Redis, no Docker).
#
#   .\run-server.ps1                 # fully local, nothing sent to Firecrawl Cloud
#   .\run-server.ps1 -Cloud auto     # also allow /v2/search + blocked-page fallback via Firecrawl Cloud
#   .\run-server.ps1 -Port 4000

param(
    [ValidateSet('off', 'search', 'auto')] [string]$Cloud = 'off',
    [int]$Port = 3002
)

$exe = Join-Path $PSScriptRoot 'bin\firecrawl-local.exe'
if (-not (Test-Path $exe)) { throw "Not built yet - run .\build.ps1 first." }

$env:FIRECRAWL_CLOUD = $Cloud
# Use the installed Chrome (falls back to Edge) for JavaScript-heavy pages.
foreach ($c in "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
               "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe") {
    if (Test-Path $c) { $env:FIRECRAWL_CHROME_PATH = $c; break }
}

Write-Host "Firecrawl Local on http://localhost:$Port  (cloud=$Cloud, browser=$env:FIRECRAWL_CHROME_PATH)" -ForegroundColor Green
& $exe serve --port $Port
