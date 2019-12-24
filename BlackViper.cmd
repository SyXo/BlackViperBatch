@echo off
:: SCRIPT SETTINGS -----------------------------------------------------

:: Configuration file (must be in CSV format)
set configFile=BlackViper.txt
:: Backup as registry file (yes|no)
set backupAsReg=no
:: Runs without apply changes (yes|no)
set dryRun=no
:: Services that cannot be disabled (will be skipped)
set skipped=AppIDSvc AppXSvc BFE BrokerInfrastructure ClipSVC CoreMessagingRegistrar DcomLaunch Dnscache embeddedmode EntAppSvc gpsvc msiserver NgcCtnrSvc NgcSvc RpcEptMapper RpcSs Schedule SecurityHealthService SgrmBroker sppsvc sppsvc StateRepository SystemEventsBroker TimeBrokerSvc UsoSvc UsoSvc WaaSMedicSvc WinHttpAutoProxySvc wscsvc wscsvc wuauserv xbgm

::----------------------------------------------------------------------

reg query "HKU\S-1-5-19" >nul
if not %errorlevel%==0 if %dryRun%==no (Powershell "Start-Process -FilePath '%0' -verb RunAs" & exit)
pushd "%~dp0"
@title %~n0.cmd
if %dryRun%==no color 4f
cls

Powershell "Get-WmiObject win32_service | ? Name -notlike '*_*' | ? PathName -like '*System32*' | Select Name, StartMode, DelayedAutoStart | Export-CSV -Path Backup.txt -NoTypeInformation"
rem FIXME:"Manual","True"

if %backupAsReg%==yes call :regBackup
if %dryRun%==no (
  echo "Name","StartMode","DelayedAutoStart"
  findstr /vixg:Backup.txt %configFile%
  set configFile=%Temp%\diff.csv
) >%Temp%\diff.csv

setlocal enableDelayedExpansion

for /f "tokens=1,2,3 delims=, skip=1" %%a in (%configFile%) do (
  set skip=no
  set start=%%~b
  if not "!skipped!"=="!skipped:%%~a=!" set skip=yes & set start=Skipped
  if %%~c==True if !start!==Auto set start=DelayedAuto
  if !skip!==no if %dryRun%==yes set skip=yes
  if !skip!==no (
    if !start!==DelayedAuto sc config %%~a start=delayed-auto || set err=!err! %%~a
    if !start!==Auto sc config %%~a start=auto || set err=!err! %%~a
    if !start!==Manual sc config %%~a start=demand || set err=!err! %%~a
    if !start!==Disabled sc config %%~a start=disabled || set err=!err! %%~a
    echo !err! | find /i "%%~a" && set start=Failed
    ) >nul 2>&1
  echo %%~a ^> !start!
  rem set "spaces=                              "
  rem set name=%%~a%spaces%
  rem echo !name:~0,30%! ^> !start!
)
rem echo set skipped=%err%

endlocal
echo.
echo Press any key to exit . . . & pause >nul
color
exit /b

:regBackup
set dtm=%date:~6,4%%date:~3,2%%date:~0,2%-%time:~0,2%%time:~3,2%
set reg=Backup-%dtm: =0%.reg

setlocal enableDelayedExpansion

(echo Windows Registry Editor Version 5.00 & echo.
for /f "tokens=1,2,3 delims=, skip=1" %%a in (Backup.txt) do (
  set skip=no
  if not "!skipped!"=="!skipped:%%~a=!" set skip=yes
  if !skip!==no (
    echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%%~a]
    if %%~c==True echo "DelayedAutoStart"=dword:00000001
    if %%~b==Auto echo "Start"=dword:00000002
    if %%~b==Manual echo "Start"=dword:00000003
    if %%~b==Disabled echo "Start"=dword:00000004
))) >%reg%

endlocal
exit /b
