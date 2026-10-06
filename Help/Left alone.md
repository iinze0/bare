# Left alone

Even option 3 does not change:

- Windows Defender and Firewall
- Windows Update (`wuauserv`)
- Edge, the Store, sign-in
- Audio endpoint on the gaming profile (performance does not disable Audiosrv either)
- Network, DHCP, TCP stack, IPv6
- Nvidia and AMD driver services
- Print spooler in 2.0 (1.1 disabled it; 2.0 does not)
- Bluetooth on the gaming profile
- Drivers, IMOD registers, timer-resolution hacks

AllowTelemetry is set to 1, not 0. 0 is the policy some tools use to cut security telemetry. bare does not.
