# preflight.ps1 -- pre-push verification for Awing.
# Catches recurring CI failure categories. Run before tagging/pushing.
#
# Usage:
#   ./scripts/preflight.ps1
#   ./scripts/preflight.ps1 -SkipBuild
#   ./scripts/preflight.ps1 -Tag

[CmdletBinding()]
param(
    [switch]$SkipBuild,
    [switch]$Tag
)

$ErrorActionPreference = 'Continue'
$failures = @()
$warnings = @()

function Section($name) {
    Write-Host ""
    Write-Host "=== $name ===" -ForegroundColor Cyan
}

function Fail($msg) {
    Write-Host "  [FAIL] $msg" -ForegroundColor Red
    $script:failures += $msg
}

function Warn($msg) {
    Write-Host "  [WARN] $msg" -ForegroundColor Yellow
    $script:warnings += $msg
}

function Pass($msg) {
    Write-Host "  [OK]   $msg" -ForegroundColor Green
}

# ---------------- 1. Version + tag consistency ----------------
Section "Version + tag consistency"

$pubspec = Get-Content pubspec.yaml -Raw
if ($pubspec -match 'version:\s*(\d+\.\d+\.\d+)\+(\d+)') {
    $semver  = $matches[1]
    $build   = [int]$matches[2]
    Pass "pubspec.yaml = $semver+$build"
} else {
    Fail "Cannot parse version: from pubspec.yaml"
    exit 1
}

$existingTags = git tag --list "v$semver+*"
$conflicting = $existingTags | Where-Object { $_ -match "\+$build$" }
if ($conflicting) {
    Fail "Build $build already tagged as $conflicting -- bump pubspec to +$($build + 1)"
} else {
    Pass "Build $build is fresh (no existing tag)"
}

$allTagsBuilds = git tag --list "v*" | ForEach-Object {
    if ($_ -match '\+(\d+)$') { [int]$matches[1] }
}
$maxPrevBuild = if ($allTagsBuilds) { ($allTagsBuilds | Measure-Object -Maximum).Maximum } else { 0 }
if ($build -le $maxPrevBuild) {
    Warn "Build $build is NOT greater than previous max +$maxPrevBuild -- TestFlight will reject as duplicate"
} else {
    Pass "Build $build > previous max +$maxPrevBuild"
}

$aboutScreen = Get-Content lib/screens/about_screen.dart -Raw -ErrorAction SilentlyContinue
if ($aboutScreen -and ($aboutScreen -match "appVersion\s*=\s*'([\d.]+)'")) {
    if ($matches[1] -ne $semver) {
        Warn "about_screen.dart appVersion = '$($matches[1])' but pubspec = $semver"
    } else {
        Pass "about_screen.dart appVersion in sync"
    }
}

# ---------------- 2. Gradle memory settings (CI-safe) ----------------
Section "Gradle memory (CI-safe)"

$gradleProps = Get-Content android/gradle.properties -Raw
if ($gradleProps -match 'Xmx(\d+)([GgMm])') {
    $heapSize = [int]$matches[1]
    $unit = $matches[2].ToUpper()
    $heapGB = if ($unit -eq 'G') { $heapSize } else { $heapSize / 1024 }
    if ($heapGB -ge 6) {
        Fail "Gradle -Xmx$heapSize$unit is too high for ubuntu-latest runner. Use Xmx3G or Xmx4G."
    } else {
        Pass "Gradle -Xmx$heapSize$unit fits CI runner memory budget"
    }
} else {
    Warn "No -Xmx found in android/gradle.properties -- using JVM default (may be too high)"
}

if ($gradleProps -match 'org\.gradle\.daemon\s*=\s*true') {
    Warn "Gradle daemon enabled -- on CI this consumes memory between APK/AAB invocations"
} else {
    Pass "Gradle daemon disabled or unset (CI-safe)"
}

# ---------------- 3. Dart analyze ----------------
Section "Dart analyze"

if (Get-Command flutter -ErrorAction SilentlyContinue) {
    Write-Host "  Running flutter analyze (may take 30s)..."
    $analyzeOutput = cmd /c "flutter analyze --no-fatal-infos --no-fatal-warnings 2>&1"
    # Count error-level issues only. info/warning are non-fatal in CI
    # (which uses continue-on-error: true on this step).
    $errorLines = $analyzeOutput | Select-String -Pattern "^\s*error - " -CaseSensitive
    $infoCount  = ($analyzeOutput | Select-String -Pattern "^\s*info - "    -CaseSensitive).Count
    $warnCount  = ($analyzeOutput | Select-String -Pattern "^\s*warning - " -CaseSensitive).Count
    if ($errorLines.Count -gt 0) {
        Fail "flutter analyze found $($errorLines.Count) error-level issue(s):"
        $errorLines | Select-Object -First 10 | ForEach-Object { Write-Host "      $_" }
    } else {
        Pass "flutter analyze: 0 errors ($infoCount infos, $warnCount warnings -- non-fatal)"
    }
} else {
    Warn "flutter not on PATH -- skipping analyze"
}

# ---------------- 4. Pubspec asset paths exist ----------------
Section "Asset path sanity"

$missingAssets = @()
$assetLines = Select-String -Path pubspec.yaml -Pattern '^\s+-\s+(assets/[^\s]+|config/[^\s]+)$' -AllMatches
foreach ($m in $assetLines.Matches) {
    $p = $m.Groups[1].Value.TrimEnd('/')
    if (-not (Test-Path $p)) {
        $missingAssets += $p
        Fail "pubspec.yaml references missing asset path: $p"
    }
}
if ($missingAssets.Count -eq 0) {
    Pass "All pubspec asset paths exist"
}

# ---------------- 5. Vocab.dart integrity ----------------
Section "Vocab file integrity"

$vocab = Get-Content lib/data/awing_vocabulary.dart -Raw
$nulCount = ($vocab.ToCharArray() | Where-Object { [int]$_ -eq 0 }).Count
if ($nulCount -gt 0) {
    Fail "lib/data/awing_vocabulary.dart has $nulCount NUL bytes (truncated write)"
} else {
    Pass "vocab.dart has no NUL bytes"
}

$awingWordCount = ([regex]::Matches($vocab, 'AwingWord\(')).Count
if ($awingWordCount -lt 20000) {
    Warn "AwingWord count = $awingWordCount (expected ~21,330) -- vocab.dart may be truncated"
} else {
    Pass "AwingWord literals: $awingWordCount"
}

# Skip naive bracket count -- string literals contain glottal-stop
# apostrophes and parens which make this metric unreliable. The Dart
# analyzer above is the real syntactic gate.

# ---------------- 6. Local AAB smoke build ----------------
if (-not $SkipBuild) {
    Section "Local AAB smoke build"
    Write-Host "  flutter build appbundle --release (5-10 min)..."
    $buildOutput = cmd /c "flutter build appbundle --release 2>&1"
    $buildExit = $LASTEXITCODE
    if ($buildExit -ne 0) {
        Fail "flutter build appbundle FAILED locally -- CI will fail too. Last 30 lines:"
        $buildOutput | Select-Object -Last 30 | ForEach-Object { Write-Host "      $_" }
    } else {
        $aab = "build/app/outputs/bundle/release/app-release.aab"
        if (Test-Path $aab) {
            $sizeMB = [math]::Round((Get-Item $aab).Length / 1MB, 1)
            $sizeMsg = "AAB built ($sizeMB MB) -- CI should succeed"
            Pass $sizeMsg
        }
    }
} else {
    Section "Local AAB smoke build"
    Warn "Skipped (-SkipBuild). CI may still surface compilation errors."
}

# ---------------- 7. Tag plan ----------------
if ($Tag) {
    Section "Tag plan"
    $head = git rev-parse HEAD
    $plannedTag = "v$semver+$build"
    $existingTag = git tag --list $plannedTag
    if ($existingTag) {
        Fail "Tag $plannedTag already exists. Delete first: git tag -d $plannedTag"
    } else {
        Pass "Planned tag $plannedTag is unused"
    }
    Pass "Tag will point at HEAD = $($head.Substring(0,7))"
}

# ---------------- Summary ----------------
Section "Summary"
if ($failures.Count -eq 0) {
    Write-Host "[ALL CHECKS PASSED] safe to commit + push + tag" -ForegroundColor Green
    if ($warnings.Count -gt 0) {
        Write-Host "($($warnings.Count) warnings -- review above)" -ForegroundColor Yellow
    }
    exit 0
} else {
    Write-Host "[$($failures.Count) FAILURE(S)] DO NOT PUSH until fixed:" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
    exit 1
}
