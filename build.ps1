# Builds Firecrawl Local (pure Rust, no DB/Docker) and copies the exe to .\bin\
#
#   powershell -ExecutionPolicy Bypass -File .\build.ps1
#
# The cargo target dir is kept OUTSIDE OneDrive - otherwise OneDrive tries to
# sync gigabytes of build artifacts and can lock files mid-build.

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$crate = Join-Path $root 'firecrawl-local'

$env:Path += ";$env:USERPROFILE\.cargo\bin;$env:ProgramFiles\NASM"
# CMake bundled with VS Build Tools (used if standalone CMake isn't installed)
$vsCmake = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"
if (-not (Get-Command cmake -ErrorAction SilentlyContinue) -and (Test-Path $vsCmake)) { $env:Path += ";$vsCmake" }
$env:CARGO_TARGET_DIR = Join-Path $env:LOCALAPPDATA 'firecrawl-local-target'
$env:CARGO_NET_GIT_FETCH_WITH_CLI = 'true'

Push-Location $crate
try {
    cargo build --release --locked
    if ($LASTEXITCODE -ne 0) { throw "cargo build failed ($LASTEXITCODE)" }
} finally { Pop-Location }

New-Item -ItemType Directory -Force "$root\bin" | Out-Null
Copy-Item "$env:CARGO_TARGET_DIR\release\firecrawl-local.exe" "$root\bin\firecrawl-local.exe" -Force
& "$root\bin\firecrawl-local.exe" --version
Write-Host "`nBuilt: $root\bin\firecrawl-local.exe" -ForegroundColor Green
