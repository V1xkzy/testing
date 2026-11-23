@echo off
start "" notepad.exe
timeout /t 2 /nobreak >nul
powershell -NoProfile -Command "$wshell = New-Object -ComObject WScript.Shell; $wshell.AppActivate('Notepad'); Start-Sleep -Milliseconds 500; $wshell.SendKeys('wsp buddy')"
