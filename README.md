# bare

Windows menu that stops optional background work from using the CPU. Run as administrator. Made by iinze0.

```powershell
.\bare.cmd
```

Option 1 is the full pass. It makes a restore point first, then does everything below. A log is written to `bare-log.txt`.

## What it does

Removes these inbox apps for all users, and stops Windows from reinstalling them for new users:

- Clipchamp, News, Weather, Bing search
- Get Help, Get Started, Office hub, Solitaire, Mixed Reality, People, To Do
- Feedback Hub, Maps, Phone Link, Groove Music, Movies & TV, Family, Quick Assist
- Cortana, Dev Home, Outlook for Windows, Alarms, Teams, Xbox app and Xbox overlays, Narrator quick start

Turns off ads and suggestions:

- Start menu recommendations
- Settings tips and suggested apps
- Consumer features policy (preinstalled suggestions)
- Widgets news and interests
- Sync provider notifications

Turns off Copilot:

- Taskbar Copilot button
- Windows Copilot policy
- Does not uninstall Edge

Stops optional background CPU use. Services are set to manual and stopped, not deleted:

- Connected User Experiences and Telemetry (`DiagTrack`)
- WAP push message routing (`dmwappushservice`)
- Delivery Optimization (`DoSvc`)
- SysMain
- Windows Search (`WSearch`)
- Windows Error Reporting (`WerSvc`)
- Xbox auth, game save, game input, and Xbox networking
- Maps, Fax, Retail Demo, Remote Registry, Phone, Wallet, Geolocation, Program Compatibility Assistant

Disables these scheduled tasks:

- Microsoft Compatibility Appraiser
- ProgramDataUpdater
- Customer Experience Improvement Program (Consolidator and UsbCeip)
- Maps update
- Feedback DmClient
- Disk diagnostic data collector
- Windows Error Reporting queue

Other CPU and UI cuts:

- Game DVR and background capture off. Game Mode is not removed.
- Store apps not allowed to run in the background
- Transparency and taskbar animations off
- Ultimate performance power plan if this Windows edition has it, otherwise High performance. Balanced is not deleted.
- File extensions shown, hidden files shown, Explorer opens to This PC

## What it does not do

- Does not turn off Defender, Firewall, or Windows Update
- Does not remove Edge, the Store, OneDrive, audio, network, or the print spooler
- Does not delete services or files in System32
- Does not change drivers, timers, or IMOD

Search is slower after Windows Search is manual. Xbox Game Bar will not be running. Store apps will not refresh in the background. Undo is the restore point from option 1.
