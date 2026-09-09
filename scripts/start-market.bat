@echo off
setlocal EnableExtensions
set "ROOT=%~dp0.."
set "COMPOSE_DIR=%ROOT%\Manufacturers-market\database"
set "SERVER_DIR=%ROOT%\Manufacturers-market\server"

echo.
echo ============================================================
echo   Market (Manufacturers-market) - Start
echo ============================================================
echo.

rem ---- Validate server environment file ----
if not exist "%SERVER_DIR%\.env" (
    echo [ERROR] Missing environment file:
    echo         %SERVER_DIR%\.env
    echo.
    echo   Fix : copy "%SERVER_DIR%\.env.example" "%SERVER_DIR%\.env"
    echo.
    exit /b 1
)
echo [OK] Server .env found

rem ---- Start marketplace PostgreSQL + FastAPI via Docker Compose ----
echo [STEP 1/1] Starting marketplace PostgreSQL + FastAPI ...
docker compose -f "%COMPOSE_DIR%\docker-compose.yml" up -d --build
if errorlevel 1 (
    echo [ERROR] Failed to start the market system via Docker Compose.
    exit /b 1
)

echo.
echo [SUCCESS] Market system is running.
echo   Market API     : http://localhost:8002
echo   Interactive API : http://localhost:8002/docs
echo   Health check    : http://localhost:8002/health
echo   PostgreSQL      : localhost:5543
echo.
echo   Run tests:  cd "%SERVER_DIR%" ^&^& python -m pytest tests -v
echo.
exit /b 0