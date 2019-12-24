@echo off
setlocal enableDelayedExpansion
set "dv==::"
if defined !dv! (Powershell "Start-Process -FilePath '%0' -verb RunAs" & exit)
for %%X in (
  "\Microsoft\Windows\Autochk\Proxy"
  "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
  "\Microsoft\Windows\Application Experience\ProgramDataUpdater"
  "\Microsoft\Windows\Application Experience\StartupAppTask"
  "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
  "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
  "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
  "\Microsoft\Windows\Feedback\Siuf\DmClient"
  "\Microsoft\Windows\Maintenance\WinSAT"
  "\Microsoft\Windows\Maps\MapsToastTask"
  "\Microsoft\Windows\Maps\MapsUpdateTask"
  "\Microsoft\Windows\NetTrace\GatherNetworkInfo"
  "\Microsoft\Windows\PI\Sqm-Tasks"
  "\Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan"
  "\Microsoft\Windows\Windows Defender\Windows Defender Verification"
  "\Microsoft\Windows\Windows Error Reporting\QueueReporting"
  "\Microsoft\Windows\WindowsUpdate\Scheduled Start"
  "\Microsoft\Windows\WindowsUpdate\sih"
) do (
  schtasks /Change /TN %%X /Disable >nul || pause
)
endlocal
exit /b