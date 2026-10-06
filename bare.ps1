# bare 2.5
$ErrorActionPreference = 'Continue'
$Log = Join-Path $PSScriptRoot 'bare-log.txt'
$TickFile = Join-Path $PSScriptRoot 'bare-ticks.txt'
function Write-Log([string]$msg) { Add-Content -Path $Log -Value ('{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg); Write-Host $msg }
function Assert-Admin { $p = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()); if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { Write-Host 'Not running as administrator.'; exit 1 } }
function Set-Dword([string]$path, [string]$name, [int]$value) { if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }; New-ItemProperty -Path $path -Name $name -Value $value -PropertyType DWord -Force | Out-Null }
function Set-ServiceMode([string]$name, [string]$mode) { try { if ($mode -eq 'Disabled') { Stop-Service -Name $name -Force -ErrorAction SilentlyContinue; Set-Service -Name $name -StartupType Disabled -ErrorAction Stop } else { Set-Service -Name $name -StartupType Manual -ErrorAction Stop; Stop-Service -Name $name -Force -ErrorAction SilentlyContinue }; Write-Log "$name -> $mode" } catch { Write-Log "$name unchanged: $($_.Exception.Message)" } }
$opts = [ordered]@{ apps=$false; ads=$false; tasks=$false; privacy=$false; telemetry=$false; search=$false; xbox=$false; gamedvr=$false; cpu=$false; idle=$false; hags=$false; visuals=$false; hibernate=$false; bluetooth=$false; print=$false; ipv6=$false; onedrive=$false; browser=$false; updates=$false; defender=$false }
$labels = [ordered]@{ apps='Remove inbox apps and deprovision them'; ads='Ads, tips, widgets, background apps, Copilot'; tasks='Feedback, CEIP, Maps, diagnostics tasks'; privacy='Advertising id, activity, location, Bing, sync'; telemetry='Telemetry, delivery optimization, SysMain, error reporting'; search='Disable Windows Search'; xbox='Disable Xbox services'; gamedvr='Game DVR off, Game Mode on, games priority'; cpu='CPU 100% on AC, parking off, USB suspend off'; idle='CPU idle off'; hags='Hardware GPU scheduling'; visuals='Performance visuals, animations off'; hibernate='Hibernate off'; bluetooth='Disable Bluetooth'; print='Disable print spooler'; ipv6='Disable IPv6'; onedrive='Uninstall OneDrive'; browser='Firefox or Brave, optional Edge uninstall'; updates='Disable Windows Update'; defender='Disable Defender real-time' }
function Show-Opts { $i=1; foreach($k in $opts.Keys){ Write-Host ('{0,2}  [{1}]  {2}' -f $i, $(if($opts[$k]){'ON '}else{'off'}), $labels[$k]); $i++ } }
function Invoke-Key([int]$n){ $keys=@($opts.Keys); if($n -ge 1 -and $n -le $keys.Count){ $opts[$keys[$n-1]] = -not $opts[$keys[$n-1]] } }
function Set-Preset([string]$name){ foreach($k in @($opts.Keys)){ $opts[$k]=$false }; switch($name){ 'perf'{ foreach($k in @('apps','ads','tasks','telemetry','search','xbox','gamedvr','cpu','hags','visuals')){ $opts[$k]=$true } } 'game'{ foreach($k in @('apps','ads','tasks','gamedvr','cpu','hags','visuals')){ $opts[$k]=$true } } 'priv'{ foreach($k in @('apps','ads','tasks','privacy','telemetry','search')){ $opts[$k]=$true } } } }
function Save-Ticks { $on = @($opts.Keys | Where-Object { $opts[$_] }); Set-Content -Path $TickFile -Value ($on -join ','); Write-Log "Saved ticks: $($on -join ', ')" }
function Load-Ticks { if (-not (Test-Path $TickFile)) { Write-Host 'No saved ticks.'; return }; foreach($k in @($opts.Keys)){ $opts[$k]=$false }; foreach($k in ((Get-Content $TickFile -Raw) -split ',')){ $name=$k.Trim(); if($opts.Contains($name)){ $opts[$name]=$true } }; Write-Log 'Loaded saved ticks.' }
function Remove-InboxApps {
  $names = @('Clipchamp.Clipchamp','Microsoft.BingNews','Microsoft.BingWeather','Microsoft.BingSearch','Microsoft.GetHelp','Microsoft.Getstarted','Microsoft.MicrosoftOfficeHub','Microsoft.MicrosoftSolitaireCollection','Microsoft.MixedReality.Portal','Microsoft.People','Microsoft.Todos','Microsoft.WindowsFeedbackHub','Microsoft.WindowsMaps','Microsoft.Xbox.TCUI','Microsoft.XboxGameOverlay','Microsoft.XboxGamingOverlay','Microsoft.XboxIdentityProvider','Microsoft.XboxSpeechToTextOverlay','Microsoft.YourPhone','Microsoft.ZuneMusic','Microsoft.ZuneVideo','MicrosoftCorporationII.MicrosoftFamily','MicrosoftCorporationII.QuickAssist','Microsoft.549981C3F5F10','Microsoft.Windows.DevHome','Microsoft.OutlookForWindows','Microsoft.WindowsAlarms','MicrosoftTeams','MSTeams','Microsoft.GamingApp','Microsoft.Windows.NarratorQuickStart','Microsoft.MicrosoftStickyNotes','Microsoft.WindowsSoundRecorder','Microsoft.Windows.Copilot')
  foreach ($name in $names) {
    foreach ($pkg in @(Get-AppxPackage -Name $name -AllUsers -ErrorAction SilentlyContinue)) { try { Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop; Write-Log "Removed $($pkg.Name)" } catch { Write-Log "Could not remove $($pkg.Name)" } }
    foreach ($p in @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object DisplayName -eq $name)) { try { Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -ErrorAction Stop | Out-Null; Write-Log "Deprovisioned $($p.DisplayName)" } catch { Write-Log "Could not deprovision $name" } }
  }
}
function Disable-Tasks {
  $tasks = @('\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser','\Microsoft\Windows\Application Experience\ProgramDataUpdater','\Microsoft\Windows\Application Experience\StartupAppTask','\Microsoft\Windows\Customer Experience Improvement Program\Consolidator','\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip','\Microsoft\Windows\Maps\MapsUpdateTask','\Microsoft\Windows\Feedback\Siuf\DmClient','\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector','\Microsoft\Windows\Windows Error Reporting\QueueReporting','\Microsoft\Windows\Diagnosis\Scheduled','\Microsoft\Windows\DiskFootprint\Diagnostics','\Microsoft\Windows\Maintenance\WinSAT','\Microsoft\Windows\CloudExperienceHost\CreateObjectTask','\Microsoft\Windows\Shell\FamilySafetyMonitor')
  foreach ($task in $tasks) { schtasks /Change /TN $task /DISABLE 2>$null | Out-Null; if ($LASTEXITCODE -eq 0) { Write-Log "Task off: $task" } }
}
function Set-Cpu([bool]$idleOff) {
  $ultimate = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
  powercfg -duplicatescheme $ultimate 2>$null | Out-Null
  $guid = $ultimate
  if ((powercfg /list) -notmatch $ultimate) { $guid = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c' }
  powercfg /setactive $guid | Out-Null
  powercfg /setacvalueindex $guid SUB_PROCESSOR PROCTHROTTLEMIN 100 | Out-Null
  powercfg /setacvalueindex $guid SUB_PROCESSOR PROCTHROTTLEMAX 100 | Out-Null
  powercfg /setacvalueindex $guid SUB_PROCESSOR CPMINCORES 100 | Out-Null
  powercfg /setacvalueindex $guid SUB_PROCESSOR CPMAXCORES 100 | Out-Null
  powercfg /setacvalueindex $guid SUB_SLEEP STANDBYIDLE 0 | Out-Null
  powercfg /setacvalueindex $guid SUB_USB USBSELECTIVESUSPEND 0 | Out-Null
  if ($idleOff) { powercfg /setacvalueindex $guid SUB_PROCESSOR IDLEDISABLE 1 | Out-Null; Write-Log 'Idle off.' } else { powercfg /setacvalueindex $guid SUB_PROCESSOR IDLEDISABLE 0 | Out-Null }
  powercfg /setactive $guid | Out-Null
  Write-Log 'CPU plan set.'
}
function Invoke-Scan {
  Write-Host (powercfg /getactivescheme)
  foreach ($svc in @('DiagTrack','SysMain','WSearch','XblGameSave','bthserv','Spooler','wuauserv','WinDefend')) {
    try { $st = (Get-Service -Name $svc -ErrorAction Stop).StartType } catch { $st = 'missing' }
    Write-Host ('{0,-16} {1}' -f $svc, $st)
  }
  Write-Host ("Edge folder: {0}" -f (Test-Path (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application')))
  if (Test-Path $TickFile) { Write-Host ("Saved ticks: {0}" -f (Get-Content $TickFile -Raw)) }
}
function Invoke-Apply {
  Write-Log 'bare 2.5 apply'
  Write-Host 'Selected:'
  foreach ($k in $opts.Keys) { if ($opts[$k]) { Write-Host "  $k" } }
  Save-Ticks
  try { Enable-ComputerRestore -Drive 'C:\' -ErrorAction SilentlyContinue; Checkpoint-Computer -Description 'bare before changes' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop; Write-Log 'Restore point created.' } catch { Write-Log 'Restore point skipped.' }
  if ($opts.apps) { Remove-InboxApps }
  if ($opts.ads) {
    foreach ($n in @('SubscribedContent-338389Enabled','SubscribedContent-310093Enabled','SubscribedContent-338388Enabled','SubscribedContent-338393Enabled','SubscribedContent-353694Enabled','SubscribedContent-353696Enabled','SilentInstalledAppsEnabled','SystemPaneSuggestionsEnabled','SoftLandingEnabled')) { Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' $n 0 }
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_IrisRecommendations' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowCopilotButton' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' 'GlobalUserDisabled' 1
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy' 'LetAppsRunInBackground' 2
    Write-Log 'Ads, widgets, background apps off.'
  }
  if ($opts.tasks) { Disable-Tasks }
  if ($opts.privacy) {
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo' 'DisabledByGroupPolicy' 1
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableActivityFeed' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'PublishUserActivities' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'UploadUserActivities' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocation' 1
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'CortanaConsent' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'AllowCortana' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'DisableWebSearch' 1
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync' 'DisableSettingSync' 2
    Write-Log 'Privacy policies set.'
  }
  if ($opts.telemetry) { foreach ($s in @('DiagTrack','dmwappushservice','DoSvc','SysMain','WerSvc','PcaSvc')) { Set-ServiceMode $s 'Disabled' } }
  if ($opts.search) { Set-ServiceMode 'WSearch' 'Disabled' }
  if ($opts.xbox) { foreach ($s in @('XblAuthManager','XblGameSave','XboxGipSvc','XboxNetApiSvc')) { Set-ServiceMode $s 'Disabled' } }
  if ($opts.gamedvr) {
    Set-Dword 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
    Set-Dword 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1
    Set-Dword 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode' 1
    Set-Dword 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 0xffffffff
    Set-Dword 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 0
    Set-Dword 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'GPU Priority' 8
    Set-Dword 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'Priority' 6
    Set-Dword 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'Scheduling Category' 2
    Set-Dword 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize' 'StartupDelayInMSec' 0
    Write-Log 'Game DVR off, Game Mode on, games priority raised.'
  }
  if ($opts.cpu -or $opts.idle) { Set-Cpu ([bool]$opts.idle) }
  if ($opts.hags) { Set-Dword 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2; Write-Log 'HAGS on.' }
  if ($opts.visuals) {
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 2
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAnimations' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt' 0
    Write-Log 'Visuals set.'
  }
  if ($opts.hibernate) { powercfg -h off | Out-Null; Write-Log 'Hibernate off.' }
  if ($opts.bluetooth) { Set-ServiceMode 'bthserv' 'Disabled' }
  if ($opts.print) { Set-ServiceMode 'Spooler' 'Disabled' }
  if ($opts.ipv6 -and (Read-Host 'Disable IPv6 on all adapters? Type yes') -eq 'yes') { Get-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue | Disable-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue; Write-Log 'IPv6 off.' }
  if ($opts.onedrive -and (Read-Host 'Uninstall OneDrive? Type yes') -eq 'yes') { winget uninstall --id Microsoft.OneDrive --accept-source-agreements; Write-Log 'OneDrive uninstall requested.' }
  if ($opts.browser) {
    Write-Host '1 Firefox  2 Brave  3 skip'
    $pick = Read-Host 'Browser'
    $id = $null
    if ($pick -eq '1') { $id = 'Mozilla.Firefox' } elseif ($pick -eq '2') { $id = 'Brave.Brave' }
    if ($id -and (Get-Command winget -ErrorAction SilentlyContinue)) {
      winget install --id $id --accept-package-agreements --accept-source-agreements
      if ($LASTEXITCODE -eq 0 -and (Read-Host 'Uninstall Edge? Type yes') -eq 'yes') {
        $setup = Get-ChildItem -Path (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application') -Recurse -Filter setup.exe -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match '\\Installer\\setup.exe$' } | Select-Object -First 1
        if ($setup) { & $setup.FullName --uninstall --system-level --force-uninstall --verbose-logging; Write-Log 'Edge uninstall finished.' } else { Write-Log 'Edge setup.exe not found.' }
      }
    } else { Write-Log 'Browser skipped.' }
  }
  if ($opts.updates -and (Read-Host 'Disable Windows Update? Type yes') -eq 'yes') { Set-ServiceMode 'wuauserv' 'Disabled' }
  if ($opts.defender -and (Read-Host 'Disable Defender real-time? Type yes') -eq 'yes') { Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue; Write-Log 'Defender real-time requested off.' }
  Write-Log 'Apply finished.'
  Write-Host "Log: $Log"
  Write-Host 'Restart to finish.'
}
Assert-Admin
if (Test-Path $TickFile) { Load-Ticks }
Write-Log 'bare 2.5 started'
while ($true) {
  Write-Host ''
  Write-Host 'bare 2.5'
  Show-Opts
  Write-Host 'p performance   g gaming   v privacy'
  Write-Host 'a apply   s save   l load   c scan   0 exit'
  $choice = Read-Host 'Choose'
  switch ($choice) {
    'p' { Set-Preset 'perf' }
    'g' { Set-Preset 'game' }
    'v' { Set-Preset 'priv' }
    'a' { Invoke-Apply }
    's' { Save-Ticks }
    'l' { Load-Ticks }
    'c' { Invoke-Scan }
    '0' { break }
    default { if ($choice -match '^\d+$') { Invoke-Key ([int]$choice) } }
  }
  if ($choice -eq '0') { break }
}
