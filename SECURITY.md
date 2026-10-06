# Security

bare does not request Windows credentials, does not disable Defender, and does not fetch code at runtime.

If you find a path in `bare.ps1` that writes outside the script folder except through documented Windows settings (services, schtasks, powercfg, AppX, registry), open an issue on this repo.

Do not run a copy of `bare.cmd` that you did not diff against `main`.
