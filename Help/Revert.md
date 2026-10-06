# Revert

In the menu, `r` then `yes`:

- Sets DiagTrack, delivery optimization, SysMain, Search, Xbox, Bluetooth, print, and Windows Update back to Manual.
- Asks Defender real-time back on.
- Switches the power plan to Balanced.
- Turns hibernate on.
- Removes AllowTelemetry, AllowGameDVR, and TurnOffWindowsCopilot.

It does not reinstall removed Store apps. It does not reinstall Edge or OneDrive.

Edge, if removed: `winget install --id XPFFTQ037JWMHS`

A System Restore point named `bare 2.6 before changes` is created on apply when Windows accepts it.
