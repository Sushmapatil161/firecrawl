# Interactive Firecrawl: type a URL, pick scrape / crawl / map, see the result.
#
#   powershell -ExecutionPolicy Bypass -File .\start.ps1

$exe = Join-Path $PSScriptRoot 'bin\firecrawl-local.exe'
if (-not (Test-Path $exe)) { Write-Host "Not built yet - run .\build.ps1 first." -ForegroundColor Red; exit 1 }

$env:FIRECRAWL_CLOUD = 'off'   # everything runs on this machine
foreach ($c in "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
               "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe") {
    if (Test-Path $c) { $env:FIRECRAWL_CHROME_PATH = $c; break }
}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "`n=== Firecrawl Local ===  (type 'exit' to quit)`n" -ForegroundColor Cyan

while ($true) {
    $url = (Read-Host "Enter website URL").Trim()
    if ($url -eq '' ) { continue }
    if ($url -in 'exit', 'quit', 'q') { break }

    Write-Host "  1) Scrape  - this one page as markdown"
    Write-Host "  2) Crawl   - follow links and scrape many pages"
    Write-Host "  3) Map     - list all URLs on the site"
    $mode = (Read-Host "Choose 1, 2 or 3 [1]").Trim()
    if ($mode -eq '') { $mode = '1' }

    switch ($mode) {
        '1' {
            Write-Host "`nScraping $url ...`n" -ForegroundColor Yellow
            & $exe scrape $url --markdown
        }
        '2' {
            $limit = (Read-Host "How many pages max? [10]").Trim()
            if ($limit -notmatch '^\d+$') { $limit = '10' }
            # Pages go to a temporary folder, are printed on screen, then the folder is deleted.
            $tmp = Join-Path $env:TEMP ("firecrawl-crawl-" + [guid]::NewGuid().ToString('N'))
            Write-Host "`nCrawling $url (up to $limit pages) ...`n" -ForegroundColor Yellow
            try {
                # Show crawl warnings/errors, but drop the "saved to <temp folder>" part of the summary.
                & $exe crawl $url --limit $limit --out $tmp 2>&1 | ForEach-Object {
                    $line = "$_"
                    if ($line -match 'pages? in .*, saved to ') { $line = $line -replace ', saved to .*$', '' }
                    if ($line -match '\S' -and $line -notmatch '\.md\s+https?://') { Write-Host $line -ForegroundColor DarkGray }
                }
                $pages = Get-ChildItem $tmp -Filter *.md -ErrorAction SilentlyContinue | Sort-Object Name
                $n = 0
                foreach ($p in $pages) {
                    $n++
                    $lines = Get-Content $p.FullName -Encoding utf8
                    $pageUrl = ($lines | Where-Object { $_ -match '^url:' } | Select-Object -First 1) -replace '^url:\s*"?|"$', ''
                    $title   = ($lines | Where-Object { $_ -match '^title:' } | Select-Object -First 1) -replace '^title:\s*"?|"$', ''
                    # Skip the small url/title header block at the top of each file.
                    $body = $lines
                    if ($lines.Count -gt 0 -and $lines[0] -eq '---') {
                        $end = [Array]::IndexOf($lines, '---', 1)
                        if ($end -gt 0) { $body = $lines[($end + 1)..($lines.Count - 1)] }
                    }
                    Write-Host "`n==================== Page $n of $($pages.Count) ====================" -ForegroundColor Cyan
                    Write-Host "Title: $title" -ForegroundColor Green
                    Write-Host "URL:   $pageUrl`n" -ForegroundColor Green
                    $body | ForEach-Object { Write-Host $_ }
                }
                if ($n -eq 0) { Write-Host "No pages could be crawled." -ForegroundColor Red }
                else { Write-Host "`nCrawled $n page(s)." -ForegroundColor Green }
            } finally {
                Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        '3' {
            Write-Host "`nMapping $url ...`n" -ForegroundColor Yellow
            $json = & $exe map $url | Out-String
            try {
                $links = ($json | ConvertFrom-Json).links
                $links | ForEach-Object { Write-Host "  $_" }
                Write-Host "`n$($links.Count) URLs found" -ForegroundColor Green
            } catch { Write-Host $json }
        }
        default { Write-Host "Please type 1, 2 or 3." -ForegroundColor Red }
    }
    Write-Host "`n----------------------------------------`n" -ForegroundColor DarkGray
}
