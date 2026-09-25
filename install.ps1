<#
.SYNOPSIS
    Install tutor mode into a repository so it runs automatically in every Claude Code session.

.DESCRIPTION
    Windows/PowerShell counterpart to install.sh. Copies TUTOR.md into the target repo and
    writes a CLAUDE.md that imports it. Behaviour matches install.sh; an existing CLAUDE.md is
    never overwritten.

.PARAMETER Target
    The repo to install into. Defaults to the current directory.

.EXAMPLE
    .\install.ps1
    Install into the current directory.

.EXAMPLE
    .\install.ps1 "C:\path\to\repo"
    Install into that repo.

.EXAMPLE
    irm https://raw.githubusercontent.com/DinakerJ/tutor-kit/main/install.ps1 | iex
    Install into the current directory straight from GitHub, without cloning.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Target = "."
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$RawBase = "https://raw.githubusercontent.com/DinakerJ/tutor-kit/main"

# Windows PowerShell 5.1 still offers TLS 1.0 by default; GitHub refuses anything below 1.2.
try {
    [Net.ServicePointManager]::SecurityProtocol =
        [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} catch {
    # Newer PowerShell manages this itself and the property may be read-only.
}

if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
    Write-Error "$Target is not a directory"
    exit 1
}
$TargetPath = (Resolve-Path -LiteralPath $Target).ProviderPath

# Set-Content -Encoding utf8 writes a BOM on 5.1, and a BOM ahead of the first heading can
# stop a tool from matching it. Write UTF-8 without one.
function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

$tutorDest = Join-Path $TargetPath "TUTOR.md"

# Use the TUTOR.md sitting next to this script if there is one; otherwise download it.
$srcDir = ""
if ($PSScriptRoot -and (Test-Path -LiteralPath (Join-Path $PSScriptRoot "TUTOR.md"))) {
    $srcDir = $PSScriptRoot
}

if ($srcDir) {
    Copy-Item -LiteralPath (Join-Path $srcDir "TUTOR.md") -Destination $tutorDest -Force
    Write-Host "wrote   TUTOR.md (from $srcDir)"
} else {
    try {
        Invoke-WebRequest -Uri "$RawBase/TUTOR.md" -OutFile $tutorDest -UseBasicParsing
    } catch {
        Write-Error "no local TUTOR.md and the download failed: $($_.Exception.Message)"
        exit 1
    }
    Write-Host "wrote   TUTOR.md (downloaded)"
}

# The @TUTOR.md line is a Claude Code import: it expands the contract into context at launch.
# It must stay outside backticks - Claude Code skips imports inside code spans, which means a
# backticked mention loads nothing and leaves the contract up to chance.
$pointer = @'
# Operating contract

@TUTOR.md

The contract imported above governs this entire session.

Your first action in a new session, including a reply to a bare greeting such as "hello", is
to ask the three configuration questions at the top of that contract (depth, pace, purpose),
then stop and wait. Do not assume defaults. Do not start work, summarise the repo, or answer
anything else until all three are answered.
'@

$dest = Join-Path $TargetPath "CLAUDE.md"
if (Test-Path -LiteralPath $dest) {
    if (Select-String -LiteralPath $dest -Pattern "@TUTOR.md" -SimpleMatch -Quiet) {
        Write-Host "ok      CLAUDE.md (already imports TUTOR.md)"
    } elseif (Select-String -LiteralPath $dest -Pattern 'Read `TUTOR.md` in this repository' -SimpleMatch -Quiet) {
        Write-Utf8NoBom -Path $dest -Content ($pointer + "`n")
        Write-Host "wrote   CLAUDE.md (upgraded an older tutor-kit pointer to a real import)"
    } elseif (Select-String -LiteralPath $dest -Pattern "TUTOR.md" -SimpleMatch -Quiet) {
        Write-Host "ACTION  CLAUDE.md mentions TUTOR.md but does not import it."
        Write-Host "          A backticked mention does not load the contract. Add this line, unquoted:"
        Write-Host "          @TUTOR.md"
    } else {
        Write-Host "SKIPPED CLAUDE.md - it already exists. Add this line to the top of it:"
        Write-Host "          @TUTOR.md"
    }
} else {
    Write-Utf8NoBom -Path $dest -Content ($pointer + "`n")
    Write-Host "wrote   CLAUDE.md"
}

# Earlier versions of this kit also wrote pointer files for other tools. Claude Code ignores
# them, and a stray AGENTS.md can confuse a later reader, so point them out.
$leftovers = @()
foreach ($n in @("AGENTS.md", "GEMINI.md", ".cursorrules", ".windsurfrules")) {
    $p = Join-Path $TargetPath $n
    if ((Test-Path -LiteralPath $p) -and (Select-String -LiteralPath $p -Pattern "TUTOR.md" -SimpleMatch -Quiet)) {
        $leftovers += $n
    }
}
if ($leftovers.Count -gt 0) {
    Write-Host ""
    Write-Host "note    leftover pointer files from an earlier tutor-kit install: $($leftovers -join ' ')"
    Write-Host "        Claude Code does not read them. Safe to delete:"
    Write-Host "          Remove-Item $($leftovers -join ', ')"
}

Write-Host ""
Write-Host "Installed into $TargetPath"
Write-Host "Verify: start a NEW session there and say only 'hello'."
Write-Host "The assistant should ask three configuration questions and wait."
