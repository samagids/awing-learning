@echo off
REM build_and_run.bat v16.0.0
REM Fail-fast: every critical step aborts the build if it fails. Shipping a
REM half-built APK with stale Dart data, missing audio, missing images, or
REM an unverified webhook is worse than not shipping — so each step either
REM completes or we stop cold with an error message that names the fix.
REM
REM 0. Deploy Apps Script webhooks (analytics + contributions) via clasp
REM    and VERIFY the deployed contributions URL supports fetch_all.
REM    setup_and_deploy.py --webhooks updates the EXISTING deployment in
REM    place (same URL), so already-installed APKs keep working. Aborts if
REM    clasp is present and deploy or verify fails.
REM 1. Apply approved contributions (modify Dart data files) — aborts on
REM    failure so we never build from a partially-edited lib/data state.
REM 2. Generate Edge TTS 6 character voices (full generation) — aborts on
REM    failure so the APK never ships with stale/missing audio.
REM 3. Regenerate pronunciation-fixed words (Edge TTS overwrites) — aborts
REM    on failure so approved pronunciation corrections actually ship.
REM 4. Generate vocabulary images (SDXL Turbo local GPU) — aborts on
REM    failure so new vocabulary never ships with placeholder icons.
REM 5. Install Flutter dependencies — aborts on failure.
REM 6. Build Flutter AAB + APK for Android — aborts on failure.
REM 7. Install on device + launch — not fatal (device may be disconnected).
REM
REM NOTE: Large assets (audio + images) are stored in android\install_time_assets\
REM       for Play Asset Delivery. Base AAB stays under 150 MB Play Store limit.

setlocal enabledelayedexpansion

REM Play Asset Delivery output root. Defined HERE, before anything can use
REM it. It used to be set ~230 lines down, which made `--purge-tts` a
REM silent no-op: %PAD_ASSETS% was empty, every path collapsed to
REM "\audio\boy", nothing existed, and the purge cheerfully reported
REM "already absent" for all six voices while 15,488 clips sat untouched.
set "PAD_ASSETS=android\install_time_assets\src\main\assets"

echo ============================================
echo  Awing AI Learning - Build and Run (Windows)
echo ============================================
echo.

REM ============================================================
REM   Step 0a: keep build output OUT of OneDrive
REM ============================================================
REM The repo lives in OneDrive and stays there. OneDrive's Files
REM On-Demand turns freshly written large files into cloud placeholders,
REM and a placeholder is an NTFS reparse point, which Java refuses to
REM snapshot. Observed 2026-09-28: bundleRelease SUCCEEDED, then
REM assembleRelease died with
REM     ':app:mergeReleaseNativeLibs' ... java.io.IOException:
REM     Cannot snapshot ...\libcactus.so: not a regular file
REM because OneDrive re-attributed the .so files the AAB step had just
REM written (ctime was two minutes later than mtime).
REM
REM Only the build OUTPUT has to leave sync. ensure_local_build_dirs.ps1
REM makes build\, .dart_tool\ and android\.gradle\ junctions to local
REM disk (default C:\dev\awing-build, override with AWING_BUILD_ROOT).
REM Idempotent: first run converts, later runs just verify.
REM
REM This runs BEFORE the fast-path jump on purpose — --fast still builds,
REM so it still needs the redirect.
REM
REM android\.gradle is EXCLUDED. Junctioning it made Gradle fail at
REM startup, every time, in 2 seconds:
REM     Could not create service of type OutputFilesRepository ...
REM     java.io.IOException: Cannot delete file:
REM       ...\android\.gradle\buildOutputCleanup\buildOutputCleanup.lock
REM Gradle rebuilds buildOutputCleanup on startup and could not delete its
REM own lock file through the junction. Not worth chasing: only build\
REM ever needed to leave OneDrive — that is where the 1 GB of native libs
REM lives and where mergeReleaseNativeLibs died. android\.gradle is tens
REM of MB, too small for OneDrive to bother dehydrating.
echo [0a/7] Ensuring build output lives outside OneDrive...
where powershell >nul 2>nul
if !ERRORLEVEL! neq 0 (
    echo        powershell not found - SKIPPING the OneDrive redirect.
    echo        If the build dies in mergeReleaseNativeLibs with
    echo        "not a regular file", this is why.
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ensure_local_build_dirs.ps1" -Exclude "android\.gradle"
    if !ERRORLEVEL! neq 0 (
        echo.
        echo        ERROR: could not redirect the build directories.
        echo        Stopping rather than building into a tree OneDrive
        echo        will dehydrate mid-build. Fix the error above, or set
        echo        AWING_BUILD_ROOT to a writable local path, then re-run.
        exit /b 1
    )
)
echo.

REM ============================================================
REM   --purge-tts : one-shot removal of the synthetic voices
REM ============================================================
REM Deliberately a separate, explicit invocation rather than something the
REM normal build does. Deleting 15,488 generated files is not a thing a
REM build should do as a side effect, and regenerating them is a 10-15
REM minute network job.
if /I "%~1"=="--purge-tts" (
    call :purge_tts_voices
    exit /b 0
)

REM ============================================================
REM   Synthetic-audio guard - runs in FAST mode too
REM ============================================================
REM Deliberately ABOVE the fast-path jump. --fast skips steps 0-4,
REM which is where this check used to live, so a fast build could
REM silently re-ship ~1 GB of Edge TTS and nobody would notice: the
REM app would just start making sound again.
REM Fail the build if a synthetic voice directory reappears in the asset
REM pack. Without this check a stray `generate_audio_edge.py` run, or an
REM old directory left behind on one machine, silently re-ships ~1 GB of
REM TTS and undoes the whole change - and nobody would notice, because
REM the app would simply start playing audio again.
set "TTS_FOUND="
for %%V in (boy girl young_man young_woman man woman bible_trained) do (
    if exist "%PAD_ASSETS%\audio\%%V" set "TTS_FOUND=!TTS_FOUND! %%V"
)
if defined TTS_FOUND (
    echo.
    echo        ERROR: synthetic voice directories are still present:
    echo             !TTS_FOUND!
    echo        under %PAD_ASSETS%\audio\
    echo.
    echo        v1.24.0 ships human recordings only. Move or delete those
    echo        directories, then re-run. Keep native, native_kids and
    echo        community - those are real people.
    echo.
    exit /b 1
)
echo        Verified: no synthetic voice directories in the asset pack.

REM ============================================================
REM   FAST PATH — Skip content gen when only Dart code changed
REM ============================================================
REM If the user sets AWING_FAST=1 (env var) or passes --fast as arg 1,
REM we skip steps 0-4 entirely and go straight to flutter pub get +
REM build. Use this when you've only edited Dart files (UI, refactor,
REM bugfix) and no vocabulary/sentences/images need regen.
REM Total time: ~30-60 seconds instead of hours.
set "FAST_MODE="
if /I "%~1"=="--fast" set "FAST_MODE=1"
if /I "%AWING_FAST%"=="1" set "FAST_MODE=1"
if defined FAST_MODE (
    echo *** FAST MODE: skipping webhook deploy, contributions,
    echo *** audio gen, and image gen. Going straight to flutter build.
    echo *** Use this only when no vocabulary/sentences/images changed.
    echo.
    goto :step5
)

REM ---- Step 0: Deploy Apps Script Webhooks ----
REM Pushes scripts\contributions_webapp.gs + scripts\analytics_webapp.gs to
REM Google Apps Script via clasp and updates the EXISTING deployment in
REM place (preserving the URL compiled into every shipped APK). Then
REM verifies the deployed contributions URL actually supports fetch_all.
REM If clasp is missing we skip (offline builds), but if it is present and
REM either deploy or verify fails, the whole build stops so we don't ship
REM an APK that points at a stale webhook.
echo [0/7] Deploying and verifying Apps Script webhooks...
where clasp >nul 2>nul
if !ERRORLEVEL! neq 0 (
    echo        clasp not found - skipping webhook deploy.
    echo        To enable: npm install -g @google/clasp ^&^& clasp login
    goto :step1
)
if not exist "scripts\setup_and_deploy.py" (
    echo        scripts\setup_and_deploy.py not found - skipping.
    goto :step1
)

REM Step 0a: deploy (push .gs, update existing deployment in place,
REM          update webhooks.json deployed_at timestamp).
python scripts\setup_and_deploy.py --webhooks
if !ERRORLEVEL! neq 0 (
    echo.
    echo        ERROR: Webhook deploy failed. Build aborted.
    echo        Run 'python scripts\setup_and_deploy.py --webhooks' manually,
    echo        fix any errors above, then retry this script.
    exit /b 1
)

REM Step 0b: verify the deployed URL supports the fetch_all action that the
REM Dev Mode Review tab relies on. Stale deployments will fail here.
python scripts\setup_and_deploy.py --verify
if !ERRORLEVEL! neq 0 (
    echo.
    echo        ERROR: Webhook verify failed. Build aborted.
    echo        The deployed contributions URL is missing fetch_all support.
    echo        Re-run 'python scripts\setup_and_deploy.py --webhooks' or paste
    echo        a fresh deployment URL into config\webhooks.json manually.
    exit /b 1
)
echo        Webhooks deployed and verified.

:step1
echo.

REM ---- Step 0c: Sync in-app version constants from pubspec.yaml ----
REM v1.24.2 (Session 66p): build_and_run.sh has run sync_version.py at
REM [0b/8] since v1.18.1, but this .bat never did -- and the .bat is what
REM actually gets run on Windows. So the two drifted silently: v1.24.1+145
REM shipped with about_screen.dart and analytics_service.dart still saying
REM 1.24.0, which means the About page lied and every analytics event from
REM that release is attributed to the wrong version.
REM
REM Idempotent: rewrites about_screen.dart, analytics_service.dart and
REM cloud_backup_service.dart only when they disagree with pubspec.yaml.
REM Non-fatal -- a stale version string is bad, but not worth killing a
REM build over, and the next line of output says exactly what it did.
echo [0c/7] Syncing in-app version constants from pubspec.yaml...
python scripts\sync_version.py
if !ERRORLEVEL! neq 0 (
    echo        WARNING: sync_version.py failed - in-app version strings may
    echo        be stale. Continuing.
)
echo.

REM ---- Step 1: Apply Approved Contributions ----
REM Applies any approved contributions (spelling fixes, new words,
REM pronunciation overrides) to lib\data\*.dart files. If this fails we
REM abort — a half-applied contribution leaves the Dart data in an
REM inconsistent state (e.g. new word added to one category but not
REM registered in allVocabulary), and building from that state would ship
REM broken content.
echo [1/7] Applying approved contributions...
if not exist "contributions" mkdir contributions
if not exist "contributions\applied" mkdir "contributions\applied"
python scripts\apply_contributions.py
if !ERRORLEVEL! neq 0 (
    echo.
    echo        ERROR: Contribution application failed. Build aborted.
    echo        Run 'python scripts\apply_contributions.py' manually to see
    echo        the full error. Common causes:
    echo          - Network issue fetching approved contributions from webhook
    echo          - Malformed JSON in contributions\approved_contributions.json
    echo          - Dart file parse failure in lib\data\*.dart
    exit /b 1
)
echo        Contributions applied successfully.
echo.

REM ---- Step 1a: Build image manifest ----
REM Scans the PAD assets/images/vocabulary/ directory and writes
REM assets/image_manifest.json, which the Flutter app loads at startup
REM so games / quizzes / exams can synchronously filter their vocab
REM selection to entries with a bundled illustration (no green
REM placeholder fallback at runtime). Cheap, always safe to re-run.
echo [1a/7] Building image manifest...
python scripts\build_image_manifest.py
if !ERRORLEVEL! neq 0 (
    echo        WARNING: build_image_manifest.py failed.
    echo        The app will fall back to "show all words" which means
    echo        some game rounds may show empty image placeholders.
)
echo.

REM ---- Step 1b: Sync native recordings from webhook ----
REM Pulls every "Native recording" tagged audio uploaded via the new Dev
REM Mode Record tab (Session 61b family-recorder-style UI) into
REM training_data/recordings/ as WAV files + manifest entries. Then
REM apply_recordings_as_audio.py (Step 1c) copies them into the PAD pack.
REM Non-fatal: if there are no native recordings to sync, the script
REM exits cleanly and the build continues with Edge TTS only.
echo [1b/7] Syncing native recordings from contributors...
python scripts\sync_recordings.py
if !ERRORLEVEL! neq 0 (
    echo        WARNING: sync_recordings.py failed.
    echo        The build will continue — TTS will fill in for missing native
    echo        audio. Common causes:
    echo          - SCRIPT_SECRET not configured (env var, config/webhooks.json,
    echo            or ~/.awing_script_secret)
    echo          - ffmpeg not on PATH
    echo          - Network issue reaching the webhook
    echo.
)
echo.

REM ---- Step 1c: Apply recordings as native audio assets ----
REM Reads training_data/recordings/manifest.json and copies each WAV to
REM android/install_time_assets/src/main/assets/audio/native/<category>/
REM <key>.mp3 via ffmpeg conversion. The Flutter app's PronunciationService
REM prefers the native/ tier over the 6 Edge TTS voices.
echo [1c/7] Applying recordings as native audio assets...
if exist "training_data\recordings\manifest.json" (
    python scripts\apply_recordings_as_audio.py
    if !ERRORLEVEL! neq 0 (
        echo        WARNING: apply_recordings_as_audio.py failed.
        echo        Build continues with TTS-only audio for the affected words.
    )
) else (
    echo        No manifest.json yet — skipping. (Run the Dev Mode Record tab
    echo        on a tablet first, or place recordings in training_data\recordings\)
)
echo.

REM ---- Step 1d: Build native audio inventory manifest ----
REM Scans audio/native/ + audio/native_kids/<slug>/ and emits
REM assets/native_audio_manifest.json — a small JSON the Flutter app
REM bundles in the main APK (NOT the PAD pack, so it's available at
REM startup before any PAD download). The Dev Mode Record tab uses it
REM to show per-item badges for which recorders have a clip + power the
REM "Missing from [active recorder]" filter so the dev can find words
REM the current picker target hasn't covered yet.
REM Non-fatal: stale manifest just dulls in-app status badges; doesn't
REM affect playback or distribution.
echo [1d/7] Building native audio inventory manifest...
python scripts\build_native_audio_manifest.py --quiet
if !ERRORLEVEL! neq 0 (
    echo        WARNING: native audio manifest build failed.
    echo        Record tab status badges will be stale until next build.
)
echo.

REM ---- PAD asset output directory (defined at the top of the script) ----
if not exist "%PAD_ASSETS%\audio" mkdir "%PAD_ASSETS%\audio"
if not exist "%PAD_ASSETS%\images\vocabulary" mkdir "%PAD_ASSETS%\images\vocabulary"

REM ---- Step 2: synthetic audio is GONE (v1.24.0) ----
REM NACDA DMV feedback: no AI pronunciation. A Swahili neural voice
REM cannot produce Awing tone, so Edge TTS was teaching children a
REM confidently wrong pronunciation for the ~95%% of the dictionary with
REM no human recording. The app now plays recordings only
REM (pronunciation_service._buildSearchPaths) and offers a Record button
REM where there is nothing to play (AwingAudioButton).
REM
REM What used to be here:
REM   [2/7] generate_audio_edge.py  -> 15,488 clips across 6 character
REM         voices (boy, girl, young_man, young_woman, man, woman)
REM   [3/7] the same script in `regenerate` mode for approved
REM         pronunciation_fix contributions
REM Both deleted. scripts/generate_audio_edge.py is left on disk and in
REM git history so the decision is reversible, but nothing calls it.
REM
REM A pronunciation_fix contribution is now applied by shipping the
REM CONTRIBUTOR'S OWN recording (audio/community/), which is what the
REM correction actually was - re-synthesising it was always a step
REM backwards.
echo [2/7] Audio: native recordings only ^(no synthetic voices^).


REM Report what IS shipping, so a build that accidentally loses the
REM native recordings is visible rather than silently quiet.
if exist "%PAD_ASSETS%\audio\native" (
    echo        native/ present - human recordings will ship.
) else (
    echo        WARNING: no native/ directory. The app will be SILENT for
    echo        every word. That is probably not what you want.
)
:step3_done
echo.

REM ---- Step 4: Vocabulary Images ----
REM New vocabulary entries need matching SDXL Turbo illustrations. If
REM this fails the new words render with placeholder icons instead of
REM kid-friendly cartoons — a regression in quality. Abort so the
REM failure gets fixed instead of papered over.
REM
REM --format webp IS NOT OPTIONAL. The generator defaults to PNG, and
REM _save_image() DELETES the sibling file in the other format after a
REM successful write. So a plain `generate` here does not merely add PNGs:
REM it converts the entire pack back to PNG and deletes the WebP, taking
REM the asset pack from 137.7 MB to roughly 700 MB. This line shipped
REM without the flag and started doing exactly that on the first v1.24.0
REM build; the run had to be killed by hand at ~150 images.
REM
REM The flag must match whatever format the pack is currently in. If that
REM ever changes, change it here too.
echo [4/7] Generating vocabulary images ^(WebP^)...
echo        Output: %PAD_ASSETS%\images\vocabulary\
python scripts\generate_images.py --output-dir "%PAD_ASSETS%\images\vocabulary" generate --format webp
if !ERRORLEVEL! neq 0 (
    echo.
    echo        ERROR: Image generation failed. Build aborted.
    echo        Run 'python scripts\generate_images.py generate --format webp' manually
    echo        to see the full error. Common causes:
    echo          - diffusers/transformers/accelerate not installed
    echo          - No NVIDIA GPU with CUDA support
    echo          - SDXL Turbo model not yet downloaded ^(~5 GB^)
    exit /b 1
)
echo        Vocabulary images generated.
echo.

REM ---- Step 4b: Asset diet (MP3 -> OPUS) ----
REM v1.17.1+ — Edge TTS and apply_recordings_as_audio.py still write
REM MP3 because that's what ffmpeg / edge-tts emit natively. We then
REM transcode the whole PAD audio tree to OPUS @ 32k mono voip before
REM the AAB is built. OPUS files are ~50%% smaller; pronunciation_service
REM .dart loads .opus directly. Skipping already-converted files keeps
REM this fast (~3s on a warm pack, ~90s on a cold pack with 18k MP3s).
echo [4b/7] Compressing audio ^(MP3 -^> OPUS^)...
python scripts\cleanup_assets.py --tier 2
if !ERRORLEVEL! neq 0 (
    echo        WARNING: audio compression had errors. Continuing with mixed pack.
    echo        Check ffmpeg is on PATH ^(winget install Gyan.FFmpeg^).
)
echo.

REM ---- Step 5: Flutter Deps ----
REM pub get MUST succeed before build. Abort otherwise — there's no
REM useful downstream work without resolved dependencies.
:step5
echo [5/7] Installing Flutter dependencies...
call flutter pub get
if !ERRORLEVEL! neq 0 (
    echo.
    echo        ERROR: flutter pub get failed. Build aborted.
    echo        Check pubspec.yaml and your Flutter install ^(flutter doctor^).
    exit /b 1
)
echo        Flutter dependencies resolved.
echo.

REM ---- Step 5b: Dart analyze (fast fail on truncations) ----
REM ~10-second guard against the recurring Edit-tool truncation pattern
REM (Sessions 49c / 60 / 61+ documented). Catches mid-string truncations,
REM unbalanced braces, and missing identifiers BEFORE Gradle wastes
REM 60+ seconds compiling the same broken file. Errors-only -- info
REM hints and lint warnings are non-fatal so build doesn't regress
REM over stylistic noise.
echo [5b/7] Pre-build Dart analyze (fast truncation guard)...
call flutter analyze --no-fatal-infos --no-fatal-warnings
if !ERRORLEVEL! neq 0 (
    echo.
    echo        ERROR: flutter analyze found errors. Build aborted.
    echo        Usually a file truncation in lib\ ^(edit-tool dropped
    echo        trailing bytes^). Check the error location above.
    echo        Common recovery: open the named file and look for an
    echo        unterminated string, missing closing brace, or mid-
    echo        method cutoff at EOF.
    exit /b 1
)
echo        Dart analyze clean.
echo.

REM ---- Step 6: Build AAB + APK ----
echo [6/7] Building Android App Bundle (release)...
call flutter build appbundle --release
if !ERRORLEVEL! neq 0 (
    echo        WARNING: AAB build failed. Trying APK instead...
    call flutter build apk --release
    if !ERRORLEVEL! neq 0 (
        echo.
        echo        ERROR: Android build failed ^(both AAB and APK^). Build aborted.
        echo        Check the Flutter/Gradle output above. Common causes:
        echo          - Signing keystore missing or misconfigured
        echo          - Android SDK / NDK version mismatch
        echo          - Dart compile errors in lib\
        exit /b 1
    )
)
echo        Also building APK for local testing...
call flutter build apk --release
if !ERRORLEVEL! neq 0 (
    echo.
    echo        ERROR: APK build failed. Build aborted.
    echo        ^(AAB already built, but the local testing APK is missing.^)
    exit /b 1
)
echo        AAB + APK built successfully.
echo.

REM ---- Step 7: Install on Device ----
REM Install is best-effort — a disconnected device is a normal dev
REM state, not a build failure. Report the result but do not abort.
echo [7/7] Installing on connected device...
if exist "scripts\setup_and_deploy.py" (
    python scripts\setup_and_deploy.py --install
) else (
    call flutter run
)

echo.
echo ============================================
echo  Build and run completed!
echo ============================================
pause
goto :eof

:purge_tts_voices
REM v1.24.0 one-shot: remove the six synthetic character-voice directories
REM from the asset pack. Run as:  scripts\build_and_run.bat --purge-tts
REM
REM This REPLACED :clean_tts_audio, which was also broken: it only deleted
REM '*.mp3' from each voice/category folder, but step 4b converts
REM everything to .opus, so it had been deleting nothing for releases.
REM
REM Only the six synthetic voices are touched. native, native_kids and
REM community are recordings of real people and are never listed here.
set "PAD_AUDIO=%PAD_ASSETS%\audio"
echo.
echo  Removing synthetic character-voice directories from the asset pack.
echo  Keeping native, native_kids and community - those are real people.
echo.
for %%V in (boy girl young_man young_woman man woman bible_trained) do (
    if exist "%PAD_AUDIO%\%%V" (
        echo    removing %%V ...
        rd /s /q "%PAD_AUDIO%\%%V"
        if exist "%PAD_AUDIO%\%%V" (
            echo    ERROR: could not remove %%V - close anything holding it, then retry.
        ) else (
            echo    %%V removed.
        )
    ) else (
        echo    %%V: already absent.
    )
)
echo.
echo  Remaining under audio\:
dir /b "%PAD_AUDIO%" 2>nul

REM Invalidate Gradle's recorded state for the asset-pack task.
REM
REM Removing ~16,000 files from the asset pack leaves
REM :app:assetPackReleasePreBundleTask holding an incremental snapshot that
REM describes a directory tree which no longer exists, and the next build
REM dies with
REM     java.nio.file.AccessDeniedException:
REM       ...\intermediates\asset_pack_bundle\release\
REM       assetPackReleasePreBundleTask\install_time_assets
REM (it took mergeReleaseNativeLibs down with it). Verified NOT a stale
REM daemon - Get-Process java came back empty, and gradle.properties sets
REM org.gradle.daemon=false anyway.
REM
REM THE SAME APPLIES TO ANY BULK ASSET CHANGE, so remember this before
REM regenerating the 9,086 images.
echo.
echo  Clearing Gradle's asset-pack state so the next build does not trip
echo  over a snapshot of the files just removed...
for %%D in (asset_pack_bundle merged_native_libs) do (
    if exist "build\app\intermediates\%%D" (
        rd /s /q "build\app\intermediates\%%D"
        echo    cleared intermediates\%%D
    ) else (
        echo    intermediates\%%D: not present
    )
)
echo.
echo  Done. Re-run scripts\build_and_run.bat to build without them.
echo  To get them back you would have to re-run
echo  scripts\generate_audio_edge.py, which takes 10-15 minutes and needs
echo  Microsoft's Edge TTS endpoint.
goto :eof
