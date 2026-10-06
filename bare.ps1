# bare 2.2 - pick each change. Nothing runs until you choose Apply.
$ErrorActionPreference = 'Continue'
$Log = Join-Path $PSScriptRoot 'bare-log.txt'
function Write-Log([string]$msg) {
    Add-Content -Path $Log -Value ('{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg)
    Write-Host $msg
}
function Assert-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { Write-Host 'Not running as administrator.'; exit 1 }
}
function Set-Dword([string]$path, [string]$name, [int]$value) {
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    New-ItemProperty -Path $path -Name $name -Value $value -PropertyType DWord -Force | Out-Null
}
function Set-ServiceMode([string]$name, [string]$mode) {
    try {
        if ($mode -eq 'Disabled') { Stop-Service -Name $name -Force -ErrorAction SilentlyContinue; Set-Service -Name $name -StartupType Disabled -ErrorAction Stop }
        else { Set-Service -Name $name -StartupType Manual -ErrorAction Stop; Stop-Service -Name $name -Force -ErrorAction SilentlyContinue }
        Write-Log "$name -> $mode"
    } catch { Write-Log "$name unchanged: $($_.Exception.Message)" }
}
$opts = [ordered]@{
    apps = $false; ads = $false; tasks = $false; privacy = $false; telemetry = $false
    search = $false; xbox = $false; gamedvr = $false; cpu = $false; idle = $false
    hags = $false; visuals = $false; hibernate = $false; bluetooth = $false; print = $false
    ipv6 = $false; onedrive = $false; browser = $false; updates = $false; defender = $false
}
$labels = [ordered]@{
    apps = 'Remove inbox apps (Clipchamp, News, Solitaire, Teams, Xbox overlays)'
    ads = 'Ads, tips, widgets, Copilot button'
    tasks = 'Feedback and compatibility scheduled tasks'
    privacy = 'Privacy policies (advertising id, activity, location, Bing search)'
    telemetry = 'Disable telemetry services'
    search = 'Disable Windows Search'
    xbox = 'Disable Xbox services'
    gamedvr = 'Game DVR off, Game Mode on'
    cpu = 'CPU 100% min/max on AC, core parking off'
    idle = 'CPU idle off (hot, confirm again)'
    hags = 'Hardware GPU scheduling on'
    visuals = 'Visual effects set to performance'
    hibernate = 'Hibernate off'
    bluetooth = 'Disable Bluetooth service'
    print = 'Disable print spooler'
    ipv6 = 'Disable IPv6 (can break some networks)'
    onedrive = 'Uninstall OneDrive'
    browser = 'Install Firefox or Brave, then optional Edge uninstall'
    updates = 'Disable Windows Update (confirm again)'
    defender = 'Disable Defender real-time (confirm again, not recommended)'
}
function Show-Opts {
    $i = 1
    foreach ($k in $opts.Keys) {
        $mark = $(if ($opts[$k]) { 'ON ' } else { 'off' })
        Write-Host ("{0,2}  [{1}]  {2}" -f $i, $mark, $labels[$k])
        $i++
    }
}
function Invoke-Key([int]$n) {
    $keys = @($opts.Keys)
    if ($n -lt 1 -or $n -gt $keys.Count) { return }
    $k = $keys[$n - 1]
    $opts[$k] = -not $opts[$k]
}
function Set-Preset([string]$name) {
    foreach ($k in @($opts.Keys)) { $opts[$k] = $false }
    switch ($name) {
        'perf' { foreach ($k in @('apps','ads','tasks','telemetry','search','xbox','gamedvr','cpu','hags','visuals')) { $opts[$k] = $true } }
        'game' { foreach ($k in @('apps','ads','tasks','gamedvr','cpu','hags','visuals')) { $opts[$k] = $true } }
        'priv' { foreach ($k in @('apps','ads','tasks','privacy','telemetry','search')) { $opts[$k] = $true } }
    }
}
function Remove-InboxApps {
    $names = @('Clipchamp.Clipchamp','Microsoft.BingNews','Microsoft.BingWeather','Microsoft.BingSearch','Microsoft.GetHelp','Microsoft.Getstarted','Microsoft.MicrosoftOfficeHub','Microsoft.MicrosoftSolitaireCollection','Microsoft.MixedReality.Portal','Microsoft.People','Microsoft.Todos','Microsoft.WindowsFeedbackHub','Microsoft.WindowsMaps','Microsoft.Xbox.TCUI','Microsoft.XboxGameOverlay','Microsoft.XboxGamingOverlay','Microsoft.YourPhone','Microsoft.ZuneMusic','Microsoft.ZuneVideo','Microsoft.549981C3F5F10','Microsoft.Windows.DevHome','Microsoft.OutlookForWindows','MicrosoftTeams','MSTeams','Microsoft.GamingApp','Microsoft.Windows.Copilot')
    foreach ($name in $names) {
        foreach ($pkg in @(Get-AppxPackage -Name $name -AllUsers -ErrorAction SilentlyContinue)) {
            try { Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop; Write-Log "Removed $($pkg.Name)" } catch { Write-Log "Could not remove $($pkg.Name)" }
        }
    }
}
function Disable-Tasks {
    foreach ($task in @('\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser','\Microsoft\Windows\Customer Experience Improvement Program\Consolidator','\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip','\Microsoft\Windows\Maps\MapsUpdateTask','\Microsoft\Windows\Feedback\Siuf\DmClient','\Microsoft\Windows\Windows Error Reporting\QueueReporting')) {
        schtasks /Change /TN $task /DISABLE 2>$null | Out-Null
    }
    Write-Log 'Feedback tasks disabled.'
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
    if ($idleOff) { powercfg /setacvalueindex $guid SUB_PROCESSOR IDLEDISABLE 1 | Out-Null; Write-Log 'Idle off.' }
    powercfg /setactive $guid | Out-Null
    Write-Log 'CPU plan set.'
}
function Install-OtherBrowser {
    Write-Host '1 Firefox  2 Brave  3 skip'
    $pick = Read-Host 'Browser'
    $id = $null
    if ($pick -eq '1') { $id = 'Mozilla.Firefox' } elseif ($pick -eq '2') { $id = 'Brave.Brave' } else { return $false }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Write-Log 'winget missing.'; return $false }
    winget install --id $id --accept-package-agreements --accept-source-agreements
    return ($LASTEXITCODE -eq 0)
}
function Uninstall-Edge {
    $root = Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application'
    $setup = Get-ChildItem -Path $root -Recurse -Filter 'setup.exe' -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match '\Installer\setup.exe$' } | Select-Object -First 1
    if (-not $setup) { Write-Log 'Edge setup.exe not found.'; return }
    & $setup.FullName --uninstall --system-level --force-uninstall --verbose-logging
    Write-Log 'Edge uninstall command finished.'
}
function Invoke-Apply {
    Write-Log 'Apply started.'
    try { Checkpoint-Computer -Description 'bare before changes' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop; Write-Log 'Restore point created.' } catch { Write-Log 'Restore point skipped.' }
    if ($opts.apps) { Remove-InboxApps }
    if ($opts.ads) {
        foreach ($n in @('SubscribedContent-338389Enabled','SilentInstalledAppsEnabled','SystemPaneSuggestionsEnabled')) { Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' $n 0 }
        Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowCopilotButton' 0
        Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1
        Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1
        Write-Log 'Ads and Copilot policy set.'
    }
    if ($opts.tasks) { Disable-Tasks }
    if ($opts.privacy) {
        Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0
        Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo' 'DisabledByGroupPolicy' 1
        Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableActivityFeed' 0
        Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocation' 1
        Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 0
        Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'DisableWebSearch' 1
        Write-Log 'Privacy policies set.'
    }
    if ($opts.telemetry) { foreach ($s in @('DiagTrack','dmwappushservice')) { Set-ServiceMode $s 'Disabled' } }
    if ($opts.search) { Set-ServiceMode 'WSearch' 'Disabled' }
    if ($opts.xbox) { foreach ($s in @('XblAuthManager','XblGameSave','XboxGipSvc','XboxNetApiSvc')) { Set-ServiceMode $s 'Disabled' } }
    if ($opts.gamedvr) {
        Set-Dword 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
        Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 0
        Set-Dword 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1
        Write-Log 'Game DVR off, Game Mode on.'
    }
    if ($opts.cpu -or $opts.idle) { Set-Cpu $opts.idle }
    if ($opts.hags) { Set-Dword 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2; Write-Log 'HAGS on.' }
    if ($opts.visuals) {
        Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 2
        Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0
        Write-Log 'Visual effects performance.'
    }
    if ($opts.hibernate) { powercfg -h off | Out-Null; Write-Log 'Hibernate off.' }
    if ($opts.bluetooth) { Set-ServiceMode 'bthserv' 'Disabled' }
    if ($opts.print) { Set-ServiceMode 'Spooler' 'Disabled' }
    if ($opts.ipv6) {
        if ((Read-Host 'Disable IPv6 on all adapters? Type yes') -eq 'yes') {
            Get-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue | Disable-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
            Write-Log 'IPv6 binding disabled.'
        }
    }
    if ($opts.onedrive) {
        if ((Read-Host 'Uninstall OneDrive? Type yes') -eq 'yes') {
            winget uninstall --id Microsoft.OneDrive --accept-source-agreements 2>$null
            Write-Log 'OneDrive uninstall requested.'
        }
    }
    if ($opts.browser) {
        if (Install-OtherBrowser) {
            if ((Read-Host 'Uninstall Edge? Type yes') -eq 'yes') { Uninstall-Edge }
        } else { Write-Log 'Edge left installed.' }
    }
    if ($opts.updates) {
        if ((Read-Host 'Disable Windows Update? Type yes') -eq 'yes') { Set-ServiceMode 'wuauserv' 'Disabled'; Write-Log 'Windows Update disabled.' }
    }
    if ($opts.defender) {
        if ((Read-Host 'Disable Defender real-time? This leaves the PC open. Type yes') -eq 'yes') {
            Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
            Write-Log 'Defender real-time disabled for this boot. Tamper Protection can turn it back on.'
        }
    }
    Write-Log 'Apply finished. Restart.'
}
Assert-Admin
Write-Log 'bare 2.2 started.'
while ($true) {
    Write-Host ''
    Write-Host 'bare 2.2  -  toggle a number, then apply'
    Show-Opts
    Write-Host 'p  performance preset    g  gaming preset    v  privacy preset'
    Write-Host 'a  apply selected         0  exit'
    $choice = Read-Host 'Choose'
    switch ($choice) {
        'p' { Set-Preset 'perf' }
        'g' { Set-Preset 'game' }
        'v' { Set-Preset 'priv' }
        'a' { Invoke-Apply }
        '0' { break }
        default { if ($choice -match '^\d+$') { Invoke-Key ([int]$choice) } }
    }
    if ($choice -eq '0') { break }
}
