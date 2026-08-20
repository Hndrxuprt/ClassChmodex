@echo off
REM Daily launcher: download ClassCodex, then publish to GitHub if changed.
REM Called by Windows Task Scheduler at 12:00. Output is logged by date.

setlocal
set "SCRIPT_DIR=%~dp0"
set "PYTHON_EXE=%SCRIPT_DIR%..\..\..\..\..\..\AppData\Local\Programs\Python\Python310\python.exe"
if not exist "%PYTHON_EXE%" set "PYTHON_EXE=python.exe"

set "LOG_DIR=%SCRIPT_DIR%logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set "DATESTAMP=%%I"
set "LOGFILE=%LOG_DIR%\%DATESTAMP%.log"

echo.                                                    >> "%LOGFILE%"
echo ==================================================== >> "%LOGFILE%"
echo [%DATE% %TIME%] Starting ClassCodex daily run       >> "%LOGFILE%"
echo ==================================================== >> "%LOGFILE%"

"%PYTHON_EXE%" "%SCRIPT_DIR%download_classcodex.py"      >> "%LOGFILE%" 2>&1
set "DL_RC=%ERRORLEVEL%"

if "%DL_RC%"=="0" (
    echo [%DATE% %TIME%] Download OK, publishing to GitHub >> "%LOGFILE%"
    "%PYTHON_EXE%" "%SCRIPT_DIR%publish_to_github.py"    >> "%LOGFILE%" 2>&1
    set "PUB_RC=!ERRORLEVEL!"
) else (
    echo [%DATE% %TIME%] Download failed (rc %DL_RC%), skipping publish >> "%LOGFILE%"
    set "PUB_RC=skipped"
)

echo [%DATE% %TIME%] Done. download=%DL_RC% publish=%PUB_RC% >> "%LOGFILE%"
endlocal