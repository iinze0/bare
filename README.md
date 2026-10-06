# bare

bare is the all-in-one Windows cleanup tool, made to stop telemetry, inbox apps, and optional background work from using the CPU you paid for. The point is a quieter machine, not a broken one. Defender, Windows Update, Edge, and sign-in stay on.

Made by iinze0.

# Important

Run bare on Windows 10 or Windows 11, as administrator. A stock install is the safest place to start, after drivers are already in. Option 1 makes a restore point before it changes anything.

This is not an extreme wipe. Services are set to manual, not deleted. If a feature needs one later, Windows can still start it. Read the [left alone list](Help/Left%20alone.md) before you run it.

# Transparency

bare does not download tools, scripts, or extra programs. Everything it changes is in `bare.ps1` in this repo.

**Logs:**

A local log is written next to the script at `bare-log.txt`. Nothing is uploaded.

# Usage

1. Download this repo, or copy `bare.cmd` and `bare.ps1` to a folder.
2. Right-click `bare.cmd` and run it as administrator.
3. Choose `1` for the full pass. Restart when it finishes.

# What it does

Full list: [What bare does](Help/What%20it%20does.md)

Short version:

- Removes inbox apps (Clipchamp, News, Solitaire, Xbox overlays, Teams, and the rest of that list)
- Turns off ads, tips, start recommendations, and widgets news
- Turns off the Copilot button and Copilot policy. Does not remove Edge
- Sets optional services to manual: telemetry, delivery optimization, SysMain, Windows Search, error reporting, Xbox, Maps, Fax, Retail Demo
- Disables feedback, compatibility, and Maps scheduled tasks
- Turns off Game DVR, background Store apps, transparency, and taskbar animations
- Switches to Ultimate performance if this edition has it, otherwise High performance

# Help

[What it does](Help/What%20it%20does.md) | Every app, service, and task.

[Left alone](Help/Left%20alone.md) | What bare will not touch, and why.

[Revert](Help/Revert.md) | How to undo a pass.

[Changelog](Changelog.md) | What changed.

[Version](Version.md) | Current version.
