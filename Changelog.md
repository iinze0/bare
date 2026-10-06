# Changelog

## 3.5

- Revert restores NTFS last-access updates and the default NTFS cache, and clears Find My Device, clipboard, and inking policies.
- Apply writes `bare-last.txt` with the time and the ticks it ran.
- Dry run warns about the temp and startup confirms.

## 3.4

- Late CPU settings are applied. Revert clears priority, overlay, Nagle, prefetch, and dynamic tick.
