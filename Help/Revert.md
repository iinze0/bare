# Revert

1. Start, search for Create a restore point.
2. System Restore.
3. Choose `bare before changes`.
4. Restart.

That rolls registry and service startup types back if the checkpoint exists.

Removed provisioned apps usually stay removed. Install the one you want from the Store.

`bare-log.txt` is the list of what the last run changed. `bare-profile.txt` is `performance`, `performance-idleoff`, or `gaming`.

To turn one service back on without a full restore:

```text
services.msc
```

Set it to Manual or Automatic. Defender and Windows Update should already be untouched.
