@echo off
setlocal EnableExtensions
set "SHIPPING=1"
set "MARKET=1"

echo.
echo ============================================================
echo   Free-Market Suite - Start Everything
echo ============================================================
echo.

rem ---- Optional: skip a system by passing a parameter ----
if /i "%~1"=="--shipping-only" set "MARKET=0"
if /i "%~1"=="--market-only"    set "SHIPPING=0"

if "%SHIPPING%"=="1" (
    echo.
    echo ============================================================
    echo   [1/2] Shipping System (free-market)
    echo ============================================================
    call "%~dp0start-shipping.bat"
    if errorlevel 1 (
        echo [ERROR] Shipping system failed to start.
        set "SHIPPING=FAIL"
    )
)

if "%MARKET%"=="1" (
    echo.
    echo ============================================================
    echo   [2/2] Market (Manufacturers-market)
    echo ============================================================
    call "%~dp0start-market.bat"
    if errorlevel 1 (
        echo [ERROR] Market system failed to start.
        set "MARKET=FAIL"
    )
)

echo.
echo ============================================================
echo   Summary
echo ============================================================
if not "%SHIPPING%"=="FAIL" (
    echo   [OK] Shipping API   : http://localhost:5000
) else (
    echo   [FAILED] Shipping API   : http://localhost:5000
)
if not "%MARKET%"=="FAIL" (
    echo   [OK] Market API     : http://localhost:8002
) else (
    echo   [FAILED] Market API     : http://localhost:8002
)
echo.
echo   All services are running.
echo   To stop everything:  scripts\stop-all.bat
echo.
exit /b 0