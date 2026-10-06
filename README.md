# bare

Windows pick-list for debloat and performance. You tick what you want. Nothing changes until you apply.

Made by [iinze0](https://github.com/iinze0). MIT. Not affiliated with Talon or QuakedK.

| | |
| --- | --- |
| Version | 2.4 |
| OS | Windows 10 and Windows 11 |
| Run | Right-click `bare.bat`, run as administrator |
| Script | `bare.ps1`, same folder as the bat |
| Log | `bare-log.txt` next to the script |
| Network | None, unless you tick OneDrive or the browser swap |

## Use

1. Download the repo zip. Do not pipe it into `iex`.
2. Right-click `bare.bat` and run as administrator.
3. Type a number to toggle that line.
4. `p` fills performance, `g` fills gaming, `v` fills privacy. Presets only tick boxes.
5. `a` applies. Restart.

Edge uninstall, IPv6, OneDrive, Windows Update, Defender, and idle-off ask for `yes` again.

## What the presets tick

| Key | Ticks |
| --- | --- |
| `p` | Apps, ads, tasks, telemetry, Search, Xbox, Game DVR, CPU 100%, GPU scheduling, visuals |
| `g` | Apps, ads, tasks, Game DVR, CPU 100%, GPU scheduling, visuals. Leaves Xbox, Bluetooth, Edge, Update, and Defender alone. |
| `v` | Apps, ads, tasks, privacy policies, telemetry, Search |

The full switch list is [Help/Options.md](Help/Options.md).

## Docs

[Options](Help/Options.md) · [Presets](Help/Presets.md) · [Power](Help/Power.md) · [Privacy](Help/Privacy.md) · [Browser](Help/Browser.md) · [Recommendations](Help/Recommendations.md)

[Left alone](Help/Left%20alone.md) · [Risks](Help/Risks.md) · [Revert](Help/Revert.md) · [Supported Windows](Help/Supported%20Windows.md) · [Trust](Help/Trust.md)

[Changelog](Changelog.md) · [Version](Version.md) · [Security](SECURITY.md) · [License](LICENSE)

## Trust

`bare.ps1` is the whole program. The bat only elevates and runs that file. It does not download the script. winget runs only if you tick OneDrive or the browser swap. How to check that is in [Help/Trust.md](Help/Trust.md).
