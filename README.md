# bare

All-in-one Windows cleanup menu. Strips inbox apps, ads, tips, and optional telemetry. Leaves Windows Update, Defender, Edge, the Store, and sign-in working.

Windows 10/11. Run as administrator. Made by iinze0.

This is not a copy of Talon or Oneclick. Those tools go further (Edge removal, service wipes, update blocks). That is also how they break machines. bare skips those.

## Use

Right-click `bare.cmd` and run as administrator, or from an admin PowerShell:

```powershell
.\bare.cmd
```

The menu:

1. Safe pass. Restore point, then apps, ads, tips, and Copilot policy. This is the one to run.
2. Inbox apps only. Clipchamp, News, Solitaire, Bing apps, and the rest of the list. Not Store, Notepad, Calculator, Photos, Terminal.
3. Ads, tips, suggestions, and start-menu recommendations.
4. Copilot button and Windows consumer Copilot policy. Does not uninstall Edge.
5. Optional telemetry services set to manual. DiagTrack and dmwappushservice. They are not deleted.
6. Show file extensions and hidden files. Open This PC instead of Home.
7. High performance power plan, if the scheme exists. Does not delete Balanced.
8. Restore point only.

Every change is logged to `bare-log.txt` next to the script.

## Left alone on purpose

- Windows Update, Defender, Firewall, Windows Search
- Edge, Store, OneDrive uninstall, account login
- Services Windows needs to boot, update, and install drivers
- Registry latency myths, timer tweaks, IMOD, and driver edits

If a pass did something you dislike, System Restore is the undo. Create the point from the menu before the first run if you skip option 1.
