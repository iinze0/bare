# Browser

Option 18 asks:

- 1 winget install Mozilla.Firefox
- 2 winget install Brave.Brave
- 3 skip

If winget is missing, or the install exit code is not 0, Edge is not removed.

If the install succeeded, a second prompt asks before this command:

```text
setup.exe --uninstall --system-level --force-uninstall --verbose-logging
```

The file is searched under `%ProgramFiles(x86)%\Microsoft\Edge\Application\*\Installer\setup.exe`.

Outside the EEA, Settings often greys out Edge uninstall. That is why the script uses setup.exe. Widgets and some Windows web links can break.

Put Edge back with:

```text
winget install --id XPFFTQ037JWMHS
```

Options 1 through 16 do not remove Edge.
