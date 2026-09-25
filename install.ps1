<#
.SYNOPSIS
    Install tutor mode into a repository so it runs automatically in every session.

.DESCRIPTION
    Windows/PowerShell counterpart to install.sh. Copies TUTOR.md into the target repo and
    writes the thin pointer files that each AI coding tool auto-loads. Behaviour matches
    install.sh: existing pointer files are never overwritten.

.PARAMETER Target
    The repo to install into. Defaults to the current directory.

.EXAMPLE
    .\install.ps1
    Install into the current directory.

.EXAMPLE
    .\install.ps1 C:\path\to\repo
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

$pointer = @'
# Operating contract

Read `TUTOR.md` in this repository and follow it for the whole session. Start by asking the
three configuration questions at the top of that file, and wait for the answers.
'@

foreach ($name in @("CLAUDE.md", "AGENTS.md", "GEMINI.md", ".cursorrules", ".windsurfrules")) {
    $dest = Join-Path $TargetPath $name
    if (Test-Path -LiteralPath $dest) {
        if (Select-String -LiteralPath $dest -Pattern "TUTOR.md" -SimpleMatch -Quiet) {
            Write-Host "ok      $name (already points at TUTOR.md)"
        } else {
            Write-Host "SKIPPED $name - it already exists. Add this line to the top of it:"
            Write-Host "          Read ``TUTOR.md`` in this repository and follow it for the whole session."
        }
    } else {
        Write-Utf8NoBom -Path $dest -Content ($pointer + "`n")
        Write-Host "wrote   $name"
    }
}

Write-Host ""
Write-Host "Installed into $TargetPath"
Write-Host "Verify: start a session there and say only 'hello'."
Write-Host "The assistant should ask three configuration questions and wait."
