@echo off
setlocal EnableExtensions

rem ============================================================
rem Lyrenthos launcher
rem Your Godot 4.7.2 installation is in:
rem C:\Users\shukl\Downloads\Compressed
rem ============================================================

set "GODOT_DIR=C:\Users\shukl\Downloads\Compressed"
set "GODOT_EXE=%GODOT_DIR%\Godot_v4.7.2-stable_win64.exe"
set "GODOT_CONSOLE=%GODOT_DIR%\Godot_v4.7.2-stable_win64_console.exe"

if exist "%GODOT_EXE%" goto launch
if exist "%GODOT_CONSOLE%" (
    set "GODOT_EXE=%GODOT_CONSOLE%"
    goto launch
)

where godot.exe >nul 2>nul
if %errorlevel%==0 (
    set "GODOT_EXE=godot.exe"
    goto launch
)

echo.
echo ============================================================
echo Lyrenthos could not find Godot 4.7.2.
echo Expected:
echo %GODOT_EXE%
echo.
echo Check that Godot_v4.7.2-stable_win64.exe is still in:
echo %GODOT_DIR%
echo ============================================================
echo.
pause
exit /b 1

:launch
echo Starting Lyrenthos...
"%GODOT_EXE%" --path "%~dp0"
if errorlevel 1 (
    echo.
    echo Lyrenthos exited with an error.
    pause
)
