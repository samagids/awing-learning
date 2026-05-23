@echo off
REM ============================================================
REM  Awing Family Voice Recording Studio - one-click launcher
REM ============================================================
REM  Regenerates family_recorder.html from the current Dart data,
REM  serves the project root over HTTP on localhost:8765, and opens
REM  the recorder in your default browser.
REM
REM  The microphone API requires localhost (or HTTPS). Double-
REM  clicking the HTML file from File Explorer DOES NOT work.
REM  Use this script instead.
REM ============================================================
setlocal

cd /d "%~dp0\.."

echo.
echo === Rebuilding family_recorder.html from current Awing data ===
python scripts\build_family_recorder.py
if errorlevel 1 (
  echo.
  echo Build failed. See message above.
  pause
  exit /b 1
)

echo.
echo === Serving on http://localhost:8765 ===
echo Press Ctrl+C in this window when you are done recording.
echo.

start "" "http://localhost:8765/family_recorder.html"
python -m http.server 8765
