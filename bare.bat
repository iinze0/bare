@echo off
setlocal
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo Requesting administrator.
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
echo bare 2.3
echo This file is the release. It runs the script embedded below. Nothing is downloaded.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=$env:TEMP+'\bare-release.ps1'; $raw=Get-Content -LiteralPath '%~f0' -Raw; $i=$raw.IndexOf('#__BARE_PS1__'); if($i -lt 0){ throw 'Embedded script missing.' }; $raw.Substring($i+13) | Set-Content -LiteralPath $p -Encoding UTF8; & $p"
exit /b
#__BARE_PS1__
$ErrorActionPreference = 'Continue'
$Log = Join-Path $env:USERPROFILE 'bare-log.txt'
function Write-Log([string]$msg) { Add-Content -Path $Log -Value ('{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg); Write-Host $msg }
function Set-Dword([string]$path, [string]$name, [int]$value) { if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }; New-ItemProperty -Path $path -Name $name -Value $value -PropertyType DWord -Force | Out-Null }
function Set-ServiceMode([string]$name, [string]$mode) { try { if ($mode -eq 'Disabled') { Stop-Service -Name $name -Force -ErrorAction SilentlyContinue; Set-Service -Name $name -StartupType Disabled -ErrorAction Stop } else { Set-Service -Name $name -StartupType Manual -ErrorAction Stop; Stop-Service -Name $name -Force -ErrorAction SilentlyContinue }; Write-Log "$name -> $mode" } catch { Write-Log "$name unchanged: $($_.Exception.Message)" } }
$opts = [ordered]@{ apps=$false; ads=$false; tasks=$false; privacy=$false; telemetry=$false; search=$false; xbox=$false; gamedvr=$false; cpu=$false; idle=$false; hags=$false; visuals=$false; hibernate=$false; bluetooth=$false; print=$false; ipv6=$false; onedrive=$false; browser=$false; updates=$false; defender=$false }
$labels = [ordered]@{ apps='Remove inbox apps'; ads='Ads, tips, Copilot'; tasks='Feedback tasks'; privacy='Privacy policies'; telemetry='Telemetry services'; search='Disable Search'; xbox='Disable Xbox services'; gamedvr='Game DVR off, Game Mode on'; cpu='CPU 100% on AC'; idle='CPU idle off'; hags='GPU scheduling on'; visuals='Visual effects performance'; hibernate='Hibernate off'; bluetooth='Disable Bluetooth'; print='Disable print spooler'; ipv6='Disable IPv6'; onedrive='Uninstall OneDrive'; browser='Firefox or Brave, optional Edge uninstall'; updates='Disable Windows Update'; defender='Disable Defender real-time' }
function Show-Opts { $i=1; foreach($k in $opts.Keys){ Write-Host ('{0,2}  [{1}]  {2}' -f $i, $(if($opts[$k]){'ON '}else{'off'}), $labels[$k]); $i++ } }
function Invoke-Key([int]$n){ $keys=@($opts.Keys); if($n -ge 1 -and $n -le $keys.Count){ $opts[$keys[$n-1]] = -not $opts[$keys[$n-1]] } }
function Set-Preset([string]$name){ foreach($k in @($opts.Keys)){ $opts[$k]=$false }; switch($name){ 'perf'{ foreach($k in @('apps','ads','tasks','telemetry','search','xbox','gamedvr','cpu','hags','visuals')){ $opts[$k]=$true } } 'game'{ foreach($k in @('apps','ads','tasks','gamedvr','cpu','hags','visuals')){ $opts[$k]=$true } } 'priv'{ foreach($k in @('apps','ads','tasks','privacy','telemetry','search')){ $opts[$k]=$true } } } }
function Remove-InboxApps { $names=@('Clipchamp.Clipchamp','Microsoft.BingNews','Microsoft.BingWeather','Microsoft.BingSearch','Microsoft.GetHelp','Microsoft.Getstarted','Microsoft.MicrosoftOfficeHub','Microsoft.MicrosoftSolitaireCollection','Microsoft.MixedReality.Portal','Microsoft.People','Microsoft.Todos','Microsoft.WindowsFeedbackHub','Microsoft.WindowsMaps','Microsoft.Xbox.TCUI','Microsoft.XboxGameOverlay','Microsoft.XboxGamingOverlay','Microsoft.YourPhone','Microsoft.ZuneMusic','Microsoft.ZuneVideo','Microsoft.549981C3F5F10','Microsoft.Windows.DevHome','Microsoft.OutlookForWindows','MicrosoftTeams','MSTeams','Microsoft.GamingApp','Microsoft.Windows.Copilot'); foreach($name in $names){ foreach($pkg in @(Get-AppxPackage -Name $name -AllUsers -ErrorAction SilentlyContinue)){ try{ Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop; Write-Log "Removed $($pkg.Name)" } catch { Write-Log "Could not remove $($pkg.Name)" } }; foreach($p in @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $name })){ try{ Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -ErrorAction Stop | Out-Null; Write-Log "Deprovisioned $($p.DisplayName)" } catch {} } } }
function Invoke-Apply {
  Write-Log 'bare 2.3 apply'
  try { Checkpoint-Computer -Description 'bare before changes' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop; Write-Log 'Restore point created.' } catch { Write-Log 'Restore point skipped.' }
  if($opts.apps){ Remove-InboxApps }
  if($opts.ads){ foreach($n in @('SubscribedContent-338389Enabled','SilentInstalledAppsEnabled','SystemPaneSuggestionsEnabled')){ Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' $n 0 }; Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowCopilotButton' 0; Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1; Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1; Write-Log 'Ads set.' }
  if($opts.tasks){ foreach($task in @('\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser','\Microsoft\Windows\Customer Experience Improvement Program\Consolidator','\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip','\Microsoft\Windows\Maps\MapsUpdateTask','\Microsoft\Windows\Feedback\Siuf\DmClient','\Microsoft\Windows\Windows Error Reporting\QueueReporting')){ schtasks /Change /TN $task /DISABLE 2>$null | Out-Null }; Write-Log 'Tasks disabled.' }
  if($opts.privacy){ Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0; Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo' 'DisabledByGroupPolicy' 1; Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableActivityFeed' 0; Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocation' 1; Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 0; Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'DisableWebSearch' 1; Write-Log 'Privacy set.' }
  if($opts.telemetry){ foreach($s in @('DiagTrack','dmwappushservice')){ Set-ServiceMode $s 'Disabled' } }
  if($opts.search){ Set-ServiceMode 'WSearch' 'Disabled' }
  if($opts.xbox){ foreach($s in @('XblAuthManager','XblGameSave','XboxGipSvc','XboxNetApiSvc')){ Set-ServiceMode $s 'Disabled' } }
  if($opts.gamedvr){ Set-Dword 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0; Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 0; Set-Dword 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1; Write-Log 'Game DVR off.' }
  if($opts.cpu -or $opts.idle){ $ultimate='e9a42b02-d5df-448d-aa00-03f14749eb61'; powercfg -duplicatescheme $ultimate 2>$null | Out-Null; $guid=$ultimate; if((powercfg /list) -notmatch $ultimate){ $guid='8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c' }; powercfg /setactive $guid | Out-Null; powercfg /setacvalueindex $guid SUB_PROCESSOR PROCTHROTTLEMIN 100 | Out-Null; powercfg /setacvalueindex $guid SUB_PROCESSOR PROCTHROTTLEMAX 100 | Out-Null; powercfg /setacvalueindex $guid SUB_PROCESSOR CPMINCORES 100 | Out-Null; if($opts.idle){ powercfg /setacvalueindex $guid SUB_PROCESSOR IDLEDISABLE 1 | Out-Null }; powercfg /setactive $guid | Out-Null; Write-Log 'CPU plan set.' }
  if($opts.hags){ Set-Dword 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2 }
  if($opts.visuals){ Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 2; Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0 }
  if($opts.hibernate){ powercfg -h off | Out-Null; Write-Log 'Hibernate off.' }
  if($opts.bluetooth){ Set-ServiceMode 'bthserv' 'Disabled' }
  if($opts.print){ Set-ServiceMode 'Spooler' 'Disabled' }
  if($opts.ipv6 -and (Read-Host 'Disable IPv6? Type yes') -eq 'yes'){ Get-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue | Disable-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue; Write-Log 'IPv6 off.' }
  if($opts.onedrive -and (Read-Host 'Uninstall OneDrive? Type yes') -eq 'yes'){ winget uninstall --id Microsoft.OneDrive --accept-source-agreements; Write-Log 'OneDrive uninstall requested.' }
  if($opts.browser){ Write-Host '1 Firefox  2 Brave  3 skip'; $pick=Read-Host 'Browser'; $id=$null; if($pick -eq '1'){ $id='Mozilla.Firefox' } elseif($pick -eq '2'){ $id='Brave.Brave' }; if($id){ winget install --id $id --accept-package-agreements --accept-source-agreements; if($LASTEXITCODE -eq 0 -and (Read-Host 'Uninstall Edge? Type yes') -eq 'yes'){ $setup=Get-ChildItem -Path (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application') -Recurse -Filter setup.exe -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match '\Installer\setup.exe$' } | Select-Object -First 1; if($setup){ & $setup.FullName --uninstall --system-level --force-uninstall --verbose-logging; Write-Log 'Edge uninstall finished.' } } } }
  if($opts.updates -and (Read-Host 'Disable Windows Update? Type yes') -eq 'yes'){ Set-ServiceMode 'wuauserv' 'Disabled' }
  if($opts.defender -and (Read-Host 'Disable Defender real-time? Type yes') -eq 'yes'){ Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue; Write-Log 'Defender real-time requested off.' }
  Write-Log 'Apply finished. Log: ' + $Log
  Write-Host 'Restart to finish.'
}
Write-Log 'bare 2.3 started'
while($true){ Write-Host ''; Write-Host 'bare 2.3'; Show-Opts; Write-Host 'p performance   g gaming   v privacy   a apply   0 exit'; $choice=Read-Host 'Choose'; switch($choice){ 'p'{ Set-Preset 'perf' } 'g'{ Set-Preset 'game' } 'v'{ Set-Preset 'priv' } 'a'{ Invoke-Apply } '0'{ break } default { if($choice -match '^\d+$'){ Invoke-Key ([int]$choice) } } }; if($choice -eq '0'){ break } }
