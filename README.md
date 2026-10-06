# bare

bare is the all-in-one Windows performance tool. It stops telemetry, inbox apps, and optional background work from sitting on the CPU you paid for. Option 7 is the insane pass: clocks pinned, core parking off, more services disabled. It can run hotter and a few features will be missing. It still boots.

Made by iinze0.

# Important

Run as administrator on Windows 10 or 11. Option 1 is the normal full pass. Option 7 asks you to type `yes`, makes a restore point, then goes harder.

Insane disables the print spooler and Bluetooth, turns hibernate off, and holds the CPU at 100% on AC. Fans will spin. Games can stutter if the chip thermal-limits. Defender, Windows Update, Edge, audio, and network stay on.

# Transparency

No downloads. Everything is in `bare.ps1`. A local log is written to `bare-log.txt`. Nothing is uploaded.

# Usage

1. Copy `bare.cmd` and `bare.ps1` to a folder.
2. Right-click `bare.cmd` and run it as administrator.
3. Choose `1` for the full pass, or `7` and type `yes` for insane. Restart.

# What it does

[What bare does](Help/What%20it%20does.md) | Normal pass and insane pass.

[Left alone](Help/Left%20alone.md) | What it will not kill.

[Revert](Help/Revert.md) | Restore point.

[Changelog](Changelog.md)

[Version](Version.md)
