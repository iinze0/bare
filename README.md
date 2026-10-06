# bare

Windows debloat and performance menu. Two profiles, a scan, and a drift fix. One script. No downloads.

Made by [iinze0](https://github.com/iinze0). MIT license. Not affiliated with Talon, Chris Titus, or QuakedK.

| | |
| --- | --- |
| Version | 2.0 |
| OS | Windows 10 and Windows 11 |
| Needs | Administrator |
| Network | None. The script does not download or phone home. |
| Undo | System Restore point `bare before changes` |

## Use

1. Download the repo as a zip, or clone it. Do not pipe it into `iex`.
2. Right-click `bare.cmd` and run as administrator.
3. Choose a profile. Restart.
4. Later, option 4 scans. Option 5 re-applies the last profile if Windows turned a service back on.

```text
1  Performance
2  Gaming
3  Performance + idle off   (confirm with yes)
4  Scan
5  Fix drift
8  Restore point only
0  Exit
```

## Trust

Read [Help/Trust.md](Help/Trust.md) before you run it. Short version: `bare.ps1` is the whole program. It does not call `Invoke-Expression` on a URL, does not drop binaries, and writes logs only next to itself (`bare-log.txt`, `bare-profile.txt`).

## Docs

- [What it does](Help/What%20it%20does.md) every app, service, task, and registry value
- [Power and CPU](Help/Power.md) what 100% minimum actually means
- [Left alone](Help/Left%20alone.md) what it will not touch
- [Risks](Help/Risks.md) what can feel unstable
- [Revert](Help/Revert.md)
- [Trust](Help/Trust.md)
- [Changelog](Changelog.md)
- [Version](Version.md)
- [License](LICENSE)
