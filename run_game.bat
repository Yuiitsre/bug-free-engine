@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Lyrenthos Launcher

rem ============================================================
rem LYRENTHOS — Windows launcher
rem Fixes GitHub ZIP / nested-folder project layouts.
rem Automatically prepares the Python toolchain, generates
rem data, validates the project, then launches Godot.
rem ============================================================

set "HERE=%~dp0"
set "GODOT_DIR=C:\Users\shukl\Downloads\Compressed"

echo.
echo ============================================================
echo                  LYRENTHOS
echo             Phase 1 - Insular Genesis
echo ============================================================
echo.

rem ------------------------------------------------------------
rem 1. Find the actual Godot project root.
rem ------------------------------------------------------------
set "PROJECT_DIR="
for /f "delims=" %%F in ('dir /b /s "%HERE%project.godot" 2^>nul') do (
    if not defined PROJECT_DIR (
        set "PROJECT_DIR=%%~dpF"
    )
)

if not defined PROJECT_DIR (
    echo [ERROR] project.godot was not found under:
    echo %HERE%
    echo.
    echo Make sure you extracted the complete GitHub repository.
    echo.
    pause
    exit /b 1
)

if "!PROJECT_DIR:~-1!"=="\" set "PROJECT_DIR=!PROJECT_DIR:~0,-1!"
echo [OK] Project:
echo      !PROJECT_DIR!
echo.

rem ------------------------------------------------------------
rem 2. Find Godot 4.7.2.
rem ------------------------------------------------------------
set "GODOT_EXE="

if exist "%GODOT_DIR%\Godot_v4.7.2-stable_win64.exe" (
    set "GODOT_EXE=%GODOT_DIR%\Godot_v4.7.2-stable_win64.exe"
    goto :godot_found
)

if exist "%GODOT_DIR%\Godot_v4.7.2-stable_win64_console.exe" (
    set "GODOT_EXE=%GODOT_DIR%\Godot_v4.7.2-stable_win64_console.exe"
    goto :godot_found
)

for /f "delims=" %%F in ('where godot.exe 2^>nul') do (
    if not defined GODOT_EXE set "GODOT_EXE=%%F"
)

if not defined GODOT_EXE (
    echo [ERROR] Godot 4.x was not found.
    echo Expected:
    echo %GODOT_DIR%\Godot_v4.7.2-stable_win64.exe
    echo.
    pause
    exit /b 1
)

:godot_found
echo [OK] Godot:
echo      !GODOT_EXE!
echo.

rem ------------------------------------------------------------
rem 3. Find Python 3.
rem ------------------------------------------------------------
set "PYTHON_SYS="

where py.exe >nul 2>nul
if %errorlevel%==0 set "PYTHON_SYS=py -3"

if not defined PYTHON_SYS (
    where python.exe >nul 2>nul
    if %errorlevel%==0 set "PYTHON_SYS=python"
)

if not defined PYTHON_SYS (
    echo [ERROR] Python 3 was not found.
    echo Install Python 3.10+ and run this file again.
    echo.
    pause
    exit /b 1
)

echo [OK] Python:
echo      !PYTHON_SYS!
echo.

rem ------------------------------------------------------------
rem 4. Create/update local Python environment and dependencies.
rem ------------------------------------------------------------
echo [1/2] Preparing Python tools...
%PYTHON_SYS% "!PROJECT_DIR!\tools\bootstrap.py" --project-root "!PROJECT_DIR!" --setup
if errorlevel 1 (
    echo.
    echo [ERROR] Python environment setup failed.
    echo.
    pause
    exit /b 1
)

set "VENV_PY=!PROJECT_DIR!\.venv\Scripts\python.exe"

if not exist "!VENV_PY!" (
    echo [ERROR] Python virtual environment was not created.
    pause
    exit /b 1
)

echo.
echo [2/2] Generating and validating Phase 1 data...
"!VENV_PY!" "!PROJECT_DIR!\tools\bootstrap.py" --project-root "!PROJECT_DIR!" --build
if errorlevel 1 (
    echo.
    echo [ERROR] Phase 1 validation/generation failed.
    echo.
    pause
    exit /b 1
)

rem ------------------------------------------------------------
rem 5. Launch the game directly.
rem ------------------------------------------------------------
echo.
echo Starting Lyrenthos...
echo Project: !PROJECT_DIR!
echo.

"!GODOT_EXE!" --path "!PROJECT_DIR!" --editor-pid 0

if errorlevel 1 (
    echo.
    echo ============================================================
    echo Lyrenthos exited with an error.
    echo ============================================================
    echo.
    pause
)

endlocal
