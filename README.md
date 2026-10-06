# bare

A Windows pick-list for debloat, performance, and privacy. You tick options. Nothing changes until you apply.

Made by [iinze0](https://github.com/iinze0). MIT license. Not affiliated with Talon, Chris Titus, or QuakedK. Not a copy of Oneclick.

| | |
| --- | --- |
| Version | 2.2 |
| OS | Windows 10 and Windows 11 |
| Needs | Administrator |
| Code | `bare.ps1` only |
| Network | None, unless you tick OneDrive or the browser swap. Those call winget. |
| Undo | Restore point `bare before changes`, if Windows accepted it |

# Important

Run it on Windows 10 or 11, as administrator. A stock install with drivers already in is the safest start.

Presets only tick boxes. `a` is what applies them. Edge uninstall, IPv6, OneDrive, Windows Update, Defender, and idle-off ask for `yes` again.

Read [Help/Options.md](Help/Options.md) and [Help/Risks.md](Help/Risks.md) before the first apply.

# Transparency

bare does not ship extra tools. It does not phone home. `bare-log.txt` is written next to the script and stays there.

winget runs only if option 17 or 18 is on. The package ids are `Microsoft.OneDrive`, `Mozilla.Firefox`, and `Brave.Brave`. Edge removal uses Edge's own `setup.exe`, not a downloaded remover.

# Usage

1. Download the repo zip, or clone it. Do not pipe it into `iex`.
2. Right-click `bare.cmd` and run as administrator.
3. Type a number to toggle that line. `p`, `g`, or `v` fills a preset.
4. Type `a` to apply. Restart.

# Help

[Options](Help/Options.md) | Every switch, what it changes, which preset ticks it.

[Presets](Help/Presets.md) | Performance, gaming, privacy.

[Power](Help/Power.md) | CPU 100% and idle off.

[Privacy](Help/Privacy.md) | What the privacy ticks change.

[Browser](Help/Browser.md) | Firefox, Brave, Edge removal, how to put Edge back.

[Left alone](Help/Left%20alone.md) | What is not in the script.

[Risks](Help/Risks.md) | What can break or run hot.

[Revert](Help/Revert.md) | Restore point and per-option undo.

[Supported Windows](Help/Supported%20Windows.md) | 10 and 11.

[Trust](Help/Trust.md) | How to audit the script.

[Recommendations](Help/Recommendations.md) | What to tick for a gaming PC.

[Changelog](Changelog.md)

[Version](Version.md)

[Security](SECURITY.md)
