<#
.SYNOPSIS
    Install Playwright dependencies + Chromium browser. Run once per checkout.

.DESCRIPTION
    From playwright/, runs `npm install` + `playwright install chromium`,
    then the doctor preflight to verify Node/firebase/flutter are on PATH and
    no port collides.
#>
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $PSCommandPath
$pwDir = Split-Path -Parent $here

Push-Location $pwDir
try {
    Write-Host '==> npm install' -ForegroundColor Cyan
    npm install
    if ($LASTEXITCODE -ne 0) { throw "npm install failed (exit $LASTEXITCODE)" }

    Write-Host '==> Installing Chromium browser' -ForegroundColor Cyan
    npx playwright install chromium
    if ($LASTEXITCODE -ne 0) { throw "playwright install failed (exit $LASTEXITCODE)" }

    Write-Host '==> Doctor preflight' -ForegroundColor Cyan
    npm run doctor

    Write-Host 'Done.' -ForegroundColor Green
} finally {
    Pop-Location
}
