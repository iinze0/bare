# bare 2.1
# Performance, gaming, privacy. Edge is removed only after another browser is installed.
$ErrorActionPreference = 'Continue'
$Log = Join-Path $PSScriptRoot 'bare-log.txt'
$StateFile = Join-Path $PSScriptRoot 'bare-profile.txt'

function Write-Log([string]$msg) {
    $line = '{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg
    Add-Content -Path $Log -Value $line
    Write-Host $msg
}
function Assert-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { Write-Host 'Not running as administrator.'; exit 1 }
}
$AppPatterns = @(
    'Clipchamp.Clipchamp','Microsoft.BingNews','Microsoft.BingWeather','Microsoft.BingSearch',
    'Microsoft.GetHelp','Microsoft.Getstarted','Microsoft.MicrosoftOfficeHub',
    'Microsoft.MicrosoftSolitaireCollection','Microsoft.MixedReality.Portal','Microsoft.People',
    'Microsoft.Todos','Microsoft.WindowsFeedbackHub','Microsoft.WindowsMaps',
    'Microsoft.Xbox.TCUI','Microsoft.XboxGameOverlay','Microsoft.XboxGamingOverlay',
    'Microsoft.XboxIdentityProvider','Microsoft.XboxSpeechToTextOverlay','Microsoft.YourPhone',
    'Microsoft.ZuneMusic','Microsoft.ZuneVideo','MicrosoftCorporationII.MicrosoftFamily',
    'MicrosoftCorporationII.QuickAssist','Microsoft.549981C3F5F10','Microsoft.Windows.DevHome',
    'Microsoft.OutlookForWindows','Microsoft.WindowsAlarms','MicrosoftTeams','MSTeams',
    'Microsoft.GamingApp','Microsoft.Windows.NarratorQuickStart','Microsoft.MicrosoftStickyNotes',
    'Microsoft.WindowsSoundRecorder','Microsoft.Windows.Copilot'
)
$QuietServices = @('DiagTrack','dmwappushservice','DoSvc','SysMain','WerSvc','MapsBroker','Fax','RetailDemo','RemoteRegistry','PhoneSvc','WalletService','lfsvc','PcaSvc','wisvc','WorkFolders','SharedAccess')
$Tasks = @(
    '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser',
    '\Microsoft\Windows\Application Experience\ProgramDataUpdater',
    '\Microsoft\Windows\Application Experience\StartupAppTask',
    '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator',
    '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip',
    '\Microsoft\Windows\Maps\MapsUpdateTask',
    '\Microsoft\Windows\Feedback\Siuf\DmClient',
    '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector',
    '\Microsoft\Windows\Windows Error Reporting\QueueReporting',
    '\Microsoft\Windows\Diagnosis\Scheduled',
    '\Microsoft\Windows\DiskFootprint\Diagnostics',
    '\Microsoft\Windows\Maintenance\WinSAT',
    '\Microsoft\Windows\CloudExperienceHost\CreateObjectTask',
    '\Microsoft\Windows\Shell\FamilySafetyMonitor'
)
function New-RestorePoint {
    try {
        Enable-ComputerRestore -Drive 'C:\' -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description 'bare before changes' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
        Write-Log 'Restore point created.'
    } catch { Write-Log "Restore point skipped: $($_.Exception.Message)" }
}
function Set-Dword([string]$path, [string]$name, [int]$value) {
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    New-ItemProperty -Path $path -Name $name -Value $value -PropertyType DWord -Force | Out-Null
}
function Remove-InboxApps {
    $removed = 0
    foreach ($name in $AppPatterns) {
        foreach ($pkg in @(Get-AppxPackage -Name $name -AllUsers -ErrorAction SilentlyContinue)) {
            try { Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop; Write-Log "Removed $($pkg.Name)"; $removed++ } catch { Write-Log "Could not remove $($pkg.Name): $($_.Exception.Message)" }
        }
        foreach ($p in @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $name })) {
            try { Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -ErrorAction Stop | Out-Null; Write-Log "Deprovisioned $($p.DisplayName)" } catch { Write-Log "Could not deprovision $($p.DisplayName): $($_.Exception.Message)" }
        }
    }
    Write-Log "Inbox app pass done ($removed packages removed)."
}
function Disable-AdsAndTips {
    $cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    foreach ($n in @('SubscribedContent-338389Enabled','SubscribedContent-310093Enabled','SubscribedContent-338388Enabled','SubscribedContent-338393Enabled','SubscribedContent-353694Enabled','SubscribedContent-353696Enabled','SilentInstalledAppsEnabled','SystemPaneSuggestionsEnabled','SoftLandingEnabled')) { Set-Dword $cdm $n 0 }
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_IrisRecommendations' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement' 'ScoobeSystemSettingEnabled' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowSyncProviderNotifications' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowCopilotButton' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1
    Write-Log 'Ads, tips, widgets, Copilot policy off.'
}
function Disable-Tasks {
    foreach ($task in $Tasks) { schtasks /Change /TN $task /DISABLE 2>$null | Out-Null; if ($LASTEXITCODE -eq 0) { Write-Log "Task disabled: $task" } }
}
function Set-ServiceMode([string]$name, [string]$mode) {
    try {
        if ($mode -eq 'Disabled') { Stop-Service -Name $name -Force -ErrorAction SilentlyContinue; Set-Service -Name $name -StartupType Disabled -ErrorAction Stop }
        else { Set-Service -Name $name -StartupType Manual -ErrorAction Stop; Stop-Service -Name $name -Force -ErrorAction SilentlyContinue }
        Write-Log "$name -> $mode"
    } catch { Write-Log "$name unchanged: $($_.Exception.Message)" }
}
function Enable-ServiceAuto([string]$name) {
    try { Set-Service -Name $name -StartupType Automatic -ErrorAction Stop; Start-Service -Name $name -ErrorAction SilentlyContinue; Write-Log "$name -> automatic" } catch { Write-Log "$name not started: $($_.Exception.Message)" }
}
function Get-PlanGuid {
    $ultimate = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
    powercfg -duplicatescheme $ultimate 2>$null | Out-Null
    $list = powercfg /list
    if ($list -match $ultimate) { return $ultimate }
    $high = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
    if ($list -match $high) { return $high }
    return $null
}
function Set-CpuPlan([bool]$idleOff) {
    $guid = Get-PlanGuid
    if (-not $guid) { Write-Log 'No Ultimate or High performance scheme.'; return }
    powercfg /setactive $guid | Out-Null
    powercfg /setacvalueindex $guid SUB_PROCESSOR PROCTHROTTLEMIN 100 | Out-Null
    powercfg /setacvalueindex $guid SUB_PROCESSOR PROCTHROTTLEMAX 100 | Out-Null
    powercfg /setacvalueindex $guid SUB_PROCESSOR CPMINCORES 100 | Out-Null
    powercfg /setacvalueindex $guid SUB_PROCESSOR CPMAXCORES 100 | Out-Null
    powercfg /setacvalueindex $guid SUB_SLEEP STANDBYIDLE 0 | Out-Null
    powercfg /setacvalueindex $guid SUB_USB USBSELECTIVESUSPEND 0 | Out-Null
    if ($idleOff) { powercfg /setacvalueindex $guid SUB_PROCESSOR IDLEDISABLE 1 | Out-Null; Write-Log 'CPU 100%, idle OFF.' }
    else { powercfg /setacvalueindex $guid SUB_PROCESSOR IDLEDISABLE 0 | Out-Null; Write-Log 'CPU 100%, idle still on.' }
    powercfg /setactive $guid | Out-Null
}
function Set-SharedPerf {
    Set-Dword 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' 'GlobalUserDisabled' 1
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy' 'LetAppsRunInBackground' 2
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAnimations' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 2
    Set-Dword 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 0xffffffff
    Set-Dword 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 0
    Set-Dword 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize' 'StartupDelayInMSec' 0
    Set-Dword 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'GPU Priority' 8
    Set-Dword 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'Priority' 6
    Set-Dword 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'Scheduling Category' 2
    Set-Dword 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1
    Set-Dword 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode' 1
    Set-Dword 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2
    Write-Log 'Game DVR off, Game Mode on, HAGS on.'
}
function Set-PrivacyPolicies {
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
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableSoftLanding' 1
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SilentInstalledAppsEnabled' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync' 'DisableSettingSync' 2
    Write-Log 'Privacy policies set: advertising id, activity history, location, Bing search, settings sync.'
}
function Install-OtherBrowser {
    Write-Host '1 Firefox'
    Write-Host '2 Brave'
    Write-Host '3 Neither'
    $pick = Read-Host 'Browser'
    $id = $null
    if ($pick -eq '1') { $id = 'Mozilla.Firefox' }
    elseif ($pick -eq '2') { $id = 'Brave.Brave' }
    else { Write-Log 'No alternate browser requested.'; return $false }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Write-Log 'winget is not installed. Install a browser yourself, then run option 7.'; return $false }
    Write-Log "winget install $id"
    winget install --id $id --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) { Write-Log "$id installed."; return $true }
    Write-Log "winget failed for $id (exit $LASTEXITCODE)."
    return $false
}
function Uninstall-Edge {
    $root = Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application'
    if (-not (Test-Path $root)) { Write-Log 'Edge application folder not found.'; return }
    $setup = Get-ChildItem -Path $root -Recurse -Filter 'setup.exe' -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match '\Installer\setup.exe$' } | Select-Object -First 1
    if (-not $setup) { Write-Log 'Edge setup.exe not found. On an EEA PC, uninstall Edge from Settings, Apps.'; return }
    Write-Log "Edge uninstall via $($setup.FullName)"
    & $setup.FullName --uninstall --system-level --force-uninstall --verbose-logging
    Write-Log 'Edge uninstall command finished. Check Settings, Apps. Widgets and some Windows links can break.'
}
function Invoke-BrowserSwap {
    $ok = Install-OtherBrowser
    if (-not $ok) { Write-Host 'Edge was not removed, because no alternate browser was installed.'; return }
    $answer = Read-Host 'Uninstall Edge now? Widgets and some system web links can break. Type yes'
    if ($answer -eq 'yes') { Uninstall-Edge } else { Write-Log 'Edge left installed.' }
}
function Set-PerformanceProfile([bool]$idleOff) {
    Write-Log 'Applying PERFORMANCE.'
    Remove-InboxApps; Disable-AdsAndTips; Disable-Tasks
    foreach ($svc in $QuietServices) { Set-ServiceMode $svc 'Disabled' }
    foreach ($svc in @('WSearch','XblAuthManager','XblGameSave','XboxGipSvc','XboxNetApiSvc')) { Set-ServiceMode $svc 'Disabled' }
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 1
    Set-SharedPerf; Set-CpuPlan $idleOff
    Set-Content -Path $StateFile -Value $(if ($idleOff) { 'performance-idleoff' } else { 'performance' })
}
function Set-GamingProfile {
    Write-Log 'Applying GAMING.'
    Remove-InboxApps; Disable-AdsAndTips; Disable-Tasks
    foreach ($svc in $QuietServices) { Set-ServiceMode $svc 'Manual' }
    Set-ServiceMode 'WSearch' 'Manual'
    foreach ($svc in @('XblAuthManager','XblGameSave','XboxGipSvc','XboxNetApiSvc','bthserv','Audiosrv','AudioEndpointBuilder')) { Enable-ServiceAuto $svc }
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 1
    Set-SharedPerf; Set-CpuPlan $false
    Set-Content -Path $StateFile -Value 'gaming'
}
function Set-PrivacyProfile {
    Write-Log 'Applying PRIVACY.'
    Remove-InboxApps; Disable-AdsAndTips; Disable-Tasks; Set-PrivacyPolicies
    foreach ($svc in $QuietServices) { Set-ServiceMode $svc 'Disabled' }
    Set-ServiceMode 'WSearch' 'Disabled'
    Set-Content -Path $StateFile -Value 'privacy'
    Write-Host 'Privacy policies are on. Defender and Windows Update stay.'
    $swap = Read-Host 'Install Firefox or Brave, then optionally remove Edge? Type yes'
    if ($swap -eq 'yes') { Invoke-BrowserSwap }
}
function Invoke-Detect {
    Write-Host (powercfg /getactivescheme)
    foreach ($svc in @('DiagTrack','SysMain','WSearch','XblGameSave','bthserv','Audiosrv','WinDefend','wuauserv')) {
        try { $st = (Get-Service -Name $svc -ErrorAction Stop).StartType } catch { $st = 'missing' }
        Write-Host ("{0,-16} {1}" -f $svc, $st)
    }
    $edge = Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application'
    Write-Host ("Edge folder present: $(Test-Path $edge)")
    if (Test-Path $StateFile) { Write-Host ("Saved profile: $(Get-Content $StateFile -Raw)") }
}
function Invoke-FixDrift {
    if (-not (Test-Path $StateFile)) { Write-Host 'No saved profile.'; return }
    switch ((Get-Content $StateFile -Raw).Trim()) {
        'gaming' { Set-GamingProfile }
        'performance' { Set-PerformanceProfile $false }
        'performance-idleoff' { Set-PerformanceProfile $true }
        'privacy' { Set-PrivacyProfile }
        default { Write-Log 'Unknown profile.' }
    }
}
Assert-Admin
Write-Log 'bare 2.1 started.'
while ($true) {
    Write-Host ''
    Write-Host 'bare 2.1'
    Write-Host '1  Performance'
    Write-Host '2  Gaming'
    Write-Host '3  Performance + idle off'
    Write-Host '6  Privacy     telemetry, ads, activity, location, Bing search'
    Write-Host '7  Browser     install Firefox or Brave, then optional Edge uninstall'
    Write-Host '4  Scan'
    Write-Host '5  Fix drift'
    Write-Host '8  Restore point only'
    Write-Host '0  Exit'
    $choice = Read-Host 'Choose'
    switch ($choice) {
        '1' { New-RestorePoint; Set-PerformanceProfile $false }
        '2' { New-RestorePoint; Set-GamingProfile }
        '3' { $a = Read-Host 'Idle off. Type yes'; if ($a -eq 'yes') { New-RestorePoint; Set-PerformanceProfile $true } }
        '6' { New-RestorePoint; Set-PrivacyProfile }
        '7' { Invoke-BrowserSwap }
        '4' { Invoke-Detect }
        '5' { Invoke-FixDrift }
        '8' { New-RestorePoint }
        '0' { break }
        default { Write-Host 'Unknown choice.' }
    }
    if ($choice -eq '0') { break }
}
Write-Log 'bare exited.'
