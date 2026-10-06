# Options

Each line is a toggle. `p`, `g`, and `v` only fill the ticks.

| # | Key | What it does | Preset |
| --- | --- | --- | --- |
| 1 | apps | Removes Clipchamp, News, Weather, Bing, Solitaire, Teams, Xbox overlays, Phone Link, Maps, Feedback Hub, and the rest of the inbox list. Store and Edge stay. | p g v |
| 2 | ads | Tips, suggestions, widgets news, Copilot button and policy. | p g v |
| 3 | tasks | Compatibility appraiser, CEIP, Maps update, feedback, error reporting queue. | p g v |
| 4 | privacy | Advertising ID, activity history, location, Bing web search. Telemetry policy 0. | v |
| 5 | telemetry | DiagTrack and dmwappushservice disabled. | p v |
| 6 | search | Windows Search disabled. File search gets slow. | p v |
| 7 | xbox | Xbox auth, save, and networking disabled. Gaming preset leaves this off. | p |
| 8 | gamedvr | Capture off, Game Mode on. | p g |
| 9 | cpu | 100% min/max on AC, core parking off. | p g |
| 10 | idle | Idle states off. Asks for yes. Hot. | none |
| 11 | hags | Hardware-accelerated GPU scheduling. | p g |
| 12 | visuals | Performance visual effects, transparency off. | p g |
| 13 | hibernate | `powercfg -h off`. | none |
| 14 | bluetooth | Bluetooth service disabled. Controllers that use it stop. | none |
| 15 | print | Print spooler disabled. | none |
| 16 | ipv6 | IPv6 binding off. Asks for yes. | none |
| 17 | onedrive | winget uninstall OneDrive. Asks for yes. | none |
| 18 | browser | Firefox or Brave, then Edge uninstall only after another yes. | none |
| 19 | updates | Windows Update service disabled. Asks for yes. | none |
| 20 | defender | Real-time monitoring off for this boot. Asks for yes. Tamper Protection often blocks it. | none |

Not included, on purpose: IMOD register writes, Nvidia service disable, Wi-Fi disable. Those are how a gaming PC loses the network or the GPU panel.
