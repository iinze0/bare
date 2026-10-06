# Supported Windows

Test target is Windows 10 and Windows 11, 64-bit, with an administrator account.

Not supported:

- Windows Home vs Pro is fine. Group policy writes still land in the registry. Home may ignore some policy keys until a Pro edition reads them.
- Windows on ARM is untested.
- Servers are untested.
- A PC with no System Restore can still be changed. Undo is then manual. See [Revert](Revert.md).

winget must already be present for options 17 and 18. Windows 11 has it. Windows 10 needs App Installer from the Store.
