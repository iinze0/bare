# Trust

Trust here means the program is one script you can read. Nobody else has signed it.

## In the repo

- `bare.cmd` relaunches as administrator and runs `bare.ps1`.
- `bare.ps1` is the only file that changes Windows.
- `Help/` matches version 2.2. If a help page disagrees with `bare.ps1`, the script wins. Open an issue.

## Not in the script

- No `Invoke-Expression` of a URL.
- No `Invoke-WebRequest`.
- No extra exe, driver, or scheduled task created by bare.
- No webhook, account, or uploaded log.

## How to check

1. Open `bare.ps1` and search for `http`, `DownloadString`, `Invoke-Expression`, and `WebClient`.
2. winget appears only inside the OneDrive and browser functions.
3. Diff the file you run against `main`.
4. After apply, read `bare-log.txt`.
