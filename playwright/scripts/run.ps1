<#
.SYNOPSIS
    One-command Playwright runner for the Filhos (Criarte) Flutter web build.
    Boots the Firebase Auth emulator and per-flavor static servers via
    global-setup, captures all logs under artifacts/<run-id>/logs/, then
    runs the requested project set.

.DESCRIPTION
    Equivalent to `npx playwright test` from playwright/ with the process
    orchestration baked in. Logs auto-attach to failing tests in the HTML
    report.

.PARAMETER Flavor
    Restrict the run to a single flavor (`parents` or `professores`). Default
    runs both. Maps to `--project=<flavor>-seed` etc.

.PARAMETER Kind
    Restrict the run to one project kind: `seed`, `generated`, or `snapshot`.
    Default runs all kinds for the chosen flavor(s).

.PARAMETER Headed
    Run Chromium in a visible window instead of headless.

.PARAMETER UI
    Open Playwright's interactive Test UI instead of running once.

.PARAMETER Grep
    Filter spec titles by a substring or regex (passed to `--grep`).

.PARAMETER Live
    Echo Flutter and emulator stdout to your terminal in real time.

.PARAMETER Rebuild
    Force `flutter build web --release` even when the cached build looks
    fresh (sets PW_REBUILD=1). Use this after a `lib/` edit you want the
    harness to pick up immediately.

.PARAMETER BaseUrlParents
    Point the harness at a Flutter web server you already have running for
    the parents flavor (sets PW_BASE_URL_PARENTS). globalSetup skips
    spawning its own static server for that flavor.

.PARAMETER BaseUrlProfessores
    Same, for the professores flavor (PW_BASE_URL_PROFESSORES).

.EXAMPLE
    pwsh playwright\scripts\run.ps1

.EXAMPLE
    pwsh playwright\scripts\run.ps1 -Flavor parents -Kind generated -Headed

.EXAMPLE
    pwsh playwright\scripts\run.ps1 -UI -Live

.NOTES
    Equivalent npm shortcuts (run from playwright/):
      npm run generated           # generator-produced specs (both flavors)
      npm run generated:parents   # parents only
      npm run generated:professores # professores only
      npm run snapshot            # aria-snapshot project (both flavors)
      npm run report              # open last HTML report
#>
[CmdletBinding()]
param(
    [ValidateSet('parents','professores','both')]
    [string]$Flavor = 'both',
    [ValidateSet('generated','snapshot','all')]
    [string]$Kind = 'all',
    [switch]$Headed,
    [switch]$UI,
    [string]$Grep,
    [switch]$Live,
    [switch]$Rebuild,
    [string]$BaseUrlParents,
    [string]$BaseUrlProfessores
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $PSCommandPath
$pwDir = Split-Path -Parent $here

if ($Live) { $env:E2E_VERBOSE = '1' } else { Remove-Item env:E2E_VERBOSE -ErrorAction SilentlyContinue }
if ($Rebuild) { $env:PW_REBUILD = '1' } else { Remove-Item env:PW_REBUILD -ErrorAction SilentlyContinue }

if ($BaseUrlParents) { $env:PW_BASE_URL_PARENTS = $BaseUrlParents } else { Remove-Item env:PW_BASE_URL_PARENTS -ErrorAction SilentlyContinue }
if ($BaseUrlProfessores) { $env:PW_BASE_URL_PROFESSORES = $BaseUrlProfessores } else { Remove-Item env:PW_BASE_URL_PROFESSORES -ErrorAction SilentlyContinue }

# Build the project filter from -Flavor and -Kind.
$flavors = if ($Flavor -eq 'both') { @('parents','professores') } else { @($Flavor) }
$kinds   = if ($Kind   -eq 'all')  { @('generated','snapshot') } else { @($Kind) }

$pwArgs = @('playwright', 'test')
if ($UI) { $pwArgs = @('playwright', 'test', '--ui') }
if ($Headed) { $pwArgs += '--headed' }
if ($Grep) { $pwArgs += @('--grep', $Grep) }
foreach ($f in $flavors) {
    foreach ($k in $kinds) {
        $pwArgs += @('--project', "$f-$k")
    }
}

Push-Location $pwDir
try {
    Write-Host "==> Running: npx $($pwArgs -join ' ')" -ForegroundColor Cyan
    Write-Host "    Logs:    $pwDir\artifacts\<run-id>\logs\{firebase-emulators,flutter-run.<flavor>}.log" -ForegroundColor DarkGray
    Write-Host "    Report:  $pwDir\artifacts\<run-id>\playwright-report\index.html" -ForegroundColor DarkGray
    Write-Host ''

    & npx @pwArgs
    $exit = $LASTEXITCODE
    if ($exit -ne 0) { throw "playwright test exited with code $exit" }
} finally {
    Pop-Location
}
