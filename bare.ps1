# bare 3.6
$ErrorActionPreference = 'Continue'
$Log = Join-Path $PSScriptRoot 'bare-log.txt'
$TickFile = Join-Path $PSScriptRoot 'bare-ticks.txt'
$Last = Join-Path $PSScriptRoot 'bare-last.txt'
function Write-Log([string]$msg) { Add-Content -Path $Log -Value ('{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg); Write-Host $msg }
function Assert-Admin { $p = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()); if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { Write-Host 'Not running as administrator.'; exit 1 } }
function Set-Dword([string]$path, [string]$name, [int]$value) { if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }; New-ItemProperty -Path $path -Name $name -Value $value -PropertyType DWord -Force | Out-Null }
function Set-ServiceMode([string]$name, [string]$mode) { try { if ($mode -eq 'Disabled') { Stop-Service -Name $name -Force -ErrorAction SilentlyContinue; Set-Service -Name $name -StartupType Disabled -ErrorAction Stop } elseif ($mode -eq 'Automatic') { Set-Service -Name $name -StartupType Automatic -ErrorAction Stop; Start-Service -Name $name -ErrorAction SilentlyContinue } else { Set-Service -Name $name -StartupType Manual -ErrorAction Stop }; Write-Log "$name -> $mode" } catch { Write-Log "$name unchanged: $($_.Exception.Message)" } }
$opts = [ordered]@{ apps=$false; ads=$false; tasks=$false; privacy=$false; telemetry=$false; search=$false; xbox=$false; gamedvr=$false; cpu=$false; idle=$false; hags=$false; visuals=$false; mouse=$false; sticky=$false; focus=$false; temp=$false; startup=$false; hibernate=$false; bluetooth=$false; print=$false; ipv6=$false; onedrive=$false; browser=$false; updates=$false; defender=$false }
$labels = [ordered]@{ apps='Remove inbox apps and deprovision them'; ads='Ads, tips, widgets, background apps, Copilot'; tasks='Feedback, CEIP, Maps, diagnostics tasks'; privacy='Advertising id, activity, location, speech, clipboard, Find My Device'; telemetry='Telemetry, delivery optimization, SysMain, error reporting'; search='Disable Windows Search'; xbox='Disable Xbox services'; gamedvr='Game DVR off, Game Mode on, games priority'; cpu='CPU 100%, no parking, no throttling, NTFS cache'; idle='CPU idle off'; hags='Hardware GPU scheduling'; visuals='Performance visuals, animations off'; mouse='Mouse acceleration off'; sticky='Sticky Keys shortcut off'; focus='Focus assist alarms only'; temp='Clean user temp, asks first'; startup='Disable known promo startup entries, asks first'; hibernate='Hibernate off'; bluetooth='Disable Bluetooth'; print='Disable print spooler'; ipv6='Disable IPv6'; onedrive='Uninstall OneDrive'; browser='Firefox or Brave, optional Edge uninstall'; updates='Disable Windows Update'; defender='Disable Defender real-time' }
function Show-Opts { $i=1; $on=0; foreach($k in $opts.Keys){ if($opts[$k]){ $on++ }; Write-Host ('{0,2}  [{1}]  {2}' -f $i, $(if($opts[$k]){'ON '}else{'off'}), $labels[$k]); $i++ }; Write-Host "$on on" }
function Invoke-Key([int]$n){ $keys=@($opts.Keys); if($n -ge 1 -and $n -le $keys.Count){ $opts[$keys[$n-1]] = -not $opts[$keys[$n-1]] } }
function Set-Preset([string]$name){ foreach($k in @($opts.Keys)){ $opts[$k]=$false }; switch($name){ 'perf'{ foreach($k in @('apps','ads','tasks','telemetry','search','xbox','gamedvr','cpu','hags','visuals','mouse','sticky')){ $opts[$k]=$true } } 'game'{ foreach($k in @('apps','ads','tasks','gamedvr','cpu','hags','visuals','mouse','sticky','focus')){ $opts[$k]=$true } } 'priv'{ foreach($k in @('apps','ads','tasks','privacy','telemetry','search')){ $opts[$k]=$true } } } }
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
  powercfg /setacvalueindex $guid SUB_PCIEXPRESS ASPM 0 | Out-Null
  powercfg /setacvalueindex $guid SUB_PROCESSOR PERFBOOSTMODE 2 | Out-Null
  powercfg /setacvalueindex $guid SUB_DISK DISKIDLE 0 | Out-Null
  powercfg /setacvalueindex $guid SUB_NONE CONNECTIVITYINKB 0 | Out-Null
  if ($idleOff) {
    powercfg /setacvalueindex $guid SUB_PROCESSOR IDLEDISABLE 1 | Out-Null
    if ((Read-Host 'Disable dynamic tick? This can make the clock less stable. Type yes') -eq 'yes') {
      bcdedit /set disabledynamictick yes | Out-Null
      bcdedit /set useplatformtick yes | Out-Null
      Write-Log 'Dynamic tick off. Reboot required.'
    }
    Write-Log 'Idle off.'
  } else { powercfg /setacvalueindex $guid SUB_PROCESSOR IDLEDISABLE 0 | Out-Null }
  powercfg /setactive $guid | Out-Null
  Set-Dword 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' 'PowerThrottlingOff' 1
  Set-Dword 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'Win32PrioritySeparation' 38
  fsutil behavior set disablelastaccess 1 | Out-Null
  fsutil behavior set memoryusage 2 | Out-Null
  $mm = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
  if (-not (Test-Path $mm)) { New-Item -Path $mm -Force | Out-Null }
  Set-Dword $mm 'SystemResponsiveness' 0
  New-ItemProperty -Path $mm -Name 'NetworkThrottlingIndex' -Value 4294967295 -PropertyType DWord -Force | Out-Null
  powercfg /setacvalueindex $guid SUB_PROCESSOR PERFEPP 0 | Out-Null
  powercfg /setacvalueindex $guid SUB_PROCESSOR LATENCYHINTPERF 100 | Out-Null
  powercfg /setacvalueindex $guid SUB_PROCESSOR HETEROPOLICY 0 | Out-Null
  powercfg /setacvalueindex $guid SUB_PROCESSOR PERFBOOSTPOL 100 | Out-Null
  powercfg /setacvalueindex $guid 19cbb8fa-5279-450e-9fac-8a3a5c00066c 12bbebe6-58d6-4636-95bb-3217ef867c1a 0 | Out-Null
  Set-Dword 'HKLM:\SYSTEM\CurrentControlSet\Control' 'SvcHostSplitThresholdInKB' 38000000
  try { Disable-MMAgent -MemoryCompression -ErrorAction Stop; Write-Log 'Memory compression off.' } catch { Write-Log 'Memory compression unchanged.' }
  try { Disable-MMAgent -PageCombining -ErrorAction Stop; Write-Log 'Page combining off.' } catch { Write-Log 'Page combining unchanged.' }
  powercfg /setactive $guid | Out-Null
  Write-Log 'CPU plan set and reactivated. Power throttling off. Foreground priority 38. NTFS cache raised. Service split raised. Hybrid policy set to performance.'
}

function Clear-UserTemp {
  if ((Read-Host 'Delete files in your Temp folder? Type yes') -ne 'yes') { return }
  $n = 0
  Get-ChildItem $env:TEMP -Force -ErrorAction SilentlyContinue | ForEach-Object { try { Remove-Item $_.FullName -Recurse -Force -ErrorAction Stop; $n++ } catch { Write-Log "Temp kept: $($_.Name)" } }
  Write-Log "Temp entries removed: $n"
}
function Disable-PromoStartup {
  if ((Read-Host 'Disable OneDrive, Teams, and Edge startup entries? Type yes') -ne 'yes') { return }
  foreach ($run in @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Run','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run')) {
    if (-not (Test-Path $run)) { continue }
    foreach ($name in @('OneDrive','Teams','com.squirrel.Teams.Teams','MicrosoftEdgeAutoLaunch')) {
      if (Get-ItemProperty -Path $run -Name $name -ErrorAction SilentlyContinue) { Remove-ItemProperty -Path $run -Name $name -ErrorAction SilentlyContinue; Write-Log "Startup removed: $run $name" }
    }
  }
}
function Set-String([string]$path, [string]$name, [string]$value) {
  if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
  New-ItemProperty -Path $path -Name $name -Value $value -PropertyType String -Force | Out-Null
}
function Set-Mouse {
  Set-String 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0'
  Set-String 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0'
  Set-String 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0'
  Write-Log 'Mouse acceleration off.'
}
function Set-Sticky {
  Set-String 'HKCU:\Control Panel\Accessibility\StickyKeys' 'Flags' '506'
  Set-String 'HKCU:\Control Panel\Accessibility\Keyboard Response' 'Flags' '122'
  Set-String 'HKCU:\Control Panel\Accessibility\ToggleKeys' 'Flags' '58'
  Write-Log 'Sticky Keys shortcut off.'
}
function Set-Focus {
  Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount\$$windows.data.notifications.quiethourssettings\Current' 'Data' 0
  Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings' 'NOC_GLOBAL_SETTING_TOASTS_ENABLED' 0
  Write-Log 'Toast notifications off for this user.'
}
function Invoke-Scan {
  Write-Host (powercfg /getactivescheme)
  foreach ($svc in @('DiagTrack','SysMain','DoSvc','WSearch','XblGameSave','bthserv','Spooler','wuauserv','WinDefend')) {
    try { $st = (Get-Service -Name $svc -ErrorAction Stop).StartType } catch { $st = 'missing' }
    Write-Host ('{0,-16} {1}' -f $svc, $st)
  }
  $tel = 'unset'; $hags = 'unset'; $dvr = 'unset'
  try { $tel = (Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name AllowTelemetry -ErrorAction Stop).AllowTelemetry } catch {}
  try { $hags = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name HwSchMode -ErrorAction Stop).HwSchMode } catch {}
  try { $dvr = (Get-ItemProperty 'HKCU:\System\GameConfigStore' -Name GameDVR_Enabled -ErrorAction Stop).GameDVR_Enabled } catch {}
  Write-Host "AllowTelemetry $tel"
  Write-Host "HAGS HwSchMode $hags"
  Write-Host "GameDVR_Enabled $dvr"
  $pref = 'unset'; $prio = 'unset'
  try { $pref = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' -Name EnablePrefetcher -ErrorAction Stop).EnablePrefetcher } catch {}
  try { $prio = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' -Name Win32PrioritySeparation -ErrorAction Stop).Win32PrioritySeparation } catch {}
  Write-Host "EnablePrefetcher $pref"
  Write-Host "Win32PrioritySeparation $prio"
  Write-Host ("Edge folder: {0}" -f (Test-Path (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application')))
  if (Test-Path $TickFile) { Write-Host ("Saved ticks: {0}" -f (Get-Content $TickFile -Raw).Trim()) } else { Write-Host 'Saved ticks: none' }
}
function Invoke-Dry {
  Write-Host 'Dry run. Nothing will be written.'
  foreach ($k in $opts.Keys) { if ($opts[$k]) { Write-Host "  would apply $k - $($labels[$k])" } }
  if ($opts.idle -or $opts.temp -or $opts.startup -or $opts.ipv6 -or $opts.onedrive -or $opts.browser -or $opts.updates -or $opts.defender) { Write-Host 'Confirm prompts would still be asked on a real apply.' }
}
function Invoke-Revert {
  Write-Host 'Revert puts services back and clears policies this script sets. Removed Store apps are not restored.'
  if ((Read-Host 'Type yes') -ne 'yes') { return }
  foreach ($s in @('DiagTrack','dmwappushservice','DoSvc','SysMain','WerSvc','PcaSvc','WSearch','XblAuthManager','XblGameSave','XboxGipSvc','XboxNetApiSvc','bthserv','Spooler','wuauserv')) { Set-ServiceMode $s 'Manual' }
  foreach ($s in @('WinDefend')) { Set-ServiceMode $s 'Automatic' }
  try { Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue; Write-Log 'Defender real-time requested on.' } catch {}
  powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e | Out-Null
  powercfg -h on | Out-Null
  Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name AllowTelemetry -ErrorAction SilentlyContinue
  Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' -Name AllowGameDVR -ErrorAction SilentlyContinue
  Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' -Name TurnOffWindowsCopilot -ErrorAction SilentlyContinue
  Remove-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' -Name Win32PrioritySeparation -ErrorAction SilentlyContinue
  Remove-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' -Name PowerThrottlingOff -ErrorAction SilentlyContinue
  Remove-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' -Name OverlayTestMode -ErrorAction SilentlyContinue
  Set-Dword 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' 'EnablePrefetcher' 3
  Set-Dword 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' 'EnableSuperfetch' 3
  try { Enable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue; Enable-MMAgent -PageCombining -ErrorAction SilentlyContinue } catch {}
  bcdedit /deletevalue disabledynamictick 2>$null | Out-Null
  bcdedit /deletevalue useplatformtick 2>$null | Out-Null
  fsutil behavior set disablelastaccess 0 | Out-Null
  fsutil behavior set memoryusage 0 | Out-Null
  foreach ($name in @('AllowFindMyDevice','AllowClipboardHistory','AllowCrossDeviceClipboard')) { Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name $name -ErrorAction SilentlyContinue }
  Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice' -Name AllowFindMyDevice -ErrorAction SilentlyContinue
  Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization' -Name AllowInputPersonalization -ErrorAction SilentlyContinue
  Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-ItemProperty -Path $_.PSPath -Name 'TcpAckFrequency' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $_.PSPath -Name 'TCPNoDelay' -ErrorAction SilentlyContinue
  }
  Write-Log 'Revert finished. Restart. Store apps stay removed. Edge stays removed if you uninstalled it. Nagle, priority, overlay, prefetch, and dynamic tick were cleared.'
}
function Invoke-Apply {
  Write-Log 'bare 3.6 apply'
  $picked = @($opts.Keys | Where-Object { $opts[$_] })
  if ($picked.Count -eq 0) { Write-Host 'Nothing ticked.'; return }
  Write-Host 'Selected:'
  foreach ($k in $picked) { Write-Host "  $k" }
  Save-Ticks
  try { Enable-ComputerRestore -Drive 'C:\' -ErrorAction SilentlyContinue; Checkpoint-Computer -Description 'bare 3.6 before changes' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop; Write-Log 'Restore point created.' } catch { Write-Log 'Restore point skipped.' }
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
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'DisableOneSettingsDownloads' 1
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'DoNotShowFeedbackNotifications' 1
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableTailoredExperiencesWithDiagnosticData' 1
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo' 'DisabledByGroupPolicy' 1
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableActivityFeed' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'PublishUserActivities' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'UploadUserActivities' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableCdp' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocation' 1
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocationScripting' 1
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice' 'AllowFindMyDevice' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'AllowClipboardHistory' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'AllowCrossDeviceClipboard' 0
    Set-Dword 'HKCU:\Software\Microsoft\Clipboard' 'EnableClipboardHistory' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization' 'AllowInputPersonalization' 0
    Set-Dword 'HKCU:\Software\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 1
    Set-Dword 'HKCU:\Software\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection' 1
    Set-Dword 'HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' 'HasAccepted' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'AllowCortana' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'DisableWebSearch' 1
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'AllowCloudSearch' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'CortanaConsent' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings' 'IsDynamicSearchBoxEnabled' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync' 'DisableSettingSync' 2
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync' 'DisableSettingSyncUserOverride' 1
    Set-Dword 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' 'AllowTelemetry' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy' 'LetAppsAccessAccountInfo' 2
    Write-Log 'Privacy policies set. Camera and microphone were not changed.'
  }
  if ($opts.telemetry) {
    foreach ($s in @('DiagTrack','dmwappushservice','DoSvc','SysMain','WerSvc','PcaSvc')) { Set-ServiceMode $s 'Disabled' }
    Set-Dword 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' 'EnablePrefetcher' 0
    Set-Dword 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' 'EnableSuperfetch' 0
    Write-Log 'Prefetch and Superfetch off.'
  }
  if ($opts.search) { Set-ServiceMode 'WSearch' 'Disabled' }
  if ($opts.xbox) { foreach ($s in @('XblAuthManager','XblGameSave','XboxGipSvc','XboxNetApiSvc')) { Set-ServiceMode $s 'Disabled' } }
  if ($opts.gamedvr) {
    Set-Dword 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
    Set-Dword 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1
    Set-Dword 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode' 1
    $mm = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
    if (-not (Test-Path $mm)) { New-Item -Path $mm -Force | Out-Null }
    New-ItemProperty -Path $mm -Name 'NetworkThrottlingIndex' -Value 4294967295 -PropertyType DWord -Force | Out-Null
    Set-Dword 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 0
    Set-Dword 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'GPU Priority' 8
    Set-Dword 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'Priority' 6
    Set-Dword 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'Scheduling Category' 2
    Set-Dword 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize' 'StartupDelayInMSec' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
    Set-Dword 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehaviorMode' 2
    Set-Dword 'HKCU:\Software\Microsoft\GameBar' 'UseNexusForGameBarEnabled' 0
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -ErrorAction SilentlyContinue | ForEach-Object {
      New-ItemProperty -Path $_.PSPath -Name 'TcpAckFrequency' -Value 1 -PropertyType DWord -Force | Out-Null
      New-ItemProperty -Path $_.PSPath -Name 'TCPNoDelay' -Value 1 -PropertyType DWord -Force | Out-Null
    }
    Write-Log 'Game DVR off, Game Bar off, fullscreen optimizations off, games priority raised, Nagle off.'
  }
  if ($opts.cpu -or $opts.idle) { Set-Cpu ([bool]$opts.idle) }
  if ($opts.hags) { Set-Dword 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2; Set-Dword 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' 'OverlayTestMode' 5; Write-Log 'HAGS on. Multiplane overlay off.' }
  if ($opts.mouse) { Set-Mouse }
  if ($opts.sticky) { Set-Sticky }
  if ($opts.focus) { Set-Focus }
  if ($opts.temp) { Clear-UserTemp }
  if ($opts.startup) { Disable-PromoStartup }
  if ($opts.visuals) {
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 2
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAnimations' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt' 0
    Set-String 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' '0'
    Set-Dword 'HKCU:\Control Panel\Desktop' 'DragFullWindows' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ListviewShadow' 0
    Set-String 'HKCU:\Control Panel\Desktop\WindowMetrics' 'MinAnimate' '0'
    Write-Log 'Visuals set. Menu delay 0. Window animations off.'
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
  $bad = @(Select-String -Path $Log -Pattern 'unchanged|Could not|skipped|failed' -ErrorAction SilentlyContinue | Select-Object -Last 8)
  Write-Log "Apply finished. $($picked.Count) ticks."
  if ($bad) { Write-Host 'Recent log warnings:'; $bad | ForEach-Object { Write-Host $_.Line } }
  Set-Content -Path $Last -Value ("{0}  ticks={1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), ($picked -join ','))
  Write-Host "Log: $Log"
  Write-Host "Last run: $Last"
  Write-Host 'Restart to finish.'
  Write-Host '--- after ---'
  foreach ($svc in @('DiagTrack','SysMain','WSearch')) { try { Write-Host ('{0,-12} {1}' -f $svc, (Get-Service $svc -ErrorAction Stop).StartType) } catch { Write-Host "$svc missing" } }
}
Assert-Admin
if (Test-Path $TickFile) { Load-Ticks }
Write-Log 'bare 3.6 started'
while ($true) {
  Write-Host ''
  Write-Host 'bare 3.6'
  Show-Opts
  Write-Host 'p performance   g gaming   v privacy'
  Write-Host 'a apply   d dry run   r revert   c scan   s save   l load   h help   0 exit'
  $choice = Read-Host 'Choose'
  switch ($choice) {
    'p' { Set-Preset 'perf' }
    'g' { Set-Preset 'game' }
    'v' { Set-Preset 'priv' }
    'a' { Invoke-Apply }
    'd' { Invoke-Dry }
    'r' { Invoke-Revert }
    'c' { Invoke-Scan }
    's' { Save-Ticks }
    'l' { Load-Ticks }
    'h' { Write-Host 'p performance: apps, ads, tasks, telemetry, search, xbox, games, cpu, gpu, visuals, mouse, sticky'; Write-Host 'g gaming: apps, ads, tasks, games, cpu, gpu, visuals, mouse, sticky, focus. Leaves Xbox, Edge, Update, Defender.'; Write-Host 'v privacy: apps, ads, tasks, privacy, telemetry, search. Camera and microphone stay.'; Write-Host 'Idle, temp, startup, IPv6, OneDrive, Edge, Update, and Defender ask for yes.' }
    '0' { break }
    default { if ($choice -match '^\d+$') { Invoke-Key ([int]$choice) } }
  }
  if ($choice -eq '0') { break }
}
