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

echo ============================================
echo  Awing AI Learning - Build and Run (Windows)
echo ============================================
echo.

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

REM ---- Set PAD asset output directory ----
set "PAD_ASSETS=android\install_time_assets\src\main\assets"
if not exist "%PAD_ASSETS%\audio" mkdir "%PAD_ASSETS%\audio"
if not exist "%PAD_ASSETS%\images\vocabulary" mkdir "%PAD_ASSETS%\images\vocabulary"

REM ---- Step 2: Edge TTS Character Voices (6 voices, full generation) ----
REM Regenerates every audio clip for every voice. Awing-specific
REM pronunciation IS the point of the app — if this fails silently, the
REM APK ships with broken/stale audio and kids hear the wrong thing. The
REM flutter_tts fallback in the app is a crash guard, not a substitute.
REM So: abort the build if generation fails.
echo [2/7] Generating Edge TTS character voice clips (incremental)...
echo        6 voices: boy/girl (Beginner) + young_man/young_woman (Medium) + man/woman (Expert)
echo        Output: %PAD_ASSETS%\audio\
echo        Existing clips are SKIPPED. Pass --force-audio to regenerate everything.
REM SKIP_TTS=1 escape hatch — set the env var to ship a build without
REM regenerating any TTS clips. Useful when Microsoft's Edge TTS endpoint
REM is throttling/down and you need to release. Stale clips for new
REM vocabulary fall through to flutter_tts at runtime. Set with:
REM     $env:SKIP_TTS="1"  (PowerShell)  or  set SKIP_TTS=1  (cmd)
if defined SKIP_TTS (
    echo        SKIP_TTS=%SKIP_TTS% set — skipping Edge TTS generation.
    echo        Build will use existing audio clips on disk.
    goto :step2_done
)
REM Only do the destructive pre-clean if explicitly asked. The default is
REM incremental: generate_audio_edge.py skips files that already exist on
REM disk. This turns audio gen from a 1-2 hour full regen into a few
REM minutes for incremental changes (and ~10-15 min for full regen with
REM concurrency=8 inside the script).
if /I "%~1"=="--force-audio" call :clean_tts_audio
if /I "%~2"=="--force-audio" call :clean_tts_audio
pip install edge-tts --quiet 2>nul
python scripts\generate_audio_edge.py --output-dir "%PAD_ASSETS%\audio" generate
if !ERRORLEVEL! neq 0 (
    echo.
    echo        ERROR: Edge TTS generation failed. Build aborted.
    echo        Run 'python scripts\generate_audio_edge.py generate' manually
    echo        to see the full error. Common causes:
    echo          - edge-tts package not installed ^(pip install edge-tts^)
    echo          - No internet connection ^(Edge TTS needs Microsoft API^)
    echo          - ffmpeg missing ^(needed for per-syllable tonal concat^)
    echo.
    echo        WORKAROUND: To ship without regenerating audio:
    echo          PowerShell:   $env:SKIP_TTS="1"; .\scripts\build_and_run.bat
    echo          cmd.exe:      set SKIP_TTS=1 ^& scripts\build_and_run.bat
    exit /b 1
)
echo        Edge TTS clips generated.
:step2_done
echo.

REM ---- Step 3: Regenerate Pronunciation-Fixed Words (overwrites specific clips) ----
REM If developer approved pronunciation_fix contributions with
REM recorded audio, apply_contributions.py wrote regenerate_words.json
REM with Whisper transcriptions as speakable_override. This step
REM regenerates ONLY those words across all 6 voices using the
REM override. Abort on failure — approved pronunciation corrections
REM are explicit developer intent and should never be silently dropped.
echo [3/7] Checking for pronunciation fixes to regenerate...
if defined SKIP_TTS (
    echo        SKIP_TTS=%SKIP_TTS% set — skipping pronunciation regeneration too.
    goto :step3_done
)
REM Prefer regenerate_words_v2.json (Session 58 pattern-mine output) when present;
REM fall back to legacy regenerate_words.json (apply_contributions.py output).
set "REGEN_FILE="
if exist "contributions\regenerate_words_v2.json" set "REGEN_FILE=contributions\regenerate_words_v2.json"
if not defined REGEN_FILE if exist "contributions\regenerate_words.json" set "REGEN_FILE=contributions\regenerate_words.json"
if defined REGEN_FILE (
    echo        Found !REGEN_FILE! — regenerating specific words with corrected pronunciation...
    python scripts\generate_audio_edge.py --output-dir "%PAD_ASSETS%\audio" regenerate --regenerate-file "!REGEN_FILE!"
    if !ERRORLEVEL! neq 0 (
        echo.
        echo        ERROR: Pronunciation regeneration failed. Build aborted.
        echo        Approved pronunciation corrections were not applied.
        echo        Fix the error above and retry, or delete
        echo        '!REGEN_FILE!' to skip this step
        echo        ^(the corrections will be re-fetched on the next build^).
        exit /b 1
    )
    echo        Pronunciation fixes regenerated successfully.
) else (
    echo        No pronunciation fixes to regenerate. Skipping.
)
:step3_done
echo.

REM ---- Step 4: Vocabulary Images ----
REM New vocabulary entries need matching SDXL Turbo illustrations. If
REM this fails the new words render with placeholder icons instead of
REM kid-friendly cartoons — a regression in quality. Abort so the
REM failure gets fixed instead of papered over.
echo [4/7] Generating vocabulary images...
echo        Output: %PAD_ASSETS%\images\vocabulary\
python scripts\generate_images.py --output-dir "%PAD_ASSETS%\images\vocabulary" generate
if !ERRORLEVEL! neq 0 (
    echo.
    echo        ERROR: Image generation failed. Build aborted.
    echo        Run 'python scripts\generate_images.py generate' manually
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
echo [4b/7] Compressing audio (MP3 -> OPUS)...
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

:clean_tts_audio
REM Delete old TTS clips from PAD voice directories
set "PAD_AUDIO=%PAD_ASSETS%\audio"
for %%V in (boy girl young_man young_woman man woman) do (
    for %%C in (alphabet vocabulary sentences stories) do (
        powershell -NoProfile -Command "if (Test-Path '%PAD_AUDIO%\%%V\%%C\*.mp3') { Remove-Item '%PAD_AUDIO%\%%V\%%C\*.mp3' -Force }"
    )
)
goto :eof
