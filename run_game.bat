@echo off
setlocal
where godot >nul 2>nul
if %errorlevel% neq 0 (
  echo Godot 4.x was not found on PATH.
  echo Install Godot 4.x and add it to PATH.
  pause
  exit /b 1
)
godot --editor --path "%~dp0"
if %errorlevel% neq 0 pause
