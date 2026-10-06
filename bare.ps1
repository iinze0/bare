# bare: wide Windows cleanup that does not remove parts Windows still needs.
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

# Inbox apps that are safe to remove. Store, photos, notepad, calculator, terminal stay.
$AppPatterns = @(
    'Clipchamp.Clipchamp',
    'Microsoft.BingNews',
    'Microsoft.BingWeather',
    'Microsoft.BingSearch',
    'Microsoft.GetHelp',
    'Microsoft.Getstarted',
    'Microsoft.MicrosoftOfficeHub',
    'Microsoft.MicrosoftSolitaireCollection',
    'Microsoft.MixedReality.Portal',
    'Microsoft.People',
    'Microsoft.Todos',
    'Microsoft.WindowsFeedbackHub',
    'Microsoft.WindowsMaps',
    'Microsoft.Xbox.TCUI',
    'Microsoft.XboxGameOverlay',
    'Microsoft.XboxGamingOverlay',
    'Microsoft.XboxIdentityProvider',
    'Microsoft.XboxSpeechToTextOverlay',
    'Microsoft.YourPhone',
    'Microsoft.ZuneMusic',
    'Microsoft.ZuneVideo',
    'MicrosoftCorporationII.MicrosoftFamily',
    'MicrosoftCorporationII.QuickAssist',
    'Microsoft.549981C3F5F10',
    'Microsoft.Windows.DevHome',
    'Microsoft.OutlookForWindows',
    'Microsoft.WindowsAlarms',
    'MicrosoftTeams',
    'MSTeams'
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
        $pkgs = Get-AppxPackage -Name $name -AllUsers -ErrorAction SilentlyContinue
        foreach ($pkg in $pkgs) {
            try {
                Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
                Write-Log "Removed $($pkg.Name)"
                $removed++
            } catch {
                Write-Log "Could not remove $($pkg.Name): $($_.Exception.Message)"
            }
        }
        $prov = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $name }
        foreach ($p in $prov) {
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
    Write-Log 'Ads, tips, and start recommendations disabled for this user.'
}

function Disable-CopilotButton {
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowCopilotButton' 0
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1
    Write-Log 'Copilot button and consumer Copilot policy set. Edge was not removed.'
}

function Set-TelemetryManual {
    foreach ($svc in @('DiagTrack','dmwappushservice')) {
        try {
            Set-Service -Name $svc -StartupType Manual -ErrorAction Stop
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            Write-Log "$svc set to manual and stopped."
        } catch {
            Write-Log "$svc unchanged: $($_.Exception.Message)"
        }
    }
    Set-Dword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 1
    Write-Log 'AllowTelemetry left at 1 (security). Not set to 0.'
}

function Set-ExplorerPrefs {
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt' 0
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Hidden' 1
    Set-Dword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'LaunchTo' 1
    Write-Log 'Explorer: extensions on, hidden files on, This PC as start.'
}

function Set-HighPerformance {
    $plans = powercfg /list
    if ($plans -match '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c') {
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c | Out-Null
        Write-Log 'High performance plan set active. Balanced was not deleted.'
    } else {
        Write-Log 'High performance scheme not installed. No plan change.'
    }
}

Assert-Admin
Write-Log 'bare started.'

while ($true) {
    Write-Host ''
    Write-Host 'bare  -  Windows cleanup that leaves the machine bootable'
    Write-Host '1  Safe pass (restore point, apps, ads, Copilot policy)'
    Write-Host '2  Inbox apps only'
    Write-Host '3  Ads and tips only'
    Write-Host '4  Copilot button and policy only'
    Write-Host '5  Telemetry services to manual'
    Write-Host '6  Explorer preferences'
    Write-Host '7  High performance power plan'
    Write-Host '8  Restore point only'
    Write-Host '0  Exit'
    $choice = Read-Host 'Choose'
    switch ($choice) {
        '1' { New-RestorePoint; Remove-InboxApps; Disable-AdsAndTips; Disable-CopilotButton }
        '2' { Remove-InboxApps }
        '3' { Disable-AdsAndTips }
        '4' { Disable-CopilotButton }
        '5' { Set-TelemetryManual }
        '6' { Set-ExplorerPrefs }
        '7' { Set-HighPerformance }
        '8' { New-RestorePoint }
        '0' { break }
        default { Write-Host 'Unknown choice.' }
    }
    if ($choice -eq '0') { break }
}
Write-Log 'bare exited.'
