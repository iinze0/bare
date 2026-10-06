# Revert

1. Start, search Create a restore point.
2. System Restore.
3. Choose `bare before changes`.
4. Restart.

That rolls service startup types and registry policies back when the checkpoint exists.

Per option, if you do not want a full restore:

- Services: `services.msc`, set the service to Manual or Automatic. Names are in [Options](Options.md).
- Hibernate: `powercfg -h on`
- IPv6: enable the Internet Protocol Version 6 binding on the adapter.
- Edge: `winget install --id XPFFTQ037JWMHS`
- Defender: Windows Security, Virus and threat protection, turn real-time protection on.
- Windows Update: set wuauserv to Manual, then check for updates.

`bare-log.txt` next to the script lists what the last apply wrote.
