@echo off
setlocal EnableExtensions
set "ROOT=%~dp0.."
set "SETUP_DIR=%ROOT%\free-market\01_database_setup"
set "API_DIR=%ROOT%\free-market\02_api_architecture"

echo.
echo ============================================================
echo   Shipping System (free-market) - Start
echo ============================================================
echo.

rem ---- Validate API environment file ----
if not exist "%API_DIR%\.env" (
    echo [ERROR] Missing environment file:
    echo         %API_DIR%\.env
    echo.
    echo         Fix : copy "%API_DIR%\.env.example" "%API_DIR%\.env"
    echo.
    exit /b 1
)
echo [OK] API .env found

rem ---- Start PostgreSQL + Flask API via Docker Compose ----
echo [STEP 1/1] Starting PostgreSQL + Flask API ...
docker compose -f "%SETUP_DIR%\docker-compose.yml" up -d --build
if errorlevel 1 (
    echo [ERROR] Failed to start the shipping system via Docker Compose.
    exit /b 1
)

echo.
echo [SUCCESS] Shipping system is running.
echo   Shipping API : http://localhost:5000
echo   Health check : http://localhost:5000/health
echo   PostgreSQL   : localhost:5432
echo.
echo   Flutter apps : run  scripts\start-apps.bat  to launch the mobile UIs.
echo.
exit /b 0