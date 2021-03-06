@echo off
title Dual Boot Installer 0.3 by William Nichols
rem goto Format
echo Performing some checks...

rem Check if we are running on arm
if NOT "%PROCESSOR_ARCHITECTURE%"=="ARM" goto notARM

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
if "%1" == "-install" goto Install
if "%1" == "/install" goto Install

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
goto Shrink

:Shrink
echo list vol >diskpart.txt
diskpart /s diskpart.txt

echo Please select the volume that you want to shrink:
set /p voltoshrink=
echo Please tell me the amount (in MB) that you want to shrink by:
set /p amounttoshrink=
echo sel vol %voltoshrink% >diskpart.txt
echo shrink minimum=%amounttoshrink% >>diskpart.txt
diskpart /s diskpart.txt

if NOT %ERRORLEVEL% == 0 goto notShrink
echo Done shrinking
pause
goto shrinkcleanup

:notShrink
echo The shrink did not work. You can try again OR restart and run "shrink.bat" in the RE (recovery enviroment). What would you like to do?
echo [Y]es! Try again!
echo [N]o. Just quit.
echo [R]estart. Let me try running shrink.bat in the RE
choice /C YNR
if %ERRORLEVEL% == 1 goto Shrink
if %ERRORLEVEL% == 2 goto Exit
if %ERRORLEVEL% == 3 shutdown /r /o

:Exit
echo Do you want a new pagefile?
choice /C YN
if %ERRORLEVEL% == 2 goto Exitno
wmic pagefileset where name="C:\\pagefile.sys"
pause
:Exitno
exit

:shrinkcleanup
echo Do you want a new pagefile?
choice /C YN
if %ERRORLEVEL% == 2 goto Cleanupno
wmic pagefileset where name="C:\\pagefile.sys"
:Cleanupno
echo Excellent! You are done shrinking!
pause
goto Format

:Format
set c=0
:FormatPath
echo Please enter the path to your install.wim && echo. && echo For example: && echo. && echo If install.wim was at: && echo. && echo E:\sources\install.wim && echo. && echo you would type: && echo. && echo E:\sources\install.wim && echo.
set /p wimpath=
rem Check if we have our wim
IF NOT EXIST %wimpath% goto needwim
echo list disk >diskpart.txt
diskpart /s diskpart.txt

echo Please select the disk that you want to create a volume on:
set /p disktocreate=

echo sel disk %disktocreate% >diskpart.txt
echo create partition primary >>diskpart.txt
echo list part >>diskpart.txt
diskpart /s diskpart.txt
echo.
echo WARNING! Pay attention!
echo Format the empty partition (should be the one with the greatest offset).
echo Please select the partition that you want to format:
set /p parttoformat=

echo sel disk %disktocreate% >diskpart.txt
echo sel part %parttoformat% >>diskpart.txt
echo format fs=NTFS LABEL="Windows RT 8.0" QUICK >>diskpart.txt
diskpart /s diskpart.txt
echo. && echo.
echo Please enter a unused drive letter for Windows RT 8.0:
set /p drvletter=
echo sel disk %disktocreate% >diskpart.txt
pause
echo sel part %parttoformat% >>diskpart.txt
echo assign letter=%drvletter% >>diskpart.txt
diskpart /s diskpart.txt
if NOT %ERRORLEVEL% == 0 goto notdrv

:Deploy
Dism /apply-image /imagefile:%wimpath% /index:1 /ApplyDir:%drvletter%
pause
:notdrv
echo the drive letter is already in use
goto Exit

:Help
echo There is no extra command syntax everything is spelled out plain as day. Read the post at http://forum.xda-developers.com/windows-8-rt/rt-development/tools-windows-rt-expander-t3141824 to find out more.
echo Unless you are one of those people who wants to shrink it yourself, in which case run with the -install flag.
pause
exit

:notARM
cls
echo This is not intended to run on %PROCESSOR_ARCHITECTURE%. Please run this on a Windows RT device.
pause
exit

:notAdmin
set "batchPath=%~0"
setlocal EnableDelayedExpansion
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\OEgetPrivileges.vbs"
echo UAC.ShellExecute "!batchPath!", "ELEV", "", "runas", 1 >> "%temp%\OEgetPrivileges.vbs"
"%temp%\OEgetPrivileges.vbs"
exit /B
goto pathset

:needwim
set /A c=c+1
echo.
echo That path was incorrect please try again. %c%/3 attempts
echo.
if %c%==3 (goto needwimfail) else (goto FormatPath)
:needwimfail
echo.
echo We failed to find the wim sending you to the exit...
pause
goto Exit
