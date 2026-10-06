# Trust

bare is a local PowerShell script. Trust here means you can read the whole change set, not that a third party audited it.

## What is in the repo

- `bare.cmd` relaunches itself as administrator, then runs `bare.ps1`.
- `bare.ps1` is the only code that changes Windows.
- `Help/` explains each change.
- `LICENSE` is MIT.

## What it does not do

- No `irm`, `Invoke-WebRequest`, `Invoke-RestMethod`, or `iex` of remote content.
- No extra executables, drivers, or scheduled tasks created by bare.
- No account, telemetry, or Discord webhook.
- Logs stay in the folder you ran it from.

## How to check

1. Open `bare.ps1` on GitHub and search for `http`, `Download`, `Invoke-Expression`, and `WebClient`. Those should not be there.
2. Compare the file you run with the file on the `main` branch. The commit history is the change log of the script.
3. After a run, open `bare-log.txt`. Every service and app touch is written there.

## What bare cannot promise

Windows updates can turn a service back on. That is why option 5 exists. A Store app removed by bare stays removed until you install it again. System Restore is the real undo, and it only exists if Windows accepted the checkpoint.
