@echo off
:: SCRIPT SETTINGS -----------------------------------------------------

:: Configuration file (must be in CSV format)
set configFile=BlackViper.txt
:: Backup as registry file (yes|no)
set backupAsReg=yes
:: Runs without apply changes (yes|no)
set dryRun=yes
:: Services that cannot be disabled (will be skipped)
set skipped=AppIDSvc AppXSvc BFE BrokerInfrastructure ClipSVC CoreMessagingRegistrar DcomLaunch Dnscache embeddedmode EntAppSvc gpsvc msiserver NgcCtnrSvc NgcSvc RpcEptMapper RpcSs Schedule SecurityHealthService SgrmBroker sppsvc sppsvc StateRepository SystemEventsBroker TimeBrokerSvc UsoSvc UsoSvc WaaSMedicSvc WinHttpAutoProxySvc wscsvc wscsvc wuauserv xbgm

::----------------------------------------------------------------------

reg query "HKU\S-1-5-19" >nul
if not %errorlevel%==0 if %dryRun%==no (Powershell "Start-Process -FilePath '%0' -Verb RunAs" & exit)
pushd "%~dp0"
if %dryRun%==no color 4f
title %~n0.cmd
cls

Powershell "Get-WmiObject win32_service | ? Name -notlike '*_*' | ? PathName -like '*System32*' | Select Name, StartMode, DelayedAutoStart | Export-CSV -Path Backup.txt -NoTypeInformation"
Powershell "(Get-Content Backup.txt | Select -Skip 1) -replace 'Auto\",\"True','DelayedAuto' -replace ',\"False\"','' -replace ',\"True\"','' | Set-Content Backup.txt"

findstr /vixg:Backup.txt %configFile% >"%Temp%\diff.csv"
set configFile=%Temp%\diff.csv

setlocal enableDelayedExpansion
if %backupAsReg%==yes call :regBackup

for /f "tokens=1,2 delims=," %%a in (%configFile%) do (
  set str=
  set skip=%dryRun%
  if not "!skipped!"=="!skipped:%%~a=!" set skip=yes & set str=Skipped
  if !skip!==no (
    if %%~b==DelayedAuto sc config %%~a start=delayed-auto || set err=!err! %%~a
    if %%~b==Auto sc config %%~a start=auto || set err=!err! %%~a
    if %%~b==Manual sc config %%~a start=demand || set err=!err! %%~a
    if %%~b==Disabled sc config %%~a start=disabled || set err=!err! %%~a
    echo !err! | find "%%~a" && set str=Failed
    ) >nul 2>&1
  if "!str!"=="" (echo %%~a ^> %%~b) else (echo %%~a = !str!)
  rem set "name=%%~a                              "
  rem echo !name:~0,30! ^> %%~b
)
rem echo set skipped=%err%
echo.
echo Press any key to exit . . . & pause >nul
color
exit /b

:regBackup
setlocal
set dtm=%date:~6,4%%date:~3,2%%date:~0,2%-%time:~0,2%%time:~3,2%
set reg=Backup-%dtm: =0%.reg

(echo Windows Registry Editor Version 5.00 & echo.
for /f "tokens=1,2 delims=," %%a in (Backup.txt) do (
  set skip=no
  if not "!skipped!"=="!skipped:%%~a=!" set skip=yes
  if !skip!==no (
    echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%%~a]
    if %%~b==DelayedAuto echo "DelayedAutoStart"=dword:00000001
    if %%~b==DelayedAuto echo "Start"=dword:00000002
    if %%~b==Auto echo "Start"=dword:00000002
    if %%~b==Manual echo "Start"=dword:00000003
    if %%~b==Disabled echo "Start"=dword:00000004
))) >%reg%
endlocal
exit /b