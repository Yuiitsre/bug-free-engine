@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Lyrenthos Debug Launcher

set "HERE=%~dp0"
set "GODOT_DIR=C:\Users\shukl\Downloads\Compressed"
set "GODOT_EXE=%GODOT_DIR%\Godot_v4.7.2-stable_win64_console.exe"

set "PROJECT_DIR="
for /f "delims=" %%F in ('dir /b /s "%HERE%project.godot" 2^>nul') do (
    if not defined PROJECT_DIR set "PROJECT_DIR=%%~dpF"
)

if not defined PROJECT_DIR (
    echo [ERROR] project.godot not found.
    pause
    exit /b 1
)

if not exist "%GODOT_EXE%" (
    echo [ERROR] Console Godot build not found:
    echo %GODOT_EXE%
    pause
    exit /b 1
)

if not exist "%PROJECT_DIR%.venv\Scripts\python.exe" (
    py -3 "%PROJECT_DIR%tools\bootstrap.py" --project-root "%PROJECT_DIR%" --setup
    if errorlevel 1 pause & exit /b 1
)

"%PROJECT_DIR%.venv\Scripts\python.exe" "%PROJECT_DIR%tools\bootstrap.py" --project-root "%PROJECT_DIR%" --build
if errorlevel 1 pause & exit /b 1

echo.
echo ============================================================
echo Starting Lyrenthos in DEBUG mode
echo Project: %PROJECT_DIR%
echo ============================================================
echo.

"%GODOT_EXE%" --path "%PROJECT_DIR%"

echo.
echo ============================================================
echo Godot closed. Exit code: %errorlevel%
echo ============================================================
pause
