# Browser and Edge

Option 7, and the end of option 6, ask which browser to install.

- 1 installs `Mozilla.Firefox` with winget
- 2 installs `Brave.Brave` with winget
- 3 installs nothing

Edge is uninstalled only after that install returns success, and only if you type `yes`.

The uninstall runs Edge's own installer:

```text
setup.exe --uninstall --system-level --force-uninstall --verbose-logging
```

The path is `%ProgramFiles(x86)%\Microsoft\Edge\Application\<version>\Installer\setup.exe`.

In the EEA, Edge can also be removed from Settings, Apps. Outside the EEA the Settings button is often greyed out, which is why the script uses setup.exe.

Removing Edge can break Widgets, some Start-menu web links, and any app that opens links through Edge. Reinstall with:

```text
winget install --id XPFFTQ037JWMHS
```

Performance and gaming do not uninstall Edge.
