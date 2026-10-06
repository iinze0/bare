# bare

All-in-one Windows menu. Goal: stop inbox apps, ads, and optional background work from using the CPU you paid for. Windows Update, Defender, networking, audio, and sign-in stay on.

Windows 10/11. Run as administrator. Made by iinze0.

## Use

Right-click `bare.cmd` and run as administrator.

```powershell
.\bare.cmd
```

1. Full pass. Restore point, inbox apps, ads, Copilot policy, then the background CPU pass. This is the one to run.
9. Background only. Services to manual, a few scheduled tasks off, Game DVR off, widgets off, Ultimate performance plan if Windows has it.

A log is written to `bare-log.txt`.

## What the background pass actually stops

Services set to manual, not deleted: DiagTrack, delivery optimization, SysMain, Windows Search, error reporting, Xbox services, Maps, Fax, Retail Demo, Remote Registry, phone, wallet, geolocation.

Tasks disabled: compatibility appraiser, customer experience, Maps update, feedback, disk-diagnostic data collection.

Also: Game DVR capture off, widgets and news off, background Store apps not allowed to run in the background, transparency and window animations off, Ultimate performance power plan if the scheme exists.

Search will be slower after Windows Search is manual. Xbox sign-in and Game Bar will not be running. Store apps will not refresh in the background. That is the trade for a quieter CPU.

## Left alone

Defender, Firewall, Windows Update, Edge, Store, audio, network, print spooler, and anything required to boot. Services are set to manual so Windows can still start them if a feature needs them. Nothing is deleted from System32.
