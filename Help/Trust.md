# Trust

`bare.ps1` is the whole program. Profiles 1, 2, and 3 do not use the network.

Option 6 and 7 call `winget install` only after you pick Firefox or Brave. That download comes from Microsoft's winget source, not from this repo.

There is no `Invoke-Expression` of a URL. Logs stay in `bare-log.txt` next to the script.
