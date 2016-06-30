@echo off
title Dual Boot Installer 0.1 by William Nichols

:pathset
set batchpath=%~dp0

:admincheck
rem Cheap dirty way to check if we're admin
reg add HKLM\software\ICS /v amIAdmin /f >nul 2>nul
if %ERRORLEVEL% == 1 goto notAdmin
reg delete HKLM\software\ICS /v amIAdmin /f >nul 2>nul
:cmdoptionscheck
if "%1" == "-auto" goto Auto
if "%1" == "-startup" goto Startup
if "%1" == "-?" goto Help
if "%1" == "/?" goto Help

:Auto
manage-bde -protectors -disable c:
wmic pagefileset where name="C:\\pagefile.sys" delete
echo Creating Task Scheduler event to run on boot
schtasks /create /sc ONLOGON /tn Dualboot /tr "\"%~fp0\" -startup" /F /RL HIGHEST
%systemroot%\system32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -Command "Set-ScheduledTask -TaskName Dualboot -Settings (New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries)"
echo Task Scheduler event created. Restart?
pause
shutdown /r /t 0

:Startup
schtasks /delete /TN Dualboot /F
rem this will be a variable later
diskpart shrink minimum=13312
echo Done shrinking
pause
goto Cleanup

:Cleanup
echo What should your new pagefile size be?
set /p Pagefilesize=
wmic pagefileset where name="C:\pagefile.sys"

:notAdmin
setlocal DisableDelayedExpansion
set "batchPath=%~0"
setlocal EnableDelayedExpansion
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\OEgetPrivileges.vbs"
echo UAC.ShellExecute "!batchPath!", "ELEV", "", "runas", 1 >> "%temp%\OEgetPrivileges.vbs"
"%temp%\OEgetPrivileges.vbs"
exit /B
goto pathset
