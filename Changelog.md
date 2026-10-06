# Changelog

## 2.6

- Dry run (`d`) lists ticked changes and writes nothing.
- Revert (`r`) sets the services this script touches back to manual, asks Defender real-time back on, switches to Balanced, turns hibernate on, and removes the telemetry, Game DVR, and Copilot policies.
- Scan also prints AllowTelemetry, HAGS, and GameDVR_Enabled.
- Apply refuses to run if nothing is ticked, and the menu shows how many are on.
- Restore point name is `bare 2.6 before changes`.

## 2.5

- Ticks save on apply and load on the next launch.
