@echo off
setlocal EnableExtensions
set "ROOT=%~dp0.."

echo.
echo ============================================================
echo   Flutter Apps (Mobile UIs) - Start China App
echo ============================================================
echo.

rem ---- Check Flutter SDK ----
where flutter >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Flutter SDK was not found on your PATH.
    echo         Install Flutter first and add "flutter" to PATH.
    exit /b 1
)

if not exist "%ROOT%\free-market\china_app" (
    echo [ERROR] Missing app folder: %ROOT%\free-market\china_app
    exit /b 1
)

echo [STEP 1/2] Fetching dependencies (flutter pub get) ...
pushd "%ROOT%\free-market\china_app"
flutter pub get
if errorlevel 1 (
    echo [ERROR] flutter pub get failed.
    popd
    exit /b 1
)
popd

echo [STEP 2/2] Launching China app ...
pushd "%ROOT%\free-market\china_app"
flutter run
set "RUN_EXIT=%ERRORLEVEL%"
popd

echo.
echo China app stopped (exit code %RUN_EXIT%).
echo.
echo   Yemen app can be started with:  scripts\start-apps.bat  choosing yemen
echo   or run manually:  cd free-market\yemen_app ^&^& flutter run
echo.
exit /b 0