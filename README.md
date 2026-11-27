# Firecrawl, built locally with Rust on Windows (no DB, no Docker)

This builds **Firecrawl Local**, the single-binary Rust edition of Firecrawl.
It serves the Firecrawl **v2 API** on `localhost:3002` using the same HTML-cleaning code as the
real API (vendored in `firecrawl-local/src/native`). It needs no Postgres, Supabase, Redis, RabbitMQ or Docker.
Only the Rust crate is kept here; the rest of the Firecrawl monorepo was removed.

## Files

| File | Purpose |
| --- | --- |
| `install-deps.ps1` | Installs Rust (MSVC), VS 2022 C++ Build Tools, CMake, NASM, Git via winget |
| `build.ps1` | `cargo build --release` and copies the exe to `bin\firecrawl-local.exe` |
| `run-server.ps1` | Starts the API on port 3002 (`-Cloud off` by default = 100% local) |
| `firecrawl-local\` | Rust source of Firecrawl Local (self-contained, `src\native` = shared cleaning code) |
| `bin\` | Built `firecrawl-local.exe` (created by `build.ps1`) |

## Steps

```powershell
# 1. Install toolchain (accept the UAC prompt for VS Build Tools; ~5-10 GB, 10-30 min)
powershell -ExecutionPolicy Bypass -File .\install-deps.ps1

# 2. Open a NEW terminal so PATH updates, then build (first build ~5-15 min)
powershell -ExecutionPolicy Bypass -File .\build.ps1

# 3. Start the API server
powershell -ExecutionPolicy Bypass -File .\run-server.ps1
```

## Use it

```powershell
# CLI, no server needed
.\bin\firecrawl-local.exe scrape https://example.com --markdown
.\bin\firecrawl-local.exe crawl https://docs.firecrawl.dev --limit 20 --out .\pages
.\bin\firecrawl-local.exe map https://firecrawl.dev

# API (with run-server.ps1 running)
Invoke-RestMethod http://localhost:3002/v2/scrape -Method Post -ContentType 'application/json' `
  -Body '{"url":"https://example.com","formats":["markdown"]}'
```

Python SDK: `pip install firecrawl-py`, then `Firecrawl(api_url="http://localhost:3002")`. No API key is needed.

Local routes: `POST /v2/scrape`, `POST /v2/map`, `/v2/crawl[/{id}]`, `/v2/batch/scrape[/{id}]`, `GET /health`.

## Limits compared with the full server (apps/api)

- No `json`/`summary` (LLM) formats and no browser `actions`.
- Crawl and batch jobs are kept in memory, so they are lost when the server stops.
- `/v2/search` needs `-Cloud auto` or `-Cloud search`, because it goes to Firecrawl Cloud.
- v0/v1 routes are not served.

The full server with every format (`apps/api` in the Firecrawl repo) needs Node, Redis and Postgres, so it isn't included here.

## Troubleshooting

- **`link.exe not found` / `cl.exe` errors**: VS Build Tools is missing the C++ workload. Re-run `install-deps.ps1`, or open *Visual Studio Installer*, then *Modify*, then tick *Desktop development with C++*.
- **aws-lc-sys build error**: make sure `cmake` and `nasm` are on PATH (open a new terminal).
- **`cargo` not recognized**: open a new terminal, or add `%USERPROFILE%\.cargo\bin` to PATH.
- Build output lives in `%LOCALAPPDATA%\firecrawl-local-target` (outside OneDrive on purpose).
