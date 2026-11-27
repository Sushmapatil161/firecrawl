# Installs everything needed to build Firecrawl Local (apps/local) on Windows.
# No database, no Redis, no Docker - just Rust + the MSVC C toolchain.
#
#   Rust (rustup, stable-x86_64-pc-windows-msvc)  - compiles the crate
#   Visual Studio 2022 Build Tools (C++ workload) - linker + C compiler (mimalloc, aws-lc, zstd, brotli)
#   CMake + NASM                                  - fallback build tools for aws-lc-sys (TLS crypto)
#   Git                                           - fetches the pinned `nodesig` git dependency
#
# Run from PowerShell:  powershell -ExecutionPolicy Bypass -File .\install-deps.ps1
# Visual Studio Build Tools will show a UAC (admin) prompt - accept it.

$ErrorActionPreference = 'Stop'

function Install-Pkg($id, $extra = @()) {
    Write-Host "==> $id" -ForegroundColor Cyan
    $listed = winget list --id $id --exact --accept-source-agreements 2>$null | Out-String
    if ($listed -match [regex]::Escape($id)) { Write-Host "    already installed"; return }
    winget install --id $id --exact --silent --accept-package-agreements --accept-source-agreements @extra
    if ($LASTEXITCODE -ne 0) { Write-Warning "winget exited with $LASTEXITCODE for $id" }
}

Install-Pkg 'Git.Git'
Install-Pkg 'Microsoft.VisualStudio.2022.BuildTools' @('--override', '--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended')
Install-Pkg 'Kitware.CMake'
Install-Pkg 'NASM.NASM'
Install-Pkg 'Rustlang.Rustup'

# Refresh PATH for this session so cargo/rustup are visible immediately.
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [Environment]::GetEnvironmentVariable('Path', 'User') + ';' +
            "$env:USERPROFILE\.cargo\bin;$env:ProgramFiles\NASM"

rustup default stable-x86_64-pc-windows-msvc
rustup update stable

# Long paths help cargo's git checkouts on Windows.
git config --global core.longpaths true

Write-Host "`nInstalled versions:" -ForegroundColor Green
rustc --version
cargo --version
cmake --version | Select-Object -First 1
Write-Host "`nDone. Open a NEW terminal, then run .\build.ps1" -ForegroundColor Green
