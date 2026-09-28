<#
.SYNOPSIS
    Keep the volatile build directories OUT of OneDrive, without moving the repo.

.DESCRIPTION
    v1.23.6 (Session 65c). The repo lives under OneDrive and stays there.
    OneDrive's Files On-Demand turns freshly written large files into cloud
    placeholders, and a placeholder is an NTFS reparse point, which Java
    refuses to snapshot. That produces, mid-build:

        Execution failed for task ':app:mergeReleaseNativeLibs'.
          > java.io.IOException: Cannot snapshot ...\libcactus.so:
            not a regular file

    The AAB builds, then the APK dies, because OneDrive re-attributes the
    .so files the AAB step just wrote.

    Only the BUILD OUTPUT needs to leave sync, and all of it lives under
    <repo>\build (android\build.gradle.kts points rootProject and every
    subproject there), plus .dart_tool and android\.gradle.

    So each of those becomes an NTFS junction to a local disk path.
    OneDrive syncs a junction's contents once when it is created and then
    ignores all later changes to them, so creating the junction while the
    target is EMPTY means the build tree never enters sync at all: no
    dehydration, no 1 GB upload per build. Junctions need no admin rights.

.PARAMETER LocalRoot
    Where the build output really lives. Defaults to %AWING_BUILD_ROOT%,
    else C:\dev\awing-build. Must NOT be inside OneDrive.

.PARAMETER ArtifactRoot
    Where an existing build\app\outputs is rescued to on first conversion,
    so a freshly built AAB is never destroyed by this script.

.NOTES
    Idempotent. First run converts; later runs just verify and return.
    Exits non-zero on failure so build_and_run.bat can stop cold rather
    than walk into the known-broken state.
#>
[CmdletBinding()]
param(
    [string]$LocalRoot    = $(if ($env:AWING_BUILD_ROOT) { $env:AWING_BUILD_ROOT } else { 'C:\dev\awing-build' }),
    [string]$ArtifactRoot = $(if ($env:AWING_ARTIFACT_ROOT) { $env:AWING_ARTIFACT_ROOT } else { 'C:\dev\awing-artifacts' }),

    # Report what would happen and change nothing. Worth running once
    # before the first real conversion, because that run deletes a
    # directory tree.
    [switch]$DryRun,

    # Paths to leave alone, by their name in the table below, e.g.
    #     -Exclude 'android\.gradle'
    # Only `build` is actually required: that is where the 1 GB of native
    # libs and merged assets live, and where OneDrive's dehydration broke
    # mergeReleaseNativeLibs. `.dart_tool` and `android\.gradle` are
    # belt-and-braces, so if either one upsets a tool, drop it rather than
    # abandoning the fix.
    [string[]]$Exclude = @()
)

$ErrorActionPreference = 'Stop'

function Write-Step($msg) { Write-Host "       $msg" }
function Write-Warn($msg) { Write-Host "       ! $msg" -ForegroundColor Yellow }
function Write-Err ($msg) { Write-Host "       X $msg" -ForegroundColor Red }

$repo = Split-Path -Parent $PSScriptRoot
if ($DryRun) { Write-Host "       [dry run] nothing will be changed" -ForegroundColor Cyan }

# A target inside OneDrive would defeat the whole point, and the failure
# would look identical to the one we are fixing.
if ($LocalRoot -match '(?i)onedrive') {
    Write-Err "LocalRoot is inside OneDrive: $LocalRoot"
    Write-Err "Set AWING_BUILD_ROOT to a path on local disk, e.g. C:\dev\awing-build"
    exit 1
}

$maps = @(
    @{ Link = 'build';           Target = (Join-Path $LocalRoot 'build') },
    @{ Link = '.dart_tool';      Target = (Join-Path $LocalRoot 'dart_tool') },
    @{ Link = 'android\.gradle'; Target = (Join-Path $LocalRoot 'android-gradle') }
)

# Returns the junction/symlink target, or $null when the path is not one.
#
# THE TRAP (hit on the first run of this script, 2026-09-28):
# a OneDrive cloud placeholder is ALSO an NTFS reparse point. Testing the
# ReparsePoint attribute alone reported the real `build` directory as a
# junction, so the script took the re-link branch and called the
# NON-recursive Directory.Delete on a full directory:
#     Exception calling "Delete" with "2" argument(s):
#     "The directory is not empty."
# The attribute says "there is a reparse point here", not "this is a link".
# The tag is what distinguishes them, so check for a real link target.
function Get-JunctionTarget($path) {
    $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    if (-not $item) { return $null }
    if (-not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { return $null }

    $linkType = $null
    try { $linkType = $item.LinkType } catch { }
    if ($linkType -and ($linkType -eq 'Junction' -or $linkType -eq 'SymbolicLink')) {
        $t = $item.Target
        if ($t -is [array]) { if ($t.Count -gt 0) { return [string]$t[0] } }
        elseif ($t) { return [string]$t }
    }

    # A placeholder has no target; a junction always does. This alone is
    # the discriminator that the first version was missing.
    $t2 = $item.Target
    if ($t2 -is [array]) { if ($t2.Count -gt 0 -and $t2[0]) { return [string]$t2[0] } }
    elseif ($t2) { return [string]$t2 }

    # Last resort: fsutil names the reparse tag outright.
    try {
        $out = & cmd.exe /c "fsutil reparsepoint query `"$path`"" 2>$null
        if ($out) {
            $text = ($out -join "`n")
            if ($text -match 'Mount Point|Symbolic Link') {
                if ($text -match 'Print Name:\s*(.+)') { return $Matches[1].Trim() }
                return 'unknown'
            }
        }
    } catch { }

    return $null   # reparse point, but not a link — i.e. a cloud placeholder
}

# rd /s /q rather than Remove-Item -Recurse: it is far faster on a tree this
# size, and it deletes a nested junction as a link instead of recursing
# through it and destroying the target's contents.
function Remove-RealDirectory($path) {
    & cmd.exe /c "rd /s /q `"$path`"" 2>$null | Out-Null
    return -not (Test-Path -LiteralPath $path)
}

$converted = 0

foreach ($map in $maps) {
    if ($Exclude -contains $map.Link) {
        Write-Step "$($map.Link) skipped (-Exclude)"
        continue
    }

    $link   = Join-Path $repo $map.Link
    $target = $map.Target

    if (-not (Test-Path -LiteralPath $target)) {
        if ($DryRun) { Write-Step "would create target $target" }
        else { New-Item -ItemType Directory -Force -Path $target | Out-Null }
    }

    if (Test-Path -LiteralPath $link) {
        $existing = Get-JunctionTarget $link
        if ($existing) {
            if ($existing.TrimEnd('\') -ieq $target.TrimEnd('\')) {
                Write-Step "$($map.Link) -> $target  [ok]"
                continue
            }
            Write-Warn "$($map.Link) points at '$existing', re-linking to '$target'"
            if ($DryRun) { continue }
            # Removing a junction removes the link, not the target's contents.
            [System.IO.Directory]::Delete($link, $false)
        }
        else {
            # A real directory. Rescue anything we would be sorry to lose,
            # then delete it. Everything under build\ is regenerable EXCEPT
            # the artifacts in build\app\outputs, which can be a 1 GB AAB
            # that took minutes to produce.
            $outputs = Join-Path $link 'app\outputs'
            if ($DryRun) {
                Write-Step "$($map.Link) is a REAL directory (not a link)"
                if ($map.Link -eq 'build' -and (Test-Path -LiteralPath $outputs)) {
                    Write-Step "  would rescue $outputs to $ArtifactRoot\<timestamp>"
                }
                Write-Step "  would delete $link, then link it to $target"
                continue
            }
            if ($map.Link -eq 'build' -and (Test-Path -LiteralPath $outputs)) {
                $stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
                $rescue = Join-Path $ArtifactRoot $stamp
                New-Item -ItemType Directory -Force -Path $rescue | Out-Null
                Write-Step "rescuing existing artifacts to $rescue"
                # Move, not copy: C:\dev and the OneDrive folder are on the
                # same volume, so this is a rename rather than a 1 GB copy.
                # Falls back to a copy if they ever are not.
                try {
                    Move-Item -Path (Join-Path $outputs '*') -Destination $rescue -Force
                }
                catch {
                    Write-Warn "move failed, copying instead: $($_.Exception.Message)"
                    Copy-Item -Path (Join-Path $outputs '*') -Destination $rescue -Recurse -Force
                }
            }

            Write-Step "converting $($map.Link) to a junction (first run, this can take a moment)"
            if (-not (Remove-RealDirectory $link)) {
                Write-Err "could not delete $link"
                Write-Err "Pause OneDrive syncing, close Android Studio and any running"
                Write-Err "Gradle daemon (gradlew --stop), then run this script again."
                exit 1
            }
        }
    }

    if ($DryRun) {
        Write-Step "$($map.Link) would be linked to $target"
        continue
    }
    New-Item -ItemType Junction -Path $link -Target $target | Out-Null
    $converted++
    Write-Step "$($map.Link) -> $target  [linked]"
}

# Verify rather than assume. A junction that silently did not take is the
# same failure we are trying to prevent, one build later.
if ($DryRun) { Write-Host "       [dry run] complete - nothing was changed" -ForegroundColor Cyan; exit 0 }

$bad = @()
foreach ($map in $maps) {
    if ($Exclude -contains $map.Link) { continue }
    $link = Join-Path $repo $map.Link
    if (-not (Get-JunctionTarget $link)) { $bad += $map.Link }
}
if ($bad.Count -gt 0) {
    Write-Err ("not a junction after setup: " + ($bad -join ', '))
    exit 1
}

if ($converted -gt 0) {
    Write-Step "$converted director(ies) now live outside OneDrive at $LocalRoot"
}
exit 0
