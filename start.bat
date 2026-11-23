@echo off
setlocal
cd /d "%~dp0"

start "" notepad.exe

rem stdin-independent wait
ping -n 3 127.0.0.1 >nul

set "VBS=%TEMP%\sk.vbs"
>  "%VBS%" echo Set s = CreateObject("WScript.Shell")
>> "%VBS%" echo s.AppActivate "Notepad"
>> "%VBS%" echo WScript.Sleep 600
>> "%VBS%" echo s.SendKeys "wsp buddy"
>> "%VBS%" echo WScript.Sleep 200

cscript //nologo "%VBS%"
if errorlevel 1 powershell -NoProfile -Command "$w=New-Object -ComObject WScript.Shell;$w.AppActivate('Notepad');Start-Sleep -m 600;$w.SendKeys('wsp buddy')"

del "%VBS%" >nul 2>&1
endlocal
