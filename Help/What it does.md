# What bare does

Option 1 and option 2 both create a restore point, then apply the shared list. They differ on services.

## Inbox apps removed

Removed for current users and deprovisioned so a new user does not get them back:

Clipchamp, News, Weather, Bing search, Get Help, Get Started, Office hub, Solitaire, Mixed Reality Portal, People, To Do, Feedback Hub, Maps, Phone Link, Groove Music, Movies and TV, Family, Quick Assist, Cortana, Dev Home, Outlook for Windows, Alarms, Teams, Xbox app, Xbox overlays, Narrator quick start, Sticky Notes, Voice Recorder, Copilot app package.

Left installed: Store, Photos, Notepad, Calculator, Terminal, Edge.

## Ads and suggestions

| Setting | Value | Why |
| --- | --- | --- |
| ContentDeliveryManager subscribed content, silent apps, suggestions, soft landing | 0 | Stops suggested apps and tips |
| Start_IrisRecommendations | 0 | Start menu recommendations |
| ScoobeSystemSettingEnabled | 0 | Finish-setup nag |
| DisableWindowsConsumerFeatures | 1 | Policy against consumer app suggestions |
| ShowSyncProviderNotifications | 0 | OneDrive-style sync toasts |
| AllowNewsAndInterests | 0 | Widgets news |
| ShowCopilotButton | 0 | Taskbar button |
| TurnOffWindowsCopilot | 1 | Consumer Copilot policy |
| AllowTelemetry | 1 | Floor left at security level, not 0 |

## Scheduled tasks disabled

Compatibility Appraiser, ProgramDataUpdater, StartupAppTask, CEIP Consolidator, UsbCeip, Maps update, Feedback DmClient, disk diagnostic data collector, error reporting queue, Diagnosis Scheduled, DiskFootprint Diagnostics, WinSAT, CloudExperienceHost CreateObjectTask, FamilySafetyMonitor.

## Both profiles, performance side

- Game DVR and app capture off. Game Mode on.
- Hardware-accelerated GPU scheduling set to 2 (on). Needs a restart. Some older GPUs dislike this.
- MMCSS Games task: GPU priority 8, priority 6, scheduling category High.
- NetworkThrottlingIndex set to max (0xffffffff) so multimedia throttling is not capping the pipe.
- SystemResponsiveness 0. More CPU for the foreground, less reserved for background.
- Startup delay 0.
- Visual effects set to performance. Transparency and taskbar animations off.
- Background Store apps blocked.
- CPU minimum and maximum 100% on AC. Core parking min cores 100%. USB selective suspend off.

## Option 1, performance services

Disabled: DiagTrack, dmwappushservice, DoSvc, SysMain, WerSvc, MapsBroker, Fax, RetailDemo, RemoteRegistry, PhoneSvc, WalletService, lfsvc, PcaSvc, wisvc, WorkFolders, SharedAccess, WSearch, XblAuthManager, XblGameSave, XboxGipSvc, XboxNetApiSvc.

## Option 2, gaming services

The quiet list is set to manual and stopped, except Search which is manual. These are forced automatic so play still works: XblAuthManager, XblGameSave, XboxGipSvc, XboxNetApiSvc, bthserv, Audiosrv, AudioEndpointBuilder.

Nvidia and AMD services are not in the list.

## Option 3

Performance profile, then `IDLEDISABLE` 1 on AC. Processor idle states off. More heat and power. Confirm with `yes`.

## Option 4 and 5

Scan prints the active scheme, processor minimum, and startup type for DiagTrack, SysMain, WSearch, XblGameSave, bthserv, Audiosrv, WinDefend, wuauserv, plus the Game DVR flag.

Fix drift reads `bare-profile.txt` (`performance`, `performance-idleoff`, or `gaming`) and applies that profile again.
