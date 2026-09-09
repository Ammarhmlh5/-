@echo off
setlocal EnableExtensions
set "ROOT=%~dp0.."
set "SHIPPING_COMPOSE=%ROOT%\free-market\01_database_setup\docker-compose.yml"
set "MARKET_COMPOSE=%ROOT%\Manufacturers-market\database\docker-compose.yml"

echo.
echo ============================================================
echo   Free-Market Suite - Stop Everything / Shutdown
echo ============================================================
echo.

rem ---- Stop shipping system (DB + API containers) ----
echo [1/2] Stopping Shipping system ...
docker compose -f "%SHIPPING_COMPOSE%" down
if errorlevel 1 (
    echo [WARN] Shipping system stop reported an error - it may already be stopped.
)

rem ---- Stop market system (DB + API containers) ----
echo [2/2] Stopping Market system ...
docker compose -f "%MARKET_COMPOSE%" down
if errorlevel 1 (
    echo [WARN] Market system stop reported an error - it may already be stopped.
)

echo.
echo [DONE] All containers have been stopped.
echo.

rem ---- Offer cleanup of database volumes ----
echo Database data is preserved.
echo To FULLY remove databases too, run:
echo     docker compose -f "%SHIPPING_COMPOSE%" down -v
echo     docker compose -f "%MARKET_COMPOSE%" down -v
echo   WARNING: -v permanently deletes all database data.
echo.
exit /b 0