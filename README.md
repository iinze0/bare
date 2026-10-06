# bare

Windows pick-list for debloat and performance. You tick what you want. Nothing changes until you apply.

Made by [iinze0](https://github.com/iinze0). MIT. Not affiliated with Talon or QuakedK.

| | |
| --- | --- |
| Version | 3.2 |
| Release | [v3.2](https://github.com/iinze0/bare/releases/tag/v3.2) |
| OS | Windows 10 and Windows 11 |
| Run | Right-click `bare.bat`, run as administrator |
| Script | `bare.ps1`, same folder as the bat |
| Saved ticks | `bare-ticks.txt`, written on apply |
| Log | `bare-log.txt` next to the script |
| Network | None, unless you tick OneDrive or the browser swap |

## Use

1. Download [v3.2](https://github.com/iinze0/bare/releases/tag/v3.2). Do not pipe it into `iex`.
2. Keep `bare.bat` and `bare.ps1` in the same folder.
3. Right-click `bare.bat` and run as administrator.
4. Type a number to toggle that line. The menu shows how many are on.
5. `p` fills performance, `g` fills gaming, `v` fills privacy. Presets only tick boxes.
6. `d` prints what would run and writes nothing.
7. `a` applies and saves the ticks. Restart.
8. `c` scans. `s` saves. `l` loads. `r` reverts services and policies. It does not reinstall removed apps.

Edge uninstall, IPv6, OneDrive, Windows Update, Defender, and idle-off ask for `yes` again.

## What the presets tick

| Key | Ticks |
| --- | --- |
| `p` | Apps, ads, tasks, telemetry, Search, Xbox, Game DVR, CPU 100%, GPU scheduling, visuals, mouse, sticky |
| `g` | Apps, ads, tasks, Game DVR, CPU 100%, GPU scheduling, visuals, mouse, sticky, focus. Leaves Xbox, Bluetooth, Edge, Update, and Defender alone. |
| `v` | Apps, ads, tasks, privacy policies, telemetry, Search |

The full switch list is [Help/Options.md](Help/Options.md).

## Docs

[Options](Help/Options.md) · [Presets](Help/Presets.md) · [Power](Help/Power.md) · [Privacy](Help/Privacy.md) · [Browser](Help/Browser.md) · [Recommendations](Help/Recommendations.md)

[Left alone](Help/Left%20alone.md) · [Risks](Help/Risks.md) · [Revert](Help/Revert.md) · [Supported Windows](Help/Supported%20Windows.md) · [Trust](Help/Trust.md)

[Changelog](Changelog.md) · [Version](Version.md) · [Security](SECURITY.md) · [License](LICENSE)

## Trust

`bare.ps1` is the whole program. The bat only elevates and runs that file. It does not download the script. winget runs only if you tick OneDrive or the browser swap.
