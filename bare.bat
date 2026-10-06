@echo off
net session >nul 2>&1
if %errorlevel% neq 0 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
if exist "%~dp0bare.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0bare.ps1"
  exit /b
)
echo bare.ps1 was not next to this bat.
echo Download the repo, or run bare.ps1 from the same folder.
pause
