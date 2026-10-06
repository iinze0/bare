# bare: quiet background by default, insane clocks on option 7. Boot, Update, and Defender stay.
$ErrorActionPreference = 'Continue'
$Log = Join-Path $PSScriptRoot 'bare-log.txt'

function Write-Log([string]$msg) {
    $line = '{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg
    Add-Content -Path $Log -Value $line
    Write-Host $msg
}

function Assert-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host 'Not running as administrator.'
        exit 1
    }
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
    'Microsoft.WindowsSoundRecorder','Microsoft.ScreenSketch'
)

$ManualServices = @(
    'DiagTrack','dmwappushservice','DoSvc','SysMain','WSearch','WerSvc',
    'XblAuthManager','XblGameSave','XboxGipSvc','XboxNetApiSvc',
    'MapsBroker','Fax','RetailDemo','RemoteRegistry','PhoneSvc','WalletService','lfsvc','PcaSvc'
)

# Extra. Disabled, not deleted. Skip audio, network, update, defender, print.
$InsaneServices = @(
    'SysMain','WSearch','WerSvc','DiagTrack','dmwappushservice','DoSvc',
    'XblAuthManager','XblGameSave','XboxGipSvc','XboxNetApiSvc',
    'MapsBroker','Fax','RetailDemo','RemoteRegistry','PhoneSvc','WalletService','lfsvc','PcaSvc',
    'TabletInputService','WbioSrvc','wisvc','WorkFolders','SharedAccess','PrintNotify','Spooler','bthserv'
)

$Tasks = @(
    '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser',
    '\Microsoft\Windows\Application Experience\ProgramDataUpdater',
    '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator',
    '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip',
    '\Microsoft\Windows\Maps\MapsUpdateTask',
    '\Microsoft\Windows\Feedback\Siuf\DmClient',
    '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector',
    '\Microsoft\Windows\Windows Error Reporting\QueueReporting',
    '\Microsoft\Windows\Application Experience\StartupAppTask',
    '\Microsoft\Windows\Autochk\Proxy',
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
    } catch {
        Write-Log "Restore point skipped: $($_.Exception.Message)"
    }
}

function Remove-InboxApps {
    $removed = 0
    foreach ($name in $AppPatterns) {
        foreach ($pkg in @(Get-AppxPackage -Name $name -AllUsers -ErrorAction SilentlyContinue)) {
            try {
                Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
                Write-Log "Removed $($pkg.Name)"
                $removed++
            } catch {
                Write-Log "Could not remove $($pkg.Name): $($_.Exception.Message)"
            }
        }
        foreach ($p in @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $name })) {
            try {
                Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -ErrorAction Stop | Out-Null
                Write-Log "Deprovisioned $($p.DisplayName)"
            } catch {
                Write-Log "Could not deprovision $($p.DisplayName): $($_.Exception.Message)"
            }
        }
    }
    Write-Log "Inbox app pass done ($removed packages removed)."
}

function Set-Dword([string]$path, [string]$name, [int]$value) {
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    New-ItemProperty -Path $path -Name $name -Value $value -PropertyType DWord -Force | Out-Null
}

function Disable-AdsAndTips {
    $cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    foreach ($n in @('SubscribedContent-338389Enabled','SubscribedContent-310093Enabled','SubscribedContent-338388Enabled','SubscribedContent-338393Enabled','SubscribedContent-353694Enabled','SubscribedContent-353696Enabled','SilentInstalledAppsEnabled','SystemPaneSuggestionsEnabled','SoftLandingEnabled')) {
        Set-Dword $cdm $n 0
    }
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_IrisRecommendations' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement' 'ScoobeSystemSettingEnabled' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowSyncProviderNotifications' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0
    Write-Log 'Ads, tips, widgets news, and start recommendations off.'
}

function Disable-CopilotButton {
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowCopilotButton' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1
    Write-Log 'Copilot button and consumer Copilot policy set. Edge was not removed.'
}

function Set-PowerPlan {
    $ultimate = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
    powercfg -duplicatescheme $ultimate 2>$null | Out-Null
    $list = powercfg /list
    if ($list -match $ultimate) {
        powercfg /setactive $ultimate | Out-Null
        Write-Log 'Ultimate performance plan active.'
        return $ultimate
    }
    $high = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
    if ($list -match $high) {
        powercfg /setactive $high | Out-Null
        Write-Log 'High performance plan active.'
        return $high
    }
    Write-Log 'No extra power scheme installed.'
    return $null
}

function Set-BackgroundQuiet {
    foreach ($svc in $ManualServices) {
        try {
            Set-Service -Name $svc -StartupType Manual -ErrorAction Stop
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            Write-Log "$svc set to manual and stopped."
        } catch {
            Write-Log "$svc unchanged: $($_.Exception.Message)"
        }
    }
    foreach ($task in $Tasks) {
        schtasks /Change /TN $task /DISABLE 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Log "Task disabled: $task" } else { Write-Log "Task skipped: $task" }
    }
    Set-Dword 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' 'GlobalUserDisabled' 1
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy' 'LetAppsRunInBackground' 2
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAnimations' 0
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop\WindowMetrics' -Name 'MinAnimate' -Value '0' -ErrorAction SilentlyContinue
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 1
    Write-Log 'Game DVR off, background Store apps blocked, animations off.'
    Set-PowerPlan | Out-Null
}

function Set-ExplorerPrefs {
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Hidden' 1
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'LaunchTo' 1
    Write-Log 'Explorer: extensions on, hidden files on, This PC as start.'
}

function Set-Insane {
    Write-Log 'INSANE pass. Heat, fan noise, and a few features will get worse. Boot, Defender, and Windows Update stay.'
    foreach ($svc in $InsaneServices) {
        try {
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop
            Write-Log "$svc disabled."
        } catch {
            Write-Log "$svc not disabled: $($_.Exception.Message)"
        }
    }
    $guid = Set-PowerPlan
    if ($guid) {
        powercfg /setacvalueindex $guid SUB_PROCESSOR PROCTHROTTLEMIN 100 | Out-Null
        powercfg /setacvalueindex $guid SUB_PROCESSOR PROCTHROTTLEMAX 100 | Out-Null
        powercfg /setacvalueindex $guid SUB_PROCESSOR CPMINCORES 100 | Out-Null
        powercfg /setacvalueindex $guid SUB_SLEEP STANDBYIDLE 0 | Out-Null
        powercfg /setactive $guid | Out-Null
        Write-Log 'CPU min and max at 100%. Core parking off. Sleep idle off on AC.'
    }
    Set-Dword 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 0xffffffff
    Set-Dword 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 0
    Set-Dword 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'DisablePagingExecutive' 1
    Set-Dword 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize' 'StartupDelayInMSec' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 2
    powercfg -h off | Out-Null
    Write-Log 'Network throttling index maxed, startup delay 0, visual effects performance, hibernate off.'
    Write-Log 'Print spooler and Bluetooth were disabled. Turn them back on in services.msc if you need them.'
    Write-Log 'Insane pass done. Restart. If a game stutters, System Restore.'
}

Assert-Admin
Write-Log 'bare started.'

while ($true) {
    Write-Host ''
    Write-Host 'bare  -  CPU for what you run'
    Write-Host '1  Full pass (restore point, apps, ads, background)'
    Write-Host '2  Inbox apps only'
    Write-Host '3  Ads and tips only'
    Write-Host '4  Copilot button and policy only'
    Write-Host '5  Explorer preferences'
    Write-Host '7  INSANE  (option 1, then clocks at 100%, extra services off)'
    Write-Host '9  Background only'
    Write-Host '8  Restore point only'
    Write-Host '0  Exit'
    $choice = Read-Host 'Choose'
    switch ($choice) {
        '1' { New-RestorePoint; Remove-InboxApps; Disable-AdsAndTips; Disable-CopilotButton; Set-BackgroundQuiet; Set-ExplorerPrefs }
        '2' { Remove-InboxApps }
        '3' { Disable-AdsAndTips }
        '4' { Disable-CopilotButton }
        '5' { Set-ExplorerPrefs }
        '7' {
            $answer = Read-Host 'Insane uses more heat and disables print and Bluetooth. Type yes'
            if ($answer -eq 'yes') {
                New-RestorePoint
                Remove-InboxApps
                Disable-AdsAndTips
                Disable-CopilotButton
                Set-BackgroundQuiet
                Set-ExplorerPrefs
                Set-Insane
            } else {
                Write-Host 'Cancelled.'
            }
        }
        '9' { Set-BackgroundQuiet }
        '8' { New-RestorePoint }
        '0' { break }
        default { Write-Host 'Unknown choice.' }
    }
    if ($choice -eq '0') { break }
}
Write-Log 'bare exited.'
