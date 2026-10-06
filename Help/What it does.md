# What bare does

## Both profiles

Restore point.

Removes inbox apps: Clipchamp, News, Weather, Bing, Get Help, Get Started, Office hub, Solitaire, Mixed Reality, People, To Do, Feedback Hub, Maps, Phone Link, Groove, Movies and TV, Family, Quick Assist, Cortana, Dev Home, Outlook for Windows, Alarms, Teams, Xbox app and overlays, Narrator quick start, Sticky Notes, Voice Recorder.

Ads, tips, start recommendations, widgets, Copilot button and policy off. Edge stays.

Feedback, compatibility, Maps, and CEIP tasks off.

Game DVR and capture off. Game Mode on. Hardware-accelerated GPU scheduling on. MMCSS games task raised. Network throttling index maxed. Startup delay 0. Visual effects set to performance.

CPU minimum and maximum 100% on AC. Core parking min cores 100%. USB selective suspend off.

## 1 Performance

Telemetry, SysMain, Search, Delivery Optimization, error reporting, Maps, Fax, Xbox services set to disabled.

File search and Xbox sign-in will not be running. Bluetooth is not touched.

## 2 Gaming

Same cleanup, but Xbox services, Bluetooth, and audio are forced automatic so controllers and game audio still work. Search is manual, not disabled.

GPU driver services are not touched. Nvidia and AMD panels keep working.

## 3 Performance, idle off

Performance profile, then processor idle disable. The CPU does not park in idle states. More heat, more power. Not for laptops.

## 4 Scan and 5 Fix drift

Scan prints the active power plan, processor minimum, and startup type for telemetry, SysMain, Search, Xbox, Bluetooth, audio, Defender, and Windows Update.

Fix drift reads `bare-profile.txt` and applies that profile again.
