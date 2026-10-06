# Options

The menu number matches this table. ON means it will run when you press `a`. A second `yes` is required where the Confirm column says yes.

| # | Name | Apply does this | Preset | Confirm |
| --- | --- | --- | --- | --- |
| 1 | apps | Removes these packages for all users: Clipchamp, Bing News, Bing Weather, Bing Search, Get Help, Get Started, Office hub, Solitaire, Mixed Reality Portal, People, To Do, Feedback Hub, Maps, Xbox TCUI, Xbox Game Overlay, Xbox Gaming Overlay, Phone Link, Groove Music, Movies and TV, Cortana, Dev Home, Outlook for Windows, Teams, Gaming App, Copilot app. Does not deprovision in 2.2. Store, Edge, Photos, Notepad, Calculator, Terminal stay. | p g v | no |
| 2 | ads | Sets suggestion and silent-install content flags to 0, Copilot button to 0, TurnOffWindowsCopilot to 1, DisableWindowsConsumerFeatures to 1. | p g v | no |
| 3 | tasks | Disables Compatibility Appraiser, CEIP Consolidator, UsbCeip, Maps update, Feedback DmClient, error reporting queue. | p g v | no |
| 4 | privacy | AllowTelemetry 0, advertising ID off, activity feed off, location policy off, Bing search off, DisableWebSearch 1. | v | no |
| 5 | telemetry | Disables DiagTrack and dmwappushservice. | p v | no |
| 6 | search | Disables WSearch. | p v | no |
| 7 | xbox | Disables XblAuthManager, XblGameSave, XboxGipSvc, XboxNetApiSvc. | p | no |
| 8 | gamedvr | GameDVR_Enabled 0, AllowGameDVR 0, AutoGameModeEnabled 1. | p g | no |
| 9 | cpu | Ultimate performance if present, else High performance. AC min and max 100. Core parking min cores 100. | p g | no |
| 10 | idle | Same plan, then IDLEDISABLE 1. | none | yes |
| 11 | hags | HwSchMode 2. Needs a restart. | p g | no |
| 12 | visuals | VisualFXSetting 2, EnableTransparency 0. | p g | no |
| 13 | hibernate | `powercfg -h off`. | none | no |
| 14 | bluetooth | Disables bthserv. | none | no |
| 15 | print | Disables Spooler. | none | no |
| 16 | ipv6 | Disables the ms_tcpip6 binding on adapters. | none | yes |
| 17 | onedrive | `winget uninstall --id Microsoft.OneDrive`. | none | yes |
| 18 | browser | winget Firefox or Brave, then Edge `setup.exe --uninstall --system-level --force-uninstall` only after a second yes. | none | yes |
| 19 | updates | Disables wuauserv. | none | yes |
| 20 | defender | `Set-MpPreference -DisableRealtimeMonitoring $true`. Often blocked by Tamper Protection. Lasts until something turns it back on. | none | yes |

2.2 does not set network throttling, MMCSS game priority, or startup delay. Those were in 2.0 and 2.1 and are not in this menu.
